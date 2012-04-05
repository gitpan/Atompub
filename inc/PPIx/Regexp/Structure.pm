#line 1
#line 41

package PPIx::Regexp::Structure;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Node };

use Carp qw{ confess };
use PPIx::Regexp::Util qw{ __instance };
use Scalar::Util qw{ refaddr };

our $VERSION = '0.026';

sub _new {
    my ( $class, @args ) = @_;
    my %brkt;
    if ( ref $args[0] eq 'HASH' ) {
	%brkt = %{ shift @args };
	foreach my $key ( qw{ start type finish } ) {
	    ref $brkt{$key} eq 'ARRAY' or $brkt{$key} = [ $brkt{$key} ];
	}
    } else {
	$brkt{finish} = [ @args ? pop @args : () ];
	$brkt{start} = [ @args ? shift @args : () ];
	while ( @args && ! $args[0]->significant() ) {
	    push @{ $brkt{start} }, shift @args;
	}
	$brkt{type} = [];
	if ( __instance( $args[0], 'PPIx::Regexp::Token::GroupType' ) ) {
	    push @{ $brkt{type} }, shift @args;
	    while ( @args && ! $args[0]->significant() ) {
		push @{ $brkt{type} }, shift @args;
	    }
	}
    }

    $class->_check_for_interpolated_match( \%brkt, \@args );

    my $self = $class->SUPER::_new( @args )
	or return;

    if ( __instance( $brkt{type}[0], 'PPIx::Regexp::Token::GroupType' ) ) {
	( my $reclass = ref $brkt{type}[0] ) =~
	    s/ Token::GroupType /Structure/smx;
	$reclass->can( 'start' )
	    or confess "Programming error - $reclass not loaded";
	bless $self, $reclass;
    }

    foreach my $key ( qw{ start type finish } ) {
	$self->{$key} = [];
	ref $brkt{$key} eq 'ARRAY'
	    or confess "Programming error - '$brkt{$key}' not an ARRAY";
	foreach my $val ( @{ $brkt{$key} } ) {
	    defined $val or next;
	    __instance( $val, 'PPIx::Regexp::Element' )
		or confess "Programming error - '$val' not a ",
		    "PPIx::Regexp::Element";
	    push @{ $self->{$key} }, $val;
	    $val->_parent( $self );
	}
    }
    return $self;
}

sub elements {
    my ( $self ) = @_;

    if ( wantarray ) {
	return (
	    @{ $self->{start} },
	    @{ $self->{type} },
	    @{ $self->{children} },
	    @{ $self->{finish} },
	);
    } elsif ( defined wantarray ) {
	my $size = scalar @{ $self->{start} };
	$size += scalar @{ $self->{type} };
	$size += scalar @{ $self->{children} };
	$size += scalar @{ $self->{finish} };
	return $size;
    } else {
	return;
    }
}

#line 143

sub finish {
    my ( $self, $inx ) = @_;
    wantarray and return @{ $self->{finish} };
    return $self->{finish}[ defined $inx ? $inx : 0 ];
}

sub first_element {
    my ( $self ) = @_;

    $self->{start}[0] and return $self->{start}[0];

    $self->{type}[0] and return $self->{type}[0];

    if ( my $elem = $self->SUPER::first_element() ) {
	return $elem;
    }

    $self->{finish}[0] and return $self->{finish}[0];

    return;
}

sub last_element {
    my ( $self ) = @_;

    $self->{finish}[-1] and return $self->{finish}[-1];

    if ( my $elem = $self->SUPER::last_element() ) {
	return $elem;
    }

    $self->{type}[-1] and return $self->{type}[-1];

    $self->{start}[-1] and return $self->{start}[-1];

    return;
}

#line 201

sub start {
    my ( $self, $inx ) = @_;
    wantarray and return @{ $self->{start} };
    return $self->{start}[ defined $inx ? $inx : 0 ];
}

#line 228

