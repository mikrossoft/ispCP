<?php
/**
 * ispCP ω (OMEGA) a Virtual Hosting Control System
 *
 * @copyright	2001-2006 by moleSoftware GmbH
 * @copyright	2006-2009 by ispCP | http://isp-control.net
 * @version		SVN: $Id$
 * @link		http://isp-control.net
 * @author		ispCP Team
 *
 * @license
 *   This program is free software; you can redistribute it and/or modify it under
 *   the terms of the MPL General Public License as published by the Free Software
 *   Foundation; either version 1.1 of the License, or (at your option) any later
 *   version.
 *   You should have received a copy of the MPL Mozilla Public License along with
 *   this program; if not, write to the Open Source Initiative (OSI)
 *   http://opensource.org | osi@opensource.org
 */

require '../include/ispcp-lib.php';

check_login(__FILE__);

$tpl = new pTemplate();
$tpl->define_dynamic('page', Config::get('CLIENT_TEMPLATE_PATH') . '/protected_areas.tpl');
$tpl->define_dynamic('page_message', 'page');
$tpl->define_dynamic('logged_from', 'page');
$tpl->define_dynamic('dir_item', 'page');
$tpl->define_dynamic('action_link', 'page');
$tpl->define_dynamic('protected_areas', 'page');

$theme_color = Config::get('USER_INITIAL_THEME');

$tpl->assign(
	array(
		'TR_CLIENT_WEBTOOLS_PAGE_TITLE' => tr('ispCP - Client/Webtools'),
		'THEME_COLOR_PATH' => "../themes/$theme_color",
		'THEME_CHARSET' => tr('encoding'),
		'ISP_LOGO' => get_logo($_SESSION['user_id'])
	)
);

function gen_htaccess_entries(&$tpl, &$sql, &$dmn_id) {
	$query = <<<SQL_QUERY
		SELECT
			*
		FROM
			`htaccess`
		WHERE
			`dmn_id` = ?
SQL_QUERY;

	$rs = exec_query($sql, $query, array($dmn_id));

	if ($rs->RecordCount() == 0) {
		$tpl->assign('PROTECTED_AREAS', '');
		set_page_message(tr('You do not have protected areas'));
	} else {
		$counter = 0;
		while (!$rs->EOF) {
			$tpl->assign('CLASS', ($counter % 2 == 0) ? 'content' : 'content2');

			$id = $rs->fields['id'];
			$user_id = $rs->fields['user_id'];
			$group_id = $rs->fields['group_id'];
			$status = $rs->fields['status'];
			$path = $rs->fields['path'];
			$auth_name = $rs->fields['auth_name'];

			$tpl->assign(
				array(
					'AREA_NAME' => $auth_name,
					'JS_AREA_NAME' => addslashes(strip_tags($auth_name)),
					'AREA_PATH' => $path,
					'PID' => $id,
					'STATUS' => translate_dmn_status($status)
				)
			);
			$tpl->parse('DIR_ITEM', '.dir_item');
			$rs->MoveNext();
			$counter++;
		}
	}
}

/*
 *
 * static page messages.
 *
 */

gen_client_mainmenu($tpl, Config::get('CLIENT_TEMPLATE_PATH') . '/main_menu_webtools.tpl');
gen_client_menu($tpl, Config::get('CLIENT_TEMPLATE_PATH') . '/menu_webtools.tpl');

gen_logged_from($tpl);

check_permissions($tpl);

$dmn_id = get_user_domain_id($sql, $_SESSION['user_id']);

gen_htaccess_entries($tpl, $sql, $dmn_id);

$tpl->assign(
	array(
		'TR_HTACCESS' => tr('Protected areas'),
		'TR_DIRECTORY_TREE' => tr('Directory tree'),
		'TR_DIRS' => tr('Name'),
		'TR__ACTION' => tr('Action'),
		'TR_MANAGE_USRES' => tr('Manage users and groups'),
		'TR_USERS' => tr('User'),
		'TR_USERNAME' => tr('Username'),
		'TR_ADD_USER' => tr('Add user'),
		'TR_GROUPNAME' => tr('Group name'),
		'TR_GROUP_MEMBERS' => tr('Group members'),
		'TR_ADD_GROUP' => tr('Add group'),
		'TR_EDIT' => tr('Edit'),
		'TR_GROUP' => tr('Group'),
		'TR_DELETE' => tr('Delete'),
		'TR_MESSAGE_DELETE' => tr('Are you sure you want to delete %s?', true, '%s'),
		'TR_STATUS' => tr('Status'),
		'TR_ADD_AREA' => tr('Add new protected area')
	)
);

gen_page_message($tpl);

$tpl->parse('PAGE', 'page');
$tpl->prnt();

if (Config::get('DUMP_GUI_DEBUG')) {
	dump_gui_debug();
}
unset_messages();