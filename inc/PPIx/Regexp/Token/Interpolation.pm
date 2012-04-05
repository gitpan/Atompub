#line 1
#line 28

package PPIx::Regexp::Token::Interpolation;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Code };

use PPI::Document;
use PPIx::Regexp::Constant qw{ COOKIE_CLASS TOKEN_LITERAL MINIMUM_PERL };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# This can be quantified because it might interpolate a quantifiable
# token. Of course, it might not, but we need to be permissive here.
# sub can_be_quantified { return };

# We overrode this in PPIx::Regexp::Token::Code, since (?{...}) did not
# appear until Perl 5.5. But interpolation has been there since the
# beginning, so we have to override again. Sigh.
sub perl_version_introduced {
#   my ( $self ) = @_;
    return MINIMUM_PERL;
}


#line 69

sub ppi {
    my ( $self ) = @_;
    if ( exists $self->{ppi} ) {
	return $self->{ppi};
    } elsif ( exists $self->{content} ) {
	( my $code = $self->{content} ) =~
	    s/ \A ( [\@\$] ) [{] ( .* ) [}] \z /$1$2/smx;
	return ( $self->{ppi} = PPI::Document->new(
		\$code, readonly => 1 ) );
    } else {
	return;
    }
}


# Match the beginning of an interpolation.

my $interp_re =
	qr{ \A (?: [\@\$]? \$ [-\w&`'+^./\\";%=~:?!\@\$<>\[\]\{\},#] |
		   \@ [\w\{] )
	}smx;

# Match bracketed interpolation

my $brkt_interp_re =
    qr{ \A (?: [\@\$] \$* [#]? \$* [\{] (?: [][\-&`'+,^./\\";%=:?\@\$<>,#] |
		\^? \w+ (?: :: \w+ )* ) [\}] |
	    \@ [\{] \w+ (?: :: \w+ )* [\}] )
    }smx;

# We pull out the logic of finding and dealing with the interpolation
# into a separate subroutine because if we fail to find an interpolation
# we want to do something with the sigils.

my %allow_subscript_based_on_cast_symbol = (
    q<$#>	=> 0,
    q<$>	=> 1,
    q<@>	=> 1,
);

sub _interpolation {
    my ( $class, $tokenizer, $character, $in_regexp ) = @_;

    # If the regexp does not interpolate, bail now.
    $tokenizer->interpolates() or return;

    # If we're a bracketed interpolation, just accept it
    if ( my $len = $tokenizer->find_regexp( $brkt_interp_re ) ) {
	return $len;
    }

    # Make sure we start off plausably
    $tokenizer->find_regexp( $interp_re )
	or return;

    # See if PPI can figure out what we have
    my $doc = $tokenizer->ppi_document()
	or return;

    # Get the first statement to work on.
    my $stmt = $doc->find_first( 'PPI::Statement' )
	or return;

    my @accum;	# The elements of the interpolation
    my $allow_subscript;	# Assume no subscripts allowed

    # Find the beginning of the interpolation
    my $next = $stmt->schild( 0 ) or return;

    # The interpolation should start with
    if ( $next->isa( 'PPI::Token::Symbol' ) ) {

	# A symbol
	push @accum, $next;
	$allow_subscript = 1;	# Subscripts are allowed

    } elsif ( $next->isa( 'PPI::Token::Cast' ) ) {

	# Or a cast followed by a block
	push @accum, $next;
	$next = $next->next_sibling() or return;
	if ( $next->isa( 'PPI::Token::Symbol' ) ) {
	    defined (
		$allow_subscript =
		    $allow_subscript_based_on_cast_symbol{
			$accum[-1]->content()
		    }
	    ) or return;
	    push @accum, $next;
	} elsif ( $next->isa( 'PPI::Structure::Block' ) ) {

#line 174

	    push @accum, $next;
	} else {
	    return;
	}

    } elsif ( $next->isa( 'PPI::Token::ArrayIndex' ) ) {

	# Or an array index
	push @accum, $next;

    } else {

	# None others need apply.
	return;

    }

    # The interpolation _may_ be subscripted. If so ...
    {

	# Only accept a subscript if wanted and available
	$allow_subscript and $next = $next->snext_sibling() or last;

	# Accept an optional dereference operator.
	my @subscr;
	if ( $next->isa( 'PPI::Token::Operator' ) ) {
	    $next->content() eq '->' or last;
	    push @subscr, $next;
	    $next = $next->next_sibling() or last;
	}

	# Accept only a subscript
	$next->isa( 'PPI::Structure::Subscript' ) or last;

	# The subscript must have a closing delimiter.
	$next->finish() or last;

	# If we are in a regular expression rather than a replacement
	# string, screen the subscript for content, since [] could be a
	# character class, and {} could be a quantifier. The perlop docs
	# say that Perl applies undocumented heuristics subject to
	# change without notice to figure this out. So we do our poor
	# best to be heuristical and undocumented.
	not $in_regexp or $class->_subscript( $next ) or last;

	# If we got this far, accept the subscript and try for another
	# one.
	push @accum, @subscr, $next;
	redo;
    }

    # Compute the length of all the PPI elements accumulated, and return
    # it.
    my $length = 0;
    foreach ( @accum ) {
	$length += ref $_ ? length $_->content() : $_;
    }
    return $length;
}

