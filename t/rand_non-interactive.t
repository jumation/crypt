#!/usr/bin/perl

# Title               : rand_non-interactive.t
# Last modified date  : 04.08.2018
# Author              : jumation.com. Based on test script included with
#                       Crypt::Juniper Perl module written by Kevin Brintnall.
# Description         : Script generates a random string of printable ASCII
#                       characters and then encrypts this string by logging
#                       into a Juniper device and executing "op crypt encrypt
#                       <random_str>" command. The returned crypt is
#                       translated into plain-text by logging into a Juniper
#                       device and executing "op crypt decrypt <crypt>" and
#                       compared with initial randomly generated string.
#                       In addition, the same random string is encrypted by
#                       juniper_encrypt() function provided by Crypt::Juniper
#                       using the same salt as "op crypt encrypt <random_str>".
#                       Finally, the crypts from "op crypt encrypt <random_str>"
#                       and juniper_encrypt() are compared.
# Options             : None. Router hostname and username are defined in
#                       variables.
# Notes               : In case of non-interactive SSH mode, the ";" character
#                       breaks the the command on Junos CLI if it is preceded by
#                       escaped double-quote character. One can test this with
#                       "ssh box 'set cli directory "a\"b;c"'". There is no such
#                       limitation in interactive mode. That is the reason why
#                       randomly generated string is sent to Juniper device
#                       using Net::SSH::Expect. In addition, there are some
#                       invalid characters or character combinations for Junos
#                       CLI. For example "'" is not supported because of Junos
#                       bug and "\" can not be the last character of the string.
#                       That is the reason of substitutions before passing the
#                       random string to Net:SSH:Expect.
#                       For Net::SSH::Expect and Net::OpenSSH modules, the
#                       key-based authentication is used.


our $NUM_TESTS; BEGIN { $NUM_TESTS = 2_000 };

use strict;
use Test::More tests => $NUM_TESTS;
use Net::SSH::Expect;
use Net::OpenSSH;
use Crypt::Juniper;


my %EXTRA;

my @FAMILY = qw[ QzF3n6/9CAtpu0O B1IREhcSyrleKvMW8LXx
7N-dVbwsY2g4oaJZGUDj iHkq.mPf5T ];

for my $fam (0..$#FAMILY)
{
	for my $c (split //, $FAMILY[$fam])
	{
		$EXTRA{$c} = (3-$fam);
	}
}

my $hostname="vmx1";
my $username="martin";

my $ssh_expect = Net::SSH::Expect->new (
	host => $hostname,
	user => $username,
	timeout => 2,
	raw_pty => 1
);
$ssh_expect->run_ssh() or die "SSH process couldn't start: $!";

my $ssh = Net::OpenSSH->new($username . '@' . $hostname,timeout => 30);


for (1..$NUM_TESTS/2)
{
	my $plain = _gen();
	print "xxx" . $plain . "yyy" . "\n";

	$ssh_expect->send('op crypt encrypt "' . $plain . '"');
	my $encrypt_out;
	my $encrypt;
	while ( defined ($encrypt_out = $ssh_expect->read_line()) ) {
		$encrypt = $encrypt_out if $encrypt_out =~ /^\$9\$/;
	}

	sleep 1;

	my $decrypt_out = $ssh->pipe_out("op crypt decrypt " . $encrypt);
	my $decrypt = <$decrypt_out>;
	$decrypt =~ s/\n//;

	# Put back the backslash preceding the double-quote. Those were removed
	# by Junos CLI.
	$decrypt =~ s/"/\\"/g;

	is($decrypt, $plain, "\"op crypt decrypt <crypt>\" returned " .
	"correct plain-text: '$plain'");


	# Salt is a single character after $9$ prefix.
	my $salt = substr($encrypt, 3, 1);


	# Remove the escape character for juniper_encrypt().
	$plain =~ s/\\"/"/g;
	my $encrypt_f = juniper_encrypt($plain, $salt);


	is( substr($encrypt, 3+1+$EXTRA{$salt}),
		substr($encrypt_f, 3+1+$EXTRA{$salt}),
		"\"op crypt encrypt\" and " .
		"\"juniper_encrypt()\" both returned: '$encrypt'" );

	sleep 1;
}

$ssh_expect->close();


sub _gen {

	my $length = int rand(127)+1;
	my $str = '';

	while ($length-- > 0)
	{
		# chr() returns an ASCII character from " "(dec 32) to "}"(dec 125).
		$str .= chr(ord(' ') + int rand (ord('~') - ord(' ')));
	}

	# Substitutions below are needed to comply with Junos CLI.
	$str =~ s/\\+$/_/;
	$str =~ s/\\+"/"/g;
	$str =~ s/'/_/g;
	$str =~ s/"/\\"/g;
	$str =~ s/^ +$/_/g;

	# If the command output contains only spaces, then Junos cli
	# returns simply a newline.
	$str =~ s/^ +$/_/g;

	return $str;
}
