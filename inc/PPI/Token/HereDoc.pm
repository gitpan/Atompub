#line 1
package PPI::Token::HereDoc;

#line 85

use strict;
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}





#####################################################################
# PPI::Token::HereDoc Methods

#line 114

sub heredoc {
	wantarray
		? @{shift->{_heredoc}}
		: scalar @{shift->{_heredoc}};
}

#line 132

sub terminator {
	shift->{_terminator};
}





#####################################################################
# Tokenizer Methods

# Parse in the entire here-doc in one call
sub __TOKENIZER__on_char {
	my $t     = $_[1];

	# We are currently located on the first char after the <<

	# Handle the most common form first for simplicity and speed reasons
	### FIXME - This regex, and this method in general, do not yet allow
	### for the null here-doc, which terminates at the first
	### empty line.
	my $rest_of_line = substr( $t->{line}, $t->{line_cursor} );
	unless ( $rest_of_line =~ /^( \s* (?: "[^"]*" | '[^']*' | `[^`]*` | \\?\w+ ) )/x  ) {
		# Degenerate to a left-shift operation
		$t->{token}->set_class('Operator');
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	# Add the rest of the token, work out what type it is,
	# and suck in the content until the end.
	my $token = $t->{token};
	$token->{content} .= $1;
	$t->{line_cursor} += length $1;

	# Find the terminator, clean it up and determine
	# the type of here-doc we are dealing with.
	my $content = $token->{content};
	if ( $content =~ /^\<\<(\w+)$/ ) {
		# Bareword
		$token->{_mode}       = 'interpolate';
		$token->{_terminator} = $1;

	} elsif ( $content =~ /^\<\<\s*\'(.*)\'$/ ) {
		# ''-quoted literal
		$token->{_mode}       = 'literal';
		$token->{_terminator} = $1;
		$token->{_terminator} =~ s/\\'/'/g;

	} elsif ( $content =~ /^\<\<\s*\"(.*)\"$/ ) {
		# ""-quoted literal
		$token->{_mode}       = 'interpolate';
		$token->{_terminator} = $1;
		$token->{_terminator} =~ s/\\"/"/g;

	} elsif ( $content =~ /^\<\<\s*\`(.*)\`$/ ) {
		# ``-quoted command
		$token->{_mode}       = 'command';
		$token->{_terminator} = $1;
		$token->{_terminator} =~ s/\\`/`/g;

	} elsif ( $content =~ /^\<\<\\(\w+)$/ ) {
		# Legacy forward-slashed bareword
		$token->{_mode}       = 'literal';
		$token->{_terminator} = $1;

	} else {
		# WTF?
		return undef;
	}

	# Define $line outside of the loop, so that if we encounter the
	# end of the file, we have access to the last line still.
	my $line;

	# Suck in the HEREDOC
	$token->{_heredoc} = [];
	my $terminator = $token->{_terminator} . "\n";
	while ( defined($line = $t->_get_line) ) {
		if ( $line eq $terminator ) {
			# Keep the actual termination line for consistency
			# when we are re-assembling the file
			$token->{_terminator_line} = $line;

			# The HereDoc is now fully parsed
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Add the line
		push @{$token->{_heredoc}}, $line;
	}

	# End of file.
	# Error: Didn't reach end of here-doc before end of file.
	# $line might be undef if we get NO lines.
	if ( defined $line and $line eq $token->{_terminator} ) {
		# If the last line matches the terminator
		# but is missing the newline, we want to allow
		# it anyway (like perl itself does). In this case
		# perl would normally throw a warning, but we will
		# also ignore that as well.
		pop @{$token->{_heredoc}};
		$token->{_terminator_line} = $line;
	} else {
		# The HereDoc was not properly terminated.
		$token->{_terminator_line} = undef;

		# Trim off the trailing whitespace
		if ( defined $token->{_heredoc}->[-1] and $t->{source_eof_chop} ) {
			chop $token->{_heredoc}->[-1];
			$t->{source_eof_chop} = '';
		}
	}

	# Set a hint for PPI::Document->serialize so it can
	# inexpensively repair it if needed when writing back out.
	$token->{_damaged} = 1;

	# The HereDoc is not fully parsed
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

#line 287
