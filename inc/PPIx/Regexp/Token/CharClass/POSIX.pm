#line 1
#line 35

package PPIx::Regexp::Token::CharClass::POSIX;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::CharClass };

use PPIx::Regexp::Constant qw{ COOKIE_CLASS MINIMUM_PERL };

our $VERSION = '0.026';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

##=head2 is_case_sensitive
##
##This override of the superclass method of the same name returns true if
##the character class is C<[:lower:]> or C<[:upper:]>, and false (but
##defined) for all other POSIX character classes.
##
##=cut
##
##{
##    my %case_sensitive = map { $_ => 1 } qw{ [:lower:] [:upper:] };
##
##    sub is_case_sensitive {
##	my ( $self ) = @_;
##	return $case_sensitive{ $self->content() } || 0;
##    }
##}

sub perl_version_introduced {
#   my ( $self ) = @_;
    return '5.006';
}

{

    my %class = (
	':' => __PACKAGE__,
    );

    sub __PPIX_TOKENIZER__regexp {
	my ( $class, $tokenizer, $character ) = @_;

	$tokenizer->cookie( COOKIE_CLASS ) or return;

	if ( my $accept = $tokenizer->find_regexp(
		qr{ \A [[] ( [.=:] ) \^? .*? \1 []] }smx ) ) {
	    my ( $punc ) = $tokenizer->capture();
	    return $tokenizer->make_token( $accept,
		$class{$punc} || __PACKAGE__ . '::Unknown' );
	}

	return;

    }

}

1;

__END__

#line 122

# ex: set textwidth=72 :
