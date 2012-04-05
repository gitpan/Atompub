#line 1
#line 77

package PPIx::Regexp::Token::Modifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    MODIFIER_GROUP_MATCH_SEMANTICS
};

our $VERSION = '0.026';

# Define modifiers that are to be aggregated internally for ease of
# computation.
my %aggregate = (
    a	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    aa	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    d	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    l	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    u	=> MODIFIER_GROUP_MATCH_SEMANTICS,
);
my %de_aggregate;
foreach my $value ( values %aggregate ) {
    $de_aggregate{$value}++;
}

#line 119

sub asserts {
    my ( $self, $modifier ) = @_;
    $self->{modifiers} ||= $self->_decode();
    if ( defined $modifier ) {
	return __asserts( $self->{modifiers}, $modifier );
    } else {
	return ( sort grep { defined $_ && $self->{modifiers}{$_} }
	    map { $de_aggregate{$_} ? $self->{modifiers}{$_} : $_ }
	    keys %{ $self->{modifiers} } );
    }
}

sub __asserts {
    my ( $present, $modifier ) = @_;
    my $bin = $aggregate{$modifier}
	or return $present->{$modifier};
    return defined $present->{$bin} && $modifier eq $present->{$bin};
}

sub can_be_quantified { return };

#line 152

sub match_semantics {
    my ( $self ) = @_;
    $self->{modifiers} ||= $self->_decode();
    return $self->{modifiers}{ MODIFIER_GROUP_MATCH_SEMANTICS() };
}

#line 168

sub modifiers {
    my ( $self ) = @_;
    $self->{modifiers} ||= $self->_decode();
    my %mods = %{ $self->{modifiers} };
    foreach my $bin ( keys %de_aggregate ) {
	defined ( my $val = delete $mods{$bin} )
	    or next;
	$mods{$bin} = $val;
    }
    return wantarray ? %mods : \%mods;
}

#line 194

sub negates {
    my ( $self, $modifier ) = @_;
    $self->{modifiers} ||= $self->_decode();
    # Note that since the values of hash entries that represent
    # aggregated modifiers will never be false (at least, not unless '0'
    # becomes a modifier) we need no special logic to handle them.
    defined $modifier
	or return ( sort grep { ! $self->{modifiers}{$_} }
	    keys %{ $self->{modifiers} } );
    return exists $self->{modifiers}{$modifier}
	&& ! $self->{modifiers}{$modifier};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return ( $self->{perl_version_introduced} ||=
	$self->_perl_version_introduced() );
}

sub _perl_version_introduced {
    my ( $self ) = @_;
    my $content = $self->content();
    my $is_statement_modifier = ( $content !~ m/ \A [(]? [?] /smx );
    my $match_semantics = $self->match_semantics();

    # Match semantics modifiers became available as regular expression
    # modifiers in 5.13.10.
    defined $match_semantics
	and $is_statement_modifier
	and return '5.013010';

    # /aa was introduced in 5.13.10.
    defined $match_semantics
	and 'aa' eq $match_semantics
	and return '5.013010';

    # /a was introduced in 5.13.9, but only in (?...), not as modifier
    # of the entire regular expression.
    defined $match_semantics
	and not $is_statement_modifier
	and 'a' eq $match_semantics
	and return '5.013009';

    # /d, /l, and /u were introduced in 5.13.6, but only in (?...), not
    # as modifiers of the entire regular expression.
    defined $match_semantics
	and not $is_statement_modifier
	and return '5.013006';

    # The '^' reassert-defaults modifier in embedded modifiers was
    # introduced in 5.13.6.
    not $is_statement_modifier
	and $content =~ m/ \^ /smx
	and return '5.013006';

    $self->asserts( 'r' ) and return '5.013002';
    $self->asserts( 'p' ) and return '5.009005';
    $self->content() =~ m/ \A [(]? [?] .* - /smx
			and return '5.005';
    $self->asserts( 'c' ) and return '5.004';
    return MINIMUM_PERL;
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };


# $present => __aggregate_modifiers( 'modifiers', ... );
#
# This subroutine is private to the PPIx::Regexp package. It may change
# or be retracted without notice. Its purpose is to support defaulted
# modifiers.
#
# Aggregate the given modifiers left-to-right, returning a hash of those
# present and their values.

sub __aggregate_modifiers {
    my ( @mods ) = @_;
    my %present;
    foreach my $content ( @mods ) {
	$content =~ s{ [?/]+ }{}smxg;
	if ( $content =~ m/ \A \^ /smx ) {
	    @present{ MODIFIER_GROUP_MATCH_SEMANTICS(), qw{ i s m x } }
		= qw{ d 0 0 0 0 };
	}

	# Have to do the global match rather than a split, because the
	# expression modifiers come through here too, and we need to
	# distinguish between s/.../.../e and s/.../.../ee.
	my $value = 1;
	while ( $content =~ m/ ( ( [[:alpha:]-] ) \2* ) /smxg ) {
	    if ( '-' eq $1 ) {
		$value = 0;
	    } elsif ( my $bin = $aggregate{$1} ) {
		$present{$bin} = $value ? $1 : undef;
	    } else {
		$present{$1} = $value;
	    }
	}
    }
    return \%present;
}

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return (
	[ qr{ \A [(] [?] [[:lower:]]* -? [[:lower:]]* [)] }smx ],
	[ qr{ \A [(] [?] \^ [[:lower:]]* [)] }smx ],
    );
}

# After the token is made, figure out what it asserts or negates.

sub __PPIX_TOKEN__post_make {
    my ( $self, $tokenizer ) = @_;
    defined $tokenizer
	and $tokenizer->modifier_modify( $self->modifiers() );
    return;
}

{

    # Called by the tokenizer to modify the current modifiers with a new
    # set. Both are passed as hash references, and a reference to the
    # new hash is returned.
    sub __PPIX_TOKENIZER__modifier_modify {
	my ( @args ) = @_;

	my %merged;
	foreach my $hash ( @args ) {
	    while ( my ( $key, $val ) = each %{ $hash } ) {
		if ( $val ) {
		    $merged{$key} = $val;
		} else {
		    delete $merged{$key};
		}
	    }
	}

	return \%merged;

    }

    # Decode modifiers from the content of the token.
    sub _decode {
	my ( $self ) = @_;
	return __aggregate_modifiers( $self->content() );
    }
}

1;

__END__

#line 376

# ex: set textwidth=72 :
