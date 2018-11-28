#!/usr/bin/perl -w

use strict;
use warnings;
use Switch;
use Text::Wrapper;
use Text::Iconv;
use vars qw($wrapper);
use Net::IRC;
use IO::Socket;
use List::MoreUtils;
use Net::MySQL;

use gsUtils;
use xmlUtils;
use sUtils;
use htmlUtils;

no warnings "utf8";

my $script_version = "1.2.5";
my $logging_enable = 0;

my $ROOT_PATH = "/home/ubuntu/gsbot/gsbot.server";

my $gs = new gsUtils;
my $xml_utils = new xmlUtils;
my $html_utils = new htmlUtils;
my $s_utils = new sUtils;

# files definition
my $file_quotes = "$ROOT_PATH/text/quotes.txt";
my $file_punish = "$ROOT_PATH/text/punish.txt";

# text wrapper to wrap long messages at the approximate length an IRC
# message should be, at its longest
$wrapper = new Text::Wrapper(columns => 400);

# converters definition
my $converter_koi2win = Text::Iconv->new( 'koi8u', 'windows-1251' );
my $converter_utf2win = Text::Iconv->new( 'utf8', 'windows-1251' );

my $converter_win2koi = Text::Iconv->new( 'windows-1251', 'koi8u' );
my $converter_win2utf = Text::Iconv->new( 'windows-1251', 'utf8' );

# create the IRC object
my $irc = new Net::IRC;

# prepare a random nick for bot
my @bot_names = $gs->get_file_content( "bot_nicks" );
my @bot_salts = $gs->get_file_content( "salts" );

my $random_len = int(rand(8)) + 1;
my $nick_range = 10 ** $random_len ;
my $random = int( rand( $nick_range ));

my $bot_name = $bot_names[ int(rand( scalar( @bot_names ) ))];
my $bot_salt = $bot_salts[ int(rand( scalar( @bot_salts ) ))];
my $bot_nick = $bot_name;
print "Nick used: " . $bot_nick . "\n";

my $start_time = (time)[0];
my $public_count = 0;
my $quote_public_count = 200;
print "rss_downloaded: " . $xml_utils->download_rss_feeds() . "\n";

##----------------------------------------------------------------------------##
## arrays preparation

my @howto_join = $gs->get_file_content( "howto_join" );
my @howto_create = $gs->get_file_content( "howto_create" );
my @howto_rank = $gs->get_file_content( "howto_rank" );
my @howto_version = $gs->get_file_content( "howto_version" );

##----------------------------------------------------------------------------##

# Create a connection object.  You can have more than one "connection" per
# IRC object, but we'll just be working with one.
my $conn = $irc->newconn(
	Server   => shift || '69.10.30.243',
	Port     => shift || '6667',
	Nick     => $bot_nick,
	Ircname  => 'I like to answer questions!',
	Username => $bot_nick . "!" . int(rand( 9 ))
);

# We're going to add this to the conn hash so we know what channel we
# want to operate in.
$conn->{channel} = shift || '#GSP!cossacks';


sub on_connect {

	# shift in our connection object that is passed automatically
	my $conn = shift;

	# when we connect, join our channel and greet it
	$conn->join($conn->{channel});
	$conn->privmsg($conn->{channel}, $converter_utf2win->convert( 'Здарова, казакеры! Наберите !help чтобы увидеть мои команды.') );
	$conn->{connected} = 1;

}


sub on_join {

	# get our connection object and the event object, which is passed
	# with this event automatically
	my ($conn, $event) = @_;

	# this is the nick that just joined
	my $nick = $event->{nick};
	my $host = $event->host;
	my $userhost = $event->{userhost};
	my @userhost_splitted = split( "@", $userhost );

	# say hello to the nick in public
	# $conn->privmsg($conn->{channel}, "Hello, $nick!");
	# $conn->privmsg($nick, "Hello, $nick!");

	# say hello with random quote
	# my $quote_line = get_quote();
	if ($nick ne $bot_nick)  {
		# $conn->privmsg( $conn->{channel}, $nick . ", " . $quote_line);
		# $conn->privmsg( $nick, $quote_line);
	}

	if ($logging_enable eq 1) {

		# log host of nick joined user
		if ($nick ne $bot_nick and $nick !~ "asker_") {
			my $logDate = $gs->get_date();
			my $logTime = $gs->get_time();
			my $log_file = "$ROOT_PATH/logs/" . $logDate . ".log";

			system "$ROOT_PATH/sh/player_ip.sh '$userhost'";

			my @player_ip = $gs->get_file_content( "$ROOT_PATH/sh/player_ip.txt" );
			my $ip = $player_ip[0];
			chomp($ip);

			$gs->add_file_content( $log_file, "$logTime\t$nick\t$ip\t$userhost");
			print "LOGGED JOIN $log_file: $logTime: $nick : $ip : $userhost \n";

			my @kicked_ip = $gs->get_file_content( "kicked_ip" );
			if ( $ip ~~ @kicked_ip ){
				$gs->add_file_content( "kicked", "$nick" );
				print "ADDED TO KICKED : $logTime: $nick : $ip : $userhost \n";
			}

		}
	}

	#### xIRC clients ignoring
	if ( ( $userhost_splitted[1] !~ /^\d+$/ and $nick !~ "asker_") or ( "$userhost_splitted[1]" eq "0" and $nick !~ "asker_" ) ) {
		my @ignored = $gs->get_file_content( "ignored" );
		my @flooders = $gs->get_file_content( "flooders" );
		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );
		if ( $nick ~~ @ignored ) {
		} else {
			if ( $nick ~~ @flooders ) {
			} else {
				if ( $nick ~~ @allowed or $nick ~~ @admins ) {
				} else {
					$gs->add_file_content( "ignored", $nick );
					print "ADDED TO IGNORED LIST : $nick : $userhost \n";
				}
			}
		}
	}

}


