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

$template = 'alias.tpl';

// static page messages
gen_logged_from($tpl);

$err_txt = "_off_";

generate_als_list($tpl, $_SESSION['user_id'], $err_txt);

generate_als_messages($tpl, $err_txt);

$tpl->assign(
	array(
		'TR_PAGE_TITLE'	=> tr('ispCP - Manage Domain/Alias'),
		'TR_MANAGE_ALIAS'	=> tr('Manage alias'),
		'TR_NAME'			=> tr('Name'),
		'TR_REAL_DOMAIN'	=> tr('Real domain'),
		'TR_FORWARD'		=> tr('Forward'),
		'TR_STATUS'			=> tr('Status'),
		'TR_ACTION'			=> tr('Action'),
		'TR_ADD_ALIAS'		=> tr('Add alias'),
		'TR_MESSAGE_DELETE'	=> tr('Are you sure you want to delete %s?', true, '%s')
	)
);

gen_reseller_mainmenu($tpl, 'main_menu_users_manage.tpl');
gen_reseller_menu($tpl, 'menu_users_manage.tpl');

if ($cfg->DUMP_GUI_DEBUG) {
	dump_gui_debug($tpl);
}

$tpl->display($template);

unset_messages();

// Function declaration

/**
 * Generate domain alias list
 *
 * @todo Use prepared statements (min. with placeholders like ":search_for")
 * @param ispCP_TemplateEngine $tpl
 * @param int $reseller_id
 * @param string $als_err
 */
