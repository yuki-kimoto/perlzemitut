use strict;
use warnings;

# リダイレクトのJavaScriptを追加する

my ($redirect_base_url, @blog_files) = @ARGV;

for my $blog_file (@blog_files) {
  my $blog_path = "templates/blog/$blog_file";
  
  open my $blog_fh, '<', $blog_path
    or die "Can't open $blog_path for read: $!";
  
  my $blog_content = do { local $/; <$blog_fh> };
  
  $blog_fh = undef;
  
  my $redirect_js = qq|<script>location.href='$redirect_base_url/blog/$blog_file';</script>|;
  
  $blog_content = "$redirect_js\n$blog_content";
  
  open my $blog_out_fh, '>', $blog_path
    or die "Can't open $blog_path for write: $!";
  
  print $blog_out_fh $blog_content;
}
