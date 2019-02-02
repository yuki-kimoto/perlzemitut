package Giblog::Command::build;

use base 'Giblog::Command::base_build';

use strict;
use warnings;
use utf8;

use File::Basename 'basename';

sub run {
  my ($self, @args) = @_;
  
  $self->SUPER::run(@args);

  # Write pre process
  $self->create_list;
  $self->create_latest;
  
  # Write post porsess
}

# Create latest entries page
sub create_latest {
  my $self = shift;
  
  my $giblog = $self->giblog;
  
  my @template_files = glob $giblog->rel_file('templates/blog/*');
  
  @template_files = reverse sort @template_files;
  
  my $latest_content;
  
  my $before_year = 0;
  for (my $i = 0; $i < 7; $i++) {
    my $template_file = $template_files[$i];
    
    my $base_name = basename $template_file;
    my ($year, $month, $mday) = $base_name =~ /^(\d{4})(\d{2})(\d{2})/;
    
    my $content = $giblog->slurp_file($template_file);
    my $data = {content => $content, path => "/blog/$base_name"};
    $self->parse_content($data);
    
    $content = $data->{content};

    $latest_content .= <<"EOS";
<div style="font-weight:bold;font-size:23px;letter-spacing:2px;margin:35px 0 0px 0;padding-left:5px;padding-top:5px;border-top:2px solid #ddd">${year}/${month}/${mday}</div>
$content
EOS
  }

  my $data = {content => $latest_content, path => '/latest.html'};
  $self->build_html($data);
  
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
  
  $list_content .= "<ul>\n";
  my $before_year = 0;
  for my $template_file (@template_files) {
    my $base_name = basename $template_file;
    my ($year, $month, $mday) = $base_name =~ /^(\d{4})(\d{2})(\d{2})/;
    $month =~ s/^0//;
    $mday =~ s/^0//;
    if ($year != $before_year) {
      $list_content .= <<"EOS";
  <li style="list-style:none;margin-left:-20px;">
    <b>${year}</b>
  </li>
EOS
    }
    $before_year = $year;
    
    my $path = "/blog/$base_name";
    
    my $content = $giblog->slurp_file($template_file);
    my $title;
    if ($content =~ /class="title">([^<]+)</) {
      $title = $1;
    }
    
    if ($title) {
      $list_content .= <<"EOS";
  <li style="list-style:none">
    $month/$mday <a href="$path">$title</a>
  </li>
EOS
    }
    else {
      warn "Warnings:Can't find title $template_file";
    }
  }

  $list_content .= "</ul>\n";
  
  my $data = {content => $list_content, path => '/list.html'};
  $self->parse_content($data);
  $self->build_html($data);
  
  my $html = $data->{content};
  
  my $list_file = $giblog->rel_file('public/list.html');
  $giblog->write_to_file($list_file, $html);
}

sub parse_content {
  my ($self, $data) = @_;
  
  # Write pre parse_content
  
  $self->SUPER::parse_content($data);
  
  # Write post parse_content
}

sub parse_common {
  my ($self, $data) = @_;
  
  # Write pre parse_common
  
  $self->SUPER::parse_common($data);

  my $giblog = $self->giblog;
  my $config = $giblog->config;
  
  # Twitter card
  {
    my $meta = $data->{meta};
    
    my $site_url = $config->{site_url};
    my $path = $data->{path};
    
    my $page_url = "$site_url/$path";
    
    my $title = $data->{title} || '';
    
    my $description = $data->{description} || '';
    
    my $image = $data->{image};
    if (defined $image) {
      unless ($image =~ /^http/) {
        $image = "$site_url/$image";
      }
    }
    else {
      $image = '';
    }
    
    my $twitter_card = <<"EOS";
<meta name="twitter:card" content="summary" />
<meta name="twitter:site" content="\@perlzemi" />
<meta property="og:url" content="$page_url" />
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="$image" />
EOS
    
    $meta .= "\n$twitter_card\n";
    
    $data->{meta} = $meta;
  }
  
  # Write post parse_common
}

sub build_html {
  my ($self, $data) = @_;
  
  # Write pre build_html
  
  $self->SUPER::build_html($data);
  
  # Write post build_html
}

1;
