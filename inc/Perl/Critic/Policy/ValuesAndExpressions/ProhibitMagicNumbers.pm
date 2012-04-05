#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitMagicNumbers.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities :data_conversion };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#----------------------------------------------------------------------------

Readonly::Scalar my $EXPL =>
    q{Unnamed numeric literals make code less maintainable};
Readonly::Scalar my $USE_READONLY_OR_CONSTANT =>
    ' Use the Readonly or Const::Fast module or the "constant" pragma instead';
Readonly::Scalar my $TYPE_NOT_ALLOWED_SUFFIX =>
    ") are not allowed.$USE_READONLY_OR_CONSTANT";

Readonly::Scalar my $UNSIGNED_NUMBER =>
    qr{
            \d+ (?: [$PERIOD] \d+ )?  # 1, 1.5, etc.
        |   [$PERIOD] \d+             # .3, .7, etc.
    }xms;
Readonly::Scalar my $SIGNED_NUMBER => qr/ [-+]? $UNSIGNED_NUMBER /xms;

Readonly::Scalar my $RANGE =>
    qr{
        \A
        ($SIGNED_NUMBER)
        [$PERIOD] [$PERIOD]
        ($SIGNED_NUMBER)
        (?:
            [$COLON] by [$LEFT_PAREN]
            ($UNSIGNED_NUMBER)
            [$RIGHT_PAREN]
        )?
        \z
    }xms;

Readonly::Scalar my $SPECIAL_ARRAY_SUBSCRIPT_EXEMPTION => -1;

#----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allowed_values',
            description    => 'Individual and ranges of values to allow, and/or "all_integers".',
            default_string => '0 1 2',
            parser         => \&_parse_allowed_values,
        },
        {
            name               => 'allowed_types',
            description        => 'Kind of literals to allow.',
            default_string     => 'Float',
            behavior           => 'enumeration',
            enumeration_values => [ qw{ Binary Exp Float Hex Octal } ],
            enumeration_allow_multiple_values => 1,
        },
        {
            name           => 'allow_to_the_right_of_a_fat_comma',
            description    =>
                q[Should anything to the right of a "=>" be allowed?],
            default_string => '1',
            behavior           => 'boolean',
        },
        {
            name            => 'constant_creator_subroutines',
            description     => q{Names of subroutines that create constants},
            behavior        => 'string list',
            list_always_present_values => [
                qw<
                    Readonly Readonly::Scalar Readonly::Array Readonly::Hash
                    const
                >,
            ],
        },
    );
}

sub default_severity { return $SEVERITY_LOW          }
sub default_themes   { return qw( core maintenance ) }
sub applies_to       { return 'PPI::Token::Number'   }

sub default_maximum_violations_per_document { return 10; }

#----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    $self->_determine_checked_types();

    return $TRUE;
}

sub _parse_allowed_values {
    my ($self, $parameter, $config_string) = @_;

    my ( $all_integers_allowed, $allowed_values )
        = _determine_allowed_values($config_string);

    my $allowed_string = ' is not one of the allowed literal values (';
    if ($all_integers_allowed) {
        $allowed_string .= 'all integers';

        if ( %{$allowed_values} ) {
            $allowed_string .= ', ';
        }
    }
    $allowed_string
        .= ( join ', ', sort { $a <=> $b } keys %{$allowed_values} ) . ').'
        . $USE_READONLY_OR_CONSTANT;

    $self->{_allowed_values}       = $allowed_values;
    $self->{_all_integers_allowed} = $all_integers_allowed;
    $self->{_allowed_string}       = $allowed_string;

    return;
}

sub _determine_allowed_values {
    my ($config_string) = @_;

    my @allowed_values;
    my @potential_allowed_values;
    my $all_integers_allowed = 0;

    if ( defined $config_string ) {
        my @allowed_values_strings =
            grep {$_} split m/\s+/xms, $config_string;

        foreach my $value_string (@allowed_values_strings) {
            if ($value_string eq 'all_integers') {
                $all_integers_allowed = 1;
            } elsif ( $value_string =~ m/ \A $SIGNED_NUMBER \z /xms ) {
                push @potential_allowed_values, $value_string + 0;
            } elsif ( $value_string =~ m/$RANGE/xms ) {
                my ( $minimum, $maximum, $increment ) = ($1, $2, $3);
                $increment ||= 1;

                $minimum += 0;
                $maximum += 0;
                $increment += 0;

                for (                       ## no critic (ProhibitCStyleForLoops)
                    my $value = $minimum;
                    $value <= $maximum;
                    $value += $increment
                ) {
                    push @potential_allowed_values, $value;
                }
            } else {
                die q{Invalid value for allowed_values: }, $value_string,
                    q{. Must be a number, a number range, or},
                    qq{ "all_integers".\n};
            }
        }

        if ($all_integers_allowed) {
            @allowed_values = grep { $_ != int $_ } @potential_allowed_values;
        } else {
            @allowed_values = @potential_allowed_values;
        }
    } else {
        @allowed_values = (2);
    }

    if ( not $all_integers_allowed ) {
        push @allowed_values, 0, 1;
    }
    my %allowed_values = hashify(@allowed_values);

    return ( $all_integers_allowed, \%allowed_values );
}

