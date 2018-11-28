package gsUtils;

use strict;
use Switch;
use vars qw($ua $wp);

my $ROOT_PATH = "/home/ubuntu/gsbot/gsbot.server";


sub new {
  my $pkg = shift;
  return bless {}, $pkg;
}


sub get_ip {
  my ( $unused, $player_nick ) = @_;
  my $ip = "0.0.0.0";
  system "$ROOT_PATH/sh/get_player_ip.sh '$player_nick'";
  my $file_with_ip = "$ROOT_PATH/sh/player_last_ip.txt";
  open( f_ip, $file_with_ip );
  my @player_ip = (<f_ip>);
  $ip = $player_ip[0];
  chomp( $ip );
  close( f_ip );
  return $ip;
}


sub get_ip_all {
  my ( $unused, $player_nick_req ) = @_;
  my @ip_all = ("0.0.0.0");
  system "$ROOT_PATH/sh/get_player_ip_all.sh '$player_nick_req'";
  my $file_with_ip_all = "$ROOT_PATH/nicks/$player_nick_req.txt";
  open( f_ip_all, $file_with_ip_all );
  @ip_all = (<f_ip_all>);
  close( f_ip_all );
  return @ip_all;
}


sub get_id_all {
  my ( $unused, $player_nick_req ) = @_;
  my @id_all = ("0");
  system "$ROOT_PATH/sh/get_player_id_all.sh '$player_nick_req'";
  my $file_with_id_all = "$ROOT_PATH/nicks_id/$player_nick_req.txt";
  open( f_id_all, $file_with_id_all );
  @id_all = (<f_id_all>);
  close( f_id_all );
  return @id_all;
}


sub get_id_all_gs {
  my ( $unused, $player_nick_req ) = @_;
  my @id_all = ("0");
  system "$ROOT_PATH/sh/get_player_id_all_gs.sh '$player_nick_req'";
  my $file_with_id_all = "$ROOT_PATH/nicks_id/$player_nick_req.gs.txt";
  open( f_id_all, $file_with_id_all );
  @id_all = (<f_id_all>);
  close( f_id_all );
  return @id_all;
}


sub get_ip_for_id {
  my ( $unused, $player_id_req ) = @_;
  my @ip_all = ("0.0.0.0");
  system "$ROOT_PATH/sh/get_player_ip_for_id.sh '$player_id_req'";
  my $file_with_ip_all = "$ROOT_PATH/id/$player_id_req.txt";
  open( f_ip_all, $file_with_ip_all );
  @ip_all = (<f_ip_all>);
  close( f_ip_all );
  return @ip_all;
}


sub get_nicks {
  my ( $unused, $player_ip ) = @_;
  system "$ROOT_PATH/sh/get_players_for_ip.sh '$player_ip'";
  sleep 0.1;
  my $file_with_nicks = "$ROOT_PATH/ip/" . $player_ip . ".txt";
  open( f_ip_nicks, $file_with_nicks );
  my @ip_nicks = (<f_ip_nicks>);
  close( f_ip_nicks );
  return @ip_nicks;
}


sub get_id {
  my ( $unused, $player_nick ) = @_;
  my $id = "0";
  system "$ROOT_PATH/sh/get_player_id.sh '$player_nick'";
  my $file_with_id = "$ROOT_PATH/sh/player_last_id.txt";
  open( f_id, $file_with_id );
  my @player_id = (<f_id>);
  $id = $player_id[0];
  chomp( $id );
  close( f_id );
  return $id;
}


sub get_last_visit {
  my ( $unused, $player_nick ) = @_;
  my $visit = "";
  system "$ROOT_PATH/sh/get_player_last_visit.sh '$player_nick'";
  my $file_with_last_visit = "$ROOT_PATH/sh/player_last_visit.txt";
  open( f_visit, $file_with_last_visit );
  my @visit = (<f_visit>);
  $visit = $visit[0];
  chomp( $visit );
  close( f_visit );
  return $visit;
}


