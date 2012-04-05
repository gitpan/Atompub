#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Theme.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Theme;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use base qw{ Exporter };

use List::MoreUtils qw(any);

use Perl::Critic::Utils qw{ :characters :data_conversion };
use Perl::Critic::Exception::Fatal::Internal qw{ &throw_internal };
use Perl::Critic::Exception::Configuration::Option::Global::ParameterValue
    qw{ &throw_global_value };

#-----------------------------------------------------------------------------

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw{
    $RULE_INVALID_CHARACTER_REGEX
    cook_rule
};

#-----------------------------------------------------------------------------

Readonly::Scalar our $RULE_INVALID_CHARACTER_REGEX =>
    qr/ ( [^()\s\w\d+\-*&|!] ) /xms;

#-----------------------------------------------------------------------------

Readonly::Scalar my $CONFIG_KEY => 'theme';

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ($self, %args) = @_;
    my $rule = $args{-rule} || $EMPTY;

    if ( $rule =~ m/$RULE_INVALID_CHARACTER_REGEX/xms ) {
        throw_global_value
            option_name     => $CONFIG_KEY,
            option_value    => $rule,
            message_suffix => qq{contains an invalid character: "$1".};
    }

    $self->{_rule} = cook_rule( $rule );

    return $self;
}

#-----------------------------------------------------------------------------

sub rule {
    my $self = shift;
    return $self->{_rule};
}

#-----------------------------------------------------------------------------

sub policy_is_thematic {

    my ($self, %args) = @_;
    my $policy = $args{-policy}
        || throw_internal 'The -policy argument is required';
    ref $policy
        || throw_internal 'The -policy must be an object';

    my $rule = $self->{_rule} or return 1;
    my %themes = hashify( $policy->get_themes() );

    # This bit of magic turns the rule into a perl expression that can be
    # eval-ed for truth.  Each theme name in the rule is translated to 1 or 0
    # if the $policy belongs in that theme.  For example:
    #
    # 'bugs && (pbp || core)'  ...could become... '1 && (0 || 1)'

    my $as_code = $rule; #Making a copy, so $rule is preserved
    $as_code =~ s/ ( [\w\d]+ ) /exists $themes{$1} || 0/gexms;
    my $is_thematic = eval $as_code;  ## no critic (ProhibitStringyEval)

    if ($EVAL_ERROR) {
        throw_global_value
            option_name     => $CONFIG_KEY,
            option_value    => $rule,
            message_suffix  => q{contains a syntax error.};
    }

    return $is_thematic;
}

#-----------------------------------------------------------------------------

sub cook_rule {
    my ($raw_rule) = @_;
    return if not defined $raw_rule;

    #Translate logical operators
    $raw_rule =~ s{\b not \b}{!}ixmsg;     # "not" -> "!"
    $raw_rule =~ s{\b and \b}{&&}ixmsg;    # "and" -> "&&"
    $raw_rule =~ s{\b or  \b}{||}ixmsg;    # "or"  -> "||"

    #Translate algebra operators (for backward compatibility)
    $raw_rule =~ s{\A [-] }{!}ixmsg;     # "-" -> "!"     e.g. difference
    $raw_rule =~ s{   [-] }{&& !}ixmsg;  # "-" -> "&& !"  e.g. difference
    $raw_rule =~ s{   [*] }{&&}ixmsg;    # "*" -> "&&"    e.g. intersection
    $raw_rule =~ s{   [+] }{||}ixmsg;    # "+" -> "||"    e.g. union

    my $cooked_rule = lc $raw_rule;  #Is now cooked!
    return $cooked_rule;
}


1;

__END__

#-----------------------------------------------------------------------------

#line 249

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
