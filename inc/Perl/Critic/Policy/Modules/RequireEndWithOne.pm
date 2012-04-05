#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Modules/RequireEndWithOne.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Modules::RequireEndWithOne;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => q{Must end with a recognizable true value};
Readonly::Scalar my $DESC => q{Module does not end with "1;"};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Document'     }

#-----------------------------------------------------------------------------

sub prepare_to_scan_document {
    my ( $self, $document ) = @_;

    return $document->is_module();   # Must be a library or module.
}

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Last statement should be just "1;"
    my @significant = grep { _is_code($_) } $doc->schildren();
    my $match = $significant[-1];
    return if !$match;
    return if ((ref $match) eq 'PPI::Statement' &&
               $match =~  m{\A 1 \s* ; \z}xms );

    # Must be a violation...
    return $self->violation( $DESC, $EXPL, $match );
}

sub _is_code {
    my $elem = shift;
    return ! (    $elem->isa('PPI::Statement::End')
               || $elem->isa('PPI::Statement::Data'));
}

1;

__END__

#-----------------------------------------------------------------------------

#line 111

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
