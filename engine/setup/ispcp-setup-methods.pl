#!/usr/bin/perl

# ispCP ω (OMEGA) a Virtual Hosting Control Panel
# Copyright (C) 2006-2010 by isp Control Panel - http://ispcp.net
#
# Version: $Id$
#
# The contents of this file are subject to the Mozilla Public License
# Version 1.1 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is "ispCP ω (OMEGA) a Virtual Hosting Control Panel".
#
# The Initial Developer of the Original Code is ispCP Team.
# Portions created by Initial Developer are Copyright (C) 2006-2010 by
# isp Control Panel. All Rights Reserved.
#
# The ispCP ω Home Page is:
#
#    http://isp-control.net
#

# Note to dev:
#
# It's important for the recovery process that all the subroutines defined here
# are idempotent. That wants mean that if a subroutine is called again and
# again, the final result should be the same. For example, if an error occurs
# and the program ends, and then the script is run again, the final result
# should be identical as if the script was run once.

use strict;
use warnings;
use version 0.74;
#~ use DateTime;
use DateTime::TimeZone;

# Hide the 'used only once: possible typo' warnings
no warnings 'once';

END {
	@main::el = reverse(@main::el);
	dump_el(\@main::el, $main::logfile);
}

################################################################################
##                              Ask subroutines                                #
################################################################################

################################################################################
# Ask for system hostname
#
# @return int 0 on success, -1 otherwise
#
sub ask_hostname {

	push_el(\@main::el, 'ask_hostname()', 'Starting...');

	my ($rs, $hostname) = get_sys_hostname();
	return -1 if ($rs != 0);

	print STDOUT "\n\tPlease enter a fully qualified hostname. [$hostname]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '') {
		$rdata = $hostname;
	}

	if ($rdata =~ /^(((([\w][\w-]{0,253}){0,1}[\w])\.)*)([\w][\w-]{0,253}[\w])\.([a-zA-Z]{2,6})$/) {
		if ($rdata =~ /^([\w][\w-]{0,253}[\w])\.([a-zA-Z]{2,6})$/) {
			my $wmsg = colored( ['bold yellow'], "\n\t[WARNING] ") .
				"$rdata is not a \"fully qualified hostname\". \n\t" .
				"Be aware you cannot use this domain for websites.\n";

			print STDOUT $wmsg;
		}

		$main::ua{'hostname'} = $rdata;
		$main::ua{'hostname_local'} = (($1) ? $1 : $4);
		$main::ua{'hostname_local'} =~ s/^([^.]+).+$/$1/;

	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"Hostname is not a valid domain name!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_hostname()', 'Ending...');

	0;
}

################################################################################
# Ask for Ip address
#
# @return int 0 on success, -1 otherwise. Exit on unrecoverable error
#
sub ask_eth {

	push_el(\@main::el, 'ask_eth()', 'Starting...');

	chomp(
		my $ipAddr =`$main::cfg{'CMD_IFCONFIG'}|$main::cfg{'CMD_GREP'} -v inet6|
		$main::cfg{'CMD_GREP'} inet|$main::cfg{'CMD_GREP'} -v 127.0.0.1|
		$main::cfg{'CMD_AWK'} '{print \$2}'|head -n 1|
		$main::cfg{'CMD_AWK'} -F: '{print \$NF}'`
	);

	if($?) {
		exit_msg(
			-1, colored(['bold red'], "[ERROR] ") . 'External command returned' .
			 " an error status: '$?' on network\n\tinterface cards lookup!\n"
		);
	}

	print STDOUT "\n\tPlease enter system network address. [$ipAddr]: ";
	chomp(my $rdata = readline \*STDIN);

	$main::ua{'eth_ip'} = (!defined $rdata || $rdata eq '') ? $ipAddr : $rdata;

	if(check_eth($main::ua{'eth_ip'})) {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"Ip address not valid!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_eth()', 'Ending...');

	0;
}

################################################################################
# Ask for ispCP Frontend vhost name
#
# @return int 0 on success, -1 otherwise
#
sub ask_vhost {

	push_el(\@main::el, 'ask_vhost()', 'Starting...');

	# Standard IP with dot to binary data (expected by gethostbyaddr() as first
	# argument )
	my $iaddr = inet_aton($main::ua{'eth_ip'});
	my $addr = gethostbyaddr($iaddr, &AF_INET);

	# gethostbyaddr() returns a short host name with a suffix ( hostname.local )
	# if the host name ( for the current interface ) is not set in /etc/hosts
	# file. In this case, or if the returned value isn't FQHN, we use the long
	# host name who's provided by the system hostname command.
	if(!defined $addr or
		($addr =~/^[\w][\w-]{0,253}[\w]\.local$/) ||
		!($addr =~ /^([\w][\w-]{0,253}[\w])\.([\w][\w-]{0,253}[\w])\.([a-zA-Z]{2,6})$/) ) {

		$addr = $main::ua{'hostname'};
	}

	my $vhost = "admin.$addr";

	print STDOUT "\n\tPlease enter the domain name from where ispCP OMEGA will " .
		"be\n\treachable [$vhost]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '') {
		$main::ua{'admin_vhost'} = $vhost;
	} elsif ($rdata =~ /^([\w][\w-]{0,253}[\w]\.)*([\w][\w-]{0,253}[\w])\.([a-zA-Z]{2,6})$/) {
		$main::ua{'admin_vhost'} = $rdata;
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"Vhost name is not valid!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_vhost()', 'Ending...');

	0;
}

################################################################################
# Ask for SQL hostname
#
# @return void
# @todo: Add check on user input data
#
sub ask_db_host {

	push_el(\@main::el, 'ask_db_host()', 'Starting...');

	print STDOUT "\n\tPlease enter SQL server host. [localhost]: ";
	chomp(my $rdata = readline \*STDIN);

	$main::ua{'db_host'} = (!defined($rdata) || $rdata eq '')
		? 'localhost' : $rdata;

	push_el(\@main::el, 'ask_db_host()', 'Ending...');
}

################################################################################
# Ask for ispCP database name
#
# @return void
# @todo: Add check on user input data
#
sub ask_db_name {

	push_el(\@main::el, 'ask_db_name()', 'Starting...');

	print STDOUT "\n\tPlease enter system SQL database. [ispcp]: ";
	chomp(my $rdata = readline \*STDIN);

	$main::ua{'db_name'} = (!defined($rdata) || $rdata eq '')
		? 'ispcp' : $rdata;

	push_el(\@main::el, 'ask_db_name()', 'Ending...');
}

################################################################################
# Ask for ispCP SQL user
#
# @return void
# @todo: Add check on user input data
#
sub ask_db_user {

	push_el(\@main::el, 'ask_db_user()', 'Starting...');

	print STDOUT "\n\tPlease enter system SQL user. [root]: ";
	chomp(my $rdata = readline \*STDIN);

	$main::ua{'db_user'} = (!defined($rdata) || $rdata eq '') ? 'root' : $rdata;

	push_el(\@main::el, 'ask_db_user()', 'Ending...');
}

################################################################################
# Ask for ispCP SQL password
#
# @return int 0 on success, -1 otherwise
#
sub ask_db_password {

	push_el(\@main::el, 'ask_db_password()', 'Starting...');

	my $pass1 = read_password("\n\tPlease enter system SQL password. [none]: ");

	if (!defined($pass1) || $pass1 eq '') {
		$main::ua{'db_password'} = '';
	} else {
		my $pass2 = read_password("\tPlease repeat system SQL password: ");

		if ($pass1 eq $pass2) {
			$main::ua{'db_password'} = $pass1;
		} else {
			print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
				"Passwords do not match!\n";

			return -1;
		}
	}

	push_el(\@main::el, 'ask_db_password()', 'Ending...');

	0;
}

################################################################################
# Ask for database Ftp user name
#
# @return int 0 on success, -1 otherwise
#
sub ask_db_ftp_user {

	push_el(\@main::el, 'ask_db_ftp_user()', 'Starting...');

	print STDOUT "\n\tPlease enter ispCP ftp SQL user. [vftp]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '') {
		$main::ua{'db_ftp_user'} = 'vftp';
	} elsif($rdata eq $main::ua{'db_user'}) {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"Ftp SQL user must not be identical to system SQL user!\n";

		return -1;
	} else {
		$main::ua{'db_ftp_user'} = $rdata;
	}

	push_el(\@main::el, 'ask_db_ftp_user()', 'Ending...');

	0;
}

