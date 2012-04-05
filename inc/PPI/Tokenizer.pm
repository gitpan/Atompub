#line 1
package PPI::Tokenizer;

#line 77

# Make sure everything we need is loaded so
# we don't have to go and load all of PPI.
use strict;
use Params::Util    qw{_INSTANCE _SCALAR0 _ARRAY0};
use List::MoreUtils ();
use PPI::Util       ();
use PPI::Element    ();
use PPI::Token      ();
use PPI::Exception  ();
use PPI::Exception::ParserRejection ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}





#####################################################################
# Creation and Initialization

#line 117

sub new {
	my $class = ref($_[0]) || $_[0];

	# Create the empty tokenizer struct
	my $self = bless {
		# Source code
		source       => undef,
		source_bytes => undef,

		# Line buffer
		line         => undef,
		line_length  => undef,
		line_cursor  => undef,
		line_count   => 0,

		# Parse state
		token        => undef,
		class        => 'PPI::Token::BOM',
		zone         => 'PPI::Token::Whitespace',

		# Output token buffer
		tokens       => [],
		token_cursor => 0,
		token_eof    => 0,

		# Perl 6 blocks
		perl6        => [],
	}, $class;

	if ( ! defined $_[1] ) {
		# We weren't given anything
		PPI::Exception->throw("No source provided to Tokenizer");

	} elsif ( ! ref $_[1] ) {
		my $source = PPI::Util::_slurp($_[1]);
		if ( ref $source ) {
			# Content returned by reference
			$self->{source} = $$source;
		} else {
			# Errors returned as a string
			return( $source );
		}

	} elsif ( _SCALAR0($_[1]) ) {
		$self->{source} = ${$_[1]};

	} elsif ( _ARRAY0($_[1]) ) {
		$self->{source} = join '', map { "\n" } @{$_[1]};

	} else {
		# We don't support whatever this is
		PPI::Exception->throw(ref($_[1]) . " is not supported as a source provider");
	}

	# We can't handle a null string
	$self->{source_bytes} = length $self->{source};
	if ( $self->{source_bytes} > 1048576 ) {
		# Dammit! It's ALWAYS the "Perl" modules larger than a
		# meg that seems to blow up the Tokenizer/Lexer.
		# Nobody actually writes real programs larger than a meg
		# Perl::Tidy (the largest) is only 800k.
		# It is always these idiots with massive Data::Dumper
		# structs or huge RecDescent parser.
		PPI::Exception::ParserRejection->throw("File is too large");

	} elsif ( $self->{source_bytes} ) {
		# Split on local newlines
		$self->{source} =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;
		$self->{source} = [ split /(?<=\n)/, $self->{source} ];

	} else {
		$self->{source} = [ ];
	}

	### EVIL
	# I'm explaining this earlier than I should so you can understand
	# why I'm about to do something that looks very strange. There's
	# a problem with the Tokenizer, in that tokens tend to change
	# classes as each letter is added, but they don't get allocated
	# their definite final class until the "end" of the token, the
	# detection of which occurs in about a hundred different places,
	# all through various crufty code (that triples the speed).
	#
	# However, in general, this does not apply to tokens in which a
	# whitespace character is valid, such as comments, whitespace and
	# big strings.
	#
	# So what we do is add a space to the end of the source. This
	# triggers normal "end of token" functionality for all cases. Then,
	# once the tokenizer hits end of file, it examines the last token to
	# manually either remove the ' ' token, or chop it off the end of
	# a longer one in which the space would be valid.
	if ( List::MoreUtils::any { /^__(?:DATA|END)__\s*$/ } @{$self->{source}} ) {
		$self->{source_eof_chop} = '';
	} elsif ( ! defined $self->{source}->[0] ) {
		$self->{source_eof_chop} = '';
	} elsif ( $self->{source}->[-1] =~ /\s$/ ) {
		$self->{source_eof_chop} = '';
	} else {
		$self->{source_eof_chop} = 1;
		$self->{source}->[-1] .= ' ';
	}

	$self;
}





#####################################################################
# Main Public Methods

#line 253

