#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/RequireConsistentNewlines.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use PPI::Token::Whitespace;
use English qw(-no_match_vars);
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

Readonly::Scalar my $LINE_END => qr/\015{1,2}\012|[\012\015]/mxs;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use the same newline through the source};
Readonly::Scalar my $EXPL => q{Change your newlines to be the same throughout};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_HIGH  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    my $filename = $doc->filename();
    return if !$filename;

    my $fh;
    return if !open $fh, '<', $filename;
    local $RS = undef;
    my $source = <$fh>;
    close $fh or return;

    my $newline; # undef until we find the first one
    my $line = 1;
    my @v;
    while ( $source =~ m/\G([^\012\015]*)($LINE_END)/cgmxs ) {
        my $code = $1;
        my $nl = $2;
        my $col = length $code;
        $newline ||= $nl;
        if ( $nl ne $newline ) {
            my $token = PPI::Token::Whitespace->new( $nl );
            # TODO this is a terrible violation of encapsulation, but absent a
            # mechanism to override the line numbers in the violation, I do
            # not know what to do about it.
            $token->{_location} = [$line, $col, $col, $line, $filename];
            push @v, $self->violation( $DESC, $EXPL, $token );
        }
        $line++;
    }
    return @v;
}

1;

#-----------------------------------------------------------------------------

__END__

#line 123

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