sub on_part {

	my ($conn, $event) = @_;
	my $nick = $event->{nick};
	# $conn->privmsg($conn->{channel}, "Goodbye, $nick!");

}


sub on_public {

	# on an event, we get connection object and event hash
	my ($conn, $event) = @_;

	my $text = $event->{args}[0];
	my $nick = $event->{nick};
	my $host = $event->host;
	my $host1 = $event->{host};
	my $userhost = $event->{userhost};
	my $userhost1 = $event->userhost;

	my @words = split( / /, $text);
	my $command = shift(@words);

	my @flooders = $gs->get_file_content( "flooders" );
	my @ignored = $gs->get_file_content( "ignored" );
	my @victims = $gs->get_file_content( "victims" );
	if ($nick ~~ @ignored) {
		last;
	}else{
		$public_count = $public_count + 1;
	}

	if ($converter_win2utf->convert($text) =~ 'расскажи че нить') {
		if ( $nick ~~ @flooders ) {
		}else{
			$conn->privmsg( $conn->{channel}, $converter_utf2win->convert( "Та блин, мистер " . $nick . ", задолбался уже рассказывать, целыми днями этим занимаюсь =)" ) );
		}
	}

	foreach my $ht_create (@howto_create) {
		if ( index( $converter_win2utf->convert( $text ), $ht_create ) >= 0 ) {
			$conn->privmsg( $conn->{channel}, $nick . ", " . $converter_utf2win->convert( $ht_create ) . " - " . $converter_utf2win->convert( " читай здесь: " ) . $howto_create[-1] . " ;-)" );
			last;
		}
	}

	foreach my $ht_join (@howto_join) {
		if ( index( $converter_win2utf->convert( $text ), $ht_join ) >= 0 ) {
			$conn->privmsg( $conn->{channel}, $nick . ", " . $converter_utf2win->convert( $ht_join ) . " - " . $converter_utf2win->convert( $howto_join[-1] ) . " ;-)" );
			last;
		}
	}

	foreach my $ht_rank (@howto_rank) {
		if ( index( $converter_win2utf->convert( $text ), $ht_rank ) >= 0 ) {
			$conn->privmsg( $conn->{channel}, $nick . ", " . $converter_utf2win->convert( $ht_rank ) . " - " . $converter_utf2win->convert( " читай здесь: " ) . $howto_rank[-1] . " ;-)" );
			last;
		}
	}

	foreach my $ht_ver (@howto_version) {
		if ( index( $converter_win2utf->convert( $text ), $ht_ver ) >= 0 ) {
			$conn->privmsg( $conn->{channel}, $nick . ", " . $converter_utf2win->convert( $ht_ver ) . " - " . $converter_utf2win->convert( $howto_version[-1] ) . " ;-)" );
			last;
		}
	}

	if ($logging_enable eq 1) {
		# log message
		if ( $nick !~ /^\d+$/ and $text !~ /@@@/ ){
			my $logTime = $gs->get_time();
			my $logDate = $gs->get_date();
			my $log_file = "$ROOT_PATH/logs/" . $logDate . "_public.txt";
			$gs->add_file_content( $log_file, "$logTime\t$nick\t$text");
			$public_count = $public_count + 1;
			print "LOGGED MSG: " . "$logTime\t$nick\t$text\t$host\t$userhost\t$userhost1\n";
		}else{
			last;
		}
	}

	#### RSS line message
	if ($public_count eq $quote_public_count/4) {
		my $char_add = $xml_utils->get_special_char(18);
		my $rss_line = $converter_utf2win->convert( $xml_utils->get_rss_line() );
		$rss_line = $char_add . " " . $rss_line . " " . $char_add;
		$conn->privmsg( $conn->{channel}, $rss_line );
	}

	#### QUOTE line message
	if (($public_count eq $quote_public_count/2) or ($public_count eq $quote_public_count)) {
		my $char_add = $xml_utils->get_special_char(18);
		my $quote_line = get_quote();
		$conn->privmsg( $conn->{channel}, $char_add . " " . $quote_line . " " . $char_add );
		$public_count = 0;
	}

	#### FLOOD prevent
	if ($nick ~~ @flooders) {
		# my $punish_mess = get_punish() . " " . int( rand( 1000 ));
		# $conn->privmsg( $nick, $punish_mess );
	}
	#### END of FLOOD prevent

	#### VICTIMS
	if ( $nick ~~ @victims ) {
		my $punish_mess = get_punish() . " " . int( rand( 1000 ));
		$conn->privmsg( $nick, $punish_mess );
	}
	#### END of VICTIMS

	#### COUNT request
	if ($text =~ /^\!?[Cc][Oo][Uu][Nn][Tt]/ ) {
		$conn->privmsg( $conn->{channel}, "Count: $public_count/$quote_public_count");
	}
	#### END of COUNT request

	#### CLEAR request
	if ($text =~ /^\!?[Cc][Ll][Ee][Aa][Rr]/ ) {
		my $char_add = $xml_utils->get_special_char(0);
		$conn->privmsg( $conn->{channel}, $char_add . "                                                                                                                                                         " . $char_add );
		$conn->privmsg( $conn->{channel}, $char_add . "                                                                                                                                                         " . $char_add );
		$conn->privmsg( $conn->{channel}, $char_add . "                                                                                                                                                         " . $char_add );
		$conn->privmsg( $conn->{channel}, $char_add . "                                                                                                                                                         " . $char_add );
		$conn->privmsg( $conn->{channel}, $char_add . "                                                                                                                                                         " . $char_add );
		$conn->privmsg( $conn->{channel}, $char_add . "                                                                                                                                                         " . $char_add );
	}
	#### END of CLEAR request

	#### HELP request
	if ($text =~ /^\!?[Hh][Ee][Ll][Pp]/ or $converter_win2utf->convert( $text ) =~ 'хелп' or $converter_win2utf->convert( $text ) =~ 'ХЕЛП' ) {
		my $help_message = get_help();
		$conn->privmsg( $conn->{channel}, "$help_message");
		$conn->privmsg( $nick, "$help_message");
	}
	#### END of HELP request

	#### SELF IP request MYIP
	if ( $text =~ /^\!?[Mm][Yy][Ii][Pp]/ ) {
		my $ip_of_player = $gs->get_ip( $nick );
		print "IP of $nick : $ip_of_player \n\n";
		$conn->privmsg( $event->{nick}, "Your IP is: $ip_of_player");
		print "\nSelf IP of $nick : $ip_of_player requested\n\n";

		my $logTime = $gs->get_time();
		open( f_query, ">>$ROOT_PATH/query/query_ip.txt" ) or die "cannot create file query_ip.txt!";
		print f_query "$logTime\tIP of $nick : $ip_of_player , requested by $nick ($host) (PUBLIC)\n";
		close( f_query );
	}
	#### END of SELF IP request

	#### LAST VISIT of player request
	if ( $text =~ /^\!?[Ll][Aa][Ss][Tt]/ ) {
		my @flooders = $gs->get_file_content( "flooders" );
		my $player_nick = "";
		$player_nick = shift( @words );
		if ( $player_nick eq "" ) {
			$player_nick = $nick;
		}
		my $answer_message = $nick . ", ";
		my $last_visit = "";
		my $query_time = $gs->get_time();
		if ( $player_nick ne "" ) {
			$last_visit = $gs->get_last_visit( $player_nick );
			if ( length($last_visit) == 0 ) {
				$answer_message .= "No such nick: $player_nick. Check spelling.";
			}else{
				$answer_message .= "$player_nick last visited GS on: $last_visit";
				print "\nLast visit of $player_nick : $last_visit, requested by $nick ($host) (PUBLIC)\n";
			}
		}

		my @banned_nicks = $gs->get_file_content( "banned" );
		if ( $nick ~~ @banned_nicks ) {
			$answer_message = "You are not allowed to query last visits of other players!"
		}

		$conn->privmsg( $conn->{channel}, $answer_message );

		my $logTime = $gs->get_time();
		open( f_query, ">>$ROOT_PATH/query/query_last_visit.txt" ) or die "cannot create file query_last_visit.txt!";
		print f_query "$logTime\t$player_nick\t$last_visit\t$nick\t$userhost1 (PUBLIC)\n";
		close( f_query );

	}
	#### END of IP of PLAYER request

	#### SELF ID request
	if ( $text =~ /^\!?[Mm][Yy][Ii][Dd]/ ) {
		my $id_of_player = $gs->get_id( $nick );
		if ( $id_of_player eq "*" ) {
			$conn->privmsg( $event->{nick}, "You don't have ID! IRC-client used? :)");
		}else{
			$conn->privmsg( $event->{nick}, "Your ID is: $id_of_player");
		}
		print "\nSelf ID of $nick : $id_of_player requested\n\n";

		my $logTime = $gs->get_time();
		open( f_query, ">>$ROOT_PATH/query/query_id.txt" ) or die "cannot create file query_id.txt!";
		print f_query "$logTime\tID of $nick : $id_of_player , requested by $nick ($host) (PUBLIC)\n";
		close( f_query );
	}
	#### END of SELF ID request

	#### NICKS for IP request
	if ( $text =~ /^\!?[Nn][Ii][Cc][Kk][Ss]/ ) {
		my $ip_request = shift( @words );
		my @allowed = $gs->get_file_content( "allowed" );
		if ( $event->{nick} ~~ @allowed ) {
			my @nicks_list = $gs->get_nicks( $ip_request );
			my $nicks_list = join( "", @nicks_list );
			@nicks_list = split( /\n/, $nicks_list);
			$nicks_list = "";

			my @protected = $gs->get_file_content( "protected" );
			for my $cur_nick (@nicks_list) {
				if ( $cur_nick ~~ @protected ) {
				}else{
					$nicks_list = $nicks_list . " " . $cur_nick . ",";
				}
			}

			$conn->privmsg( $conn->{channel}, $ip_request . ": " . $nicks_list );
			my $logTime = $gs->get_time();
			open( f_query_nicks, ">>$ROOT_PATH/query/query_nicks.txt" ) or die "cannot create file query_nicks.txt!";
			print f_query_nicks "$logTime\t$ip_request\t$nicks_list\t$nick ($userhost) (PUBLIC)\n";
			close( f_query_nicks );

		}else{
			$conn->privmsg( $conn->{channel}, $nick . ", you are not allowed to query nicks of other players" );
		}

	}
	#### END of NICKS for IP request

	#### QUOTE request
	if ($text =~ /^\!?[Qq][Uu][Oo][Tt][Ee]/ ) {
		my $quote_line = get_quote();
		$conn->privmsg($conn->{channel}, "-->" . $nick . ", " . $quote_line);
	}
	#### END of QUOTE request

	#### RSS feed print
	if ( $text =~ /^!?[Rr][Ss][Ss]/ ) {
		my $char_add = $xml_utils->get_special_char(18);
		my $rss_line = $converter_utf2win->convert( $xml_utils->get_rss_line() );
		$rss_line = $char_add . " " . $rss_line . " " . $char_add;
		$conn->privmsg( $conn->{channel}, $rss_line );
	}
	#### END of RSS feed print

	#### BASH RSS feed print
	if ( $text =~ /^!?[Bb][Aa][Ss][Hh]/ ) {
		my $rss_line = $xml_utils->get_bash_rss_line();
		my @bash = split( "<br>", $rss_line);
		my $cur_line = "";
		foreach (@bash) {
			$cur_line = $_;
			$cur_line =~ s/\&quot;/\"/g;
			$cur_line =~ s/\&lt;/\</g;
			$cur_line =~ s/\&gt;/\>/g;
			$conn->privmsg( $conn->{channel}, $cur_line );
		}
	}
	#### END of BASH RSS feed print

	#### RUDE answer
	#    my @rude = $gs->get_rude();
	#    my @arr_text = split( / /, $text );
	#    foreach (@arr_text) {
	#        if ( $text =~ /!?[HhXx][YyUu][YyIi]/ or $converter_win2utf->convert( $text ) ~~ @rude or uc($converter_win2utf->convert( $text )) ~~ @rude or lc($converter_win2utf->convert( $text )) ~~ @rude ) {
	#        if ( $_ =~ /!?[HhXx][YyUu][YyIi]/ or $converter_win2utf->convert( $_ ) ~~ @rude or uc($converter_win2utf->convert( $_ )) ~~ @rude or lc($converter_win2utf->convert( $_ )) ~~ @rude ) {
	#            $conn->privmsg( $conn->{channel}, $converter_utf2win->convert( "$nick, " . "не ругайся, а то забаню." ) );
	#            last;
	#        }
	#    }
	#### END of RUDE answer

	#### RANKLIST request
	if ($text =~ /^\!?[Rr][Aa][Nn][Kk][Ss]/ ) {
		my $rank_list = "Звания: Нуб(0-24) -> Дворянин(25-89) -> Рыцарь(90-159) -> Барон(160-209) -> Виконт(210-339) -> Граф(340-589) -> Маркиз(590-1289) -> Герцог(1290-2239) -> Король(2240+) ";
		$conn->privmsg($conn->{channel}, $nick . ", " . $converter_utf2win->convert($rank_list) );
	}
	#### END of RANKLIST request

	#### RANKLISTEN request
	if ($text =~ /^\!?[Rr][Aa][Nn][Kk][Ii][Nn][Gg]/ ) {
		my $rank_list = "Cossacks Ranking: Noob(0-24) -> Nobleman(25-89) -> Knight(90-159) -> Baron(160-209) -> Vicomte(210-339) -> Earl(340-589) -> Marquis(590-1289) -> Duke(1290-2239) -> King(2240+) ";
		$conn->privmsg($conn->{channel}, $nick . ", " . $rank_list );
	}
	#### END of RANKLISTEN request

	#### HERE? request
	if ($text =~ /^[Hh][Ee][Rr][Ee]\?/ or $converter_win2utf->convert( $text ) =~ 'тута?' ) {
		$conn->privmsg( $nick, $converter_utf2win->convert( "На месте!" ) );
	}
	#### END of HERE? request

	#### LCNTOP request
	if ($text =~ /^\!?[Ll][Cc][Nn][Tt][Oo][Pp]/ ) {
		my @text_arr = split( " ", $text);
		my $char_add = $xml_utils->get_special_char(18);
		my $lcn_top_player = $html_utils->get_lcn_top( $text_arr[1], $text_arr[2] );
		if ( $lcn_top_player ne "" ) {
			$conn->privmsg( $conn->{channel}, $char_add . " " . "$nick, LCN top at $lcn_top_player" . " " . $char_add);
		}else{
			$conn->privmsg( $conn->{channel}, "$nick, No such nomination: $text_arr[1] or place $text_arr[2] not in the top list!");
		}
	}
	#### END of LCNTOP request

	#### LCNNOM request
	if ($text =~ /^\!?[Ll][Cc][Nn][Nn][Oo][Mm]/ ) {
		my $char_add = $xml_utils->get_special_char(18);
		my $lcn_noms = get_lcn_noms();
		$conn->privmsg( $conn->{channel}, $char_add . " " . "$nick, $lcn_noms" . " " . $char_add);
	}
	#### END of LCNNOM request

	#### LCNNEWS request
	if ($text =~ /^\!?[Ll][Cc][Nn][Nn][Ee][Ww][Ss]/ ) {
		my $char_add = $xml_utils->get_special_char(18);
		my $lcn_news_item = $html_utils->get_lcn_news_item( );
		$conn->privmsg( $conn->{channel}, $char_add . " " . "newlcn.com: " . "$lcn_news_item" . " " . $char_add );
	}
	#### END of LCNNEWS request

	#### request to add NICK into ignored.txt file
	if ( $text =~ /^\!?[Aa][Dd][Dd][Tt][Oo]/ ) {
		my $file2add = shift( @words ) || "ignored";
		my $nick4add = shift( @words );
		my @admins = $gs->get_file_content( "admins" );
		if ( $nick ~~ @admins ) {
			$gs->add_file_content( $file2add, $nick4add );
			$conn->privmsg( $conn->{$nick}, $nick4add . " added to " . $file2add . " list" );
			print $nick4add . " ADDED TO " . $file2add . " list";
		}else{
			$conn->privmsg( $conn->{channel}, $nick . ", you are not allowed to add nicks into " . $file2add . " list" );
		}
	}
	#### END of request to add NICK into ignored.txt file

	#### GAME Announce
	if ( $text =~ /^!?[1][0][0][0]/ or $text =~ /^!?[1][Kk]/) {
		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );
		if ( $nick ~~ @allowed or $nick ~~ @admins ) {
			my $char_add = $xml_utils->get_special_char('18');
			my $spacer = "                                                                                    ";
			my $announce_line = $spacer . $converter_utf2win->convert( "1OOO pt O nO rules 2-2 3-3" ) . $spacer . "Join: " . $nick . " ";
			$announce_line = $char_add . " " . $announce_line . " " . $char_add;
			$conn->privmsg( $conn->{channel}, $announce_line );
		}
	}

	if ( $text =~ /^!?[5][0][0][0]/ or $text =~ /^!?[5][Kk]/) {
		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );
		if ( $nick ~~ @allowed or $nick ~~ @admins ) {
			my $char_add = $xml_utils->get_special_char('18');
			my $spacer = "                                                                                    ";
			my $announce_line = $spacer . $converter_utf2win->convert( "5OOO pt O nO rules 2-2 3-3" ) . $spacer . "Join: " . $nick . " ";
			$announce_line = $char_add . " " . $announce_line . " " . $char_add;
			$conn->privmsg( $conn->{channel}, $announce_line );
		}
	}
	#### END of GAME Announce

}


