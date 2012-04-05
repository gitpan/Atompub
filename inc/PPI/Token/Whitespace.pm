#line 1
package PPI::Token::Whitespace;

#line 42

use strict;
use Clone      ();
use PPI::Token ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Token';
}

#line 74

my $null = undef;

sub null {
	$null ||= $_[0]->new('');
	Clone::clone($null);
}

### XS -> PPI/XS.xs:_PPI_Token_Whitespace__significant 0.900+
sub significant { '' }

#line 98

sub tidy {
	$_[0]->{content} =~ s/^\s+?(?>\n)//;
	1;
}





#####################################################################
# Parsing Methods

# Build the class and commit maps
use vars qw{ @CLASSMAP @COMMITMAP %MATCHWORD };
BEGIN {
	@CLASSMAP  = ();
	@COMMITMAP = ();
	foreach (
		'a' .. 'u', 'w', 'y', 'z', 'A' .. 'Z', '_'
	) {
		$COMMITMAP[ord $_] = 'PPI::Token::Word';
	}
	foreach ( qw!; [ ] { } )! )       { $COMMITMAP[ord $_] = 'PPI::Token::Structure' }
	foreach ( 0 .. 9 )                { $CLASSMAP[ord $_]  = 'Number'   }
	foreach ( qw{= ? | + > . ! ~ ^} ) { $CLASSMAP[ord $_]  = 'Operator' }
	foreach ( qw{* $ @ & : %} )       { $CLASSMAP[ord $_]  = 'Unknown'  }

	# Miscellaneous remainder
	$COMMITMAP[ord '#'] = 'PPI::Token::Comment';
	$COMMITMAP[ord 'v'] = 'PPI::Token::Number::Version';
	$CLASSMAP[ord ',']  = 'PPI::Token::Operator';
	$CLASSMAP[ord "'"]  = 'Quote::Single';
	$CLASSMAP[ord '"']  = 'Quote::Double';
	$CLASSMAP[ord '`']  = 'QuoteLike::Backtick';
	$CLASSMAP[ord '\\'] = 'Cast';
	$CLASSMAP[ord '_']  = 'Word';
	$CLASSMAP[9]        = 'Whitespace'; # A horizontal tab
	$CLASSMAP[10]       = 'Whitespace'; # A newline
	$CLASSMAP[13]       = 'Whitespace'; # A carriage return
	$CLASSMAP[32]       = 'Whitespace'; # A normal space

	# Words (functions and keywords) after which a following / is
	# almost certainly going to be a regex
	%MATCHWORD = map { $_ => 1 } qw{
		split
		if
		unless
		grep
		map
	};
}

sub __TOKENIZER__on_line_start {
	my $t    = $_[1];
	my $line = $t->{line};

	# Can we classify the entire line in one go
	if ( $line =~ /^\s*$/ ) {
		# A whitespace line
		$t->_new_token( 'Whitespace', $line );
		return 0;

	} elsif ( $line =~ /^\s*#/ ) {
		# A comment line
		$t->_new_token( 'Comment', $line );
		$t->_finalize_token;
		return 0;

	} elsif ( $line =~ /^=(\w+)/ ) {
		# A Pod tag... change to pod mode
		$t->_new_token( 'Pod', $line );
		if ( $1 eq 'cut' ) {
			# This is an error, but one we'll ignore
			# Don't go into Pod mode, since =cut normally
			# signals the end of Pod mode
		} else {
			$t->{class} = 'PPI::Token::Pod';
		}
		return 0;

	} elsif ( $line =~ /^use v6\-alpha\;/ ) {
		# Indicates a Perl 6 block. Make the initial
		# implementation just suck in the entire rest of the
		# file.
		my @perl6 = ();
		while ( 1 ) {
			my $line6 = $t->_get_line;
			last unless defined $line6;
			push @perl6, $line6;
		}
		push @{ $t->{perl6} }, join '', @perl6;

		# We only sucked in the block, we don't actially do
		# anything to the "use v6..." line. So return as if
		# we didn't find anything at all.
		return 1;
	}

	1;
}

