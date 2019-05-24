#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use CGI;
use JSON::PP 'encode_json';
use MIME::Lite;

use Encode 'decode', 'encode';

my $q = CGI->new;

# Mail to
my $mailto = 'kimoto.yuki+perlzemitutmail@gmail.com';

# Mail title
my $subject = 'Perlゼミにメールが届いています';

# Errors
my @errors;

# Name
my $name = $q->param('name');
$name = decode('UTF-8', $name);
unless (length $name) {
  push @errors, "名前を指定してください。";
}

# Email
my $email = $q->param('email');
$email = decode('UTF-8', $email);

unless (length $email && $email =~ /\@/) {
  push @errors, "Eメールアドレスを正しく入力してください。";
}

# Message
my $message = $q->param('message');
$message = decode('UTF-8', $message);
unless (length $message) {
  push @errors, "メッセージを指定してください。";
}

# Response
my $res = <<"EOS";
Content-type: application/json;

EOS

my $res_data = {};

unless (@errors) {
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
  unless ($msg->send) {
    push @errors, "メールの送信に失敗しました。";
  }
}

if (@errors) {
  $res_data->{success} = 0;
  $res_data->{errors} = \@errors;
}
else {
  $res_data->{success} = 1;
}

# JSON response
my $res_json = encode_json($res_data);
$res .= "$res_json\n";

# Print response
print $res;
