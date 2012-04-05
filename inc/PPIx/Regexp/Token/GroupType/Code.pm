#line 1
#line 35

package PPIx::Regexp::Token::GroupType::Code;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{
    my %perl_version_introduced = (
	'?'	=> '5.005',
	'?p'	=> '5.005',	# Presumed. I can find no documentation.
	'??'	=> '5.006',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{ $self->content() } || '5.005';
    }

}

{

    my %perl_version_removed = (
	'?p'	=> '5.009005',
    );

    sub perl_version_removed {
	my ( $self ) = @_;
	return $perl_version_removed{ $self->content() };
    }
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # Recognize '?{', '??{', or '?p{', the latter deprecated in Perl
    # 5.6, and removed in 5.10. The extra escapes are because the
    # non-open-bracket characters may appear as delimiters to the
    # expression.
    if ( my $accept = $tokenizer->find_regexp(
	    qr{ \A \\? \? \\? [?p]? \{ }smx ) ) {

	--$accept;	# Don't want the curly bracket.

	# Code token comes after.
	$tokenizer->expect( 'PPIx::Regexp::Token::Code' );

	return $accept;
    }

    return;
}

1;

__END__

#line 123

# ex: set textwidth=72 :
