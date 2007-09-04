#!/usr/bin/perl

# ispCP ω (OMEGA) a Virtual Hosting Control Panel
# Copyright (c) 2001-2004 by moleSoftware GmbH
# Copyright (c) 2007 by isp Control Panel
# http://isp-control.net
#
# License:
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
#  On Debian systems, the complete text of the GNU Lesser General
#  Public License can be found in `/usr/share/common-licenses/LGPL'.
#
#
# The ispCP ω Home Page is at:
#
#    http://isp-control.net



use FindBin;
use lib "$FindBin::Bin/:/var/www/vhcs2/engine:/srv/www/vhcs2/engine";
require 'vhcs2_common_code.pl';

use strict;

use warnings;

%main::ua = ();

sub welcome_note {

    push_el(\@main::el, 'welcome_note()', 'Starting...');

    my $welcome_message = <<MSG;

    Welcome to the VHCS2 '$main::cfg{'VersionH'}' Uninstall Program.

    This program will uninstall the VHCS configurations from your server.
    All domain users and their accounts won't be removed.

    Press 'Enter' to continue.
MSG

    print STDOUT $welcome_message;

    readline(\*STDIN);

    push_el(\@main::el, 'welcome_note()', 'Ending...');

}

sub user_dialog {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'user_dialog()', 'Starting...');

    $rs = welcome_note();

    return $rs if ($rs != 0);

    return 0;

}

sub uninstall_start_up {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_start_up()', 'Starting...');

    # config check;

    $rs = get_conf();

    return $rs if ($rs != 0);

    push_el(\@main::el, 'uninstall_start_up()', 'Ending...');

    return 0;

}

sub uninstall_shut_down {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_shut_down()', 'Starting...');

    $rs = del_file("/tmp/vhcs2-uninstall-services.log");

    return $rs if ($rs != 0);

    my $shut_down_message = <<MSG;

    Congratulations !

    VHCS2 '$main::cfg{'VersionH'}' uninstall completed successfully !

    Thank you for using our product !

MSG

    print STDOUT $shut_down_message;

    push_el(\@main::el, 'uninstall_shut_down()', 'Ending...');

    return 0;

}

sub uninstall_system_dirs {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_system_dirs()', 'Starting...');

    $rs = del_dir($main::cfg{'APACHE_BACKUP_LOG_DIR'});

    return $rs if ($rs != 0);

    $rs = del_dir($main::cfg{'MTA_VIRTUAL_CONF_DIR'});

    return $rs if ($rs != 0);

    $rs = del_dir($main::cfg{'LOG_DIR'});

    return $rs if ($rs != 0);

    push_el(\@main::el, 'uninstall_system_dirs()', 'Ending...');

    return 0;

}

sub uninstall_crontab {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_crontab()', 'Starting...');

    my $cfg_dir = "$main::cfg{'CONF_DIR'}/crontab";

    my $bk_dir = "$cfg_dir/backup";

    my $wrk_dir = "$cfg_dir/working";

    my ($cfg_tpl, $cfg, $cmd) = (undef, undef, undef);


    $cmd = "$main::cfg{'CMD_CRONTAB'} -u root -r &> /tmp/vhcs2-uninstall-crontab.log";

    $rs = sys_command_rs($cmd);

    $rs = del_file("/tmp/vhcs2-uninstall-crontab.log");

    return $rs if ($rs != 0);

    if (-e "$bk_dir/crontab.conf.system") { # We are running uninstall for the first time.

        ($rs, $rdata) = get_file("$bk_dir/crontab.conf.system");

        return $rs if ($rs != 0);

        if ($rdata !~ /no crontab/) {

            $cmd = "$main::cfg{'CMD_CRONTAB'} -u root $bk_dir/crontab.conf.system";

            $rs = sys_command_rs($cmd);

        }

        $rs = del_file("$bk_dir/crontab.conf.system");

        return $rs if ($rs != 0);

    }

    push_el(\@main::el, 'uninstall_crontab()', 'Ending...');

    return 0;

}

