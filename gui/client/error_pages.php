<?php
/**
 * ispCP ω (OMEGA) a Virtual Hosting Control System
 *
 * @copyright 	2001-2006 by moleSoftware GmbH
 * @copyright 	2006-2011 by ispCP | http://isp-control.net
 * @version 	SVN: $Id$
 * @link 		http://isp-control.net
 * @author 		ispCP Team
 *
 * @license
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * The Original Code is "VHCS - Virtual Hosting Control System".
 *
 * The Initial Developer of the Original Code is moleSoftware GmbH.
 * Portions created by Initial Developer are Copyright (C) 2001-2006
 * by moleSoftware GmbH. All Rights Reserved.
 * Portions created by the ispCP Team are Copyright (C) 2006-2011 by
 * isp Control Panel. All Rights Reserved.
 */

require '../include/ispcp-lib.php';

check_login(__FILE__);

$cfg = ispCP_Registry::get('Config');

$tpl = ispCP_TemplateEngine::getInstance();
$template = 'error_pages.tpl';

// common page data.

$domain = $_SESSION['user_logged'];
$domain = "http://www." . $domain;

// dynamic page data.

update_error_page($sql);

// static page messages.
gen_logged_from($tpl);
check_permissions($tpl);

$tpl->assign(
	array(
		'TR_PAGE_TITLE'		=> tr('ispCP - Client/Manage Error Custom Pages'),
		'DOMAIN'			=> $domain,
		'TR_ERROR_401'		=> tr('Error 401 (unauthorised)'),
		'TR_ERROR_403'		=> tr('Error 403 (forbidden)'),
		'TR_ERROR_404'		=> tr('Error 404 (not found)'),
		'TR_ERROR_500'		=> tr('Error 500 (internal server error)'),
		'TR_ERROR_503'		=> tr('Error 503 (service unavailable)'),
		'TR_ERROR_PAGES'	=> tr('Error pages'),
		'TR_EDIT'			=> tr('Edit'),
		'TR_VIEW'			=> tr('View')
	)
);

gen_client_mainmenu($tpl, 'main_menu_webtools.tpl');
gen_client_menu($tpl, 'menu_webtools.tpl');

gen_page_message($tpl);

if ($cfg->DUMP_GUI_DEBUG) {
	dump_gui_debug($tpl);
}

$tpl->display($template);

unset_messages();

// page functions.

function write_error_page($sql, $eid) {

	$error = $_POST['error'];
	$file = '/errors/' . $eid . '.html';
	$vfs = new ispCP_VirtualFileSystem($_SESSION['user_logged'], $sql);

	return $vfs->put($file, $error);
}

function update_error_page($sql) {

	if (isset($_POST['uaction']) && $_POST['uaction'] === 'updt_error') {
		$eid = intval($_POST['eid']);

		if (in_array($eid, array(401, 402, 403, 404, 500, 503))
			&& write_error_page($sql, $eid)) {
			set_page_message(tr('Custom error page was updated!'), 'success');
		} else {
			set_page_message(
				tr('System error - custom error page was NOT updated!'),
				'error'
			);
		}
	}
}
?>