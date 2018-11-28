# MarfeelLogicCDN
Marfeel logic on CDN for server-side device detection.

# 1. What is a CDN?
A CDN, or content delivery network, delivers the content from a publisher's website to users in faster and more efficient because it is based on the user's geographic location.

A CDN is made up of a network of servers all over the world called points of presence or POPs. The CDN that is closest to a user is referred to as the edge server. When a user requests content from a website served through a CDN, they're connected to the edge server closest to them. This ensures that the content they are browsing for is served to them the quickest, giving them the best browsing experience possible.

Websites temporarily store (also known as cache) their content on CDNs so that is can be delivered from an edge server much quicker than if it had to be delivered all the way from an origin server. When a user wants to access content from a website or mobile app that uses a CDN to host their content, that user's requests only has to travel to a nearby POP and back, not all the way back to the origin server.

# 2. What is the Marfeel server-side device detection on CDN?
[Garda](https://atenea.marfeel.com/atn/marfeel-press/marfeel-sdk/marfeel-garda "Marfeel Garda") is what allows Marfeel to show a partner's Marfeelized content under the publisher's URL and essentially activate their Marfeel [PWA](https://atenea.marfeel.com/atn/marfeel-press/360-platform/marfeel-progressive-webapps-pwas "Marfeel PWA").

Although this is the ultimate function of the Garda, the way it's engineered significantly impacts a Marfeel PWA's speed, performance, and therefore overall UX.

Its sophistication can be determined by how it limits interactions between servers and browsers, its ability to remove unnecessary script executions, and its capacity for limiting the resources loaded to deliver optimal speed.

When a user accesses a website, depending on the device they are using, one version of the site must be rendered (the desktop version or the mobile version). The Marfeel Premium CDN new configuration activates a publisher's Marfeel PWA (Progressive WebApp) and enables lightning-quick page speed that now, has gotten even faster because device detection occurs on the server-side.

This means that the right version to display to the user is executed on the first roundtrip and pushed "down the wire", saving several seconds off loading time and getting Marfeel closer to their goal of 0.7s and avoiding two entire round trips, saving you crucial time before the session starts.

Additionally, moving the activation logic from JavaScript to the server also avoids sending unnecessary and un-optimized assets meant for desktop.

# 3. How Marfeel server-side device detection on CDN works.
Marfeel creates a configuration based on device type on the Marfeel CDN platform pointing to Marfeel's backend servers. When a request from a mobile device is detected, instead of the browser asking for the HTML from the client's servers, the request is directed right to Marfeel's backend servers to display the partner's Marfeel version.

The original requests go to the Marfeel CDN platform, instead of the customer´s servers (you need to change your DNS entries for this). When a mobile device is detected, the request is directly sent to Marfeel's backend servers, instantly providing the user with the tenant's Marfeel version. If a desktop device is detected, the request is sent to customer´s origin servers, and a cached Desktop version is serverd to the end users.

This technique allows Marfeel to remove the interactions and any dependency on client-side servers, thereby significantly reducing the load time of the mobile page.

# 4. How you could build the device detection on your infrastructure.
You could do the device detection in your infrastructure servers and resend (proxy) this kinds of requests to the Marfeel CDN.
Then, the only thing you have to do is to check if the UserAgent...
- contains "windows phone|mobile.*firefox|tablet.*firefox"
- contains "(ip(hone|od).*?os )(?!1_|2_|3_|4_|X)|mozill?a.*android (?!(1|2|3)\.)[0-9].*mobile|bb10"
- contains "\bsilk\b"
- contains "(ipad.*?os )(?!1_|2_|3_|4_|x)"

And re-send/proxy these requests to Marfeel CDN (ssl.marfeelcdn.com).
