sub vcl_recv {

  table mrf {
    "tablet":    "enabled",
  }

  unset req.http.MRF-MarfeelDT;
  set req.http.Device = "Desktop";

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

  return(lookup);

}

sub vcl_fetch {


}


