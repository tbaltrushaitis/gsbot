package sUtils;

sub new {
  my $pkg = shift;
  return bless {}, $pkg;
}

###########################################################
# Written by Guy Malachi http://guymal.com
# 18 August, 2002
###########################################################

# This function generates random strings of a given length
sub generate_random_string {
  my $length_of_randomstring=shift;# the length of
  # the random string to generate
  my @chars=('a'..'z','A'..'Z','0'..'9','_');
  my $random_string;
  foreach (1..$length_of_randomstring) {
    # rand @chars will generate a random
    # number between 0 and scalar @chars
    $random_string .= $chars[rand @chars];
  }

  return $random_string;
}

1;
