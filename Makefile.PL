use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'SFC-Room';
author   q{cory <cory@sfc.keio.ac.jp>};
all_from 'lib/SFC/Room.pm';
license  'mit';

build_requires 'Test::More' => 0,
configure_requires 'File::ShareDir' => 0;
requires(
    'Encode'          => 0,
    'JSON'            => 0,
    'File::ShareDir'  => 0,
    'Class::Accessor' => 0,
    );


tests 't/*.t';
install_share;
auto_include;

WriteAll;
