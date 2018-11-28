package mysqlUtils;

use Net::MySQL;

# CONFIG VARIABLES for MYSQL
my $mysql_host 			=	"/var/lib/mysql/mysql.sock";
my $mysql_database	=	"gamespy";
my $mysql_user 			= "collector";
my $mysql_pw 				=	"secret_password";

my $mysql_conn = Net::MySQL->new(
	# hostname => $mysql_host,   # Default use UNIX socket
	database => $mysql_database,
	user     => $mysql_user,
	password => $mysql_pw
);


sub new {
	my $pkg = shift;
	return $pkg;
}


sub mysql_log_join {

	my ( $self, $log_line )= @_ ;
	my $mysql_table = "gs_joins";

	my @arr_line_content = split( /\t/, $log_line );
	my @userhost = split( "@", $arr_line_content[3]);
	print $arr_line_content[0];

	my $mysql_insert_query = "insert into " . $mysql_table . " ";
	$mysql_insert_query .= " ( `join_time`, `nick`, `ip`, `ipgs`, `idgs`, `userhost` ) ";
	$mysql_insert_query .= " values ( ";
	$mysql_insert_query .= " STR_TO_DATE( '" . $arr_line_content[0] . "', '%Y-%m-%d %H:%i:%s' ) ";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $arr_line_content[1] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $arr_line_content[2] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $userhost[0] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $userhost[1] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $arr_line_content[3] . "'";
	$mysql_insert_query .= " );";

	$mysql_conn->query( $mysql_insert_query );

}


sub mysql_log_part {

	my ( $self, $log_line )= @_ ;
	my $mysql_table = "gs_parts_test";

	my @arr_line_content = split( /\t/, $log_line );
	my @userhost = split( "@", $arr_line_content[3]);
	print $arr_line_content[0];

	my $mysql_insert_query = "insert into " . $mysql_table . " ";
	$mysql_insert_query .= " ( `act_time`, `nick`, `ip`, `ipgs`, `idgs`, `userhost` ) ";
	$mysql_insert_query .= " values ( ";
	$mysql_insert_query .= " STR_TO_DATE( '" . $arr_line_content[0] . "', '%Y-%m-%d %H:%i:%s' ) ";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $arr_line_content[1] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $arr_line_content[2] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $userhost[0] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $userhost[1] . "'";
	$mysql_insert_query .= ",";
	$mysql_insert_query .= "'" . $arr_line_content[3] . "'";
	$mysql_insert_query .= " );";

	$mysql_conn->query( $mysql_insert_query );

}

1;
