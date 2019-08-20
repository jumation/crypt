#!/usr/bin/perl

# Title               : rand_interactive.t
# Last modified date  : 04.08.2018
# Author              : jumation.com. Based on test script included with
#                       Crypt::Juniper Perl module written by Kevin Brintnall.
# Description         : Script generates a random string of printable ASCII
#                       characters and then encrypts this string by logging
#                       into a Juniper device and executing crypt.slax script
#                       in interactive mode. The returned crypt is translated
#                       into plain-text by again logging into a Juniper device
#                       and using the "op crypt" command. Result is compared
#                       with initial randomly generated string. In addition,
#                       the same random string is encrypted by juniper_encrypt()
#                       function provided by Crypt::Juniper using the same salt
#                       as encryption operation before. Finally, the crypts from
#                       crypt.slax and juniper_encrypt() are compared.
# Options             : None. Router hostname and username are defined in
#                       variables.
# Notes               : For Net::SSH::Expect module, the key-based
#                       authentication is used.


our $NUM_TESTS; BEGIN { $NUM_TESTS = 2_000 };

use strict;
use Test::More tests => $NUM_TESTS;
use Net::SSH::Expect;
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

# Key-based authentication is used.
# SSH connection is open until close().
my $ssh = Net::SSH::Expect->new (
	host => $hostname,
	user => $username,
	timeout => 5,
	raw_pty => 1
);
$ssh->run_ssh() or die "SSH process couldn't start: $!";
$ssh->read_all(2) =~ />\s*\z/ or die "No Junos CLI";


for (1..$NUM_TESTS/2)
{
	my $plain = _gen();

	$ssh->send('op crypt');
	$ssh->waitfor('mode: \z') or die;
	$ssh->send('2');
	$ssh->waitfor('secret\(input is hidden\): \z') or die;
	$ssh->send($plain . "\n");
	$ssh->waitfor('salt\(leave empty for random\): \z') or die;
	$ssh->send("\n");

	my $encrypt_out;
	my $encrypt;
	while ( defined ($encrypt_out = $ssh->read_line()) ) {
		$encrypt = $encrypt_out if $encrypt_out =~ /^\$9\$/;
	}

	sleep 1;


	$ssh->send('op crypt');
	$ssh->waitfor('mode: \z') or die;
	$ssh->send('1');
	$ssh->waitfor('secret: \z') or die;
	$ssh->send($encrypt);

	# As Junos CLI does not have "stty -echo" option, then command itself
	# is echoed back and needs to be removed from the input stream.
	$ssh->read_line();

	my $decrypt = $ssh->read_line();

	is($decrypt, $plain, "Decrypt function of crypt script returned " .
	"correct plain-text: '$plain'");


	# Salt is a single character after $9$ prefix.
	my $salt = substr($encrypt, 3, 1);

	my $encrypt_f = juniper_encrypt($plain, $salt);

	# Random part of crypt is ignored.
	is( substr($encrypt, 3+1+$EXTRA{$salt}),
		substr($encrypt_f, 3+1+$EXTRA{$salt}),
		"Encrypt function of \"op crypt\" and " .
		"\"juniper_encrypt()\" both returned: '$encrypt'" );

	sleep 1;
}

$ssh->close();

sub _gen {

	my $length = int rand(127)+1;
	my $str = '';

	while ($length-- > 0)
	{
		# chr() returns an ASCII character from " "(dec 32) to "}"(dec 125).
		$str .= chr(ord(' ') + int rand (ord('~') - ord(' ')));
		$str = '    a';
	}

	# If the command output contains only spaces, then Junos cli
	# returns simply a newline.
	$str =~ s/^ +$/_/g;

	return $str;
}
