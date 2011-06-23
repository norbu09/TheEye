use Test::More tests => 4;
use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok('https://github.com/');
$mech->base_is('https://github.com/');
$mech->title_is("Secure source code hosting and collaborative development - GitHub");
$mech->content_contains("git repositories");
