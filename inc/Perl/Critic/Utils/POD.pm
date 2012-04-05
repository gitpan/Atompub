#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Utils/POD.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Utils::POD;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;

use IO::String ();
use Pod::PlainText ();
use Pod::Select ();

# TODO: non-fatal generic?
use Perl::Critic::Exception::Fatal::Generic qw< throw_generic >;
use Perl::Critic::Exception::IO qw< throw_io >;
use Perl::Critic::Utils qw< :characters >;

use base 'Exporter';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    get_pod_file_for_module
    get_raw_pod_section_from_file
    get_raw_pod_section_from_filehandle
    get_raw_pod_section_from_string
    get_raw_pod_section_for_module
    get_pod_section_from_file
    get_pod_section_from_filehandle
    get_pod_section_from_string
    get_pod_section_for_module
    trim_raw_pod_section
    trim_pod_section
    get_raw_module_abstract_from_file
    get_raw_module_abstract_from_filehandle
    get_raw_module_abstract_from_string
    get_raw_module_abstract_for_module
    get_module_abstract_from_file
    get_module_abstract_from_filehandle
    get_module_abstract_from_string
    get_module_abstract_for_module
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub get_pod_file_for_module {
    my ($module_name) = @_;

    # No File::Spec: %INC always uses forward slashes.
    (my $relative_path = $module_name) =~ s< :: ></>xmsg;
    $relative_path .= '.pm';

    my $absolute_path = $INC{$relative_path} or return;

    (my $pod_path = $absolute_path) =~ s< [.] [^.]+ \z><.pod>xms;
    return $pod_path if -f $pod_path;

    return $absolute_path;
}

#-----------------------------------------------------------------------------

sub get_raw_pod_section_from_file {
    my ($file_name, $section_name) = @_;

    return _get_pod_section_from_file(
        $file_name,
        $section_name,
        Pod::Select->new(),
    );
}

#-----------------------------------------------------------------------------

sub get_raw_pod_section_from_filehandle {
    my ($file_handle, $section_name) = @_;

    return _get_pod_section_from_filehandle(
        $file_handle,
        $section_name,
        Pod::Select->new(),
    );
}

#-----------------------------------------------------------------------------

sub get_raw_pod_section_from_string {
    my ($source, $section_name) = @_;

    return _get_pod_section_from_string(
        $source,
        $section_name,
        Pod::Select->new(),
    );
}

#-----------------------------------------------------------------------------

sub get_raw_pod_section_for_module {
    my ($module_name, $section_name) = @_;

    my $file_name = get_pod_file_for_module($module_name)
        or throw_generic qq<Could not find POD for "$module_name".>;

    return get_raw_pod_section_from_file($file_name, $section_name);
}

#-----------------------------------------------------------------------------

sub get_pod_section_from_file {
    my ($file_name, $section_name) = @_;

    return _get_pod_section_from_file(
        $file_name,
        $section_name,
        Pod::PlainText->new(),
    );
}

#-----------------------------------------------------------------------------

sub get_pod_section_from_filehandle {
    my ($file_handle, $section_name) = @_;

    return _get_pod_section_from_filehandle(
        $file_handle,
        $section_name,
        Pod::PlainText->new(),
    );
}

#-----------------------------------------------------------------------------

sub get_pod_section_from_string {
    my ($source, $section_name) = @_;

    return _get_pod_section_from_string(
        $source,
        $section_name,
        Pod::PlainText->new(),
    );
}

#-----------------------------------------------------------------------------

sub get_pod_section_for_module {
    my ($module_name, $section_name) = @_;

    my $file_name = get_pod_file_for_module($module_name)
        or throw_generic qq<Could not find POD for "$module_name".>;

    return get_pod_section_from_file($file_name, $section_name);
}

#-----------------------------------------------------------------------------

sub _get_pod_section_from_file {
    my ($file_name, $section_name, $parser) = @_;

    open my $file_handle, '<', $file_name
        or throw_io
            message     => qq<Could not open "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    my $content =
        _get_pod_section_from_filehandle(
            $file_handle, $section_name, $parser,
        );

    close $file_handle
        or throw_io
            message     => qq<Could not close "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    return $content;
}

#-----------------------------------------------------------------------------

sub _get_pod_section_from_filehandle {
    my ($file_handle, $section_name, $parser) = @_;

    $parser->select($section_name);

    my $content = $EMPTY;
    my $content_handle = IO::String->new( \$content );

    $parser->parse_from_filehandle( $file_handle, $content_handle );

    return if $content eq $EMPTY;
    return $content;
}

#-----------------------------------------------------------------------------

sub _get_pod_section_from_string {
    my ($source, $section_name, $parser) = @_;

    my $source_handle = IO::String->new( \$source );

    return
        _get_pod_section_from_filehandle(
            $source_handle, $section_name, $parser,
        );
}

#-----------------------------------------------------------------------------

sub trim_raw_pod_section {
    my ($pod) = @_;

    return if not defined $pod;

    $pod =~ s< \A =head1 \b [^\n]* \n $ ><>xms;
    $pod =~ s< \A \s+ ><>xms;
    $pod =~ s< \s+ \z ><>xms;

    return $pod;
}

