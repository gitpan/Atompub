#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Variables/ProhibitMatchVars.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Variables::ProhibitMatchVars;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Match variable used};
Readonly::Scalar my $EXPL => [ 82 ];

Readonly::Array my @FORBIDDEN => qw( $` $& $' $MATCH $PREMATCH $POSTMATCH );
Readonly::Hash my %FORBIDDEN => hashify( @FORBIDDEN );

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGH             }
sub default_themes       { return qw( core performance pbp ) }
sub applies_to           { return qw( PPI::Token::Symbol
                                      PPI::Statement::Include ) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if (_is_use_english($elem) || _is_forbidden_var($elem)) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;  #ok!
}

#-----------------------------------------------------------------------------

sub _is_use_english {
    my $elem = shift;
    $elem->isa('PPI::Statement::Include') || return;
    $elem->type() eq 'use' || return;
    $elem->module() eq 'English' || return;

    # Bare, lacking -no_match_vars.  Now handled by
    # Modules::RequireNoMatchVarsWithUseEnglish.
    return 0 if ($elem =~ m/\A use \s+ English \s* ;\z/xms);

    return 1 if ($elem =~ m/\$(?:PRE|POST|)MATCH/xms);
    return;  # either "-no_match_vars" or a specific list
}

sub _is_forbidden_var {
    my $elem = shift;
    $elem->isa('PPI::Token::Symbol') || return;
    return exists $FORBIDDEN{$elem};
}

1;

__END__

#-----------------------------------------------------------------------------

#line 119

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
