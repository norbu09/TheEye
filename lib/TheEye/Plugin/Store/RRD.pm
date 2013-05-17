package TheEye::Plugin::Store::RRD;

use 5.010;
use Mouse::Role;
use RRD::Simple;
use Data::Dumper;

# ABSTRACT: RRD plugin for TheEye
#
# VERSION

has 'rrd_dir' => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    lazy     => 1,
    default => '/tmp/rrds/'
);

has 'rrd_bin' => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    lazy     => 1,
    default => qx/which rrdtool/
);

has 'rrd_tmp' => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    lazy     => 1,
    default => '/tmp'
);


around 'save' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;
    foreach my $result (@{$tests}) {
        my @fparts = split( /\./, $result->{file} );
        $fparts[0] =~ s/\//-/g;
        print STDERR "saving ".$result->{file}."\n" if $self->debug;
        my $rrd = RRD::Simple->new(
            file           => $self->rrd_dir. $fparts[0] . '.rrd',
            rrdtool        => $self->rrd_bin,
            tmpdir         => $self->rrd_tmp,
            cf             => [qw(AVERAGE MAX)],
            default_dstype => "GAUGE",
            on_missing_ds  => "add",
        );
        $rrd->update(
            $result->{time},
            delta  => $result->{delta},
            passed => $result->{passed},
            failed => $result->{failed},
        );
    }
    return;
};


1;
