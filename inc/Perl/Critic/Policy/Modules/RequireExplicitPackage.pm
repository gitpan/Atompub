#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/RequireExplicitPackage.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::RequireExplicitPackage;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Violates encapsulation};
Readonly::Scalar my $DESC => q{Code not contained in explicit package};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'exempt_scripts',
            description    => q{Don't require programs to contain a package statement.},
            default_string => '1',
            behavior       => 'boolean',
        },
        {
            name           => 'allow_import_of',
            description    => q{Allow the specified modules to be imported outside a package},
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_HIGH  }
sub default_themes   { return qw( core bugs ) }
sub applies_to       { return 'PPI::Document' }

sub default_maximum_violations_per_document { return 1; }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    return ! $self->{_exempt_scripts} || $document->is_module();
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Find the first 'package' statement
    my $package_stmnt = $doc->find_first( 'PPI::Statement::Package' );
    my $package_line = $package_stmnt ? $package_stmnt->location()->[0] : undef;

    # Find all statements that aren't 'package' statements
    my $stmnts_ref = $doc->find( 'PPI::Statement' );
    return if !$stmnts_ref;
    my @non_packages = grep {
        $self->_is_statement_of_interest( $_ )
    } @{$stmnts_ref};
    return if !@non_packages;

    # If the 'package' statement is not defined, or the other
    # statements appear before the 'package', then it violates.

    my @viols = ();
    for my $stmnt ( @non_packages ) {
        my $stmnt_line = $stmnt->location()->[0];
        if ( (! defined $package_line) || ($stmnt_line < $package_line) ) {
            push @viols, $self->violation( $DESC, $EXPL, $stmnt );
        }
    }

    return @viols;
}

sub _is_statement_of_interest {
    my ( $self, $elem ) = @_;

    $elem
        or return $FALSE;

    $elem->isa( 'PPI::Statement::Package' )
        and return $FALSE;

    if ( $elem->isa( 'PPI::Statement::Include' ) ) {
        if ( my $module = $elem->module() ) {
            $self->{_allow_import_of}{$module}
                and return $FALSE;
        }
    }

    return $TRUE;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 187

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