#-----------------------------------------------------------------------------

sub trim_pod_section {
    my ($pod) = @_;

    return if not defined $pod;

    $pod =~ s< \A [^\n]* \n ><>xms;
    $pod =~ s< \A \s* \n ><>xms;
    $pod =~ s< \s+ \z ><>xms;

    return $pod;
}

#-----------------------------------------------------------------------------

sub get_raw_module_abstract_from_file {
    my ($file_name) = @_;

    return
        _get_module_abstract_from_file(
            $file_name,
            Pod::Select->new(),
            \&trim_raw_pod_section,
        );
}

#-----------------------------------------------------------------------------

sub get_raw_module_abstract_from_filehandle {
    my ($file_handle) = @_;

    return
        _get_module_abstract_from_filehandle(
            $file_handle,
            Pod::Select->new(),
            \&trim_raw_pod_section,
        );
}

#-----------------------------------------------------------------------------

sub get_raw_module_abstract_from_string {
    my ($source) = @_;

    return
        _get_module_abstract_from_string(
            $source,
            Pod::Select->new(),
            \&trim_raw_pod_section,
        );
}

#-----------------------------------------------------------------------------

sub get_raw_module_abstract_for_module {
    my ($module_name) = @_;

    my $file_name = get_pod_file_for_module($module_name)
        or throw_generic qq<Could not find POD for "$module_name".>;

    return get_raw_module_abstract_from_file($file_name);
}

#-----------------------------------------------------------------------------

sub get_module_abstract_from_file {
    my ($file_name) = @_;

    return
        _get_module_abstract_from_file(
            $file_name,
            Pod::PlainText->new(),
            \&trim_pod_section,
        );
}

#-----------------------------------------------------------------------------

sub get_module_abstract_from_filehandle {
    my ($file_handle) = @_;

    return
        _get_module_abstract_from_filehandle(
            $file_handle,
            Pod::PlainText->new(),
            \&trim_pod_section,
        );
}

#-----------------------------------------------------------------------------

sub get_module_abstract_from_string {
    my ($source) = @_;

    return
        _get_module_abstract_from_string(
            $source,
            Pod::PlainText->new(),
            \&trim_pod_section,
        );
}

#-----------------------------------------------------------------------------

sub get_module_abstract_for_module {
    my ($module_name) = @_;

    my $file_name = get_pod_file_for_module($module_name)
        or throw_generic qq<Could not find POD for "$module_name".>;

    return get_module_abstract_from_file($file_name);
}

#-----------------------------------------------------------------------------

sub _get_module_abstract_from_file {
    my ($file_name, $parser, $trimmer) = @_;

    open my $file_handle, '<', $file_name
        or throw_io
            message     => qq<Could not open "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    my $module_abstract =
        _get_module_abstract_from_filehandle(
            $file_handle, $parser, $trimmer,
        );

    close $file_handle
        or throw_io
            message     => qq<Could not close "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    return $module_abstract;
}

#-----------------------------------------------------------------------------

sub _get_module_abstract_from_filehandle { ## no critic (RequireFinalReturn)
    my ($file_handle, $parser, $trimmer) = @_;

    my $name_section =
        _get_pod_section_from_filehandle( $file_handle, 'NAME', $parser );
    return if not $name_section;

    $name_section = $trimmer->($name_section);
    return if not $name_section;

    # Testing for parser class, blech.  But it's a lot simpler and it's all
    # hidden in the implementation.
    if ('Pod::Select' eq ref $parser) {
        if ( $name_section =~ m< \n >xms ) {
            throw_generic
                qq<Malformed NAME section in "$name_section". >
                . q<It must be on a single line>;
        }
    }
    else {
        $name_section =~ s< \s+ >< >xmsg;

        # Ugh.  Pod::PlainText splits up module names.
        if (
            $name_section =~ m<
                \A
                \s*
                (
                    \w [ \w:]+ \w
                )
                (
                    \s*
                    -
                    .*
                )?
                \z
            >xms
        ) {
            my ($module_name, $rest) = ($1, $2);

            $module_name =~ s/ [ ] //xms;

            $name_section = $module_name . ( $rest ? $rest : $EMPTY );
        }
    }

    if (
        $name_section =~ m<
            \A
            \s*
            [\w:]+              # Module name.
            \s+
            -                   # The required single hyphen.
            \s+
            (
                \S              # At least one non-whitespace.
                (?: .* \S)?     # Everything up to the last non-whitespace.
            )
            \s*
            \z
        >xms
    ) {
        my $module_abstract = $1;
        return $module_abstract;
    }

    if (
        $name_section =~ m<
            \A
            \s*
            [\w:]+              # Module name.
            (?: \s* - )?        # The single hyphen is now optional.
            \s*
            \z
        >xms
    ) {
        return;
    }

    throw_generic qq<Malformed NAME section in "$name_section".>;
}

#-----------------------------------------------------------------------------

sub _get_module_abstract_from_string {
    my ($source, $parser, $trimmer) = @_;

    my $source_handle = IO::String->new( \$source );

    return
        _get_module_abstract_from_filehandle(
            $source_handle, $parser, $trimmer,
        );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 711

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
