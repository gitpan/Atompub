#line 1
package PPIx::Regexp::Tokenizer;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Support };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    TOKEN_LITERAL
    TOKEN_UNKNOWN
};
use PPIx::Regexp::Token::Assertion		();
use PPIx::Regexp::Token::Backreference		();
use PPIx::Regexp::Token::Backtrack		();
use PPIx::Regexp::Token::CharClass::POSIX	();
use PPIx::Regexp::Token::CharClass::POSIX::Unknown	();
use PPIx::Regexp::Token::CharClass::Simple	();
use PPIx::Regexp::Token::Code			();
use PPIx::Regexp::Token::Comment		();
use PPIx::Regexp::Token::Condition		();
use PPIx::Regexp::Token::Control		();
use PPIx::Regexp::Token::Delimiter		();
use PPIx::Regexp::Token::Greediness		();
use PPIx::Regexp::Token::GroupType::Assertion	();
use PPIx::Regexp::Token::GroupType::BranchReset	();
use PPIx::Regexp::Token::GroupType::Code	();
use PPIx::Regexp::Token::GroupType::Modifier	();
use PPIx::Regexp::Token::GroupType::NamedCapture	();
use PPIx::Regexp::Token::GroupType::Subexpression	();
use PPIx::Regexp::Token::GroupType::Switch	();
use PPIx::Regexp::Token::Interpolation		();
use PPIx::Regexp::Token::Literal		();
use PPIx::Regexp::Token::Modifier		();
use PPIx::Regexp::Token::Operator		();
use PPIx::Regexp::Token::Quantifier		();
use PPIx::Regexp::Token::Recursion		();
use PPIx::Regexp::Token::Structure		();
use PPIx::Regexp::Token::Unknown		();
use PPIx::Regexp::Token::Whitespace		();
use PPIx::Regexp::Util qw{ __instance };
use Scalar::Util qw{ looks_like_number };

our $VERSION = '0.026';

{
    # Names of classes containing tokenization machinery. There are few
    # known ordering requirements, since each class recognizes its own,
    # and I have tried to prevent overlap. Absent such constraints, the
    # order is in percieved frequency of acceptance, to keep the search
    # as short as possible. If I were conscientious I would gather
    # statistics on this.
    my @classes = (	# TODO make readonly when acceptable way appears
	'PPIx::Regexp::Token::Literal',
	'PPIx::Regexp::Token::Interpolation',
	'PPIx::Regexp::Token::Control',			# Note 1
	'PPIx::Regexp::Token::CharClass::Simple',	# Note 2
        'PPIx::Regexp::Token::Quantifier',
	'PPIx::Regexp::Token::Greediness',
	'PPIx::Regexp::Token::CharClass::POSIX',	# Note 3
	'PPIx::Regexp::Token::Structure',
	'PPIx::Regexp::Token::Assertion',
	'PPIx::Regexp::Token::Backreference',
	'PPIx::Regexp::Token::Operator',		# Note 4
    );

    # Note 1: If we are in quote mode ( \Q ... \E ), Control makes a
    #		literal out of anything it sees other than \E. So it
    #		needs to come before almost all other tokenizers. Not
    #		Literal, which already makes literals, and not
    #		Interpolation, which is legal in quote mode, but
    #		everything else.

    # Note 2: CharClass::Simple must come after Literal, because it
    #		relies on Literal to recognize a Unicode named character
    #		( \N{something} ), so any \N that comes through to it
    #		must be the \N simple character class (which represents
    #		anything but a newline, and was introduced in Perl
    #		5.11.0.

    # Note 3: CharClass::POSIX has to come before Structure, since both
    #		look for square brackets, and CharClass::POSIX is the
    #		more particular.

    # Note 4: Operator relies on Literal making the characters literal
    #		if they appear in a context where they can not be
    #		operators, and Control making them literals if quoting,
    #		so it must come after both.

    sub _known_tokenizers {
	my ( $self ) = @_;

	my $mode = $self->{mode};

	my @expect;
	if ( $self->{expect_next} ) {
	    $self->{expect} = $self->{expect_next};
	    $self->{expect_next} = undef;
	}
	if ( $self->{expect} ) {
	    @expect = $self->_known_tokenizer_check(
		@{ $self->{expect} } );
	}

	exists $self->{known}{$mode} and return (
	    @expect, @{ $self->{known}{$mode} } );

	my @found = $self->_known_tokenizer_check( @classes );

	$self->{known}{$mode} = \@found;
	return (@expect, @found);
    }

    sub _known_tokenizer_check {
	my ( $self, @args ) = @_;

	my $mode = $self->{mode};

	my $handler = '__PPIX_TOKENIZER__' . $mode;
	my @found;

	foreach my $class ( @args ) {

	    $class->can( $handler ) or next;
	    push @found, $class;

	}

	return @found;
    }

}