sub _determine_checked_types {
    my ($self) = @_;

    my %checked_types = (
        'PPI::Token::Number::Binary'  => 'Binary literals (',
        'PPI::Token::Number::Float'   => 'Floating-point literals (',
        'PPI::Token::Number::Exp'     => 'Exponential literals (',
        'PPI::Token::Number::Hex'     => 'Hexadecimal literals (',
        'PPI::Token::Number::Octal'   => 'Octal literals (',
        'PPI::Token::Number::Version' => 'Version literals (',
    );

    # This will be set by the enumeration behavior specified in
    # supported_parameters() above.
    my $allowed_types = $self->{_allowed_types};

    foreach my $allowed_type ( keys %{$allowed_types} ) {
        delete $checked_types{"PPI::Token::Number::$allowed_type"};

        if ( $allowed_type eq 'Exp' ) {

            # because an Exp isa(Float).
            delete $checked_types{'PPI::Token::Number::Float'};
        }
    }

    $self->{_checked_types} = \%checked_types;

    return;
}


sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( $self->{_allow_to_the_right_of_a_fat_comma} ) {
        return if _element_is_to_the_right_of_a_fat_comma($elem);
    }

    return if _element_is_in_an_include_readonly_or_version_statement(
        $self, $elem,
    );
    return if _element_is_in_a_plan_statement($elem);
    return if _element_is_in_a_constant_subroutine($elem);
    return if _element_is_a_package_statement_version_number($elem);

    my $literal = $elem->literal();
    if (
            defined $literal
        and not (
                    $self->{_all_integers_allowed}
                and int $literal == $literal
            )
        and not defined $self->{_allowed_values}{$literal}
        and not (
                    _element_is_sole_component_of_a_subscript($elem)
                and $literal == $SPECIAL_ARRAY_SUBSCRIPT_EXEMPTION
            )
    ) {
        return
            $self->violation(
                $elem->content() . $self->{_allowed_string},
                $EXPL,
                $elem,
            );
    }


    my ( $number_type, $type_string );

    while (
        ( $number_type, $type_string ) = ( each %{ $self->{_checked_types} } )
    ) {
        if ( $elem->isa($number_type) ) {
            return
                $self->violation(
                    $type_string . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                    $EXPL,
                    $elem,
                );
        }
    }

    return;
}

sub _element_is_to_the_right_of_a_fat_comma {
    my ($elem) = @_;

    my $previous = $elem->sprevious_sibling() or return;

    $previous->isa('PPI::Token::Operator') or return;

    return $previous->content() eq q[=>];
}

sub _element_is_sole_component_of_a_subscript {
    my ($elem) = @_;

    my $parent = $elem->parent();
    if ( $parent and $parent->isa('PPI::Statement::Expression') ) {
        if ( $parent->schildren() > 1 ) {
            return 0;
        }

        my $grandparent = $parent->parent();
        if (
                $grandparent
            and $grandparent->isa('PPI::Structure::Subscript')
        ) {
            return 1;
        }
    }

    return 0;
}

sub _element_is_in_an_include_readonly_or_version_statement {
    my ($self, $elem) = @_;

    my $parent = $elem->parent();
    while ($parent) {
        if ( $parent->isa('PPI::Statement') ) {
            return 1 if $parent->isa('PPI::Statement::Include');

            if ( $parent->isa('PPI::Statement::Variable') ) {
                if ( $parent->type() eq 'our' ) {
                    my @variables = $parent->variables();
                    if (
                            scalar @variables == 1
                        and $variables[0] eq '$VERSION' ## no critic (RequireInterpolationOfMetachars)
                    ) {
                        return 1;
                    }
                }

                return 0;
            }

            my $first_token = $parent->first_token();
            if ( $first_token->isa('PPI::Token::Word') ) {
                if ( $self->{_constant_creator_subroutines}{
                        $first_token->content() } ) {
                    return 1;
                }
            } elsif ($parent->isa('PPI::Structure::Block')) {
                return 0;
            }
        }

        $parent = $parent->parent();
    }

    return 0;
}

# Allow "plan tests => 39;".

Readonly::Scalar my $PLAN_STATEMENT_MINIMUM_TOKENS => 4;

sub _element_is_in_a_plan_statement {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return 0 if not $parent;

    return 0 if not $parent->isa('PPI::Statement');

    my @children = $parent->schildren();
    return 0 if @children < $PLAN_STATEMENT_MINIMUM_TOKENS;

    return 0 if not $children[0]->isa('PPI::Token::Word');
    return 0 if $children[0]->content() ne 'plan';

    return 0 if not $children[1]->isa('PPI::Token::Word');
    return 0 if $children[1]->content() ne 'tests';

    return 0 if not $children[2]->isa('PPI::Token::Operator');
    return 0 if $children[2]->content() ne '=>';

    return 1;
}

sub _element_is_in_a_constant_subroutine {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return 0 if not $parent;

    return 0 if not $parent->isa('PPI::Statement');

    my $following = $elem->snext_sibling();
    if ($following) {
        return 0 if not $following->isa('PPI::Token::Structure');
        return 0 if $following->content() ne $SCOLON;
        return 0 if $following->snext_sibling();
    }

    my $preceding = $elem->sprevious_sibling();
    if ($preceding) {
        return 0 if not $preceding->isa('PPI::Token::Word');
        return 0 if $preceding->content() ne 'return';
        return 0 if $preceding->sprevious_sibling();
    }

    return 0 if $parent->snext_sibling();
    return 0 if $parent->sprevious_sibling();

    my $grandparent = $parent->parent();
    return 0 if not $grandparent;

    return 0 if not $grandparent->isa('PPI::Structure::Block');

    my $greatgrandparent = $grandparent->parent();
    return 0 if not $greatgrandparent;
    return 0 if not $greatgrandparent->isa('PPI::Statement::Sub');

    return 1;
}

sub _element_is_a_package_statement_version_number {
    my ($elem) = @_;

    my $parent = $elem->statement()
        or return 0;

    $parent->isa( 'PPI::Statement::Package' )
        or return 0;

    my $version = $parent->schild( 2 )
        or return 0;

    return $version == $elem;
}

1;

__END__

#----------------------------------------------------------------------------

#line 677

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
