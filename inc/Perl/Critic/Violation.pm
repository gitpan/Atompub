#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Violation.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Violation;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Readonly;

use File::Basename qw< basename >;
use IO::String qw< >;
use Pod::PlainText qw< >;
use Scalar::Util qw< blessed >;
use String::Format qw< stringf >;

use overload ( q{""} => 'to_string', cmp => '_compare' );

use Perl::Critic::Utils qw< :characters :internal_lookup >;
use Perl::Critic::Utils::POD qw<
    get_pod_section_for_module
    trim_pod_section
>;
use Perl::Critic::Exception::Fatal::Internal qw< throw_internal >;

our $VERSION = '1.117';


Readonly::Scalar my $LOCATION_LINE_NUMBER               => 0;
Readonly::Scalar my $LOCATION_COLUMN_NUMBER             => 1;
Readonly::Scalar my $LOCATION_VISUAL_COLUMN_NUMBER      => 2;
Readonly::Scalar my $LOCATION_LOGICAL_LINE_NUMBER       => 3;
Readonly::Scalar my $LOCATION_LOGICAL_FILENAME          => 4;


# Class variables...
my $format = "%m at line %l, column %c. %e.\n"; # Default stringy format
my %diagnostics = ();  # Cache of diagnostic messages

#-----------------------------------------------------------------------------

Readonly::Scalar my $CONSTRUCTOR_ARG_COUNT => 5;

sub new {
    my ( $class, $desc, $expl, $elem, $sev ) = @_;

    # Check arguments to help out developers who might
    # be creating new Perl::Critic::Policy modules.

    if ( @_ != $CONSTRUCTOR_ARG_COUNT ) {
        throw_internal 'Wrong number of args to Violation->new()';
    }

    if ( eval { $elem->isa( 'Perl::Critic::Document' ) } ) {
        # break the facade, return the real PPI::Document
        $elem = $elem->ppi_document();
    }

    if ( not eval { $elem->isa( 'PPI::Element' ) } ) {
        throw_internal '3rd arg to Violation->new() must be a PPI::Element';
    }

    # Strip punctuation.  These are controlled by the user via the
    # formats.  He/She can use whatever makes sense to them.
    ($desc, $expl) = _chomp_periods($desc, $expl);

    # Create object
    my $self = bless {}, $class;
    $self->{_description} = $desc;
    $self->{_explanation} = $expl;
    $self->{_severity}    = $sev;
    $self->{_policy}      = caller;

    # PPI eviscerates the Elements in a Document when the Document gets
    # DESTROY()ed, and thus they aren't useful after it is gone.  So we have
    # to preemptively grab everything we could possibly want.
    $self->{_element_class} = blessed $elem;

    my $top = $elem->top();
    $self->{_filename} = $top->can('filename') ? $top->filename() : undef;
    $self->{_source}   = _line_containing_violation( $elem );
    $self->{_location} =
        $elem->location() || [ 0, 0, 0, 0, $self->filename() ];

    return $self;
}

#-----------------------------------------------------------------------------

sub set_format { return $format = verbosity_to_format( $_[0] ); }  ## no critic(ArgUnpacking)
sub get_format { return $format;         }

#-----------------------------------------------------------------------------

sub sort_by_location {  ## no critic(ArgUnpacking)

    ref $_[0] || shift;              # Can call as object or class method
    return scalar @_ if ! wantarray; # In case we are called in scalar context

    ## TODO: What if $a and $b are not Violation objects?
    return
        map {$_->[0]}
            sort { ($a->[1] <=> $b->[1]) || ($a->[2] <=> $b->[2]) }
                map {[$_, $_->location->[0] || 0, $_->location->[1] || 0]}
                    @_;
}

#-----------------------------------------------------------------------------

sub sort_by_severity {  ## no critic(ArgUnpacking)

    ref $_[0] || shift;              # Can call as object or class method
    return scalar @_ if ! wantarray; # In case we are called in scalar context

    ## TODO: What if $a and $b are not Violation objects?
    return
        map {$_->[0]}
            sort { $a->[1] <=> $b->[1] }
                map {[$_, $_->severity() || 0]}
                    @_;
}

#-----------------------------------------------------------------------------

sub location {
    my $self = shift;

    return $self->{_location};
}

#-----------------------------------------------------------------------------

sub line_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_LINE_NUMBER];
}

#-----------------------------------------------------------------------------

sub logical_line_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_LOGICAL_LINE_NUMBER];
}

#-----------------------------------------------------------------------------

