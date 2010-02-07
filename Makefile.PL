use inc::Module::Install;

name     'TheEye';
all_from 'lib/TheEye.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Moose';
requires 'File::Util';
requires 'File::ShareDir';
requires 'TAP::Parser';
requires 'TAP::Parser::Aggregator';
requires 'Time::HiRes';
requires 'RRD::Simple';

auto_install;

WriteAll;