################################################################################
# Ask for database Ftp user password
#
# @return int 0 on success, -1 otherwise
#
sub ask_db_ftp_password {

	push_el(\@main::el, 'ask_db_ftp_password()', 'Starting...');

	my ($rs, $pass1, $pass2, $dbPassword);

	$pass1 = read_password(
		"\n\tPlease enter ispCP ftp SQL user password. [auto generate]: "
	);

	if (!defined($pass1) || $pass1 eq '') {
		$dbPassword = gen_sys_rand_num(18);
		$dbPassword =~ s/('|"|`|#|;)//g;
		$main::ua{'db_ftp_password'} = $dbPassword;

		print STDOUT "\tispCP ftp SQL user password set to: $dbPassword\n";
	} else {
		$pass2 = read_password("\tPlease repeat ispCP ftp SQL user password: ");

		if ($pass1 eq $pass2) {
			$main::ua{'db_ftp_password'} = $pass1;
		} else {
			print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
				"Passwords do not match!\n";

			return -1;
		}
	}

	push_el(\@main::el, 'ask_db_ftp_password()', 'Ending...');

	0;
}

################################################################################
# Ask for ispCP Frontend first admin name
#
# @return void
# @todo: Add check on user input data
#
sub ask_admin {

	push_el(\@main::el, 'ask_admin()', 'Starting...');

	print STDOUT "\n\tPlease enter administrator login name. [admin]: ";
	chomp(my $rdata = readline \*STDIN);

	$main::ua{'admin'} = (!defined($rdata) || $rdata eq '') ? 'admin' : $rdata;

	push_el(\@main::el, 'ask_admin()', 'Ending...');
}

################################################################################
# Ask for ispCP Frontend first admin password
#
# @return int 0 on success, -1 otherwise
#
sub ask_admin_password {

	push_el(\@main::el, 'ask_admin_password()', 'Starting...');

	my $pass1 = read_password("\n\tPlease enter administrator password: ");

	if (!defined($pass1) || $pass1 eq '') {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			 "Password cannot be empty!\n";

		return -1;

	} else {
		if (length($pass1) < 5) {
			print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
				"Password too short!\n";

			return -1;
		}

		my $pass2 = read_password("\tPlease repeat administrator password: ");

		if ($pass1 =~ m/[a-zA-Z]/ && $pass1 =~ m/[0-9]/) {
			if ($pass1 eq $pass2) {
				$main::ua{'admin_password'} = $pass1;
			} else {
				print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
					"Passwords do not match!\n";

				return -1;
			}
		} else {
			print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
				"Passwords must contain at least digits and chars!\n";

			return -1;
		}
	}

	push_el(\@main::el, 'ask_admin_password()', 'Ending...');

	0;
}

################################################################################
# Ask for ispCP Frontend first admin email
#
# @return int 0 on success, -1 otherwise
#
sub ask_admin_email {

	push_el(\@main::el, 'ask_admin_email()', 'Starting...');

	print STDOUT "\n\tPlease enter administrator e-mail address: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '') {
		return -1;
	} else {
		# Note About the mail validation
		#
		# The RFC 2822 list quite a few characters that can be
		# used in an email address. However, in practice, the
		# mail client accept a limited version of this list.
		#
		# This regular expression allows the character list in
		# the local part of the email. Regarding the domain part,
		# the syntax is much more strict.
		#
		# Local part:
		#
		#  Validation is a limited version of the syntax allowed by the RFC 2822.
		#
		# Domain part:
		#
		# The syntax is much more strict:
		#
		# - The dash characters are forbidden in the beginning and end of line;
		# - The underscore is prohibited.
		# - It requires at least one second level domain in accordance with
		#   standards set by the RFC 952 and 1123.
		# - It allows only IPv4 domain literal
		if ($rdata =~
        	/^
				# Local part :
				# Optional segment for the local part
				(?:[-!#\$%&'*+\/=?^`{|}~\w]+\.)*
				# Segment required for the local part
				[-!#\$%&'*+\/=?^`{|}~\w]+
				# Separator
				@
				# Domain part
				(?:
				# As common form ( ex. local@domain.tld ) :
					(?:
						[a-z0-9](?:
						(?:[.](?!-))?[-a-z0-9]*[a-z0-9](?:(?:(?<!-)[.](?!-))?[-a-z0-9])*)?
						)+
						(?<!-)[.][a-z0-9]{2,6}
						|
						# As IPv4 domain literal ( ex. local@[192.168.0.130] )
						(?:\[(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\])
					)
			$/x
		) {
			$main::ua{'admin_email'} = $rdata;
		} else {
			print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
				"E-mail address not valid!\n";

			return -1;
		}
	}

	push_el(\@main::el, 'ask_admin_email()', 'Ending...');

	0;
}

################################################################################
# Ask for slave DNS
#
# @return int 0 on success, -1 otherwise
#
sub ask_second_dns {

	push_el(\@main::el, 'ask_second_dns()', 'Starting...');

	print STDOUT "\n\tIP of Secondary DNS. (optional) []: ";
	chomp(my $rdata = readline *STDIN);

	if (!defined($rdata) || $rdata eq '') {
		$main::ua{'secondary_dns'} = '';
	} elsif(check_eth($rdata) == 0) {
		$main::ua{'secondary_dns'} = $rdata;
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"No valid IP, please retry!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_second_dns()', 'Ending...');

	0;
}

################################################################################
# Ask for adding nameserver in the resolv.conf file
#
# @return int 0 on success, -1 otherwise
#
sub ask_resolver {

	push_el(\@main::el, 'ask_resolver()', 'Starting...');

	print STDOUT "\n\tDo you want allow the system resolver to use the " .
	"local nameserver\n\tsets by ispCP ? [Y/n]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '' || $rdata =~ /^(?:(y|yes)|(n|no))$/i) {
		$main::ua{'resolver'} = ! defined $2 ? 'yes' : 'no';
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"You entered an unrecognized value!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_resolver()', 'Ending...');

	0;
}

################################################################################
# Ask for MySQL prefix
#
# @return int 0 on success, -1 otherwise
#
sub ask_mysql_prefix {

	push_el(\@main::el, 'ask_mysql_prefix()', 'Starting...');

	print STDOUT "\n\tUse MySQL Prefix.\n\tPossible values: " .
		"[i]nfront, [b]ehind, [n]one. [none]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '' || $rdata eq 'none' || $rdata eq 'n') {
		$main::ua{'mysql_prefix'} = 'no';
		$main::ua{'mysql_prefix_type'} = '';
	} elsif ($rdata eq 'infront' || $rdata eq 'i') {
		$main::ua{'mysql_prefix'} = 'yes';
		$main::ua{'mysql_prefix_type'} = 'infront';
	} elsif ($rdata eq 'behind' || $rdata eq 'b') {
		$main::ua{'mysql_prefix'} = 'yes';
		$main::ua{'mysql_prefix_type'} = 'behind';
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
		"Not allowed Value, please retry!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_mysql_prefix()', 'Ending...');

	0;
}

################################################################################
# Ask for PhpMyAdmin control user name
#
# @return int 0 on success, -1 otherwise
#
sub ask_db_pma_user {

	push_el(\@main::el, 'ask_db_pma_user()', 'Starting...');

	if(defined &update_engine) {
		$main::ua{'db_user'} = $main::cfg{'DATABASE_USER'};
	}

	print STDOUT "\n\tPlease enter ispCP phpMyAdmin Control user. " .
		"[$main::cfg{'PMA_USER'}]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '') {
		$main::ua{'db_pma_user'} = $main::cfg{'PMA_USER'}
	} elsif($rdata eq $main::ua{'db_user'}) {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"PhpMyAdmin Control user must not be identical to system SQL user!\n";

		return 1;
	} elsif ($rdata eq $main::ua{'db_ftp_user'}) {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"PhpMyAdmin Control user must not be identical to ftp SQL user!\n";

		return -1;
	} else {
		$main::ua{'db_pma_user'} = $rdata;
	}

	push_el(\@main::el, 'ask_db_pma_user()', 'Ending...');

	0;
}

################################################################################
# Ask for PhpMyAdmin control user password
#
# @return int 0 on success, -1 otherwise
#
sub ask_db_pma_password {

	push_el(\@main::el, 'ask_db_pma_password()', 'Starting...');

	my $pass1 = read_password(
		"\n\tPlease enter ispCP PhpMyAdmin Control user password. " .
		"[auto generate]: "
	);

	if (!defined($pass1) || $pass1 eq '') {
		my $dbPassword = gen_sys_rand_num(18);
		$dbPassword =~ s/('|"|`|#|;)//g;
		$main::ua{'db_pma_password'} = $dbPassword;

		print STDOUT "\tPhpMyAdmin Control user password set to: $dbPassword\n";
	} else {
		my $pass2 = read_password(
			"\tPlease repeat ispCP PhpMyAdmin Control user password: "
		);

		if ($pass1 eq $pass2) {
			$main::ua{'db_pma_password'} = $pass1;
		} else {
			print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
				"Passwords do not match!\n";

			return -1;
		}
	}

	push_el(\@main::el, 'ask_db_pma_password()', 'Ending...');

	0;
}

################################################################################
# Ask for Apache fastCGI module (fcgid|fastcgi)
#
# @return int 0 on success, -1 otherwise
#
sub ask_fastcgi {

	push_el(\@main::el, 'ask_fastcgi()', 'Starting...');

	print STDOUT "\n\tFastCGI Version: [f]cgid or fast[c]gi. [fcgid]: ";
	chomp(my$rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '' || $rdata eq 'fcgid' || $rdata eq 'f') {
		$main::ua{'php_fastcgi'} = 'fcgid';
	} elsif ($rdata eq 'fastcgi' || $rdata eq 'c') {
		$main::ua{'php_fastcgi'} = 'fastcgi';
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"Only '[f]cgid' or 'fast[c]gi' are allowed!\n";

		return -1
	}

	push_el(\@main::el, 'ask_fastcgi()', 'Ending...');

	0;
}

################################################################################
# Ask for default timezone
#
# @return int 0 on success, -1 otherwise
#
sub ask_timezone {

	push_el(\@main::el, 'ask_timezone()', 'Starting...');

	# Get the user's default timezone
	my ($sec, $min, $hour, $mday, $mon, $year, @misc) = localtime;
	my $datetime  = DateTime->new(
		year => $year + 1900, month => $mon, day => $mday, hour => $hour,
		minute => $min, second => $sec, time_zone => 'local'
	);

	my $timezone_name = $datetime->time_zone_long_name();

	print STDOUT "\n\tServer's Timezone [$timezone_name]: ";
	chomp(my $rdata = readline \*STDIN);

	# Copy $timezone_name to $rdata if $rdata is empty
	if (!defined($rdata) || $rdata eq '') {
		$rdata = $timezone_name;
	}

	# DateTime::TimeZone::is_olson exits with die if the given data is not valid
	# eval catches the die() and keeps this program alive
	eval {
		my $timezone = DateTime::TimeZone->new(name => $rdata);
		$timezone->is_olson;
	};

	my $error = ($@) ? 1 : 0; # $@ contains the die() message

	if ($error == 1) {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"$rdata is not a valid Timezone!" .
			"\n\tThe continent and the city both must start with a capital " .
			"letter, e.g. Europe/London\n";

		return -1;
	} else {
		$main::ua{'php_timezone'} = $rdata;
	}

	push_el(\@main::el, 'ask_timezone()', 'Ending...');

	0;
}

################################################################################
# Ask for Awstats (On|Off)
#
# @return int 0 on success, -1 otherwise
#
sub ask_awstats_on {

	push_el(\@main::el, 'ask_awstats_on()', 'Starting...');

	print STDOUT "\n\tActivate AWStats. [no]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '' || $rdata eq 'no' || $rdata eq 'n') {
		$main::ua{'awstats_on'} = 'no';
	} elsif ($rdata eq 'yes' || $rdata eq 'y') {
		$main::ua{'awstats_on'} = 'yes';
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			"Only '(y)es' and '(n)o' are allowed!\n";

			return -1;
	}

	push_el(\@main::el, 'ask_awstats_on()', 'Ending...');

	0;
}

################################################################################
# Ask for Awstats usage (Dynamic|static)
#
# @return int 0 on success, -1 otherwise
#
sub ask_awstats_dyn {

	push_el(\@main::el, 'ask_awstats_dyn()', 'Starting...');

	print STDOUT "\n\tAWStats Mode:\n\tPossible values [d]ynamic and " .
		"[s]tatic. [dynamic]: ";
	chomp(my $rdata = readline \*STDIN);

	if (!defined($rdata) || $rdata eq '' || $rdata eq 'dynamic' || $rdata eq 'd') {

		$main::ua{'awstats_dyn'} = '0';
	} elsif ($rdata eq 'static' || $rdata eq 's') {
		$main::ua{'awstats_dyn'} = '1';
	} else {
		print STDOUT colored(['bold red'], "\n\t[ERROR] ") .
			 "Only '[d]ynamic' or '[s]tatic' are allowed!\n";

		return -1;
	}

	push_el(\@main::el, 'ask_awstats_dyn()', 'Ending...');

	0;
}

################################################################################
#                         Setup/Update subroutines                             #
################################################################################

################################################################################
# ispCP crontab file
#
# This subroutine built, store and install the ispCP crontab file
#
sub setup_crontab {

	push_el(\@main::el, 'setup_crontab()', 'Starting...');

	my ($rs, $cfgTpl);
	my $cfg = \$cfgTpl;

	my $awstats = '';
	my ($rkhunter, $chkrootkit);

	# Directories paths
	my $cfgDir = $main::cfg{'CONF_DIR'} . '/cron.d';
	my $bkpDir = $cfgDir . '/backup';
	my $wrkDir = $cfgDir . '/working';
	my $prodDir;

	# Determines production directory path
	if ($main::cfg{'ROOT_GROUP'} eq 'wheel') {
		$prodDir = '/usr/local/etc/ispcp/cron.d';
	} else {
		$prodDir = '/etc/cron.d';
	}

	# Saving the current production file if it exists
	if(-e  "$prodDir/ispcp") {
		$rs = sys_command_rs(
			"$main::cfg{'CMD_CP'} -p $prodDir/ispcp $bkpDir/ispcp." . time
		);
		return $rs if ($rs != 0);
	}

	## Building new configuration file

	# Loading the template from /etc/ispcp/cron.d/ispcp
	($rs, $cfgTpl) = get_file("$cfgDir/ispcp");
	return $rs if ($rs != 0);

	# Awstats cron task preparation (On|Off) according status in ispcp.conf
	if ($main::cfg{'AWSTATS_ACTIVE'} ne 'yes' || $main::cfg{'AWSTATS_MODE'} eq 1) {
		$awstats = '#';
	}

	# Search and cleaning path for rkhunter and chkrootkit programs
	($rkhunter = `which rkhunter`) =~ s/\s$//g;
	($chkrootkit = `which chkrootkit`) =~ s/\s$//g;

	# Tags preparation
	my %tags_hash = (
		'{LOG_DIR}' => $main::cfg{'LOG_DIR'},
		'{CONF_DIR}' => $main::cfg{'CONF_DIR'},
		'{QUOTA_ROOT_DIR}' => $main::cfg{'QUOTA_ROOT_DIR'},
		'{TRAFF_ROOT_DIR}' => $main::cfg{'TRAFF_ROOT_DIR'},
		'{TOOLS_ROOT_DIR}' => $main::cfg{'TOOLS_ROOT_DIR'},
		'{BACKUP_ROOT_DIR}' => $main::cfg{'BACKUP_ROOT_DIR'},
		'{AWSTATS_ROOT_DIR}' => $main::cfg{'AWSTATS_ROOT_DIR'},
		'{RKHUNTER_LOG}' => $main::cfg{'RKHUNTER_LOG'},
		'{CHKROOTKIT_LOG}' => $main::cfg{'CHKROOTKIT_LOG'},
		'{AWSTATS_ENGINE_DIR}' => $main::cfg{'AWSTATS_ENGINE_DIR'},
		'{AW-ENABLED}' => $awstats,
		'{RK-ENABLED}' => !length($rkhunter) ? '#' : '',
		'{RKHUNTER}' => $rkhunter,
		'{CR-ENABLED}' => !length($chkrootkit) ? '#' : '',
		'{CHKROOTKIT}' => $chkrootkit
	);

	# Building the new file
	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	## Storage and installation of new file

	# Store the new file in the working directory
	$rs = store_file(
		"$wrkDir/ispcp", $$cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command_rs("$main::cfg{'CMD_CP'} -fp $wrkDir/ispcp $prodDir/");
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_crontab()', 'Ending...');

	0;
}

################################################################################
# IspCP named main configuration setup / update
#
# This subroutine built, store and install the main named configuration file
#
# @return int 0 on success, other on failure
#
sub setup_named {

	push_el(\@main::el, 'setup_named()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'CMD_NAMED'} =~ /^no$/i);

	my ($rs, $rdata, $cfgTpl, $cfg);

	my $cfgDir = "$main::cfg{'CONF_DIR'}/bind";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	## Dedicated tasks for Setup and Update process

	# Setup:
	if(defined &setup_engine) {
		# Saving the system main configuration file
		if(-e $main::cfg{'BIND_CONF_FILE'} && !-e "$bkpDir/named.conf.system") {
			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $main::cfg{'BIND_CONF_FILE'} " .
				"$bkpDir/named.conf.system"
			);
			return $rs if ($rs != 0);
		}
	# Update:
	} else {
		# Saving the current main production file if it exists
		if(-e $main::cfg{'BIND_CONF_FILE'}) {
			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $main::cfg{'BIND_CONF_FILE'} " .
				"$bkpDir/named.conf." . time
			);
			return $rs if ($rs != 0);
		}
	}

	## Building of new configuration file

	# Loading the system main configuration file from
	# /etc/ispcp/bind/backup/named.conf.system if it exists
	if(-e "$bkpDir/named.conf.system") {
		($rs, $cfg) = get_file("$bkpDir/named.conf.system");
		return $rs if($rs != 0);

		# Adjusting the configuration if needed
		$cfg =~ s/listen-on ((.*) )?{ 127.0.0.1; };/listen-on $1 { any; };/;
		$cfg .= "\n";
	# eg. Centos, Fedora did not file by default
	} else {
		push_el(
			\@main::el, 'add_named_db_data()',
			"[WARNING] Can't find the parent file for named..."
		);

		$cfg = '';
	}

	# Loading the template from /etc/ispcp/bind/named.conf
	($rs, $cfgTpl) = get_file("$cfgDir/named.conf");
	return $rs if($rs != 0);

	# Building of new file
	$cfg .= $cfgTpl;

	## Storage and installation of new file

	# Storage of new file in the working directory
	$rs = store_file(
		"$wrkDir/named.conf", $cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	# Install the new file in the production directory
	$rs = sys_command_rs(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/named.conf " .
		"$main::cfg{'BIND_CONF_FILE'}"
	);
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_named()', 'Ending...');

	0;
}

################################################################################
# IspCP Apache fastCGI modules configuration
#
# This subroutine do the following tasks:
#  - Built, store and install all system php related configuration files
#  - Enable required modules and disable unused
#
# @return int 0 on success, other on failure
#
sub setup_fastcgi_modules {

	push_el(\@main::el, 'setup_php()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'CMD_HTTPD'} =~ /^no$/i);

	my ($rs, $cfgTpl);
	my $cfg = \$cfgTpl;

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/apache";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	## Dedicated tasks for the updates process

	# Update:
	if(defined &update_engine) {
		for (qw/fastcgi_ispcp.conf fastcgi_ispcp.load fcgid_ispcp.conf fcgid_ispcp.load/) {
			# Saving the current production file if it exists
			if(-e "$main::cfg{'APACHE_MODS_DIR'}/$_") {
				$rs = sys_command_rs(
					"$main::cfg{CMD_CP} -p $main::cfg{'APACHE_MODS_DIR'}/$_ " .
					"$bkpDir/$_." . time()
				);
				return $rs if($rs != 0);
			}
		}
	}

	## Building, storage and installation of new files

	# Tags preparation
	my %tags_hash = (
		fastcgi => {
			'{APACHE_SUEXEC_MIN_UID}' => $main::cfg{'APACHE_SUEXEC_MIN_UID'},
			'{APACHE_SUEXEC_MIN_GID}' => $main::cfg{'APACHE_SUEXEC_MIN_GID'},
			'{APACHE_SUEXEC_USER_PREF}' => $main::cfg{'APACHE_SUEXEC_USER_PREF'},
			'{PHP_STARTER_DIR}' => $main::cfg{'PHP_STARTER_DIR'},
			'{PHP_VERSION}' => $main::cfg{'PHP_VERSION'}
		},
		fcgid => {
			'{PHP_VERSION}' => $main::cfg{'PHP_VERSION'}
		}
	);

	# fastcgi_ispcp.conf / fcgid_ispcp.conf
	for (qw/fastcgi fcgid/) {
		# Loading the template from /etc/ispcp/apache
		($rs, $cfgTpl) = get_file("$cfgDir/${_}_ispcp.conf");
		return $rs if ($rs != 0);

		# Building the new configuration file
		($rs, $$cfg) = prep_tpl($tags_hash{$_}, $cfgTpl);
		return $rs if ($rs != 0);

		# Store the new file
		$rs = store_file(
			"$wrkDir/${_}_ispcp.conf", $$cfg, $main::cfg{'ROOT_USER'},
			$main::cfg{'ROOT_GROUP'}, 0644
		);
		return $rs if ($rs != 0);

		# Install the new file
		$rs = sys_command_rs(
			"$main::cfg{'CMD_CP'} -pf $wrkDir/${_}_ispcp.conf " .
			"$main::cfg{'APACHE_MODS_DIR'}/"
		);
		return $rs if($rs != 0);
	}

	# fastcgi_ispcp.load / fcgid_ispcp.load
	for (qw/fastcgi fcgid/) {
		next if(! -e "$main::cfg{'APACHE_MODS_DIR'}/$_.load");

		# Loading the system configuration file
		($rs, $$cfg) = get_file("$main::cfg{'APACHE_MODS_DIR'}/$_.load");
		return $rs if ($rs != 0);

		# Building the new configuration file
		$$cfg = "<IfModule !mod_$_.c>\n" . $$cfg . "</IfModule>\n";

		# Store the new file
		$rs = store_file(
			"$wrkDir/${_}_ispcp.load", $$cfg, $main::cfg{'ROOT_USER'},
			$main::cfg{'ROOT_GROUP'}, 0644
		);
		return $rs if ($rs != 0);

		# Install the new file
		$rs = sys_command_rs(
			"$main::cfg{'CMD_CP'} -pf $wrkDir/${_}_ispcp.load " .
			"$main::cfg{'APACHE_MODS_DIR'}/"
		);
		return $rs if($rs != 0);
	}

	## Enable required modules and disable unused

	# Debian like only:
	# Note for distributions maintainers:
	# For others distributions, you must use the a post-installation scripts
	if(-e '/usr/sbin/a2enmod' && -e '/usr/sbin/a2dismod' ) {
		# Disable php4/5 modules if enabled
		sys_command_rs("/usr/sbin/a2dismod php4 $main::rlogfile");
		sys_command_rs("/usr/sbin/a2dismod php5 $main::rlogfile");

		# Enable actions modules
		$rs = sys_command_rs("/usr/sbin/a2enmod actions $main::rlogfile");
		return $rs if($rs != 0);

		if(! -e '/etc/SuSE-release') {
			if ($main::cfg{'PHP_FASTCGI'} eq 'fastcgi') {
				# Ensures that the unused ispcp fcgid module loader is disabled
				$rs = sys_command_rs(
					"/usr/sbin/a2dismod fcgid_ispcp $main::rlogfile"
				);
				return $rs if($rs != 0);

				# Enable fastcgi module
				$rs = sys_command_rs(
					"/usr/sbin/a2enmod fastcgi_ispcp $main::rlogfile"
				);
				return $rs if($rs != 0);
			} else {
				# Ensures that the unused ispcp fastcgi ispcp module loader is
				# disabled
				$rs = sys_command_rs(
					"/usr/sbin/a2dismod fastcgi_ispcp $main::rlogfile"
				);
				return $rs if($rs != 0);

				# Enable ispcp fastcgi loader
				$rs = sys_command_rs(
					"/usr/sbin/a2enmod fcgid_ispcp $main::rlogfile"
				);
				return $rs if($rs != 0);
			}

			# Disable default  fastcgi/fcgid modules loaders to avoid conflicts
			# with ispcp loaders
			$rs = sys_command_rs("/usr/sbin/a2dismod fastcgi $main::rlogfile");
			return $rs if($rs != 0);

			$rs = sys_command_rs("/usr/sbin/a2dismod fcgid $main::rlogfile");
			return $rs if($rs != 0);
		}
	}

	push_el(\@main::el, 'setup_php()', 'Ending...');

	0;
}

################################################################################
# IspCP httpd main vhost setup / update
#
# This subroutine do the following tasks:
#  - Built, store and install ispCP main vhost configuration file
#  - Enable required modules (cgid, rewrite, suexec)
#
# @return int 0 on success, other on failure
#
sub setup_httpd_main_vhost {

	push_el(\@main::el, 'setup_httpd_main_vhost()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'CMD_HTTPD'} =~ /^no$/i);

	my ($rs, $cfgTpl);
	my $cfg = \$cfgTpl;

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/apache";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	# Saving the current production file if it exists
	if(-e "$main::cfg{'APACHE_SITES_DIR'}/ispcp.conf") {
		my $rs = sys_command_rs(
			"$main::cfg{'CMD_CP'} -p $main::cfg{'APACHE_SITES_DIR'}/" .
			"ispcp.conf $bkpDir/ispcp.conf.". time
		);
		return $rs if($rs != 0);
	}

	## Building, storage and installation of new file

	# Using alternative syntax for piped logs scripts when possible
	# The alternative syntax does not involve the Shell (from Apache 2.2.12)
	my $pipeSyntax = '|';

	if(`$main::cfg{'CMD_HTTPD'} -v` =~ m!Apache/([\d.]+)! &&
		version->new($1) >= version->new('2.2.12')) {
		$pipeSyntax .= '|';
	}

	# Loading the template from /etc/ispcp/apache/
	($rs, $cfgTpl) = get_file("$cfgDir/httpd.conf");
	return $rs if ($rs != 0);

	# Building the new file
	($rs, $$cfg) = prep_tpl(
		{
			'{APACHE_WWW_DIR}' => $main::cfg{'APACHE_WWW_DIR'},
			'{ROOT_DIR}' => $main::cfg{'ROOT_DIR'},
			'{PIPE}' => $pipeSyntax
		},
		$cfgTpl
	);
	return $rs if ($rs != 0);

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/ispcp.conf", $$cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command_rs(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/ispcp.conf " .
		"$main::cfg{'APACHE_SITES_DIR'}/"
	);
	return $rs if($rs != 0);

	## Enable required modules

	# Debian like only:
	# Note for distributions maintainers:
	# For others distributions, you must use the a post-installation scripts
	if(-e '/usr/sbin/a2enmod') {
		# We use cgid instead of cgi because we working with MPM.
		$rs = sys_command("/usr/sbin/a2enmod cgid $main::rlogfile");
		return $rs if($rs != 0);

		sys_command("/usr/sbin/a2enmod rewrite $main::rlogfile");
		return $rs if($rs != 0);

		sys_command("/usr/sbin/a2enmod suexec $main::rlogfile");
		return $rs if($rs != 0);
	}

	## Enable main vhost configuration file

	# Debian like only:
	# Note for distributions maintainers:
	# For others distributions, you must use the a post-installation scripts
	if(-e '/usr/sbin/a2ensite') {
		$rs = sys_command("/usr/sbin/a2ensite ispcp.conf $main::rlogfile");
		return $rs if($rs != 0);
	}

	push_el(\@main::el, 'setup_httpd_main_vhost()', 'Ending...');

	0;
}

################################################################################
# IspCP awstats vhost setup / update
#
# This subroutine do the following tasks:
#  - Built, store and install awstats vhost configuration file
#  - Change proxy module configuration file if it exits
#  - Enable proxy module
#
# @return int 0 on success, other on failure
#
sub setup_awstats_vhost {

	push_el(\@main::el, 'setup_awstats_vhost()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'AWSTATS_ACTIVE'} =~ /^no$/i);

	my ($rs, $path, $file, $cfgTpl);
	my $cfg = \$cfgTpl;

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/apache";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	## Dedicated tasks for Setup or Updates process

	# Setup:
	if(defined &setup_engine) {
		# Saving some system configuration files modified for ispCP
		for (
			map {/(.*\/)(.*)$/ && $1.':'.$2}
			'/etc/logrotate.d/apache',
			'/etc/logrotate.d/apache2',
			"$main::cfg{'APACHE_MODS_DIR'}/proxy.conf"
		) {
			($path, $file) = split /:/ ;
			next if(!-e $path.$file);

			if(!-e "$bkpDir/$file.system") {
				$rs = sys_command_rs(
					"$main::cfg{'CMD_CP'} -p $path$file $bkpDir/$file.system"
				);
				return $rs if($rs != 0);
			}
		}
	# Update:
	} else {
		my $timestamp = time;

		# Saving more production files if they exist
		for (
			map {/(.*\/)(.*)$/ && $1.':'.$2}
			'/etc/logrotate.d/apache',
			'/etc/logrotate.d/apache2',
			"$main::cfg{'APACHE_MODS_DIR'}/proxy.conf",
			"$main::cfg{'APACHE_SITES_DIR'}/01_awstats.conf"
		) {
			($path, $file)= split /:/;
			next if(!-e $path.$file);

			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $path$file $bkpDir/$file.$timestamp"
			);
			return $rs if($rs != 0);
		}
	}

	## Building, storage and installation of new file

	# Tags preparation
	my %tags_hash = (
		'{AWSTATS_ENGINE_DIR}' => $main::cfg{'AWSTATS_ENGINE_DIR'},
		'{AWSTATS_WEB_DIR}' => $main::cfg{'AWSTATS_WEB_DIR'}
	);

	# Loading the template from /etc/ispcp/apache
	($rs, $cfgTpl) = get_file("$cfgDir/01_awstats.conf");
	return $rs if($rs != 0);

	# Building the new file
	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/01_awstats.conf", $$cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command_rs(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/01_awstats.conf " .
		"$main::cfg{'APACHE_SITES_DIR'}/"
	);
	return $rs if($rs != 0);

	if ($main::cfg{'AWSTATS_ACTIVE'} eq 'yes' &&
		$main::cfg{'AWSTATS_MODE'} eq 0) {

		## Change the proxy module configuration file if it exists
		if(-e "$bkpDir/proxy.conf.system") {
			($rs, $$cfg) = get_file("$bkpDir/proxy.conf.system");
			return $rs if($rs != 0);

			# Replace the allowed hosts in mod_proxy if nedeed
			$$cfg =~ s/#Allow from .example.com/Allow from 127.0.0.1/gi;

			# Store the new file in working directory
			$rs = store_file(
				"$wrkDir/proxy.conf", $$cfg, $main::cfg{'ROOT_USER'},
				$main::cfg{'ROOT_GROUP'}, 0644
			);
			return $rs if ($rs != 0);

			# Install the new file in production directory
			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -pf $wrkDir/proxy.conf " .
				"$main::cfg{'APACHE_MODS_DIR'}/"
			);
			return $rs if($rs != 0);
		}

		# Enable required modules
		if(-e '/usr/sbin/a2enmod') {
			sys_command_rs("/usr/sbin/a2enmod proxy $main::rlogfile");
			sys_command_rs("/usr/sbin/a2enmod proxy_http $main::rlogfile");
		}

		## Enable awstats vhost

		if(-e '/usr/sbin/a2ensite') {
			sys_command("/usr/sbin/a2ensite 01_awstats.conf $main::rlogfile");
		}

		## Update Apache logrotate file

		# if the distribution provides an apache or apache2 log rotation file,
		# update it with the awstats information. If not, use the ispcp file.
		# log rotation should be never executed twice. Therefore it is sane to
		# define it two times in different scopes.
		for (qw/apache apache2/) {
			next if(! -e "$bkpDir/$_.system");

			($rs, $$cfg) = get_file("$bkpDir/$_.system");
			return $rs if ($rs != 0);

			# Add code if not exists
			if ($$cfg !~ /awstats_updateall\.pl/i) {
				# Building the new file
				$$cfg =~ s/sharedscripts/sharedscripts\n\tprerotate\n\t\t$main::cfg{'AWSTATS_ROOT_DIR'}\/awstats_updateall.pl now -awstatsprog=$main::cfg{'AWSTATS_ENGINE_DIR'}\/awstats.pl &> \/dev\/null\n\tendscript/gi;

				# Store the new file in working directory
				$rs = store_file(
					"$wrkDir/$_", $$cfg, $main::cfg{'ROOT_USER'},
					$main::cfg{'ROOT_GROUP'}, 0644
				);
				return $rs if ($rs != 0);

				# Install the new file in production directory
				$rs = sys_command_rs(
					"$main::cfg{'CMD_CP'} -pf $wrkDir/$_ /etc/logrotate.d/"
				);
				return $rs if($rs != 0);
			}
		}
	}

	push_el(\@main::el, 'setup_awstats_vhost()', 'Starting...');

	0;
}

################################################################################
# IspCP Postfix setup / update
#
# This subroutine built, store and install Postfix configuration files
#
# @return int 0 on success, other on failure
#
sub setup_mta {

	push_el(\@main::el, 'setup_mta()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'CMD_MTA'} =~ /^no$/i);

	my ($rs, $cfgTpl, $path, $file);
	my $cfg = \$cfgTpl;

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/postfix";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";
	my $vrlDir = "$cfgDir/ispcp";

	## Dedicated tasks for the Install or Updates process

	# Install
	if(!defined &update_engine) {
		# Savings all system configuration files if they exist
		for (
			map {/(.*\/)(.*)$/ && $1.':'.$2}
			$main::cfg{'POSTFIX_CONF_FILE'},
			$main::cfg{'POSTFIX_MASTER_CONF_FILE'}
		) {
			($path, $file) = split /:/;

			next if(!-e $path.$file);

			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $path$file  $bkpDir/$file.system"
			);
			return $rs if ($rs != 0);
		}
	# Update
	} else {
		my $timestamp = time;

		# Saving all current production files
		for (
			map {/(.*\/)(.*)$/ && $1.':'.$2}
			$main::cfg{'POSTFIX_CONF_FILE'},
			$main::cfg{'POSTFIX_MASTER_CONF_FILE'},
			$main::cfg{'MTA_VIRTUAL_CONF_DIR'}.'/aliases',
			$main::cfg{'MTA_VIRTUAL_CONF_DIR'}.'/domains',
			$main::cfg{'MTA_VIRTUAL_CONF_DIR'}.'/mailboxes',
			$main::cfg{'MTA_VIRTUAL_CONF_DIR'}.'/transport',
			$main::cfg{'MTA_VIRTUAL_CONF_DIR'}.'/sender-access'
		) {
			($path, $file) = split /:/;

			next if(!-e $path.$file);

			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $path$file  $bkpDir/$file.$timestamp"
			);
			return $rs if ($rs != 0);
		}
	}

	## Building, storage and installation of new file

	# main.cf

	# Tags preparation
	my %tags_hash = (
		'{MTA_HOSTNAME}' => $main::cfg{'SERVER_HOSTNAME'},
		'{MTA_LOCAL_DOMAIN}' => "$main::cfg{'SERVER_HOSTNAME'}.local",
		'{MTA_VERSION}' => $main::cfg{'Version'},
		'{MTA_TRANSPORT_HASH}' => $main::cfg{'MTA_TRANSPORT_HASH'},
		'{MTA_LOCAL_MAIL_DIR}' => $main::cfg{'MTA_LOCAL_MAIL_DIR'},
		'{MTA_LOCAL_ALIAS_HASH}' => $main::cfg{'MTA_LOCAL_ALIAS_HASH'},
		'{MTA_VIRTUAL_MAIL_DIR}' => $main::cfg{'MTA_VIRTUAL_MAIL_DIR'},
		'{MTA_VIRTUAL_DMN_HASH}' => $main::cfg{'MTA_VIRTUAL_DMN_HASH'},
		'{MTA_VIRTUAL_MAILBOX_HASH}' => $main::cfg{'MTA_VIRTUAL_MAILBOX_HASH'},
		'{MTA_VIRTUAL_ALIAS_HASH}' => $main::cfg{'MTA_VIRTUAL_ALIAS_HASH'},
		'{MTA_MAILBOX_MIN_UID}' => $main::cfg{'MTA_MAILBOX_MIN_UID'},
		'{MTA_MAILBOX_UID}' => $main::cfg{'MTA_MAILBOX_UID'},
		'{MTA_MAILBOX_GID}' => $main::cfg{'MTA_MAILBOX_GID'},
		'{PORT_POSTGREY}' => $main::cfg{'PORT_POSTGREY'}
	);

	# Loading the template from /etc/ispcp/postfix/
	($rs, $cfgTpl) = get_file("$cfgDir/main.cf");
	return $rs if ($rs != 0);

	# Building the new file
	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/main.cf", $$cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command_rs(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/main.cf " .
		"$main::cfg{'POSTFIX_CONF_FILE'}"
	);
	return $rs if($rs != 0);

	# master.cf

	# Store the file in working directory
	$rs = sys_command("$main::cfg{'CMD_CP'} -pf $cfgDir/master.cf $wrkDir/");
	return $rs if ($rs != 0);

	# Install the file in production dir
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $cfgDir/master.cf " .
		"$main::cfg{'POSTFIX_MASTER_CONF_FILE'}"
	);
	return $rs if ($rs != 0);

	## Virtuals related files

	for (qw/aliases domains mailboxes transport sender-access/) {
		# Store the new files in working directory
		$rs = sys_command("$main::cfg{'CMD_CP'} -pf $vrlDir/$_ $wrkDir/");
		return $rs if ($rs != 0);

		# Install the files in production directory
		$rs = sys_command(
			"$main::cfg{'CMD_CP'} -pf $wrkDir/$_ " .
			"$main::cfg{'MTA_VIRTUAL_CONF_DIR'}/"
		);
		return $rs if ($rs != 0);

		# Create / update Btree databases for all lookup tables
		$rs = sys_command(
			"$main::cfg{'CMD_POSTMAP'} $main::cfg{'MTA_VIRTUAL_CONF_DIR'}/$_ " .
			"$main::rlogfile"
		);
		return $rs if ($rs != 0);
	}

	# Rebuild the database for the mail aliases file - Begin
	$rs = sys_command("$main::cfg{'CMD_NEWALIASES'} $main::rlogfile");
	return $rs if ($rs != 0);

	## Set ARPL messenger owner, group and permissions

	$rs = setfmode(
		"$main::cfg{'ROOT_DIR'}/engine/messenger/ispcp-arpl-msgr",
		$main::cfg{'MTA_MAILBOX_UID_NAME'}, $main::cfg{'MTA_MAILBOX_GID_NAME'},
		0755
	);
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_mta()', 'Ending...');

	0;
}

################################################################################
# IspCP Courier setup / update
#
# This subroutine do the following tasks:
#  - Built, store and install Courier, related configuration files
#  - Creates userdb.dat from the contents of userdb file
#
# @return int 0 on success, other on failure
#
sub setup_po {

	push_el(\@main::el, 'setup_po()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'CMD_AUTHD'} =~ /^no$/i);

	my ($rs, $rdata);

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/courier";
	my $bkpDir ="$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	## Dedicated tasks for the Install or Updates process

	# Install:
	if(!defined &update_engine) {
		# Saving all system configuration files if they exist
		for (qw/authdaemonrc userdb/) {
			next if(!-e "$main::cfg{'AUTHLIB_CONF_DIR'}/$_");

			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $main::cfg{'AUTHLIB_CONF_DIR'}/$_ " .
				"$bkpDir/$_.system"
			);
			return $rs if ($rs != 0);
		}
	# Update:
	} else {
		my $timestamp = time;

		# Saving all current production files if they exist
		for (qw/authdaemonrc userdb/) {
			next if(!-e "$main::cfg{'AUTHLIB_CONF_DIR'}/$_");

			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $main::cfg{'AUTHLIB_CONF_DIR'}/$_ " .
				"$bkpDir/$_.$timestamp"
			);
			return $rs if ($rs != 0);
		}
	}

	## Building, storage and installation of new file

	# authdaemonrc

	# Loading the system file from /etc/ispcp/backup
	($rs, $rdata) = get_file("$bkpDir/authdaemonrc.system");
	return $rs if ($rs != 0);

	# Building the new file
	# FIXME: Sould be review...
	$rdata =~ s/authmodulelist="/authmodulelist="authuserdb /gi;

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/authdaemonrc", $rdata, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0660
	);
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/authdaemonrc " .
		"$main::cfg{'AUTHLIB_CONF_DIR'}/"
	);
	return $rs if ($rs != 0);

	# userdb

	# Store the new file in working directory
	$rs = sys_command("$main::cfg{'CMD_CP'} -pf $cfgDir/userdb $wrkDir/");
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/userdb " .
		"$main::cfg{'AUTHLIB_CONF_DIR'}"
	);
	return $rs if ($rs != 0);

	# Set permissions for the production file
	$rs = setfmode(
		"$main::cfg{'AUTHLIB_CONF_DIR'}/userdb", $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0600
	);
	return $rs if($rs != 0);

	# Creates userdb.dat from the contents of userdb
	$rs = sys_command($main::cfg{'CMD_MAKEUSERDB'});
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_po()', 'Ending...');

	0;
}

