#line 1
package PPI::Token;

#line 21

use strict;
use Params::Util   qw{_INSTANCE};
use PPI::Element   ();
use PPI::Exception ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.215';
	@ISA     = 'PPI::Element';
}

# We don't load the abstracts, they are loaded
# as part of the inheritance process.

# Load the token classes
use PPI::Token::BOM                   ();
use PPI::Token::Whitespace            ();
use PPI::Token::Comment               ();
use PPI::Token::Pod                   ();
use PPI::Token::Number                ();
use PPI::Token::Number::Binary        ();
use PPI::Token::Number::Octal         ();
use PPI::Token::Number::Hex           ();
use PPI::Token::Number::Float         ();
use PPI::Token::Number::Exp           ();
use PPI::Token::Number::Version       ();
use PPI::Token::Word                  ();
use PPI::Token::DashedWord            ();
use PPI::Token::Symbol                ();
use PPI::Token::ArrayIndex            ();
use PPI::Token::Magic                 ();
use PPI::Token::Quote::Single         ();
use PPI::Token::Quote::Double         ();
use PPI::Token::Quote::Literal        ();
use PPI::Token::Quote::Interpolate    ();
use PPI::Token::QuoteLike::Backtick   ();
use PPI::Token::QuoteLike::Command    ();
use PPI::Token::QuoteLike::Regexp     ();
use PPI::Token::QuoteLike::Words      ();
use PPI::Token::QuoteLike::Readline   ();
use PPI::Token::Regexp::Match         ();
use PPI::Token::Regexp::Substitute    ();
use PPI::Token::Regexp::Transliterate ();
use PPI::Token::Operator              ();
use PPI::Token::Cast                  ();
use PPI::Token::Structure             ();
use PPI::Token::Label                 ();
use PPI::Token::HereDoc               ();
use PPI::Token::Separator             ();
use PPI::Token::Data                  ();
use PPI::Token::End                   ();
use PPI::Token::Prototype             ();
use PPI::Token::Attribute             ();
use PPI::Token::Unknown               ();





#####################################################################
# Constructor and Related

sub new {
	bless { content => (defined $_[1] ? "$_[1]" : '') }, $_[0];
}

sub set_class {
	my $self  = shift;
	# @_ or throw Exception("No arguments to set_class");
	my $class = substr( $_[0], 0, 12 ) eq 'PPI::Token::' ? shift : 'PPI::Token::' . shift;

	# Find out if the current and new classes are complex
	my $old_quote = (ref($self) =~ /\b(?:Quote|Regex)\b/o) ? 1 : 0;
	my $new_quote = ($class =~ /\b(?:Quote|Regex)\b/o)     ? 1 : 0;

	# No matter what happens, we will have to rebless
	bless $self, $class;

	# If we are changing to or from a Quote style token, we
	# can't just rebless and need to do some extra thing
	# Otherwise, we have done enough
	return $class if ($old_quote - $new_quote) == 0;

	# Make a new token from the old content, and overwrite the current
	# token's attributes with the new token's attributes.
	my $token = $class->new( $self->{content} );
	%$self = %$token;

	# Return the class as a convenience
	return $class;
}





#####################################################################
# PPI::Token Methods

#line 131

sub set_content {
	$_[0]->{content} = $_[1];
}

#line 146

sub add_content { $_[0]->{content} .= $_[1] }

#line 156

sub length { CORE::length($_[0]->{content}) }





#####################################################################
# Overloaded PPI::Element methods

sub content {
	$_[0]->{content};
}

# You can insert either a statement, or a non-significant token.
sub insert_before {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element')  or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_before($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_before($Element);
	}
	'';
}

# As above, you can insert a statement, or a non-significant token
sub insert_after {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_after($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_after($Element);
	}
	'';
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_line_start { 1 }
sub __TOKENIZER__on_line_end   { 1 }
sub __TOKENIZER__on_char       { 'Unknown' }





#####################################################################
# Lexer Methods

sub __LEXER__opens {
	ref($_[0]) eq 'PPI::Token::Structure'
	and
	$_[0]->{content} =~ /(?:\(|\[|\{)/
}

sub __LEXER__closes {
	ref($_[0]) eq 'PPI::Token::Structure'
	and
	$_[0]->{content} =~ /(?:\)|\]|\})/
}

1;

#line 247
