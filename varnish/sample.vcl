sub vcl_recv {

   backend origin_desktop_backend {
      .host = "origin.thecustomerdomain.com";
      .port = "443";
   }

   backend marfeelcache_com_backend {
      .host = "backend.marfeelcache.com";
      .port = "443";
   }

   # default conditions
   set req.backend = origin_desktop_backend;

   table mrf {
      "mobile":    "enabled",
      "tablet":    "enabled",
      "amp":       "enabled",
      "ads":       "enabled",
      "sw":        "enabled"
   }
  
   unset req.http.MRF-MarfeelDT;
   set req.http.Device = "Desktop";

   ##TODO: restart logic
   
   # Device Detection
   if (table.lookup(mrf, "mobile") == "enabled") {
      if (std.tolower(req.http.User-Agent) ~ "windows phone|mobile.*firefox|tablet.*firefox") {
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

   if (std.tolower(req.url) ~ "marfeelgarda=off" || std.tolower(req.http.Cookie:marfeelgarda) ~ "off") {
      set req.http.MRF-MarfeelDT = "l";
      set req.http.Device = "Mobile";
   }

   if (std.tolower(req.url) ~ "fromt=yes" || std.tolower(req.http.Cookie:fromt) ~ "yes") {
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

   return(lookup);
}

sub vcl_fetch {

   ##TODO: restart logic

}

sub vcl_miss {

   # Send Requests To Marfeel Backends
   if (req.http.marfeelOrigin ~ "Mobile") {
      set req.backend = marfeelcache_com_backend;
      set bereq.http.host = "backend.marfeelcache.com";
   }
}

sub vcl_pass {
   # Send Requests To Marfeel Backends
   if (req.http.marfeelOrigin ~ "Mobile") {
      set req.backend = marfeelcache_com_backend;
      set bereq.http.host = "backend.marfeelcache.com";
   }
}

