#!/usr/bin/env perl

use strict;
use warnings;

warn "Server start\n";

my $cmd = 'giblog build';
system($cmd) == 0
  or die "Can't execute $cmd: $!";

use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
