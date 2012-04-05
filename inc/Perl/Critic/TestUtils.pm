#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/TestUtils.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::TestUtils;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use base 'Exporter';

use File::Path ();
use File::Spec ();
use File::Spec::Unix ();
use File::Temp ();
use File::Find qw( find );

use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::Exception::Fatal::Generic qw{ &throw_generic };
use Perl::Critic::Exception::Fatal::Internal qw{ &throw_internal };
use Perl::Critic::Utils qw{ :severities :data_conversion policy_long_name };
use Perl::Critic::PolicyFactory (-test => 1);

our $VERSION = '1.117';

Readonly::Array our @EXPORT_OK => qw(
    pcritique pcritique_with_violations
    critique  critique_with_violations
    fcritique fcritique_with_violations
    subtests_in_tree
    should_skip_author_tests
    get_author_test_skip_message
    starting_points_including_examples
    bundled_policy_names
    names_of_policies_willing_to_work
);

#-----------------------------------------------------------------------------
# If the user already has an existing perlcriticrc file, it will get
# in the way of these test.  This little tweak to ensures that we
# don't find the perlcriticrc file.

sub block_perlcriticrc {
    no warnings 'redefine';  ## no critic (ProhibitNoWarnings);
    *Perl::Critic::UserProfile::_find_profile_path = sub { return }; ## no critic (ProtectPrivateVars)
    return 1;
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using only one policy.  Returns the violations.

sub pcritique_with_violations {
    my($policy, $code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);
    return $c->critique($code_ref);
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using only one policy.  Returns the number
# of violations

sub pcritique {  ##no critic(ArgUnpacking)
    return scalar pcritique_with_violations(@_);
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using a specified config.  Returns the violations.

sub critique_with_violations {
    my ($code_ref, $config_ref) = @_;
    my $c = Perl::Critic->new( %{$config_ref} );
    return $c->critique($code_ref);
}

#-----------------------------------------------------------------------------
# Criticize a code snippet using a specified config.  Returns the
# number of violations

sub critique {  ##no critic(ArgUnpacking)
    return scalar critique_with_violations(@_);
}

#-----------------------------------------------------------------------------
# Like pcritique_with_violations, but forces a PPI::Document::File context.
# The $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

Readonly::Scalar my $TEMP_FILE_PERMISSIONS => oct 700;

sub fcritique_with_violations {
    my($policy, $code_ref, $filename, $config_ref) = @_;
    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $policy, -config => $config_ref);

    my $dir = File::Temp::tempdir( 'PerlCritic-tmpXXXXXX', TMPDIR => 1 );
    $filename ||= 'Temp.pm';
    my @fileparts = File::Spec::Unix->splitdir($filename);
    if (@fileparts > 1) {
        my $subdir = File::Spec->catdir($dir, @fileparts[0..$#fileparts-1]);
        File::Path::mkpath($subdir, 0, $TEMP_FILE_PERMISSIONS);
    }
    my $file = File::Spec->catfile($dir, @fileparts);
    if (open my $fh, '>', $file) {
        print {$fh} ${$code_ref};
        close $fh or throw_generic "unable to close $file: $OS_ERROR";
    }

    # Use eval so we can clean up before throwing an exception in case of
    # error.
    my @v = eval {$c->critique($file)};
    my $err = $EVAL_ERROR;
    File::Path::rmtree($dir, 0, 1);
    if ($err) {
        throw_generic $err;
    }
    return @v;
}

#-----------------------------------------------------------------------------
# Like pcritique, but forces a PPI::Document::File context.  The
# $filename arg is a Unix-style relative path, like 'Foo/Bar.pm'

sub fcritique {  ##no critic(ArgUnpacking)
    return scalar fcritique_with_violations(@_);
}

# Note: $include_extras is not documented in the POD because I'm not
# committing to the interface yet.
sub subtests_in_tree {
    my ($start, $include_extras) = @_;

    my %subtests;

    find(
        {
            wanted => sub {
                return if not -f $_;

                my ($fileroot) = m{(.+)[.]run\z}xms;

                return if not $fileroot;

                my @pathparts = File::Spec->splitdir($fileroot);
                if (@pathparts < 2) {
                    throw_internal 'confusing policy test filename ' . $_;
                }

                my $policy = join q{::}, @pathparts[-2, -1]; ## no critic (MagicNumbers)

                my $globals = _globals_from_file( $_ );
                if ( my $prerequisites = $globals->{prerequisites} ) {
                    foreach my $prerequisite ( keys %{$prerequisites} ) {
                        eval "require $prerequisite; 1" or return;
                    }
                }

                my @subtests = _subtests_from_file( $_ );

                if ($include_extras) {
                    $subtests{$policy} =
                        { subtests => [ @subtests ], globals => $globals };
                }
                else {
                    $subtests{$policy} = [ @subtests ];
                }

                return;
            },
            no_chdir => 1,
        },
        $start
    );

    return \%subtests;
}

# Answer whether author test should be run.
#
# Note: this code is duplicated in
# t/tlib/Perl/Critic/TestUtilitiesWithMinimalDependencies.pm.
# If you change this here, make sure to change it there.

sub should_skip_author_tests {
    return not $ENV{TEST_AUTHOR_PERL_CRITIC}
}

sub get_author_test_skip_message {
    ## no critic (RequireInterpolation);
    return 'Author test.  Set $ENV{TEST_AUTHOR_PERL_CRITIC} to a true value to run.';
}


sub starting_points_including_examples {
    return (-e 'blib' ? 'blib' : 'lib', 'examples');
}

sub _globals_from_file {
    my $test_file = shift;

    my %valid_keys = hashify qw< prerequisites >;

    return if -z $test_file;  # Skip if the Policy has a regular .t file.

    my %globals;

    open my $handle, '<', $test_file   ## no critic (RequireBriefOpen)
        or throw_internal "Couldn't open $test_file: $OS_ERROR";

    while ( my $line = <$handle> ) {
        chomp;

        if (
            my ($key,$value) =
                $line =~ m<\A [#][#] [ ] global [ ] (\S+) (?:\s+(.+))? >xms
        ) {
            next if not $key;
            if ( not $valid_keys{$key} ) {
                throw_internal "Unknown global key $key in $test_file";
            }

            if ( $key eq 'prerequisites' ) {
                $value = { hashify( words_from_string($value) ) };
            }
            $globals{$key} = $value;
        }
    }
    close $handle or throw_generic "unable to close $test_file: $OS_ERROR";

    return \%globals;
}

# The internal representation of a subtest is just a hash with some
# named keys.  It could be an object with accessors for safety's sake,
# but at this point I don't see why.
sub _subtests_from_file {
    my $test_file = shift;

    my %valid_keys = hashify qw( name failures parms TODO error filename optional_modules );

    return if -z $test_file;  # Skip if the Policy has a regular .t file.

    open my $fh, '<', $test_file   ## no critic (RequireBriefOpen)
        or throw_internal "Couldn't open $test_file: $OS_ERROR";

    my @subtests;

    my $incode = 0;
    my $cut_in_code = 0;
    my $subtest;
    my $lineno;
    while ( <$fh> ) {
        ++$lineno;
        chomp;
        my $inheader = /^## name/ .. /^## cut/; ## no critic (ExtendedFormatting LineBoundaryMatching DotMatchAnything)

        my $line = $_;

        if ( $inheader ) {
            $line =~ m/\A [#]/xms or throw_internal "Code before cut: $test_file";
            my ($key,$value) = $line =~ m/\A [#][#] [ ] (\S+) (?:\s+(.+))? /xms;
            next if !$key;
            next if $key eq 'cut';
            if ( not $valid_keys{$key} ) {
                throw_internal "Unknown key $key in $test_file";
            }

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push @subtests, _finalize_subtest( $subtest );
                    undef $subtest;
                }
                $subtest->{lineno} = $lineno;
                $incode = 0;
                $cut_in_code = 0;
            }
            if ($incode) {
                throw_internal "Header line found while still in code: $test_file";
            }
            $subtest->{$key} = $value;
        }
        elsif ( $subtest ) {
            $incode = 1;
            $cut_in_code ||= $line =~ m/ \A [#][#] [ ] cut \z /smx;
            # Don't start a subtest if we're not in one.
            # Don't add to the test if we have seen a '## cut'.
            $cut_in_code or push @{$subtest->{code}}, $line;
        }
        elsif (@subtests) {
            ## don't complain if we have not yet hit the first test
            throw_internal "Got some code but I'm not in a subtest: $test_file";
        }
    }
    close $fh or throw_generic "unable to close $test_file: $OS_ERROR";
    if ( $subtest ) {
        if ( $incode ) {
            push @subtests, _finalize_subtest( $subtest );
        }
        else {
            throw_internal "Incomplete subtest in $test_file";
        }
    }

    return @subtests;
}

sub _finalize_subtest {
    my $subtest = shift;

    if ( $subtest->{code} ) {
        $subtest->{code} = join "\n", @{$subtest->{code}};
    }
    else {
        throw_internal "$subtest->{name} has no code lines";
    }
    if ( !defined $subtest->{failures} ) {
        throw_internal "$subtest->{name} does not specify failures";
    }
    if ($subtest->{parms}) {
        $subtest->{parms} = eval $subtest->{parms}; ## no critic(StringyEval)
        if ($EVAL_ERROR) {
            throw_internal
                "$subtest->{name} has an error in the 'parms' property:\n"
                  . $EVAL_ERROR;
        }
        if ('HASH' ne ref $subtest->{parms}) {
            throw_internal
                "$subtest->{name} 'parms' did not evaluate to a hashref";
        }
    } else {
        $subtest->{parms} = {};
    }

    if (defined $subtest->{error}) {
        if ( $subtest->{error} =~ m{ \A / (.*) / \z }xms) {
            $subtest->{error} = eval {qr/$1/}; ## no critic (ExtendedFormatting LineBoundaryMatching DotMatchAnything)
            if ($EVAL_ERROR) {
                throw_internal
                    "$subtest->{name} 'error' has a malformed regular expression";
            }
        }
    }

    return $subtest;
}

sub bundled_policy_names {
    require ExtUtils::Manifest;
    my $manifest = ExtUtils::Manifest::maniread();
    my @policy_paths = map {m{\A lib/(Perl/Critic/Policy/.*).pm \z}xms} keys %{$manifest};
    my @policies = map { join q{::}, split m{/}xms, $_} @policy_paths;
    my @sorted_policies = sort @policies;
    return @sorted_policies;
}

sub names_of_policies_willing_to_work {
    my %configuration = @_;

    my @policies_willing_to_work =
        Perl::Critic::Config
            ->new( %configuration )
            ->policies();

    return map { ref $_ } @policies_willing_to_work;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 642

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