{
    my $errstr;

    sub new {
	my ( $class, $re, %args ) = @_;
	ref $class and $class = ref $class;

	$errstr = undef;

	exists $args{default_modifiers}
	    and 'ARRAY' ne ref $args{default_modifiers}
	    and do {
		$errstr = 'default_modifiers must be an array reference';
		return;
	    };

	my $self = {
	    capture => undef,	# Captures from find_regexp.
	    content => undef,	# The string we are tokenizing.
	    cookie => {},	# Cookies
	    cursor_curr => 0,	# The current position in the string.
	    cursor_limit => undef, # The end of the portion of the
	    			   # string being tokenized.
	    cursor_orig => undef, # Position of cursor when tokenizer
	    			# called. Used by get_token to prevent
				# recursion.
	    cursor_modifiers => undef,	# Position of modifiers.
	    default_modifiers => $args{default_modifiers} || [],
	    delimiter_finish => undef,	# Finishing delimiter of regexp.
	    delimiter_re =>	undef,	# Recognize finishing delimiter.
	    delimiter_start => undef,	# Starting delimiter of regexp.
	    encoding => $args{encoding}, # Character encoding.
	    expect => undef,	# Extra classes to expect.
	    expect_next => undef, # Extra classes as of next parse cycle
	    failures => 0,	# Number of parse failures.
	    find => undef,	# String for find_regexp
	    known => {},	# Known tokenizers, by mode.
	    match => undef,	# Match from find_regexp.
	    mode => 'init',	# Initialize
	    modifiers => [{}],	# Modifier hash.
	    pending => [],	# Tokens made but not returned.
	    prior => TOKEN_UNKNOWN,	# Prior significant token.
	    source => $re,	# The object we were initialized with.
	    trace => __PACKAGE__->_defined_or(
		$args{trace}, $ENV{PPIX_REGEXP_TOKENIZER_TRACE}, 0 ),
	};

	if ( __instance( $re, 'PPI::Element' ) ) {
	    $self->{content} = $re->content();
	} elsif ( ref $re ) {
	    $errstr = ref( $re ) . ' not supported';
	    return;
	} else {
	    $self->{content} = $re;
	}

	bless $self, $class;

	$self->{content} = $self->decode( $self->{content} );

	if ( $self->{content} =~ m/ \s+ \z /smx ) {
	    $self->{cursor_limit} = $-[0];
	} else {
	    $self->{cursor_limit} = length $self->{content};
	}

	$self->{trace}
	    and warn "\ntokenizing '$self->{content}'\n";

	return $self;
    }

    sub errstr {
	return $errstr;
    }

}

sub capture {
    my ( $self ) = @_;
    $self->{capture} or return;
    defined wantarray or return;
    return wantarray ? @{ $self->{capture} } : $self->{capture};
}

sub content {
    my ( $self ) = @_;
    return $self->{content};
}

sub cookie {
    my ( $self, $name, @args ) = @_;
    defined $name
	or confess "Programming error - undefined cookie name";
    @args or return $self->{cookie}{$name};
    my $cookie = shift @args;
    if ( ref $cookie eq 'CODE' ) {
	return ( $self->{cookie}{$name} = $cookie );
    } elsif ( defined $cookie ) {
	confess "Programming error - cookie must be CODE ref or undef";
    } else {
	return delete $self->{cookie}{$name};
    }
}

