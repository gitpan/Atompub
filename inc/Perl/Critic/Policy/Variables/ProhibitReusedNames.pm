#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitReusedNames.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitReusedNames;

use 5.006001;
use strict;
use warnings;
use List::MoreUtils qw(part);
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Reused variable name in lexical scope: };
Readonly::Scalar my $EXPL => q{Invent unique variable names};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     => 'The variables to not consider as duplicates.',
            default_string  => '$self $class',    ## no critic (RequireInterpolationOfMetachars)
            behavior        => 'string list',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core bugs )            }
sub applies_to           { return 'PPI::Statement::Variable' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if 'local' eq $elem->type;

    my $allow = $self->{_allow};
    my @names = grep { not $allow->{$_} } $elem->variables();
    my $names = [ @names ];
    # Assert: it is impossible for @$names to be empty in valid Perl syntax
    # But if it IS empty, this code should still work but will be inefficient

    # walk up the PDOM looking for declared variables in the same
    # scope or outer scopes quit when we hit the root or when we find
    # violations for all vars (the latter is a shortcut)
    my $outer = $elem;
    my @violations;
    while (1) {
        my $up = $outer->sprevious_sibling;
        if (not $up) {
            $up = $outer->parent;
        }
        last if !$up; # top of PDOM, we're done
        $outer = $up;

        if ($outer->isa('PPI::Statement::Variable') && 'local' ne $outer->type) {
            my %vars = map {$_ => undef} $outer->variables;
            my $hits;
            ($hits, $names) = part { exists $vars{$_} ? 0 : 1 } @{$names};
            if ($hits) {
                push @violations, map { $self->violation( $DESC . $_, $EXPL, $elem ) } @{$hits};
                last if not $names;  # found violations for ALL variables, we're done
            }
        }
        }
    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 184

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
