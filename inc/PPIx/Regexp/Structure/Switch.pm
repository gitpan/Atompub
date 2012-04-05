#line 1
#line 28

package PPIx::Regexp::Structure::Switch;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    STRUCTURE_UNKNOWN
    TOKEN_UNKNOWN
};

our $VERSION = '0.026';

sub __PPIX_LEXER__finalize {
    my ( $self ) = @_;

    # Assume no errors.
    my $rslt = 0;

    # Number of allowed alternations not known yet.
    my $alternations;

    # If we are a valid switch, the first child is the condition. Make
    # sure we have a first child and that it is of the expected class.
    # If it is, determine how many alternations are allowed.
    if ( my $condition = $self->child( 0 ) ) {
	foreach my $class ( qw{
	    PPIx::Regexp::Structure::Assertion
	    PPIx::Regexp::Structure::Code
	    PPIx::Regexp::Token::Condition
	    } ) {
	    $condition->isa( $class ) or next;
	    $alternations = $condition->content() eq '(DEFINE)' ? 0 : 1;
	    last;
	}
    }

    if ( defined $alternations ) {
	# If we figured out how many alternations were allowed, count
	# them, changing surplus ones to the unknown token.
	foreach my $kid ( $self->children () ) {
	    $kid->isa( 'PPIx::Regexp::Token::Operator' ) or next;
	    $kid->content() eq '|' or next;
	    --$alternations >= 0 and next;
	    bless $kid, TOKEN_UNKNOWN;
	    $rslt++;
	}
    } else {
	# If we could not figure out how many alternations were allowed,
	# it means we did not understand our condition. Rebless
	# ourselves to the unknown structure and count a parse failure.
	bless $self, STRUCTURE_UNKNOWN;
	$rslt++;
    }

    # Delegate to the superclass to finalize our children, now that we
    # have finished messing with them.
    $rslt = $self->SUPER::__PPIX_LEXER__finalize();

    return $rslt;
}

1;

__END__

#line 119

# ex: set textwidth=72 :
