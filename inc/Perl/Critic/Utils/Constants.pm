#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Utils/Constants.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Utils::Constants;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ $EMPTY hashify };

use base 'Exporter';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{
    $PROFILE_STRICTNESS_WARN
    $PROFILE_STRICTNESS_FATAL
    $PROFILE_STRICTNESS_QUIET
    $PROFILE_STRICTNESS_DEFAULT
    %PROFILE_STRICTNESSES
    $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT
    $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT
    $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT
    $PROFILE_COLOR_SEVERITY_LOW_DEFAULT
    $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT
    $_MODULE_VERSION_TERM_ANSICOLOR
};

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    profile_strictness => [
        qw{
            $PROFILE_STRICTNESS_WARN
            $PROFILE_STRICTNESS_FATAL
            $PROFILE_STRICTNESS_QUIET
            $PROFILE_STRICTNESS_DEFAULT
            %PROFILE_STRICTNESSES
        }
    ],
    color_severity  => [
        qw{
            $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT
            $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT
            $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT
            $PROFILE_COLOR_SEVERITY_LOW_DEFAULT
            $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT
        }
    ],
);

#-----------------------------------------------------------------------------

Readonly::Scalar our $PROFILE_STRICTNESS_WARN    => 'warn';
Readonly::Scalar our $PROFILE_STRICTNESS_FATAL   => 'fatal';
Readonly::Scalar our $PROFILE_STRICTNESS_QUIET   => 'quiet';
Readonly::Scalar our $PROFILE_STRICTNESS_DEFAULT => $PROFILE_STRICTNESS_WARN;

Readonly::Hash our %PROFILE_STRICTNESSES =>
    hashify(
        $PROFILE_STRICTNESS_WARN,
        $PROFILE_STRICTNESS_FATAL,
        $PROFILE_STRICTNESS_QUIET,
    );

Readonly::Scalar our $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT    => 'bold red';
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT       => 'magenta';
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT     => $EMPTY;
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_LOW_DEFAULT        => $EMPTY;
Readonly::Scalar our $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT     => $EMPTY;

# If the following changes, the corresponding change needs to be made in
# inc/Perl/Critic/BuildUtilities.pm, sub recommended_module_versions().
Readonly::Scalar our $_MODULE_VERSION_TERM_ANSICOLOR => 2.02;

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 173

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
