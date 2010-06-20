<?php
/**
 * ispCP ω (OMEGA) a Virtual Hosting Control System
 *
 * @copyright 	2001-2006 by moleSoftware GmbH
 * @copyright 	2006-2010 by ispCP | http://isp-control.net
 * @version 	SVN: $Id$
 * @link 		http://isp-control.net
 * @author 		Laurent Declercq (nuxwin) <laurent.declercq@ispcp.net>
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
 * The Original Code is "ispCP - ISP Control Panel".
 *
 * The Initial Developer of the Original Code is ispCP Team.
 * Portions created by Initial Developer are Copyright (C) 2006-2010 by
 * isp Control Panel. All Rights Reserved.
 */

defined('INCLUDEPATH') or define('INCLUDEPATH', dirname(dirname(__FILE__)));

/**
 * Bootstrap class for ispCP
 *
 * This class provide a very small program to boot ispCP
 *
 * Note: Will be improved later
 *
 * @since 1.0.6
 * @version 1.0.2
 * @author Laurent Declercq (nuxwin) <laurent.declercq@ispcp.net>
 */
class ispCP_Bootstrap {

	/**
	 * Boot ispCP environment and, configuration
	 *
	 * @throws ispCP_Exception
	 * @return void
	 */
	public static function boot() {

		if(!self::_isBooted()) {
			$boot = new self;
			$boot->_run();
		} else {
			throw new ispCP_Exception('Error: ispCP is already booted!');
		}
	}

	/**
	 * Shouldn't be instanciated directly
	 *
	 * @return void
	 */
	private function __construct() {}

	/**
	 * This class shouldn't be cloned
	 *
	 * @return void
	 */
	private function __clone() {}

	/**
	 * Check if ispCP is already booted
	 *
	 * @return TRUE if booted, FALSE othewise
	 */
	protected static function _isBooted() {

		return class_exists('ispCP_Initializer', false);
	}

	/**
	 * Load the initializer and set the include_path
	 *
	 * @return void
	 */
	protected function _run() {

		$this->_loadInitializer();
		ispCP_Initializer::run('_setIncludePath');
	}

	/**
	 * Load the initializer
	 *
	 * @return void
	 */
	protected function _loadInitializer() {

      require INCLUDEPATH . '/ispCP/Initializer.php';
	}
}