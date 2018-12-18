vcl 4.0;

import std;
import cookie;

backend default {
    .host = "origin.thecustomerdomain.com";
    .port = "443";
}

backend marfeel {
    .host = "backend.marfeelcache.com";
    .port = "443";
}

table mrf {
    "mobile":    "enabled",
    "tablet":    "enabled",
    "amp":       "enabled",
    "ads":       "enabled",
    "sw":        "enabled",
    "version":   "0.1"
}

sub vcl_recv {

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
   		if (table.lookup(mrf, "mobile") == "enabled") {
      		if (req.http.User-Agent ~ "windows phone|mobile.*firefox|tablet.*firefox") {
         		unset req.http.MRF-MarfeelDT;
         		set req.http.Device = "Desktop";
      		} elsif (std.tolower(req.http.User-Agent) ~ "(ip(hone|od).*?os )(?!1_|2_|3_|4_|X)|mozill?a.*android (?!(1|2|3)\.)[0-9].*mobile|bb10") {
         		set req.http.MRF-MarfeelDT = "s";
         		set req.http.Device = "Mobile";
      		}
   		} elsif (table.lookup(mrf, "tablet") == "enabled") {
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

   		if (std.tolower(req.url) ~ "marfeelgarda=no" || std.tolower(cookie.get("marfeelgarda")) ~ "no") {
      		unset req.http.MRF-MarfeelDT;
      		set req.http.Device = "Desktop";
   		}

   		if (std.tolower(req.url) ~ "fromt=yes" || std.tolower(cookie.get("fromt")) ~ "yes") {
      		unset req.http.MRF-MarfeelDT;
      		set req.http.Device = "Desktop";
   		}

   		# Set Requests For Marfeel Backend Origins
   		if (( std.tolower(req.http.Accept) ~ "html"
         		|| (req.http.Accept == "*/*" && std.tolower(req.url.ext) ~ "htm|php|jsp|asp|^(?!.)")
      		) && std.tolower(req.url.ext) !~ "(?i)^(gif|png|jpg|jpeg|webp|woff|ttf|ico)$" ) {
      
      		set req.http.marfeelOrigin = req.http.Device;

   		}

   		if (table.lookup(mrf, "amp") == "enabled") {
      		if (req.url.path ~ "(.*)(/amp)(/?)$" || req.url.path ~ "^(/)(amp/)(.*)") {
         		set req.http.prefix = "/amp";
         		unset req.http.MRF-MarfeelDT;
         		set req.http.marfeelOrigin = "Mobile";
         		set req.url = if(req.url.qs, re.group.1 re.group.3 "?" req.url.qs, re.group.1 re.group.3);
      		}
   		}
   
   		if (table.lookup(mrf, "ads") == "enabled" && req.url.path == "/ads.txt") {
      		set req.url = "/mds/" req.http.host req.url;
      		set req.http.marfeelOrigin = "Mobile";
   		} elsif (table.lookup(mrf, "sw") == "enabled" && req.url ~ "(/marfeel_sw\.)(js|html)(\?)?(.*)?$") {    
      		set req.url = if ( (req.http.X-Forwarded-Proto ~ "(?i)https") ), "/statics/marfeel/marfeel_sw." re.group.2 "?" req.url.qs, req.url);
      		set req.http.marfeelOrigin = "Mobile";
   		} elsif (req.url.path ~ "^/mrf4u/"){
      		set req.url = regsub(req.url, "^/mrf4u/","/");
      		set req.http.marfeelOrigin = "Mobile";
   		} elsif (req.http.marfeelOrigin == "Mobile") {
      		set req.url = req.http.prefix "/" req.http.host req.url;
      		if (req.url.qs !~ "marfeeldt=" && req.http.MRF-MarfeelDT) {
         		set req.url = querystring.add(req.url, "marfeeldt", req.http.MRF-MarfeelDT);
      		}
   		}
   }

   return(lookup);
}

sub vcl_backend_response {

	##TODO: restart logic
    if (req.restarts > 0) {
        if (beresp.status >= 500 && beresp.status < 600){
            if (stale.exists) {
                return(deliver_stale);
            }
        }
    }
    #FASTLY fetch
    set beresp.http.MRF-tech = "CDN_" table.lookup(mrf, "version");
    
    if (req.http.marfeelOrigin == "Mobile" && req.restarts < 1
            && (beresp.status == 307 || (beresp.status >= 400 && beresp.status <= 599))
            && (!bereq.is_bgfetch && (req.request == "GET" || req.request == "HEAD"))) {
        restart;
    }

   return(deliver);

}

sub vcl_miss {

   # Send Requests To Marfeel Backends
   if (req.http.marfeelOrigin == "Mobile") {
      set req.backend_hint = marfeel;
      set bereq.http.host = "backend.marfeelcache.com";
   }
}

sub vcl_pass {
   # Send Requests To Marfeel Backends
   if (req.http.marfeelOrigin == "Mobile") {
      set req.backend_hint = marfeel;
      set bereq.http.host = "backend.marfeelcache.com";
   }
}

sub vcl_hash {
	hash_data(req.http.Device);
}