################################################################################
# IspCP Proftpd setup / update
#
# This subroutine do the following tasks:
#  - Built, store and install Proftpd main configuration files
#  - Create Ftpd SQL account if needed
#
# @return int 0 on success, other on failure
#
sub setup_ftpd {

	push_el(\@main::el, 'setup_ftpd()', 'Starting...');

	# Do not generate cfg files if the service is disabled
	return 0 if($main::cfg{'CMD_FTPD'} =~ /^no$/i);

	my ($rs, $rdata, $sql, $cfgTpl);
	my $cfg = \$cfgTpl;

	my $warnMsg;
	my $wrkFile;

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/proftpd";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	## Sets the path to the configuration file

	if (!-e $main::cfg{'FTPD_CONF_FILE'}) {
		$rs = set_conf_val('FTPD_CONF_FILE', '/etc/proftpd/proftpd.conf');
		return $rs if ($rs != 0);

		$rs = store_conf();
		return $rs if ($rs != 0);
	}

	## Dedicated tasks for Install or Updates process

	# Install:
	if(!defined &update_engine) {
		# Saving the system configuration file if it exist
		if(-e $main::cfg{'FTPD_CONF_FILE'}) {
			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $main::cfg{'FTPD_CONF_FILE'} " .
				"$bkpDir/proftpd.conf.system"
			);
			return $rs if($rs != 0);
		}
	# Update:
	} else {
		my $timestamp = time;

		# Saving the current production files if it exits
		if(-e $main::cfg{'FTPD_CONF_FILE'}) {
			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $main::cfg{'FTPD_CONF_FILE'} " .
				"$bkpDir/proftpd.conf.$timestamp"
			);
			return $rs if($rs != 0);
		}

		## Get the current user and password for SQL connection and check it

		if(-e "$wrkDir/proftpd.conf" ) {
			$wrkFile = "$wrkDir/proftpd.conf";
		} elsif(-e "$main::cfg{'CONF_DIR'}/proftpd/backup/proftpd.conf.ispcp") {
			$wrkFile = "$main::cfg{'CONF_DIR'}/proftpd/backup/proftpd.conf.ispcp";
		} elsif(-e '/etc/proftpd.conf.bak') {
			$wrkFile = '/etc/proftpd.conf.bak';
		}

		# Loading working configuration file from /etc/ispcp/working/
		($rs, $rdata) = get_file($wrkFile);

		unless($rs) {
			if($rdata =~ /^SQLConnectInfo(?: |\t)+.*?(?: |\t)+(.*?)(?: |\t)+(.*?)\n/im) {

				# Check the database connection with current ids
				$rs = check_sql_connection($1, $2);

				# If the connection is successful, we can use these identifiers
				unless($rs) {
					$main::ua{'db_ftp_user'} = $1;
					$main::ua{'db_ftp_password'} = $2;
				} else {
					$warnMsg = "\n\t[WARNING] Unable to connect to the " .
						"database with authentication information\n\tfound in " .
						"your proftpd.conf file! We will create a new Ftpd " .
						"Sql account.\n";
				}
			}
		} else {
			$warnMsg = "\n\t[WARNING] Unable to find the Proftpd " .
				"configuration file!\n\tWe will create a new one.";
		}

		# We ask the database ftp user and password, and we create new Sql ftp
		# user account if needed
		if(!defined($main::ua{'db_ftp_user'}) ||
			!defined($main::ua{'db_ftp_password'})) {

			print defined($warnMsg)
				? $warnMsg
				: "\n\t[WARNING] Unable to retrieve your current username " .
					"and/or\n\tpassword for the Ftpd Sql account! We will " .
					"create a new Ftpd Sql account.\n";

			do {
				$rs = ask_db_ftp_user();
			} while ($rs);

			do {
				$rs = ask_db_ftp_password();
			} while ($rs);

			## Setup of new Sql ftp user

			# First, we reset the db connection
			$main::db = undef;

			# Sets the dsn
			@main::db_connect = (
				"DBI:mysql:mysql:$main::db_host", $main::db_user, $main::db_pwd
			);

			## We ensure that news data doesn't exist in database

			$sql = "
				DELETE FROM
					tables_priv
				WHERE
					Host = '$main::cfg{'SERVER_HOSTNAME'}'
				AND
					Db = '$main::db_name'
				AND
					User = '$main::ua{'db_ftp_user'}'
				;
			";

			($rs, $rdata) = doSQL($sql);
			return $rs if ($rs != 0);

			$sql = "
				DELETE FROM
					user
				WHERE
					Host = '$main::db_host'
				AND
					User = '$main::ua{'db_ftp_user'}'
				;
			";

			($rs, $rdata) = doSQL($sql);
			return $rs if ($rs != 0);

			($rs, $rdata) = doSQL('FLUSH PRIVILEGES');
			return $rs if ($rs != 0);

			## Inserting new data into the database

			for (qw/ftp_group ftp_users quotalimits quotatallies/) {
				$sql = "
					GRANT SELECT,INSERT,UPDATE,DELETE ON
						$main::db_name.$_
					TO
						'$main::ua{'db_ftp_user'}'\@'$main::db_host'
					IDENTIFIED BY
						'$main::ua{'db_ftp_password'}'
					;
				";

				($rs, $rdata) = doSQL($sql);
				return $rs if ($rs != 0);
			}
		}
	}

	## Building, storage and installation of new file

	# Tags preparation
	my %tags_hash = (
		'{HOST_NAME}' => $main::cfg{'SERVER_HOSTNAME'},
		'{DATABASE_NAME}' => $main::db_name,
		'{DATABASE_HOST}' => $main::db_host,
		'{DATABASE_USER}' => $main::ua{'db_ftp_user'},
		'{DATABASE_PASS}' => $main::ua{'db_ftp_password'},
		'{FTPD_MIN_UID}' => $main::cfg{'APACHE_SUEXEC_MIN_UID'},
		'{FTPD_MIN_GID}' => $main::cfg{'APACHE_SUEXEC_MIN_GID'}
	);

	# Loading the template from /etc/ispcp/proftpd/
	($rs, $cfgTpl) = get_file("$cfgDir/proftpd.conf");
	return $rs if ($rs != 0);

	# Building the new file
	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/proftpd.conf", $$cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0600
	);
	return $rs if ($rs != 0);

	# Install the new file in production directory
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/proftpd.conf " .
		"$main::cfg{'FTPD_CONF_FILE'}"
	);
	return $rs if ($rs != 0);

	## To fill ftp_traff.log file with something.

	if (! -e "$main::cfg{'TRAFF_LOG_DIR'}/proftpd") {
		$rs = make_dir(
			"$main::cfg{'TRAFF_LOG_DIR'}/proftpd", $main::cfg{'ROOT_USER'},
			$main::cfg{'ROOT_GROUP'}, 0755
		);
		return $rs if ($rs != 0);
	}

	if(! -e "$main::cfg{'TRAFF_LOG_DIR'}$main::cfg{'FTP_TRAFF_LOG'}") {
		$rs = store_file(
			"$main::cfg{'TRAFF_LOG_DIR'}$main::cfg{'FTP_TRAFF_LOG'}", "\n",
			$main::cfg{'ROOT_USER'}, $main::cfg{'ROOT_GROUP'}, 0644
		);
		return $rs if ($rs != 0);
	}

	push_el(\@main::el, 'setup_ftpd()', 'Ending...');

	0;
}

