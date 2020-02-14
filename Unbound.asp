<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Unbound</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">

<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaSCript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/disk_functions.js"></script>
<script language="JavaScript" type="text/javascript" src="/base64.js"></script>

<script>
var custom_settings = <% get_custom_settings(); %>;

function initial(){
        show_menu();

        if (custom_settings.unbound_enable == undefined)
                document.form.unbound_enable.value = "0";
        else
                document.form.unbound_enable.value = custom_settings.unbound_enable;

        if (custom_settings.unbound_control == undefined)
                document.form.unbound_control.value = "1";
        else
                document.form.unbound_control.value = custom_settings.unbound_control;

        if (custom_settings.unbound_validator == undefined)
                document.form.unbound_validator.value = "1";
        else
                document.form.unbound_validator.value = custom_settings.unbound_validator;

        if (custom_settings.unbound_logdest == undefined)
                document.form.unbound_logdest.value = "syslog";
        else
                document.form.unbound_logdest.value = custom_settings.unbound_logdest;

        if (custom_settings.unbound_logextra == undefined)
                document.form.unbound_logextra.value = "0";
        else
                document.form.unbound_logextra.value = custom_settings.unbound_logextra;

        if (custom_settings.unbound_verbosity == undefined)
                document.form.unbound_verbosity.value = "1";
        else
                document.form.unbound_verbosity.value = custom_settings.unbound_verbosity;

        if (custom_settings.unbound_extended_stats == undefined)
                document.form.unbound_extended_stats.value = "0";
        else
                document.form.unbound_extended_stats.value = custom_settings.unbound_extended_stats;

		if (custom_settings.unbound_protocol == undefined)
                document.form.unbound_protocol.value = "ip4_only";
        else
                document.form.unbound_protocol.value = custom_settings.unbound_protocol;

        if (custom_settings.unbound_edns_size == undefined)
                document.getElementById('unbound_edns_size').value = "1280";
        else
                document.getElementById('unbound_edns_size').value = custom_settings.unbound_edns_size;

        if (custom_settings.unbound_listen_port == undefined)
                document.getElementById('unbound_listen_port').value = "53535";
        else
                document.getElementById('unbound_listen_port').value = custom_settings.unbound_listen_port;

        if (custom_settings.unbound_resource == undefined)
                document.form.unbound_resource.value = "default";
        else
                document.form.unbound_resource.value = custom_settings.unbound_resource;

        if (custom_settings.unbound_dns64 == undefined)
                document.form.unbound_dns64.value = "0";
        else
                document.form.unbound_dns64.value = custom_settings.unbound_dns64;

        hide_dns64(getRadioValue(document.form.unbound_dns64));

        if (custom_settings.unbound_dns64_prefix == undefined)
                document.getElementById('unbound_dns64_prefix').value = "64:ff9b::/96";
        else
                document.getElementById('unbound_dns64_prefix').value = custom_settings.unbound_dns64_prefix;

        if (custom_settings.unbound_recursion == undefined)
                document.form.unbound_recursion.value = "default";
        else
                document.form.unbound_recursion.value = custom_settings.unbound_recursion;

        if (custom_settings.unbound_query_minimize == undefined)
                document.form.unbound_query_minimize.value = "1";
        else
                document.form.unbound_query_minimize.value = custom_settings.unbound_query_minimize;

        if (custom_settings.unbound_query_min_strict == undefined)
                document.form.unbound_query_min_strict.value = "0";
        else
                document.form.unbound_query_min_strict.value = custom_settings.unbound_query_min_strict;

        if (custom_settings.unbound_ttl_min == undefined)
                document.getElementById('unbound_ttl_min').value = "120";
        else
                document.getElementById('unbound_ttl_min').value = custom_settings.unbound_ttl_min;

        if (custom_settings.unbound_rebind_protection == undefined)
                document.form.unbound_rebind_protection.value = "1";
        else
                document.form.unbound_rebind_protection.value = custom_settings.unbound_rebind_protection;

        if (custom_settings.unbound_rebind_localhost == undefined)
                document.form.unbound_rebind_localhost.value = "1";
        else
                document.form.unbound_rebind_localhost.value = custom_settings.unbound_rebind_localhost;

        if (custom_settings.unbound_domain_insecure == undefined)
                document.getElementById('unbound_domain_insecure').value ="<% nvram_get("ntp_server0"); %> <% nvram_get("ntp_server1"); %>";  // TODO Get NTP server 1 and 2 from nvram
        else
                document.getElementById('unbound_domain_insecure').value = Base64.decode(custom_settings.unbound_domain_insecure);

        if (custom_settings.unbound_domain_rebindok == undefined)
                document.getElementById('unbound_domain_rebindok').value = "";  // TODO Get NTP server 1 and 2 from nvram
        else
                document.getElementById('unbound_domain_rebindok').value = Base64.decode(custom_settings.unbound_domain_rebindok);

        if (custom_settings.unbound_validator_ntp == undefined)
                document.form.unbound_validator_ntp.value = "0";
        else
                document.form.unbound_validator_ntp.value = custom_settings.unbound_validator_ntp;

        if (custom_settings.unbound_statslog == undefined)
                document.form.unbound_statslog.value = "0";
        else
                document.form.unbound_statslog.value = custom_settings.unbound_statslog;

		hide_dnsrebind(getRadioValue(document.form.unbound_rebind_protection));
		hide_dnssec(getRadioValue(document.form.unbound_validator));
}

