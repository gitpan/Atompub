#line 1
package PPI::Token::BOM;

#line 40

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}

sub significant { '' }





#####################################################################
# Parsing Methods

my %bom_types = (
   "\x00\x00\xfe\xff" => 'UTF-32',
   "\xff\xfe\x00\x00" => 'UTF-32',
   "\xfe\xff"         => 'UTF-16',
   "\xff\xfe"         => 'UTF-16',
   "\xef\xbb\xbf"     => 'UTF-8',
);

sub __TOKENIZER__on_line_start {
	my $t = $_[1];
	$_ = $t->{line};

	if (m/^(\x00\x00\xfe\xff |  # UTF-32, big-endian
		\xff\xfe\x00\x00 |  # UTF-32, little-endian
		\xfe\xff         |  # UTF-16, big-endian
		\xff\xfe         |  # UTF-16, little-endian
		\xef\xbb\xbf)       # UTF-8
	    /xs) {
	   my $bom = $1;

	   if ($bom_types{$bom} ne 'UTF-8') {
	      return $t->_error("$bom_types{$bom} is not supported");
	   }

	   $t->_new_token('BOM', $bom) or return undef;
	   $t->{line_cursor} += length $bom;
	}

	# Continue just as if there was no BOM
	$t->{class} = 'PPI::Token::Whitespace';
	return $t->{class}->__TOKENIZER__on_line_start($t);
}

1;

#line 115
