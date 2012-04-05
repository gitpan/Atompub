#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/ControlStructures/ProhibitPostfixControls.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities :data_conversion :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Hash my %PAGES_OF => (
    if      => [ 93, 94 ],
    unless  => [ 96, 97 ],
    until   => [ 96, 97 ],
    for     => [ 96     ],
    foreach => [ 96     ],
    while   => [ 96     ],
    when    => q<Similar to "if", postfix "when" should only be used with flow-control>,
);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'allow',
            description        => 'The permitted postfix controls.',
            default_string     => $EMPTY,
            behavior           => 'enumeration',
            enumeration_values => [ sort keys %PAGES_OF ],
            enumeration_allow_multiple_values   => 1,
        },
        {
            name               => 'flowcontrol',
            description        => 'The exempt flow control functions.',
            default_string     => 'carp cluck confess croak die exit goto warn',
            behavior           => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_LOW         }
sub default_themes   { return qw(core pbp cosmetic) }
sub applies_to       { return 'PPI::Token::Word'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $expl = $PAGES_OF{$elem};
    return if not $expl;

    return if is_hash_key($elem);
    return if is_method_call($elem);
    return if is_subroutine_name($elem);
    return if is_included_module_name($elem);
    return if is_package_declaration($elem);

    # Skip controls that are allowed
    return if exists $self->{_allow}->{ $elem->content() };

    # Skip Compound variety (these are good)
    my $stmnt = $elem->statement();
    return if not $stmnt;
    return if $stmnt->isa('PPI::Statement::Compound');
    return if $stmnt->isa('PPI::Statement::When');

    # Handle special cases
    my $content = $elem->content();
    if ($content eq 'if' or $content eq 'when') {
        # Postfix 'if' allowed with loop breaks, or other
        # flow-controls like 'die', 'warn', and 'croak'
        return if $stmnt->isa('PPI::Statement::Break');
        return if defined $self->{_flowcontrol}{ $stmnt->schild(0)->content() };
    }

    # If we get here, it must be postfix.
    my $desc = qq{Postfix control "$content" used};
    return $self->violation($desc, $expl, $elem);
}

1;

__END__

#line 205

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
