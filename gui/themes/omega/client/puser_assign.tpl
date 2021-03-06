{include file='header.tpl'}
<body>
	<div class="header">
		{include file="$MAIN_MENU"}
		<div class="logo">
			<img src="{$THEME_COLOR_PATH}/images/ispcp_logo.png" alt="ispCP Omega logo" />
			<img src="{$THEME_COLOR_PATH}/images/ispcp_webhosting.png" alt="ispCP Omega" />
		</div>
	</div>
	<div class="location">
		<div class="location-area">
			<h1 class="webtools">{$TR_MENU_WEBTOOLS}</h1>
		</div>
		<ul class="location-menu">
			{if isset($YOU_ARE_LOGGED_AS)}
			<li><a href="change_user_interface.php?action=go_back" class="backadmin">{$YOU_ARE_LOGGED_AS}</a></li>
			{/if}
			<li><a href="../index.php?logout" class="logout">{$TR_MENU_LOGOUT}</a></li>
		</ul>
		<ul class="path">
			<li><a href="webtools.php">{$TR_MENU_OVERVIEW}</a></li>
			<li><a href="protected_user_manage.php">{$TR_HTACCESS_USER}</a></li>
			<li>{$TR_USER_ASSIGN}</li>
		</ul>
	</div>
	<div class="left_menu">{include file="$MENU"}</div>
	<div class="main">
		{if isset($MESSAGE)}
		<div class="{$MSG_TYPE}">{$MESSAGE}</div>
		{/if}
		<h2 class="users"><span>{$TR_USER_ASSIGN}</span></h2>
		<table>
			<tr>
				<th colspan="3">{$UNAME}</th>
			</tr>
		</table>
		<!-- BDP: in_group -->
		<form action="protected_user_assign.php?uname={$UNAME}" method="post" id="client_protected_user_assign_remove">
			<table>
				<tr>
					<td>{$TR_MEMBER_OF_GROUP}</td>
					<td>
						<select name="groups_in">
				  			<!-- BDP: already_in -->
							<option value="{$GRP_IN_ID}">{$GRP_IN}</option>
							<!-- EDP: already_in -->
						</select>
					</td>
					<td>
						<div class="buttons">
							<input type="hidden" name="nadmin_name" value="{$UID}" />
							<input type="hidden" name="uaction" value="remove" />
							<input type="submit" name="Submit" value="{$TR_REMOVE}" />
						</div>
					</td>
				</tr>
			</table>
		</form>
		<!-- EDP: in_group -->
		<!-- BDP: not_in_group -->
		<form action="protected_user_assign.php?uname={$UNAME}" method="post" id="client_protected_user_assign_add">
			<table>
				<tr>
					<td>{$TR_SELECT_GROUP}</td>
					<td>
						<select name="groups">
							<!-- BDP: grp_avlb -->
							<option value="{$GRP_ID}">{$GRP_NAME}</option>
							<!-- EDP: grp_avlb -->
						</select>
					</td>
					<td>
						<div class="buttons">
							<input type="hidden" name="nadmin_name" value="{$UID}" />
							<input type="hidden" name="uaction" value="add" />
							<input type="submit" name="Submit" value="{$TR_ADD}" />
						</div>
					</td>
				</tr>
			</table>
		</form>
		<!-- EDP: not_in_group -->
	</div>
{include file='footer.tpl'}