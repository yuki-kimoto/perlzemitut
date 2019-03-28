#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use Encode 'decode', 'encode';
use MIME::Base64;

my $mailto = 'kimoto_yuki@shinshina.co.jp';
my $subject = 'Mail from giblog-mail';
my $mail_cmd = '/usr/sbin/sendmail';

# Check enviroment - giblog-mail.cgi?test
if ($ENV{REQUEST_METHOD} eq "GET") {
  if ($ENV{QUERY_STRING} =~ /test/) {
    my $message = <<"EOS";
Content-type: text/html; charset=UTF-8

<!-- GIBLOG_CONTENT_START -->
<p>CGI OK</p>
EOS

		unless (-f $mail_cmd) {
			$message .= "<p>$mail_cmd not found</p>";
		}
		unless (-x $mail_cmd) {
			$message .= "<p>$mail_cmd not excutable</p>";
		}
    $message .= <<"EOS";
<!-- GIBLOG_CONTENT_END -->
EOS
	  print encode('UTF-8', $message);
		exit 0;
  }
  # Top page - giblog-mail.cgi
  else {
    my $html = <<"EOS";
Content-type: text/html; charset=UTF-8

<!-- GIBLOG_CONTENT_START -->
<h2>Message Form</h2>
<hr>
<form method="POST" action="">
Name:<br>
<input type="text" size=50 name="name"><br>
<br>
Mail:<br>
<input type="text" size=50 name="email"><br>
<br>
Message:<br>
<textarea cols=50 rows=3 name="message"></textarea><br>
<br>
<input type="submit" value=" Send ">
<input type="reset" value=" Clear ">
</form>
<!-- GIBLOG_CONTENT_END -->
EOS
	  print encode('UTF-8', $html);
		exit 0;
  }
}

# Form data
my %form;
my @form_name_index;
my $cnt = 0;
if ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN, my $query_string, $ENV{'CONTENT_LENGTH'});
	my @pairs = split(/&/, $query_string);
	for my $x (@pairs) {
		my ($name, $value) = split(/=/, $x);
		$name =~ tr/+/ /;
		$name =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("C", hex($1))/eg;
		$value =~ tr/+/ /;
		$value =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("C", hex($1))/eg;
		$value =~ s/\r\n/\n/g;
		
		$name = decode('UTF-8', $name);
		$value = decode('UTF-8', $value);
		
		if (defined $form{$name}) {
			$form{$name} .= " " . $value;
		}
		else {
			$form{$name} = $value;
			$form_name_index[$cnt++] = $name;
		}
	}
}

# Mail header
my $mailfrom;
if ($form{'email'} =~ /^[-_\.a-zA-Z0-9]+\@[-_\.a-zA-Z0-9]+$/) {
	$mailfrom = $form{'email'};
}
my $mail_head = "";
$mail_head .= "Content-Type: text/plain; charset=\"UTF-8\"\n";
$mail_head .= "Content-Transfer-Encoding: base64\n";
$mail_head .= "MIME-Version: 1.0\n";
$mail_head .= "To: $mailto\n";
if ($mailfrom) {
	$mail_head .= "From: $form{'email'}\n";
	$mail_head .= "Cc: $form{'email'}\n";
} else {
	$mail_head .= "From: $mailto\n";
}
$mail_head .= "Subject: " . encode('MIME-Header', $subject) . "\n";
$mail_head .= "\n";

# Mail body
my $mail_body;
for (my $i = 0; $i < $cnt; $i++) {
	$mail_body .= "$form_name_index[$i] = $form{$form_name_index[$i]}\n";
}

# "." のみの行は ". " に変換する。
# 2回繰り返さないと、2行連続で "." のみの行に対応できない
# "." を ".." に変換する処理が一般的だそうだが、あえて、
# "." を ". " に変換する。
$mail_body =~ s/(^|\n)\.(\n|$)/$1. $2/g;
$mail_body =~ s/(^|\n)\.(\n|$)/$1. $2/g;

# Send mail
my $cmd;
if ($mail_cmd =~ /sendmail/) {
	$cmd = "$mail_cmd -f $mailto -t";
	my $out;
	unless (open($out, "| $cmd")) {
		&errexit("Mail sending fail(1)");
	}
	unless (print $out $mail_head) {
		&errexit("Mail sending fail(2)");
	}
	unless (print $out encode_base64(encode('UTF-8', $mail_body))) {
		&errexit("Mail sending fail(3)");
	}
}
else {
	&errexit("$mail_cmd not found");
}

# Render result
my $mail;
$mail = $mail_body;
$mail = html_escape($mail);
$mail =~ s/\n/<BR>/g;
my $html = <<"EOS";
Content-type: text/html; charset=UTF-8

<!-- GIBLOG_CONTENT_START -->
<h2>Mail sending result</h2>
<hr>
<p>The following mail is send. Thank you.</p>
$mail
<hr>
<a href="../index.html">[Back]</a>
<!-- GIBLOG_CONTENT_END -->
EOS
print encode('UTF-8', $html);

#
# Subroutiens
#

# Show error message and exit
sub errexit {
	my ($err) = @_;
  
  my $msg = <<"EOS";
Content-type: text/html; charset=UTF-8

<!-- GIBLOG_CONTENT_START -->
<h2>Mail sending result</h2>
<hr>
<p>$err</p>
<p>Return back by browser back</p>
<!-- GIBLOG_CONTENT_END -->
EOS

	print encode('UTF-8', $msg);

	exit(0);
}

# HTML escape
sub html_escape {
  my $value = shift;
	$value =~ s/&/&amp;/g;
	$value =~ s/"/&quot;/g;
	$value =~ s/</&lt;/g;
	$value =~ s/>/&gt;/g;
  
  return $value;
}
