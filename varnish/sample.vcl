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
    "amp":       "disabled",
  }

  if (table.lookup(mrf, "mobile") == "disabled") {
    return(lookup);
  }

  unset req.http.MRF-MarfeelDT;
  set req.http.Device = "Desktop";

  # Device Detection
  if (std.tolower(req.http.User-Agent) ~ "windows phone|mobile.*firefox|tablet.*firefox") {
    unset req.http.MRF-MarfeelDT;
    set req.http.Device = "Desktop";
  }
  elsif (std.tolower(req.http.User-Agent) ~ "(ip(hone|od).*?os )(?!1_|2_|3_|4_|X)|mozill?a.*android (?!(1|2|3)\.)[0-9].*mobile|bb10") {
    set req.http.MRF-MarfeelDT = "s";
    set req.http.Device = "Mobile";
  }
  elsif (table.lookup(mrf, "tablet") == "enabled") {
    if (std.tolower(req.http.User-Agent) ~ "\bsilk\b") {
      set req.http.MRF-MarfeelDT = "s";
      set req.http.Device = "Mobile";
    }
    elsif (std.tolower(req.http.User-Agent) ~ "(ipad.*?os )(?!1_|2_|3_|4_|x)") {
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
  if ((std.tolower(req.http.Accept) ~ "html"
  || (req.http.Accept ~ "/" && std.tolower(req.url.ext) ~ "htm|php|jsp|asp|^(?!.)"))
  && std.tolower(req.url.ext) !~ "(?i)^(gif|png|jpg|jpeg|webp|woff|ttf|ico)$" ) {
      set req.http.marfeelOrigin = req.http.Device;
  }

    # AMP Start
    if (table.lookup(mrf, "amp") == "enabled") {
      if (req.url.path ~ "(.*)(/amp)(/?)$" || req.url.path ~ "^(/)(amp/)(.*)") {
        set req.http.prefix = "/amp";
        unset req.http.MRF-MarfeelDT;
        set req.http.marfeelOrigin = "Mobile";
        set req.url = if(req.url.qs, re.group.1 re.group.3 "?" req.url.qs, re.group.1 re.group.3);
      }
    }
    if (table.lookup(mrf, "amp") == "redirect"){
      if (req.url.path ~ "(.*)(/amp)(/?)$" || req.url.path ~ "^(/)(amp/)(.*)") {
        unset req.http.MRF-MarfeelDT;
        set req.http.marfeelOrigin = "Desktop";
        set req.url = if(req.url.qs, re.group.1 re.group.3 "?" req.url.qs, re.group.1 re.group.3);
        error 756 "Redirect to canonical URL";
        }
    }
    # AMP End

  if (req.url.path == "/index.fbinstant.xml") {
      set req.url = "/hub/marfeel/" req.http.host req.url;
      set req.http.marfeelOrigin = "Mobile";
  }
  elsif (req.url.path == "/ads.txt") {
      set req.url = "/mds/" req.http.host req.url;
      set req.http.marfeelOrigin = "Mobile";
  }
  elsif (req.url.path ~ "^/sitemap(.*).xml") {
      set req.url = "/statics/" req.http.host "/index/resources/sitemap" re.group.1 ".xml";
      set req.http.marfeelOrigin = "Mobile";
  }
  elsif (req.url.path ~ "^/sitemaps/(.*)") {
      set req.url = "/statics/" req.http.host "/index/resources/" re.group.1 ;
      set req.http.marfeelOrigin = "Mobile";
  }
  elsif (req.url ~ "(/marfeel_sw\.)(js|html)(\?)?(.*)?$") {
        set req.url = if ( (req.http.X-Forwarded-Proto ~ "(?i)https") ), "/statics/marfeel/marfeel_sw." re.group.2 "?" req.url.qs, req.url);
        set req.http.marfeelOrigin = "Mobile";
  }  
  elsif (req.url.path ~ "/statics/marfeel/fonts/icons-font.ttf") {
      set req.http.marfeelOrigin = "Mobile";
  }
  elsif (req.url.path ~ "^/mrf4u/"){
      set req.url = regsub(req.url, "^/mrf4u/","/");
      set req.http.marfeelOrigin = "Mobile";
  }
  elsif (req.http.marfeelOrigin ~ "Mobile") {
      set req.url = req.http.prefix "/" req.http.host req.url;
      if (req.url.qs !~ "marfeeldt=" && req.http.MRF-MarfeelDT) {
         set req.url = querystring.add(req.url, "marfeeldt", req.http.MRF-MarfeelDT);
      }
  }


  return(lookup);

}

sub vcl_fetch {


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

