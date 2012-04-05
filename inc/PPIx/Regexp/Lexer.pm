#line 1
#line 32

package PPIx::Regexp::Lexer;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Support };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{ TOKEN_LITERAL TOKEN_UNKNOWN };
use PPIx::Regexp::Node::Range				();
use PPIx::Regexp::Structure				();
use PPIx::Regexp::Structure::Assertion			();
use PPIx::Regexp::Structure::BranchReset		();
use PPIx::Regexp::Structure::Code			();
use PPIx::Regexp::Structure::Capture			();
use PPIx::Regexp::Structure::CharClass			();
use PPIx::Regexp::Structure::Subexpression		();
use PPIx::Regexp::Structure::Main			();
use PPIx::Regexp::Structure::Modifier			();
use PPIx::Regexp::Structure::NamedCapture		();
use PPIx::Regexp::Structure::Quantifier			();
use PPIx::Regexp::Structure::Regexp			();
use PPIx::Regexp::Structure::Replacement		();
use PPIx::Regexp::Structure::Switch			();
use PPIx::Regexp::Structure::Unknown			();
use PPIx::Regexp::Token::Unmatched			();
use PPIx::Regexp::Tokenizer				();
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.026';

#line 74

{

    my $errstr;

    sub new {
	my ( $class, $tokenizer, %args ) = @_;
	ref $class and $class = ref $class;

	__instance( $tokenizer, 'PPIx::Regexp::Tokenizer' )
	    or $tokenizer = PPIx::Regexp::Tokenizer->new( $tokenizer, %args )
	    or do {
		$errstr = PPIx::Regexp::Tokenizer->errstr();
		return;
	    };

	my $self = {
	    deferred => [],	# Deferred tokens
	    failures => 0,
	    tokenizer => $tokenizer,
	};

	bless $self, $class;
	return $self;
    }

    sub errstr {
	return $errstr;
    }

}

#line 113

# Defined above

#line 126

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

#line 138

sub lex {
    my ( $self ) = @_;

    my @content;
    $self->{failures} = 0;

    # Accept everything up to the first delimiter.
    {
	my $token = $self->_get_token()
	    or return $self->_finalize( @content );
	$token->isa( 'PPIx::Regexp::Token::Delimiter' ) or do {
	    push @content, $token;
	    redo;
	};
	$self->_unget_token( $token );
    }

    # Accept the first delimited structure.
    push @content, ( my $regexp = $self->_get_delimited(
	    'PPIx::Regexp::Structure::Regexp' ) );

    # If we are a substitution ...
    if ( $content[0]->content() eq 's' ) {

	# Accept any insignificant stuff.
	while ( my $token = $self->_get_token() ) {
	    if ( $token->significant() ) {
		$self->_unget_token( $token );
		last;
	    } else {
		push @content, $token;
	    }
	}

	# Figure out if we should expect an opening bracket.
	my $expect_open_bracket = $self->close_bracket(
	    $regexp->start( 0 ) ) || 0;

	# Accept the next delimited structure.
	push @content, $self->_get_delimited(
	    'PPIx::Regexp::Structure::Replacement',
	    $expect_open_bracket,
	);
    }

    # Accept the modifiers (we hope!) plus any trailing white space.
    while ( my $token = $self->_get_token() ) {
	push @content, $token;
    }

    # Let all the elements finalize themselves, recording any additional
    # errors as they do so.
    $self->_finalize( @content );

    # If we found a regular expression (and we should have done so) ...
    if ( $regexp ) {

	# Retrieve the maximum capture group.
	my $max_capture = $regexp->max_capture_number();

	# If we have any back references
	if ( my $backrefs = $regexp->find(
		'PPIx::Regexp::Token::Backreference' ) ) {

	    # The break point for capture group numbers is either 9 or
	    # the actual number found, whichever is greater.
	    my $limit = $max_capture > 9 ? $max_capture : 9;

	    foreach my $elem ( @{ $backrefs } ) {

		# Named or relative captures are not at issue.
		$elem->is_named() and next;
		$elem->is_relative() and next;

		# Anything less than or equal to the break point remains
		# a capture group.
		$elem->absolute() <= $limit and next;

		# Anything greater than the break point (in decimal)
		# gets made a literal. Because the literal is octal, we
		# make an unknown instead if it contains non-octal
		# digits.
		if ( $elem->content() =~ m/ [89] /smx ) {
		    bless $elem, TOKEN_UNKNOWN;
		    # We must hand-increment the failures since we
		    # already finalized.
		    $self->{failures}++;
		} else {
		    bless $elem, TOKEN_LITERAL;
		}

	    }
	}
    }

    return @content;

}

