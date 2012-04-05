#line 1
package Devel::StackTrace;
BEGIN {
  $Devel::StackTrace::VERSION = '1.27';
}

use 5.006;

use strict;
use warnings;

use Devel::StackTrace::Frame;
use File::Spec;
use Scalar::Util qw( blessed );

use overload
    '""'     => \&as_string,
    fallback => 1;

sub new {
    my $class = shift;
    my %p     = @_;

    # Backwards compatibility - this parameter was renamed to no_refs
    # ages ago.
    $p{no_refs} = delete $p{no_object_refs}
        if exists $p{no_object_refs};

    my $self = bless {
        index  => undef,
        frames => [],
        raw    => [],
        %p,
    }, $class;

    $self->_record_caller_data();

    return $self;
}

sub _record_caller_data {
    my $self = shift;

    # We exclude this method by starting one frame back.
    my $x = 1;
    while (
        my @c
        = do { package # the newline keeps dzil from adding a version here
                   DB; @DB::args = (); caller( $x++ ) }
        ) {
        my @args = @DB::args;

        if ( $self->{no_refs} ) {
            @args = map { ref $_ ? $self->_ref_to_string($_) : $_ } @args;
        }

        push @{ $self->{raw} }, {
            caller => \@c,
            args   => \@args,
            };
    }
}

sub _ref_to_string {
    my $self = shift;
    my $ref  = shift;

    return overload::AddrRef($ref)
        if blessed $ref && $ref->isa('Exception::Class::Base');

    return overload::AddrRef($ref) unless $self->{respect_overload};

    local $@;
    local $SIG{__DIE__};

    my $str = eval { $ref . '' };

    return $@ ? overload::AddrRef($ref) : $str;
}

sub _make_frames {
    my $self = shift;

    my $filter = $self->_make_frame_filter;

    my $raw = delete $self->{raw};
    for my $r ( @{$raw} ) {
        next unless $filter->($r);

        $self->_add_frame( $r->{caller}, $r->{args} );
    }
}

my $default_filter = sub {1};

sub _make_frame_filter {
    my $self = shift;

    my ( @i_pack_re, %i_class );
    if ( $self->{ignore_package} ) {
        $self->{ignore_package} = [ $self->{ignore_package} ]
            unless UNIVERSAL::isa( $self->{ignore_package}, 'ARRAY' );

        @i_pack_re
            = map { ref $_ ? $_ : qr/^\Q$_\E$/ } @{ $self->{ignore_package} };
    }

    my $p = __PACKAGE__;
    push @i_pack_re, qr/^\Q$p\E$/;

    if ( $self->{ignore_class} ) {
        $self->{ignore_class} = [ $self->{ignore_class} ]
            unless ref $self->{ignore_class};
        %i_class = map { $_ => 1 } @{ $self->{ignore_class} };
    }

    my $user_filter = $self->{frame_filter};

    return sub {
        return 0 if grep { $_[0]{caller}[0] =~ /$_/ } @i_pack_re;
        return 0 if grep { $_[0]{caller}[0]->isa($_) } keys %i_class;

        if ($user_filter) {
            return $user_filter->( $_[0] );
        }

        return 1;
    };
}

sub _add_frame {
    my $self = shift;
    my $c    = shift;
    my $args = shift;

    # eval and is_require are only returned when applicable under 5.00503.
    push @$c, ( undef, undef ) if scalar @$c == 6;

    if ( $self->{no_refs} ) {
    }

    push @{ $self->{frames} },
        Devel::StackTrace::Frame->new(
        $c,
        $args,
        $self->{respect_overload},
        $self->{max_arg_length},
        $self->{message},
        $self->{indent}
        );
}

sub next_frame {
    my $self = shift;

    # reset to top if necessary.
    $self->{index} = -1 unless defined $self->{index};

    my @f = $self->frames();
    if ( defined $f[ $self->{index} + 1 ] ) {
        return $f[ ++$self->{index} ];
    }
    else {
        $self->{index} = undef;
        return undef;
    }
}

sub prev_frame {
    my $self = shift;

    my @f = $self->frames();

    # reset to top if necessary.
    $self->{index} = scalar @f unless defined $self->{index};

    if ( defined $f[ $self->{index} - 1 ] && $self->{index} >= 1 ) {
        return $f[ --$self->{index} ];
    }
    else {
        $self->{index} = undef;
        return undef;
    }
}

sub reset_pointer {
    my $self = shift;

    $self->{index} = undef;
}

sub frames {
    my $self = shift;

    $self->_make_frames() if $self->{raw};

    return @{ $self->{frames} };
}

sub frame {
    my $self = shift;
    my $i    = shift;

    return unless defined $i;

    return ( $self->frames() )[$i];
}

sub frame_count {
    my $self = shift;

    return scalar( $self->frames() );
}

sub as_string {
    my $self = shift;

    my $st    = '';
    my $first = 1;
    foreach my $f ( $self->frames() ) {
        $st .= $f->as_string($first) . "\n";
        $first = 0;
    }

    return $st;
}

{
    package
        Devel::StackTraceFrame;

    our @ISA = 'Devel::StackTrace::Frame';
}

1;

# ABSTRACT: An object representing a stack trace



#line 443


__END__