sub default_modifiers {
    my ( $self ) = @_;
    return [ @{ $self->{default_modifiers} } ];
}

sub __effective_modifiers {
    my ( $self ) = @_;
    'HASH' eq ref $self->{effective_modifiers}
	or return {};
    return { %{ $self->{effective_modifiers} } };
}

sub encoding {
    my ( $self ) = @_;
    return $self->{encoding};
}

sub expect {
    my ( $self, @args ) = @_;
    $self->{expect_next} = [
	map { m/ \A PPIx::Regexp:: /smx ? $_ : 'PPIx::Regexp::' . $_ }
	@args
    ];
    $self->{expect} = undef;
    return;
}

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

sub find_matching_delimiter {
    my ( $self ) = @_;
    $self->{cursor_curr} ||= 0;
    my $start = substr
	$self->{content},
	$self->{cursor_curr},
	1;

    my $inx = $self->{cursor_curr};
    my $finish = (
	my $bracketed = $self->close_bracket( $start ) ) || $start;
    my $nest = 0;

    while ( ++$inx < $self->{cursor_limit} ) {
	my $char = substr $self->{content}, $inx, 1;
	if ( $char eq '\\' && $finish ne '\\' ) {
	    ++$inx;
	} elsif ( $bracketed && $char eq $start ) {
	    ++$nest;
	} elsif ( $char eq $finish ) {
	    --$nest < 0
		and return $inx - $self->{cursor_curr};
	}
    }

    return;
}

sub find_regexp {
    my ( $self, $regexp ) = @_;

    ref $regexp eq 'Regexp'
	or confess
	'Argument is a ', ( ref $regexp || 'scalar' ), ' not a Regexp';

    defined $self->{find} or $self->_remainder();

    $self->{find} =~ $regexp
	or return;

    my @capture;
    foreach my $inx ( 0 .. $#+ ) {
	if ( defined $-[$inx] && defined $+[$inx] ) {
	push @capture, $self->{capture} = substr
		    $self->{find},
		    $-[$inx],
		    $+[$inx] - $-[$inx];
	} else {
	    push @capture, undef;
	}
    }
    $self->{match} = shift @capture;
    $self->{capture} = \@capture;

    # The following circumlocution seems to be needed under Perl 5.13.0
    # for reasons I do not fathom -- at least in the case where
    # wantarray is false. RT 56864 details the symptoms, which I was
    # never able to reproduce outside Perl::Critic. But returning $+[0]
    # directly, the value could transmogrify between here and the
    # calling module.
##  my @data = ( $-[0], $+[0] );
##  return wantarray ? @data : $data[1];
    return wantarray ? ( $-[0] + 0, $+[0] + 0 ) : $+[0] + 0;
}

sub get_token {
    my ( $self ) = @_;

    caller eq __PACKAGE__ or $self->{cursor_curr} > $self->{cursor_orig}
	or confess 'Programming error - get_token() called without ',
	    'first calling make_token()';

    my $handler = '__PPIX_TOKENIZER__' . $self->{mode};

    my $character = substr(
	$self->{content},
	$self->{cursor_curr},
	1
    );

    return ( __PACKAGE__->$handler( $self, $character ) );
}

