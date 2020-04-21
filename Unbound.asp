<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<!-- UnboundUI-by-dave14305 -->
<html xmlns="http://www.w3.org/1999/xhtml">
<html xmlns:v>

<head>
    <meta http-equiv="X-UA-Compatible" content="IE=Edge" />
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
    <script language="JavaScript" type="text/javascript" src="/popup.js"></script>
    <script language="JavaScript" type="text/javascript" src="/help.js"></script>
    <script language="JavaScript" type="text/javascript" src="/detect.js"></script>
    <script language="JavaScript" type="text/javascript" src="/validator.js"></script>
    <script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
    <script language="JavaScript" type="text/javascript" src="/base64.js"></script>

    <script>
        var custom_settings = <% get_custom_settings(); %>;

        function YazHint(hintid) {
            var tag_name = document.getElementsByTagName('a');
            for (var i = 0; i < tag_name.length; i++) {
                tag_name[i].onmouseout = nd;
            }
            hinttext = "Help text not yet defined";
            if (hintid == 1) hinttext = "Choose which IP protocol Unbound uses for external communication. Prefer IPv6 uses both IPv4 and IPv6 but gives preference to IPv6.";
            if (hintid == 2) hinttext = "UDP and TCP port that Unbound will listen on using the loopback interface. Avoid ports that are already in use by other services.";
            if (hintid == 3) hinttext = "Choose specific outgoing interfaces, such as VPN client tunnels, to protect outbound DNS queries from snooping.";
            if (hintid == 5) hinttext = "Allow these domains to fail DNSSEC validation, e.g. before the clock is synced.";
            if (hintid == 7) hinttext = "Select the desination for Unbound log output. If using logging level greater than 1, use a logfile.";
            if (hintid == 8) hinttext = "The verbosity number, level 0 means no verbosity, only errors. Level 1 gives operational information. Level 2 gives detailed operational information. Level 3 gives query level information, output per query. Level 4 gives algorithm level information. Level 5 logs client identification for cache misses.";
            if (hintid == 9) hinttext = "Enable extra log details for queries (log-tag-queryreply) and upstream failures (log-servfail).";
            if (hintid == 10) hinttext = "Write statistics to the chosen log destination every X minutes. Zero to disable. Maximum 1440 (24 hours). 60 is typical.";
            if (hintid == 11) hinttext = "Enable more detailed statistics collection, viewable in unbound-control stats.";
            if (hintid == 12) hinttext = "Number of bytes size to advertise as the EDNS reassembly buffer size. This is the value put into datagrams over UDP towards peers. Default is 4096 which is RFC recommended. If you have fragmentation reassembly problems, usually seen as timeouts, then a value of 1472 can fix it.";
            if (hintid == 13) hinttext = "Size various performance-related resources (e.g. cache sizes, TCP buffers).";
            if (hintid == 14) hinttext = "Unbound has many options for recursion: passive - slower until cache fills but kind on CPU load. default - Unbound built-in defaults. aggressive - uses prefetching to handle more requests quickly.";
            if (hintid == 15) hinttext = "Time to live minimum for RRsets and messages in the cache. If the minimum kicks in, the data is cached for longer than the domain owner intended, and thus fewer queries are made to lookup the data. Zero makes sure the data in the cache is as the domain owner intended. Higher values, especially more than an hour or so, can lead to trouble as the data in the cache does not match up with the actual data any more.";
            if (hintid == 16) hinttext = "Send minimum amount of information to upstream servers to enhance privacy.";
            if (hintid == 17) hinttext = "Download and cache the root (.) zone for faster lookups.";
            if (hintid == 20) hinttext = "Allow these domains, and all their subdomains to contain private addresses. Give multiple times to allow multiple domain names to contain private addresses.";
            if (hintid == 23) hinttext = "Place unbound.conf options to add to the server: clause.";
            if (hintid == 24) hinttext = "Place unbound.conf options to add outside the server: clause (e.g. local-zone, stub-zone, remote-control, etc.)";
            return overlib(hinttext, HAUTO, VAUTO);
        }

        function SetCurrentPage() {
            document.form.next_page.value = window.location.pathname.substring(1);
            document.form.current_page.value = window.location.pathname.substring(1);
        }

        function showCacheRAM(cacheoption) {
          if (cacheoption == "default")
            document.getElementById("resourcesize").innerHTML = "RAM: 12 MB";
          if (cacheoption == "small")
            document.getElementById("resourcesize").innerHTML = "RAM: 4 MB";
          if (cacheoption == "medium")
            document.getElementById("resourcesize").innerHTML = "RAM: 8 MB";
          if (cacheoption == "large")
            document.getElementById("resourcesize").innerHTML = "RAM: 16 MB";
          if (cacheoption == "xlarge")
            document.getElementById("resourcesize").innerHTML = "RAM: 32 MB";
        }

        function SetOutgoingInterfaceOptions() {
          var retval = 0;
          if ( "<% nvram_get("vpn_client1_state"); %>" == "2" ) {
              add_option(document.form.unbound_outiface, "VPN Client 1", "1", custom_settings.unbound_outiface == "1");
              retval = 1;
          }
          if ( "<% nvram_get("vpn_client2_state"); %>" == "2" ) {
              add_option(document.form.unbound_outiface, "VPN Client 2", "2", custom_settings.unbound_outiface == "2");
              retval = 1;
          }
          if ( "<% nvram_get("vpn_client3_state"); %>" == "2" ) {
              add_option(document.form.unbound_outiface, "VPN Client 3", "3", custom_settings.unbound_outiface == "3");
              retval = 1;
          }
          if ( "<% nvram_get("vpn_client4_state"); %>" == "2" ) {
              add_option(document.form.unbound_outiface, "VPN Client 4", "4", custom_settings.unbound_outiface == "4");
              retval = 1;
          }
          if ( "<% nvram_get("vpn_client5_state"); %>" == "2" ) {
              add_option(document.form.unbound_outiface, "VPN Client 5", "5", custom_settings.unbound_outiface == "5");
              retval = 1;
          }
          return retval;
        }

        function initial() {
            show_menu();
            SetCurrentPage();
            firmwarebuild = (<% nvram_get("buildno"); %>);
            unbound_state = (<% sysinfo("pid.unbound"); %> > 0 ? 1 : 0);
            dnssecenabled = (<% nvram_get("dnssec_enable"); %>);
            dnsrebindenabled = (<% nvram_get("dns_norebind"); %>);

            if (unbound_state > 0)
                document.getElementById("unbound_status").innerHTML = "Status: Running";
            else
                document.getElementById("unbound_status").innerHTML = "Status: Stopped";

            if (custom_settings.unbound_enable == undefined)
                document.form.unbound_enable.value = "1";
            else
                document.form.unbound_enable.value = custom_settings.unbound_enable;

            if (custom_settings.unbound_outiface == undefined)
                document.form.unbound_outiface.value = "0";
            else
                document.form.unbound_outiface.value = custom_settings.unbound_outiface;

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

            if (custom_settings.unbound_edns_size == undefined)
                document.getElementById('unbound_edns_size').value = "1280";
            else
                document.getElementById('unbound_edns_size').value = custom_settings.unbound_edns_size;

            if (custom_settings.unbound_listen_port == undefined)
                document.getElementById('unbound_listen_port').value = "5653";
            else
                document.getElementById('unbound_listen_port').value = custom_settings.unbound_listen_port;

            if (custom_settings.unbound_resource == undefined)
                document.form.unbound_resource.value = "default";
            else
                document.form.unbound_resource.value = custom_settings.unbound_resource;

            if (custom_settings.unbound_recursion == undefined)
                document.form.unbound_recursion.value = "default";
            else
                document.form.unbound_recursion.value = custom_settings.unbound_recursion;

            if (custom_settings.unbound_query_minimize == undefined)
                document.form.unbound_query_minimize.value = "1";
            else
                document.form.unbound_query_minimize.value = custom_settings.unbound_query_minimize;

            if (custom_settings.unbound_cache_root == undefined)
                document.form.unbound_cache_root.value = "0";
            else
                document.form.unbound_cache_root.value = custom_settings.unbound_cache_root;

            if (custom_settings.unbound_save_cache == undefined)
                document.form.unbound_save_cache = "0"
            else
              document.form.unbound_save_cache = custom_settings.unbound_save_cache;

            if (custom_settings.unbound_ttl_min == undefined)
                document.getElementById('unbound_ttl_min').value = "0";
            else
                document.getElementById('unbound_ttl_min').value = custom_settings.unbound_ttl_min;

            if (custom_settings.unbound_domain_insecure == undefined)
                document.getElementById('unbound_domain_insecure').value = "<% nvram_get("ntp_server0"); %> <% nvram_get("ntp_server1"); %>";
            else
                document.getElementById('unbound_domain_insecure').value = Base64.decode(custom_settings.unbound_domain_insecure);

            if (custom_settings.unbound_domain_rebindok == undefined)
                document.getElementById('unbound_domain_rebindok').value = "";
            else
                document.getElementById('unbound_domain_rebindok').value = Base64.decode(custom_settings.unbound_domain_rebindok);

            if (custom_settings.unbound_statslog == undefined)
                document.form.unbound_statslog.value = "0";
            else
                document.form.unbound_statslog.value = custom_settings.unbound_statslog;

            if (custom_settings.unbound_custom_server == undefined)
                document.getElementById('unbound_custom_server').value = "";
            else
                document.getElementById('unbound_custom_server').value = Base64.decode(custom_settings.unbound_custom_server);

            if (custom_settings.unbound_custom_extend == undefined)
                document.getElementById('unbound_custom_extend').value = "";
            else
                document.getElementById('unbound_custom_extend').value = Base64.decode(custom_settings.unbound_custom_extend);

            if (custom_settings.unbound_newvers != undefined) {
                document.getElementById("unboundui_verstatus").innerHTML = "New version "+custom_settings.unbound_newvers+" available!";
                showhide("checkbutton", false);
                showhide("updatebutton", true);
            }
            else {
              showhide("checkbutton", true);
              showhide("updatebutton", false);
            }

            var vpnclientsactive = SetOutgoingInterfaceOptions();
            hide_outiface(vpnclientsactive);
            hide_dnssec(dnssecenabled);
            hide_dnsrebind(dnsrebindenabled);
            showCacheRAM(document.form.unbound_resource.value);
            //eval("delete custom_settings.unbound_newvers");
        }

        function hide_dnssec(_value) {
            showhide("dnssecdom_tr", (_value == "1"));
        }

        function hide_dnsrebind(_value) {
            showhide("dnsrebdom_tr", (_value == "1"));
        }

        function hide_outiface(_value) {
            showhide("outiface_tr", (_value == "1"));
        }

        function checkForUpdate() {
          document.getElementById("unboundui_verstatus").style.display = "inline";
          document.getElementById("unboundui_verstatus").innerHTML = "New version available!";
          showhide("checkbutton", false);
          showhide("updatebutton", true);
        }

        function updateSelf() {
          document.getElementById("unboundui_verstatus").style.display = "none";
          showhide("checkbutton", true);
          showhide("updatebutton", false);
        }

        function applySettings() {
            if ( firmwarebuild == "374.43" )
            {
              if (!validate_range(document.form.unbound_listen_port, 1, 65535)){
                document.form.unbound_listen_port.focus();
                return false;
              }
              if (!validate_range(document.form.unbound_statslog, 0, 1440)){
                document.form.unbound_statslog.focus();
                return false;
              }
              if (!validate_range(document.form.unbound_edns_size, 512, 4096)){
                document.form.unbound_edns_size.focus();
                return false;
              }
              if (!validate_range(document.form.unbound_ttl_min, 0, 1800)){
                document.form.unbound_ttl_min.focus();
                return false;
              }
            }
            else
            {
            if (!validator.numberRange(document.form.unbound_listen_port, 1, 65535) ||
                !validator.numberRange(document.form.unbound_statslog, 0, 1440) ||
                !validator.numberRange(document.form.unbound_edns_size, 512, 4096) ||
                !validator.numberRange(document.form.unbound_ttl_min, 0, 1800))
                return false;
            }

            if (document.form.unbound_listen_port.value == '53') {
                alert("Port 53 conflicts with dnsmasq. Choose another port.");
                return false;
            }

            if ( document.form.unbound_enable.value != custom_settings.unbound_enable ||
                 document.getElementById('unbound_listen_port').value != custom_settings.unbound_listen_port
               )
                document.form.action_script.value += ";restart_dnsmasq";

            /* Retrieve value from input fields, and store in object */
            custom_settings.unbound_enable = document.form.unbound_enable.value;
            custom_settings.unbound_listen_port = document.getElementById('unbound_listen_port').value;
            custom_settings.unbound_outiface = document.form.unbound_outiface.value;
            custom_settings.unbound_logdest = document.form.unbound_logdest.value;
            custom_settings.unbound_logextra = document.form.unbound_logextra.value;
            custom_settings.unbound_verbosity = document.form.unbound_verbosity.value;
            custom_settings.unbound_extended_stats = document.form.unbound_extended_stats.value;
            custom_settings.unbound_edns_size = document.getElementById('unbound_edns_size').value;
            custom_settings.unbound_resource = document.form.unbound_resource.value;
            custom_settings.unbound_recursion = document.form.unbound_recursion.value;
            custom_settings.unbound_query_minimize = document.form.unbound_query_minimize.value;
            custom_settings.unbound_ttl_min = document.getElementById('unbound_ttl_min').value;
            custom_settings.unbound_domain_rebindok = Base64.encode(document.getElementById('unbound_domain_rebindok').value);
            custom_settings.unbound_domain_insecure = Base64.encode(document.getElementById('unbound_domain_insecure').value);
            custom_settings.unbound_custom_server = Base64.encode(document.getElementById('unbound_custom_server').value);
            custom_settings.unbound_custom_extend = Base64.encode(document.getElementById('unbound_custom_extend').value);
            custom_settings.unbound_statslog = document.form.unbound_statslog.value;
            custom_settings.unbound_cache_root = document.form.unbound_cache_root.value;
            custom_settings.unbound_save_cache = document.form.unbound_save_cache;

            /* Store object as a string in the amng_custom hidden input field */
            document.getElementById('amng_custom').value = JSON.stringify(custom_settings);

            /* Apply */
            showLoading();
            document.form.submit();
        }
    </script>