sub type {
    my ( $self, $inx ) = @_;
    wantarray and return @{ $self->{type} };
    return $self->{type}[ defined $inx ? $inx : 0 ];
}

# Check for things like (?$foo:...) or (?$foo)
sub _check_for_interpolated_match {
    my ( $class, $brkt, $args ) = @_;

    # Everything we are interested in begins with a literal '?' followed
    # by an interpolation.
    __instance( $args->[0], 'PPIx::Regexp::Token::Unknown' )
	and $args->[0]->content() eq '?'
	and __instance( $args->[1], 'PPIx::Regexp::Token::Interpolation' )
	or return;

    my $hiwater = 2;	# Record how far we got into the arguments for
    			# subsequent use detecting things like
			# (?$foo).

    # If we have a literal ':' as the third argument:
    # GroupType::Modifier, rebless the ':' so we know not to match
    # against it, and splice all three tokens into the type.
    if ( __instance( $args->[2], 'PPIx::Regexp::Token::Literal' )
	&& $args->[2]->content() eq ':' ) {

	# Rebless the '?' as a GroupType::Modifier.
	bless $args->[0], 'PPIx::Regexp::Token::GroupType::Modifier';
	# Note that we do _not_ want __PPIX_TOKEN__post_make here.

	# Rebless the ':' as a GroupType, just so it does not look like
	# something to match against.
	bless $args->[2], 'PPIx::Regexp::Token::GroupType';

	# Shove our three significant tokens into the type.
	push @{ $brkt->{type} }, splice @{ $args }, 0, 3;

	# Stuff all the immediately-following insignificant tokens into
	# the type as well.
	while ( @{ $args } && ! $args->[0]->significant() ) {
	    push @{ $brkt->{type} }, shift @{ $args };
	}

	# Return to the caller, since we have done all the damage we
	# can.
	return;
    }

    # If we have a literal '-' as the third argument, we might have
    # something like (?$on-$off:$foo).
    if ( __instance( $args->[2], 'PPIx::Regexp::Token::Literal' )
	&& $args->[2]->content() eq '-'
	&& __instance( $args->[3], 'PPIx::Regexp::Token::Interpolation' )
    ) {
	$hiwater = 4;

	if ( __instance( $args->[4], 'PPIx::Regexp::Token::Literal' )
	    && $args->[4]->content() eq ':' ) {

	    # Rebless the '?' as a GroupType::Modifier.
	    bless $args->[0], 'PPIx::Regexp::Token::GroupType::Modifier';
	    # Note that we do _not_ want __PPIX_TOKEN__post_make here.

	    # Rebless the '-' and ':' as GroupType, just so they do not
	    # look like something to match against.
	    bless $args->[2], 'PPIx::Regexp::Token::GroupType';
	    bless $args->[4], 'PPIx::Regexp::Token::GroupType';

	    # Shove our five significant tokens into the type.
	    push @{ $brkt->{type} }, splice @{ $args }, 0, 5;

	    # Stuff all the immediately-following insignificant tokens
	    # into the type as well.
	    while ( @{ $args } && ! $args->[0]->significant() ) {
		push @{ $brkt->{type} }, shift @{ $args };
	    }

	    # Return to the caller, since we have done all the damage we
	    # can.
	    return;
	}
    }

    # If the group contains _any_ significant tokens at this point, we
    # do _not_ have something like (?$foo).
    foreach my $inx ( $hiwater .. $#$args ) {
	$args->[$inx]->significant() and return;
    }

    # Rebless the '?' as a GroupType::Modifier.
    bless $args->[0], 'PPIx::Regexp::Token::GroupType::Modifier';
    # Note that we do _not_ want __PPIX_TOKEN__post_make here.

    # Shove all the contents of $args into type, using splice to leave
    # @{ $args } empty after we do this.
    push @{ $brkt->{type} }, splice @{ $args };

    # We have done all the damage we can.
    return;
}

1;

__END__

#line 357

# ex: set textwidth=72 :
