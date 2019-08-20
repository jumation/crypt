#!/usr/bin/perl

# Title               : invalid_interactive.t
# Last modified date  : 22.07.2018
# Author              : jumation.com. Based on test script included with
#                       Crypt::Juniper Perl module written by Kevin Brintnall.
# Description         : Script sends list of invalid crypts to crypt.slax
#                       script using Net::SSH::Expect module in interactive
#                       mode, i.e crypt.slax is started with "op crypt" command.
# Options             : None. Router hostname and username are defined in
#                       variables.
# Notes               : For Net::SSH::Expect module, the key-based
#                       authentication is used.

use strict;
use Test::More;
use Net::SSH::Expect;

my $hostname="vmx1";
my $username="martin";

my @invalid = (undef, qw[ $9jadsfdf $9$asd $9$asdf*
						$9$dLw2ajHmFnCZUnCtuEhVwYY
						$9$dLw2ajHmFnCZUnCtuEhVw ]);

plan tests => scalar @invalid;

# Key-based authentication is used.
# SSH connection is open until close().
my $ssh = Net::SSH::Expect->new (
	host => $hostname,
	user => $username,
	raw_pty => 1
);
$ssh->run_ssh() or die "SSH process couldn't start: $!";
$ssh->read_all(2) =~ />\s*\z/ or die "No Junos CLI";


for my $crypt (@invalid)
{
	my $print = defined $crypt ? "'$crypt'" : "'undef'";

	$ssh->send('op crypt');
	$ssh->waitfor('mode: \z', 1) or die;
	$ssh->send('1');
	$ssh->waitfor('secret: \z', 1) or die;

	# If $crypt is not defined, then send a newline.
	if ( defined($crypt) ) {
		$ssh->send($crypt);
	} else {
		$ssh->send("\n");
	}

	# As Junos CLI does not have "stty -echo" option, then command itself
	# is echoed back and needs to be removed from the input stream.
	$ssh->read_line();

	like($ssh->read_line(), qr/^error: /,
	"Invalid crypt $print returned error");

	sleep 1;
}

$ssh->close();
