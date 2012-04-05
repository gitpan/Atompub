#line 1
package PPI::Statement::Sub;

#line 31

use strict;
use List::Util     ();
use Params::Util   qw{_INSTANCE};
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

# Lexer clue
sub __LEXER__normal { '' }

sub _complete {
	my $child = $_[0]->schild(-1);
	return !! (
		defined $child
		and
		$child->isa('PPI::Structure::Block')
		and
		$child->complete
	);
}





#####################################################################
# PPI::Statement::Sub Methods

#line 74

sub name {
	my $self = shift;

	# The second token should be the name, if we have one
	my $Token = $self->schild(1) or return '';
	$Token->isa('PPI::Token::Word') and $Token->content;
}

#line 94

sub prototype {
	my $self      = shift;
	my $Prototype = List::Util::first {
		_INSTANCE($_, 'PPI::Token::Prototype')
	} $self->children;
	defined($Prototype) ? $Prototype->prototype : '';
}

#line 115

sub block {
	my $self = shift;
	my $lastchild = $self->schild(-1) or return '';
	$lastchild->isa('PPI::Structure::Block') and $lastchild;
}

#line 133

sub forward {
	! shift->block;
}

#line 153

sub reserved {
	my $self = shift;
	my $name = $self->name or return '';
	$name eq uc $name;
}

1;

#line 187