{

    my %allowed = (
	'[' => '_square',
	'{' => '_curly',
    );

    sub _subscript {
	my ( $class, $struct ) = @_;

	# We expect to have a left delimiter, which is either a '[' or a
	# '{'.
	my $left = $struct->start() or return;
	my $lc = $left->content();
	my $handler = $allowed{$lc} or return;

	# We expect a single child, which is a PPI::Statement
	( my @kids = $struct->schildren() ) == 1 or return;
	$kids[0]->isa( 'PPI::Statement' ) or return;

	# We expect the statement to have at least one child.
	( @kids = $kids[0]->schildren() ) or return;

	return $class->$handler( @kids );

    }

}

# Return true if we think a curly-bracketed subscript is really a
# subscript, rather than a quantifier.
sub _curly {
    my ( $class, @kids ) = @_;

    # If the first child is a word, and either it is an only child or
    # the next child is the fat comma operator, we accept it as a
    # subscript.
    if ( $kids[0]->isa( 'PPI::Token::Word' ) ) {
	@kids == 1 and return 1;
	$kids[1]->isa( 'PPI::Token::Operator' )
	    and $kids[1]->content() eq '=>'
	    and return 1;
    }

    # If we have exactly one child which is a symbol, we accept it as a
    # subscript.
    @kids == 1
	and $kids[0]->isa( 'PPI::Token::Symbol' )
	and return 1;

    # We reject anything else.
    return;
}

# Return true if we think a square-bracketed subscript is really a
# subscript, rather than a character class.
sub _square {
    my ( $class, @kids ) = @_;

    # We expect to have either a number or a symbol as the first
    # element.
    $kids[0]->isa( 'PPI::Token::Number' ) and return 1;
    $kids[0]->isa( 'PPI::Token::Symbol' ) and return 1;

    # Anything else is rejected.
    return;
}

# Alternate classes for the sigils, depending on whether we are in a
# character class (index 1) or not (index 0).
my %sigil_alternate = (
    '$' => [ 'PPIx::Regexp::Token::Assertion', TOKEN_LITERAL ],
    '@' => [ TOKEN_LITERAL, TOKEN_LITERAL ],
);

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    exists $sigil_alternate{$character} or return;

    if ( my $accept = _interpolation( $class, $tokenizer, $character, 1 ) ) {
	return $accept;
    }

    my $alternate = $sigil_alternate{$character} or return;
    return $tokenizer->make_token(
	1, $alternate->[$tokenizer->cookie( COOKIE_CLASS ) ? 1 : 0 ] );

}

sub __PPIX_TOKENIZER__repl {
    my ( $class, $tokenizer, $character ) = @_;

    exists $sigil_alternate{$character} or return;

    if ( my $accept = _interpolation( $class, $tokenizer, $character, 0 ) ) {
	return $accept;
    }

    return $tokenizer->make_token( 1, TOKEN_LITERAL );

}

1;

__END__

#line 428

# ex: set textwidth=72 :
