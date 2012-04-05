#line 1
#line 29

package PPIx::Regexp::Token::Greediness;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

my %greediness = (
    '?' => MINIMUM_PERL,
    '+' => '5.009005',
);

#line 57

sub could_be_greediness {
    my ( $class, $string ) = @_;
    return $greediness{$string};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return $greediness{ $self->content() } || MINIMUM_PERL;
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character, $char_type ) = @_;

    $tokenizer->prior( 'is_quantifier' ) or return;

    $greediness{$character} or return;

    return length $character;
}

1;

__END__

#line 104

# ex: set textwidth=72 :
