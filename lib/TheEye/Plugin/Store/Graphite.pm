package TheEye::Plugin::Store::Graphite;

use 5.010;
use Mouse::Role;
use Net::Graphite;
use Carp;

# ABSTRACT: Graphite plugin for TheEye
#
# VERSION

has 'graphite_host' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'localhost' },
);

has 'graphite_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 2003 },
);

has 'graphite_proto' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'tcp' },
);

around 'save' => sub {
    my $orig = shift;
    my ($self, $tests) = @_;

    my $graphite = Net::Graphite->new(
        host            => $self->graphite_host,
        port            => $self->graphite_port,
        proto           => $self->graphite_proto,
        fire_and_forget => 1,
    );

    foreach my $result (@{$tests}) {

        my @path = split(/\//, $result->{file});
        my ($file) = split(/\./, pop(@path));

        my $service = 'tests.' . $self->hostname . '.' . $file;
        eval {
            $graphite->send(
                path  => "$service.ok",
                value => $result->{passed});
        };
        carp "sending metric failed: $@" if $@;
        eval {
            $graphite->send(
                path  => "$service.nok",
                value => $result->{failed});
        };
        carp "sending metric failed: $@" if $@;
        eval {
            $graphite->send(
                path  => "$service.delta",
                value => $result->{delta});
        };
        carp "sending metric failed: $@" if $@;

    }
    return;
};

1;