sub column_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_COLUMN_NUMBER];
}

#-----------------------------------------------------------------------------

sub visual_column_number {
    my ($self) = @_;

    return $self->location()->[$LOCATION_VISUAL_COLUMN_NUMBER];
}

#-----------------------------------------------------------------------------

sub diagnostics {
    my ($self) = @_;
    my $policy = $self->policy();

    if ( not $diagnostics{$policy} ) {
        eval {              ## no critic (RequireCheckingReturnValueOfEval)
            my $module_name = ref $policy || $policy;
            $diagnostics{$policy} =
                trim_pod_section(
                    get_pod_section_for_module( $module_name, 'DESCRIPTION' )
                );
        };
        $diagnostics{$policy} ||= "    No diagnostics available\n";
    }
    return $diagnostics{$policy};
}

#-----------------------------------------------------------------------------

sub description {
    my $self = shift;
    return $self->{_description};
}

#-----------------------------------------------------------------------------

sub explanation {
    my $self = shift;
    my $expl = $self->{_explanation};
    if ( !$expl ) {
       $expl = '(no explanation)';
    }
    if ( ref $expl eq 'ARRAY' ) {
        my $page = @{$expl} > 1 ? 'pages' : 'page';
        $page .= $SPACE . join $COMMA, @{$expl};
        $expl = "See $page of PBP";
    }
    return $expl;
}

#-----------------------------------------------------------------------------

sub severity {
    my $self = shift;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub policy {
    my $self = shift;
    return $self->{_policy};
}

#-----------------------------------------------------------------------------

sub filename {
    my $self = shift;
    return $self->{_filename};
}

#-----------------------------------------------------------------------------

sub logical_filename {
    my ($self) = @_;

    return $self->location()->[$LOCATION_LOGICAL_FILENAME];
}

#-----------------------------------------------------------------------------

sub source {
    my $self = shift;
    return $self->{_source};
}

#-----------------------------------------------------------------------------

sub element_class {
    my ($self) = @_;

    return $self->{_element_class};
}

#-----------------------------------------------------------------------------

sub to_string {
    my $self = shift;

    my $long_policy = $self->policy();
    (my $short_policy = $long_policy) =~ s/ \A Perl::Critic::Policy:: //xms;

    # Wrap the more expensive ones in sub{} to postpone evaluation
    my %fspec = (
         'f' => sub { $self->logical_filename()             },
         'F' => sub { basename( $self->logical_filename() ) },
         'g' => sub { $self->filename()                     },
         'G' => sub { basename( $self->filename() )         },
         'l' => sub { $self->logical_line_number()          },
         'L' => sub { $self->line_number()                  },
         'c' => sub { $self->visual_column_number()         },
         'C' => sub { $self->element_class()                },
         'm' => $self->description(),
         'e' => $self->explanation(),
         's' => $self->severity(),
         'd' => sub { $self->diagnostics()                  },
         'r' => sub { $self->source()                       },
         'P' => $long_policy,
         'p' => $short_policy,
    );
    return stringf($format, %fspec);
}

#-----------------------------------------------------------------------------
# Apparently, some perls do not implicitly stringify overloading
# objects before doing a comparison.  This causes a couple of our
# sorting tests to fail.  To work around this, we overload C<cmp> to
# do it explicitly.
#
# 20060503 - More information:  This problem has been traced to
# Test::Simple versions <= 0.60, not perl itself.  Upgrading to
# Test::Simple v0.62 will fix the problem.  But rather than forcing
# everyone to upgrade, I have decided to leave this workaround in
# place.

sub _compare { return "$_[0]" cmp "$_[1]" }

#-----------------------------------------------------------------------------

sub _line_containing_violation {
    my ( $elem ) = @_;

    my $stmnt = $elem->statement() || $elem;
    my $code_string = $stmnt->content() || $EMPTY;

    # Split into individual lines
    my @lines = split qr{ \n\s* }xms, $code_string;

    # Take the line containing the element that is in violation
    my $inx = ( $elem->line_number() || 0 ) -
        ( $stmnt->line_number() || 0 );
    $inx > @lines and return $EMPTY;
    return $lines[$inx];
}

#-----------------------------------------------------------------------------

sub _chomp_periods {
    my @args = @_;

    for (@args) {
        next if not defined or ref;
        s{ [.]+ \z }{}xms
    }

    return @args;
}

#-----------------------------------------------------------------------------

1;

#-----------------------------------------------------------------------------

__END__

#line 595

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