sub get_token {
	my $self = shift;

	# Shortcut for EOF
	if ( $self->{token_eof}
	 and $self->{token_cursor} > scalar @{$self->{tokens}}
	) {
		return 0;
	}

	# Return the next token if we can
	if ( my $token = $self->{tokens}->[ $self->{token_cursor} ] ) {
		$self->{token_cursor}++;
		return $token;
	}

	my $line_rv;

	# Catch exceptions and return undef, so that we
	# can start to convert code to exception-based code.
	my $rv = eval {
		# No token, we need to get some more
		while ( $line_rv = $self->_process_next_line ) {
			# If there is something in the buffer, return it
			# The defined() prevents a ton of calls to PPI::Util::TRUE
			if ( defined( my $token = $self->{tokens}->[ $self->{token_cursor} ] ) ) {
				$self->{token_cursor}++;
				return $token;
			}
		}
		return undef;
	};
	if ( $@ ) {
		if ( _INSTANCE($@, 'PPI::Exception') ) {
			$@->throw;
		} else {
			my $errstr = $@;
			$errstr =~ s/^(.*) at line .+$/$1/;
			PPI::Exception->throw( $errstr );
		}
	} elsif ( $rv ) {
		return $rv;
	}

	if ( defined $line_rv ) {
		# End of file, but we can still return things from the buffer
		if ( my $token = $self->{tokens}->[ $self->{token_cursor} ] ) {
			$self->{token_cursor}++;
			return $token;
		}

		# Set our token end of file flag
		$self->{token_eof} = 1;
		return 0;
	}

	# Error, pass it up to our caller
	undef;
}

#line 330

sub all_tokens {
	my $self = shift;

	# Catch exceptions and return undef, so that we
	# can start to convert code to exception-based code.
	eval {
		# Process lines until we get EOF
		unless ( $self->{token_eof} ) {
			my $rv;
			while ( $rv = $self->_process_next_line ) {}
			unless ( defined $rv ) {
				PPI::Exception->throw("Error while processing source");
			}

			# Clean up the end of the tokenizer
			$self->_clean_eof;
		}
	};
	if ( $@ ) {
		my $errstr = $@;
		$errstr =~ s/^(.*) at line .+$/$1/;
		PPI::Exception->throw( $errstr );
	}

	# End of file, return a copy of the token array.
	return [ @{$self->{tokens}} ];
}

#line 374

sub increment_cursor {
	# Do this via the get_token method, which makes sure there
	# is actually a token there to move to.
	$_[0]->get_token and 1;
}

#line 399

sub decrement_cursor {
	my $self = shift;

	# Check for the beginning of the file
	return 0 unless $self->{token_cursor};

	# Decrement the token cursor
	$self->{token_eof} = 0;
	--$self->{token_cursor};
}





#####################################################################
# Working With Source

# Fetches the next line from the input line buffer
# Returns undef at EOF.
sub _get_line {
	my $self = shift;
	return undef unless $self->{source}; # EOF hit previously

	# Pull off the next line
	my $line = shift @{$self->{source}};

	# Flag EOF if we hit it
	$self->{source} = undef unless defined $line;

	# Return the line (or EOF flag)
	return $line; # string or undef
}

# Fetches the next line, ready to process
# Returns 1 on success
# Returns 0 on EOF
sub _fill_line {
	my $self   = shift;
	my $inscan = shift;

	# Get the next line
	my $line = $self->_get_line;
	unless ( defined $line ) {
		# End of file
		unless ( $inscan ) {
			delete $self->{line};
			delete $self->{line_cursor};
			delete $self->{line_length};
			return 0;
		}

		# In the scan version, just set the cursor to the end
		# of the line, and the rest should just cascade out.
		$self->{line_cursor} = $self->{line_length};
		return 0;
	}

	# Populate the appropriate variables
	$self->{line}        = $line;
	$self->{line_cursor} = -1;
	$self->{line_length} = length $line;
	$self->{line_count}++;

	1;
}

# Get the current character
sub _char {
	my $self = shift;
	substr( $self->{line}, $self->{line_cursor}, 1 );
}





####################################################################
# Per line processing methods

