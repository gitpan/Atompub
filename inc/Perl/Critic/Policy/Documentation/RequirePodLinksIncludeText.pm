#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Documentation/RequirePodLinksIncludeText.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText;

use 5.006001;

use strict;
use warnings;

use Readonly;
use English qw{ -no_match_vars };
use Perl::Critic::Utils qw{ :booleans :characters :severities };
use base 'Perl::Critic::Policy';

use Perl::Critic::Utils::POD::ParseInteriorSequence;

#-----------------------------------------------------------------------------

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => 'Without text, you are at the mercy of the POD translator';

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow_external_sections',
            description     => 'Allow external sections without text',
            default_string  => '1',
            behavior        => 'boolean',
        },
        {
            name            => 'allow_internal_sections',
            description     => 'Allow internal sections without text',
            default_string  => '1',
            behavior        => 'boolean',
        },
    );
}
sub default_severity { return $SEVERITY_LOW            }
sub default_themes   { return qw(core maintenance)     }
sub applies_to       { return 'PPI::Token::Pod'        }

#-----------------------------------------------------------------------------

Readonly::Scalar my $INCREMENT_NESTING => 1;
Readonly::Scalar my $DECREMENT_NESTING => -1;
Readonly::Hash my %ESCAPE_NESTING => (
    '<' => $INCREMENT_NESTING,
    '>' => $DECREMENT_NESTING,
);

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @violations;

#line 124

    my $parser = Perl::Critic::Utils::POD::ParseInteriorSequence->new();
    $parser->errorsub( sub { return 1 } );  # Suppress error messages.

    foreach my $seq ( $parser->get_interior_sequences( $elem->content() ) ) {

        # Not interested in nested thing like C<< L<Foo> >>. I think.
        $seq->nested() and next;

        # Not interested in anything but L<...>.
        'L' eq $seq->cmd_name() or next;

        # If the link is allowed, pass on to the next one.
        $self->_allowed_link( $seq ) and next;

        # A-Hah! Gotcha!
        my $line_number = $elem->line_number() + ( $seq->file_line() )[1] - 1;
        push @violations, $self->violation(
            join( $SPACE, 'Link', $seq->raw_text(),
                "on line $line_number does not specify text" ),
            $EXPL, $elem );
    }

    return @violations;
}

sub _allowed_link {

#line 159

    my ( $self, $pod_seq ) = @_;

    # Extract the content of the sequence.
    my $content = $pod_seq->raw_text();
    $content = substr $content, 0, - length $pod_seq->right_delimiter();
    $content = substr $content, length( $pod_seq->cmd_name() ) + length(
        $pod_seq->left_delimiter() );

    # Not interested in hyperlinks.
    $content =~ m{ \A \w+ : (?! : ) }smx
        and return $TRUE;

    # Links with text specified are good.
    $content =~ m/ [|] /smx
        and return $TRUE;

    # Internal sections without text are either good or bad, depending on how
    # we are configured.
    $content =~ m{ \A [/"] }smx
        and return $self->{_allow_internal_sections};

    # External sections without text are either good or bad, depending on how
    # we are configured.
    $content =~ m{ / }smx
        and return $self->{_allow_external_sections};

    # Anything else without text is bad.
    return $FALSE;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 265

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