sub get_names {
  use IO::Socket;
  my ( $self, $peer_addr ) = @_;
  my $sock = IO::Socket::INET->new(
    PeerAddr => $peer_addr || '69.10.30.243',
    PeerPort => 6667,
    Proto => 'tcp'
  ) or die "could not make the connection";

  my $rand_nick = "asker_" . int(rand(1000));
  my $ret_str = "";

  print $sock "NICK " . $rand_nick . "\nUSER " . $rand_nick . " 0 * :just a " . $rand_nick . "\n";
  sleep(1);
  print $sock "JOIN #GSP!cossacks\n";
  while (my $line = <$sock>) {
    my ($command, $text) = split(/ :/, $line);   # $text is the stuff from the ping or the text from the server

    if ( $command eq 'PING') {
      # while there is a line break - many different ways to do this
      while ( (index($text,"\r") >= 0) || (index($text,"\n") >= 0) ){ chop($text); }
      print $sock "PONG $text\n";
      print "PONG $text\n";
      next;
    }

    if ($line =~ /(353)/i) {
      my ($line_info, $nicks_line) = split( / :/, $line);
      $ret_str = $ret_str . $nicks_line;
    }

    if($line =~ /(366)/i) {
      last;
    }
  }

  close($sock);
  return $ret_str ;
}

#------------------------------------------------------------------------------#

sub get_time {
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();

  $month = $month +1;
  if ( length($second) == 1 ) {
    $second = "0" . $second;
  }
  if ( length($minute) == 1 ) {
    $minute = "0" . $minute;
  }
  if ( length($hour) == 1 ) {
    $hour = "0" . $hour;
  }
  if ( length($month) == 1 ) {
    $month = "0" . $month;
  }
  if ( length($dayOfMonth) == 1 ) {
    $dayOfMonth = "0" . $dayOfMonth;
  }

  my $year = 1900 + $yearOffset;
  my $theTimeFull = "$year-$month-$dayOfMonth $hour:$minute:$second";
  my $theTime = "$hour:$minute:$second";

  return $theTimeFull;
}
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
sub get_date {
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();

  $month = $month +1;
  if ( length($month) == 1 ) {
    $month = "0" . $month;
  }
  if ( length($dayOfMonth) == 1 ) {
    $dayOfMonth = "0" . $dayOfMonth;
  }

  my $year = 1900 + $yearOffset;
  my $theDate = "$year-$month-$dayOfMonth";

  return $theDate;
}
#------------------------------------------------------------------------------#

sub get_full_name {
  my ( $unused, $player_nick ) = @_;
  print "received: " . $player_nick . "\n";

  my $sock = IO::Socket::INET->new(
    PeerAddr => 'irc.gamespy.com',
    PeerPort => 6667,
    Proto => 'tcp' ) or die "could not make the connection";

  my $ret_str = "";

  print $sock "NICK bot_asker\nUSER bot_asker 0 * :just a bot\n";
  print $sock "JOIN #GSP!cossacks\n";

  while (my $line = <$sock>) {
    print $line;

    my ($command, $text) = split(/ :/, $line); # $text is the stuff from the ping or the text from the server

    if ($command eq 'PING'){
      # while there is a line break - many different ways to do this
      while ( (index($text,"\r") >= 0) || (index($text,"\n") >= 0) ){ chop($text); }
      print $sock "PONG $text\n";
      next;
    }
    # done with ping handling

    if ($line =~ /(366)/i) {
      print "\n\nPRIVMSG $player_nick\n\n";
      last;
    }

  }
  return $ret_str ;
}

sub get_banned_list { # global ban list
  open( f_banned_list, "$ROOT_PATH/conf/banned.txt" );
  my @banned_nicks = (<f_banned_list>);
  close( f_banned_list );
  my $banned_nicks = join( "", @banned_nicks );
  @banned_nicks = split( /\n/, $banned_nicks);
  return @banned_nicks;
}

sub get_flooders {
  open( f_flooders, "$ROOT_PATH/conf/flooders.txt" );
  my @flooders = (<f_flooders>);
  close( f_flooders );
  my $flooders = join( "", @flooders );
  @flooders = split( /\n/, $flooders);
  return @flooders;
}

sub get_allowed {
  open( f_allowed, "$ROOT_PATH/conf/allowed.txt" );
  my @allowed = (<f_allowed>);
  close( f_allowed );
  my $allowed = join( "", @allowed );
  @allowed = split( /\n/, $allowed );
  return @allowed;
}

