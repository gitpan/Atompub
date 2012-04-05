#line 1
package PPI::Token::Symbol;

#line 28
 
use strict;
use Params::Util qw{_INSTANCE};
use PPI::Token   ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# PPI::Token::Symbol Methods

#line 59

sub canonical {
	my $symbol = shift->content;
	$symbol =~ s/\s+//;
	$symbol =~ s/(?<=[\$\@\%\&\*])::/main::/;
	$symbol =~ s/\'/::/g;
	$symbol;
}

#line 83

my %cast_which_trumps_braces = map { $_ => 1 } qw{ $ @ };

sub symbol {
	my $self   = shift;
	my $symbol = $self->canonical;

	# Immediately return the cases where it can't be anything else
	my $type = substr( $symbol, 0, 1 );
	return $symbol if $type eq '%';
	return $symbol if $type eq '&';

	# Unless the next significant Element is a structure, it's correct.
	my $after  = $self->snext_sibling;
	return $symbol unless _INSTANCE($after, 'PPI::Structure');

	# Process the rest for cases where it might actually be something else
	my $braces = $after->braces;
	return $symbol unless defined $braces;
	if ( $type eq '$' ) {

		# If it is cast to '$' or '@', that trumps any braces
		my $before = $self->sprevious_sibling;
		return $symbol if $before &&
			$before->isa( 'PPI::Token::Cast' ) &&
			$cast_which_trumps_braces{ $before->content };

		# Otherwise the braces rule
		substr( $symbol, 0, 1, '@' ) if $braces eq '[]';
		substr( $symbol, 0, 1, '%' ) if $braces eq '{}';

	} elsif ( $type eq '@' ) {
		substr( $symbol, 0, 1, '%' ) if $braces eq '{}';

	}

	$symbol;
}

#line 132

sub raw_type {
	substr( $_[0]->content, 0, 1 );
}

#line 147

sub symbol_type {
	substr( $_[0]->symbol, 0, 1 );
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t = $_[1];

	# Suck in till the end of the symbol
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $line =~ /^([\w:\']+)/ ) {
		$t->{token}->{content} .= $1;
		$t->{line_cursor}      += length $1;
	}

	# Handle magic things
	my $content = $t->{token}->{content};	
	if ( $content eq '@_' or $content eq '$_' ) {
		$t->{class} = $t->{token}->set_class( 'Magic' );
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	# Shortcut for most of the X:: symbols
	if ( $content eq '$::' ) {
		# May well be an alternate form of a Magic
		my $nextchar = substr( $t->{line}, $t->{line_cursor}, 1 );
		if ( $nextchar eq '|' ) {
			$t->{token}->{content} .= $nextchar;
			$t->{line_cursor}++;
			$t->{class} = $t->{token}->set_class( 'Magic' );
		}
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}
	if ( $content =~ /^[\$%*@&]::(?:[^\w]|$)/ ) {
		my $current = substr( $content, 0, 3, '' );
		$t->{token}->{content} = $current;
		$t->{line_cursor} -= length( $content );
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}
	if ( $content =~ /^(?:\$|\@)\d+/ ) {
		$t->{class} = $t->{token}->set_class( 'Magic' );
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	# Trim off anything we oversucked...
	$content =~ /^(
		[\$@%&*]
		(?: : (?!:) | # Allow single-colon non-magic vars
			(?: \w+ | \' (?!\d) \w+ | \:: \w+ )
			(?:
				# Allow both :: and ' in namespace separators
				(?: \' (?!\d) \w+ | \:: \w+ )
			)*
			(?: :: )? # Technically a compiler-magic hash, but keep it here
		)
	)/x or return undef;
	unless ( length $1 eq length $content ) {
		$t->{line_cursor} += length($1) - length($content);
		$t->{token}->{content} = $1;
	}

	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 241
