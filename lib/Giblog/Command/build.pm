package Giblog::Command::build;

use base 'Giblog::Command';

use strict;
use warnings;
use utf8;
use Giblog::API;

use File::Basename 'basename';

sub run {
  my ($self, @args) = @_;
  
  my $api = $self->api;
  
  $api->read_config;
  
  $api->build_all(sub {
    my ($api, $data) = @_;
    
    # Config
    my $config = $api->config;

    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Parse title
    $api->parse_title($data);

    # Add page link
    $api->add_page_link($data);

    # Parse description
    $api->parse_description($data);

    # Create description from first p tag
    $api->parse_description_from_first_p_tag($data);

    # Parse keywords
    $api->parse_keywords($data);

    # Parse first image src
    $api->parse_first_img_src($data);

    # Prepare wrap content
    $api->prepare_wrap_content($data);
    
    # Add meta title
    $api->add_meta_title($data);

    # Add meta description
    $api->add_meta_description($data);

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
    
    # Wrap content by header, footer, etc
    $api->wrap_content($data);
  });

  # Write pre process
  $self->create_list;
  $self->create_latest;
}

# Create latest entries page
sub create_latest {
  my $self = shift;
  
  my $api = $self->api;

  my @template_files = glob $api->rel_file('templates/blog/*');
  
  @template_files = reverse sort @template_files;
  
  my $latest_content;
  
  my $before_year = 0;
  for (my $i = 0; $i < 7; $i++) {
    my $template_file = $template_files[$i];
    
    my $base_name = basename $template_file;
    my ($year, $month, $mday) = $base_name =~ /^(\d{4})(\d{2})(\d{2})/;
    
    my $content = $api->slurp_file($template_file);
    my $data = {content => $content, path => "/blog/$base_name"};
    
    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Add page link
    $api->add_page_link($data);
    
    $content = $data->{content};

    $latest_content .= <<"EOS";
<div style="font-weight:bold;font-size:18px;letter-spacing:2px;margin:35px 0 0px 0;padding-left:5px;padding-top:5px;border-top:2px solid #ddd">${year}/${month}/${mday}</div>
$content
EOS
  }

  my $data = {content => $latest_content, path => '/latest.html'};
  
  $data->{title} = '最新記事';
  $data->{description} = 'Perlゼミの最新記事です。';

  # Prepare wrap content
  $api->prepare_wrap_content($data);

  $api->wrap_content($data);
  
  my $html = $data->{content};

  my $latest_file = $api->rel_file('public/latest.html');
  $api->write_to_file($latest_file, $html);
}

# Create all entry list page
sub create_list {
  my $self = shift;
  
  my $api = $self->api;

  my @template_files = glob $api->rel_file('templates/blog/*');
  
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
    
    my $content = $api->slurp_file($template_file);
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

  # Prepare wrap content
  $api->prepare_wrap_content($data);

  $api->wrap_content($data);
  
  my $html = $data->{content};
  
  my $list_file = $api->rel_file('public/list.html');
  $api->write_to_file($list_file, $html);
}

1;
