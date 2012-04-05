#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/CodeLayout/RequireTidyCode.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::CodeLayout::RequireTidyCode;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Perl::Tidy qw< >;

use Perl::Critic::Utils qw{ :booleans :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Code is not tidy};
Readonly::Scalar my $EXPL => [ 33 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'perltidyrc',
            description     => 'The Perl::Tidy configuration file to use, if any.',
            default_string  => undef,
        },
    );
}

sub default_severity { return $SEVERITY_LOWEST      }
sub default_themes   { return qw(core pbp cosmetic) }
sub applies_to       { return 'PPI::Document'       }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    # Set configuration if defined
    if (defined $self->{_perltidyrc} && $self->{_perltidyrc} eq $EMPTY) {
        $self->{_perltidyrc} = \$EMPTY;
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Perl::Tidy seems to produce slightly different output, depending
    # on the trailing whitespace in the input.  As best I can tell,
    # Perl::Tidy will truncate any extra trailing newlines, and if the
    # input has no trailing newline, then it adds one.  But when you
    # re-run it through Perl::Tidy here, that final newline gets lost,
    # which causes the policy to insist that the code is not tidy.
    # This only occurs when Perl::Tidy is writing the output to a
    # scalar, but does not occur when writing to a file.  I may
    # investigate further, but for now, this seems to do the trick.

    my $source = $doc->serialize();
    $source =~ s{ \s+ \Z}{\n}xms;

    # Remove the shell fix code from the top of program, if applicable
    ## no critic (ProhibitComplexRegexes)
    my $shebang_re = qr< [#]! [^\015\012]+ [\015\012]+ >xms;
    my $shell_re   = qr<eval [ ] 'exec [ ] [^\015\012]* [ ] \$0 [ ] \${1[+]"\$@"}'
                        [ \t]*[\012\015]+ [ \t]* if [^\015\012]+ [\015\012]+ >xms;
    $source =~ s/\A ($shebang_re) $shell_re /$1/xms;

    my $dest    = $EMPTY;
    my $stderr  = $EMPTY;


    # Perl::Tidy gets confused if @ARGV has arguments from
    # another program.  Also, we need to override the
    # stdout and stderr redirects that the user may have
    # configured in their .perltidyrc file.
    local @ARGV = qw(-nst -nse);

    # Trap Perl::Tidy errors, just in case it dies
    my $eval_worked = eval {
        Perl::Tidy::perltidy(
            source      => \$source,
            destination => \$dest,
            stderr      => \$stderr,
            defined $self->{_perltidyrc} ? (perltidyrc => $self->{_perltidyrc}) : (),
       );
       1;
    };

    if ($stderr or not $eval_worked) {
        # Looks like perltidy had problems
        return $self->violation( 'perltidy had errors!!', $EXPL, $elem );
    }

    if ( $source ne $dest ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;    #ok!
}

1;

#-----------------------------------------------------------------------------

__END__

#line 184

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