function hide_dns64(_value){
        showhide("dns64pre_tr", (_value == "1"));
}
function hide_dnssec(_value){
        showhide("dnssecdom_tr", (_value == "1"));
        showhide("dnssecboot_tr", (_value == "1"));
}
function hide_dnsrebind(_value){
        showhide("dnsrebdom_tr", (_value == "1"));
        showhide("dnsreblocal_tr", (_value == "1"));
}
function applySettings(){
	if (!validator.numberRange(document.form.unbound_edns_size, 512, 4096) ||
	    !validator.numberRange(document.form.unbound_listen_port, 1, 65535) ||
	    !validator.numberRange(document.form.unbound_ttl_min, 0, 1800))
		return false;

  if (document.form.unbound_listen_port.value == '53') {
    alert("Port 53 conflicts with dnsmasq. Choose another port.");
    return false;
    }

        /* Retrieve value from input fields, and store in object */
        custom_settings.unbound_enable = document.form.unbound_enable.value;
        custom_settings.unbound_control = document.form.unbound_control.value;
        custom_settings.unbound_validator = document.form.unbound_validator.value;
        custom_settings.unbound_logdest = document.form.unbound_logdest.value;
        custom_settings.unbound_logextra = document.form.unbound_logextra.value;
        custom_settings.unbound_verbosity = document.form.unbound_verbosity.value;
        custom_settings.unbound_extended_stats = document.form.unbound_extended_stats.value;
        custom_settings.unbound_protocol = document.form.unbound_protocol.value;
        custom_settings.unbound_edns_size = document.getElementById('unbound_edns_size').value;
        custom_settings.unbound_listen_port = document.getElementById('unbound_listen_port').value;
        custom_settings.unbound_resource = document.form.unbound_resource.value;
        custom_settings.unbound_dns64 = document.form.unbound_dns64.value;
        custom_settings.unbound_dns64_prefix = document.getElementById('unbound_dns64_prefix').value;
        custom_settings.unbound_recursion = document.form.unbound_recursion.value;
        custom_settings.unbound_query_minimize = document.form.unbound_query_minimize.value;
        custom_settings.unbound_query_min_strict = document.form.unbound_query_min_strict.value;
        custom_settings.unbound_ttl_min = document.getElementById('unbound_ttl_min').value;
        custom_settings.unbound_rebind_protection = document.form.unbound_rebind_protection.value;
        custom_settings.unbound_rebind_localhost = document.form.unbound_rebind_localhost.value;
        custom_settings.unbound_domain_rebindok = Base64.encode(document.getElementById('unbound_domain_rebindok').value);
        custom_settings.unbound_domain_insecure = Base64.encode(document.getElementById('unbound_domain_insecure').value);
        custom_settings.unbound_validator_ntp = document.form.unbound_validator_ntp.value;
        custom_settings.unbound_statslog = document.form.unbound_statslog.value;

        /* Store object as a string in the amng_custom hidden input field */
        document.getElementById('amng_custom').value = JSON.stringify(custom_settings);

        /* Apply */
        showLoading();
        document.form.submit();
}

