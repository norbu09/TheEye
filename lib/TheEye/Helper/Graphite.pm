package TheEye::Helper::Graphite;

use 5.010;
use Mouse;
use LWP::UserAgent;
use HTTP::Request;
use Test::More;

# ABSTRACT: Graphite plugin for TheEye
#
# VERSION

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'postfix' => (
    is      => 'rw',
    isa     => 'Str',
    default => '&rawData=true&from=-15min',
);

has 'user' => (
    is  => 'rw',
    isa => 'Str',
);

has 'pass' => (
    is  => 'rw',
    isa => 'Str',
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
        load => {
            path => '.load.load.shortterm',
        },
        rabbit_msg => {
            path => '.messages',
            drill_down => 3,
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
    my $url = $self->url . $host . $svc->{path} . $self->postfix;
    my $req = HTTP::Request->new(GET => $url );
    if($self->user){
        $req->authorization_basic($self->user, $self->pass);
    }

    my $res = $ua->request($req);
    if ($res->is_success) {
        my $res_txt = $res->content;
        if(exists $svc->{drill_down}){
            foreach my $i (1 .. $svc->{drill_down}){
                $host .= '.*';
                my $res2 = $ua->get($self->url . $host . $svc->{path} . $self->postfix);
                $res_txt .= $res2->content;
            }
        }
        my $result;
        foreach (split(/\n/, $res_txt)) {
            my ($def, $vals) = split(/\|/, $_);
            my @values = split(/,/, $vals);
            my ($node, $from, $to, $resolution) = split(/,/, $def);
            my $val = pop(@values);
            $val = pop(@values)
                if $val =~ m{none}i;    # make sure we got something
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

=head2 test_graphite

Test a grahite data source for stale data and min/max

=cut

sub test_graphite {
    my($self, $data, $limits) = @_;

    if (ref $data eq 'HASH') {
        fail("Communication error: " . $data->{error});
    }
    else {
        foreach my $res (@{$data}) {
            if(exists $limits->{lower}){
                cmp_ok($res->{value}, '>=', $limits->{lower},
                    "$res->{node} has less than $limits->{lower} $limits->{what} - currently: $res->{value}");
            }
            if(exists $limits->{upper}){
                cmp_ok($res->{value}, '<=', $limits->{upper},
                    "$res->{node} has more than $limits->{upper} $limits->{what} - currently: $res->{value}");
            }
            if(exists $limits->{stale}){
                cmp_ok($res->{to}, '>=', time - $limits->{stale},
                    "$res->{node} has stale data (currently $res->{to} seconds old)"
                );
            }
        }
    }

}

__PACKAGE__->meta->make_immutable;
