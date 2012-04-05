#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/RequireFilenameMatchesPackage.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage;

use 5.006001;
use strict;
use warnings;
use Readonly;

use File::Spec;

use Perl::Critic::Utils qw{ :characters :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Package declaration must match filename};
Readonly::Scalar my $EXPL => q{Correct the filename or package statement};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                }
sub default_severity     { return $SEVERITY_HIGHEST }
sub default_themes       { return qw(core bugs)     }
sub applies_to           { return 'PPI::Document'   }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;
    return $document->is_module();   # Must be a library or module.
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    # 'Foo::Bar' -> ('Foo', 'Bar')
    my $pkg_node = $doc->find_first('PPI::Statement::Package');
    return if not $pkg_node;
    my $pkg = $pkg_node->namespace();
    return if $pkg eq 'main';
    my @pkg_parts = split m/(?:\'|::)/xms, $pkg;


    # 'lib/Foo/Bar.pm' -> ('lib', 'Foo', 'Bar')
    my $filename = $pkg_node->logical_filename() || $doc->filename();
    return if not $filename;

    my @path = File::Spec->splitpath($filename);
    $filename = $path[2];
    $filename =~ s/ [.] \w+ \z //xms;
    my @path_parts =
        grep {$_ ne $EMPTY} File::Spec->splitdir($path[1]), $filename;


    # To succeed, at least the lastmost must match
    # Beyond that, the search terminates if a dirname is an impossible package name
    my $matched_any;
    while (@pkg_parts && @path_parts) {
        my $pkg_part = pop @pkg_parts;
        my $path_part = pop @path_parts;
        if ($pkg_part eq $path_part) {
            $matched_any = 1;
            next;
        }

        # if it's a path that's not a possible package (like 'Foo-Bar-1.00'), that's OK
        last if ($path_part =~ m/\W/xms);

        # Mismatched name
        return $self->violation( $DESC, $EXPL, $pkg_node );
    }

    return if $matched_any;
    return $self->violation( $DESC, $EXPL, $pkg_node );
}

1;

#-----------------------------------------------------------------------------

__END__

#line 153

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
