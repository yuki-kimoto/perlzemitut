#!/usr/bin/env perl

use strict;
use warnings;

warn "Server start\n";

my $cmd = 'giblog build';
system($cmd) == 0
  or die "Can't execute $cmd: $!";

use Mojolicious::Lite;

# render CGI
app->hook(before_dispatch => sub {
  my $c = shift;
  
  my $req = $c->req;
  
  my $path = $req->url->path;
  
  if ($path =~ /\.cgi$/) {
    my $method = $c->req->method;
    
    # CGI Environment variable
    local $ENV{AUTH_TYPE} = '';
    local $ENV{CONTENT_LENGTH} = $req->headers->content_length;
    local $ENV{CONTENT_TYPE} = $req->headers->content_type;
    local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    local $ENV{PATH_INFO} = $req->url->path;
    local $ENV{PATH_TRANSLATED} = $req->url->path;
    local $ENV{QUERY_STRING} = $req->url->query->to_string;
    local $ENV{REMOTE_ADDR} = $c->tx->remote_address;
    local $ENV{REMOTE_HOST} = $c->tx->remote_address;
    local $ENV{REMOTE_IDENT} = '';
    local $ENV{REMOTE_USER} = '';
    local $ENV{REQUEST_METHOD} = $method;
    local $ENV{SCRIPT_NAME} = $c->app->home->rel_file("public/$path");
    local $ENV{SERVER_NAME} = 'localhost';
    local $ENV{SERVER_PORT} = $c->tx->remote_port;
    local $ENV{SERVER_SOFTWARE} = "Mojolicious (Perl)";
    local $ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
    
    $c->render(text => 'aaaa');
  }
});

get '/' => sub {
  my $c = shift;
  
  $c->reply->static('index.html');
};

app->start;
