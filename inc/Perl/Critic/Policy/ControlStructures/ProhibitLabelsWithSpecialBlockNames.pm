#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitLabelsWithSpecialBlockNames.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitLabelsWithSpecialBlockNames;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

Readonly::Hash my %SPECIAL_BLOCK_NAMES =>
    hashify( qw< BEGIN END INIT CHECK UNITCHECK > );

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Special block name used as label.>;
Readonly::Scalar my $EXPL =>
    q<Use a label that cannot be confused with BEGIN, END, CHECK, INIT, or UNITCHECK blocks.>;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw< core bugs >         }
sub applies_to           { return qw< PPI::Token::Label > }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    # Does the function call have enough arguments?
    my $label = $elem->content();
    $label =~ s/ \s* : \z //xms;
    return if not $SPECIAL_BLOCK_NAMES{ $label };

    return $self->violation( $DESC, $EXPL, $elem );
}


1;

#-----------------------------------------------------------------------------

__END__

#line 116

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
