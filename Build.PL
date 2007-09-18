use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Atompub',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/Atompub.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,

	'Class::Accessor::Fast' => 0,
	'Class::Accessor::Lvalue::Fast' => 0,
	'DateTime' => 0,
        'Digest::SHA1' => 0,
        'File::Slurp' => 0,
	'HTTP::Date' => 0,
	'HTTP::Headers' => 0,
	'HTTP::Request' => 0,
	'HTTP::Response' => 0,
        'HTTP::Status' => 0,
        'MIME::Base64' => 0,
	'MIME::Types' => 0,
	'Perl6::Export::Attrs' => 0,
        'Test::Perl::Critic' => 0,
	'URI::Escape' => 0,
        'XML::Atom::Service' => '0.15.4',
    },
    add_to_cleanup      => [ 'Atompub-*' ],
);

$builder->create_build_script();
