#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/PolicyParameter/Behavior/StringList.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::PolicyParameter::Behavior::StringList;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Utils qw{ :characters &words_from_string &hashify };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    # Unfortunately, this has to be kept as a reference, rather than a regular
    # array, due to a problem in Devel::Cycle
    # (http://rt.cpan.org/Ticket/Display.html?id=25360) which causes
    # t/92_memory_leaks.t to fall over.
    my $always_present_values = $specification->{list_always_present_values};
    $parameter->_get_behavior_values()->{always_present_values} =
        $always_present_values;

    if ( not $always_present_values ) {
        $always_present_values = [];
    }

    $parameter->_set_parser(
        sub {
            # Normally bad thing, obscuring a variable in a outer scope
            # with a variable with the same name is being done here in
            # order to remain consistent with the parser function interface.
            my ($policy, $parameter, $config_string) = @_;  ## no critic(Variables::ProhibitReusedNames)

            my @values = @{$always_present_values};
            my $value_string = $parameter->get_default_string();

            if (defined $config_string) {
                $value_string = $config_string;
            }

            if ( defined $value_string ) {
                push @values, words_from_string($value_string);
            }

            my %values = hashify(@values);

            $policy->__set_parameter_value($parameter, \%values);

            return;
        }
    );

    return;
}

#-----------------------------------------------------------------------------

sub generate_parameter_description {
    my ($self, $parameter) = @_;

    my $always_present_values =
        $parameter->_get_behavior_values()->{always_present_values};

    my $description = $parameter->_get_description_with_trailing_period();
    if ( $description and $always_present_values ) {
        $description .= qq{\n};
    }

    if ( $always_present_values ) {
        $description .= 'Values that are always included: ';
        $description .= join ', ', sort @{ $always_present_values };
        $description .= $PERIOD;
    }

    return $description;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 163

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
