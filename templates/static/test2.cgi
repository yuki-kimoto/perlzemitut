#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use CGI;

use Encode 'decode', 'encode';

my $q = CGI->new;

my $x = $q->param('x');

# Response
my $res = <<"EOS";
Content-type: application/json;

$x
EOS
print encode('UTF-8', $res);
