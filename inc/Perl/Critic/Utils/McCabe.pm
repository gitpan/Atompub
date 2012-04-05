#line 1
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic/Utils/McCabe.pm $
#     $Date: 2011-12-21 14:40:10 -0800 (Wed, 21 Dec 2011) $
#   $Author: thaljef $
# $Revision: 4106 $
##############################################################################

package Perl::Critic::Utils::McCabe;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :data_conversion :classification };

use base 'Exporter';

#-----------------------------------------------------------------------------

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK =>
  qw( calculate_mccabe_of_sub calculate_mccabe_of_main );

#-----------------------------------------------------------------------------

Readonly::Hash my %LOGIC_OPS =>
    hashify( qw( && || ||= &&= or and xor ? <<= >>= ) );

Readonly::Hash my %LOGIC_KEYWORDS =>
    hashify( qw( if else elsif unless until while for foreach ) );

#-----------------------------------------------------------------------------

sub calculate_mccabe_of_sub {

    my ( $sub ) = @_;

    my $count = 1; # Minimum score is 1
    $count += _count_logic_keywords( $sub );
    $count += _count_logic_operators( $sub );

    return $count;
}

#-----------------------------------------------------------------------------

sub calculate_mccabe_of_main {

    my ( $doc ) = @_;

    my $count = 1; # Minimum score is 1
    $count += _count_main_logic_operators_and_keywords( $doc );
    return $count;
}

#-----------------------------------------------------------------------------

sub _count_main_logic_operators_and_keywords {

    my ( $doc ) = @_;

    # I can't leverage Perl::Critic::Document's fast search mechanism here
    # because we're not searching for elements by class name.  So to speed
    # things up, search for both keywords and operators at the same time.

    my $wanted = sub {

        my (undef, $elem) = @_;

        # Only count things that *are not* in a subroutine.  Returning an
        # explicit 'undef' here prevents PPI from descending into the node.

        ## no critic (ProhibitExplicitReturnUndef)
        return undef if $elem->isa('PPI::Statement::Sub');


        if ( $elem->isa('PPI::Token::Word') ) {
            return 0 if is_hash_key( $elem );
            return exists $LOGIC_KEYWORDS{$elem};
        }
        elsif ($elem->isa('PPI::Token::Operator') ) {
            return exists $LOGIC_OPS{$elem};
        }
    };

    my $logic_operators_and_keywords = $doc->find( $wanted );

    my $count = $logic_operators_and_keywords ?
      scalar @{$logic_operators_and_keywords} : 0;

    return $count;
}

#-----------------------------------------------------------------------------

sub _count_logic_keywords {

    my ( $sub ) = @_;
    my $count = 0;

    # Here, I'm using this round-about method of finding elements so
    # that I can take advantage of Perl::Critic::Document's faster
    # find() mechanism.  It can only search for elements by class name.

    my $keywords_ref = $sub->find('PPI::Token::Word');
    if ( $keywords_ref ) { # should always be true due to "sub" keyword
        my @filtered = grep { ! is_hash_key($_) } @{ $keywords_ref };
        $count = grep { exists $LOGIC_KEYWORDS{$_} } @filtered;
    }
    return $count;
}

#-----------------------------------------------------------------------------

sub _count_logic_operators {

    my ( $sub ) = @_;
    my $count = 0;

    # Here, I'm using this round-about method of finding elements so
    # that I can take advantage of Perl::Critic::Document's faster
    # find() mechanism.  It can only search for elements by class name.

    my $operators_ref = $sub->find('PPI::Token::Operator');
    if ( $operators_ref ) {
        $count = grep { exists $LOGIC_OPS{$_} }  @{ $operators_ref };
    }

    return $count;
}


1;

__END__

#-----------------------------------------------------------------------------

#line 201

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