function generate_als_list($tpl, $reseller_id, &$als_err) {
	$sql = ispCP_Registry::get('Db');
	$cfg = ispCP_Registry::get('Config');

	list(,,,,,,$uals_current) = generate_reseller_user_props($reseller_id);
	list(,,,,,$rals_max) = get_reseller_default_props($sql, $reseller_id);

	if ($uals_current >= $rals_max && $rals_max != "0") {
		$tpl->assign('ALS_ADD_BUTTON', '');
	}

	$start_index = 0;

	$rows_per_page = $cfg->DOMAIN_ROWS_PER_PAGE;

	$current_psi = 0;
	$_SESSION['search_for'] = '';
	$search_common = '';
	$search_for = '';

	if (isset($_GET['psi'])) {
		$start_index = $_GET['psi'];
		$current_psi = $_GET['psi'];
	}

	if (isset($_POST['uaction']) && !empty($_POST['uaction'])) {

		$_SESSION['search_for'] = trim(clean_input($_POST['search_for']));
		$_SESSION['search_common'] = $_POST['search_common'];
		$search_for = $_SESSION['search_for'];
		$search_common = $_SESSION['search_common'];

	} else {

		if (isset($_SESSION['search_for']) && !isset($_GET['psi'])) {
			unset($_SESSION['search_for']);
			unset($_SESSION['search_common']);
		}
	}
	$tpl->assign(
		array(
			'PSI'				=> $current_psi,
			'SEARCH_FOR'		=> tohtml($search_for),
			'TR_SEARCH'			=> tr('Search'),
			'M_ALIAS_NAME'		=> tr('Alias name'),
			'M_ACCOUNT_NAME'	=> tr('Account name'),
		)
	);

	if (isset($_SESSION['search_for']) && $_SESSION['search_for'] != '') {
		if (isset($search_common) && $search_common == 'alias_name') {
			$query = "
				SELECT
					t1.*,
					t2.`domain_id`,
					t2.`domain_name`,
					t2.`domain_created_id`
				FROM
					`domain_aliasses` AS t1,
					`domain` AS t2
				WHERE
					`alias_name` RLIKE '$search_for'
				AND
					t2.`domain_created_id` = ?
				AND
					t1.`domain_id` = t2.`domain_id`
				ORDER BY
					t1.`alias_name` ASC
				LIMIT
					$start_index, $rows_per_page
			";
			// count query
			$count_query = "
				SELECT
					COUNT(`alias_id`) AS cnt
				FROM
					`domain_aliasses` AS t1,
					`domain` AS t2
				WHERE
					t2.`domain_created_id` = ?
				AND
					`alias_name` RLIKE '$search_for'
				AND
					t1.`domain_id` = t2.`domain_id`
			";
		} else {
			$query = "
				SELECT
					t1.*,
					t2.`domain_id`,
					t2.`domain_name`,
					t2.`domain_created_id`
				FROM
					`domain_aliasses` AS t1,
					`domain` AS t2
				WHERE
					t2.`domain_name` RLIKE '$search_for'
				AND
					t1.`domain_id` = t2.`domain_id`
				AND
					t2.`domain_created_id` = ?
				ORDER BY
					t1.`alias_name` ASC
				LIMIT
					$start_index, $rows_per_page
			";
			// count query
			$count_query = "
				SELECT
					COUNT(`alias_id`) AS cnt
				FROM
					`domain_aliasses` AS t1,
					`domain` AS t2
				WHERE
					t2.`domain_created_id` = ?
				AND
					t2.`domain_name` RLIKE '$search_for'
				AND
					t1.`domain_id` = t2.`domain_id`
			";
		}
	} else {
		$query = "
			SELECT
				t1.*,
				t2.`domain_id`,
				t2.`domain_name`,
				t2.`domain_created_id`
			FROM
				`domain_aliasses` AS t1,
				`domain` AS t2
			WHERE
				t1.`domain_id` = t2.`domain_id`
			AND
				t2.`domain_created_id` = ?
			ORDER BY
				t1.`alias_name` ASC
			LIMIT
				$start_index, $rows_per_page
		";
		// count query
		$count_query = "
			SELECT
				COUNT(`alias_id`) AS cnt
			FROM
				`domain_aliasses` AS t1,
				`domain` AS t2
			WHERE
				t1.`domain_id` = t2.domain_id
			AND
				t2.`domain_created_id` = ?
		";
	}
	// let's count
	$rs = exec_query($sql, $count_query, $reseller_id);
	$records_count = $rs->fields['cnt'];
	// Get all alias records
	$rs = exec_query($sql, $query, $reseller_id);

	if ($records_count == 0) {
		if (isset($_SESSION['search_for']) && $_SESSION['search_for'] != '') {
			$tpl->assign(
				array(
					'TABLE_LIST'				=> '',
					'USERS_LIST'				=> '',
					'SCROLL_PREV'				=> '',
					'SCROLL_NEXT'				=> '',
					'M_DOMAIN_NAME_SELECTED'	=> '',
					'M_ACCOUN_NAME_SELECTED'	=> ''
				)
			);
		} else {
			$tpl->assign(
				array(
					'TABLE_LIST'	=> '',
					'TABLE_HEADER'	=> '',
					'USERS_LIST'	=> '',
					'SCROLL_PREV'	=> '',
					'SCROLL_NEXT'	=> '',
				)
			);
		}

		if (isset($_SESSION['search_for'])) {
			$als_err = tr('Not found user records matching the search criteria!');
		} else {
			if (isset($_SESSION['almax'])) {
				if ($_SESSION['almax'] === '_yes_')
					$als_err = tr('Domain alias limit reached!');
				else
					$als_err = tr('You have no alias records.');

				unset($_SESSION['almax']);
			} else {
				$als_err = tr('You have no alias records.');
			}
		}
		return;
	} else {
		$prev_si = $start_index - $rows_per_page;

		if ($start_index == 0) {
			$tpl->assign('SCROLL_PREV', '');
		} else {
			$tpl->assign(
				array(
					'SCROLL_PREV_GRAY'	=> '',
					'PREV_PSI'			=> $prev_si
				)
			);
		}

		$next_si = $start_index + $rows_per_page;

		if ($next_si + 1 > $records_count) {
			$tpl->assign('SCROLL_NEXT', '');
		} else {
			$tpl->assign(
				array(
					'SCROLL_NEXT_GRAY'	=> '',
					'NEXT_PSI'			=> $next_si
				)
			);
		}
	}

	while (!$rs->EOF) {
		$als_id = $rs->fields['alias_id'];
		$als_name = $rs->fields['alias_name'];
		$als_mount_point = ($rs->fields['alias_mount'] != '')
			? $rs->fields['alias_mount']
			: '/';
		$als_status = $rs->fields['alias_status'];
		$als_ip_id = $rs->fields['alias_ip_id'];
		$als_fwd = $rs->fields['url_forward'];
		$show_als_fwd = ($als_fwd == 'no') ? "-" : $als_fwd;

		$domain_name = decode_idna($rs->fields['domain_name']);

		$query = "SELECT `ip_number`, `ip_domain` FROM `server_ips` WHERE `ip_id` = ?";

		$alsip_r = exec_query($sql, $query, $als_ip_id);
		$alsip_d = $alsip_r->fetchRow();

		$als_ip = $alsip_d['ip_number'];
		$als_ip_name = $alsip_d['ip_domain'];

		if ($als_status === $cfg->ITEM_OK_STATUS) {
			$delete_link = "alias_delete.php?del_id=" . $als_id;
			$edit_link = "alias_edit.php?edit_id=" . $als_id;
			$action_text = tr("Delete");
			$edit_text = tr("Edit");
		} else if ($als_status === $cfg->ITEM_ORDERED_STATUS) {
			$delete_link = "alias_order.php?action=delete&del_id=".$als_id;
			$edit_link = "alias_order.php?action=activate&act_id=".$als_id;
			$action_text = tr("Delete order");
			$edit_text = tr("Activate");
		} else {
			$delete_link = "#";
			$edit_link = "#";
			$action_text = tr('N/A');
			$edit_text = tr('N/A');
		}
		$als_status = translate_dmn_status($als_status);
		$als_name = decode_idna($als_name);
		$show_als_fwd = decode_idna($show_als_fwd);

		if (isset($_SESSION['search_common'])
			&& $_SESSION['search_common'] === 'account_name') {
			$domain_name_selected = '';
			$account_name_selected = $cfg->HTML_SELECTED;
		} else {
			$domain_name_selected = $cfg->HTML_SELECTED;
			$account_name_selected = '';
		}

		$tpl->append(
			array(
				'NAME'						=> tohtml($als_name),
				'ALIAS_IP'					=> tohtml("$als_ip ($als_ip_name)"),
				'REAL_DOMAIN'				=> tohtml($domain_name),
				'REAL_DOMAIN_MOUNT'			=> tohtml($als_mount_point),
				'FORWARD'					=> tohtml($show_als_fwd),
				'STATUS'					=> $als_status,
				'ID'						=> $als_id,
				'DELETE'					=> $action_text,
				'DELETE_LINK'				=> $delete_link,
				'EDIT_LINK'					=> $edit_link,
				'EDIT'						=> $edit_text,
				'M_DOMAIN_NAME_SELECTED'	=> $domain_name_selected,
				'M_ACCOUN_NAME_SELECTED'	=> $account_name_selected,
			)
		);

		$rs->moveNext();
	}
} // End of generate_als_list()