sub uninstall_named {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_named()', 'Starting...');

    my $cfg_dir = "$main::cfg{'CONF_DIR'}/bind";

    my $bk_dir = "$cfg_dir/backup";

    my $wrk_dir = "$cfg_dir/working";

    my ($cfg_tpl, $cfg, $cmd) = (undef, undef, undef);

    sys_command_rs("$main::cfg{'CMD_NAMED'} stop &> /tmp/vhcs2-uninstall-services.log");

    if (-e "$bk_dir/named.conf.system") {

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/named.conf.system $main::cfg{'BIND_CONF_FILE'}";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/named.conf.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/named.conf.vhcs2");

        return $rs if ($rs != 0);


    }

    push_el(\@main::el, 'uninstall_named()', 'Ending...');

    return 0;

}

sub uninstall_httpd {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_httpd()', 'Starting...');

    my $cfg_dir = "$main::cfg{'CONF_DIR'}/apache";

    my $bk_dir = "$cfg_dir/backup";

    my $wrk_dir = "$cfg_dir/working";

    my ($cfg_tpl, $cfg, $cmd) = (undef, undef, undef);

    sys_command_rs("$main::cfg{'CMD_HTTPD'} stop &> /tmp/vhcs2-uninstall-services.log");

    $rs = del_file($main::cfg{'APACHE_CONF_FILE'});

    return $rs if ($rs != 0);

    push_el(\@main::el, 'uninstall_httpd()', 'Ending...');

    return 0;

}

sub uninstall_mta {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_mta()', 'Starting...');

    my $cfg_dir = "$main::cfg{'CONF_DIR'}/postfix";

    my $bk_dir = "$cfg_dir/backup";

    my $wrk_dir = "$cfg_dir/working";

    my $vrl_dir = "$cfg_dir/vhcs2";

    my ($cfg_tpl, $cfg, $cmd) = (undef, undef, undef);

    sys_command_rs("$main::cfg{'CMD_MTA'} stop &> /tmp/vhcs2-uninstall-services.log");

    if (-e "$bk_dir/main.cf.system") {

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/main.cf.system $main::cfg{'POSTFIX_CONF_FILE'}";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/master.cf.system $main::cfg{'POSTFIX_MASTER_CONF_FILE'}";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/main.cf.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/master.cf.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/main.cf.vhcs2");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/master.cf.vhcs2");

        return $rs if ($rs != 0);

    }

    $rs = sys_command("$main::cfg{'CMD_NEWALIASES'} &> /tmp/vhcs2-uninstall-services.log");

    return $rs if ($rs != 0);

    push_el(\@main::el, 'uninstall_mta()', 'Ending...');

    return 0;

}

sub uninstall_po {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_po()', 'Starting...');

    my $cfg_dir = "$main::cfg{'CONF_DIR'}/courier";

    my $bk_dir = "$cfg_dir/backup";

    my $wrk_dir = "$cfg_dir/working";

    my ($cfg_tpl, $cfg, $cmd) = (undef, undef, undef);

    sys_command_rs("$main::cfg{'CMD_AUTHD'} stop &> /tmp/vhcs2-uninstall-services.log");

    sys_command_rs("$main::cfg{'CMD_IMAP'} stop &> /tmp/vhcs2-uninstall-services.log");

    sys_command_rs("$main::cfg{'CMD_POP'} stop &> /tmp/vhcs2-uninstall-services.log");

    if (-e "$bk_dir/imapd.system") {


        # Let's backup system configs;


        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/imapd.system $main::cfg{'COURIER_CONF_DIR'}/imapd";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/pop3d.system $main::cfg{'COURIER_CONF_DIR'}/pop3d";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

	if (exists $main::cfg{'AUTHLIB_CONF_DIR'} && $main::cfg{'AUTHLIB_CONF_DIR'}) {

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/authdaemonrc.system $main::cfg{'AUTHLIB_CONF_DIR'}/authdaemonrc";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/authmodulelist.system $main::cfg{'AUTHLIB_CONF_DIR'}/authmodulelist";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

	if (-e "$bk_dir/userdb.system") {

    	    $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/userdb.system $main::cfg{'AUTHLIB_CONF_DIR'}/userdb";

    	    $rs = sys_command($cmd);

	}

	} else {

	$cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/authdaemonrc.system $main::cfg{'COURIER_CONF_DIR'}/authdaemonrc";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/authmodulelist.system $main::cfg{'COURIER_CONF_DIR'}/authmodulelist";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        if (-e "$bk_dir/userdb.system") {

            $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/userdb.system $main::cfg{'COURIER_CONF_DIR'}/userdb";

            $rs = sys_command($cmd);

        }

	}

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/imapd.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/pop3d.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/authdaemonrc.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/authmodulelist.system");

        return $rs if ($rs != 0);

	if (-e "$bk_dir/userdb.system") {

    	    $rs = del_file("$bk_dir/userdb.system");

    	    return $rs if ($rs != 0);

	}

        $rs = del_file("$bk_dir/imapd.vhcs2");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/pop3d.vhcs2");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/authdaemonrc.vhcs2");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/authmodulelist.vhcs2");

        return $rs if ($rs != 0);

    }

    $rs = sys_command($main::cfg{'CMD_MAKEUSERDB'});

    return $rs if ($rs != 0);

    push_el(\@main::el, 'uninstall_po()', 'Ending...');

    return 0;

}

