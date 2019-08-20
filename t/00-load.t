#!perl -T

# Title               : 00-load.t
# Last modified date  : 23.07.2018
# Author              : jumation.com. Based on test script included with
#                       Crypt::Juniper Perl module written by Kevin Brintnall.
# Description         : Script tries to use the Crypt::Juniper, Net::OpenSSH
#                       and Net::SSH::Expect modules which are needed in next
#                       test scripts.
# Options             : None.
# Notes               : None.

use Test::More tests => 3;

BEGIN {
	use_ok( 'Crypt::Juniper' );
	use_ok( 'Net::OpenSSH' );
	use_ok( 'Net::SSH::Expect' );
}

diag( "Necessary modules for testing crypt.slax were found." );