################################################################################
# IspCP Daemon, network setup / update
#
# This subroutine install or update the ispCP daemon and network init scripts
#
# @return int 0 on success, other on failure
#
sub setup_ispcp_daemon_network {

	push_el(\@main::el, 'setup_ispcp_daemon_network()', 'Starting...');

	my ($rs, $rdata, $fileName);

	for ($main::cfg{'CMD_ISPCPD'}, $main::cfg{'CMD_ISPCPN'}) {
		# Do not process if the service is disabled
		next if(/^no$/i);

		($fileName) = /.*\/(.*)$/;

		$rs = sys_command_rs(
			"$main::cfg{'CMD_CHOWN'} $main::cfg{'ROOT_USER'}:" .
			"$main::cfg{'ROOT_GROUP'} $_ $main::rlogfile"
		);
		return $rs if($rs != 0);

		$rs = sys_command_rs("$main::cfg{'CMD_CHMOD'} 0755 $_ $main::rlogfile");
		return $rs if($rs != 0);

		# Services installation / update (Debian, Ubuntu)
		# Todo Check it for Debian Squeeze
		if(-x '/usr/sbin/update-rc.d') {
			# Update task - The links should be removed first to be updated
			if(defined &update_engine) {
				sys_command_rs(
					"/usr/sbin/update-rc.d -f $fileName remove $main::rlogfile"
				);
			}

			# ispcp_network should be stopped before the MySQL server (due to the
			# interfaces deletion process)
			if($fileName eq 'ispcp_network') {
				sys_command_rs(
					"/usr/sbin/update-rc.d $fileName defaults 99 20 $main::rlogfile"
				);
			} else {
				sys_command_rs(
					"/usr/sbin/update-rc.d $fileName defaults 99 $main::rlogfile"
				);
			}

		# LSB 3.1 Core section 20.4 compatibility (ex. OpenSUSE > 10.1)
		} elsif(-x '/usr/lib/lsb/install_initd') {
			# Update task
			if(-x '/usr/lib/lsb/remove_initd' && defined &update_engine) {
				sys_command_rs("/usr/lib/lsb/remove_initd $_ $main::rlogfile");
			}

			sys_command_rs("/usr/lib/lsb/install_initd $_ $main::rlogfile");
			return $rs if ($rs != 0);
		}
	}

	push_el(\@main::el, 'setup_ispcp_daemon_network()', 'Ending...');

	0;
}