sub uninstall_ftpd {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_ftpd()', 'Starting...');

    my $cfg_dir = "$main::cfg{'CONF_DIR'}/proftpd";

    my $bk_dir = "$cfg_dir/backup";

    my ($cfg_tpl, $cfg, $cmd) = (undef, undef, undef);

    sys_command_rs("$main::cfg{'CMD_FTPD'} stop &> /tmp/vhcs2-uninstall-services.log");

    if (-e "$bk_dir/proftpd.conf.system") {

        $cmd = "$main::cfg{'CMD_CP'} -p $bk_dir/proftpd.conf.system $main::cfg{'FTPD_CONF_FILE'}";

        $rs = sys_command($cmd);

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/proftpd.conf.system");

        return $rs if ($rs != 0);

        $rs = del_file("$bk_dir/proftpd.conf.vhcs2");

        return $rs if ($rs != 0);

    }

    push_el(\@main::el, 'uninstall_ftpd()', 'Ending...');

    return 0;

}

sub uninstall_vhcs2d {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_vhcs2d()', 'Starting...');

    sys_command_rs("$main::cfg{'CMD_VHCS2D'} stop &> /tmp/vhcs2-uninstall-services.log");

    del_file("$main::cfg{'CMD_VHCS2D'}");

     if ( -e "/usr/sbin/update-rc.d" ) {

		sys_command_rs("/usr/sbin/update-rc.d vhcs2_daemon remove &> /tmp/vhcs2-uninstall-services.log");

	}

    push_el(\@main::el, 'uninstall_vhcs2d()', 'Ending...');

    return 0;

}

sub uninstall_host_system {

    my ($rs, $rdata) = (undef, undef);

    push_el(\@main::el, 'uninstall_host_system()', 'Starting...');

    $rs = uninstall_system_dirs();

    return $rs if ($rs != 0);

    $rs = uninstall_crontab();

    return $rs if ($rs != 0);

    $rs = uninstall_httpd();

    return $rs if ($rs != 0);

    $rs = uninstall_mta();

    return $rs if ($rs != 0);

    $rs = uninstall_po();

    return $rs if ($rs != 0);

    $rs = uninstall_ftpd();

    return $rs if ($rs != 0);

    $rs = uninstall_named();

    return $rs if ($rs != 0);

    $rs = uninstall_vhcs2d();

    return $rs if ($rs != 0);

    push_el(\@main::el, 'uninstall_host_system()', 'Ending...');

    return 0;

}

my $rs = undef;

$rs = uninstall_start_up();

if ($rs != 0) {

    my $el_data = pop_el(\@main::el);

    my ($sub_name, $msg) = split(/$main::el_sep/, $el_data);

    print STDERR "$msg\n";

    exit 1;

}

$rs = user_dialog();

if ($rs != 0) {

    my $el_data = pop_el(\@main::el);

    my ($sub_name, $msg) = split(/$main::el_sep/, $el_data);

    print STDERR "$msg\n";

    exit 1;

}

$rs = uninstall_host_system();

if ($rs != 0) {

    my $el_data = pop_el(\@main::el);

    my ($sub_name, $msg) = split(/$main::el_sep/, $el_data);

    print STDERR "$msg\n";

    exit 1;

}

$rs = uninstall_shut_down();

if ($rs != 0) {

    my $el_data = pop_el(\@main::el);

    my ($sub_name, $msg) = split(/$main::el_sep/, $el_data);

    print STDERR "$msg\n";

    exit 1;

}

