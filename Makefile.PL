use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Atompub',
    AUTHOR              => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    VERSION_FROM        => 'lib/Atompub.pm',
    ABSTRACT_FROM       => 'lib/Atompub.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Atompub-*' },
);
