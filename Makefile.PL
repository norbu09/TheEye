use inc::Module::Install;
use Module::Install::Share;

name     'TheEye';
all_from 'lib/TheEye.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Mouse';
requires 'File::Util';
requires 'File::ShareDir';
requires 'TAP::Parser';
requires 'TAP::Parser::Aggregator';
requires 'Time::HiRes';
requires 'RRD::Simple';
requires 'LWP::UserAgent';
requires 'URI::Escape';
requires 'XML::Simple';
requires 'Mojolicious::Lite';
requires 'Collectd::Unixsock';

#install_share  'share/TheEye';

WriteAll;

