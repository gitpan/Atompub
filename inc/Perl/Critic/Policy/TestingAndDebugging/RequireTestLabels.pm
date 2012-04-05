#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Policy/TestingAndDebugging/RequireTestLabels.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::MoreUtils qw(any);
use Perl::Critic::Utils qw{
    :characters :severities :data_conversion :classification :ppi
};
use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

Readonly::Hash my %LABEL_ARG_POS => (
   ok        => 1,
   is        => 2,
   isnt      => 2,
   like      => 2,
   unlike    => 2,
   cmp_ok    => 3,
   is_deeply => 2,
   pass      => 0,
   fail      => 0,
);

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Test without a label};
Readonly::Scalar my $EXPL => q{Add a label argument to all Test::More functions};

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'modules',
            description     => 'The additional modules to require labels for.',
            default_string  => $EMPTY,
            behavior        => 'string list',
            list_always_present_values => [ qw( Test::More ) ],
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM             }
sub default_themes   { return qw( core maintenance tests ) }
sub applies_to       { return 'PPI::Token::Word'           }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    my $arg_index = $LABEL_ARG_POS{$elem};
    return if not defined $arg_index;
    return if not is_function_call($elem);
    return if not $self->_has_test_more($doc);

    # Does the function call have enough arguments?
    my @args = parse_arg_list($elem);
    return if ( @args > $arg_index );

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _has_test_more {
    my ( $self, $doc ) = @_;

    # TODO: This method gets called every time violates() is invoked,
    # but it only needs to happen once per document.  Perhaps this
    # policy should just apply to PPI::Document, and then do its own
    # search for for method calls.  Since Perl::Critic::Document is
    # optimized, this should be pretty fast.

    my $includes = $doc->find('PPI::Statement::Include');
    return if not $includes;
    return any { exists $self->{_modules}->{$_->module()} }
        @{ $includes };
}

1;

#-----------------------------------------------------------------------------

__END__

#line 154

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
