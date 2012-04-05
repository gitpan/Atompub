#line 1
package Exception::Class;
BEGIN {
  $Exception::Class::VERSION = '1.32';
}

use 5.008001;

use strict;

use Exception::Class::Base;
use Scalar::Util qw(blessed);

our $BASE_EXC_CLASS;
BEGIN { $BASE_EXC_CLASS ||= 'Exception::Class::Base'; }

our %CLASSES;

sub import {
    my $class = shift;

    local $Exception::Class::Caller = caller();

    my %c;

    my %needs_parent;
    while ( my $subclass = shift ) {
        my $def = ref $_[0] ? shift : {};
        $def->{isa}
            = $def->{isa}
            ? ( ref $def->{isa} ? $def->{isa} : [ $def->{isa} ] )
            : [];

        $c{$subclass} = $def;
    }

    # We need to sort by length because if we check for keys in the
    # Foo::Bar:: stash, this creates a "Bar::" key in the Foo:: stash!
MAKE_CLASSES:
    foreach my $subclass ( sort { length $a <=> length $b } keys %c ) {
        my $def = $c{$subclass};

        # We already made this one.
        next if $CLASSES{$subclass};

        {
            no strict 'refs';
            foreach my $parent ( @{ $def->{isa} } ) {
                unless ( keys %{"$parent\::"} ) {
                    $needs_parent{$subclass} = {
                        parents => $def->{isa},
                        def     => $def
                    };
                    next MAKE_CLASSES;
                }
            }
        }

        $class->_make_subclass(
            subclass => $subclass,
            def      => $def || {},
        );
    }

    foreach my $subclass ( keys %needs_parent ) {

        # This will be used to spot circular references.
        my %seen;
        $class->_make_parents( \%needs_parent, $subclass, \%seen );
    }
}

sub _make_parents {
    my $class    = shift;
    my $needs    = shift;
    my $subclass = shift;
    my $seen     = shift;
    my $child    = shift;    # Just for error messages.

    no strict 'refs';

    # What if someone makes a typo in specifying their 'isa' param?
    # This should catch it.  Either it's been made because it didn't
    # have missing parents OR it's in our hash as needing a parent.
    # If neither of these is true then the _only_ place it is
    # mentioned is in the 'isa' param for some other class, which is
    # not a good enough reason to make a new class.
    die
        "Class $subclass appears to be a typo as it is only specified in the 'isa' param for $child\n"
        unless exists $needs->{$subclass}
            || $CLASSES{$subclass}
            || keys %{"$subclass\::"};

    foreach my $c ( @{ $needs->{$subclass}{parents} } ) {

        # It's been made
        next if $CLASSES{$c} || keys %{"$c\::"};

        die "There appears to be some circularity involving $subclass\n"
            if $seen->{$subclass};

        $seen->{$subclass} = 1;

        $class->_make_parents( $needs, $c, $seen, $subclass );
    }

    return if $CLASSES{$subclass} || keys %{"$subclass\::"};

    $class->_make_subclass(
        subclass => $subclass,
        def      => $needs->{$subclass}{def}
    );
}

sub _make_subclass {
    my $class = shift;
    my %p     = @_;

    my $subclass = $p{subclass};
    my $def      = $p{def};

    my $isa;
    if ( $def->{isa} ) {
        $isa = ref $def->{isa} ? join ' ', @{ $def->{isa} } : $def->{isa};
    }
    $isa ||= $BASE_EXC_CLASS;

    my $version_name = 'VERSION';

    my $code = <<"EOPERL";
package $subclass;

use base qw($isa);

our \$$version_name = '1.1';

1;

EOPERL

    if ( $def->{description} ) {
        ( my $desc = $def->{description} ) =~ s/([\\\'])/\\$1/g;
        $code .= <<"EOPERL";
sub description
{
    return '$desc';
}
EOPERL
    }

    my @fields;
    if ( my $fields = $def->{fields} ) {
        @fields = UNIVERSAL::isa( $fields, 'ARRAY' ) ? @$fields : $fields;

        $code
            .= "sub Fields { return (\$_[0]->SUPER::Fields, "
            . join( ", ", map {"'$_'"} @fields )
            . ") }\n\n";

        foreach my $field (@fields) {
            $code .= sprintf( "sub %s { \$_[0]->{%s} }\n", $field, $field );
        }
    }

    if ( my $alias = $def->{alias} ) {
        die "Cannot make alias without caller"
            unless defined $Exception::Class::Caller;

        no strict 'refs';
        *{"$Exception::Class::Caller\::$alias"}
            = sub { $subclass->throw(@_) };
    }

    if ( my $defaults = $def->{defaults} ) {
        $code
            .= "sub _defaults { return shift->SUPER::_defaults, our \%_DEFAULTS }\n";
        no strict 'refs';
        *{"$subclass\::_DEFAULTS"} = {%$defaults};
    }

    eval $code;

    die $@ if $@;

    $CLASSES{$subclass} = 1;
}

sub caught {
    my $e = $@;

    return $e unless $_[1];

    return unless blessed($e) && $e->isa( $_[1] );
    return $e;
}

sub Classes { sort keys %Exception::Class::CLASSES }

1;

# ABSTRACT: A module that allows you to declare real exception classes in Perl



#line 518


__END__

