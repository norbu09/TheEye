#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite; # 'app', 'post', 'get', 'shagadelic' is exported
use Mojo::ByteStream 'b';
use File::Util;

my $img_dir = app->home->rel_dir('../../../images');

get '/' => sub {
    my $self = shift;
    
    my $f = File::Util->new();
    my @files = $f->list_dir( $img_dir, qw/ --files-only / );
    
    # Render index page
    $self->render(images => \@files);

} => 'index';

shagadelic;

__DATA__

@@ index.html.ep
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" >
    <title>TheEye</title>
  </head>
  <body>
    <h1>TheEye - RRDs overview</h1>
    <div>
<% foreach my $img (@$images) { %>
      <img src="<%= $img %>" />
<% } %>        
    </div>
  </body>
</html>


@@ error.html.ep
<html>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8" >
<title>Error</title>
</html>
<body>
  <%= $message %>
</body>
