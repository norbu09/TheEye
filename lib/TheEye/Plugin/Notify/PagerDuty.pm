#!/usr/bin/perl -Ilib

package TheEye::Plugin::Notify::PagerDuty;

use Mouse::Role;
use LWP::UserAgent;
use URI::Escape;
use JSON;
use Data::Dumper;

has 'pd_token' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => '',
);

has 'pd_host' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => ''
);

has 'pd_url' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'https://events.pagerduty.com/generic/2010-04-15/create_event.json',
);

has 'pd_err' => (
    is        => 'rw',
    isa       => 'HashRef',
    required  => 0,
    default   => 0,
    predicate => 'has_pd_err',
);

around 'notify' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @errors;
    foreach my $test (@{$tests}) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {

                my $message = {
                    service_key => $self->pd_token,
                    incident_key => $test->{file},
                    event_type => 'trigger',
                    description => $step->{message},
                    details => {
                        test => $step->{comment},
                        host => $self->pd_host,
                        delta => $step->{delta},
                    },
                };
                my $res = $self->pd_send($message);
                print Dumper $res if $self->is_debug;
            }
        }
    }

sub pd_send {
    my ( $self, $content ) = @_;

    my $req = HTTP::Request->new();
    $req->method('POST');
    $req->uri($self->pd_url);
    $req->header('Content-Type' => 'application/json');

    $req->content( to_json($content) ) if ($content);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    print STDERR "Result: " . $res->decoded_content . "\n" if $self->is_debug;
    if ( $res->is_success ) {
        return from_json( $res->decoded_content );
    }
    else {
        if ( my $_err = from_json( $res->decoded_content ) ) {
            $self->pd_err($_err);
        }
        else {
            $self->pd_err( $res->status_line );
        }
    }
    return;
}

1;