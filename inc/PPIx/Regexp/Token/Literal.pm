#line 1
#line 28

package PPIx::Regexp::Token::Literal;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ COOKIE_CLASS MINIMUM_PERL };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub perl_version_introduced {
    my ( $self ) = @_;
    exists $self->{perl_version_introduced}
	and return $self->{perl_version_introduced};
    ( my $content = $self->content() ) =~ m/ \A \\ o /smx
	and return ( $self->{perl_version_introduced} = '5.013003' );
    $content =~ m/ \A \\ N [{] U [+] /smx
	and return ( $self->{perl_version_introduced} = '5.008' );
    $content =~ m/ \A \\ x [{] /smx	# }
	and return ( $self->{perl_version_introduced} = '5.006' );
    $content =~ m/ \A \\ N /smx
	and return ( $self->{perl_version_introduced} = '5.006001' );
    return ( $self->{perl_version_introduced} = MINIMUM_PERL );
}

# Some characters may or may not be literals depending on whether we are
# inside a character class. The following hash identifies those
# characters and says what we should return when outside (index 0) or
# inside (index 1) a character class, as judged by the presence of the
# relevant cookie.
my %double_agent = (
    '.' => [ undef, 1 ],
    '*' => [ undef, 1 ],
    '?' => [ undef, 1 ],
    '+' => [ undef, 1 ],
    '-' => [ 1, undef ],
    '|' => [ undef, 1 ],
);

# These are the characters that other external tokenizers need to see,
# or at least that we need to take a closer look at. All others can be
# unconditionally made into single-character literals.
my %extra_ordinary = map { $_ => 1 }
    split qr{}smx, '$@*+?.\\(){}[]^|-#';
#   $ -> Token::Interpolation, Token::Assertion
#   @ -> Token::Interpolation
#   * -> Token::Quantifier
#   + ? -> Token::Quantifier, Token::Greediness
#   . -> Token::CharClass::Simple
#   \ -> Token::Control, Token::CharClass::Simple, Token::Assertion,
#        Token::Backreference
#   ( ) { } [ ] -> Token::Structure
#   ^ -> Token::Assertion
#   | - -> Token::Operator

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character, $char_type ) = @_;

    # Handle the characters that may or may not be literals depending on
    # whether or not we are in a character class.
    if ( my $class = $double_agent{$character} ) {
	my $inx = $tokenizer->cookie( COOKIE_CLASS ) ? 1 : 0;
	return $class->[$inx];
    }

    # If /x is in effect _and_ we are not inside a character class, \s
    # is whitespace, and '#' introduces a comment. Otherwise they are
    # both literals.
    if ( $tokenizer->modifier( 'x' ) &&
	! $tokenizer->cookie( COOKIE_CLASS ) ) {
	my $accept;
	$accept = $tokenizer->find_regexp( qr{ \A \s+ }smx )
	    and return $tokenizer->make_token(
		$accept, 'PPIx::Regexp::Token::Whitespace' );
	$accept = $tokenizer->find_regexp(
	    qr{ \A \# [^\n]* (?: \n | \z) }smx )
	    and return $tokenizer->make_token(
		$accept, 'PPIx::Regexp::Token::Comment' );
    } else {
	( $character eq '#' || $character =~ m/ \A \s \z /smx )
	    and return 1;
    }

#line 131

    # Recognize all the escaped constructions that generate literal
    # characters in one gigantic regexp. Technically \1.. through \7..
    # are octal literals too, but we can not disambiguate these from
    # back references until we know how many there are. So the lexer
    # gets another dirty job.
    if ( $character eq '\\' ) {
	if ( my $accept = $tokenizer->find_regexp(
		qr< \A \\ (?:
		    [^\w\s] |		# delimiters/metas
		    [tnrfae] |		# C-style escapes
		    0 [01234567]{0,2} |	# octal
#		    [01234567]{1,3} |	# made from backref by lexer
		    c [][[:alpha:]\@\\^_?] |	# control characters
		    x (?: \{ [[:xdigit:]]* \} | [[:xdigit:]]{0,2} ) | # hex
		    o [{] [01234567]+ [}] |	# octal as of 5.13.3
##		    N (?: \{ (?: [[:alpha:]] [\w\s:()-]* | # must begin w/ alpha
##			U [+] [[:xdigit:]]+ ) \} ) |	# unicode
		    N (?: [{] (?= \D ) [^\}]+ [}] )	# unicode
		) >smx ) ) {
	    return $accept;
	}
    }

    # All other characters which are not extra ordinary get accepted.
    $extra_ordinary{$character} or return 1;

    return;
}

#line 181

{

    my %escapes = (
	'\\t' => ord "\t",
	'\\n' => ord "\n",
	'\\r' => ord "\r",
	'\\f' => ord "\f",
	'\\a' => ord "\a",
	'\\b' => ord "\b",
	'\\e' => ord "\e",
	'\\c?' => ord "\c?",
	'\\c@' => ord "\c@",
	'\\cA' => ord "\cA",
	'\\ca' => ord "\cA",
	'\\cB' => ord "\cB",
	'\\cb' => ord "\cB",
	'\\cC' => ord "\cC",
	'\\cc' => ord "\cC",
	'\\cD' => ord "\cD",
	'\\cd' => ord "\cD",
	'\\cE' => ord "\cE",
	'\\ce' => ord "\cE",
	'\\cF' => ord "\cF",
	'\\cf' => ord "\cF",
	'\\cG' => ord "\cG",
	'\\cg' => ord "\cG",
	'\\cH' => ord "\cH",
	'\\ch' => ord "\cH",
	'\\cI' => ord "\cI",
	'\\ci' => ord "\cI",
	'\\cJ' => ord "\cJ",
	'\\cj' => ord "\cJ",
	'\\cK' => ord "\cK",
	'\\ck' => ord "\cK",
	'\\cL' => ord "\cL",
	'\\cl' => ord "\cL",
	'\\cM' => ord "\cM",
	'\\cm' => ord "\cM",
	'\\cN' => ord "\cN",
	'\\cn' => ord "\cN",
	'\\cO' => ord "\cO",
	'\\co' => ord "\cO",
	'\\cP' => ord "\cP",
	'\\cp' => ord "\cP",
	'\\cQ' => ord "\cQ",
	'\\cq' => ord "\cQ",
	'\\cR' => ord "\cR",
	'\\cr' => ord "\cR",
	'\\cS' => ord "\cS",
	'\\cs' => ord "\cS",
	'\\cT' => ord "\cT",
	'\\ct' => ord "\cT",
	'\\cU' => ord "\cU",
	'\\cu' => ord "\cU",
	'\\cV' => ord "\cV",
	'\\cv' => ord "\cV",
	'\\cW' => ord "\cW",
	'\\cw' => ord "\cW",
	'\\cX' => ord "\cX",
	'\\cx' => ord "\cX",
	'\\cY' => ord "\cY",
	'\\cy' => ord "\cY",
	'\\cZ' => ord "\cZ",
	'\\cz' => ord "\cZ",
	'\\c[' => ord "\c[",
	'\\c\\\\' => ord "\c\\",	# " # Get Vim's head straight.
	'\\c]' => ord "\c]",
	'\\c^' => ord "\c^",
	'\\c_' => ord "\c_",
    );

    sub ordinal {
	my ( $self ) = @_;
	exists $self->{ordinal} and return $self->{ordinal};
	return ( $self->{ordinal} = $self->_ordinal() );
    }

    my %octal = map {; "$_" => 1 } ( 0 .. 7 );

    sub _ordinal {
	my ( $self ) = @_;
	my $content = $self->content();

	$content =~ m/ \A \\ /smx or return ord $content;

	exists $escapes{$content} and return $escapes{$content};

	my $indicator = substr $content, 1, 1;

	$octal{$indicator} and return oct substr $content, 1;

	if ( $indicator eq 'x' ) {
	    $content =~ m/ \A \\ x \{ ( [[:xdigit:]]+ ) \} \z /smx
		and return hex $1;
	    $content =~ m/ \A \\ x ( [[:xdigit:]]{0,2} ) \z /smx
		and return hex $1;
	    return;
	}

	if ( $indicator eq 'o' ) {
	    $content =~ m/ \A \\ o [{] ( [01234567]+ ) [}] \z /smx
		and return oct $1;
	    return;	# Shouldn't happen, but ...
	}

	if ( $indicator eq 'N' ) {
	    $content =~ m/ \A \\ N \{ U [+] ( [[:xdigit:]]+ ) \} \z /smx
		and return hex $1;
	    $content =~ m/ \A \\ N [{] ( .+ ) [}] \z /smx
		and return (
		    _have_charnames_vianame() ?
			charnames::vianame( $1 ) :
			undef
		);
	    return;	# Shouldn't happen, but ...
	}

	return ord $indicator;
    }

}

{
    my $have_charnames_vianame;

    sub _have_charnames_vianame {
	defined $have_charnames_vianame
	    and return $have_charnames_vianame;
	return (
	    $have_charnames_vianame =
		charnames->can( 'vianame' ) ? 1 : 0
	);

    }
}


*__PPIX_TOKENIZER__repl = \&__PPIX_TOKENIZER__regexp;

1;

__END__

#line 347

# ex: set textwidth=72 :