# Finalize the content array, updating the parse failures count as we
# go.
sub _finalize {
    my ( $self, @content ) = @_;
    foreach my $elem ( @content ) {
	$self->{failures} += $elem->__PPIX_LEXER__finalize();
    }
    defined wantarray and return @content;
    return;
}

{

    my %bracket = (
	'{' => '}',
	'(' => ')',
	'[' => ']',
    ##  '<' => '>',
    );

    my %unclosed = (
	'{' => '_recover_curly',
    );

    sub _get_delimited {
	my ( $self, $class, $expect_open_bracket ) = @_;
	defined $expect_open_bracket or $expect_open_bracket = 1;

	my @rslt;
	$self->{_rslt} = \@rslt;

	if ( $expect_open_bracket ) {
	    if ( my $token = $self->_get_token() ) {
		push @rslt, [];
		if ( $token->isa( 'PPIx::Regexp::Token::Delimiter' ) ) {
		    push @{ $rslt[-1] }, '', $token;
		} else {
		    push @{ $rslt[-1] }, '', undef;
		    $self->_unget_token( $token );
		}
	    } else {
		return;
	    }
	} else {
	    push @rslt, [ '', undef ];
	}

	while ( my $token = $self->_get_token() ) {
	    if ( $token->isa( 'PPIx::Regexp::Token::Delimiter' ) ) {
		$self->_unget_token( $token );
		last;
	    }
	    if ( $token->isa( 'PPIx::Regexp::Token::Structure' ) ) {
		my $content = $token->content();

		if ( my $finish = $bracket{$content} ) {
		    # Open bracket
		    push @rslt, [ $finish, $token ];

		} elsif ( $content eq $rslt[-1][0] ) {

		    # Matched close bracket
		    $self->_make_node( $token );

		} elsif ( $content ne ')' ) {

		    # If the close bracket is not a parenthesis, it becomes
		    # a literal.
		    bless $token, TOKEN_LITERAL;
		    push @{ $rslt[-1] }, $token;

		} elsif ( $content eq ')'
			and @rslt > 1	# Ignore enclosing delimiter
			and my $recover = $unclosed{$rslt[-1][1]->content()} ) {
		    # If the close bracket is a parenthesis and there is a
		    # recovery procedure, we use it.
		    $self->$recover( $token );

		} else {

		    # Unmatched close with no recovery.
		    $self->{failures}++;
		    bless $token, 'PPIx::Regexp::Token::Unmatched';
		    push @{ $rslt[-1] }, $token;
		}

	    } else {
		push @{ $rslt[-1] }, $token;
	    }

	    # We have to hand-roll the Range object.
	    if ( __instance( $rslt[-1][-2], 'PPIx::Regexp::Token::Operator' )
		&& $rslt[-1][-2]->content() eq '-' ) {
		my @tokens = splice @{ $rslt[-1] }, -3;
		push @{ $rslt[-1] },
		    PPIx::Regexp::Node::Range->_new( @tokens );
	    }
	}

	while ( @rslt > 1 ) {
	    if ( my $recover = $unclosed{$rslt[-1][1]->content()} ) {
		$self->$recover();
	    } else {
		$self->{failures}++;
		$self->_make_node( undef );
	    }
	}

	if ( @rslt == 1 ) {
	    my @last = @{ pop @rslt };
	    shift @last;
	    push @last, $self->_get_token();
	    return $class->_new( @last );
	} else {
	    confess "Missing data";
	}

    }

}

#	$token = $self->_get_token();
#
#	This method returns the next token from the tokenizer.

sub _get_token {
    my ( $self ) = @_;

    if ( @{ $self->{deferred} } ) {
	return shift @{ $self->{deferred} };
    }

    my $token = $self->{tokenizer}->next_token() or return;

    return $token;
}

