<?php
/**
 * ispCP ω (OMEGA) a Virtual Hosting Control System
 *
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
 * The Original Code is "ispCP ω (OMEGA) a Virtual Hosting Control Panel".
 *
 * The Initial Developer of the Original Code is ispCP Team.
 * Portions created by Initial Developer are Copyright (C) 2006-2011 by
 * isp Control Panel. All Rights Reserved.
 * Portions created by the ispCP Team are Copyright (C) 2006-2011 by
 * isp Control Panel. All Rights Reserved.
 *
 * @category	ispCP
 * @package		ispCP
 * @copyright 	2006-2011 by ispCP | http://isp-control.net
 * @author 		ispCP Team
 * @author 	    Laurent Declercq <laurent.declercq@ispcp.net>
 * @version 	SVN: $Id$
 * @link		http://isp-control.net ispCP Home Site
 * @license		http://www.mozilla.org/MPL/ MPL 1.1
 */

/**
 * This is the primarly file that should be included in all the ispCP's user
 * levels scripts such as all scripts that live under gui/{admin,reseller,client}
 */

// Set default error reporting level
error_reporting(E_ALL|E_STRICT);

// Sets to TRUE here to ensure displaying of the base core errors
// Will be overwritten during initialization process
// @see ispCP_Initializer::_setDisplayErrors()
ini_set('display_errors', 1);

// Define path for the ispCP include directory
define('INCLUDEPATH', dirname(__FILE__));

/**
 * Autoloading classes
 *
 * @todo switch to POO
 */
require_once INCLUDEPATH . '/ispcp-loader.php';
spl_autoload_register('autoload_class');

/**
 * Exception Handler for uncaught exceptions
 *
 * Sets the exception handler for uncaught exceptions and register it in the
 * registry.
 */
ispCP_Registry::setAlias(
	'exceptionHandler',
	ispCP_Exception_Handler::getInstance()->setHandler()
);

/**
 * Attach the primary writer to write uncaught exceptions messages to
 * the client browser.
 *
 * The writer writes all exception messages to the client browser. In production,
 * all messages are replaced by a specific message to avoid revealing important
 * information about the ispCP application environment if the user is not an
 * administrator.
 *
 * Another optional writers will be attached to this object during
 * initialization process.
 */
ispCP_Registry::get('exceptionHandler')->attach(
	new ispCP_Exception_Writer_Browser()
);

/**
 * Encryption data
 */
require_once INCLUDEPATH . '/ispcp-load-db-keys.php';

if($ispcp_db_pass_key != '{KEY}' && $ispcp_db_pass_iv != '{IV}') {
	ispCP_Registry::set('MCRYPT_KEY', $ispcp_db_pass_key);
	ispCP_Registry::set('MCRYPT_IV', $ispcp_db_pass_iv);
	unset($ispcp_db_pass_key, $ispcp_db_pass_iv);
} else {
	throw new ispCP_Exception(
		'Error: Database key and/or initialization vector was not generated!'
	);
}

/**
 * Include ispCP common functions
 */
require_once 'Net/IDNA2.php';
require_once INCLUDEPATH . '/ispcp-functions.php';

/**
 * Bootstrap the ispCP environment, and default configuration
 *
 * @see {@link ispCP_Bootstrap} class
 * @see {@link ispCP_Initializer} class
 */
require_once INCLUDEPATH . '/environment.php';

/**
 * Internationalization functions
 */
require_once 'i18n.php';

/**
 * System message functions
 *
 * @deprecated Deprecated since 1.0.6 - Will be replaced by ispCP_Exception
 */
require_once 'system-message.php';

/**
 * SQL convenience functions
 */
require_once 'sql.php';

/**
 * Authentication functions
 */
require_once 'login-functions.php';

/**
 * User level functions
 *
 * @todo: Must be refactored to be able to load only files that are needed
 */
require_once 'admin-functions.php';
require_once 'reseller-functions.php';
require_once 'client-functions.php';

/**
 * Some others shared libraries
 */
require_once 'date-functions.php';
require_once 'input-checks.php';
require_once 'calc-functions.php';
require_once 'lostpassword-functions.php';
require_once 'emailtpl-functions.php';
require_once 'layout-functions.php';
require_once 'functions.ticket_system.php';
require_once 'debug.php';
