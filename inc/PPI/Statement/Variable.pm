#line 1
package PPI::Statement::Variable;

#line 39

use strict;
use Params::Util               qw{_INSTANCE};
use PPI::Statement::Expression ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement::Expression';
}

#line 61

sub type {
	my $self = shift;

	# Get the first significant child
	my @schild = grep { $_->significant } $self->children;

	# Ignore labels
	shift @schild if _INSTANCE($schild[0], 'PPI::Token::Label');

	# Get the type
	(_INSTANCE($schild[0], 'PPI::Token::Word') and $schild[0]->content =~ /^(my|local|our|state)$/)
		? $schild[0]->content
		: undef;
}

#line 123

sub variables {
	map { $_->canonical } $_[0]->symbols;
}

#line 136

sub symbols {
	my $self = shift;

	# Get the children we care about
	my @schild = grep { $_->significant } $self->children;
	shift @schild if _INSTANCE($schild[0], 'PPI::Token::Label');

	# If the second child is a symbol, return its name
	if ( _INSTANCE($schild[1], 'PPI::Token::Symbol') ) {
		return $schild[1];
	}

	# If it's a list, return as a list
	if ( _INSTANCE($schild[1], 'PPI::Structure::List') ) {
		my $Expression = $schild[1]->schild(0);
		$Expression and
		$Expression->isa('PPI::Statement::Expression') or return ();

		# my and our are simpler than local
		if (
			$self->type eq 'my'
			or
			$self->type eq 'our'
			or
			$self->type eq 'state'
		) {
			return grep {
				$_->isa('PPI::Token::Symbol')
			} $Expression->schildren;
		}

		# Local is much more icky (potentially).
		# Not that we are actually going to deal with it now,
		# but having this seperate is likely going to be needed
		# for future bug reports about local() things.

		# This is a slightly better way to check.
		return grep {
			$self->_local_variable($_)
		} grep {
			$_->isa('PPI::Token::Symbol')
		} $Expression->schildren;
	}

	# erm... this is unexpected
	();
}

sub _local_variable {
	my ($self, $el) = @_;

	# The last symbol should be a variable
	my $n = $el->snext_sibling or return 1;
	my $p = $el->sprevious_sibling;
	if ( ! $p or $p eq ',' ) {
		# In the middle of a list
		return 1 if $n eq ',';

		# The first half of an assignment
		return 1 if $n eq '=';
	}

	# Lets say no for know... additional work
	# should go here.
	return '';
}

1;

#line 231