{

    my %handler = (
	'(' => '_round',
	'[' => '_square',
	'{' => '_curly',
    );

    sub _make_node {
	my ( $self, $token ) = @_;
	my @args = @{ pop @{ $self->{_rslt} } };
	shift @args;
	push @args, $token;
	my @node;
	if ( my $method = $handler{ $args[0]->content() } ) {
	    @node = $self->$method( \@args );
	}
	@node or @node = PPIx::Regexp::Structure->_new( @args );
	push @{ $self->{_rslt}[-1] }, @node;
	return;
    }

}

sub _curly {
    my ( $self, $args ) = @_;

    if ( $args->[-1] && $args->[-1]->is_quantifier() ) {

	# If the tokenizer has marked the right curly as a quantifier,
	# make the whole thing a quantifier structure.
	return PPIx::Regexp::Structure::Quantifier->_new( @{ $args } );

    } elsif ( $args->[-1] ) {

	# If there is a right curly but it is not a quantifier,
	# make both curlys into literals.
	foreach my $inx ( 0, -1 ) {
	    bless $args->[$inx], TOKEN_LITERAL;
	}

	# Try to recover possible quantifiers not recognized because we
	# thought this was a structure.
	$self->_recover_curly_quantifiers( $args );

	return @{ $args };

    } else {

	# If there is no right curly, just make a generic structure
	# TODO maybe this should be something else?
	return PPIx::Regexp::Structure->_new( @{ $args } );
    }
}

# Recover from an unclosed left curly.
sub _recover_curly {
    my ( $self, $token ) = @_;

    # Get all the stuff we have accumulated for this curly.
    my @content = @{ pop @{ $self->{_rslt} } };

    # Lose the right bracket, which we have already failed to match.
    shift @content;

    # Rebless the left curly to a literal.
    bless $content[0], TOKEN_LITERAL;

    # Try to recover possible quantifiers not recognized because we
    # thought this was a structure.
    $self->_recover_curly_quantifiers( \@content );

    # Shove the curly and its putative contents into whatever structure
    # we have going.
    # The checks are to try to trap things like RT 56864, though on
    # further reflection it turned out that you could get here with an
    # empty $self->{_rslt} on things like 'm{)}'. This one did not get
    # made into an RT ticket, but was fixed by not calling the recovery
    # code if $self->{_rslt} contained only the enclosing delimiters.
    'ARRAY' eq ref $self->{_rslt}
	or confess 'Programming error - $self->{_rslt} not array ref, ',
	    "parsing '", $self->{tokenizer}->content(), "' at ",
	    $token->content();
    @{ $self->{_rslt} }
	or confess 'Programming error - $self->{_rslt} empty, ',
	    "parsing '", $self->{tokenizer}->content(), "' at ",
	    $token->content();
    push @{ $self->{_rslt}[-1] }, @content;

    # Shove the mismatched delimiter back into the input so we can have
    # another crack at it.
    $token and $self->_unget_token( $token );

    # We gone.
    return;
}

sub _recover_curly_quantifiers {
    my ( $self, $args ) = @_;

    if ( __instance( $args->[0], TOKEN_LITERAL )
	&& __instance( $args->[1], TOKEN_UNKNOWN )
	&& PPIx::Regexp::Token::Quantifier->could_be_quantifier(
	$args->[1]->content() )
    ) {
	bless $args->[1], 'PPIx::Regexp::Token::Quantifier';

	if ( __instance( $args->[2], TOKEN_UNKNOWN )
	    && PPIx::Regexp::Token::Greediness->could_be_greediness(
		$args->[2]->content() )
	) {
	    bless $args->[2], 'PPIx::Regexp::Token::Greediness';
	}

    }

    return;
}

sub _round {
    my ( $self, $args ) = @_;

    # The instantiator will rebless based on the first token if need be.
    return PPIx::Regexp::Structure::Capture->_new( @{ $args } );
}

sub _square {
    my ( $self, $args ) = @_;
    return PPIx::Regexp::Structure::CharClass->_new( @{ $args } );
}

#	$self->_unget_token( $token );
#
#	This method caches its argument so that it will be returned by
#	the next call to C<_get_token()>. If more than one argument is
#	passed, they will be returned in the order given; that is,
#	_unget_token/_get_token work like unshift/shift.

sub _unget_token {
    my ( $self, @args ) = @_;
    unshift @{ $self->{deferred} }, @args;
    return $self;
}

1;

__END__

#line 545

# ex: set textwidth=72 :