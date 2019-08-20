#!/usr/bin/perl

# Title               : invalid_non-interactive.t
# Last modified date  : 20.07.2018
# Author              : jumation.com. Based on test script included with
#                       Crypt::Juniper Perl module written by Kevin Brintnall.
# Description         : Script sends list of invalid crypts to crypt.slax
#                       script using Net::SSH::Expect module.
# Options             : None. Router hostname and username are defined in
#                       variables.
# Notes               : Net::SSH::Expect is used in order to avoid Junos CLI
#                       quirks in SSH protocol command mode.
#                       For Net::SSH::Expect module, the key-based
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

for my $crypt (@invalid)
{
	my $print = defined $crypt ? "'$crypt'" : "'undef'";

	my $crypt_output = $ssh->exec('op crypt decrypt ' . $crypt);

	like($crypt_output, qr/\nerror: |\nsyntax error/,
	"Invalid crypt $print returned error");

}

$ssh->close();
