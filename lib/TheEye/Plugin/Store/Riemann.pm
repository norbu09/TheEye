package TheEye::Plugin::Store::Riemann;

use Mouse::Role;
use Riemann::Client;

# ABSTRACT: Riemann plugin for TheEye
#
# VERSION

has 'riemann' => (
    is       => 'rw',
    isa      => 'Riemann::Client',
    required => 1,
    lazy     => 1,
    default  => sub { Riemann::Client->new( host => 'localhost', port => 5555)},
);


around 'save' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @events;
    foreach my $result (@{$tests}) {

        my @path = split(/\//, $result->{file});
        my @file = split(/\./, pop(@path));

        my $event = {
            state => 'ok',
            host   => $self->hostname,
            service => $file[0],
            time   => $result->{time},
            metric   => $result->{delta},
            description => $result->{passed} .' passed and '. $result->{failed} .' failed',
        };
        if($result->{failed}){
            $event->{state} = 'critical';
        }
        push(@events, $event);
    }
    $self->riemann->send(@events);
    return;
};


1;
