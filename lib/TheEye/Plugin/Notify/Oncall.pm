package TheEye::Plugin::Notify::Oncall;

use Mouse::Role;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;

has 'oncall_token' => (
    is  => 'rw',
    isa => 'Str',
    lazy     => 1,
    required => 1,
    default => 123,
);

has 'oncall_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://localhost:3000/add/',
    lazy     => 1,
    required => 1,
);

has 'oncall_host' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { my $host = qx{hostname}; chomp($host); return $host },
    lazy     => 1,
    required => 1,
);

around 'notify' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @errors;
    foreach my $test (@{$tests}) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {
                my $message = 'Test: ' . $test->{file} . "\n";
                $message .= $step->{message} . "\n";
                $message .= $step->{comment} if $step->{comment};
                push(@errors, $message);
            }
        }
    }
    if($errors[0]){
        my $msg = join("\n\n--~==##\n\n", @errors);
        $self->oncall_send({message => $msg});
    }
};

sub oncall_send {
    my ($self, $message) = @_;

    $message->{host} = $self->oncall_host unless exists $message->{host};
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->post(
        $self->oncall_url . $self->oncall_token,
        Content_Type => 'form-data',
        Content      => { payload => to_json($message) });
    print Dumper($message)
        if $self->debug;
    return $res->is_success;
}

1;
