#line 1
package PPI::Normal::Standard;

#line 17

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.215';
}





#####################################################################
# Configuration and Registration

my @METHODS = (
	remove_insignificant_elements => 1,
	remove_useless_attributes     => 1,
	remove_useless_pragma         => 2,
	remove_statement_separator    => 2,
	remove_useless_return         => 2,
);

sub import {
	PPI::Normal->register(
		map { /\D/ ? "PPI::Normal::Standard::$_" : $_ } @METHODS
	) or die "Failed to register PPI::Normal::Standard transforms";
}





#####################################################################
# Level 1 Transforms

# Remove all insignificant elements
sub remove_insignificant_elements {
	my $Document = shift;
	$Document->prune( sub { ! $_[1]->significant } );
}

# Remove custom attributes that are not relevant to normalization
sub remove_useless_attributes {
	my $Document = shift;
	delete $Document->{tab_width};

	### FIXME - Add support for more things
}





#####################################################################
# Level 2 Transforms

# Remove version dependencies and pragma
my $remove_pragma = map { $_ => 1 } qw{
	strict warnings diagnostics	less
	};
sub remove_useless_pragma {
	my $Document = shift;
	$Document->prune( sub {
		return '' unless $_[1]->isa('PPI::Statement::Include');
		return 1  if     $_[1]->version;
		return 1  if     $remove_pragma->{$_[1]->pragma};
		'';
	} );
}

# Remove all semi-colons at the end of statements
sub remove_statement_separator {
	my $Document = shift;
	$Document->prune( sub {
		$_[1]->isa('PPI::Token::Structure') or return '';
		$_[1]->content eq ';'               or return '';
		my $stmt = $_[1]->parent            or return '';
		$stmt->isa('PPI::Statement')        or return '';
		$_[1]->next_sibling                and return '';
		1;
	} );
}

# In any block, the "return" in the last statement is not
# needed if there is only one and only one thing after the
# return.
sub remove_useless_return {
	my $Document = shift;
	$Document->prune( sub {
		$_[1]->isa('PPI::Token::Word')       or return '';
		$_[1]->content eq 'return'           or return '';
		my $stmt = $_[1]->parent             or return '';
		$stmt->isa('PPI::Statement::Break')  or return '';
		$stmt->children == 2                 or return '';
		$stmt->next_sibling                 and return '';
		my $block = $stmt->parent            or return '';
		$block->isa('PPI::Structure::Block') or return '';
		1;
	} );
}

1;

#line 142