/**
 * @param ispCP_TemplateEngine $tpl
 * @param string $als_err
 */
function generate_als_messages($tpl, $als_err) {
	if ($als_err != '_off_') {
		$tpl->assign(
			array('MESSAGE' => $als_err)
		);
		return;
	} else if (isset($_SESSION["dahavemail"])) {
		$tpl->assign('MESSAGE', tr('Domain alias you are trying to remove has email accounts !<br>First remove them!'));
		unset($_SESSION['dahavemail']);
	} else if (isset($_SESSION["dahaveftp"])) {
		$tpl->assign('MESSAGE', tr('Domain alias you are trying to remove has FTP accounts!<br>First remove them!'));
		unset($_SESSION['dahavemail']);
	} else if (isset($_SESSION["aldel"])) {
		if ('_yes_' === $_SESSION['aldel'])
			$tpl->assign('MESSAGE', tr('Domain alias added for termination!'));
		else
			$tpl->assign('MESSAGE', tr('Domain alias not added for termination!'));

		unset($_SESSION['aldel']);
	} else if (isset($_SESSION['aladd'])) {
		if ('_yes_' === $_SESSION['aladd'])
			$tpl->assign('MESSAGE', tr('Domain alias added!'));
		else
			$tpl->assign('MESSAGE', tr('Domain alias not added!'));

		unset($_SESSION['aladd']);
	} else if (isset($_SESSION['aledit'])) {
		if ('_yes_' === $_SESSION['aledit'])
			$tpl->assign('MESSAGE', tr('Domain alias modified!'));
		else
			$tpl->assign('MESSAGE', tr('Domain alias not modified!'));

		unset($_SESSION['aledit']);
	} else if (isset($_SESSION['orderaldel'])) {
		if ('_no_' === $_SESSION['orderaldel']) {
			$tpl->assign('MESSAGE', tr('Ordered domain alias not deleted!'));
		}
		unset($_SESSION['orderaldel']);
	} else if (isset($_SESSION['orderalact'])) {
		if ('_yes_' === $_SESSION['orderalact'])
			$tpl->assign('MESSAGE', tr('Ordered domain alias activated!'));
		else
			$tpl->assign('MESSAGE', tr('Ordered domain alias not activated!'));

		unset($_SESSION['orderalact']);
	} else if (isset($_SESSION['almax'])) {
		if ('_yes_' === $_SESSION['almax'])
			$tpl->assign('MESSAGE', tr('Domain alias limit reached!'));
		else
			$tpl->assign('MESSAGE', '');

		unset($_SESSION['almax']);
	} else {
		$tpl->assign('MESSAGE', '');
		$tpl->assign('PAGE_MESSAGE', "");
	}
} // End of generate_als_messages()
