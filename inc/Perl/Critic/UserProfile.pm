#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/UserProfile.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::UserProfile;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Config::Tiny qw();
use File::Spec qw();

use Perl::Critic::OptionsProcessor qw();
use Perl::Critic::Utils qw{ :characters policy_long_name policy_short_name };
use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Critic::Exception::Configuration::Generic qw{ throw_generic };
use Perl::Critic::PolicyConfig;

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, %args ) = @_;
    # The profile can be defined, undefined, or an empty string.
    my $profile = defined $args{-profile} ? $args{-profile} : _find_profile_path();
    $self->_load_profile( $profile );
    $self->_set_options_processor();
    return $self;
}

#-----------------------------------------------------------------------------

sub options_processor {

    my ($self) = @_;
    return $self->{_options_processor};
}

#-----------------------------------------------------------------------------

sub policy_params {

    my ( $self, $policy ) = @_;

    my $short_name = policy_short_name($policy);

    return Perl::Critic::PolicyConfig->new(
        $short_name,
        $self->raw_policy_params($policy),
    );
}

#-----------------------------------------------------------------------------

sub raw_policy_params {

    my ( $self, $policy ) = @_;
    my $profile = $self->{_profile};
    my $long_name  = ref $policy || policy_long_name( $policy );
    my $short_name = policy_short_name( $long_name );

    return
            $profile->{$short_name}
        ||  $profile->{$long_name}
        ||  $profile->{"-$short_name"}
        ||  $profile->{"-$long_name"}
        ||  {};
}

#-----------------------------------------------------------------------------

sub policy_is_disabled {

    my ( $self, $policy ) = @_;
    my $profile = $self->{_profile};
    my $long_name  = ref $policy || policy_long_name( $policy );
    my $short_name = policy_short_name( $long_name );

    return exists $profile->{"-$short_name"}
        || exists $profile->{"-$long_name"};
}

#-----------------------------------------------------------------------------

sub policy_is_enabled {

    my ( $self, $policy ) = @_;
    my $profile = $self->{_profile};
    my $long_name  = ref $policy || policy_long_name( $policy );
    my $short_name = policy_short_name( $long_name );

    return exists $profile->{$short_name}
        || exists $profile->{$long_name};
}

#-----------------------------------------------------------------------------

sub listed_policies {

    my ( $self, $policy ) = @_;
    my @normalized_policy_names = ();

    for my $policy_name ( sort keys %{$self->{_profile}} ) {
        $policy_name =~ s/\A - //xmso; #Chomp leading "-"
        my $policy_long_name = policy_long_name( $policy_name );
        push @normalized_policy_names, $policy_long_name;
    }

    return @normalized_policy_names;
}

#-----------------------------------------------------------------------------

sub source {
    my ( $self ) = @_;

    return $self->{_source};
}

sub _set_source {
    my ( $self, $source ) = @_;

    $self->{_source} = $source;

    return;
}

#-----------------------------------------------------------------------------
# Begin PRIVATE methods

Readonly::Hash my %LOADER_FOR => (
    ARRAY   => \&_load_profile_from_array,
    DEFAULT => \&_load_profile_from_file,
    HASH    => \&_load_profile_from_hash,
    SCALAR  => \&_load_profile_from_string,
);

sub _load_profile {

    my ( $self, $profile ) = @_;

    my $ref_type = ref $profile || 'DEFAULT';
    my $loader = $LOADER_FOR{$ref_type};

    if (not $loader) {
        throw_internal qq{Can't load UserProfile from type "$ref_type"};
    }

    $self->{_profile} = $loader->($self, $profile);
    return $self;
}

#-----------------------------------------------------------------------------

sub _set_options_processor {

    my ($self) = @_;
    my $profile = $self->{_profile};
    my $defaults = delete $profile->{__defaults__} || {};
    $self->{_options_processor} =
        Perl::Critic::OptionsProcessor->new( %{ $defaults } );
    return $self;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_file {
    my ( $self, $file ) = @_;

    # Handle special cases.
    return {} if not defined $file;
    return {} if $file eq $EMPTY;
    return {} if $file eq 'NONE';

    $self->_set_source( $file );

    my $profile = Config::Tiny->read( $file );
    if (not defined $profile) {
        my $errstr = Config::Tiny::errstr();
        throw_generic
            message => qq{Could not parse profile "$file": $errstr},
            source  => $file;
    }

    _fix_defaults_key( $profile );

    return $profile;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_array {
    my ( $self, $array_ref ) = @_;
    my $joined    = join qq{\n}, @{ $array_ref };
    my $profile = Config::Tiny->read_string( $joined );

    if (not defined $profile) {
        throw_generic 'Profile error: ' . Config::Tiny::errstr();
    }

    _fix_defaults_key( $profile );

    return $profile;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_string {
    my ( $self, $string ) = @_;
    my $profile = Config::Tiny->read_string( ${ $string } );

    if (not defined $profile) {
        throw_generic 'Profile error: ' . Config::Tiny::errstr();
    }

    _fix_defaults_key( $profile );

    return $profile;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_hash {
    my ( $self, $hash_ref ) = @_;
    return $hash_ref;
}

#-----------------------------------------------------------------------------

sub _find_profile_path {

    #Define default filename
    my $rc_file = '.perlcriticrc';

    #Check explicit environment setting
    return $ENV{PERLCRITIC} if exists $ENV{PERLCRITIC};

    #Check current directory
    return $rc_file if -f $rc_file;

    #Check home directory
    if ( my $home_dir = _find_home_dir() ) {
        my $path = File::Spec->catfile( $home_dir, $rc_file );
        return $path if -f $path;
    }

    #No profile defined
    return;
}

#-----------------------------------------------------------------------------

sub _find_home_dir {

    # Try using File::HomeDir
    if ( eval { require File::HomeDir } ) {
        return File::HomeDir->my_home();
    }

    # Check usual environment vars
    for my $key (qw(HOME USERPROFILE HOMESHARE)) {
        next if not defined $ENV{$key};
        return $ENV{$key} if -d $ENV{$key};
    }

    # No home directory defined
    return;
}

#-----------------------------------------------------------------------------

# !$%@$%^ Config::Tiny uses a completely non-descriptive name for global
# values.
sub _fix_defaults_key {
    my ( $profile ) = @_;

    my $defaults = delete $profile->{_};
    if ($defaults) {
        $profile->{__defaults__} = $defaults;
    }

    return;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 425

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