</head>

<body onload="initial();" class="bg">
    <div id="TopBanner"></div>
    <div id="Loading" class="popup_bg"></div>
    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
    <form method="post" name="form" action="start_apply.htm" target="hidden_frame">
        <input type="hidden" name="current_page" value="">
        <input type="hidden" name="next_page" value="">
        <input type="hidden" name="group_id" value="">
        <input type="hidden" name="modified" value="0">
        <input type="hidden" name="action_mode" value="apply">
        <input type="hidden" name="action_wait" value="5">
        <input type="hidden" name="first_time" value="">
        <input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get(" preferred_lang "); %>">
        <input type="hidden" name="firmver" value="<% nvram_get(" firmver "); %>">
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
                                                        <input type="radio" name="unbound_enable" class="input" value="1">Yes
                                                        <input type="radio" name="unbound_enable" class="input" value="0">No
                                                        <span id="unbound_status"></span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>Unbound UI Version</th>
                                                    <td>
                                                        <input type="text" maxlength="5" class="input_6_table" id="unboundui_ver" value="1.0" readonly>
                                                        <input type="button" class="button_gen" onclick="checkForUpdate();" value="Check" id="checkbutton">
                                                        <input type="button" class="button_gen" onclick="updateSelf();" value="Update" id="updatebutton" style="display:none;">
                                                        <span id="unboundui_verstatus" style="display:none;">Current version</span>
                                                    </td>
                                                </tr>
                                                <tr id="outiface_tr">
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(3);">WAN Interface</a></th>
                                                    <td>
                                                      <select name="unbound_outiface" class="input_option">
                                                          <option value="0">Any</option>
                                                      </select>
                                                      <span>Default: Any</span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(2);">Listen Port</a></th>
                                                    <td>
                                                        <input type="text" maxlength="5" class="input_6_table" id="unbound_listen_port" onKeyPress="return validator.isNumber(this,event);" value="0">
                                                        <span>Default: 5653</span>
                                                    </td>
                                                </tr>
                                                <thead>
                                                    <tr>
                                                        <td colspan="2">Log Configuration</td>
                                                    </tr>
                                                </thead>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(7);">Log Destination</a></th>
                                                    <td>
                                                        <select name="unbound_logdest" class="input_option">
                                                            <option value="syslog">Syslog</option>
                                                            <option value="file">File</option>
                                                        </select>
                                                        <span>Default: Syslog</span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(8);">Logging Level</a></th>
                                                    <td>
                                                        <select name="unbound_verbosity" class="input_option">
                                                            <option value="0">0-Error</option>
                                                            <option value="1">1-Operational</option>
                                                            <option value="2">2-Detailed</option>
                                                            <option value="3">3-Query</option>
                                                            <option value="4">4-Algorithm</option>
                                                            <option value="5">5-Client</option>
                                                        </select>
                                                        <span>Default: 1</span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(9);">Enhanced Logging</a></th>
                                                    <td>
                                                        <input type="radio" name="unbound_logextra" class="input" value="1">Yes
                                                        <input type="radio" name="unbound_logextra" class="input" value="0">No
                                                        <span>Default: No</span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(10);">Send Stats to Log every</a></th>
                                                    <td>
                                                        <input type="text" maxlength="5" class="input_6_table" id="unbound_statslog" onKeyPress="return validator.isNumber(this,event);" value="0">&nbsp;minute(s)
                                                        <span>(Disable : 0)</span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <thead>
                                                        <tr>
                                                            <td colspan="2">Security Settings</td>
                                                        </tr>
                                                    </thead>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(50,6);">Enable DNSSEC support</a></th>
                                                    <td>
                                                        <input type="radio" value="1" name="dnssec_enable" <% nvram_match( "dnssec_enable", "1", "checked"); %> disabled />Yes
                                                        <input type="radio" value="0" name="dnssec_enable" <% nvram_match( "dnssec_enable", "0", "checked"); %> disabled />No
                                                        <span>Click <a style="color:#FC0;text-decoration: underline;" href="Advanced_WAN_Content.asp">here</a> to manage.</span>
                                                    </td>
                                                    <tr id="dnssecdom_tr">
                                                        <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(5);">Ignore DNSSEC Domains</a></th>
                                                        <td>
                                                            <textarea rows="1" class="textarea_ssh_table" style="height:auto" id="unbound_domain_insecure" spellcheck="false" name="unbound_domain_insecure" cols="50" maxlength="2249"></textarea>
                                                        </td>
                                                    </tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onClick="openHint(50,9);">Enable DNS Rebind protection</a></th>
                                                    <td>
                                                        <input type="radio" value="1" name="dns_norebind" <% nvram_match( "dns_norebind", "1", "checked"); %> disabled />Yes
                                                        <input type="radio" value="0" name="dns_norebind" <% nvram_match( "dns_norebind", "0", "checked"); %> disabled />No
                                                        <span>Click <a style="color:#FC0;text-decoration: underline;" href="Advanced_WAN_Content.asp">here</a> to manage.</span>
                                                    </td>
                                                    <tr id="dnsrebdom_tr">
                                                        <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(20);">Whitelisted rebind domains</a></th>
                                                        <td>
                                                            <textarea rows="1" class="textarea_ssh_table" style="height:auto" id="unbound_domain_rebindok" spellcheck="false" name="unbound_domain_rebindok" cols="50" maxlength="2249"></textarea>
                                                        </td>
                                                    </tr>
                                                    <thead>
                                                        <tr>
                                                            <td colspan="2">Advanced Settings</td>
                                                        </tr>
                                                    </thead>
                                                    <tr>
                                                        <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(11);">Extended Statistics</a></th>
                                                        <td>
                                                            <input type="radio" name="unbound_extended_stats" class="input" value="1">Yes
                                                            <input type="radio" name="unbound_extended_stats" class="input" value="0">No
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(12);">EDNS Buffer Size</a></th>
                                                        <td>
                                                            <input type="text" maxlength="5" class="input_6_table" id="unbound_edns_size" onKeyPress="return validator.isNumber(this,event);" value="0">&nbsp;bytes
                                                            <span>Default: 4096</span>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(13);">Cache Sizing</a></th>
                                                        <td>
                                                            <select name="unbound_resource" class="input_option" onchange="showCacheRAM(this.value);">
                                                                <option value="default">Default</option>
                                                                <option value="small">Small</option>
                                                                <option value="medium">Medium</option>
                                                                <option value="large">Large</option>
                                                                <option value="xlarge">X-Large</option>
                                                            </select>
                                                            <span id="resourcesize">RAM: </span>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(16);">QNAME Minimization</a></th>
                                                        <td>
                                                            <input type="radio" name="unbound_query_minimize" class="input" value="1">Yes
                                                            <input type="radio" name="unbound_query_minimize" class="input" value="0">No
                                                        </td>
                                                    </tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(14);">Recursion Style</a></th>
                                                    <td>
                                                        <select name="unbound_recursion" class="input_option">
                                                            <option value="default">Default</option>
                                                            <option value="passive">Passive</option>
                                                            <option value="aggressive">Aggressive</option>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(15);">Minimum TTL</a></th>
                                                    <td>
                                                        <input type="text" maxlength="4" class="input_6_table" id="unbound_ttl_min" onKeyPress="return validator.isNumber(this,event);" value="0">&nbsp;seconds
                                                        <span>Default: 0 Max: 1800</span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(17);">Cache root zone</a></th>
                                                    <td>
                                                        <input type="radio" name="unbound_cache_root" class="input" value="1">Yes
                                                        <input type="radio" name="unbound_cache_root" class="input" value="0">No
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(18);">Save cache on restart</a></th>
                                                    <td>
                                                        <input type="radio" name="unbound_save_cache" class="input" value="1">Yes
                                                        <input type="radio" name="unbound_save_cache" class="input" value="0">No
                                                    </td>
                                                </tr>
                                                <thead>
                                                    <tr>
                                                        <td colspan="2">Custom Configuration</td>
                                                    </tr>
                                                </thead>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(23);">Custom server: configuration</a></th>
                                                    <td>
                                                        <textarea rows="5" class="textarea_ssh_table" style="height:auto" id="unbound_custom_server" spellcheck="false" name="unbound_custom_server" cols="50" maxlength="2249"></textarea>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th><a class="hintstyle" href="javascript:void(0);" onclick="YazHint(24);">Custom extended configuration</a></th>
                                                    <td>
                                                        <textarea rows="5" class="textarea_ssh_table" style="height:auto" id="unbound_custom_extend" spellcheck="false" name="unbound_custom_extend" cols="50" maxlength="2249"></textarea>
                                                    </td>
                                                </tr>
                                            </table>
                                            <div class="apply_gen">
                                                <input name="button" type="button" class="button_gen" onclick="applySettings();" value="Apply" />
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
