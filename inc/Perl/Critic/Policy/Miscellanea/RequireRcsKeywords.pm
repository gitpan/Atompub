#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Miscellanea/RequireRcsKeywords.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Miscellanea::RequireRcsKeywords;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(none);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 441 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'keywords',
            description     => 'The keywords to require in all files.',
            default_string  => $EMPTY,
            behavior        => 'string list',
        },
    );
}

sub default_severity  { return $SEVERITY_LOW         }
sub default_themes    { return qw(core pbp cosmetic) }
sub applies_to        { return 'PPI::Document'       }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    # Any of these lists
    $self->{_keyword_sets} = [

        # Minimal svk/svn
        [qw(Id)],

        # Expansive svk/svn
        [qw(Revision HeadURL Date)],

        # cvs?
        [qw(Revision Source Date)],
    ];

    # Set configuration, if defined.
    my @keywords = keys %{ $self->{_keywords} };
    if ( @keywords ) {
        $self->{_keyword_sets} = [ [ @keywords ] ];
    }

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @viols = ();

    my $nodes = $self->_find_wanted_nodes($doc);
    for my $keywordset_ref ( @{ $self->{_keyword_sets} } ) {
        if ( not $nodes ) {
            my $desc = 'RCS keywords '
                . join( ', ', map {"\$$_\$"} @{$keywordset_ref} )
                . ' not found';
            push @viols, $self->violation( $desc, $EXPL, $doc );
        }
        else {
            my @missing_keywords =
                grep
                    {
                        my $keyword_rx = qr< \$ $_ .* \$ >xms;
                        ! ! none { m/$keyword_rx/xms } @{$nodes}
                    }
                    @{$keywordset_ref};

            if (@missing_keywords) {
                # Provisionally flag a violation. See below.
                my $desc =
                    'RCS keywords '
                        . join( ', ', map {"\$$_\$"} @missing_keywords )
                        . ' not found';
                push @viols, $self->violation( $desc, $EXPL, $doc );
            }
            else {
                # Hey! I'm ignoring @viols for other keyword sets
                # because this one is complete.
                return;
            }
        }
    }

    return @viols;
}

#-----------------------------------------------------------------------------

sub _find_wanted_nodes {
    my ( $self, $doc ) = @_;
    my @wanted_types = qw(Pod Comment Quote::Single Quote::Literal End);
    my @found =  map { @{ $doc->find("PPI::Token::$_") || [] } } @wanted_types;
    push @found, grep { $_->content() =~ m/ \A qw\$ [^\$]* \$ \z /smx } @{
        $doc->find('PPI::Token::QuoteLike::Words') || [] };
    return @found ? \@found : $EMPTY;  # Behave like PPI::Node::find()
}

1;

__END__

#-----------------------------------------------------------------------------

#line 193

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :