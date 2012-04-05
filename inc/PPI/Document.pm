#line 1
package PPI::Document;

#line 64

use strict;
use Carp                          ();
use List::MoreUtils               ();
use Params::Util                  qw{_SCALAR0 _ARRAY0 _INSTANCE};
use Digest::MD5                   ();
use PPI::Util                     ();
use PPI                           ();
use PPI::Node                     ();
use PPI::Exception::ParserTimeout ();

use overload 'bool' => \&PPI::Util::TRUE;
use overload '""'   => 'content';

use vars qw{$VERSION @ISA $errstr};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Node';
	$errstr  = '';
}

use PPI::Document::Fragment ();

# Document cache
my $CACHE = undef;

# Convenience constants related to constants
use constant LOCATION_LINE         => 0;
use constant LOCATION_CHARACTER    => 1;
use constant LOCATION_COLUMN       => 2;
use constant LOCATION_LOGICAL_LINE => 3;
use constant LOCATION_LOGICAL_FILE => 4;





#####################################################################
# Constructor and Static Methods

#line 146

sub new {
	local $_; # An extra one, just in case
	my $class = ref $_[0] ? ref shift : shift;

	unless ( @_ ) {
		my $self = $class->SUPER::new;
		$self->{readonly}  = ! 1;
		$self->{tab_width} = 1;
		return $self;
	}

	# Check constructor attributes
	my $source  = shift;
	my %attr    = @_;
	my $timeout = delete $attr{timeout};
	if ( $timeout and ! PPI::Util::HAVE_ALARM() ) {
		Carp::croak("This platform does not support PPI parser timeouts");
	}

	# Check the data source
	if ( ! defined $source ) {
		$class->_error("An undefined value was passed to PPI::Document::new");

	} elsif ( ! ref $source ) {
		# Catch people using the old API
		if ( $source =~ /(?:\012|\015)/ ) {
			Carp::croak("API CHANGE: Source code should only be passed to PPI::Document->new as a SCALAR reference");
		}

		# When loading from a filename, use the caching layer if it exists.
		if ( $CACHE ) {
			my $file   = $source;
			my $source = PPI::Util::_slurp( $file );
			unless ( ref $source ) {
				# Errors returned as plain string
				return $class->_error($source);
			}

			# Retrieve the document from the cache
			my $document = $CACHE->get_document($source);
			return $class->_setattr( $document, %attr ) if $document;

			if ( $timeout ) {
				eval {
					local $SIG{ALRM} = sub { die "alarm\n" };
					alarm( $timeout );
					$document = PPI::Lexer->lex_source( $$source );
					alarm( 0 );
				};
			} else {
				$document = PPI::Lexer->lex_source( $$source );
			}
			if ( $document ) {
				# Save in the cache
				$CACHE->store_document( $document );
				return $class->_setattr( $document, %attr );
			}
		} else {
			if ( $timeout ) {
				eval {
					local $SIG{ALRM} = sub { die "alarm\n" };
					alarm( $timeout );
					my $document = PPI::Lexer->lex_file( $source );
					return $class->_setattr( $document, %attr ) if $document;
					alarm( 0 );
				};
			} else {
				my $document = PPI::Lexer->lex_file( $source );
				return $class->_setattr( $document, %attr ) if $document;
			}
		}

	} elsif ( _SCALAR0($source) ) {
		if ( $timeout ) {
			eval {
				local $SIG{ALRM} = sub { die "alarm\n" };
				alarm( $timeout );
				my $document = PPI::Lexer->lex_source( $$source );
				return $class->_setattr( $document, %attr ) if $document;
				alarm( 0 );
			};
		} else {
			my $document = PPI::Lexer->lex_source( $$source );
			return $class->_setattr( $document, %attr ) if $document;
		}

	} elsif ( _ARRAY0($source) ) {
		$source = join '', map { "$_\n" } @$source;
		if ( $timeout ) {
			eval {
				local $SIG{ALRM} = sub { die "alarm\n" };
				alarm( $timeout );
				my $document = PPI::Lexer->lex_source( $source );
				return $class->_setattr( $document, %attr ) if $document;
				alarm( 0 );
			};
		} else {
			my $document = PPI::Lexer->lex_source( $source );
			return $class->_setattr( $document, %attr ) if $document;
		}

	} else {
		$class->_error("Unknown object or reference was passed to PPI::Document::new");
	}

	# Pull and store the error from the lexer
	my $errstr;
	if ( _INSTANCE($@, 'PPI::Exception::Timeout') ) {
		$errstr = 'Timed out while parsing document';
	} elsif ( _INSTANCE($@, 'PPI::Exception') ) {
		$errstr = $@->message;
	} elsif ( $@ ) {
		$errstr = $@;
		$errstr =~ s/\sat line\s.+$//;
	} elsif ( PPI::Lexer->errstr ) {
		$errstr = PPI::Lexer->errstr;
	} else {
		$errstr = "Unknown error parsing Perl document";
	}
	PPI::Lexer->_clear;
	$class->_error( $errstr );
}

