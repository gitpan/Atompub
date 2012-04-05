#line 1
package PPI::Token::Pod;

#line 27

use strict;
use Params::Util qw{_INSTANCE};
use PPI::Token   ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# PPI::Token::Pod Methods

#line 71

sub merge {
	my $class = (! ref $_[0]) ? shift : return undef;

	# Check there are no bad arguments
	if ( grep { ! _INSTANCE($_, 'PPI::Token::Pod') } @_ ) {
		return undef;
	}

	# Get the tokens, and extract the lines
	my @content = ( map { [ $_->lines ] } @_ ) or return undef;

	# Remove the leading =pod tags, trailing =cut tags, and any empty lines
	# between them and the pod contents.
	foreach my $pod ( @content ) {
		# Leading =pod tag
		if ( @$pod and $pod->[0] =~ /^=pod\b/o ) {
			shift @$pod;
		}

		# Trailing =cut tag
		if ( @$pod and $pod->[-1] =~ /^=cut\b/o ) {
			pop @$pod;
		}

		# Leading and trailing empty lines
		while ( @$pod and $pod->[0]  eq '' ) { shift @$pod }
		while ( @$pod and $pod->[-1] eq '' ) { pop @$pod   }
	}

	# Remove any empty pod sections, and add the =pod and =cut tags
	# for the merged pod back to it.
	@content = ( [ '=pod' ], grep { @$_ } @content, [ '=cut' ] );

	# Create the new object
	$class->new( join "\n", map { join( "\n", @$_ ) . "\n" } @content );
}

#line 117

sub lines {
	split /(?:\015{1,2}\012|\015|\012)/, $_[0]->{content};
}






#####################################################################
# PPI::Element Methods

### XS -> PPI/XS.xs:_PPI_Token_Pod__significant 0.900+
sub significant { '' }





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_line_start {
	my $t = $_[1];

	# Add the line to the token first
	$t->{token}->{content} .= $t->{line};

	# Check the line to see if it is a =cut line
	if ( $t->{line} =~ /^=(\w+)/ ) {
		# End of the token
		$t->_finalize_token if lc $1 eq 'cut';
	}

	0;
}

1;

#line 178
