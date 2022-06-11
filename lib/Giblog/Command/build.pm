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
  
  # Read config
  my $config = $api->read_config;
  
  # Copy static files to public
  $api->copy_static_files_to_public;

  # Get files in templates directory
  my $files = $api->get_templates_files;
  
  for my $file (@$files) {
    
    # Data
    my $data = {file => $file};
    
    # Get content from file in templates directory
    $api->get_content($data);

    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Parse title
    $api->parse_title_from_first_h_tag($data);
    
    # Edit site title
    my $site_title = $config->{site_title};
    if ($data->{file} eq 'index.html') {
      $data->{title} = "$site_title";
    }
    else {
      $data->{title} = "$data->{title} - $site_title";
    }
    
    # Add page link
    $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});

    # Parse description
    $api->parse_description($data);

    # Create description from first p tag
    $api->parse_description_from_first_p_tag($data);
    
    # 最初の段落下に広告を追加
    {
      my $ad = <<'EOS';
<div style="width:calc(100% - 30px);margin:10px auto;">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4525414114581084"
       crossorigin="anonymous"></script>
  <!-- 最初の段落下 - ディスプレイ 横長 レスポンシブ -->
  <ins class="adsbygoogle"
       style="display:block"
       data-ad-client="ca-pub-4525414114581084"
       data-ad-slot="2828858335"
       data-ad-format="auto"
       data-full-width-responsive="true"></ins>
  <script>
       (adsbygoogle = window.adsbygoogle || []).push({});
  </script>
</div>
EOS
      $data->{content} =~ s|</p>|</p>\n$ad\n|;
    }

    # Read common templates
    $api->read_common_templates($data);
    
    # Add meta title
    $api->add_meta_title($data);
    
    # Add meta description
    $api->add_meta_description($data);
    
    # Twitter card
    {
      my $meta = $data->{meta};
      
      my $site_url = $config->{site_url};
      my $title = $data->{title} || '';
      my $description = $data->{description} || '';
      
      my $twitter_card = <<"EOS";
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:site" content="\@perlzemi" />
<meta name="twitter:title" content="$title" />
<meta name="twitter:description" content="$description" />
<meta name="twitter:image" content="$site_url/images/twitter_card_large_kaeru.png" />
EOS
      
      $meta .= "\n$twitter_card\n";
      
      $data->{meta} = $meta;
    }

    # Build entry html
    $api->build_entry($data);
    
    # Build whole html
    $api->build_html($data);
    
    # Write to public file
    $api->write_to_public_file($data);
  };

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
    my $data = {content => $content, file => "blog/$base_name"};
    
    # Parse Giblog syntax
    $api->parse_giblog_syntax($data);

    # Add page link
    $api->add_page_link_to_first_h_tag($data, {root => 'index.html'});
    
    $content = $data->{content};

    $latest_content .= <<"EOS";
<div style="font-weight:bold;font-size:18px;letter-spacing:2px;margin:35px 0 0px 0;padding-left:5px;padding-top:5px;border-top:2px solid #ddd">${year}/${month}/${mday}</div>
$content
EOS
  }

  my $data = {content => $latest_content, file => 'latest.html'};
  
  $data->{title} = '最新記事';
  $data->{description} = 'Perlゼミの最新記事です。';

  # Read common templates
  $api->read_common_templates($data);

  # Build entry html
  $api->build_entry($data);
  
  # Build whole html
  $api->build_html($data);
  
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

  $list_content .= qq(<h2><a href="/list.html">Perlゼミ新着情報</a></h2>\n);
  
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
    
    my $file = "blog/$base_name";
    
    my $data = {file => $file};
    
    $api->get_content($data);
    
    $api->parse_title_from_first_h_tag($data);
    
    my $title = $data->{title};
    
    my $path;
    if ($file eq 'index.html') {
      $path = '/';
    }
    else {
      $path = "/$file";
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
  
  my $data = {content => $list_content, file => 'list.html'};

  # Read common templates
  $api->read_common_templates($data);
  
  my $config = $api->config;
  my $site_title = $config->{site_title};
  $data->{meta} .= "<title>新着情報 - $site_title</title>\n";

  # Build entry html
  $api->build_entry($data);
  
  # Build whole html
  $api->build_html($data);
  
  my $html = $data->{content};
  
  my $list_file = $api->rel_file('public/list.html');
  $api->write_to_file($list_file, $html);
}

1;
