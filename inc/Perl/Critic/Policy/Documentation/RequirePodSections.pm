#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/Documentation/RequirePodSections.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::Documentation::RequirePodSections;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [133, 138];

Readonly::Scalar my $BOOK                => 'book';
Readonly::Scalar my $BOOK_FIRST_EDITION  => 'book_first_edition';
Readonly::Scalar my $MODULE_STARTER_PBP  => 'module_starter_pbp';
Readonly::Scalar my $M_S_PBP_0_0_3       => 'module_starter_pbp_0_0_3';

Readonly::Scalar my $DEFAULT_SOURCE      => $BOOK_FIRST_EDITION;

Readonly::Hash   my %SOURCE_TRANSLATION  => (
    $BOOK               => $BOOK_FIRST_EDITION,
    $BOOK_FIRST_EDITION => $BOOK_FIRST_EDITION,
    $MODULE_STARTER_PBP => $M_S_PBP_0_0_3,
    $M_S_PBP_0_0_3      => $M_S_PBP_0_0_3,
);

Readonly::Scalar my $EN_AU                       => 'en_AU';
Readonly::Scalar my $EN_US                       => 'en_US';
Readonly::Scalar my $ORIGINAL_MODULE_VERSION     => 'original';

Readonly::Hash my %SOURCE_DEFAULT_LANGUAGE     => (
    $BOOK_FIRST_EDITION => $ORIGINAL_MODULE_VERSION,
    $M_S_PBP_0_0_3      => $EN_AU,
);

Readonly::Scalar my $BOOK_FIRST_EDITION_US_LIB_SECTIONS =>
    [
        'NAME',
        'VERSION',
        'SYNOPSIS',
        'DESCRIPTION',
        'SUBROUTINES/METHODS',
        'DIAGNOSTICS',
        'CONFIGURATION AND ENVIRONMENT',
        'DEPENDENCIES',
        'INCOMPATIBILITIES',
        'BUGS AND LIMITATIONS',
        'AUTHOR',
        'LICENSE AND COPYRIGHT',
    ];

Readonly::Hash my %DEFAULT_LIB_SECTIONS => (
    $BOOK_FIRST_EDITION => {
        $ORIGINAL_MODULE_VERSION => $BOOK_FIRST_EDITION_US_LIB_SECTIONS,
        $EN_AU => [
            'NAME',
            'VERSION',
            'SYNOPSIS',
            'DESCRIPTION',
            'SUBROUTINES/METHODS',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
        ],
        $EN_US => $BOOK_FIRST_EDITION_US_LIB_SECTIONS,
    },
    $M_S_PBP_0_0_3 => {
        $EN_AU => [
            'NAME',
            'VERSION',
            'SYNOPSIS',
            'DESCRIPTION',
            'INTERFACE',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY',
        ],
        $EN_US => [
            'NAME',
            'VERSION',
            'SYNOPSIS',
            'DESCRIPTION',
            'INTERFACE',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY'
        ],
    },
);

Readonly::Hash my %DEFAULT_SCRIPT_SECTIONS => (
    $BOOK_FIRST_EDITION => {
        $ORIGINAL_MODULE_VERSION => [
            'NAME',
            'USAGE',
            'DESCRIPTION',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DIAGNOSTICS',
            'EXIT STATUS',
            'CONFIGURATION',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
        ],
        $EN_AU => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
        ],
        $EN_US => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
        ],
    },
    $M_S_PBP_0_0_3 => {
        $EN_AU => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENCE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY',
        ],
        $EN_US => [
            'NAME',
            'VERSION',
            'USAGE',
            'REQUIRED ARGUMENTS',
            'OPTIONS',
            'DESCRIPTION',
            'DIAGNOSTICS',
            'CONFIGURATION AND ENVIRONMENT',
            'DEPENDENCIES',
            'INCOMPATIBILITIES',
            'BUGS AND LIMITATIONS',
            'AUTHOR',
            'LICENSE AND COPYRIGHT',
            'DISCLAIMER OF WARRANTY',
        ],
    },
);

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'lib_sections',
            description     => 'The sections to require for modules (separated by qr/\s* [|] \s*/xms).',
            default_string  => $EMPTY,
            parser          => \&_parse_lib_sections,
        },
        {
            name            => 'script_sections',
            description     => 'The sections to require for programs (separated by qr/\s* [|] \s*/xms).',
            default_string  => $EMPTY,
            parser          => \&_parse_script_sections,
        },
        {
            name            => 'source',
            description     => 'The origin of sections to use.',
            default_string  => $DEFAULT_SOURCE,
            behavior        => 'enumeration',
            enumeration_values => [ keys %SOURCE_TRANSLATION ],
        },
        {
            name            => 'language',
            description     => 'The spelling of sections to use.',
            default_string  => $EMPTY,
            behavior        => 'enumeration',
            enumeration_values => [ $EN_AU, $EN_US ],
        },
    );
}

