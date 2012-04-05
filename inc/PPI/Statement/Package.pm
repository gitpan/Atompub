#line 1
package PPI::Statement::Package;

#line 65

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';
}

#line 90

sub namespace {
	my $self = shift;
	my $namespace = $self->schild(1) or return '';
	$namespace->isa('PPI::Token::Word')
		? $namespace->content
		: '';
}

#line 116

sub file_scoped {
	my $self     = shift;
	my ($Parent, $Document) = ($self->parent, $self->top);
	$Parent and $Document and $Parent == $Document
	and $Document->isa('PPI::Document')
	and ! $Document->isa('PPI::Document::Fragment');
}

1;

#line 148
