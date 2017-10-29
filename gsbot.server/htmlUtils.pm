package htmlUtils;

use LWP::Simple qw(getstore);
use strict;
use XML::XPath;
use Encode;
use Text::Iconv;
use HTML::TreeBuilder;
use vars qw($ua $wp);

$ua = new LWP::UserAgent;
$ua->agent("Mozilla/5.0 (compatible; GoogleBot 1.1; Google Inc.)");

my $ROOT_PATH = "/home/ubuntu/gsbot/gsbot.server";

#### NEWLCN defines ####

my $lcn_url         =   "http://newlcn.com/";
my $nom_page_prefix =   "nomination.php?rules=";
my $lcn_news_page   =   "news.php";

#http://www.newlcn.com/nomination.php?rules=ukr30pt
# nominations array:
# 1000 - 1000 pt 0
# 10pt - 1000 no market
# 5000 - 5000 pt 0
# 1000000 - $$$ pt 10
# mil0pt - $$$ pt 0
# 20pt - 5000 pt 20
# ukr30pt - ukraine pt 20
# 30pt - no rules pt 30
# sea - seawars

#### NEWLCN defines ####

my $html_tree = HTML::TreeBuilder->new;

sub new {
  my $pkg = shift;
  return bless {}, $pkg;
}

sub get_lcn_top {

  my ( $self, $nomination, $place ) = @_;
  $nomination = '1000' unless $nomination;
  $place      = 0 unless $place;

  my $nom_html = $ROOT_PATH . "/lcn/" . $nomination . ".html";
  my $nom_url  = $lcn_url . $nom_page_prefix . $nomination;

  my $response = $ua->get( $nom_url );
  my $page_content = $response->content;

  my $top_cnt = 0;
  my $html_tree = HTML::TreeBuilder->new_from_content( $page_content );
  my $nom_name_hash = $html_tree->look_down( '_tag' => 'div', 'class' => 'nomination_info header1');

  if ( $nom_name_hash eq '' ) {
    return "";
  }

  my $nom_name = $nom_name_hash->as_HTML("<>%");
  my $top_list = $nom_name;
  $top_list =~ s{(^.*)\>(.*)(\<\/div\>$)}{$2};
  chomp($top_list);
  $top_list .= ": ";

  my $top_players = "";
  foreach my $top_player_row ( $html_tree->look_down( '_tag' => 'tr', 'class'=>'top1 ') ) {

    my $top_player_html = $top_player_row->as_HTML("<>%");
    my $top_table_tree  = HTML::TreeBuilder->new_from_content( $top_player_html );
    foreach my $top_player_a ( $top_table_tree->look_down( '_tag' => 'a' ) ) {
      my $top_player_ = $top_player_a->as_HTML("<>%");
      my $top_player = $top_player_;
      $top_player =~ s{(^.*)\>(.*)(\<\/a\>$)}{$2};
      chomp($top_player);
      if ( $top_player ) {
        $top_cnt += 1;
        if ( $place > 0 and $top_cnt eq $place) {
          $top_players .= $top_cnt . " - " . $top_player;
        }else{
          if ( $place == 0 ) {
            $top_players .= $top_cnt . " - " . $top_player;
            if ( $top_cnt ne $place) {
              $top_players .= "; ";
            }
          }
        }
      }
    }

    if ($place > 0 and $top_cnt eq $place){
      last;
    }

  }

  if ($top_players ne "") {
    return $top_list . $top_players;
  }else{
    return "";
  }

}

## returns one item from lcn news feed
sub get_lcn_news_item {

  my ( $self )     = @_;
  my $news_html    = $ROOT_PATH . "/lcn/news.html";
  my $news_url     = $lcn_url . $lcn_news_page;
  my $response     = $ua->get( $news_url );
  my $page_content = $response->content;

  my $top_cnt = 0;
  my $html_tree = HTML::TreeBuilder->new_from_content( $page_content );

  my $news_item           = "";
  my $news_item_date      = "";
  my $news_div            = $html_tree->look_down( '_tag' => 'div', 'class'=>'news_list');
  my $news_div_html       = $news_div->as_HTML("<>%");
  my $news_div_html_tree  = HTML::TreeBuilder->new_from_content( $news_div_html );

  my $random_dig = int(rand(10));
  $random_dig ++;

  my $i_cnt = 0;
  foreach my $news_item_row ( $news_div_html_tree->look_down( '_tag' => 'p') ) {
    $i_cnt++;
    my $news_item_row_html = $news_item_row->as_HTML("<>%");

    if ( $i_cnt eq $random_dig ) {
      $news_item      =   $news_item_row_html;
      $news_item_date =   $news_item_row_html;
      $news_item      =~  s{(^.*)\>(.*)(\<br \/\>\<span)(.*$)}{$2};
      $news_item_date =~  s{(^.*)i\>(.*)(\<\/i\>)(.*$)}{$2};

      chomp($news_item);
      chomp($news_item_date);

      $news_item = $news_item_date . " - " . $news_item;
      last;
    }

  }

  return $news_item;

}

1;
