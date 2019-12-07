use strict;
use warnings;
use utf8;

use Giblog;
use Mojolicious::Lite;

use Mojo::Message::Response;
use File::Temp 'tempfile';

# render CGI
app->hook(before_dispatch => sub {
  my $c = shift;
  
  my $req = $c->req;
  
  my $path = $req->url->path->clone;
  
  if ($path =~ /\.cgi$/) {
    
    # Prevent directory traversal
    $path->canonicalize;
    if ($path =~ /^[\\\/]\./) {
      die "Can't contain \. in path \"$path\"";
    }

    my $method = $c->req->method;
    my $script_name = $c->app->home->rel_file("public/$path");
    
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
    local $ENV{SCRIPT_NAME} = $script_name;
    local $ENV{SERVER_NAME} = 'localhost';
    local $ENV{SERVER_PORT} = $c->tx->remote_port;
    local $ENV{SERVER_SOFTWARE} = "Mojolicious (Perl)";
    local $ENV{SERVER_PROTOCOL} = 'HTTP/1.1';
    
    # Check script name
    unless ($script_name =~ /^[a-zA-Z_0-9\/\-\.]+$/) {
      die "Invalid script name";
    }
    
    # Check existance of CGI script
    unless (-f $script_name) {
      die "Not found CGI script";
    }
    
    # Run CGI script
    my $output;
    if ($method eq 'GET') {
      # GET requst
      $output = `$^X $script_name`;
      if ($?) {
        $c->res->code('505');
        $c->render(text => "Internal Server Error");
      }
    }
    elsif ($method eq 'POST') {
      # POST request
      my $body = $req->body;
      my ($in_fh, $in_file) = tempfile;
      print $in_fh $body;
      close $in_fh;
      $output = `$^X -pe "" $in_file | $^X $script_name`;
      if ($?) {
        $c->res->code('505');
        $c->render(text => "Internal Server Error");
      }
      unlink $in_file;
    }
    
    # Header part and body part
    my ($header_part, $body_part) = split("\n\n", $output, 2);
    
    # Response
    my $res = Mojo::Message::Response->new;
    while (!$res->is_finished) {
      $res->parse($header_part);
    }
    $c->res->code($res->code);
    $c->res->headers($res->headers);
    $c->render(data => $body_part);
  }
});



# Build
Giblog->build;

# Mojolicious::Lite Application
my $app = app;

# Serve
Giblog->serve($app);
