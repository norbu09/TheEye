package TheEye::Helper::Graphite;

use 5.010;
use Mouse;
use LWP::UserAgent;

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'postfix' => (
    is      => 'rw',
    isa     => 'Str',
    default => '&rawData=true&from=-15min',
);

=head2 map_services

Map services to easier names

=cut

sub map_services {
    my ($self, $name) = @_;

    my $hash = {
        df_root => {
            path    => '.df-root.df_complex-free.value',
            convert => 'byte_to_gb'
        },
        mem => {
            path    => '.memory.memory-free.value',
            convert => 'byte_to_mb',
        },
    };

    return $hash->{$name};
}

=head2 get_numbers

Get the numbers from the Graphite server

=cut

sub get_numbers {
    my ($self, $host, $service) = @_;

    my $ua  = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $svc = $self->map_services($service);
    my $res = $ua->get($self->url . $host . $svc->{path} . $self->postfix);
    if ($res->is_success) {
        my $result;
        foreach (split(/\n/, $res->content)) {
            my ($def, $vals) = split(/\|/, $_);
            my @values = split(/,/, $vals);
            my ($node, $from, $to, $resolution) = split(/,/, $def);
            my $val = pop(@values);
            $val = pop(@values)
                if $val =~ m{none}i;    # make syre we got something
            if (exists $svc->{convert}) {
                my $conv = $svc->{convert};
                $val = $self->$conv($val);
            }
            push(
                @{$result}, {
                    node       => $node,
                    from       => $from,
                    to         => $to,
                    resolution => $resolution,
                    value      => $val,
                });
        }
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

__PACKAGE__->meta->make_immutable;
