use Test::More tests => 4;
use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok('http://github.com');
$mech->base_is('http://github.com');
$mech->title_is("Secure source code hosting and collaborative development - GitHub");
$mech->content_contains("Search public git repositories");
