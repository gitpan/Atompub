#line 1
#line 81

package PPIx::Regexp;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Node };

use PPIx::Regexp::Lexer ();
use PPIx::Regexp::Token::Modifier ();	# For its modifier manipulations.
use PPIx::Regexp::Util qw{ __instance };
use Scalar::Util qw{ refaddr };

our $VERSION = '0.026';

#line 159

{

    my $errstr;

    sub new {
	my ( $class, $content, %args ) = @_;
	ref $class and $class = ref $class;

	$errstr = undef;

	my $tokenizer = PPIx::Regexp::Tokenizer->new(
	    $content, %args ) or do {
	    $errstr = PPIx::Regexp::Tokenizer->errstr();
	    return;
	};

	my $lexer = PPIx::Regexp::Lexer->new( $tokenizer, %args );
	my @nodes = $lexer->lex();
	my $self = $class->SUPER::_new( @nodes );
	$self->{source} = $content;
	$self->{failures} = $lexer->failures();
	$self->{effective_modifiers} =
	    $tokenizer->__effective_modifiers();
	return $self;
    }

    sub errstr {
	return $errstr;
    }

}

#line 220

{

    my %cache;

    our $DISABLE_CACHE;		# Leave this undocumented, at least for
				# now.

    sub _cache_size {
	return scalar keys %cache;
    }

    sub new_from_cache {
	my ( $class, $content, %args ) = @_;

	__instance( $content, 'PPI::Element' )
	    or return $class->new( $content, %args );

	$DISABLE_CACHE and return $class->new( $content, %args );

	my $addr = refaddr( $content );
	exists $cache{$addr} and return $cache{$addr};

	my $self = $class->new( $content, %args )
	    or return;

	$cache{$addr} = $self;

	return $self;

    }

    sub flush_cache {
	my @args = @_;

	ref $args[0] or shift @args;

	if ( @args ) {
	    foreach my $obj ( @args ) {
		if ( __instance( $obj, __PACKAGE__ ) &&
		    __instance( ( my $parent = $obj->source() ),
			'PPI::Element' ) ) {
		    delete $cache{ refaddr( $parent ) };
		}
	    }
	} else {
	    %cache = ();
	}
	return;
    }

}

sub can_be_quantified { return; }


#line 294

sub capture_names {
    my ( $self ) = @_;
    my $re = $self->regular_expression() or return;
    return $re->capture_names();
}

#line 328

sub delimiters {
    my ( $self, $inx ) = @_;

    my @rslt;
    foreach my $method ( qw{ regular_expression replacement } ) {
	defined ( my $obj = $self->$method() ) or next;
	push @rslt, $obj->delimiters();
    }

    defined $inx and return $rslt[$inx];
    wantarray and return @rslt;
    defined wantarray and return $rslt[0];
    return;
}

#line 351

# defined above, just after sub new.

#line 363

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

#line 386

sub max_capture_number {
    my ( $self ) = @_;
    my $re = $self->regular_expression() or return;
    return $re->max_capture_number();
}

#line 413

sub modifier {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Token::Modifier' );
}

#line 431

sub modifier_asserted {
    my ( $self, $modifier ) = @_;
    return PPIx::Regexp::Token::Modifier::__asserts(
	$self->{effective_modifiers},
	$modifier,
    );
}

#line 450

sub regular_expression {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Structure::Regexp' );
}

#line 469

sub replacement {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Structure::Replacement' );
}

#line 483

sub source {
    my ( $self ) = @_;
    return $self->{source};
}

#line 502

sub type {
    my ( $self ) = @_;
    return $self->_component( 'PPIx::Regexp::Token::Structure' );
}

sub _component {
    my ( $self, $class ) = @_;
    foreach my $elem ( $self->children() ) {
	$elem->isa( $class ) and return $elem;
    }
    return;
}

1;

__END__

#line 652

# ex: set textwidth=72 :
