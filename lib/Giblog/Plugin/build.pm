package Giblog::Plugin::build;

use base 'Giblog::Plugin::base_build';

use strict;
use warnings;
use utf8;

use File::Basename 'basename';

sub plugin {
  my ($self, @args) = @_;
  
  # Write pre process
  $self->create_list;
  $self->create_latest;
  
  $self->SUPER::plugin(@args);
  
  # Write post porsess
}

# Create latest entries page
sub create_latest {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  my @template_files = glob $giblog->rel_file('templates/blog/*');
  
  @template_files = reverse sort @template_files;
  
  my $latest_content;
  
  $latest_content .= <<"EOS";
<div class="title" style="font-weight:bold;font-size:26px;letter-spacing:2px"><a style="color:#333;text-decoration:none;" href="/latest.html">最新記事</a></div>
EOS

  my $before_year = 0;
  for (my $i = 0; $i < 7; $i++) {
    my $template_file = $template_files[$i];
    
    my $base_name = basename $template_file;
    my ($year, $month, $mday) = $base_name =~ /^(\d{4})(\d{2})(\d{2})/;
    
    my $content = $giblog->slurp_file($template_file);
    my $data = {content => $content, url => "/blog/$base_name"};
    $data = $self->parse_template($data);
    
    $content = $data->{content};

    $latest_content .= <<"EOS";
<div style="font-weight:bold;font-size:23px;letter-spacing:2px;margin:35px 0 0px 0;padding-left:5px;padding-top:5px;border-top:2px solid #ddd">${year}年${month}月${mday}日</div>
$content
EOS
  }

  my $data = {content => $latest_content, url => '/latest.html'};
  $data = $self->build_html($data);
  
  my $html = $data->{content};

  my $latest_file = $giblog->rel_file('public/latest.html');
  $giblog->write_to_file($latest_file, $html);
}

# Create all entry list page
sub create_list {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  my @template_files = glob $giblog->rel_file('templates/blog/*');
  
  @template_files = reverse sort @template_files;
  
  my $list_content;
  
  $list_content = <<"EOS";
<h2 class="title">記事一覧</h2>
EOS

  $list_content .= "<ul>\n";
  my $before_year = 0;
  for my $template_file (@template_files) {
    my $base_name = basename $template_file;
    my ($year) = $base_name =~ /^(\d{4})/;
    if ($year != $before_year) {
      $list_content .= <<"EOS";
  <li style="list-style:none;margin-left:-20px;">
    <b>${year}年</b>
  </li>
EOS
    }
    $before_year = $year;
    
    my $url = "/blog/$base_name";
    
    my $content = $giblog->slurp_file($template_file);
    my $title;
    if ($content =~ /class="title">([^<]+)</) {
      $title = $1;
    }
    
    if ($title) {
      $list_content .= <<"EOS";
  <li>
    <a href="$url">$title</a>
  </li>
EOS
    }
    else {
      warn "Warnings:Can't find title $template_file";
    }
  }

  $list_content .= "</ul>\n";
  
  my $data = {content => $list_content, url => '/list.html'};
  $data = $self->parse_template($data);
  $data = $self->build_html($data);
  
  my $html = $data->{content};
  
  my $list_file = $giblog->rel_file('public/list.html');
  $giblog->write_to_file($list_file, $html);
}

1;
