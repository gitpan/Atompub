#line 1
package PPI::Statement::Compound;

#line 51

use strict;
use PPI::Statement ();

use vars qw{$VERSION @ISA %TYPES};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Statement';

	# Keyword type map
	%TYPES = (
		'if'      => 'if',
		'unless'  => 'if',
		'while'   => 'while',
		'until'   => 'while',
		'for'     => 'for',
		'foreach' => 'foreach',
	);
}

# Lexer clues
sub __LEXER__normal { '' }





#####################################################################
# PPI::Statement::Compound analysis methods

#line 189

sub type {
	my $self    = shift;
	my $p       = 0; # Child position
	my $Element = $self->schild($p) or return undef;

	# A labelled statement
	if ( $Element->isa('PPI::Token::Label') ) {
		$Element = $self->schild(++$p) or return 'label';
	}

	# Most simple cases
	my $content = $Element->content;
	if ( $content =~ /^for(?:each)?\z/ ) {
		$Element = $self->schild(++$p) or return $content;
		if ( $Element->isa('PPI::Token') ) {
			return 'foreach' if $Element->content =~ /^my|our|state\z/;
			return 'foreach' if $Element->isa('PPI::Token::Symbol');
			return 'foreach' if $Element->isa('PPI::Token::QuoteLike::Words');
		}
		if ( $Element->isa('PPI::Structure::List') ) {
			return 'foreach';
		}
		return 'for';
	}
	return $TYPES{$content} if $Element->isa('PPI::Token::Word');
	return 'continue'       if $Element->isa('PPI::Structure::Block');

	# Unknown (shouldn't exist?)
	undef;
}





#####################################################################
# PPI::Node Methods

sub scope { 1 }





#####################################################################
# PPI::Element Methods

sub _complete {
	my $self = shift;
	my $type = $self->type or die "Illegal compound statement type";

	# Check the different types of compound statements
	if ( $type eq 'if' ) {
		# Unless the last significant child is a complete
		# block, it must be incomplete.
		my $child = $self->schild(-1) or return '';
		$child->isa('PPI::Structure') or return '';
		$child->braces eq '{}'        or return '';
		$child->_complete             or return '';

		# It can STILL be
	} elsif ( $type eq 'while' ) {
		die "CODE INCOMPLETE";
	} else {
		die "CODE INCOMPLETE";
	}
}

1;

#line 285