sub get_admins {
  open( f_admins, "$ROOT_PATH/conf/admins.txt" );
  my @admins = (<f_admins>);
  close( f_admins );
  my $admins = join( "", @admins );
  @admins = split( /\n/, $admins );
  return @admins;
}

sub get_protected {
  open( f_protected, "$ROOT_PATH/conf/protected.txt" );
  my @protected = (<f_protected>);
  close( f_protected );
  my $protected = join( "", @protected );
  @protected = split( /\n/, $protected );
  return @protected;
}

sub get_protected_id {
  open( f_protected_id, "$ROOT_PATH/conf/protected_id.txt" );
  my @protected_id = (<f_protected_id>);
  close( f_protected_id );
  my $protected_id = join( "", @protected_id );
  @protected_id = split( /\n/, $protected_id );
  return @protected_id;
}

sub get_victims {
  open( f_victims, "$ROOT_PATH/conf/victims.txt" );
  my @victims = (<f_victims>);
  close( f_victims );
  my $victims = join( "", @victims );
  @victims = split( /\n/, $victims );
  return @victims;
}

sub get_rude {
  open( f_rude, "$ROOT_PATH/conf/rude.txt" );
  my @rude = (<f_rude>);
  close( f_rude );
  my $rude = join( "", @rude );
  @rude = split( /\n/, $rude );
  return @rude;
}

sub get_ignored {
  open( f_ignored, "$ROOT_PATH/conf/ignored.txt" );
  my @ignored = (<f_ignored>);
  close( f_ignored );
  my $ignored = join( "", @ignored );
  @ignored = split( /\n/, $ignored );
  return @ignored;
}

sub get_file_content {
  my ( $self, $file4open ) = @_;
  $file4open = "$ROOT_PATH/conf/" . $file4open . ".txt" if ( $file4open !~ "/" );
  open( f_file_cont, $file4open );
  my @file_cont = (<f_file_cont>);
  close( f_file_cont );
  my $file_cont = join( "", @file_cont );
  @file_cont = split( /\n/, $file_cont);
  return @file_cont;
}

sub file_to_array {
  my ( $self, $file4open ) = @_;
  open( f_file_cont, $file4open );
  my @file_cont = (<f_file_cont>);
  close( f_file_cont );
  my $file_cont = join( "", @file_cont );
  @file_cont = split( /\n/, $file_cont);
  return @file_cont;
}

sub set_ban {
  my ( $unused, $player_nick ) = @_;
}

sub add_file_content {
  my ( $self, $file4open, $text ) = @_;
  $file4open = "$ROOT_PATH/conf/" . $file4open . ".txt" if ( $file4open !~ "/" );
  open( f_file_cont, ">>" . $file4open );
  print f_file_cont "$text\n";
  close( f_file_cont );
  return ;
}

sub kick_from_gs {
  use IO::Socket;
  use String::Random;
  my ( $self, $nick ) = @_;

  my $sock = IO::Socket::INET->new(
    PeerAddr => '69.10.30.243',
    PeerPort => 6667,
    Proto => 'tcp' ) or die "could not make the connection";

  my $rand_generator = new String::Random;
  my $rand_nick = $rand_generator->randpattern("C");

  print $sock "NICK " . $rand_nick . "\nUSER " . $rand_nick . " 0 * :just a " . $rand_nick . "\n";
  sleep(2);
  print $sock "JOIN #GSP!cossacks\n";

  while (my $line = <$sock>) {
    my ($command, $text) = split(/ :/, $line); # $text is the stuff from the ping or the text from the server
    if ( $command eq 'PING' ){
      # while there is a line break - many different ways to do this
      while ( (index($text,"\r") >= 0) || (index($text,"\n") >= 0) ){ chop($text); }
      print $sock "PONG $text\n";
      print "PONG $text\n";
      next;
    }
    #done with ping handling

    print $sock "PRIVMSG $nick :" . ".                                                                                                                                                                                                                                                                                                                                                                                                            ." . "\r\n";
    sleep(0.5);
    print $sock "PRIVMSG $nick :" . ".                                                                                                                                                                                                                                                                                                                                                                                                            ." . "\r\n";
    sleep(0.5);
    print $sock "PRIVMSG $nick :" . ".                                                                                                                                                                                                                                                                                                                                                                                                            ." . "\r\n";
    print "\n\n $rand_nick KICKED $nick \n";
    last;
  }
  close($sock);
}
