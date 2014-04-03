#!/usr/bin/perl

use 5.010;
use Test::More;
use lib 'lib';
use TheEye::Helper::RabbitMQ;
use Data::Printer;

my $upper = 2;

my $g = TheEye::Helper::RabbitMQ->new(
    url   => 'http://dreyfus.domarino.com:15672',
    realm => 'RabbitMQ Management',
    user  => 'hase',
    pass  => 'hase'
);

my $result = $g->get_numbers('z\.', 'nsearch2');  # ignore management queues and nsearch2
$g->test_rabbit($result, { upper => $upper, what => 'messages' });

done_testing();