################################################################################
# IspCP GUI apache vhost setup / update
#
# this subroutine built, store and install ispCP GUI vhost configuration file
#
# @return int 0 on success, other on failure
#
sub setup_gui_httpd {

	push_el(\@main::el, 'setup_gui_httpd()', 'Starting...');

	my ($rs, $cmd, $cfgTpl);
	my $cfg = \$cfgTpl;

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/apache";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	# Update:
	if(defined &update_engine) {
		# Saving the current production file if it exists
		if(-e "$main::cfg{'APACHE_SITES_DIR'}/00_master.conf") {
			$cmd = "$main::cfg{'CMD_CP'} -p $main::cfg{'APACHE_SITES_DIR'}/" .
			"00_master.conf $bkpDir/00_master.conf." . time;

			$rs = sys_command_rs($cmd);
			return $rs if($rs != 0);
		}
	}

	# Building new configuration file

	# Loading the template from /etc/ispcp/apache
	($rs, $cfgTpl) = get_file("$cfgDir/00_master.conf");
	return $rs if($rs != 0);

	# Tags preparation
	my %tags_hash = (
		'{BASE_SERVER_IP}' => $main::cfg{'BASE_SERVER_IP'},
		'{BASE_SERVER_VHOST}' => $main::cfg{'BASE_SERVER_VHOST'},
		'{DEFAULT_ADMIN_ADDRESS}' => $main::cfg{'DEFAULT_ADMIN_ADDRESS'},
		'{ROOT_DIR}' => $main::cfg{'ROOT_DIR'},
		'{APACHE_WWW_DIR}' => $main::cfg{'APACHE_WWW_DIR'},
		'{APACHE_USERS_LOG_DIR}' => $main::cfg{'APACHE_USERS_LOG_DIR'},
		'{APACHE_LOG_DIR}' => $main::cfg{'APACHE_LOG_DIR'},
		'{PHP_STARTER_DIR}' => $main::cfg{'PHP_STARTER_DIR'},
		'{PHP_VERSION}' => $main::cfg{'PHP_VERSION'},
		'{WWW_DIR}' => $main::cfg{'ROOT_DIR'},
		'{DMN_NAME}' => 'gui',
		'{CONF_DIR}' => $main::cfg{'CONF_DIR'},
		'{MR_LOCK_FILE}' => $main::cfg{'MR_LOCK_FILE'},
		'{RKHUNTER_LOG}' => $main::cfg{'RKHUNTER_LOG'},
		'{CHKROOTKIT_LOG}' => $main::cfg{'CHKROOTKIT_LOG'},
		'{PEAR_DIR}' => $main::cfg{'PEAR_DIR'},
		'{OTHER_ROOTKIT_LOG}' => $main::cfg{'OTHER_ROOTKIT_LOG'},
		'{APACHE_SUEXEC_USER_PREF}' => $main::cfg{'APACHE_SUEXEC_USER_PREF'},
		'{APACHE_SUEXEC_MIN_UID}' => $main::cfg{'APACHE_SUEXEC_MIN_UID'},
		'{APACHE_SUEXEC_MIN_GID}' => $main::cfg{'APACHE_SUEXEC_MIN_GID'}
	);

	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	## Storage and installation of new file

	$rs = store_file(
		"$wrkDir/00_master.conf", $$cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	$rs = sys_command_rs(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/00_master.conf " .
		"$main::cfg{'APACHE_SITES_DIR'}/"
	);
	return $rs if($rs != 0);

	## Disable 000-default vhost

	if (-e "/usr/sbin/a2dissite") {
		sys_command_rs("/usr/sbin/a2dissite 000-default $main::rlogfile");
	}

	## Disable the default NameVirtualHost directive

	if(-e '/etc/apache2/ports.conf') {
		# Loading the file
		($rs, my $rdata) = get_file('/etc/apache2/ports.conf');
		return $rs if($rs != 0);

		# Disable the default NameVirtualHost directive
		$rdata =~ s/^NameVirtualHost \*:80/#NameVirtualHost \*:80/gmi;

		# Saving the modified file
		$rs = save_file('/etc/apache2/ports.conf', $rdata);
		return $rs if($rs != 0);
	}

	## Enable GUI vhost - Begin

	if (-e "/usr/sbin/a2ensite") {
		sys_command("/usr/sbin/a2ensite 00_master.conf $main::rlogfile");
	}

	push_el(\@main::el, 'setup_gui_httpd()', 'Ending...');

	0;
}

################################################################################
# ispCP GUI PHP configuration files - Setup / Update
#
# This subroutine do the following tasks:
#  - Create the master fcgi directory
#  - Built, store and install gui php related files (starter script, php.ini...)
#
# @return int 0 on success, other on failure
#
sub setup_gui_php {

	push_el(\@main::el, 'setup_gui_php()', 'Starting...');

	my ($rs, $cfgTpl);
	my $cfg = \$cfgTpl;

	my %tags_hash = ();

	my $cfgDir = "$main::cfg{'CONF_DIR'}/fcgi";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";

	# Update:
	if(defined &update_engine) {
		my $timestamp = time();

		for (qw{php5-fcgi-starter php5/php.ini php5/browscap.ini}) {
			if(-e "$main::cfg{'PHP_STARTER_DIR'}/master/$_") {
				my (undef, $file) = split('/');
				$file = $_ if(!defined $file);

				$rs = sys_command_rs(
					"$main::cfg{'CMD_CP'} -p $main::cfg{'PHP_STARTER_DIR'}/" .
					"master/$_ $bkpDir/master.$file.$timestamp"
				);
				return $rs if($rs != 0);
			}
		}
	}

	## Create the fcgi directories tree for gui user if it doesn't exists

	$rs = make_dir(
		"$main::cfg{'PHP_STARTER_DIR'}/master/php5", $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0755
	);
	return $rs if ($rs != 0);

	## PHP5 Starter script

	# Loading the template from /etc/ispcp/fcgi/parts/master
	($rs, $cfgTpl) = get_file("$cfgDir/parts/master/php5-fcgi-starter.tpl");
	return $rs if ($rs != 0);

	# Tags preparation
	%tags_hash = (
		'{PHP_STARTER_DIR}' => $main::cfg{'PHP_STARTER_DIR'},
		'{PHP5_FASTCGI_BIN}' => $main::cfg{'PHP5_FASTCGI_BIN'},
		'{GUI_ROOT_DIR}' => $main::cfg{'GUI_ROOT_DIR'},
		'{DMN_NAME}' => 'master'
	);

	# Building the new file
	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/master.php5-fcgi-starter", $$cfg,
		$main::cfg{'APACHE_SUEXEC_USER_PREF'} . $main::cfg{'APACHE_SUEXEC_MIN_UID'},
		$main::cfg{'APACHE_SUEXEC_USER_PREF'} . $main::cfg{'APACHE_SUEXEC_MIN_GID'},
		0755
	);
	return $rs if ($rs != 0);

	# Install the new file
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/master.php5-fcgi-starter " .
		"$main::cfg{'PHP_STARTER_DIR'}/master/php5-fcgi-starter"
	);
	return $rs if ($rs != 0);

	## PHP5 php.ini file

	# Loading the template from /etc/ispcp/fcgi/parts/master/php5
	($rs, $cfgTpl) = get_file("$cfgDir/parts/master/php5/php.ini");
	return $rs if ($rs != 0);

	# Tags preparation
	%tags_hash = (
		'{WWW_DIR}' => $main::cfg{'ROOT_DIR'},
		'{DMN_NAME}' => 'gui',
		'{MAIL_DMN}' => $main::cfg{'BASE_SERVER_VHOST'},
		'{CONF_DIR}' => $main::cfg{'CONF_DIR'},
		'{MR_LOCK_FILE}' => $main::cfg{'MR_LOCK_FILE'},
		'{PEAR_DIR}' => $main::cfg{'PEAR_DIR'},
		'{RKHUNTER_LOG}' => $main::cfg{'RKHUNTER_LOG'},
		'{CHKROOTKIT_LOG}' => $main::cfg{'CHKROOTKIT_LOG'},
		'{OTHER_ROOTKIT_LOG}' => ($main::cfg{'OTHER_ROOTKIT_LOG'} ne '')
			? ":$main::cfg{'OTHER_ROOTKIT_LOG'}" : '',
		'{PHP_STARTER_DIR}' => $main::cfg{'PHP_STARTER_DIR'},
		'{PHP_TIMEZONE}' => $main::cfg{'PHP_TIMEZONE'}
	);

	# Building the new file
	($rs, $$cfg) = prep_tpl(\%tags_hash, $cfgTpl);
	return $rs if ($rs != 0);

	# Store the new file in working directory
	$rs = store_file(
		"$wrkDir/master.php.ini", $$cfg,
		$main::cfg{'APACHE_SUEXEC_USER_PREF'} . $main::cfg{'APACHE_SUEXEC_MIN_UID'},
		$main::cfg{'APACHE_SUEXEC_USER_PREF'} . $main::cfg{'APACHE_SUEXEC_MIN_GID'},
		0644
	);
	return $rs if ($rs != 0);

	# Install the new file
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/master.php.ini " .
		"$main::cfg{'PHP_STARTER_DIR'}/master/php5/php.ini"
	);
	return $rs if ($rs != 0);

	## PHP Browser Capabilities support file

	# Store the new file in working directory
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $cfgDir/parts/master/php5/browscap.ini " .
		"$wrkDir/browscap.ini"
	);
	return $rs if ($rs != 0);

	# Set file permissions
	$rs = setfmode(
		"$wrkDir/browscap.ini",
		$main::cfg{'APACHE_SUEXEC_USER_PREF'} . $main::cfg{'APACHE_SUEXEC_MIN_UID'},
		$main::cfg{'APACHE_SUEXEC_USER_PREF'} . $main::cfg{'APACHE_SUEXEC_MIN_GID'},
		0644
	);
	return $rs if ($rs != 0);

	# Install the new file
	$rs = sys_command(
		"$main::cfg{'CMD_CP'} -pf $wrkDir/browscap.ini " .
		"$main::cfg{'PHP_STARTER_DIR'}/master/php5/browscap.ini"
	);
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_gui_php()', 'Ending...');

	0;
}