sub load {
	Carp::croak("API CHANGE: File names should now be passed to PPI::Document->new to load a file");
}

sub _setattr {
	my ($class, $document, %attr) = @_;
	$document->{readonly} = !! $attr{readonly};
	return $document;
}

#line 301

sub set_cache {
	my $class  = ref $_[0] ? ref shift : shift;

	if ( defined $_[0] ) {
		# Enable the cache
		my $object = _INSTANCE(shift, 'PPI::Cache') or return undef;
		$CACHE = $object;
	} else {
		# Disable the cache
		$CACHE = undef;
	}

	1;
}

#line 328

sub get_cache {
	$CACHE;	
}





#####################################################################
# PPI::Document Instance Methods

#line 352

sub readonly {
	$_[0]->{readonly};
}

#line 372

sub tab_width {
	my $self = shift;
	return $self->{tab_width} unless @_;
	$self->{tab_width} = shift;
}

#line 390

sub save {
	my $self = shift;
	local *FILE;
	open( FILE, '>', $_[0] )    or return undef;
	print FILE $self->serialize or return undef;
	close FILE                  or return undef;
	return 1;
}

#line 419

sub serialize {
	my $self   = shift;
	my @tokens = $self->tokens;

	# The here-doc content buffer
	my $heredoc = '';

	# Start the main loop
	my $output = '';
	foreach my $i ( 0 .. $#tokens ) {
		my $Token = $tokens[$i];

		# Handle normal tokens
		unless ( $Token->isa('PPI::Token::HereDoc') ) {
			my $content = $Token->content;

			# Handle the trivial cases
			unless ( $heredoc ne '' and $content =~ /\n/ ) {
				$output .= $content;
				next;
			}

			# We have pending here-doc content that needs to be
			# inserted just after the first newline in the content.
			if ( $content eq "\n" ) {
				# Shortcut the most common case for speed
				$output .= $content . $heredoc;
			} else {
				# Slower and more general version
				$content =~ s/\n/\n$heredoc/;
				$output .= $content;
			}

			$heredoc = '';
			next;
		}

		# This token is a HereDoc.
		# First, add the token content as normal, which in this
		# case will definately not contain a newline.
		$output .= $Token->content;

		# Now add all of the here-doc content to the heredoc buffer.
		foreach my $line ( $Token->heredoc ) {
			$heredoc .= $line;
		}

		if ( $Token->{_damaged} ) {
			# Special Case:
			# There are a couple of warning/bug situations
			# that can occur when a HereDoc content was read in
			# from the end of a file that we silently allow.
			#
			# When writing back out to the file we have to
			# auto-repair these problems if we arn't going back
			# on to the end of the file.

			# When calculating $last_line, ignore the final token if
			# and only if it has a single newline at the end.
			my $last_index = $#tokens;
			if ( $tokens[$last_index]->{content} =~ /^[^\n]*\n$/ ) {
				$last_index--;
			}

			# This is a two part test.
			# First, are we on the last line of the
			# content part of the file
			my $last_line = List::MoreUtils::none {
				$tokens[$_] and $tokens[$_]->{content} =~ /\n/
				} (($i + 1) .. $last_index);
			if ( ! defined $last_line ) {
				# Handles the null list case
				$last_line = 1;
			}

			# Secondly, are their any more here-docs after us,
			# (with content or a terminator)
			my $any_after = List::MoreUtils::any {
				$tokens[$_]->isa('PPI::Token::HereDoc')
				and (
					scalar(@{$tokens[$_]->{_heredoc}})
					or
					defined $tokens[$_]->{_terminator_line}
					)
				} (($i + 1) .. $#tokens);
			if ( ! defined $any_after ) {
				# Handles the null list case
				$any_after = '';
			}

			# We don't need to repair the last here-doc on the
			# last line. But we do need to repair anything else.
			unless ( $last_line and ! $any_after ) {
				# Add a terminating string if it didn't have one
				unless ( defined $Token->{_terminator_line} ) {
					$Token->{_terminator_line} = $Token->{_terminator};
				}

				# Add a trailing newline to the terminating
				# string if it didn't have one.
				unless ( $Token->{_terminator_line} =~ /\n$/ ) {
					$Token->{_terminator_line} .= "\n";
				}
			}
		}

		# Now add the termination line to the heredoc buffer
		if ( defined $Token->{_terminator_line} ) {
			$heredoc .= $Token->{_terminator_line};
		}
	}

	# End of tokens

	if ( $heredoc ne '' ) {
		# If the file doesn't end in a newline, we need to add one
		# so that the here-doc content starts on the next line.
		unless ( $output =~ /\n$/ ) {
			$output .= "\n";
		}

		# Now we add the remaining here-doc content
		# to the end of the file.
		$output .= $heredoc;
	}

	$output;
}

#line 565

sub hex_id {
	PPI::Util::md5hex($_[0]->serialize);
}

#line 588

sub index_locations {
	my $self   = shift;
	my @tokens = $self->tokens;

	# Whenever we hit a heredoc we will need to increment by
	# the number of lines in it's content section when when we
	# encounter the next token with a newline in it.
	my $heredoc = 0;

	# Find the first Token without a location
	my ($first, $location) = ();
	foreach ( 0 .. $#tokens ) {
		my $Token = $tokens[$_];
		next if $Token->{_location};

		# Found the first Token without a location
		# Calculate the new location if needed.
		if ($_) {
			$location =
				$self->_add_location( $location, $tokens[$_ - 1], \$heredoc );
		} else {
			my $logical_file =
				$self->can('filename') ? $self->filename : undef;
			$location = [ 1, 1, 1, 1, $logical_file ];
		}
		$first = $_;
		last;
	}

	# Calculate locations for the rest
	if ( defined $first ) {
		foreach ( $first .. $#tokens ) {
			my $Token = $tokens[$_];
			$Token->{_location} = $location;
			$location = $self->_add_location( $location, $Token, \$heredoc );

			# Add any here-doc lines to the counter
			if ( $Token->isa('PPI::Token::HereDoc') ) {
				$heredoc += $Token->heredoc + 1;
			}
		}
	}

	1;
}

sub _add_location {
	my ($self, $start, $Token, $heredoc) = @_;
	my $content = $Token->{content};

	# Does the content contain any newlines
	my $newlines =()= $content =~ /\n/g;
	my ($logical_line, $logical_file) =
		$self->_logical_line_and_file($start, $Token, $newlines);

	unless ( $newlines ) {
		# Handle the simple case
		return [
			$start->[LOCATION_LINE],
			$start->[LOCATION_CHARACTER] + length($content),
			$start->[LOCATION_COLUMN]
				+ $self->_visual_length(
					$content,
					$start->[LOCATION_COLUMN]
				),
			$logical_line,
			$logical_file,
		];
	}

	# This is the more complex case where we hit or
	# span a newline boundary.
	my $physical_line = $start->[LOCATION_LINE] + $newlines;
	my $location = [ $physical_line, 1, 1, $logical_line, $logical_file ];
	if ( $heredoc and $$heredoc ) {
		$location->[LOCATION_LINE]         += $$heredoc;
		$location->[LOCATION_LOGICAL_LINE] += $$heredoc;
		$$heredoc = 0;
	}

	# Does the token have additional characters
	# after their last newline.
	if ( $content =~ /\n([^\n]+?)\z/ ) {
		$location->[LOCATION_CHARACTER] += length($1);
		$location->[LOCATION_COLUMN] +=
			$self->_visual_length(
				$1, $location->[LOCATION_COLUMN],
			);
	}

	$location;
}

sub _logical_line_and_file {
	my ($self, $start, $Token, $newlines) = @_;

	# Regex taken from perlsyn, with the correction that there's no space
	# required between the line number and the file name.
	if ($start->[LOCATION_CHARACTER] == 1) {
		if ( $Token->isa('PPI::Token::Comment') ) {
			if (
				$Token->content =~ m<
					\A
					\#      \s*
					line    \s+
					(\d+)   \s*
					(?: (\"?) ([^\"]* [^\s\"]) \2 )?
					\s*
					\z
				>xms
			) {
				return $1, ($3 || $start->[LOCATION_LOGICAL_FILE]);
			}
		}
		elsif ( $Token->isa('PPI::Token::Pod') ) {
			my $content = $Token->content;
			my $line;
			my $file = $start->[LOCATION_LOGICAL_FILE];
			my $end_of_directive;
			while (
				$content =~ m<
					^
					\#      \s*?
					line    \s+?
					(\d+)   (?: (?! \n) \s)*
					(?: (\"?) ([^\"]*? [^\s\"]) \2 )??
					\s*?
					$
				>xmsg
			) {
				($line, $file) = ($1, ( $3 || $file ) );
				$end_of_directive = pos $content;
			}

			if (defined $line) {
				pos $content = $end_of_directive;
				my $post_directive_newlines =()= $content =~ m< \G [^\n]* \n >xmsg;
				return $line + $post_directive_newlines - 1, $file;
			}
		}
	}

	return
		$start->[LOCATION_LOGICAL_LINE] + $newlines,
		$start->[LOCATION_LOGICAL_FILE];
}

sub _visual_length {
	my ($self, $content, $pos) = @_;

	my $tab_width = $self->tab_width;
	my ($length, $vis_inc);

	return length $content if $content !~ /\t/;

	# Split the content in tab and non-tab parts and calculate the
	# "visual increase" of each part.
	for my $part ( split(/(\t)/, $content) ) {
		if ($part eq "\t") {
			$vis_inc = $tab_width - ($pos-1) % $tab_width;
		}
		else {
			$vis_inc = length $part;
		}
		$length += $vis_inc;
		$pos    += $vis_inc;
	}

	$length;
}

#line 768

sub flush_locations {
	shift->_flush_locations(@_);
}

#line 791

sub normalized {
	# The normalization process will utterly destroy and mangle
	# anything passed to it, so we are going to only give it a
	# clone of ourself.
	PPI::Normal->process( $_[0]->clone );
}

#line 810

sub complete {
	my $self = shift;

	# Every structure has to be complete
	$self->find_any( sub {
		$_[1]->isa('PPI::Structure')
		and
		! $_[1]->complete
	} )
	and return '';

	# Strip anything that isn't a statement off the end
	my @child = $self->children;
	while ( @child and not $child[-1]->isa('PPI::Statement') ) {
		pop @child;
	}

	# We must have at least one statement
	return '' unless @child;

	# Check the completeness of the last statement
	return $child[-1]->_complete;
}





#####################################################################
# PPI::Node Methods

# We are a scope boundary
### XS -> PPI/XS.xs:_PPI_Document__scope 0.903+
sub scope { 1 }





#####################################################################
# PPI::Element Methods

sub insert_before {
	return undef;
	# die "Cannot insert_before a PPI::Document";
}

sub insert_after {
	return undef;
	# die "Cannot insert_after a PPI::Document";
}

sub replace {
	return undef;
	# die "Cannot replace a PPI::Document";
}





#####################################################################
# Error Handling

# Set the error message
sub _error {
	$errstr = $_[1];
	undef;
}

# Clear the error message.
# Returns the object as a convenience.
sub _clear {
	$errstr = '';
	$_[0];
}

#line 898

sub errstr {
	$errstr;
}





#####################################################################
# Native Storable Support

sub STORABLE_freeze {
	my $self  = shift;
	my $class = ref $self;
	my %hash  = %$self;
	return ($class, \%hash);
}

sub STORABLE_thaw {
	my ($self, undef, $class, $hash) = @_;
	bless $self, $class;
	foreach ( keys %$hash ) {
		$self->{$_} = delete $hash->{$_};
	}
	$self->__link_children;
}

1;

#line 958
