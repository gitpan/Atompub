#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Exception/AggregateConfiguration.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Exception::AggregateConfiguration;

use 5.006001;
use strict;
use warnings;

use Carp qw{ confess };
use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Utils qw{ :characters };

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::AggregateConfiguration' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A collected set of configuration exceptions.',
        fields      => [ qw{ exceptions } ],
        alias       => 'throw_aggregate',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_aggregate >;

#-----------------------------------------------------------------------------

sub new {
    my ($class, %options) = @_;

    my $exceptions = $options{exceptions};
    if (not $exceptions) {
        $options{exceptions} = [];
    }

    return $class->SUPER::new(%options);
}

#-----------------------------------------------------------------------------

sub add_exception {
    my ( $self, $exception ) = @_;

    push @{ $self->exceptions() }, $exception;

    return;
}

#-----------------------------------------------------------------------------

sub add_exceptions_from {
    my ( $self, $aggregate ) = @_;

    push @{ $self->exceptions() }, @{ $aggregate->exceptions() };

    return;
}

#-----------------------------------------------------------------------------

sub add_exception_or_rethrow {
    my ( $self, $eval_error ) = @_;

    return if not $eval_error;
    confess $eval_error if not ref $eval_error;

    if ( $eval_error->isa('Perl::Critic::Exception::Configuration') ) {
        $self->add_exception($eval_error);
    }
    elsif (
        $eval_error->isa('Perl::Critic::Exception::AggregateConfiguration')
    ) {
        $self->add_exceptions_from($eval_error);
    }
    else {
        die $eval_error; ## no critic (RequireCarping)
    }

    return;
}

#-----------------------------------------------------------------------------

sub has_exceptions {
    my ( $self ) = @_;

    return @{ $self->exceptions() } ? 1 : 0;
}

#-----------------------------------------------------------------------------

Readonly::Scalar my $MESSAGE_PREFIX => $EMPTY;
Readonly::Scalar my $MESSAGE_SUFFIX => "\n";
Readonly::Scalar my $MESSAGE_SEPARATOR => $MESSAGE_SUFFIX . $MESSAGE_PREFIX;

sub full_message {
    my ( $self ) = @_;

    my $message = $MESSAGE_PREFIX;
    $message .= join $MESSAGE_SEPARATOR, @{ $self->exceptions() };
    $message .= $MESSAGE_SUFFIX;

    return $message;
}

1;

#-----------------------------------------------------------------------------

__END__

#line 199

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