sub interpolates {
    my ( $self ) = @_;
    return $self->{delimiter_start} ne q{'};
}

sub make_token {
    my ( $self, $length, $class, $arg ) = @_;
    defined $class or $class = caller;

    if ( $length + $self->{cursor_curr} > $self->{cursor_limit} ) {
	$length = $self->{cursor_limit} - $self->{cursor_curr}
	    or return;
    }

    $class =~ m/ \A PPIx::Regexp:: /smx
	or $class = 'PPIx::Regexp::' . $class;
    my $content = substr
	    $self->{content},
	    $self->{cursor_curr},
	    $length;

    $self->{trace}
	and warn "make_token( $length, '$class' ) => '$content'\n";
    $self->{trace} > 1
	and warn "    make_token: cursor_curr = $self->{cursor_curr}; ",
	    "cursor_limit = $self->{cursor_limit}\n";
    my $token = $class->_new( $content ) or return;
    $token->significant() and $self->{expect} = undef;
    $token->__PPIX_TOKEN__post_make( $self, $arg );

    $token->isa( TOKEN_UNKNOWN ) and $self->{failures}++;

    $self->{cursor_curr} += $length;
    $self->{find} = undef;
    $self->{match} = undef;
    $self->{capture} = undef;

    foreach my $name ( keys %{ $self->{cookie} } ) {
	my $cookie = $self->{cookie}{$name};
	$cookie->( $self, $token )
	    or delete $self->{cookie}{$name};
    }

    # Record this token as the prior token if it is significant. We must
    # do this after processing cookies, so that the cookies have access
    # to the old token if they want.
    $token->significant()
	and $self->{prior} = $token;

    return $token;
}

sub match {
    my ( $self ) = @_;
    return $self->{match};
}

sub modifier {
    my ( $self, $modifier ) = @_;
    return $self->{modifiers}[-1]{$modifier};
}

sub modifier_duplicate {
    my ( $self ) = @_;
    push @{ $self->{modifiers} },
	{ %{ $self->{modifiers}[-1] } };
    return;
}

sub modifier_modify {
    my ( $self, %args ) = @_;

    # Modifier code is centralized in PPIx::Regexp::Token::Modifier
    $self->{modifiers}[-1] =
	PPIx::Regexp::Token::Modifier::__PPIX_TOKENIZER__modifier_modify(
	$self->{modifiers}[-1], \%args );

    return;

}

sub modifier_pop {
    my ( $self ) = @_;
    @{ $self->{modifiers} } > 1
	and pop @{ $self->{modifiers} };
    return;
}

sub next_token {
    my ( $self ) = @_;

    {

	if ( @{ $self->{pending} } ) {
	    return shift @{ $self->{pending} };
	}

	if ( $self->{cursor_curr} >= $self->{cursor_limit} ) {
	    $self->{cursor_limit} >= length $self->{content}
		and return;
	    $self->{mode} eq 'finish' and return;
	    $self->{mode} = 'finish';
	    $self->{cursor_limit}++;
	}

	if ( my @tokens = $self->get_token() ) {
	    push @{ $self->{pending} }, @tokens;
	    redo;

	}

    }

    return;

}

sub peek {
    my ( $self, $offset ) = @_;
    defined $offset or $offset = 0;
    $offset < 0 and return;
    $offset += $self->{cursor_curr};
    $offset >= $self->{cursor_limit} and return;
    return substr $self->{content}, $offset, 1;
}

sub ppi_document {
    my ( $self ) = @_;

    defined $self->{find} or $self->_remainder();

    return PPI::Document->new( \"$self->{find}" );
}

sub prior {
    my ( $self, $method, @args ) = @_;
    defined $method or return $self->{prior};
    $self->{prior}->can( $method )
	or confess 'Programming error - ',
	    ( ref $self->{prior} || $self->{prior} ),
	    ' does not support method ', $method;
    return $self->{prior}->$method( @args );
}

sub significant {
    return 1;
}

sub tokens {
    my ( $self ) = @_;

    my @rslt;
    while ( my $token = $self->next_token() ) {
	push @rslt, $token;
    }

    return @rslt;
}

sub _remainder {
    my ( $self ) = @_;

    $self->{cursor_curr} > $self->{cursor_limit}
	and confess "Programming error - Trying to find past end of string";
    $self->{find} = substr(
	$self->{content},
	$self->{cursor_curr},
	$self->{cursor_limit} - $self->{cursor_curr}
    );

    return;
}

sub __PPIX_TOKENIZER__init {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->{mode} = 'kaput';
    $tokenizer->{content} =~ m/ \A \s* ( qr | m | s )? ( \s* ) ( [^\w\s] ) /smx
	or return $tokenizer->make_token(
	    length( $tokenizer->{content} ), TOKEN_UNKNOWN );
#   my ( $type, $white, $delim ) = ( $1, $2, $3 );
    my ( $type, $white ) = ( $1, $2 );
    my $start_pos = defined $-[1] ? $-[1] :
	defined $-[2] ? $-[2] :
	defined $-[3] ? $-[3] : 0;

    defined $type or $type = '';
    $tokenizer->{type} = $type;

    my @tokens;
    $start_pos
	and push @tokens, $tokenizer->make_token( $start_pos,
	'PPIx::Regexp::Token::Whitespace' );
    push @tokens, $tokenizer->make_token( length $type,
	'PPIx::Regexp::Token::Structure' );
    length $white > 0
	and push @tokens, $tokenizer->make_token( length $white,
	'PPIx::Regexp::Token::Whitespace' );

    {
	my @mods = @{ $tokenizer->{default_modifiers} };
	if ( $tokenizer->{content} =~ m/ ( [[:lower:]]* ) \s* \z /smx ) {
	    my $mod = $1;
	    $tokenizer->{cursor_limit} -= length $mod;
	    push @mods, $mod;
	}
	$tokenizer->{effective_modifiers} =
	    PPIx::Regexp::Token::Modifier::__aggregate_modifiers (
		@mods );
	$tokenizer->{modifiers} = [
	    { %{ $tokenizer->{effective_modifiers} } },
	];
	$tokenizer->{cursor_modifiers} = $tokenizer->{cursor_limit};
    }

    $tokenizer->{delimiter_start} = substr
	$tokenizer->{content},
	$tokenizer->{cursor_curr},
	1;

    if ( $type eq 's' and my $offset = $tokenizer->find_matching_delimiter() ) {
	$tokenizer->{cursor_limit} = $tokenizer->{cursor_curr} + $offset;
    } else {
	$tokenizer->{cursor_limit} = $tokenizer->{cursor_modifiers} - 1;
    }

    $tokenizer->{delimiter_finish} = substr
	$tokenizer->{content},
	$tokenizer->{cursor_limit},
	1;
    $tokenizer->{delimiter_re} = undef;

    push @tokens, $tokenizer->make_token( 1,
	'PPIx::Regexp::Token::Delimiter' );

    $tokenizer->{mode} = 'regexp';

    return @tokens;
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    my $mode = $tokenizer->{mode};
    my $handler = '__PPIX_TOKENIZER__' . $mode;

    $tokenizer->{cursor_orig} = $tokenizer->{cursor_curr};
    foreach my $class( $tokenizer->_known_tokenizers() ) {
	my @tokens = grep { $_ } $class->$handler( $tokenizer, $character );
	$tokenizer->{trace}
	    and warn $class, "->$handler( \$tokenizer, '$character' )",
		" => (@tokens)\n";
	@tokens
	    and return ( map {
		ref $_ ? $_ : $tokenizer->make_token( $_,
		    $class ) } @tokens );
    }

    # Find a fallback processor for the character.
    my $fallback = __PACKAGE__->can( '__PPIX_TOKEN_FALLBACK__' . $mode )
	|| __PACKAGE__->can( '__PPIX_TOKEN_FALLBACK__regexp' )
	|| confess "Programming error - unable to find fallback for $mode";
    return $fallback->( $class, $tokenizer, $character );
}

*__PPIX_TOKENIZER__repl = \&__PPIX_TOKENIZER__regexp;

sub __PPIX_TOKEN_FALLBACK__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # As a fallback in regexp mode, any escaped character is a literal.
    if ( $character eq '\\'
	&& $tokenizer->{cursor_limit} - $tokenizer->{cursor_curr} > 1
    ) {
	return $tokenizer->make_token( 2, TOKEN_LITERAL );
    }

    # Any normal character is unknown.
    return $tokenizer->make_token( 1, TOKEN_UNKNOWN );
}

