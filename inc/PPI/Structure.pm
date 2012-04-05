#line 1
package PPI::Structure;

#line 89

use strict;
use Scalar::Util   ();
use Params::Util   qw{_INSTANCE};
use PPI::Node      ();
use PPI::Exception ();

use vars qw{$VERSION @ISA *_PARENT};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Node';
	*_PARENT = *PPI::Element::_PARENT;
}

use PPI::Structure::Block       ();
use PPI::Structure::Condition   ();
use PPI::Structure::Constructor ();
use PPI::Structure::For         ();
use PPI::Structure::Given       ();
use PPI::Structure::List        ();
use PPI::Structure::Subscript   ();
use PPI::Structure::Unknown     ();
use PPI::Structure::When        ();





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $Token = PPI::Token::__LEXER__opens($_[0]) ? shift : return undef;

	# Create the object
	my $self = bless {
		children => [],
		start    => $Token,
		}, $class;

	# Set the start braces parent link
	Scalar::Util::weaken(
		$_PARENT{Scalar::Util::refaddr $Token} = $self
	);

	$self;
}





#####################################################################
# PPI::Structure API methods

#line 164

sub start  { $_[0]->{start}  }

#line 180

sub finish { $_[0]->{finish} }

#line 195

sub braces {
	my $self = $_[0]->{start} ? shift : return undef;
	return {
		'[' => '[]',
		'(' => '()',
		'{' => '{}',
	}->{ $self->{start}->{content} };
}

#line 218

sub complete {
	!! ($_[0]->{start} and $_[0]->{finish});
}





#####################################################################
# PPI::Node overloaded methods

# For us, the "elements" concept includes the brace tokens
sub elements {
	my $self = shift;

	if ( wantarray ) {
		# Return a list in array context
		return ( $self->{start} || (), @{$self->{children}}, $self->{finish} || () );
	} else {
		# Return the number of elements in scalar context.
		# This is memory-cheaper than creating another big array
		return scalar(@{$self->{children}})
			+ ($self->{start}  ? 1 : 0)
			+ ($self->{finish} ? 1 : 0);
	}
}

# For us, the first element is probably the opening brace
sub first_element {
	# Technically, if we have no children and no opening brace,
	# then the first element is the closing brace.
	$_[0]->{start} or $_[0]->{children}->[0] or $_[0]->{finish};
}

# For us, the last element is probably the closing brace
sub last_element {
	# Technically, if we have no children and no closing brace,
	# then the last element is the opening brace
	$_[0]->{finish} or $_[0]->{children}->[-1] or $_[0]->{start};
}

# Location is same as the start token, if any
sub location {
	my $self  = shift;
	my $first = $self->first_element or return undef;
	$first->location;
}





#####################################################################
# PPI::Element overloaded methods

# Get the full set of tokens, including start and finish
sub tokens {
	my $self = shift;
	my @tokens = (
		$self->{start}  || (),
		$self->SUPER::tokens(@_),
		$self->{finish} || (),
		);
	@tokens;
}

# Like the token method ->content, get our merged contents.
# This will recurse downwards through everything
### Reimplement this using List::Utils stuff
sub content {
	my $self = shift;
	my $content = $self->{start} ? $self->{start}->content : '';
	foreach my $child ( @{$self->{children}} ) {
		$content .= $child->content;
	}
	$content .= $self->{finish}->content if $self->{finish};
	$content;
}

# Is the structure completed
sub _complete {
	!! ( defined $_[0]->{finish} );
}

# You can insert either another structure, or a token
sub insert_before {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_before($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_before($Element);
	}
	'';
}

# As above, you can insert either another structure, or a token
sub insert_after {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_after($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_after($Element);
	}
	'';
}

1;

#line 350
