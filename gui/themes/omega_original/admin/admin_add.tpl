<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>{TR_ADMIN_ADD_USER_PAGE_TITLE}</title>
<meta name="robots" content="nofollow, noindex" />
<meta http-equiv="Content-Type" content="text/html; charset={THEME_CHARSET}" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<link href="{THEME_COLOR_PATH}/css/ispcp.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="{THEME_COLOR_PATH}/scripts/ispcp.js"></script>
<!--[if lt IE 7.]>
<script defer type="text/javascript" src="{THEME_COLOR_PATH}/scripts/pngfix.js"></script>
<![endif]-->
</head>

<body onLoad="MM_preloadImages('{THEME_COLOR_PATH}/images/icons/database_a.png','{THEME_COLOR_PATH}/images/icons/hosting_plans_a.png','{THEME_COLOR_PATH}/images/icons/domains_a.png','{THEME_COLOR_PATH}/images/icons/general_a.png' ,'{THEME_COLOR_PATH}/images/icons/manage_users_a.png','{THEME_COLOR_PATH}/images/icons/webtools_a.png','{THEME_COLOR_PATH}/images/icons/statistics_a.png','{THEME_COLOR_PATH}/images/icons/support_a.png')">
<table width="100%" border="0" cellspacing="0" cellpadding="0" style="height:100%;padding:0;margin:0 auto;">
<tr>
<td align="left" valign="top" style="vertical-align: top; width: 195px; height: 56px;"><img src="{THEME_COLOR_PATH}/images/top/top_left.jpg" width="195" height="56" border="0" alt="ispCP Logogram" /></td>
<td style="height: 56px; width:100%; background-color: #0f0f0f"><img src="{THEME_COLOR_PATH}/images/top/top_left_bg.jpg" width="582" height="56" border="0" alt="" /></td>
<td style="width: 73px; height: 56px;"><img src="{THEME_COLOR_PATH}/images/top/top_right.jpg" width="73" height="56" border="0" alt="" /></td>
</tr>
	<tr>
		<td style="width: 195px; vertical-align: top;">{MENU}</td>
	    <td colspan="2" style="vertical-align: top;"><table style="width: 100%; padding:0;margin:0;" cellspacing="0">
				<tr style="height:95px;">
				  <td style="padding-left:30px; width: 100%; background-image: url({THEME_COLOR_PATH}/images/top/middle_bg.jpg);">{MAIN_MENU}</td>
					<td style="padding:0;margin:0;text-align: right; width: 73px;vertical-align: top;"><img src="{THEME_COLOR_PATH}/images/top/middle_right.jpg" width="73" height="95" border="0" alt="" /></td>
				</tr>
				<tr>
				  <td colspan="3"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr>
                      <td align="left"><table width="100%" cellpadding="5" cellspacing="5">
                          <tr>
                            <td width="25"><img src="{THEME_COLOR_PATH}/images/content/table_icon_user.png" width="25" height="25" alt="" /></td>
                            <td colspan="2" class="title">{TR_ADD_ADMIN}</td>
                          </tr>
                      </table></td>
                      <td width="27" align="right">&nbsp;</td>
                    </tr>
                    <tr>
                      <td valign="top"><!-- BDP: props_list -->
                          <form name="admin_add_user" method="post" action="admin_add.php">
                            <table width="100%" cellpadding="5" cellspacing="5">
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td colspan="2" class="content3"><b>{TR_CORE_DATA}</b></td>
                              </tr>
                              <!-- BDP: page_message -->
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td colspan="2" class="title"><span class="message">{MESSAGE}</span></td>
                              </tr>
                              <!-- EDP: page_message -->
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_USERNAME}</td>
                                <td class="content"><input type="text" name="username" value="{USERNAME}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_PASSWORD}</td>
                                <td class="content"><input type="password" name="pass" value="{GENPAS}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_PASSWORD_REPEAT}</td>
                                <td class="content"><input type="password" name="pass_rep" value="{GENPAS}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_EMAIL}</td>
                                <td class="content"><input type="text" name="email" value="{EMAIL}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td colspan="2" class="content3"><b>{TR_ADDITIONAL_DATA}</b></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_FIRST_NAME}</td>
                                <td class="content"><input type="text" name="fname" value="{FIRST_NAME}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_LAST_NAME}</td>
                                <td class="content"><input type="text" name="lname" value="{LAST_NAME}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_GENDER}</td>
                                <td class="content"><select name="gender" size="1">
                                      <option value="M" {VL_MALE}>{TR_MALE}</option>
                                      <option value="F" {VL_FEMALE}>{TR_FEMALE}</option>
                                      <option value="U" {VL_UNKNOWN}>{TR_UNKNOWN}</option>
                                    </select></td>
                               </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_COMPANY}</td>
                                <td class="content"><input type="text" name="firm" value="{FIRM}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_STREET_1}</td>
                                <td class="content"><input type="text" name="street1" value="{STREET_1}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_STREET_2}</td>
                                <td class="content"><input type="text" name="street2" value="{STREET_2}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_ZIP_POSTAL_CODE}</td>
                                <td class="content"><input type="text" name="zip" value="{ZIP}" style="width:80px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_CITY}</td>
                                <td class="content"><input type="text" name="city" value="{CITY}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_STATE}</td>
                                <td class="content"><input type="text" name="state" value="{STATE}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_COUNTRY}</td>
                                <td class="content"><input type="text" name="country" value="{COUNTRY}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_PHONE}</td>
                                <td class="content"><input type="text" name="phone" value="{PHONE}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td width="25">&nbsp;</td>
                                <td width="200" class="content2">{TR_FAX}</td>
                                <td class="content"><input type="text" name="fax" value="{FAX}" style="width:210px" class="textinput" /></td>
                              </tr>
                              <tr>
                                <td>&nbsp;</td>
                                <td colspan="2"><input name="Submit" type="submit" class="button" value="  {TR_ADD}  " /></td>
                              </tr>
                              <tr>
                                <td colspan="3">&nbsp;</td>
                              </tr>
                            </table>
                            <input type="hidden" name="uaction" value="add_user" />
                          </form>
                        <!-- EDP: props_list -->
                      </td>
                      <td>&nbsp;</td>
                    </tr>
                    <tr>
                      <td>&nbsp;</td>
                      <td>&nbsp;</td>
                    </tr>
                  </table></td>
				</tr>
			</table></td>
	</tr>
</table>
</body>
</html>
