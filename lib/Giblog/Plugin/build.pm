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
  
  my $html;
  
  $html .= <<"EOS";
<div class="title" style="font-weight:bold;font-size:26px;letter-spacing:2px">最新記事</div>
EOS

  my $before_year = 0;
  for (my $i = 0; $i < 7; $i++) {
    my $template_file = $template_files[$i];
    
    my $base_name = basename $template_file;
    my ($year, $month, $mday) = $base_name =~ /^(\d{4})(\d{2})(\d{2})/;
    
    my $content = $giblog->slurp_file($template_file);
    $content =~ s/class="title"//g;

    $html .= <<"EOS";
<div style="font-weight:bold;font-size:23px;letter-spacing:2px;margin:35px 0 0px 0;padding-left:5px;padding-top:5px;border-top:2px solid #ddd">${year}年${month}月${mday}日</div>
$content
EOS
  }
  
  my $latest_file = $giblog->rel_file('templates/latest.html');
  $giblog->write_to_file($latest_file, $html);
}

# Create all entry list page
sub create_list {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  my @template_files = glob $giblog->rel_file('templates/blog/*');
  
  @template_files = reverse sort @template_files;
  
  my $html;
  
  $html = <<"EOS";
<h2 class="title">記事一覧</h2>
EOS

  $html .= "<ul>\n";
  my $before_year = 0;
  for my $template_file (@template_files) {
    my $base_name = basename $template_file;
    my ($year) = $base_name =~ /^(\d{4})/;
    if ($year != $before_year) {
      $html .= <<"EOS";
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
      $html .= <<"EOS";
  <li>
    <a href="$url">$title</a>
  </li>
EOS
    }
    else {
      warn "Warnings:Can't find title $template_file";
    }
  }

  $html .= "</ul>\n";
  
  my $list_file = $giblog->rel_file('templates/list.html');
  $giblog->write_to_file($list_file, $html);
}

1;
