#line 1
package PPIx::Regexp::Constant;

use strict;
use warnings;

our $VERSION = '0.026';

use base qw{ Exporter };

our @EXPORT_OK = qw{
    COOKIE_CLASS
    COOKIE_QUANT
    COOKIE_QUOTE
    MINIMUM_PERL
    MODIFIER_GROUP_MATCH_SEMANTICS
    RE_CAPTURE_NAME
    STRUCTURE_UNKNOWN
    TOKEN_LITERAL
    TOKEN_UNKNOWN
};

use constant COOKIE_CLASS	=> ']';
use constant COOKIE_QUANT	=> '}';
use constant COOKIE_QUOTE	=> '\\E';

use constant MINIMUM_PERL	=> '5.000';

use constant MODIFIER_GROUP_MATCH_SEMANTICS => 'match_semantics';

# The perlre for Perl 5.010 says:
#
#      Currently NAME is restricted to simple identifiers only.  In
#      other words, it must match "/^[_A-Za-z][_A-Za-z0-9]*\z/" or
#      its Unicode extension (see utf8), though it isn't extended by
#      the locale (see perllocale).

use constant RE_CAPTURE_NAME => ' [_[:alpha:]] \w* ';

use constant STRUCTURE_UNKNOWN	=> 'PPIx::Regexp::Structure::Unknown';

use constant TOKEN_LITERAL	=> 'PPIx::Regexp::Token::Literal';
use constant TOKEN_UNKNOWN	=> 'PPIx::Regexp::Token::Unknown';

1;

__END__

#line 157

# ex: set textwidth=72 :