# Processes the next line
# Returns 1 on success completion
# Returns 0 if EOF
# Returns undef on error
sub _process_next_line {
	my $self = shift;

	# Fill the line buffer
	my $rv;
	unless ( $rv = $self->_fill_line ) {
		return undef unless defined $rv;

		# End of file, finalize last token
		$self->_finalize_token;
		return 0;
	}

	# Run the __TOKENIZER__on_line_start
	$rv = $self->{class}->__TOKENIZER__on_line_start( $self );
	unless ( $rv ) {
		# If there are no more source lines, then clean up
		if ( ref $self->{source} eq 'ARRAY' and ! @{$self->{source}} ) {
			$self->_clean_eof;
		}

		# Defined but false means next line
		return 1 if defined $rv;
		PPI::Exception->throw("Error at line $self->{line_count}");
	}

	# If we can't deal with the entire line, process char by char
	while ( $rv = $self->_process_next_char ) {}
	unless ( defined $rv ) {
		PPI::Exception->throw("Error at line $self->{line_count}, character $self->{line_cursor}");
	}

	# Trigger any action that needs to happen at the end of a line
	$self->{class}->__TOKENIZER__on_line_end( $self );

	# If there are no more source lines, then clean up
	unless ( ref($self->{source}) eq 'ARRAY' and @{$self->{source}} ) {
		return $self->_clean_eof;
	}

	return 1;
}





#####################################################################
# Per-character processing methods

# Process on a per-character basis.
# Note that due the the high number of times this gets
# called, it has been fairly heavily in-lined, so the code
# might look a bit ugly and duplicated.
sub _process_next_char {
	my $self = shift;

	### FIXME - This checks for a screwed up condition that triggers
	###         several warnings, amoungst other things.
	if ( ! defined $self->{line_cursor} or ! defined $self->{line_length} ) {
		# $DB::single = 1;
		return undef;
	}

	# Increment the counter and check for end of line
	return 0 if ++$self->{line_cursor} >= $self->{line_length};

	# Pass control to the token class
        my $result;
	unless ( $result = $self->{class}->__TOKENIZER__on_char( $self ) ) {
		# undef is error. 0 is "Did stuff ourself, you don't have to do anything"
		return defined $result ? 1 : undef;
	}

	# We will need the value of the current character
	my $char = substr( $self->{line}, $self->{line_cursor}, 1 );
	if ( $result eq '1' ) {
		# If __TOKENIZER__on_char returns 1, it is signaling that it thinks that
		# the character is part of it.

		# Add the character
		if ( defined $self->{token} ) {
			$self->{token}->{content} .= $char;
		} else {
			defined($self->{token} = $self->{class}->new($char)) or return undef;
		}

		return 1;
	}

	# We have been provided with the name of a class
	if ( $self->{class} ne "PPI::Token::$result" ) {
		# New class
		$self->_new_token( $result, $char );
	} elsif ( defined $self->{token} ) {
		# Same class as current
		$self->{token}->{content} .= $char;
	} else {
		# Same class, but no current
		defined($self->{token} = $self->{class}->new($char)) or return undef;
	}

	1;
}





#####################################################################
# Altering Tokens in Tokenizer

# Finish the end of a token.
# Returns the resulting parse class as a convenience.
sub _finalize_token {
	my $self = shift;
	return $self->{class} unless defined $self->{token};

	# Add the token to the token buffer
	push @{ $self->{tokens} }, $self->{token};
	$self->{token} = undef;

	# Return the parse class to that of the zone we are in
	$self->{class} = $self->{zone};
}

# Creates a new token and sets it in the tokenizer
# The defined() in here prevent a ton of calls to PPI::Util::TRUE
sub _new_token {
	my $self = shift;
	# throw PPI::Exception() unless @_;
	my $class = substr( $_[0], 0, 12 ) eq 'PPI::Token::'
		? shift : 'PPI::Token::' . shift;

	# Finalize any existing token
	$self->_finalize_token if defined $self->{token};

	# Create the new token and update the parse class
	defined($self->{token} = $class->new($_[0])) or PPI::Exception->throw;
	$self->{class} = $class;

	1;
}