sub __PPIX_TOKEN_FALLBACK__repl {
    my ( $class, $tokenizer, $character ) = @_;

    # As a fallback in replacement mode, any escaped character is a literal.
    if ( $character eq '\\'
	&& defined ( my $next = $tokenizer->peek( 1 ) ) ) {

	if ( $tokenizer->interpolates() || $next eq q<'> || $next eq '\\' ) {
	    return $tokenizer->make_token( 2, TOKEN_LITERAL );
	}
	return $tokenizer->make_token( 1, TOKEN_LITERAL );
    }

    # So is any normal character.
    return $tokenizer->make_token( 1, TOKEN_LITERAL );
}

sub __PPIX_TOKENIZER__finish {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->{cursor_limit} > length $tokenizer->{content}
	and confess "Programming error - ran off string";
    my @tokens = $tokenizer->make_token( 1,
	'PPIx::Regexp::Token::Delimiter' );

    if ( $tokenizer->{cursor_curr} eq $tokenizer->{cursor_modifiers} ) {

	# We are out of string. Make the modifier token and close up
	# shop.
	my $trailer;
	if ( $tokenizer->{content} =~ m/ \s+ \z /smx ) {
	    $tokenizer->{cursor_limit} = $-[0];
	    $trailer = length( $tokenizer->{content} ) -
		$tokenizer->{cursor_curr};
	} else {
	    $tokenizer->{cursor_limit} = length $tokenizer->{content};
	}
	push @tokens, $tokenizer->make_token(
	    $tokenizer->{cursor_limit} - $tokenizer->{cursor_curr},
	    'PPIx::Regexp::Token::Modifier' );
	if ( $trailer ) {
	    $tokenizer->{cursor_limit} = length $tokenizer->{content};
	    push @tokens, $tokenizer->make_token(
		$trailer, 'PPIx::Regexp::Token::Whitespace' );
	}
	$tokenizer->{mode} = 'kaput';

    } else {

	# Clear the cookies, because we are going around again.
	$tokenizer->{cookie} = {};

	# Move the cursor limit to just before the modifiers.
	$tokenizer->{cursor_limit} = $tokenizer->{cursor_modifiers} - 1;

	# If the preceding regular expression was bracketed, we need to
	# consume possible whitespace and find another delimiter.

	if ( $tokenizer->close_bracket( $tokenizer->{delimiter_start} ) ) {
	    my $accept;
	    $accept = $tokenizer->find_regexp( qr{ \A \s+ }smx )
		and push @tokens, $tokenizer->make_token(
		$accept, 'PPIx::Regexp::Token::Whitespace' );
	    my $character = $tokenizer->peek();
	    $tokenizer->{delimiter_start} = $character;
	    push @tokens, $tokenizer->make_token(
		1, 'PPIx::Regexp::Token::Delimiter' );
	    $tokenizer->{delimiter_finish} = substr
		$tokenizer->{content},
		$tokenizer->{cursor_limit} - 1,
		1;
	    $tokenizer->{delimiter_re} = undef;
	}

	if ( $tokenizer->modifier( 'e' ) ) {
	    # With /e, the replacement portion is code. We make it all
	    # into one big PPIx::Regexp::Token::Code, slap on the
	    # trailing delimiter and modifiers, and return it all.
	    push @tokens, $tokenizer->make_token(
		$tokenizer->{cursor_limit} - $tokenizer->{cursor_curr},
		'PPIx::Regexp::Token::Code',
		{ perl_version_introduced => MINIMUM_PERL },
	    );
	    $tokenizer->{cursor_limit} = length $tokenizer->{content};
	    push @tokens, $tokenizer->make_token( 1,
		'PPIx::Regexp::Token::Delimiter' );
	    push @tokens, $tokenizer->make_token(
		$tokenizer->{cursor_limit} - $tokenizer->{cursor_curr},
		'PPIx::Regexp::Token::Modifier' );
	    $tokenizer->{mode} = 'kaput';
	} else {
	    # Put our mode to replacement.
	    $tokenizer->{mode} = 'repl';
	}

    }

    return @tokens;

}

1;

__END__

#line 1139

# ex: set textwidth=72 :
