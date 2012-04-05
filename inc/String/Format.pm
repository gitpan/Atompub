#line 1
package String::Format;

# ----------------------------------------------------------------------
#  Copyright (C) 2002,2009 darren chamberlain <darren@cpan.org>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; version 2.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION @EXPORT);
use Exporter;
use base qw(Exporter);

$VERSION = '1.16';
@EXPORT = qw(stringf);

sub _replace {
    my ($args, $orig, $alignment, $min_width,
        $max_width, $passme, $formchar) = @_;

    # For unknown escapes, return the orignial
    return $orig unless defined $args->{$formchar};

    $alignment = '+' unless defined $alignment;

    my $replacement = $args->{$formchar};
    if (ref $replacement eq 'CODE') {
        # $passme gets passed to subrefs.
        $passme ||= "";
        $passme =~ tr/{}//d;
        $replacement = $replacement->($passme);
    }

    my $replength = length $replacement;
    $min_width  ||= $replength;
    $max_width  ||= $replength;

    # length of replacement is between min and max
    if (($replength > $min_width) && ($replength < $max_width)) {
        return $replacement;
    }

    # length of replacement is longer than max; truncate
    if ($replength > $max_width) {
        return substr($replacement, 0, $max_width);
    }
    
    # length of replacement is less than min: pad
    if ($alignment eq '-') {
        # left align; pad in front
        return $replacement . " " x ($min_width - $replength);
    }

    # right align, pad at end
    return " " x ($min_width - $replength) . $replacement;
}

my $regex = qr/
               (%             # leading '%'
                (-)?          # left-align, rather than right
                (\d*)?        # (optional) minimum field width
                (?:\.(\d*))?  # (optional) maximum field width
                ({.*?})?      # (optional) stuff inside
                (\S)          # actual format character
             )/x;
sub stringf {
    my $format = shift || return;
    my $args = UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
       $args->{'n'} = "\n" unless exists $args->{'n'};
       $args->{'t'} = "\t" unless exists $args->{'t'};
       $args->{'%'} = "%"  unless exists $args->{'%'};

    $format =~ s/$regex/_replace($args, $1, $2, $3, $4, $5, $6)/ge;

    return $format;
}

sub stringfactory {
    shift;  # It's a class method, but we don't actually want the class
    my $args = UNIVERSAL::isa($_[0], "HASH") ? shift : { @_ };
    return sub { stringf($_[0], $args) };
}

1;
__END__

