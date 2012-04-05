#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/PolicyParameter/Behavior/Enumeration.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::PolicyParameter::Behavior::Enumeration;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Exception::Fatal::PolicyDefinition
    qw{ &throw_policy_definition };
use Perl::Critic::Utils qw{ :characters &words_from_string &hashify };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    my $valid_values = $specification->{enumeration_values}
        or throw_policy_definition
            'No enumeration_values given for '
                . $parameter->get_name()
                . $PERIOD;
    ref $valid_values eq 'ARRAY'
        or throw_policy_definition
            'The value given for enumeration_values for '
                . $parameter->get_name()
                . ' is not an array reference.';
    scalar @{$valid_values} > 1
        or throw_policy_definition
            'There were not at least two valid values given for'
                . ' enumeration_values for '
                . $parameter->get_name()
                . $PERIOD;

    # Unfortunately, this has to be a reference, rather than a regular hash,
    # due to a problem in Devel::Cycle
    # (http://rt.cpan.org/Ticket/Display.html?id=25360) which causes
    # t/92_memory_leaks.t to fall over.
    my $value_lookup = { hashify( @{$valid_values} ) };
    $parameter->_get_behavior_values()->{enumeration_values} = $value_lookup;

    my $allow_multiple_values =
        $specification->{enumeration_allow_multiple_values};

    if ($allow_multiple_values) {
        $parameter->_set_parser(
            sub {
                # Normally bad thing, obscuring a variable in a outer scope
                # with a variable with the same name is being done here in
                # order to remain consistent with the parser function interface.
                my ($policy, $parameter, $config_string) = @_;  ## no critic(Variables::ProhibitReusedNames)

                my @potential_values;
                my $value_string = $parameter->get_default_string();

                if (defined $config_string) {
                    $value_string = $config_string;
                }

                if ( defined $value_string ) {
                    @potential_values = words_from_string($value_string);

                    my @bad_values =
                        grep { not exists $value_lookup->{$_} } @potential_values;
                    if (@bad_values) {
                        $policy->throw_parameter_value_exception(
                            $parameter->get_name(),
                            $value_string,
                            undef,
                            q{contains invalid values: }
                                . join (q{, }, @bad_values)
                                . q{. Allowed values are: }
                                . join (q{, }, sort keys %{$value_lookup})
                                . qq{.\n},
                        );
                    }
                }

                my %actual_values = hashify(@potential_values);

                $policy->__set_parameter_value($parameter, \%actual_values);

                return;
            }
        );
    } else {
        $parameter->_set_parser(
            sub {
                # Normally bad thing, obscuring a variable in a outer scope
                # with a variable with the same name is being done here in
                # order to remain consistent with the parser function interface.
                my ($policy, $parameter, $config_string) = @_;  ## no critic(Variables::ProhibitReusedNames)

                my $value_string = $parameter->get_default_string();

                if (defined $config_string) {
                    $value_string = $config_string;
                }

                if (
                        defined $value_string
                    and $EMPTY ne $value_string
                    and not defined $value_lookup->{$value_string}
                ) {
                    $policy->throw_parameter_value_exception(
                        $parameter->get_name(),
                        $value_string,
                        undef,
                        q{is not one of the allowed values: }
                            . join (q{, }, sort keys %{$value_lookup})
                            . qq{.\n},
                    );
                }

                $policy->__set_parameter_value($parameter, $value_string);

                return;
            }
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub generate_parameter_description {
    my ($self, $parameter) = @_;

    my $description = $parameter->_get_description_with_trailing_period();
    if ( $description ) {
        $description .= qq{\n};
    }

    my %values = %{$parameter->_get_behavior_values()->{enumeration_values}};
    return
        $description
        . 'Valid values: '
        . join (', ', sort keys %values)
        . $PERIOD;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 239

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