################################################################################
# IspCP GUI pma configuration file and pma slq control user
#
# This subroutine built, store and install the ispCP GUI pma configuration file
#
# @return int 0 on success, other on failure
#
sub setup_gui_pma {

	push_el(\@main::el, 'setup_gui_pma()', 'Starting...');

	my ($rs, $sql, $cfg_file, $pma_sql_user, $pma_sql_password, $hostname);
	my $cfg =  \$cfg_file;

	my $cfgDir = "$main::cfg{'GUI_ROOT_DIR'}/tools/pma/";

	# Gets the pma configuration file
	($rs, $cfg_file) = get_file("${cfgDir}config.inc.php");
	return $rs if ($rs != 0);

	# Install
	if(!defined &update_engine) {
		$pma_sql_user = $main::ua{'db_pma_user'};
		$pma_sql_password = $main::ua{'db_pma_password'};
		$hostname = $main::ua{'db_host'};
	# Update:
	} else {
		if($cfg_file =~ /\{(?:HOSTNAME|PMA_USER|PMA_PASS|BLOWFISH|TMP_DIR)\}/) {
			print STDOUT colored(['bold yellow'], "\n\n\tWARNING: ") .
				"Your PMA configuration file should be re-builded !\n";

			# Gets the new pma control user username
			do {
				$rs = ask_db_pma_user();
			} while ($rs == 1);

			# Gets the new pma control user password
			do {
				$rs = ask_db_pma_password();
			} while ($rs == 1);

			$pma_sql_user = $main::ua{'db_pma_user'};
			$pma_sql_password = $main::ua{'db_pma_password'};
			$hostname = $main::cfg{'DATABASE_HOST'}
		}
	}

	# Create or update the PMA user if needed
	if(defined $pma_sql_user && defined $pma_sql_password) {
		$main::db = undef;

		@main::db_connect = (
			"DBI:mysql:mysql:$main::db_host", $main::db_user, $main::db_pwd
		);

		## We ensure the new user is not already registered and we remove the
		## old user if one exist

		my $i = 0;

		for ($main::cfg{'PMA_USER'}, $pma_sql_user) {
			if($main::cfg{'PMA_USER'} eq $pma_sql_user && $i == 0) {
				$i++;
				next;
			}

			$sql = "
				DELETE FROM
					tables_priv
				WHERE
					Host = '$hostname'
				AND
					Db = 'mysql' AND User = '$_'
				;
			";

			($rs) = doSQL($sql);
			return $rs if ($rs != 0);

			$sql = "
				DELETE FROM
					user
				WHERE
					Host = '$hostname'
				AND
					User = '$_'
				;
			";

			($rs) = doSQL($sql);
			return $rs if ($rs != 0);

			$sql = "
				DELETE FROM
					columns_priv
				WHERE
					Host = '$hostname'
				AND
					User = '$_'
				;
			";

			($rs) = doSQL($sql);
			return $rs if ($rs != 0);
		}

		## Flush Db privileges

		($rs) = doSQL('FLUSH PRIVILEGES');
		return $rs if ($rs != 0);

		## Adding the new pma control user

		$sql = "
			GRANT USAGE ON
				mysql.*
			TO
				'$pma_sql_user'\@'$hostname'
			IDENTIFIED BY
				'$pma_sql_password'
			;
		";

		($rs) = doSQL($sql);
		return $rs if ($rs != 0);

		## Sets the rights for the pma control user
		$sql = "
			GRANT SELECT (
				Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv,
				Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv,
				File_priv, Grant_priv, References_priv, Index_priv, Alter_priv,
				Show_db_priv, Super_priv, Create_tmp_table_priv,
				Lock_tables_priv, Execute_priv, Repl_slave_priv,
				Repl_client_priv
			)
			ON
				mysql.user
			TO
				'$pma_sql_user'\@'$hostname'
			;
		";

		($rs) = doSQL($sql);
		return $rs if ($rs != 0);

		$sql = "
			GRANT SELECT ON
				mysql.db
			TO
				'$pma_sql_user'\@'$hostname'
			;
		";

		($rs) = doSQL($sql);
		return $rs if ($rs != 0);

		$sql = "
			GRANT SELECT ON
				mysql.host
			TO
				'$pma_sql_user'\@'$hostname'
			;
		";

		($rs) = doSQL($sql);
		return $rs if ($rs != 0);

		$sql = "
			GRANT SELECT
				(Host, Db, User, Table_name, Table_priv, Column_priv)
			ON
				mysql.tables_priv
			TO
				'$pma_sql_user'\@'$hostname'
			;
		";

		($rs) = doSQL($sql);
		return $rs if ($rs != 0);

		## Insert pma user and password to config file
		## together with some other information

		my $blowfish = gen_sys_rand_num(31);
		$blowfish =~ s/'/\\'/gi;

		# Tags preparation
		my %tag_hash = (
			'{PMA_USER}' => $pma_sql_user,
			'{PMA_PASS}' => $pma_sql_password,
			'{HOSTNAME}' => $hostname,
			'{TMP_DIR}'  => "$main::cfg{'GUI_ROOT_DIR'}/phptmp",
			'{BLOWFISH}' => $blowfish
		);

		# Building the file
		($rs, $$cfg) = prep_tpl(\%tag_hash, $cfg_file);
		return $rs if ($rs != 0);

		# Install the new file
		$rs = store_file(
			"$cfgDir/config.inc.php", $$cfg,
			"$main::cfg{'APACHE_SUEXEC_USER_PREF'}$main::cfg{'APACHE_SUEXEC_MIN_UID'}",
			"$main::cfg{'APACHE_GROUP'}", 0440
		);
		return $rs if ($rs != 0);

		## Update the ispcp.conf file

		$rs = set_conf_val('PMA_USER', $pma_sql_user);
		return $rs if ($rs != 0);

		$rs = store_conf();
		return $rs if ($rs != 0);

	}

	push_el(\@main::el, 'setup_gui_pma()', 'Ending...');

	0;
}