sub get_help {
	my $help_message = "";
	$help_message .= "Available commands: ";
	$help_message .= "LAST player_nick; ";
	$help_message .= "MYIP; ";
	$help_message .= "MYID; ";
	$help_message .= "RANKS (ru); ";
	$help_message .= "RANKING (en); ";
	$help_message .= "QUOTE; ";
	$help_message .= "RSS; ";
	$help_message .= "LCNNOM; ";
	$help_message .= "LCNTOP nomination [place]; ";
	$help_message .= "LCNNEWS; ";
	$help_message .= "HELP; ";
}

sub get_lcn_noms {
	my $lcn_noms = "";
	$lcn_noms .= "LCN nominations: ";
	$lcn_noms .= "1000; ";							# - 1000 pt 0; ";
	$lcn_noms .= "10pt; ";							# - 1000 no market; ";
	$lcn_noms .= "5000; ";							# - 5000 pt 0; ";
	$lcn_noms .= "1000000; ";						# - $$$ pt 10; ";
	$lcn_noms .= "mil0pt; ";						# - $$$ pt 0; ";
	$lcn_noms .= "20pt; ";							# - 5000 pt 20; ";
	$lcn_noms .= "ukr30pt; ";						# - ukraine pt 20; ";
	$lcn_noms .= "30pt; ";							# - no rules pt 30; ";
	$lcn_noms .= "sea; ";								# - seawars; ";
}

