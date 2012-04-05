#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitQuotesAsQuotelikeOperatorDelimiters.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitQuotesAsQuotelikeOperatorDelimiters;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Hash my %DESCRIPTIONS => (
    $QUOTE    => q{Single-quote used as quote-like operator delimiter},
    $DQUOTE   => q{Double-quote used as quote-like operator delimiter},
    $BACKTICK => q{Back-quote (back-tick) used as quote-like operator delimiter},
);

Readonly::Scalar my $EXPL =>
    q{Using quotes as delimiters for quote-like operators obfuscates code};

Readonly::Array my @OPERATORS => qw{ m q qq qr qw qx s tr y };

Readonly::Hash my %INFO_RETRIEVERS_BY_PPI_CLASS => (
    'PPI::Token::Quote::Literal'        => \&_info_for_single_character_operator,
    'PPI::Token::Quote::Interpolate'    => \&_info_for_two_character_operator,
    'PPI::Token::QuoteLike::Command'    => \&_info_for_two_character_operator,
    'PPI::Token::QuoteLike::Regexp'     => \&_info_for_two_character_operator,
    'PPI::Token::QuoteLike::Words'      => \&_info_for_two_character_operator,
    'PPI::Token::Regexp::Match'         => \&_info_for_match,
    'PPI::Token::Regexp::Substitute'    => \&_info_for_single_character_operator,
    'PPI::Token::Regexp::Transliterate' => \&_info_for_transliterate,
);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'single_quote_allowed_operators',
            description        =>
                'The operators to allow single-quotes as delimiters for.',
            default_string     => 'm s qr qx',
            behavior           => 'enumeration',
            enumeration_values => [ @OPERATORS ],
            enumeration_allow_multiple_values => 1,
        },
        {
            name               => 'double_quote_allowed_operators',
            description        =>
                'The operators to allow double-quotes as delimiters for.',
            default_string     => $EMPTY,
            behavior           => 'enumeration',
            enumeration_values => [ @OPERATORS ],
            enumeration_allow_multiple_values => 1,
        },
        {
            name               => 'back_quote_allowed_operators',
            description        =>
                'The operators to allow back-quotes (back-ticks) as delimiters for.',
            default_string     => $EMPTY,
            behavior           => 'enumeration',
            enumeration_values => [ @OPERATORS ],
            enumeration_allow_multiple_values => 1,
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM       }
sub default_themes   { return qw( core maintenance ) }

sub applies_to {
    return qw{
        PPI::Token::Quote::Interpolate
        PPI::Token::Quote::Literal
        PPI::Token::QuoteLike::Command
        PPI::Token::QuoteLike::Regexp
        PPI::Token::QuoteLike::Words
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::Regexp::Transliterate
    };
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->{_allowed_operators_by_delimiter} = {
        $QUOTE    => $self->_single_quote_allowed_operators(),
        $DQUOTE   => $self->_double_quote_allowed_operators(),
        $BACKTICK => $self->_back_quote_allowed_operators(),
    };

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub _single_quote_allowed_operators {
    my ( $self ) = @_;

    return $self->{_single_quote_allowed_operators};
}

sub _double_quote_allowed_operators {
    my ( $self ) = @_;

    return $self->{_double_quote_allowed_operators};
}

sub _back_quote_allowed_operators {
    my ( $self ) = @_;

    return $self->{_back_quote_allowed_operators};
}

sub _allowed_operators_by_delimiter {
    my ( $self ) = @_;

    return $self->{_allowed_operators_by_delimiter};
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $info_retriever = $INFO_RETRIEVERS_BY_PPI_CLASS{ ref $elem };
    return if not $info_retriever;

    my ($operator, $delimiter) = $info_retriever->( $elem );

    my $allowed_operators =
        $self->_allowed_operators_by_delimiter()->{$delimiter};
    return if not $allowed_operators;

    if ( not $allowed_operators->{$operator} ) {
        return $self->violation( $DESCRIPTIONS{$delimiter}, $EXPL, $elem );
    }

    return;
}

#-----------------------------------------------------------------------------

sub _info_for_single_character_operator {
    my ( $elem ) = @_;

    ## no critic (ProhibitParensWithBuiltins)
    return ( substr ($elem, 0, 1), substr ($elem, 1, 1) );
    ## use critic
}

#-----------------------------------------------------------------------------

sub _info_for_two_character_operator {
    my ( $elem ) = @_;

    ## no critic (ProhibitParensWithBuiltins)
    return ( substr ($elem, 0, 2), substr ($elem, 2, 1) );
    ## use critic
}

#-----------------------------------------------------------------------------

sub _info_for_match {
    my ( $elem ) = @_;

    if ( $elem =~ m/ ^ m /xms ) {
        return ('m', substr $elem, 1, 1);
    }

    return ('m', q{/});
}

#-----------------------------------------------------------------------------

sub _info_for_transliterate {
    my ( $elem ) = @_;

    if ( $elem =~ m/ ^ tr /xms ) {
        return ('tr', substr $elem, 2, 1);
    }

    return ('y', substr $elem, 1, 1);
}


1;

__END__

#-----------------------------------------------------------------------------

#line 292

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