################################################################################
# IspCP Gui named configuration
#
# This subroutine do the following tasks:
#  - Add Gui named cfg data in main configuration file
#  - Built GUI named dns record's file
#
# @return int 0 on success, other on failure
#
sub setup_gui_named {

	push_el(\@main::el, 'setup_gui_named()', 'Starting...');

	# Add GUI named cfg data
	my $rs = setup_gui_named_cfg_data($main::cfg{'BASE_SERVER_VHOST'});
	return $rs if($rs != 0);

	# Building GUI named dns records file
	$rs = setup_gui_named_db_data(
		$main::cfg{'BASE_SERVER_IP'}, $main::cfg{'BASE_SERVER_VHOST'}
	);
	return $rs if($rs != 0);

	push_el(\@main::el, 'setup_gui_named()', 'Ending...');

	0;
}

################################################################################
# IspCP Gui named cfg file
#
# This subroutine do the following tasks:
#  - Add Gui named cfg data in main configuration file
#
# @return int 0 on success, other on failure
#
sub setup_gui_named_cfg_data {

	push_el(\@main::el, 'setup_gui_named_cfg_data()', 'Starting...');

	my ($base_vhost) = @_;

	my ($rs, $rdata, $cfg);

	# Named directories paths
	my $cfgDir = $main::cfg{'CONF_DIR'};
	my $tpl_dir = "$cfgDir/bind/parts";
	my $bkpDir = "$cfgDir/bind/backup";
	my $wrkDir = "$cfgDir/bind/working";
	my $dbDir = $main::cfg{'BIND_DB_DIR'};

	if (!defined($base_vhost) || $base_vhost eq '') {
		push_el(
			\@main::el, 'setup_gui_named_cfg_data()',
			'[FATAL] Undefined Input Data...'
		);
		return 1;
	}

	# Saving the current production file if it exists
	if(-e $main::cfg{'BIND_CONF_FILE'}) {
		$rs = sys_command_rs(
			"$main::cfg{'CMD_CP'} -p $main::cfg{'BIND_CONF_FILE'} " .
			"$bkpDir/named.conf." . time
		);
		return $rs if ($rs != 0);
	}

	## Building of new configuration file

	# Loading all needed templates from /etc/ispcp/bind/parts
	my ($entry_b, $entry_e, $entry) = ('', '', '');

	($rs, $entry_b, $entry_e, $entry) = get_tpl(
		$tpl_dir, 'cfg_entry_b.tpl', 'cfg_entry_e.tpl', 'cfg_entry.tpl'
	);
	return $rs if ($rs != 0);

	# Preparation tags
	my %tags_hash = ('{DMN_NAME}' => $base_vhost, '{DB_DIR}' => $dbDir);

	# Replacement tags
	my ($entry_b_val, $entry_e_val, $entry_val) = ('', '', '');

	($rs, $entry_b_val, $entry_e_val, $entry_val) = prep_tpl(
		\%tags_hash, $entry_b, $entry_e, $entry
	);
	return $rs if ($rs != 0);

	# Loading working file from /etc/ispcp/bind/working/named.conf
	($rs, $cfg) = get_file("$wrkDir/named.conf");
	return $rs if ($rs != 0);

	# Building the new configuration file
	my $entry_repl = "$entry_b_val$entry_val$entry_e_val\n$entry_b$entry_e";

	($rs, $cfg) = repl_tag(
		$entry_b, $entry_e, $cfg, $entry_repl, 'setup_gui_named_cfg_data'
	);
	return $rs if ($rs != 0);

	## Storage and installation of new file - Begin

	# Store the new builded file in the working directory
	$rs = store_file(
		"$wrkDir/named.conf", $cfg, $main::cfg{'ROOT_USER'},
		$main::cfg{'ROOT_GROUP'}, 0644
	);
	return $rs if ($rs != 0);

	# Install the new file in the production directory
	$rs = sys_command_rs(
		"$main::cfg{'CMD_CP'} -pf " .
		"$wrkDir/named.conf $main::cfg{'BIND_CONF_FILE'}"
	);
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_gui_named_cfg_data()', 'Ending...');

	0;
}

################################################################################
# IspCP Gui named dns record's Setup / Update
#
# This subroutine do the following tasks:
#  - Building GUI named dns record's file
#
# @return int 0 on success, other on failure
#
sub setup_gui_named_db_data {

	push_el(\@main::el, 'setup_gui_named_db_data()', 'Starting...');

	my ($baseIp, $baseVhost) = @_;

	if (!defined($baseVhost) || $baseVhost eq '') {
		push_el(
			\@main::el, 'add_named_db_data()', 'FATAL: Undefined Input Data...'
		);

		return 1;
	}

	my ($rs, $wrkFileContent, $entries);

	# Slave DNS  - Address IP
	my $secDnsIp = $main::cfg{'SECONDARY_DNS'};

	# Directories paths
	my $cfgDir = "$main::cfg{'CONF_DIR'}/bind";
	my $bkpDir = "$cfgDir/backup";
	my $wrkDir = "$cfgDir/working";
	my $dbDir = $main::cfg{'BIND_DB_DIR'};

	# Zone file name
	my $dbFname = "$baseVhost.db";

	# Named zone files paths
	my $sysCfg = "$dbDir/$dbFname";
	my $wrkCfg = "$wrkDir/$dbFname";
	my $bkpCfg = "$bkpDir/$dbFname";

	## Dedicated tasks for Install or Updates process

	if (defined &update_engine) {
		# Saving the current production file if it exists
		if(-e $sysCfg) {
			$rs = sys_command_rs(
				"$main::cfg{'CMD_CP'} -p $sysCfg $bkpCfg." . time
			);
			return $rs if ($rs != 0);
		}

		# Load the current working db file
		($rs, $wrkFileContent) = get_file($wrkCfg);

		if($rs != 0) {
			push_el(
				\@main::el, 'add_named_db_data()',
				"[WARNING] $baseVhost: Working db file not found!. " .
				'Re-creation from scratch is needed...'
			);

			$wrkFileContent = \$entries;
		}
	} else {
		$wrkFileContent = \$entries;
	}

	## Building new configuration file

	# Loading the template from /etc/ispcp/bind/parts
	($rs, $entries) = get_file("$cfgDir/parts/db_master_e.tpl");
	return $rs if ($rs != 0);

	# Replacement tags
	($rs, $entries) = prep_tpl(
		{
			'{DMN_NAME}' => $baseVhost,
			'{DMN_IP}' => $baseIp,
			'{BASE_SERVER_IP}' => $baseIp,
			'{SECONDARY_DNS_IP}' => ($secDnsIp ne '') ? $secDnsIp : $baseIp
		},
		$entries
	);
	return $rs if ($rs != 0);

	# Create or Update serial number according RFC 1912
	$rs = getSerialNumber(\$baseVhost, \$entries, \$wrkFileContent);
	return $rs if($rs != 0);

	## Store and install

	# Store the file in the working directory
	$rs = store_file(
		$wrkCfg, $entries, $main::cfg{'ROOT_USER'}, $main::cfg{'ROOT_GROUP'},
		0644
	);
	return $rs if ($rs != 0);

	# Install the file in the production directory
	$rs = sys_command_rs("$main::cfg{'CMD_CP'} -pf $wrkCfg $dbDir/");
	return $rs if ($rs != 0);

	push_el(\@main::el, 'setup_gui_named_db_data()', 'Ending...');

	0;
}


################################################################################
# Setup all services and does some other tasks
#
# @return void
# todo make all subroutine called here idempotent
#
sub setup_services_cfg {

	push_el(\@main::el, 'setup_services_cfg()', 'Starting...');

	##  Dedicated task for setup process
	if(defined &setup_engine) {
		# For 'rpm' package the user/group creation is supported by maintenance
		# scripts
		if (!defined($ARGV[0]) || $ARGV[0] ne '-rpm') {
			subtitle('ispCP users and groups:');
			my $rs = setup_system_users();
			print_status($rs, 'exit_on_error');
		}

		for (
			[\&setup_system_dirs, 'ispCP directories:'],
			[\&setup_config, 'ispCP configuration file:'],
			[\&setup_ispcp_database, 'ispCP database:'],
			[\&setup_default_language_table, 'ispCP default language table:'],
			[\&setup_default_sql_data, 'ispCP default SQL data:'],
			[\&setup_hosts, 'ispCP system hosts file:']
		) {
			subtitle($_->[1]);
			my $rs = &{$_->[0]};
			print_status($rs, 'exit_on_error');
		}
	}

	# Common tasks
	for (
		[\&setup_crontab, 'ispCP Crontab file:'],
		[\&setup_named, 'ispCP Bind9 main configuration file:'],
		[\&setup_fastcgi_modules, 'ispCP Apache fastCGI modules configuration'],
		[\&setup_httpd_main_vhost, 'ispCP Apache main vhost file:'],
		[\&setup_awstats_vhost, 'ispCP Apache AWStats vhost file:'],
		[\&setup_mta, 'ispCP Postfix configuration files:'],
		[\&setup_po, 'ispCP Courier-Authentication:'],
		[\&setup_ftpd, 'ispCP ProFTPd configuration file:'],
		[\&setup_ispcp_daemon_network, 'ispCP init scripts:']
	) {
		subtitle($_->[1]);
		my $rs = &{$_->[0]};
		print_status($rs, 'exit_on_error');
	}

	push_el(\@main::el, 'setup_services_cfg()', 'Ending...');
}

################################################################################
# Build all GUI related configuration files
#
# @return void
#
#sub rebuild_gui_cfg {
sub setup_gui_cfg {

	push_el(\@main::el, 'rebuild_gui_cfg()', 'Starting...');

	for (
		[\&setup_gui_named, 'ispCP GUI Bind9 configuration:'],
		[\&setup_gui_php, 'ispCP GUI fastCGI/PHP configuration:'],
		[\&setup_gui_httpd, 'ispCP GUI vhost file:'],
		[\&setup_gui_pma, 'ispCP PMA configuration file:']
	) {
		subtitle($_->[1]);
		my $rs = &{$_->[0]};
		print_status($rs, 'exit_on_error');
	}

	push_el(\@main::el, 'rebuild_gui_cfg()', 'Ending...');
}