sub __TOKENIZER__on_char {
	my $t    = $_[1];
	my $char = ord substr $t->{line}, $t->{line_cursor}, 1;

	# Do we definately know what something is?
	return $COMMITMAP[$char]->__TOKENIZER__commit($t) if $COMMITMAP[$char];

	# Handle the simple option first
	return $CLASSMAP[$char] if $CLASSMAP[$char];

	if ( $char == 40 ) {  # $char eq '('
		# Finalise any whitespace token...
		$t->_finalize_token if $t->{token};

		# Is this the beginning of a sub prototype?
		# We are a sub prototype IF
		# 1. The previous significant token is a bareword.
		# 2. The one before that is the word 'sub'.
		# 3. The one before that is a 'structure'

		# Get the three previous significant tokens
		my $tokens = $t->_previous_significant_tokens(3);
		if ( $tokens ) {
			# A normal subroutine declaration
			my $p1 = $tokens->[1];
			my $p2 = $tokens->[2];
			if (
				$tokens->[0]->isa('PPI::Token::Word')
				and
				$p1->isa('PPI::Token::Word')
				and
				$p1->content eq 'sub'
				and (
					$p2->isa('PPI::Token::Structure')
					or (
						$p2->isa('PPI::Token::Whitespace')
						and
						$p2->content eq ''
					)
				)
			) {
				# This is a sub prototype
				return 'Prototype';
			}

			# An prototyped anonymous subroutine
			my $p0 = $tokens->[0];
			if ( $p0->isa('PPI::Token::Word') and $p0->content eq 'sub'
				# Maybe it's invoking a method named 'sub'
				and not ( $p1 and $p1->isa('PPI::Token::Operator') and $p1->content eq '->')
			) {
				return 'Prototype';
			}
		}

		# This is a normal open bracket
		return 'Structure';

	} elsif ( $char == 60 ) { # $char eq '<'
		# Finalise any whitespace token...
		$t->_finalize_token if $t->{token};

		# This is either "less than" or "readline quote-like"
		# Do some context stuff to guess which.
		my $prev = $t->_last_significant_token;

		# The most common group of less-thans are used like
		# $foo < $bar
		# 1 < $bar
		# $#foo < $bar
		return 'Operator' if $prev->isa('PPI::Token::Symbol');
		return 'Operator' if $prev->isa('PPI::Token::Magic');
		return 'Operator' if $prev->isa('PPI::Token::Number');
		return 'Operator' if $prev->isa('PPI::Token::ArrayIndex');

		# If it is <<... it's a here-doc instead
		my $next_char = substr( $t->{line}, $t->{line_cursor} + 1, 1 );
		if ( $next_char eq '<' ) {
			return 'Operator';
		}

		# The most common group of readlines are used like
		# while ( <...> )
		# while <>;
		my $prec = $prev->content;
		if ( $prev->isa('PPI::Token::Structure') and $prec eq '(' ) {
			return 'QuoteLike::Readline';
		}
		if ( $prev->isa('PPI::Token::Word') and $prec eq 'while' ) {
			return 'QuoteLike::Readline';
		}
		if ( $prev->isa('PPI::Token::Operator') and $prec eq '=' ) {
			return 'QuoteLike::Readline';
		}
		if ( $prev->isa('PPI::Token::Operator') and $prec eq ',' ) {
			return 'QuoteLike::Readline';
		}

		if ( $prev->isa('PPI::Token::Structure') and $prec eq '}' ) {
			# Could go either way... do a regex check
			# $foo->{bar} < 2;
			# grep { .. } <foo>;
			my $line = substr( $t->{line}, $t->{line_cursor} );
			if ( $line =~ /^<(?!\d)\w+>/ ) {
				# Almost definitely readline
				return 'QuoteLike::Readline';
			}
		}

		# Otherwise, we guess operator, which has been the default up
		# until this more comprehensive section was created.
		return 'Operator';

	} elsif ( $char == 47 ) { #  $char eq '/'
		# Finalise any whitespace token...
		$t->_finalize_token if $t->{token};

		# This is either a "divided by" or a "start regex"
		# Do some context stuff to guess ( ack ) which.
		# Hopefully the guess will be good enough.
		my $prev = $t->_last_significant_token;
		my $prec = $prev->content;

		# Most times following an operator, we are a regex.
		# This includes cases such as:
		# ,  - As an argument in a list 
		# .. - The second condition in a flip flop
		# =~ - A bound regex
		# !~ - Ditto
		return 'Regexp::Match' if $prev->isa('PPI::Token::Operator');

		# After a symbol
		return 'Operator' if $prev->isa('PPI::Token::Symbol');
		if ( $prec eq ']' and $prev->isa('PPI::Token::Structure') ) {
			return 'Operator';
		}

		# After another number
		return 'Operator' if $prev->isa('PPI::Token::Number');

		# After going into scope/brackets
		if (
			$prev->isa('PPI::Token::Structure')
			and (
				$prec eq '('
				or
				$prec eq '{'
				or
				$prec eq ';'
			)
		) {
			return 'Regexp::Match';
		}

		# Functions and keywords
		if (
			$MATCHWORD{$prec}
			and
			$prev->isa('PPI::Token::Word')
		) {
			return 'Regexp::Match';
		}

		# Or as the very first thing in a file
		return 'Regexp::Match' if $prec eq '';

		# What about the char after the slash? There's some things
		# that would be highly illogical to see if its an operator.
		my $next_char = substr $t->{line}, $t->{line_cursor} + 1, 1;
		if ( defined $next_char and length $next_char ) {
			if ( $next_char =~ /(?:\^|\[|\\)/ ) {
				return 'Regexp::Match';
			}
		}

		# Otherwise... erm... assume operator?
		# Add more tests here as potential cases come to light
		return 'Operator';

	} elsif ( $char == 120 ) { # $char eq 'x'
		# Handle an arcane special case where "string"x10 means the x is an operator.
		# String in this case means ::Single, ::Double or ::Execute, or the operator versions or same.
		my $nextchar = substr $t->{line}, $t->{line_cursor} + 1, 1;
		my $prev     = $t->_previous_significant_tokens(1);
		$prev = ref $prev->[0];
		if ( $nextchar =~ /\d/ and $prev ) {
			if ( $prev =~ /::Quote::(?:Operator)?(?:Single|Double|Execute)$/ ) {
				return 'Operator';
			}
		}

		# Otherwise, commit like a normal bareword
		return PPI::Token::Word->__TOKENIZER__commit($t);

	} elsif ( $char == 45 ) { # $char eq '-'
		# Look for an obvious operator operand context
		my $context = $t->_opcontext;
		if ( $context eq 'operator' ) {
			return 'Operator';
		} else {
			# More logic needed
			return 'Unknown';
		}

	} elsif ( $char >= 128 ) { # Outside ASCII
		return 'PPI::Token::Word'->__TOKENIZER__commit($t) if $t =~ /\w/;
		return 'Whitespace' if $t =~ /\s/;
        }


	# All the whitespaces are covered, so what to do
	### For now, die
	PPI::Exception->throw("Encountered unexpected character '$char'");
}

sub __TOKENIZER__on_line_end {
	$_[1]->_finalize_token if $_[1]->{token};
}

1;

#line 442
