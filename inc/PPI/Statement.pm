#line 1
package PPI::Statement;

#line 147

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

use PPI::Statement::Break          ();
use PPI::Statement::Compound       ();
use PPI::Statement::Data           ();
use PPI::Statement::End            ();
use PPI::Statement::Expression     ();
use PPI::Statement::Include        ();
use PPI::Statement::Null           ();
use PPI::Statement::Package        ();
use PPI::Statement::Scheduled      ();
use PPI::Statement::Sub            ();
use PPI::Statement::Given         ();
use PPI::Statement::UnmatchedBrace ();
use PPI::Statement::Unknown        ();
use PPI::Statement::Variable       ();
use PPI::Statement::When           ();

# "Normal" statements end at a statement terminator ;
# Some are not, and need the more rigorous _continues to see
# if we are at an implicit statement boundary.
sub __LEXER__normal { 1 }





#####################################################################
# Constructor

sub new {
	my $class = shift;
	if ( ref $class ) {
		PPI::Exception->throw;
	}

	# Create the object
	my $self = bless { 
		children => [],
	}, $class;

	# If we have been passed what should be an initial token, add it
	my $token = shift;
	if ( _INSTANCE($token, 'PPI::Token') ) {
		# Inlined $self->__add_element(shift);
		Scalar::Util::weaken(
			$_PARENT{Scalar::Util::refaddr $token} = $self
		);
		push @{$self->{children}}, $token;
	}

	$self;
}

#line 229

sub label {
	my $first = shift->schild(1) or return '';
	$first->isa('PPI::Token::Label')
		? substr($first, 0, length($first) - 1)
		: '';
}

#line 289

# Yes, this is doing precisely what it's intending to prevent
# client code from doing.  However, since it's here, if the
# implementation changes, code outside PPI doesn't care.
sub specialized {
	__PACKAGE__ ne ref $_[0];
}

#line 310

sub stable {
	die "The ->stable method has not yet been implemented";	
}





#####################################################################
# PPI::Element Methods

# Is the statement complete.
# By default for a statement, we need a semi-colon at the end.
sub _complete {
	my $self = shift;
	my $semi = $self->schild(-1);
	return !! (
		defined $semi
		and
		$semi->isa('PPI::Token::Structure')
		and
		$semi->content eq ';'
	);
}

# You can insert either a statement or a non-significant token.
sub insert_before {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Statement') ) {
		return $self->__insert_before($Element);
	} elsif ( $Element->isa('PPI::Token') and ! $Element->significant ) {
		return $self->__insert_before($Element);
	}
	'';
}

# As above, you can insert a statement, or a non-significant token
sub insert_after {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Statement') ) {
		return $self->__insert_after($Element);
	} elsif ( $Element->isa('PPI::Token') and ! $Element->significant ) {
		return $self->__insert_after($Element);
	}
	'';
}

1;

#line 387
