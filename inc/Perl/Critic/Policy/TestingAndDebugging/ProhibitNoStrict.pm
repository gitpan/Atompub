#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/TestingAndDebugging/ProhibitNoStrict.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{ :characters :severities :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Stricture disabled};
Readonly::Scalar my $EXPL => [ 429 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow',
            description     => 'Allow vars, subs, and/or refs.',
            default_string  => $EMPTY,
            parser          => \&_parse_allow,
        },
    );
}

sub default_severity { return $SEVERITY_HIGHEST         }
sub default_themes   { return qw( core pbp bugs )       }
sub applies_to       { return 'PPI::Statement::Include' }

#-----------------------------------------------------------------------------

sub _parse_allow {
    my ($self, $parameter, $config_string) = @_;

    $self->{_allow} = {};

    if( defined $config_string ) {
        my $allowed = lc $config_string; #String of words
        my %allowed = hashify( $allowed =~ m/ (\w+) /gxms );
        $self->{_allow} = \%allowed;
    }

    return;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->type()   ne 'no';
    return if $elem->pragma() ne 'strict';

    #Arguments to 'no strict' are usually a list of literals or a qw()
    #list.  Rather than trying to parse the various PPI elements, I
    #just use a regex to split the statement into words.  This is
    #kinda lame, but it does the trick for now.

    # TODO consider: a possible alternate implementation:
    #   my $re = join q{|}, keys %{$self->{allow}};
    #   return if $re && $stmnt =~ m/\b(?:$re)\b/mx;
    # May need to detaint for that to work...  Not sure.

    my $stmnt = $elem->statement();
    return if !$stmnt;
    my @words = $stmnt =~ m/ ([[:lower:]]+) /gxms;
    @words = grep { $_ ne 'qw' && $_ ne 'no' && $_ ne 'strict' } @words;
    return if @words && all { exists $self->{_allow}->{$_} } @words;

    #If we get here, then it must be a violation
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

#line 147

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
