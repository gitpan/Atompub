use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Atompub',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/Atompub.pm',
    requires => {
        'Test::More'         => 0,
        'version'            => 0,
        'URI::Escape'        => 0,
        'HTTP::Status'       => 0,
        'DateTime'           => 0,
        'Digest::SHA1'       => 0,
        'MIME::Base64'       => 0,
        'File::Slurp'        => 0,
        'XML::Atom'          => 0.25,
        'XML::Atom::Service' => '0.13.4',
    },
    add_to_cleanup      => [ 'Atompub-*' ],
);

$builder->create_build_script();
