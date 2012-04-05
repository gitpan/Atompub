#line 1
package PPI::Statement::Scheduled;

#line 54

use strict;
use PPI::Statement::Sub ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement::Sub';
}

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

#line 85

sub type {
	my $self     = shift;
	my @children = $self->schildren or return undef;
	$children[0]->content eq 'sub'
		? $children[1]->content
		: $children[0]->content;
}

# This is actually the same as Sub->name
sub name {
	shift->type(@_);
}

1;

#line 126