sub get_full_help {
	my $help_message = "";
	$help_message .= "Secret commands: ";
	$help_message .= "MYIP; ";
	$help_message .= "IP player_nick; ";
	$help_message .= "ALLIP player_nick; ";
	$help_message .= "ALLIDS player_nick; ";
	$help_message .= "ALLIDGS player_nick; ";
	$help_message .= "ID2IP player_ID; ";
	$help_message .= "NICKS player_ip; ";
	$help_message .= "ALLNICKS player_nick|ip; ";
	$help_message .= "RSS; ";
	$help_message .= "COUNT; ";
}

sub on_msg {
	my ($conn, $event) = @_;
	my $nick = $event->{nick};
	my $host = $event->{host};
	my $userhost = $event->{userhost};
	my @splitted_host = split( "@", $userhost );
	my $user_gs_id = $splitted_host[1];
	my $received_message = $event->{args}[0];
	my @words = split( / /, $received_message);
	my $command = shift( @words );

	# log message
	my $logTime = $gs->get_time();
	my $logDate = $gs->get_date();
	my $logFile = "$ROOT_PATH/logs/" . $logDate . "_private.txt";
	$gs->add_file_content( $logFile, "$logTime\t$nick\t$userhost\t$received_message");

	#### SECRET HELP request
	if ($command =~ /^\!?[Gg][Ii][Vv][Ee][Ff][Uu][Ll][Ll][Hh][Ee][Ll][Pp]/ ) {
		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );
		if ( ( $user_gs_id =~ /^\d+$/ and $nick ~~ @allowed ) or $nick ~~ @admins ) {
			my $help_message = get_full_help();
			$conn->privmsg( $nick, "$help_message");
		}
	}
	#### END of SECRET HELP

	#### LIST of players request
	if ( $command =~ /^\!?[Ll][Ii][Ss][Tt]/ ) {
		# print "Now call get_names ...\n\n";
		my $players_list = $gs->get_names();
		my @players_list = split( / /, $players_list);
		foreach (@players_list) {
			print $_ . "\n";
		}
	}
	#### END of IP of PLAYER request

	#### IP of PLAYER request
	if ( $command =~ /^\!?[Mm][Yy][Ii][Pp]/ ) {
		my $ip_of_player = $gs->get_ip( $event->{nick} );
		$conn->privmsg( $event->{nick}, "Your IP is: $ip_of_player");
		my $logTime = $gs->get_time();
		open( f_query, ">>$ROOT_PATH/query/query_ip.txt" ) or die "cannot create file query_ip.txt!";
		print f_query "$logTime\t$nick\t$ip_of_player\t$nick\t$userhost\t(PRIV)\n";
		close( f_query );
	}
	#### END of IP of PLAYER request

	#### IP of player request
	if ( $command =~ /^\!?[Ii][Pp]/ ) {
		my $player_nick = shift( @words );
		if ($player_nick eq "") {
			$player_nick = $nick;
		}

		my $ip_of_player = $gs->get_ip( $player_nick );
		my $answer_message = $event->{nick} . ", ";
		my $query_time = $gs->get_time();
		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );

		if ( ( $user_gs_id =~ /^\d+$/ or $nick ~~ @allowed ) or $nick ~~ @admins ) {
			if ( length($ip_of_player) == 0 ) {
				$answer_message .= "No such nick: $player_nick. Check spelling.";
			}else{
				$answer_message .= "IP of $player_nick is: $ip_of_player. Time: $query_time (GMT+02)";
			}

			my @banned_nicks = $gs->get_file_content( "banned" );
			if ( $event->{nick} ~~ @banned_nicks ) {
				$answer_message = "You are not allowed to query IP addresses of other players!"
			}
			$conn->privmsg( $event->{nick}, $answer_message );
		}else{
			$answer_message = "Players who are not logged in throw cossacks are NOT ALLOWED to query IP addresses!";
		}
		print "\nIP of $player_nick : $ip_of_player , requested by $event->{nick}\n\n";

		my $logTime = $gs->get_time();
		open( f_query, ">>$ROOT_PATH/query/query_ip.txt" ) or die "cannot create file query_ip.txt!";
		print f_query "$logTime\t$player_nick\t$ip_of_player\t$nick\t$userhost\t(PRIV)\n";
		close( f_query );

	}
	#### END of IP of PLAYER request

	#### ALL NICKs of PLAYER
	if ( $command =~ /^\!?[Aa][Ll][Ll][Nn][Ii][Cc][Kk][Ss]/ ) {
		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );
		if ( ( $user_gs_id =~ /^\d+$/ and $nick ~~ @allowed ) or $nick ~~ @admins ) {
			my $player_nick = shift( @words );
			print "player_nick for request ALLNICKS: " . $player_nick . "\n";
			my @ips_list = $gs->get_ip_all( $player_nick );
			my $ips_list = join( "", @ips_list );
			@ips_list = split( /\n/, $ips_list);
			my $full_nicks_list = $player_nick . ": ";
			my $cur_ip = "";
			my $logTime = $gs->get_time();
			if ( scalar(@ips_list) > 0 ) {
				foreach $cur_ip (@ips_list) {
					my @nicks_list = $gs->get_nicks( $cur_ip );
					my $nicks_list = join( "", @nicks_list );
					@nicks_list = split( /\n/, $nicks_list);
					my %seen = ();
					my @unique_nicks_list = grep { ! $seen{ $_ }++ } @nicks_list;
					$nicks_list = join( ",", @unique_nicks_list);
					$full_nicks_list .= $nicks_list . ",";
					$conn->privmsg( $event->{nick}, $cur_ip . ": " . $nicks_list );
					sleep(0.2);
					open( f_query, ">>$ROOT_PATH/query/query_all_nicks.txt" ) or die "cannot create file query_all_nicks.txt!";
					print f_query "$logTime\t$player_nick\t$cur_ip\t$nicks_list\t$nick ($userhost) (PRIV)\n";
					close( f_query );
				}
			}else{
				$conn->privmsg( $event->{nick}, "No records in database for $player_nick" );
			}
		}else{
			$conn->privmsg( $event->{nick}, "Sorry, but you are not allowed to running query of this type." );
		}
	}
	#### END of ALL NICKs of PLAYER

	#### ALL IPs of PLAYER for NICK
	if ( $command =~ /^\!?[Aa][Ll][Ll][Ii][Pp]/ ) {

		my @allowed = $gs->get_file_content( "allowed" );
		my @admins = $gs->get_file_content( "admins" );

		if ( ( $user_gs_id =~ /^\d+$/ and $nick ~~ @allowed ) or $nick ~~ @admins ) {
			my $player_nick = shift( @words );
			my @ips_list = $gs->get_ip_all( $player_nick );
			my $ips_list = join( "", @ips_list );
			@ips_list = split( /\n/, $ips_list);
			my $cur_ip = "";
			my $logTime = $gs->get_time();
			if ( scalar(@ips_list) > 0 ) {
				my %seen = ();
				my @unique_ips_list = grep { ! $seen{ $_ }++ } @ips_list;
				$ips_list = join( ", ", @unique_ips_list);
				$ips_list = $player_nick . ": " . $ips_list;
				$conn->privmsg( $event->{nick}, $ips_list );
				open( f_query, ">>$ROOT_PATH/query/query_all_ips.txt" ) or die "cannot create file query_all_ips.txt!";
				print f_query "$logTime\t$player_nick\t$ips_list\t$nick ($userhost) (PRIV)\n";
				close( f_query );
			}else{
				$conn->privmsg( $event->{nick}, "No records in database for $player_nick" );
			}
		}

	}
	#### END of ALL IPs of PLAYER for NICK

	#### ALL IPs of PLAYER for ID
	if ( $command =~ /^\!?[Ii][Dd][2][Ii][Pp]/ ) {
		my $player_id = shift( @words );
		my @ips_list = $gs->get_ip_for_id( $player_id );
		my $ips_list = join( "", @ips_list );
		@ips_list = split( /\n/, $ips_list);
		my $cur_ip = "";
		my $logTime = $gs->get_time();
		if ( scalar(@ips_list) > 0 ) {
			my %seen = ();
			my @unique_ips_list = grep { ! $seen{ $_ }++ } @ips_list;
			$ips_list = join( ", ", @unique_ips_list);
			$ips_list = $player_id . ": " . $ips_list;
			$conn->privmsg( $event->{nick}, $ips_list );

			open( f_query, ">>$ROOT_PATH/query/query_all_ip_for_id.txt" ) or die "cannot create file query_all_ip_for_id.txt!";
			print f_query "$logTime\t$player_id\t$ips_list\t$nick ($userhost) (PRIV)\n";
			close( f_query );
		}else{
			$conn->privmsg( $event->{nick}, "No records in database for ID=$player_id" );
		}
	}
	#### END of ALL IPs of PLAYER for ID

	#### ALL IDs for NICK
	if ( $command =~ /^\!?[Aa][Ll][Ll][Ii][Dd][Ss]/ ) {
		my $player_nick = shift( @words );
		my @ids_list = $gs->get_id_all( $player_nick );
		my $ids_list = join( "", @ids_list );
		@ids_list = split( /\n/, $ids_list);
		my $cur_id = "";
		my $logTime = $gs->get_time();
		if ( scalar(@ids_list) > 0 ) {
			my %seen = ();
			my @unique_ids_list = grep { ! $seen{ $_ }++ } @ids_list;
			$ids_list = join( ", ", @unique_ids_list);
			$ids_list = $player_nick . ": " . $ids_list;
			$conn->privmsg( $event->{nick}, $ids_list );

			open( f_query, ">>$ROOT_PATH/query/query_all_ids.txt" ) or die "cannot create file query_all_ids.txt!";
			print f_query "$logTime\t$player_nick\t$ids_list\t$nick ($userhost) (PRIV)\n";
			close( f_query );
		}else{
			$conn->privmsg( $event->{nick}, "No records in database for $player_nick" );
		}
	}
	#### END of ALL IDs for NICK

	#### ALL IDs for NICK from GameSpy
	if ( $command =~ /^\!?[Aa][Ll][Ll][Ii][Dd][Gg][Ss]/ ) {
		my $player_nick = shift( @words );
		my @ids_list = $gs->get_id_all_gs( $player_nick );
		my $ids_list = join( "", @ids_list );
		@ids_list = split( /\n/, $ids_list);
		my $cur_id = "";
		my $logTime = $gs->get_time();
		if ( scalar(@ids_list) > 0 ) {
			my %seen = ();
			my @unique_ids_list = grep { ! $seen{ $_ }++ } @ids_list;
			$ids_list = join( ", ", @unique_ids_list);
			$ids_list = $player_nick . ": " . $ids_list;
			$conn->privmsg( $event->{nick}, $ids_list );
			open( f_query, ">>$ROOT_PATH/query/query_all_ids_gs.txt" ) or die "cannot create file query_all_ids_gs.txt!";
			print f_query "$logTime\t$player_nick\t$ids_list\t$nick ($userhost) (PRIV)\n";
			close( f_query );
		}else{
			$conn->privmsg( $event->{nick}, "No records in database for $player_nick" );
		}
	}
	#### END of ALL IDs for NICK from GameSpy

	#### NICKS for IP request
	if ( $command =~ /^\!?[Nn][Ii][Cc][Kk][Ss]/ ) {
		my $ip_request = shift(@words);
		my @allowed = $gs->get_file_content( "allowed" );
		if ($nick ~~ @allowed) {
			my @nicks_list = $gs->get_nicks( $ip_request );
			my $nicks_list = join( "", @nicks_list );
			@nicks_list = split( /\n/, $nicks_list);
			$nicks_list = "";
			my @protected = $gs->get_file_content( "protected" );

			for my $cur_nick (@nicks_list) {
				if ($cur_nick ~~ @protected) {
				}else{
					$nicks_list = $nicks_list . " " . $cur_nick . ",";
				}
			}

			$conn->privmsg( $event->{nick}, $ip_request . ": " . $nicks_list );
			my $logTime = $gs->get_time();
			open( f_query_nicks, ">>$ROOT_PATH/query/query_nicks.txt" ) or die "cannot create file query_nicks.txt!";
			print f_query_nicks "$logTime\t$ip_request\t$nicks_list\t$nick ($userhost) (PRIV)\n";
			close( f_query_nicks );
		}else{
			$conn->privmsg( $conn->{channel}, $nick . ", you are not allowed to query nicks of other players" );
		}
	}
	#### END of NICKS for IP request

	#### request to add NICK into ignored.txt file
	if ( $command =~ /^\!?[Aa][Dd][Dd][Tt][Oo]/ ) {
		my $nick4add = shift( @words );
		my $file2add = shift( @words ) || "ignored";
		my @admins = $gs->get_file_content( "admins" );
		if ( $nick ~~ @admins ) {
			$gs->add_file_content( $file2add, $nick4add );
			$conn->privmsg( $event->{nick}, $nick4add . " added to " . $file2add ." list" );
		}else{
			$conn->privmsg( $conn->{channel}, $nick . ", you are not allowed to add nicks into " . $file2add . " list" );
		}
	}
	#### END of request to add NICK into ignored.txt file

	#### request to STOP running
	if ( $command =~ /^\!?[Dd][Ii][Ee]/ ) {
		my @admins = $gs->get_file_content( "admins" );
		if ( $nick ~~ @admins ) {
			$conn->privmsg( $conn->{channel}, "I'm going for reboot now!" );
			$conn->privmsg( $event->{nick}, "System STOP now." );
			exit;
		}
	}
	#### END of request to STOP running

}


