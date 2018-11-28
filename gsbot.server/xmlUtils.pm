package xmlUtils;

use LWP::Simple qw(getstore);
use strict;
use XML::XPath;
use Encode;
use Text::Iconv;

my $ROOT_PATH = "/home/ubuntu/gsbot/gsbot.server";


sub new {
  my $pkg = shift;
  return bless {}, $pkg;
}


sub xml_download {
  my ( $rss_feed, $rss_file ) = @_;
  my $query_status = 0;
  $query_status = getstore( $rss_feed, $rss_file );
  print "rss_feed = " . $rss_feed . " rss_file = " . $rss_file . " query_status = " . $query_status . "\n";
  return $query_status;
}


sub get_rss_feed {
  my ( $self ) = @_;

  open( f_rss_feeds, "$ROOT_PATH/conf/rss_feeds.txt" ) or die("RSS feeds file does not exist");
    my @rss_feeds = (<f_rss_feeds>);
    my $rss_feeds_count = scalar(@rss_feeds);
    my $rss_feeds_rand = int( rand( $rss_feeds_count ) );
    my $rss_feeds_line = $rss_feeds[$rss_feeds_rand];
  close( f_rss_feeds );

  return $rss_feeds_line;
}


sub download_rss_feeds {

  my ( $self ) = @_;
  my $feeds_downloaded = 0;

  open( f_rss_feeds, "$ROOT_PATH/conf/rss_feeds.txt" ) or die("RSS feeds file does not exist");
  my @rss_feeds = (<f_rss_feeds>);
  close( f_rss_feeds );

  foreach (@rss_feeds) {
    my $rss_feeds_line = $_;
    chomp($rss_feeds_line);
    my $rss_file = $rss_feeds_line;

    $rss_file =~ s/http:\/\/// ;
    $rss_file =~ s/\//_/g ;
    chomp( $rss_file ) ;
    $rss_file .= ".xml";
    $rss_file = "$ROOT_PATH/rss/" . $rss_file;

    my $query_result = xml_download( $rss_feeds_line, $rss_file );
    my $rss_file_size = -s "$rss_file";

    if ($rss_file_size) {
      $feeds_downloaded++;
    }
  }

  return $feeds_downloaded;

}


sub get_rss_line {

  my $ret_rss_line = "";
  my $rss_feed = get_rss_feed();
  my $rss_file = $rss_feed;

  $rss_file =~ s/http:\/\/// ;
  $rss_file =~ s/\//_/g ;

  chomp( $rss_file ) ;

  $rss_file .= ".xml";
  $rss_file = "$ROOT_PATH/rss/" . $rss_file;

  my $rss_file_size = -s "$rss_file";

  ##  ------------------------  content reading  ---------------------------  ##
  if ( $rss_file_size ne 0 ) {

    my $xpath = XML::XPath->new(filename => $rss_file);
    my $cur_title = "";
    my $cur_description = "";
    my $cur_url = "";
    my $pub_date = "";

    my @items_array = $xpath->find('//item')->get_nodelist ;
    my $rss_items_count = scalar( @items_array );
    my $rss_item_rand = int(rand($rss_items_count));
    if ( $rss_item_rand eq 0 ) {
      $rss_item_rand = 1;
    }
    my $item_count = 0;
    foreach my $rss_item (@items_array) {
      $item_count++;
      if ($item_count eq $rss_item_rand) {
        $cur_title = $rss_item->find('title')->string_value;
        $cur_description = $rss_item->find('description')->string_value;
        $cur_url = $rss_item->find('link')->string_value;
        $pub_date = $rss_item->find('pubDate')->string_value;
        $ret_rss_line = $cur_title . " ==> " . $cur_url ;
      }
    }

  }
  ##  ------------------------  content reading  ---------------------------  ##

  return $ret_rss_line;
}


sub get_bash_rss_line {

  my $ret_rss_line = "";
  my $rss_feed = "http://bash.org.ru/rss/";
  my $rss_file = $rss_feed;

  $rss_file =~ s/http:\/\/// ;
  $rss_file =~ s/\//_/g ;

  chomp( $rss_file ) ;

  $rss_file .= ".xml";
  $rss_file = "$ROOT_PATH/rss/" . $rss_file;

  my $query_result = xml_download( $rss_feed, $rss_file );
  my $rss_file_size = -s "$rss_file";

  ##  ------------------------  content reading  ---------------------------  ##
  if ($rss_file_size ne 0) {
    my $xpath = XML::XPath->new( filename => $rss_file );
    my $cur_title = "";
    my $cur_description = "";
    my $rss_items_count = scalar( $xpath->find('//item')->get_nodelist );
    my $rss_item_rand = int( rand( $rss_items_count ) );
    if ( $rss_item_rand eq 0 ) {
      $rss_item_rand = 1;
    }

    my $item_count = 0;
    foreach my $rss_item ( $xpath->find('//item')->get_nodelist ) {
      $item_count = $item_count + 1;
      if ( $item_count eq $rss_item_rand ) {
        $cur_title = $rss_item->find('title')->string_value;
        $cur_description = $rss_item->find('description')->string_value;
        $ret_rss_line = $cur_title . "<br>" . $cur_description;
      }
    }

    my $char_add = get_special_char(18);
    $ret_rss_line = $char_add . " " . $ret_rss_line . " " . $char_add;
  }
  ##  ------------------------  content reading  ---------------------------  ##

  my $converter = Text::Iconv->new( 'utf-8', 'windows-1251' );
  return $converter->convert($ret_rss_line);
}


sub get_special_char {
  my ( $self, $char_code ) = @_;
  my $ret_char = "";
  $ret_char = `cat $ROOT_PATH/text/00$char_code.txt`;
  return $ret_char;
}

1;