</script>
</head>

<body onload="initial();"  class="bg">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="Unbound.asp">
<input type="hidden" name="next_page" value="Unbound.asp">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="5">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<input type="hidden" name="action_script" value="restart_unbound">

<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tr>
<td bgcolor="#4D595D" colspan="3" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle">Unbound DNS Recursive Resolver</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">Unbound is a validating, recursive, caching DNS resolver. It is designed to be fast and lean and incorporates modern features based on open standards.</div>

<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
		<thead>
			<tr>
				<td colspan="2">Basic Configuration</td>
			</tr>
		</thead>
        <tr>
                <th>Enable Unbound</th>
                <td>
                        <input type="radio" name="unbound_enable" class="input" value="1" >Yes
						<input type="radio" name="unbound_enable" class="input" value="0" >No
				</td>
        </tr>
        <tr>
                <th>IP Protocol</th>
                <td>
                        <select name="unbound_protocol" class="input_option">
						<option value="ip4_only">IPv4 Only</option>
						<option value="mixed">IPv4 and IPv6</option>
						<option value="ip6_prefer">Prefer IPv6</option>
						</select>
                </td>
        </tr>
        <tr>
                <th>Listen Port</th>
                <td>
                        <input type="text" maxlength="5" class="input_6_table" id="unbound_listen_port" onKeyPress="return validator.isNumber(this,event);" value="0">
						<span>Default: 53535</span>

                </td>
        </tr>
        <tr>
                <th>Unbound Control Setup</th>
                <td>
                        <select name="unbound_control" class="input_option">
						<option value="1">localhost No SSL</option>
						<option value="2">localhost SSL</option>
						<option value="3">LAN SSL</option>
						</select>
                </td>
        </tr>
		<thead>
			<tr>
				<td colspan="2">DNSSEC Configuration</td>
			</tr>
		</thead>
        <tr>
                <th>Enable DNSSEC?</th>
                <td>
                        <input type="radio" name="unbound_validator" class="input" value="1" onclick="hide_dnssec(this.value);">Yes
						<input type="radio" name="unbound_validator" class="input" value="0" onclick="hide_dnssec(this.value);">No
                </td>
        </tr>
        <tr id="dnssecdom_tr">
                <th>Ignore DNSSEC Domains</th>
                <td>
                        <textarea rows="1" class="textarea_ssh_table" id="unbound_domain_insecure" spellcheck="false" name="unbound_domain_insecure" cols="50" maxlength="2249"></textarea>
                </td>
        </tr>
        <tr id="dnssecboot_tr">
                <th>Disable DNSSEC before NTP sync</th>
                <td>
                        <input type="radio" name="unbound_validator_ntp" class="input" value="1" >Yes
						<input type="radio" name="unbound_validator_ntp" class="input" value="0" >No
                </td>
        </tr>
		<thead>
			<tr>
				<td colspan="2">Log Configuration</td>
			</tr>
		</thead>
        <tr>
                <th>Log Destination</th>
                <td>
                        <select name="unbound_logdest" class="input_option">
						<option value="syslog">Syslog</option>
						<option value="file">File</option>
						</select>
						<span>Default: Syslog</span>
                </td>
        </tr>
        <tr>
                <th>Logging Level</th>
                <td>
                        <select name="unbound_verbosity" class="input_option">
						<option value="0">0-Error</option>
						<option value="1">1-Operational</option>
						<option value="2">2-Detailed</option>
						<option value="3">3-Query</option>
						<option value="4">4-Algorithm</option>
						<option value="5">5-Client</option>
						</select>
						<span>Default: 1-Operational</span>
                </td>
        </tr>
        <tr>
                <th>Enhanced Logging</th>
                <td>
                        <input type="radio" name="unbound_logextra" class="input" value="1" >Yes
						<input type="radio" name="unbound_logextra" class="input" value="0" >No
						<span>Query tags, SERVFAIL, local actions</span>
                </td>
        </tr>
        <tr>
                <th>Send Stats to Log Hourly</th>
                <td>
                        <input type="radio" name="unbound_statslog" class="input" value="1" >Yes
						<input type="radio" name="unbound_statslog" class="input" value="0" >No
                </td>
        </tr>
        <tr>
		<thead>
			<tr>
				<td colspan="2">Performance Tuning</td>
			</tr>
		</thead>
        <tr>
                <th>Extended Statistics</th>
                <td>
                        <input type="radio" name="unbound_extended_stats" class="input" value="1" >Yes
						<input type="radio" name="unbound_extended_stats" class="input" value="0" >No
                </td>
        </tr>
        <tr>
                <th>EDNS Buffer Size</th>
                <td>
                        <input type="text" maxlength="5" class="input_6_table" id="unbound_edns_size" onKeyPress="return validator.isNumber(this,event);" value="0">&nbsp;bytes
						<span>Default: 4096</span>
                </td>
        </tr>
        <tr>
                <th>Cache Sizing</th>
                <td>
                        <select name="unbound_resource" class="input_option">
						<option value="default">Default</option>
						<option value="tiny">Tiny</option>
						<option value="small">Small</option>
						<option value="medium">Medium</option>
						<option value="large">Large</option>
                </td>
        </tr>
                <th>Recursion Style</th>
                <td>
                        <select name="unbound_recursion" class="input_option">
						<option value="default">Default</option>
						<option value="passive">Passive</option>
						<option value="aggressive">Aggressive</option>
                </td>
        </tr>
        <tr>
                <th>Minimum TTL</th>
                <td>
                        <input type="text" maxlength="4" class="input_6_table" id="unbound_ttl_min" onKeyPress="return validator.isNumber(this,event);" value="0">&nbsp;seconds
						<span>Default: 0 Max: 1800</span>
                </td>
        </tr>
		<thead>
			<tr>
				<td colspan="2">Privacy Settings</td>
			</tr>
		</thead>
        <tr>
                <th>QNAME Minimization</th>
                <td>
                        <input type="radio" name="unbound_query_minimize" class="input" value="1" >Yes
						<input type="radio" name="unbound_query_minimize" class="input" value="0" >No
                </td>
        </tr>
        <tr>
                <th>Strict QNAME Minimization</th>
                <td>
                        <input type="radio" name="unbound_query_min_strict" class="input" value="1" >Yes
						<input type="radio" name="unbound_query_min_strict" class="input" value="0" >No
                </td>
        </tr>
		<thead>
			<tr>
				<td colspan="2">Security Settings</td>
			</tr>
		</thead>
        <tr>
                <th>DNS Rebind Protection</th>
                <td>
                        <input type="radio" name="unbound_rebind_protection" class="input" onclick="hide_dnsrebind(this.value);" value="1" >Yes
						<input type="radio" name="unbound_rebind_protection" class="input" onclick="hide_dnsrebind(this.value);" value="0" >No
                </td>
        </tr>
        <tr id="dnsreblocal_tr">
                <th>Block localhost responses</th>
                <td>
                        <input type="radio" name="unbound_rebind_localhost" class="input" value="1" >Yes
						<input type="radio" name="unbound_rebind_localhost" class="input" value="0" >No
                </td>
        </tr>
        <tr id="dnsrebdom_tr">
                <th>Whitelisted rebind domains</th>
                <td>
                        <textarea rows="1" class="textarea_ssh_table" id="unbound_domain_rebindok" spellcheck="false" name="unbound_domain_rebindok" cols="50" maxlength="2249"></textarea>
                </td>
        </tr>
		<thead>
			<tr>
				<td colspan="2">Other Configuration</td>
			</tr>
		</thead>
        <tr>
                <th>Enable DNS64</th>
                <td>
                        <input type="radio" name="unbound_dns64" class="input" onclick="hide_dns64(this.value);" value="1" >Yes
						<input type="radio" name="unbound_dns64" class="input" onclick="hide_dns64(this.value);" value="0" >No
                </td>
        </tr>
        <tr id="dns64pre_tr">
                <th>DNS64 Prefix</th>
                <td>
                        <input type="text" maxlength="20" class="input_20_table" id="unbound_dns64_prefix" value="">
                </td>
        </tr>
        <tr>
</table>
<div class="apply_gen">
        <input name="button" type="button" class="button_gen" onclick="applySettings();" value="Apply"/>
</div>
</form>

<div>
<table class="apply_gen">
<tr class="apply_gen" valign="top">
</tr>
</table>
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top"></td>
</tr>
</table>
<div id="footer"></div>
</body>
</html>