sub get_quote {
	open( f_quotes, $file_quotes ) or die("Quotes file does not exist");
	my @quotes = (<f_quotes>);
	my $quotes_count = scalar(@quotes);
	my $quote_rand = int( rand( $quotes_count ) );
	my $quote_line = $quotes[$quote_rand];
	close( f_quotes );
	return $quote_line;
}


sub get_punish {
	open( f_punish, $file_punish ) or die("punish file does not exist");
	my @punish = (<f_punish>);
	my $punish_count = scalar(@punish);
	my $punish_rand = int( rand( $punish_count ) );
	my $punish_line = $punish[$punish_rand];
	close( f_punish );
	return $punish_line;
}


# Reconnect to the server when we die.
sub on_disconnect {
	my ($self, $event) = @_;
	print "Disconnected from ", $event->from(), " (", ($event->args())[0], "). Attempting to reconnect ... \n";
	$self->connect();
}


sub restart_303 {
	$irc->start();
}

# add event handlers for join and part events
$conn->add_handler('join', \&on_join);
$conn->add_handler('part', \&on_part);
$conn->add_handler('public', \&on_public);
$conn->add_handler('msg', \&on_msg);
$conn->add_global_handler('disconnect', \&on_disconnect);

# The end of MOTD (message of the day), numbered 376 signifies we've connect
$conn->add_handler('303', \&restart_303);
$conn->add_handler('376', \&on_connect);

# start IRC
$irc->start();
