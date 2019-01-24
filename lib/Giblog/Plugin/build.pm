package Giblog::Plugin::build;

use base 'Giblog::Plugin::base_build';

use strict;
use warnings;

use File::Basename 'basename';

sub plugin {
  my ($self, @args) = @_;
  
  # Write pre process
  $self->create_list;
  
  $self->SUPER::plugin(@args);
  
  # Write post porsess
}

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
    open my $template_fh, '<', $template_file
      or die "Can't open file $template_file: $!";
    
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
    
    my $content = do { local $/; <$template_fh> };
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
  open my $list_fh, '>', $list_file
    or die "Can't open file $list_file: $!";
  
  print $list_fh $html;
}

1;