sub default_severity { return $SEVERITY_LOW            }
sub default_themes   { return qw(core pbp maintenance) }
sub applies_to       { return 'PPI::Document'          }

#-----------------------------------------------------------------------------

sub _parse_sections {
    my $config_string = shift;

    my @sections = split m{ \s* [|] \s* }xms, $config_string;

    return map { uc $_ } @sections;  # Normalize CaSe!
}

sub _parse_lib_sections {
    my ($self, $parameter, $config_string) = @_;

    if ( defined $config_string ) {
        $self->{_lib_sections} = [ _parse_sections( $config_string ) ];
    }

    return;
}

sub _parse_script_sections {
    my ($self, $parameter, $config_string) = @_;

    if ( defined $config_string ) {
        $self->{_script_sections} = [ _parse_sections( $config_string ) ];
    }

    return;
}

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ($self, $config) = @_;

    my $source = $self->{_source};
    if ( not defined $source or not defined $DEFAULT_LIB_SECTIONS{$source} ) {
        $source = $DEFAULT_SOURCE;
    }

    my $language = $self->{_language};
    if (
            not defined $language
        or  not defined $DEFAULT_LIB_SECTIONS{$source}{$language}
    ) {
        $language = $SOURCE_DEFAULT_LANGUAGE{$source};
    }

    if ( not $self->_sections_specified('_lib_sections') ) {
        $self->{_lib_sections} = $DEFAULT_LIB_SECTIONS{$source}{$language};
    }
    if ( not $self->_sections_specified('_script_sections') ) {
        $self->{_script_sections} =
            $DEFAULT_SCRIPT_SECTIONS{$source}{$language};
    }

    return $TRUE;
}

sub _sections_specified {
    my ( $self, $sections_key ) = @_;

    my $sections = $self->{$sections_key};

    return 0 if not defined $sections;

    return scalar @{ $sections };
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # This policy does not apply unless there is some real code in the
    # file.  For example, if this file is just pure POD, then
    # presumably this file is ancillary documentation and you can use
    # whatever headings you want.
    return if ! $doc->schild(0);

    my %found_sections = ();
    my @violations = ();

    my @required_sections =
        $doc->is_program()
            ? @{ $self->{_script_sections} }
            : @{ $self->{_lib_sections} };

    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if not $pods_ref;

    # Round up the names of all the =head1 sections
    my $pod_of_record;
    for my $pod ( @{ $pods_ref } ) {
        for my $found ( $pod =~ m{ ^ =head1 \s+ ( .+? ) \s* $ }gxms ) {
            # Use first matching POD as POD of record (RT #59268)
            $pod_of_record ||= $pod;
            #Leading/trailing whitespace is already removed
            $found_sections{ uc $found } = 1;
        }
    }

    # Compare the required sections against those we found
    for my $required ( @required_sections ) {
        if ( not exists $found_sections{$required} ) {
            my $desc = qq{Missing "$required" section in POD};
            # Report any violations against POD of record rather than whole
            # document (the point of RT #59268)
            # But if there are no =head1 records at all, rat out the
            # first pod found, as being better than blowing up. RT #67231
            push @violations, $self->violation( $desc, $EXPL,
                $pod_of_record || $pods_ref->[0] );
        }
    }

    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

#line 492

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
