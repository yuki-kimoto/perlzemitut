#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use MIME::Base64;
use CGI;
use MIME::Lite;

use Encode 'decode', 'encode';

my $q = CGI->new;

# Mail to
my $mailto = 'kimoto_yuki@shinshina.co.jp';

# Mail title
my $subject = 'Mail From giblog-mail';

# Mail command
my $mail_cmd = '/usr/sbin/sendmail';

# Name
my $name = $q->param('name');
$name = decode('UTF-8', $name);

# Email
my $email = $q->param('email');
$email = decode('UTF-8', $email);

# Message
my $message = $q->param('message');
$message = decode('UTF-8', $message);

# Mail body
my $mail_body = <<"EOS";
Name: $name
Email: $email
Message: $message
EOS

# Send mail
my $msg = MIME::Lite->new(
  From    => $mailto,
  To      => $mailto,
  Subject => encode('MIME-Header', $subject),
  Type    => 'multipart/mixed'
);
$msg->attach(
  Type     => 'TEXT',
  Data     => encode('UTF-8', $mail_body),
);
$msg->send;

# Response
my $res = <<"EOS";
Content-type: application/json;

1
EOS
print encode('UTF-8', $res);
