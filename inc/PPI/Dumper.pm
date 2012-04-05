#line 1
package PPI::Dumper;

#line 33

use strict;
use Params::Util qw{_INSTANCE};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}





#####################################################################
# Constructor

#line 105

sub new {
	my $class   = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;

	# Create the object
	my $self = bless {
		root    => $Element,
		display => {
			memaddr    => '', # Show the refaddr of the item
			indent     => 2,  # Indent the structures
			class      => 1,  # Show the object class
			content    => 1,  # Show the object contents
			whitespace => 1,  # Show whitespace tokens
			comments   => 1,  # Show comment tokens
			locations  => 0,  # Show token locations
			},
		}, $class;

	# Handle the options
	my %options = map { lc $_ } @_;
	foreach ( keys %{$self->{display}} ) {
		if ( exists $options{$_} ) {
			if ( $_ eq 'indent' ) {
				$self->{display}->{indent} = $options{$_};
			} else {
				$self->{display}->{$_} = !! $options{$_};
			}
		}
	}

	$self->{indent_string} = join '', (' ' x $self->{display}->{indent});

	$self;
}





#####################################################################
# Main Interface Methods

#line 157

sub print {
	CORE::print(shift->string);
}

#line 172

sub string {
	my $array_ref = shift->_dump or return undef;
	join '', map { "$_\n" } @$array_ref;
}

#line 189

sub list {
	my $array_ref = shift->_dump or return ();
	@$array_ref;
}





#####################################################################
# Generation Support Methods

sub _dump {
	my $self    = ref $_[0] ? shift : shift->new(shift);
	my $Element = _INSTANCE($_[0], 'PPI::Element') ? shift : $self->{root};
	my $indent  = shift || '';
	my $output  = shift || [];

	# Print the element if needed
	my $show = 1;
	if ( $Element->isa('PPI::Token::Whitespace') ) {
		$show = 0 unless $self->{display}->{whitespace};
	} elsif ( $Element->isa('PPI::Token::Comment') ) {
		$show = 0 unless $self->{display}->{comments};
	}
	push @$output, $self->_element_string( $Element, $indent ) if $show;

	# Recurse into our children
	if ( $Element->isa('PPI::Node') ) {
		my $child_indent = $indent . $self->{indent_string};
		foreach my $child ( @{$Element->{children}} ) {
			$self->_dump( $child, $child_indent, $output );
		}
	}

	$output;
}

sub _element_string {
	my $self    = ref $_[0] ? shift : shift->new(shift);
	my $Element = _INSTANCE($_[0], 'PPI::Element') ? shift : $self->{root};
	my $indent  = shift || '';
	my $string  = '';

	# Add the memory location
	if ( $self->{display}->{memaddr} ) {
		$string .= $Element->refaddr . '  ';
	}
        
        # Add the location if such exists
	if ( $self->{display}->{locations} ) {
		my $loc_string;
		if ( $Element->isa('PPI::Token') ) {
			my $location = $Element->location;
			if ($location) {
				$loc_string = sprintf("[ % 4d, % 3d, % 3d ] ", @$location);
			}
		}
		# Output location or pad with 20 spaces
		$string .= $loc_string || " " x 20;
	}
        
	# Add the indent
	if ( $self->{display}->{indent} ) {
		$string .= $indent;
	}

	# Add the class name
	if ( $self->{display}->{class} ) {
		$string .= ref $Element;
	}

	if ( $Element->isa('PPI::Token') ) {
		# Add the content
		if ( $self->{display}->{content} ) {
			my $content = $Element->content;
			$content =~ s/\n/\\n/g;
			$content =~ s/\t/\\t/g;
			$string .= "  \t'$content'";
		}

	} elsif ( $Element->isa('PPI::Structure') ) {
		# Add the content
		if ( $self->{display}->{content} ) {
			my $start = $Element->start
				? $Element->start->content
				: '???';
			my $finish = $Element->finish
				? $Element->finish->content
				: '???';
			$string .= "  \t$start ... $finish";
		}
	}
	
	$string;
}

1;

#line 310