################################################################################
# Setup rkhunter
#
# This subroutine process the following tasks:
#
#  - update rkhunter database files (only during setup process)
#  - Debian specific: Updates the configuration file and cron task, and
#  remove default unreadable created log file
#
# @return int 0 on success, other on failure
#
sub setup_rkhunter {

	push_el(\@main::el, 'setup_rkhunter()', 'Starting...');

	my ($rs, $rdata);

	# Deleting any existant log files
	$rs = sys_command_rs("$main::cfg{'CMD_RM'} -f $main::cfg{'RKHUNTER_LOG'}*");
	return $rs if($rs != 0);

	# Updates the rkhunter configuration provided by Debian package
	# to disable the default cron task (ispCP provides its own cron job for
	# rkhunter)
	if(-e '/etc/default/rkhunter') {
		# Get the file as a string
		($rs, $rdata) = get_file('/etc/default/rkhunter');
		return $rs if($rs != 0);

		# Disable cron task default
		$rdata =~ s@CRON_DAILY_RUN="yes"@CRON_DAILY_RUN="no"@gmi;

		# Saving the modified file
		$rs = save_file('/etc/default/rkhunter', $rdata);
		return $rs if($rs != 0);
	}

	# Update weekly cron task provided with the debian package
	# to avoid creation of unreadable log file
	if(-e '/etc/cron.weekly/rkhunter') {
		# Get the rkhunter file content
		($rs, $rdata) = get_file('/etc/cron.weekly/rkhunter');
		return $rs if($rs != 0);

		# Adds `--nolog`option to avoid unreadable log file
		$rdata =~ s@\$RKHUNTER --versioncheck --nocolors$@\$RKHUNTER --versioncheck --nocolors --nolog@gmi;
		$rdata =~ s@\$RKHUNTER --update --nocolors$@\$RKHUNTER --update --nocolors --nolog@gmi;
		$rdata =~ s@\$RKHUNTER --versioncheck 1>/dev/null 2>\$OUTFILE@\$RKHUNTER --versioncheck --nolog 1>/dev/null 2>\$OUTFILE@gmi;
		$rdata =~ s@\$RKHUNTER --update 1>/dev/null 2>>\$OUTFILE@\$RKHUNTER --update --nolog 1>/dev/null 2>>\$OUTFILE@gmi;

		# Saving the modified file
		$rs = save_file('/etc/cron.weekly/rkhunter', $rdata);
		return $rs if($rs != 0);
	}

	# Updates rkhunter database files (Only during setup process)
	if(defined &setup_engine) {
		if (sys_command_rs("which rkhunter > /dev/null") == 0 ) {
			# Here, we run the command with `--nolog` option to avoid creation
			# of unreadable log file. The log file will be created later by an
			# ispCP cron task
			$rs = sys_command_rs("rkhunter --update --nolog");
			return $rs if($rs != 0);
		}
	}

	push_el(\@main::el, 'setup_rkhunter()', 'Ending...');

	0;
}

################################################################################
# Remove some unneeded files
#
# This subroutine process the following tasks:
# - Delete .prev log files and their rotations not longer needed since r2251
# - Delete setup/update log files created in /tmp
# - Delete empty files in ispCP configuration directories
#
# @return int 1 on success, other on failure
#
sub setup_cleanup {

	push_el(\@main::el, 'setup_cleanup()', 'Starting...');

	my $rs = sys_command_rs(
		"$main::cfg{'CMD_RM'} -f $main::cfg{'LOG_DIR'}/*-traf.log.prev* " .
		"/tmp/ispcp-update-* /tmp/ispcp-setup-* " .
		"$main::cfg{'CONF_DIR'}/*/*/empty-file"
	);
	return $rs if($rs != 0);

	push_el(\@main::el, 'setup_cleanup()', 'Ending...');

	0;
}

################################################################################
# Run all update additional task such a rkhunter configuration
#
# @return void
#
sub additional_tasks{

	push_el(\@main::el, 'additional_tasks()', 'Starting...');

	subtitle('ispCP Rkhunter configuration:');
	my $rs = setup_rkhunter();
	print_status($rs, 'exit_on_error');

	subtitle('ispCP System cleanup:');
	setup_cleanup();
	print_status(0);

	push_el(\@main::el, 'additional_tasks()', 'Ending...');
}

################################################################################
# Set engine and gui permissions
#
# @return int 0 on success, other on failure
#
sub set_permissions {

	push_el(\@main::el, 'set_permissions()', 'Starting...');

	for (qw/engine gui/) {
		subtitle("Set $_ permissions:");

		my $rs = sys_command_rs(
			"$main::cfg{'CMD_SHELL'} " .
			"$main::cfg{'ROOT_DIR'}/engine/setup/set-$_-permissions.sh " .
			"$main::rlogfile"
		);

		print_status($rs, 'exit_on_error');
	}

	push_el(\@main::el, 'set_permissions()', 'Ending...');

	0;
}

################################################################################
# Starting services
#
# This subroutine start all serviced that are not marked as no in the main ispCP
# configuration file
#
sub start_services {

	push_el(\@main::el, 'start_services()', 'Starting...');

	for (
		qw/CMD_ISPCPN CMD_ISPCPD CMD_NAMED CMD_HTTPD CMD_FTPD CMD_MTA CMD_AUTHD
		CMD_POP CMD_POP_SSL CMD_IMAP CMD_IMAP_SSL/
	) {
		if( $main::cfg{$_} !~ /^no$/i && -e $main::cfg{$_}) {
			sys_command("$main::cfg{$_} start $main::rlogfile");
			progress();
		}
	}

	push_el(\@main::el, 'start_services()', 'Ending...');
}

################################################################################
# Stopping services
#
sub stop_services {

	push_el(\@main::el, 'stop_services()', 'Starting...');

	for (
		qw/CMD_ISPCPN CMD_ISPCPD CMD_NAMED CMD_HTTPD CMD_FTPD CMD_MTA CMD_AUTHD
		CMD_POP CMD_POP_SSL CMD_IMAP CMD_IMAP_SSL/
	) {
		if(-e $main::cfg{$_}) {
			sys_command("$main::cfg{$_} stop $main::rlogfile");
			progress();
		}
	}

	push_el(\@main::el, 'stop_services()', 'Ending...');
}

################################################################################
#                             Check subroutines                                #
################################################################################

################################################################################
# Check the format of an IpV4 address
#
# @param IpV4 address (dot-decimal notation)
#
sub check_eth {

	return 0 if(
		shift =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ &&
		($1 >  0) && ($1 <  255) && ($2 >= 0) && ($2 <= 255) &&
		($3 >= 0) && ($3 <= 255) && ($4 >  0) && ($4 <  255)
	);

	1;
}

################################################################################
# Check Sql connection
#
# This subroutine can be used to check an MySQL server connection with different
# login credentials.
#
# Note:
#
# This subroutine automatically restore the previous DSN at end.
#
# @param scalar $user SQL username
# @param scalar $password SQL user password
# @return int 0 on success, other on failure
#
sub check_sql_connection {

	push_el(\@main::el, 'sql_check_connections()', 'Starting...');

	my($userName, $password) = @_;

	if(!defined $userName && !defined $password) {
		push_el(
			\@main::el, 'sql_check_connections()',
			'[ERROR] Undefined login credential!'
		);

		return -1;
	}

	# Define the DSN
	@main::db_connect = ("DBI:mysql:$main::db_name:$main::db_host", $userName, $password);
	# We force reconnection to the database by removing the current
	$main::db = undef;

	push_el(
		\@main::el, 'sql_check_connections()',
		"Checking MySQL server connection with the following DSN: @main::db_connect"
	);

	# @todo really needed ?
	my($rs, $rdata) = doSQL('SHOW databases;');
	return $rs if ($rs != 0);

	# We force reconnection to the database by resetting the default DSN
	setup_main_vars();

	push_el(\@main::el, 'sql_check_connections()', 'Ending...');

	0;
}

################################################################################
##                             Utils subroutines                               #
################################################################################

################################################################################
# Get and return the fully qualified hostname
#
# @return mixed [0, string] on success, -1 on failure
sub get_sys_hostname {

	push_el(\@main::el, 'get_sys_hostname()', 'Starting...');

	chomp(my $hostname = `$main::cfg{'CMD_HOSTNAME'} -f`);
	return -1 if($? != 0);

	push_el(\@main::el, 'get_sys_hostname()', 'Ending...');

	return (0, $hostname);
}

################################################################################
# Convenience subroutine to print a title
#
# @param string title to be printed (without EOL)
#
sub title {
	my $title = shift;
	print STDOUT colored(['bold'], "\t$title\n");
}

################################################################################
# Convenience subroutine  to print a subtitle
#
# @param string subtitle to be printed (without EOL)
#
sub subtitle {
	my $subtitle = shift;
	print STDOUT "\t $subtitle";

	$main::dyn_length = 0 if(defined $main::dyn_length);
	$main::subtitle_length = length $subtitle;
}

################################################################################
# Convenience subroutine to insert a new line
#
sub spacer {
	print STDOUT "\n";
}

################################################################################
# Can be used in a loop to reflect the action progression
#
sub progress {
	print STDOUT '.';
	$main::dyn_length++;
}

################################################################################
# Print status string
#
# Note: Should be always called after the subtitle subroutine
#
# Param: int action status
# [Param: string If set to 'exit_on_error', the program will end up] if the exit
# status is a non-zero value
sub print_status {

	my ($status, $exitOnError) = @_;
	my $length = $main::subtitle_length;

	if(defined $main::dyn_length && $main::dyn_length != 0) {
		$length = $length+$main::dyn_length;
		$main::dyn_length = 0;
	}

	my ($termWidth) = GetTerminalSize();
	my $statusString = ($status == 0)
		? colored(['green'], 'Done') : colored(['red'], 'Failed');

	$statusString = sprintf('%'.($termWidth-($length+1)).'s', $statusString);

	print STDOUT colored(['bold'], "$statusString\n");

	if(defined $exitOnError && $exitOnError eq 'exit_on_error' && $status != 0) {
		exit_msg($status);
	}
}

################################################################################
# Exit with a message
#
# [param: int exit code] (default set to 1)
# [param: string optional user message]
#
sub exit_msg {

	push_el(\@main::el, 'exit_msg()', 'Starting...');

	my ($exitCode, $userMsg) = @_;
	my $msg = '';

	if (!defined $exitCode) {
		$exitCode = 1;
	}

	if($exitCode != 0) {
		my $context = defined &setup_engine ? 'setup' : 'update';

		$msg = "\n\t" . colored(['red bold'], '[FATAL] ')  .
			"An error occurred during $context process!\n" .
			"\tCorrect it and re-run this program." .
			"\n\n\tYou can find help at http://isp-control.net/forum\n\n";
	}

	if(defined $userMsg && $userMsg ne '') {
		$msg = "\n\t$userMsg\n" . $msg;
	}

	print STDERR $msg;

	push_el(\@main::el, 'exit_msg()', 'Ending...');

	exit $exitCode;
}

################################################################################
#                             Hooks subroutines                                #
################################################################################

# Common behavior for the preinst and postinst scripts
#
# The main script will only end if the  maintainer scripts ends with an exit
# status equal to 2.
#

################################################################################
# Implements the hook for the maintainers pre-installation scripts
#
# Hook that can be used by distribution maintainers to perform any required
# tasks before that the actions of the main process are executed. This hook
# allow to add a specific script named `preinst` that will be run before the
# both setup and update process actions. This hook is automatically called after
# that all services are shutting down.
#
# Note:
#
#  The `preinst` script can be written in PERL, PHP or SHELL (POSIX compliant),
#  and must be copied in the engine/setup directory during the make process. A
#  shared library for the scripts that are written in SHELL is available in the
#  engine/setup directory.
#
# @param mixed Argument that will be be passed to the maintainer script
#
sub preinst {

	push_el(\@main::el, 'preinst()', 'Starting...');

	my $task = shift;
	my $mime_type = mimetype("$main::cfg{'ROOT_DIR'}/engine/setup/preinst");

	($mime_type =~ /(shell|perl|php)/) ||
		exit_msg(
			1, '[err] Unable to determine the mimetype of the `preinst` script!'
		);

	my $rs = sys_command_rs("$main::cfg{'CMD_'.uc($1)} preinst $task");
	return $rs if($rs != 0);

	push_el(\@main::el, 'preinst()', 'Ending...');

	0;
}

################################################################################
# Implements the hook for the maintainers post-installation scripts
#
# Hook that can be used by distribution maintainers to perform any required
# tasks after that the actions of the main process are executed. This hook
# allow to add a specific script named `postinst` that will be run after the
# both setup and update process actions. This hook is automatically called
# before the set_permissions() subroutine call and so, before that all services
# are restarting.
#
# Note:
#
#  The `postinst` script can be written in PERL, PHP or SHELL (POSIX compliant),
#  and must be copied in the engine/setup directory during the make process. A
#  shared library for the scripts that are written in SHELL is available in the
#  engine/setup directory.
#
# @param mixed Argument that will be be passed to the maintainer script
#
sub postinst {

	push_el(\@main::el, 'postinst()', 'Starting...');

	my $task = shift;
	my $mime_type = mimetype("$main::cfg{'ROOT_DIR'}/engine/setup/postinst");

	($mime_type =~ /(shell|perl|php)/) ||
		exit_msg(
			1, '[err] Unable to determine the mimetype of the `postinst` script!'
		);

	my $rs = sys_command_rs("$main::cfg{'CMD_'.uc($1)} postinst $task");
	return $rs if($rs != 0);

	push_el(\@main::el, 'postinst()', 'Ending...');

	0;
}

1;
