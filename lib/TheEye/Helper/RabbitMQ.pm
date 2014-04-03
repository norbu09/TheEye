package TheEye::Helper::RabbitMQ;

use 5.010;
use Mouse;
use LWP::UserAgent;
use HTTP::Request;
use Test::More;
use JSON;

# ABSTRACT: Graphite plugin for TheEye
#
# VERSION

has 'json' => (
    is      => 'rw',
    isa     => 'JSON',
    default => sub {
        JSON->new->utf8->allow_nonref->allow_blessed->convert_blessed;
    },
);

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'realm' => (
    is  => 'rw',
    isa => 'Str',
);

has 'user' => (
    is  => 'rw',
    isa => 'Str',
);

has 'pass' => (
    is  => 'rw',
    isa => 'Str',
);

=head2 get_numbers

Get the numbers from the Graphite server

=cut

sub get_numbers {
    my ($self, $service) = @_;

    my $ua   = LWP::UserAgent->new();

    my $req = HTTP::Request->new(GET => $self->url . '/api/queues');
    $req->authorization_basic($self->user, $self->pass);

    my $res = $ua->request($req);
    if ($res->is_success) {

        my $json;
        my $result;
        eval { $json = $self->json->decode($res->content) };
        unless ($@) {
            foreach my $queue (@{$json}){
                #$result->{$queue->{vhost} . '/' . $queue->{name}} = $queue;
                push(
                    @{$result}, {
                        node       => $queue->{vhost} . '/' . $queue->{name},
                        from       => time,
                        to         => time,
                        resolution => 1,
                        value      => $queue->{messages},
                    });
            }
        }
        return {error => 'Could not parse JSON'} unless $result;
        return $result;
    }
    else {
        return { error => $res->status_line, };
    }
}

=head2 byte_to_gb

Convert bytes into GB

=cut

sub byte_to_gb {
    my ($self, $bytes) = @_;

    return $bytes / 1024 / 1024 / 1024;
}

=head2 byte_to_mb

Convert bytes into MB

=cut

sub byte_to_mb {
    my ($self, $bytes) = @_;

    return $bytes / 1024 / 1024;
}

=head2 test_graphite

Test a grahite data source for stale data and min/max

=cut

sub test_rabbit {
    my ($self, $data, $limits) = @_;

    if (ref $data eq 'HASH') {
        fail("Communication error: " . $data->{error});
    }
    else {
        foreach my $res (@{$data}) {
            if (exists $limits->{lower}) {
                cmp_ok($res->{value}, '>=', $limits->{lower},
                    "$res->{node} has less than $limits->{lower} $limits->{what} - currently: $res->{value}"
                );
            }
            if (exists $limits->{upper}) {
                cmp_ok($res->{value}, '<=', $limits->{upper},
                    "$res->{node} has more than $limits->{upper} $limits->{what} - currently: $res->{value}"
                );
            }
            if (exists $limits->{stale}) {
                cmp_ok($res->{to}, '>=', time - $limits->{stale},
                    "$res->{node} has stale data (currently $res->{to} seconds old)"
                );
            }
        }
    }

}

__PACKAGE__->meta->make_immutable;
