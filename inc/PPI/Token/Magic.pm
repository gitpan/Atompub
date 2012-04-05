#line 1
package PPI::Token::Magic;

#line 42

use strict;
use PPI::Token::Symbol ();
use PPI::Token::Unknown ();

use vars qw{$VERSION @ISA %magic};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token::Symbol';

	# Magic variables taken from perlvar.
	# Several things added separately to avoid warnings.
	foreach ( qw{
		$1 $2 $3 $4 $5 $6 $7 $8 $9
		$_ $& $` $' $+ @+ %+ $* $. $/ $|
		$\\ $" $; $% $= $- @- %- $)
		$~ $^ $: $? $! %! $@ $$ $< $>
		$( $0 $[ $] @_ @*

		$^L $^A $^E $^C $^D $^F $^H
		$^I $^M $^N $^O $^P $^R $^S
		$^T $^V $^W $^X %^H

		$::|
	}, '$}', '$,', '$#', '$#+', '$#-' ) {
		$magic{$_} = 1;
	}
}

#line 111

sub __TOKENIZER__on_char {
	my $t = $_[1];

	# $c is the candidate new content
	my $c = $t->{token}->{content} . substr( $t->{line}, $t->{line_cursor}, 1 );

	# Do a quick first test so we don't have to do more than this one.
	# All of the tests below match this one, so it should provide a
	# small speed up. This regex should be updated to match the inside
	# tests if they are changed.
	if ( $c =~ /^  \$  .*  [  \w  :  \$  \{  ]  $/x ) {

		if ( $c =~ /^(\$(?:\_[\w:]|::))/ or $c =~ /^\$\'[\w]/ ) {
			# If and only if we have $'\d, it is not a
			# symbol. (this was apparently a concious choice)
			# Note that $::0 on the other hand is legal
			if ( $c =~ /^\$\'\d$/ ) {
				# In this case, we have a magic plus a digit.
				# Save the CURRENT token, and rerun the on_char
				return $t->_finalize_token->__TOKENIZER__on_char( $t );
			}

			# A symbol in the style $_foo or $::foo or $'foo.
			# Overwrite the current token
			$t->{class} = $t->{token}->set_class('Symbol');
			return PPI::Token::Symbol->__TOKENIZER__on_char( $t );
		}

		if ( $c =~ /^\$\$\w/ ) {
			# This is really a scalar dereference. ( $$foo )
			# Add the current token as the cast...
			$t->{token} = PPI::Token::Cast->new( '$' );
			$t->_finalize_token;

			# ... and create a new token for the symbol
			return $t->_new_token( 'Symbol', '$' );
		}

		if ( $c eq '$${' ) {
			# This _might_ be a dereference of one of the
			# control-character symbols.
			my $line = substr $t->{line}, $t->{line_cursor} + 1;
			if ( $line =~ m/$PPI::Token::Unknown::CURLY_SYMBOL/ ) {
				# This is really a dereference. ( $${^_foo} )
				# Add the current token as the cast...
				$t->{token} = PPI::Token::Cast->new( '$' );
				$t->_finalize_token;

				# ... and create a new token for the symbol
				return $t->_new_token( 'Magic', '$' );
			}
		}

		if ( $c eq '$#$' or $c eq '$#{' ) {
			# This is really an index dereferencing cast, although
			# it has the same two chars as the magic variable $#.
			$t->{class} = $t->{token}->set_class('Cast');
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		if ( $c =~ /^(\$\#)\w/ ) {
			# This is really an array index thingy ( $#array )
			$t->{token} = PPI::Token::ArrayIndex->new( "$1" );
			return PPI::Token::ArrayIndex->__TOKENIZER__on_char( $t );
		}

		if ( $c =~ /^\$\^\w+$/o ) {
			# It's an escaped char magic... maybe ( like $^M )
			my $next = substr( $t->{line}, $t->{line_cursor}+1, 1 ); # Peek ahead
			if ($magic{$c} && (!$next || $next !~ /\w/)) {
				$t->{token}->{content} = $c;
				$t->{line_cursor}++;
			} else {
				# Maybe it's a long magic variable like $^WIDE_SYSTEM_CALLS
				return 1;
			}
		}

		if ( $c =~ /^\$\#\{/ ) {
			# The $# is actually a case, and { is its block
			# Add the current token as the cast...
			$t->{token} = PPI::Token::Cast->new( '$#' );
			$t->_finalize_token;

			# ... and create a new token for the block
			return $t->_new_token( 'Structure', '{' );
		}
	} elsif ($c =~ /^%\^/) {
		return 1 if $c eq '%^';
		# It's an escaped char magic... maybe ( like %^H )
		if ($magic{$c}) {
			$t->{token}->{content} = $c;
			$t->{line_cursor}++;
		} else {
			# Back off, treat '%' as an operator
			chop $t->{token}->{content};
			bless $t->{token}, $t->{class} = 'PPI::Token::Operator';
			$t->{line_cursor}--;
		}
	}

	if ( $magic{$c} ) {
		# $#+ and $#-
		$t->{line_cursor} += length( $c ) - length( $t->{token}->{content} );
		$t->{token}->{content} = $c;
	} else {
		my $line = substr( $t->{line}, $t->{line_cursor} );
		if ( $line =~ /($PPI::Token::Unknown::CURLY_SYMBOL)/ ) {
			# control character symbol (e.g. ${^MATCH})
			$t->{token}->{content} .= $1;
			$t->{line_cursor}      += length $1;
		}
	}

	# End the current magic token, and recheck
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

# Our version of canonical is plain simple
sub canonical { $_[0]->content }

1;

#line 256