# At the end of the file, we need to clean up the results of the erroneous
# space that we inserted at the beginning of the process.
sub _clean_eof {
	my $self = shift;

	# Finish any partially completed token
	$self->_finalize_token if $self->{token};

	# Find the last token, and if it has no content, kill it.
	# There appears to be some evidence that such "null tokens" are
	# somehow getting created accidentally.
	my $last_token = $self->{tokens}->[ -1 ];
	unless ( length $last_token->{content} ) {
		pop @{$self->{tokens}};
	}

	# Now, if the last character of the last token is a space we added,
	# chop it off, deleting the token if there's nothing else left.
	if ( $self->{source_eof_chop} ) {
		$last_token = $self->{tokens}->[ -1 ];
		$last_token->{content} =~ s/ $//;
		unless ( length $last_token->{content} ) {
			# Popping token
			pop @{$self->{tokens}};
		}

		# The hack involving adding an extra space is now reversed, and
		# now nobody will ever know. The perfect crime!
		$self->{source_eof_chop} = '';
	}

	1;
}





#####################################################################
# Utility Methods

# Context
sub _last_token {
	$_[0]->{tokens}->[-1];
}

sub _last_significant_token {
	my $self   = shift;
	my $cursor = $#{ $self->{tokens} };
	while ( $cursor >= 0 ) {
		my $token = $self->{tokens}->[$cursor--];
		return $token if $token->significant;
	}

	# Nothing...
	PPI::Token::Whitespace->null;
}

# Get an array ref of previous significant tokens.
# Like _last_significant_token except it gets more than just one token
# Returns array ref on success.
# Returns 0 on not enough tokens
sub _previous_significant_tokens {
	my $self   = shift;
	my $count  = shift || 1;
	my $cursor = $#{ $self->{tokens} };

	my ($token, @tokens);
	while ( $cursor >= 0 ) {
		$token = $self->{tokens}->[$cursor--];
		if ( $token->significant ) {
			push @tokens, $token;
			return \@tokens if scalar @tokens >= $count;
		}
	}

	# Pad with empties
	foreach ( 1 .. ($count - scalar @tokens) ) {
		push @tokens, PPI::Token::Whitespace->null;
	}

	\@tokens;
}

my %OBVIOUS_CLASS = (
	'PPI::Token::Symbol'              => 'operator',
	'PPI::Token::Magic'               => 'operator',
	'PPI::Token::Number'              => 'operator',
	'PPI::Token::ArrayIndex'          => 'operator',
	'PPI::Token::Quote::Double'       => 'operator',
	'PPI::Token::Quote::Interpolate'  => 'operator',
	'PPI::Token::Quote::Literal'      => 'operator',
	'PPI::Token::Quote::Single'       => 'operator',
	'PPI::Token::QuoteLike::Backtick' => 'operator',
	'PPI::Token::QuoteLike::Command'  => 'operator',
	'PPI::Token::QuoteLike::Readline' => 'operator',
	'PPI::Token::QuoteLike::Regexp'   => 'operator',
	'PPI::Token::QuoteLike::Words'    => 'operator',
);

my %OBVIOUS_CONTENT = (
	'(' => 'operand',
	'{' => 'operand',
	'[' => 'operand',
	';' => 'operand',
	'}' => 'operator',
);

# Try to determine operator/operand context, is possible.
# Returns "operator", "operand", or "" if unknown.
sub _opcontext {
	my $self   = shift;
	my $tokens = $self->_previous_significant_tokens(1);
	my $p0     = $tokens->[0];
	my $c0     = ref $p0;

	# Map the obvious cases
	return $OBVIOUS_CLASS{$c0}   if defined $OBVIOUS_CLASS{$c0};
	return $OBVIOUS_CONTENT{$p0} if defined $OBVIOUS_CONTENT{$p0};

	# Most of the time after an operator, we are an operand
	return 'operand' if $p0->isa('PPI::Token::Operator');

	# If there's NOTHING, it's operand
	return 'operand' if $p0->content eq '';

	# Otherwise, we don't know
	return ''
}

1;

#line 1002
