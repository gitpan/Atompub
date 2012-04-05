#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ValuesAndExpressions/ProhibitSpecialLiteralHeredocTerminator.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Hash my %SPECIAL_LITERAL => map { '__' . $_ . '__' => 1 }
                                      qw( FILE LINE PACKAGE END DATA );
Readonly::Scalar my $DESC =>
    q{Heredoc terminator must not be a special literal};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_MEDIUM         }
sub default_themes       { return qw(core maintenance)     }
sub applies_to           { return 'PPI::Token::HereDoc'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # remove << and (optional) quotes from around terminator
    ( my $heredoc_terminator = $elem ) =~
        s{ \A << \s* (["']?) (.*) \1 \z }{$2}xms;

    if ( $SPECIAL_LITERAL{ $heredoc_terminator } ) {
        my $expl = qq{Used "$heredoc_terminator" as heredoc terminator};
        return $self->violation( $DESC, $expl, $elem );
    }

    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

#line 126

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
