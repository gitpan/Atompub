#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Statistics.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Statistics;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Utils::McCabe qw{ calculate_mccabe_of_sub };

#-----------------------------------------------------------------------------

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

sub new {
    my ( $class ) = @_;

    my $self = bless {}, $class;

    $self->{_modules} = 0;
    $self->{_subs} = 0;
    $self->{_statements} = 0;
    $self->{_lines} = 0;
    $self->{_lines_of_blank} = 0;
    $self->{_lines_of_comment} = 0;
    $self->{_lines_of_data} = 0;
    $self->{_lines_of_perl} = 0;
    $self->{_lines_of_pod} = 0;
    $self->{_violations_by_policy} = {};
    $self->{_violations_by_severity} = {};
    $self->{_total_violations} = 0;

    return $self;
}

#-----------------------------------------------------------------------------

sub accumulate {
    my ($self, $doc, $violations) = @_;

    $self->{_modules}++;

    my $subs = $doc->find('PPI::Statement::Sub');
    if ($subs) {
        foreach my $sub ( @{$subs} ) {
            $self->{_subs}++;
            $self->{_subs_total_mccabe} += calculate_mccabe_of_sub( $sub );
        }
    }

    my $statements = $doc->find('PPI::Statement');
    $self->{_statements} += $statements ? scalar @{$statements} : 0;

    ## no critic (RequireDotMatchAnything, RequireExtendedFormatting, RequireLineBoundaryMatching)
    my @lines = split /$INPUT_RECORD_SEPARATOR/, $doc->serialize();
    ## use critic
    $self->{_lines} += scalar @lines;
    {
        my ( $in_data, $in_pod );
        foreach ( @lines ) {
            if ( q{=} eq substr $_, 0, 1 ) {    ## no critic (ProhibitCascadingIfElse)
                $in_pod = not m/ \A \s* =cut \b /smx;
                $self->{_lines_of_pod}++;
            } elsif ( $in_pod ) {
                $self->{_lines_of_pod}++;
            } elsif ( q{__END__} eq $_ || q{__DATA__} eq $_ ) {
                $in_data = 1;
                $self->{_lines_of_perl}++;
            } elsif ( $in_data ) {
                $self->{_lines_of_data}++;
            } elsif ( m/ \A \s* \# /smx ) {
                $self->{_lines_of_comment}++;
            } elsif ( m/ \A \s* \z /smx ) {
                $self->{_lines_of_blank}++;
            } else {
                $self->{_lines_of_perl}++;
            }
        }
    }

    foreach my $violation ( @{ $violations } ) {
        $self->{_violations_by_severity}->{ $violation->severity() }++;
        $self->{_violations_by_policy}->{ $violation->policy() }++;
        $self->{_total_violations}++;
    }

    return;
}

#-----------------------------------------------------------------------------

sub modules {
    my ( $self ) = @_;

    return $self->{_modules};
}

#-----------------------------------------------------------------------------

sub subs {
    my ( $self ) = @_;

    return $self->{_subs};
}

#-----------------------------------------------------------------------------

sub statements {
    my ( $self ) = @_;

    return $self->{_statements};
}

#-----------------------------------------------------------------------------

sub lines {
    my ( $self ) = @_;

    return $self->{_lines};
}

#-----------------------------------------------------------------------------

sub lines_of_blank {
    my ( $self ) = @_;

    return $self->{_lines_of_blank};
}

#-----------------------------------------------------------------------------

sub lines_of_comment {
    my ( $self ) = @_;

    return $self->{_lines_of_comment};
}

#-----------------------------------------------------------------------------

sub lines_of_data {
    my ( $self ) = @_;

    return $self->{_lines_of_data};
}

#-----------------------------------------------------------------------------

sub lines_of_perl {
    my ( $self ) = @_;

    return $self->{_lines_of_perl};
}

#-----------------------------------------------------------------------------

sub lines_of_pod {
    my ( $self ) = @_;

    return $self->{_lines_of_pod};
}

#-----------------------------------------------------------------------------

sub _subs_total_mccabe {
    my ( $self ) = @_;

    return $self->{_subs_total_mccabe};
}

#-----------------------------------------------------------------------------

sub violations_by_severity {
    my ( $self ) = @_;

    return $self->{_violations_by_severity};
}

#-----------------------------------------------------------------------------

sub violations_by_policy {
    my ( $self ) = @_;

    return $self->{_violations_by_policy};
}

#-----------------------------------------------------------------------------

sub total_violations {
    my ( $self ) = @_;

    return $self->{_total_violations};
}

#-----------------------------------------------------------------------------

sub statements_other_than_subs {
    my ( $self ) = @_;

    return $self->statements() - $self->subs();
}

#-----------------------------------------------------------------------------

sub average_sub_mccabe {
    my ( $self ) = @_;

    return if $self->subs() == 0;

    return $self->_subs_total_mccabe() / $self->subs();
}

#-----------------------------------------------------------------------------

sub violations_per_file {
    my ( $self ) = @_;

    return if $self->modules() == 0;

    return $self->total_violations() / $self->modules();
}

#-----------------------------------------------------------------------------

sub violations_per_statement {
    my ( $self ) = @_;

    my $statements = $self->statements_other_than_subs();

    return if $statements == 0;

    return $self->total_violations() / $statements;
}

#-----------------------------------------------------------------------------

sub violations_per_line_of_code {
    my ( $self ) = @_;

    return if $self->lines() == 0;

    return $self->total_violations() / $self->lines();
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

#line 409

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
