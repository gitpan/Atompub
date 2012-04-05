#line 1
package Devel::StackTrace::Frame;
BEGIN {
  $Devel::StackTrace::Frame::VERSION = '1.27';
}

use strict;
use warnings;

# Create accessor routines
BEGIN {
    no strict 'refs';
    foreach my $f (
        qw( package filename line subroutine hasargs
        wantarray evaltext is_require hints bitmask args )
        ) {
        next if $f eq 'args';
        *{$f} = sub { my $s = shift; return $s->{$f} };
    }
}

{
    my @fields = (
        qw( package filename line subroutine hasargs wantarray
            evaltext is_require hints bitmask )
    );

    sub new {
        my $proto = shift;
        my $class = ref $proto || $proto;

        my $self = bless {}, $class;

        @{$self}{@fields} = @{ shift() };

        # fixup unix-style paths on win32
        $self->{filename} = File::Spec->canonpath( $self->{filename} );

        $self->{args} = shift;

        $self->{respect_overload} = shift;

        $self->{max_arg_length} = shift;

        $self->{message} = shift;

        $self->{indent} = shift;

        return $self;
    }
}

sub args {
    my $self = shift;

    return @{ $self->{args} };
}

sub as_string {
    my $self  = shift;
    my $first = shift;

    my $sub = $self->subroutine;

    # This code stolen straight from Carp.pm and then tweaked.  All
    # errors are probably my fault  -dave
    if ($first) {
        $sub
            = defined $self->{message}
            ? $self->{message}
            : 'Trace begun';
    }
    else {

        # Build a string, $sub, which names the sub-routine called.
        # This may also be "require ...", "eval '...' or "eval {...}"
        if ( my $eval = $self->evaltext ) {
            if ( $self->is_require ) {
                $sub = "require $eval";
            }
            else {
                $eval =~ s/([\\\'])/\\$1/g;
                $sub = "eval '$eval'";
            }
        }
        elsif ( $sub eq '(eval)' ) {
            $sub = 'eval {...}';
        }

        # if there are any arguments in the sub-routine call, format
        # them according to the format variables defined earlier in
        # this file and join them onto the $sub sub-routine string
        #
        # We copy them because they're going to be modified.
        #
        if ( my @a = $self->args ) {
            for (@a) {

                # set args to the string "undef" if undefined
                $_ = "undef", next unless defined $_;

                # hack!
                $_ = $self->Devel::StackTrace::_ref_to_string($_)
                    if ref $_;

                local $SIG{__DIE__};
                local $@;

                eval {
                    if ( $self->{max_arg_length}
                        && length $_ > $self->{max_arg_length} ) {
                        substr( $_, $self->{max_arg_length} ) = '...';
                    }

                    s/'/\\'/g;

                    # 'quote' arg unless it looks like a number
                    $_ = "'$_'" unless /^-?[\d.]+$/;

                    # print control/high ASCII chars as 'M-<char>' or '^<char>'
                    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
                    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
                };

                if ( my $e = $@ ) {
                    $_ = $e =~ /malformed utf-8/i ? '(bad utf-8)' : '?';
                }
            }

            # append ('all', 'the', 'arguments') to the $sub string
            $sub .= '(' . join( ', ', @a ) . ')';
            $sub .= ' called';
        }
    }

    # If the user opted into indentation (a la Carp::confess), pre-add a tab
    my $tab = $self->{indent} && !$first ? "\t" : q{};

    return "${tab}$sub at " . $self->filename . ' line ' . $self->line;
}

1;

# ABSTRACT: A single frame in a stack trace



#line 211


__END__

