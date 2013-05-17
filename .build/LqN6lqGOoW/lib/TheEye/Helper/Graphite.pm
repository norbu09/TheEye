package TheEye::Helper::Graphite;

use 5.010;
use Mouse;
use LWP::UserAgent;

# ABSTRACT: Graphite plugin for TheEye
#
our $VERSION = '0.8'; # VERSION

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'postfix' => (
    is      => 'rw',
    isa     => 'Str',
    default => '&rawData=true&from=-15min',
);


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


sub byte_to_gb {
    my ($self, $bytes) = @_;

    return $bytes / 1024 / 1024 / 1024;
}


sub byte_to_mb {
    my ($self, $bytes) = @_;

    return $bytes / 1024 / 1024;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TheEye::Helper::Graphite - Graphite plugin for TheEye

=head1 VERSION

version 0.8

=head2 map_services

Map services to easier names

=head2 get_numbers

Get the numbers from the Graphite server

=head2 byte_to_gb

Convert bytes into GB

=head2 byte_to_mb

Convert bytes into MB

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
