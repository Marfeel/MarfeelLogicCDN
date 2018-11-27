vcl 4.0;

import std;
import cookie;
import var;

backend default {
    .host = "52.0.145.3";
    .port = "80";
}

backend marfeel {
    .host = "54.194.23.213";
    .port = "443";
}

sub vcl_recv {

    # Set some values.
    var.set("mobile", "enabled");
    var.set("tablet", "enabled");
    var.set("amp", "enabled");
    var.set("ads", "enabled");
    var.set("sw", "enabled");
    var.set("version", "0.1");

   	# default conditions
   	set req.backend_hint = default;

   	if (req.restarts > 0 ) {
    	unset req.http.MRF-MarfeelDT;
      	unset req.http.marfeelOrigin;
      	set req.http.Device = "Desktop";
      	set req.url = req.http.X-Url;
      	set req.http.host = req.http.X-Host;
   	} else {
		unset req.http.MRF-MarfeelDT;
   		set req.http.Device = "Desktop";
   		set req.http.X-Url = req.url;
        set req.http.X-Host = req.http.host;   		
   	
        cookie.parse (req.http.cookie);

   		# Device Detection
   		if (var.get("mobile") == "enabled") {
      		if (req.http.User-Agent ~ "windows phone|mobile.*firefox|tablet.*firefox") {
         		unset req.http.MRF-MarfeelDT;
         		set req.http.Device = "Desktop";
      		} elsif (std.tolower(req.http.User-Agent) ~ "(ip(hone|od).*?os )(?!1_|2_|3_|4_|X)|mozill?a.*android (?!(1|2|3)\.)[0-9].*mobile|bb10") {
         		set req.http.MRF-MarfeelDT = "s";
         		set req.http.Device = "Mobile";
      		}
   		} elsif (var.get("tablet") == "enabled") {
      		if (std.tolower(req.http.User-Agent) ~ "\bsilk\b") {
         		set req.http.MRF-MarfeelDT = "s";
         		set req.http.Device = "Mobile";
      		} elsif (std.tolower(req.http.User-Agent) ~ "(ipad.*?os )(?!1_|2_|3_|4_|x)") {
         		set req.http.MRF-MarfeelDT = "l";
         		set req.http.Device = "Mobile";
      		}
   		}

   		if (std.tolower(req.url) ~ "marfeelgarda=off" || std.tolower(cookie.get("marfeelgarda")) ~ "off") {
      		set req.http.MRF-MarfeelDT = "l";
      		set req.http.Device = "Mobile";
   		}

   		if (std.tolower(req.url) ~ "fromt=yes" || std.tolower(cookie.get("fromt")) ~ "yes") {
      		unset req.http.MRF-MarfeelDT;
      		set req.http.Device = "Desktop";
   		}

   		# Set Requests For Marfeel Backend Origins
                set req.http.X-Qst = regsub(req.url, "^[^?]+\?", ""); // tatata=hi&foo1=true&bar2=false
                set req.http.X-Path = regsub(req.url, "\?.+$", "");  // /foo/bar
                set req.http.X-Ext = regsub( req.url, "\?.+$", "" ); // /foo/bar/index.html
                set req.http.X-Ext = regsub( req.http.ext, ".+\.([a-zA-Z]+)$", "\2" );

   		if (( std.tolower(req.http.Accept) ~ "html"
         		|| (req.http.Accept == "*/*" && std.tolower(req.http.X-Ext) ~ "htm|php|jsp|asp|^(?!.)")
      		) && std.tolower(req.http.X-Ext) !~ "(?i)^(gif|png|jpg|jpeg|webp|woff|ttf|ico)$" ) {
      
      		set req.http.marfeelOrigin = req.http.Device;

   		}

   		if (var.get("amp") == "enabled") {
      		  if (req.http.X-Path ~ "(.*)(/amp)(/?)$" || req.http.X-Path ~ "^(/)(amp/)(.*)") {
         	    set req.http.prefix = "/amp";
         	    unset req.http.MRF-MarfeelDT;
         	    set req.http.marfeelOrigin = "Mobile";
         	      if (req.http.X-Qst) {
                        set req.url = regsub(req.http.X-Path, "(.*)((/?)amp(/?))(/?)", "\1\3\?req.http.X-Qst");
                      } else {
                        set req.url = regsub(req.http.X-Path, "(.*)((/?)amp(/?))(/?)", "\1\3");
      		      }
                  }
   		}
   
   		if (var.get("ads") == "enabled" && req.http.X-Path == "/ads.txt") {
      		  set req.url = "/mds/" + req.http.host + req.url;
      		  set req.http.marfeelOrigin = "Mobile";
   		} elsif (var.get("sw") == "enabled" && req.url ~ "(/marfeel_sw\.)(js|html)(\?)?(.*)?$") {    
                  if (req.http.X-Forwarded-Proto ~ "(?i)https") {
                    set req.url = "/statics/marfeel/marfeel_sw." + req.http.X-Ext + "?" + req.http.X-Qst;
                  }
      		  set req.http.marfeelOrigin = "Mobile";
   		} elsif (req.http.X-Path ~ "^/mrf4u/"){
      		  set req.url = regsub(req.url, "^/mrf4u/","/");
      		  set req.http.marfeelOrigin = "Mobile";
   		} elsif (req.http.marfeelOrigin == "Mobile") {
      		  set req.url = req.http.prefix + "/" + req.http.host  + req.url;
      		  if (req.http.X-Qst !~ "marfeeldt=" && req.http.MRF-MarfeelDT) {
                    set req.url = req.url + "?marfeeldt=" + req.http.MRF-MarfeelDT; 
      		  }
   		}
   }

   return(hash);
}



sub vcl_hash {

  hash_data(req.http.Device);

}

sub vcl_miss {

  # Send Requests To Marfeel Backends
  if (req.http.marfeelOrigin == "Mobile") {
    set req.backend_hint = marfeel;
    ######set bereq.http.host = "backend.marfeelcache.com";
  }

}

sub vcl_pass {

  # Send Requests To Marfeel Backends
  if (req.http.marfeelOrigin == "Mobile") {
    set req.backend_hint = marfeel;
    ######set bereq.http.host = "backend.marfeelcache.com";
  }

}


sub try_stale_if_error {
#	if (obj.ttl < 0s && obj.ttl + obj.grace > 0s) {
#		if (bereq.retries == 0) {
#			set req.http.sie-enabled = true;
#			return (retry);
#		} else {
#			set req.http.sie-abandon = true;
#			return (deliver);
#		}
#	}
}

sub vcl_backend_response {

    ##TODO: restart logic
    if (bereq.retries > 0) {
        if (beresp.status >= 500 && beresp.status < 600){
          call try_stale_if_error;
        }
    }

    set beresp.http.MRF-tech = "CDN_" + var.get("mobile");
    
    if (bereq.http.marfeelOrigin == "Mobile" && bereq.retries < 1
            && (beresp.status == 307 || (beresp.status >= 400 && beresp.status <= 599))
            && (!bereq.is_bgfetch && (bereq.method == "GET" || bereq.method == "HEAD"))) {
      return (retry);
    }

   return(deliver);

}


sub vcl_backend_error {

  if (beresp.status >= 500 && beresp.status < 600){
    return (retry);
  }

}

