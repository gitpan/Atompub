#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/ProfilePrototype.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::ProfilePrototype;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Config qw{};
use Perl::Critic::Policy qw{};
use Perl::Critic::Utils qw{ :characters };
use overload ( q{""} => 'to_string' );

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    my $policies = $args{-policies} || [];
    $self->{_policies} = [ sort _by_type @{ $policies } ];

    my $comment_out_parameters = $args{'-comment-out-parameters'};
    if (not defined $comment_out_parameters) {
        $comment_out_parameters = 1;
    }
    $self->{_comment_out_parameters} = $comment_out_parameters;

    my $configuration = $args{'-config'};
    if (not $configuration) {
        $configuration = Perl::Critic::Config->new(-profile => $EMPTY);
    }
    $self->{_configuration} = $configuration;


    return $self;
}

#-----------------------------------------------------------------------------

sub _get_policies {
    my ($self) = @_;

    return $self->{_policies};
}

sub _comment_out_parameters {
    my ($self) = @_;

    return $self->{_comment_out_parameters};
}

sub _configuration {
    my ($self) = @_;

    return $self->{_configuration};
}

#-----------------------------------------------------------------------------

sub _line_prefix {
    my ($self) = @_;

    return $self->_comment_out_parameters() ? q{# } : $EMPTY;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $prefix = $self->_line_prefix();
    my $configuration = $self->_configuration();

    my $prototype = "# Globals\n";

    $prototype .= $prefix;
    $prototype .= q{severity = };
    $prototype .= $configuration->severity();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{force = };
    $prototype .= $configuration->force();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{only = };
    $prototype .= $configuration->only();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{allow-unsafe = };
    $prototype .= $configuration->unsafe_allowed();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{profile-strictness = };
    $prototype .= $configuration->profile_strictness();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{color = };
    $prototype .= $configuration->color();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{pager = };
    $prototype .= $configuration->pager();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{top = };
    $prototype .= $configuration->top();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{verbose = };
    $prototype .= $configuration->verbose();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{include = };
    $prototype .= join $SPACE, $configuration->include();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{exclude = };
    $prototype .= join $SPACE, $configuration->exclude();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{single-policy = };
    $prototype .= join $SPACE, $configuration->single_policy();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{theme = };
    $prototype .= $configuration->theme()->rule();
    $prototype .= "\n";

    foreach my $item (qw<
        color-severity-highest
        color-severity-high
        color-severity-medium
        color-severity-low
        color-severity-lowest
        >) {
        ( my $accessor = $item ) =~ s/ - /_/gmsx;
        $prototype .= $prefix;
        $prototype .= "$item = ";
        $prototype .= $configuration->$accessor;
        $prototype .= "\n";
    }

    $prototype .= $prefix;
    $prototype .= q{program-extensions = };
    $prototype .= join $SPACE, $configuration->program_extensions();

    Perl::Critic::Policy::set_format( $self->_proto_format() );

    return $prototype . "\n\n" . join q{}, map { "$_" } @{ $self->_get_policies() };
}

#-----------------------------------------------------------------------------

# About "%{\\n%\\x7b# \\x7df\n${prefix}%n = %D\\n}O" below:
#
# The %0 format for a policy specifies how to format parameters.
# For a parameter %f specifies the full description.
#
# The problem is that both of these need to take options, but String::Format
# doesn't allow nesting of {}.  So, to get the option to the %f, the braces
# are hex encoded.  I.e., assuming that comment_out_parameters is in effect,
# the parameter sees:
#
#    \n%{# }f\n# %n = %D\n

sub _proto_format {
    my ($self) = @_;

    my $prefix = $self->_line_prefix();

    return <<"END_OF_FORMAT";
# %a
[%p]
${prefix}set_themes                         = %t
${prefix}add_themes                         =
${prefix}severity                           = %s
${prefix}maximum_violations_per_document    = %v
%{\\n%\\x7b# \\x7df\\n${prefix}%n = %D\\n}O%{${prefix}Cannot programmatically discover what parameters this policy takes.\\n}U

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

#line 285

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
