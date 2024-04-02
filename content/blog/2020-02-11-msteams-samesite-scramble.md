+++
title = "MS Teams SameSite Scramble"
slug = "teams-samesite-scramble"
date = 2020-02-11

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["web", "security"]
+++

## Microsoft Teams

Microsoft released their Teams chat application in 2017, but the platform didn't pick up for some time and particularly gained traction after certain _bundles_ with other software such as Office and Windows Server setups for businesses. This is an [Electron] app, so at its core it's really an embedded Chrome instance running a web application with hooks into certain native functionalities, window management, and more. But you can consider MS Teams to effectively behave like Chrome when it comes to web standards.

## SameSite

[SameSite] refers to a cookie attribute that control the security behaviors around cookies across domains. When cookies are set, they can have a SameSite property set to one of several values: `Strict`, `Lax`, and `None`. The 

To quote from MDN what each of these values mean:

**Strict**
 
> Means that the browser sends the cookie only for same-site requests, that is, requests originating from the same site that set the cookie. If a request originates from a different domain or scheme (even with the same domain), no cookies with the SameSite=Strict attribute are sent.

**Lax**
 
> Means that the cookie is not sent on cross-site requests, such as on requests to load images or frames, but is sent when a user is navigating to the origin site from an external site (for example, when following a link). This is the default behavior if the SameSite attribute is not specified.

**None**
 
> means that the browser sends the cookie with both cross-site and same-site requests. The Secure attribute must also be set when setting this value, like so SameSite=None; Secure. If Secure is missing an error will be logged

As browser's increase their security rules to protect their users, defaults around these types of configurations shift.

## The Incompatibility

The issue came up as a console log in the application that indicated what went wrong and suggestions for how to resolve it:

> Because a cookie's SameSite attribute was not set or is invalid, it defaults to SameSite=Lax, which will prevents the cookie from being set in a cross-site context in a future version of the browser. This behavior protects user data from accidentally leaking to third parties and cross-site request forgery.
>
> Resolve this issue by updating the attributes of the cookie:
>
> Specify SameSite=None and Secure if the cookie is intended to be set in cross-site contexts. Note that only cookies sent over 
>
> HTTPS may use the Secure attribute.
>
> Specify SameSite=Strict or SameSite=Lax if the cookie should not be set by cross-site requests

The root cause of this was a change in behavior for how Google Chrome handled the `SameSite=None` cookie attributes in version 67. Because a MS Teams app needs to be able a large range of browsers, just like a traditional web app. Since this change made it incompatible with the SameSite behavior of older versions of Chrome and other browsers, it had to be accounted for dynamically. Effectively, all versions of Chrome between 51.x and 67.x exhibited this issue.

## The Solution

A JavaScript function that validates the current browser and checks whether the UserAgent matches a Microsoft Teams desktop clients with older Chromium versions incorrectly handle cookies with the SameSite=None property. We check for Teams clients with Chrome versions >= `51.x` < `67.x`. This method returns true if an invalid user agent is not found. Cases that are not known may fall through, this was based on testing with macOS, Windows, and Linux clients for Microsoft Teams.

```ts
const lowerIncompatibleVersion = 51;
const compatibleVersion = 67;
const teamsChromePattern = /(Teams|MicrosoftTeams-Insiders)\/[\d\.]+ Chrome\/([\d\.]+)/;

export function incompatible(userAgent?: string | null) {
  if (!userAgent) {
    return false;
  }

  const match = userAgent.match(teamsChromePattern);
  if (!match) {
    return false;
  }

  let teamsVersion = 0;
  try {
    let majorVersion = match[2].split(".")[0];
    teamsVersion = parseInt(majorVersion);
  } catch (err) {
    return false;
  }

  return (
    teamsVersion < compatibleVersion &&
    teamsVersion >= lowerIncompatibleVersion
  )
}
```

With this function, we can detect an unsupported scenario for our security rules and then provide an alternative method of interacting with our app. In the scenario this was built around, our account linking process for the platform to a Microsoft Teams account was breaking due to this incompatibility, and this allowed us to externalize the process to another browser to continue the flow.

The source code for this can be found on my GitHub under the [msteams-samesite-compatibility-validator] project.

<!-- References -->

[msteams-samesite-compatibility-validator]: https://github.com/tcarrio/msteams-samesite-compatibility-validator
[SameSite]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#samesitesamesite-value