#line 1
package PPI::Token::Attribute;

#line 33

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}




#####################################################################
# PPI::Token::Attribute Methods

#line 59

sub identifier {
	my $self = shift;
	$self->{content} =~ /^(.+?)\(/ ? $1 : $self->{content};
}

#line 80

sub parameters {
	my $self = shift;
	$self->{content} =~ /\((.+)\)$/ ? $1 : undef;
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Unless this is a '(', we are finished.
	unless ( $char eq '(' ) {
		# Finalise and recheck
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	# This is a bar(...) style attribute.
	# We are currently on the ( so scan in until the end.
	# We finish on the character AFTER our end
	my $string = $class->__TOKENIZER__scan_for_end( $t );
	if ( ref $string ) {
		# EOF
		$t->{token}->{content} .= $$string;
		$t->_finalize_token;
		return 0;
	}

	# Found the end of the attribute
	$t->{token}->{content} .= $string;
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

# Scan for a close braced, and take into account both escaping,
# and open close bracket pairs in the string. When complete, the
# method leaves the line cursor on the LAST character found.
sub __TOKENIZER__scan_for_end {
	my $t = $_[1];

	# Loop as long as we can get new lines
	my $string = '';
	my $depth = 0;
	while ( exists $t->{line} ) {
		# Get the search area
		my $search = $t->{line_cursor}
			? substr( $t->{line}, $t->{line_cursor} )
			: $t->{line};

		# Look for a match
		unless ( $search =~ /^((?:\\.|[^()])*?[()])/ ) {
			# Load in the next line and push to first character
			$string .= $search;
			$t->_fill_line(1) or return \$string;
			$t->{line_cursor} = 0;
			next;
		}

		# Add to the string
		$string .= $1;
		$t->{line_cursor} += length $1;

		# Alter the depth and continue if we arn't at the end
		$depth += ($1 =~ /\($/) ? 1 : -1 and next;

		# Found the end
		return $string;
	}

	# Returning the string as a reference indicates EOF
	\$string;
}

1;

#line 182
