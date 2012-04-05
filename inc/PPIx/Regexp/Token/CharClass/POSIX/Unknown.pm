#line 1
package PPIx::Regexp::Token::CharClass::POSIX::Unknown;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::CharClass::POSIX };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.026';

sub perl_version_introduced {
#   my ( $self ) = @_;
    return MINIMUM_PERL;
}

# Note that these guys are recognized by PPIx::Regexp::CharClass::POSIX,
# and if one of them becomes supported that is where the change needs to
# be made.

# This is the handiest way to make this object represent a parse error.
sub __PPIX_LEXER__finalize {
    return 1;
}


1;

__END__

#line 87

# ex: set textwidth=72 :
