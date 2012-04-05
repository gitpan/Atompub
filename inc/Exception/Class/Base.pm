#line 1
package Exception::Class::Base;
BEGIN {
  $Exception::Class::Base::VERSION = '1.32';
}

use strict;
use warnings;

use Class::Data::Inheritable;
use Devel::StackTrace 1.20;
use Scalar::Util qw( blessed );

use base qw(Class::Data::Inheritable);

BEGIN {
    __PACKAGE__->mk_classdata('Trace');
    __PACKAGE__->mk_classdata('NoRefs');
    __PACKAGE__->NoRefs(1);

    __PACKAGE__->mk_classdata('NoContextInfo');
    __PACKAGE__->NoContextInfo(0);

    __PACKAGE__->mk_classdata('RespectOverload');
    __PACKAGE__->RespectOverload(0);

    __PACKAGE__->mk_classdata('MaxArgLength');
    __PACKAGE__->MaxArgLength(0);

    sub Fields { () }
}

use overload
    # an exception is always true
    bool => sub {1}, '""' => 'as_string', fallback => 1;

# Create accessor routines
BEGIN {
    my @fields = qw( message pid uid euid gid egid time trace );

    foreach my $f (@fields) {
        my $sub = sub { my $s = shift; return $s->{$f}; };

        no strict 'refs';
        *{$f} = $sub;
    }
    *error = \&message;

    my %trace_fields = (
        package => 'package',
        file    => 'filename',
        line    => 'line',
    );

    while ( my ( $f, $m ) = each %trace_fields ) {
        my $sub = sub {
            my $s = shift;
            return $s->{$f} if exists $s->{$f};

            my $frame = $s->trace->frame(0);

            return $s->{$f} = $frame ? $frame->$m() : undef;
        };
        no strict 'refs';
        *{$f} = $sub;
    }
}

1;

sub Classes { Exception::Class::Classes() }

sub throw {
    my $proto = shift;

    $proto->rethrow if ref $proto;

    die $proto->new(@_);
}

sub rethrow {
    my $self = shift;

    die $self;
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize {
    my $self = shift;
    my %p = @_ == 1 ? ( error => $_[0] ) : @_;

    $self->{message} = $p{message} || $p{error} || '';

    $self->{show_trace} = $p{show_trace} if exists $p{show_trace};

    if ( $self->NoContextInfo() ) {
        $self->{show_trace} = 0;
        $self->{package} = $self->{file} = $self->{line} = undef;
    }
    else {
        # CORE::time is important to fix an error with some versions of
        # Perl
        $self->{time} = CORE::time();
        $self->{pid}  = $$;
        $self->{uid}  = $<;
        $self->{euid} = $>;
        $self->{gid}  = $(;
        $self->{egid} = $);

        my @ignore_class   = (__PACKAGE__);
        my @ignore_package = 'Exception::Class';

        if ( my $i = delete $p{ignore_class} ) {
            push @ignore_class, ( ref($i) eq 'ARRAY' ? @$i : $i );
        }

        if ( my $i = delete $p{ignore_package} ) {
            push @ignore_package, ( ref($i) eq 'ARRAY' ? @$i : $i );
        }

        $self->{trace} = Devel::StackTrace->new(
            ignore_class     => \@ignore_class,
            ignore_package   => \@ignore_package,
            no_refs          => $self->NoRefs,
            respect_overload => $self->RespectOverload,
            max_arg_length   => $self->MaxArgLength,
        );
    }

    my %fields = map { $_ => 1 } $self->Fields;
    while ( my ( $key, $value ) = each %p ) {
        next if $key =~ /^(?:error|message|show_trace)$/;

        if ( $fields{$key} ) {
            $self->{$key} = $value;
        }
        else {
            Exception::Class::Base->throw(
                error => "unknown field $key passed to constructor for class "
                    . ref $self );
        }
    }
}

sub description {
    return 'Generic exception';
}

sub show_trace {
    my $self = shift;

    return 0 unless $self->{trace};

    if (@_) {
        $self->{show_trace} = shift;
    }

    return exists $self->{show_trace} ? $self->{show_trace} : $self->Trace;
}

sub as_string {
    my $self = shift;

    my $str = $self->full_message;
    $str .= "\n\n" . $self->trace->as_string
        if $self->show_trace;

    return $str;
}

sub full_message { $_[0]->{message} }

#
# The %seen bit protects against circular inheritance.
#
eval <<'EOF' if $] == 5.006;
sub isa {
    my ( $inheritor, $base ) = @_;
    $inheritor = ref($inheritor) if ref($inheritor);

    my %seen;

    no strict 'refs';
    my @parents = ( $inheritor, @{"$inheritor\::ISA"} );
    while ( my $class = shift @parents ) {
        return 1 if $class eq $base;

        push @parents, grep { !$seen{$_}++ } @{"$class\::ISA"};
    }
    return 0;
}
EOF

sub caught {
    my $class = shift;

    my $e = $@;

    return unless defined $e && blessed($e) && $e->isa($class);
    return $e;
}

1;

# ABSTRACT: A base class for exception objects



#line 518


__END__

