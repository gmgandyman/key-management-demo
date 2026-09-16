# 001: Choosing an OIDC provider
## Date: 2026-09-14
## Status: Pending
## Context
Linux user accounts and key management is too burdensome and error-prone to maintain user accounts across
the stack. One lost or stolen key triggers an enormous burden that has to be automated through web
interfaces or bash scripts, which is why I assume no modern Internal Developer Platform (IDP) is using
them any longer.

So if I'm moving to a centralized authentication solution, what jobs does it need to fill?

1. Session-based human logins through a web form (SSO, OIDC w/ PKCE, SAML, etc.)
2. Machine-to-Machine communication, stateless (mTLS, OIDC w/ JWT, etc.)
3. Legacy Public Key Infrastructure (PKI) - this is legacy in a cloud native world, but I still have legacy
    full Linux containers in this stack

Some of this we can avoid for now. I am not looking for a full SAML implementation that integrates
with an existing enterprise SSO solution. No Entra ID, etc. A session-based OIDC for humans, stateless OIDC
for machines, and some PKI replacement until I can lighten the Linux containers in this app will work.

## Options
#### Keycloak
The industry standard. It handles human and machine authentication fine, along with a lot of other services
I won't use. But it also provides nothing out of the box for PKI, unless I add a plugin. It does use
Postgres as its database. Also, it has an incredibly heavy memory footprint at 700MB for a container 
and 2GB for full instances.

Summary: It's too much for what I need.

#### Ory with (Kratos + Hydra)
Hydra provides the session based OIDC, Kratos can provide UI for administration of it. Hydra also handles
stateless OIDC. However, it requires a bridge OIDC-to-SSH provider to act as a PKI replacement.

This is closer to what I want, but it's still mostly a set of services to build your own things on.
1. No login form for the session based OIDC
2. Strongest M2M layer, until you need scopes of what a machine can do. Hydra covers a coarse-grained ACL,
  but you have to bring in Keto for RBAC
3. No PKI, so I need Step CA for that
4. This looks like it could have up to 6 different services/containers running for all of this. 
  That's too heavy.

#### Authelia
This is arguably the lightest weight solution. It provides the session based OIDC, but it doesn't really
provide M2M or PKI solutions/replacements without a lot of additional wiring.

Summary: I need more than just session-based OIDC.

#### Authentik
It handles session based OIDC, even SAML, for humans. It has stateless OIDC/OAuth2 for M2M. PKI is 
repalced by their Proxy Outpost, which is a fancy version of a Bastion jump host, except fully in 
the browser.

Honestly, everything about this reads like they have poured resources into the web portal side of things.
It supports tons of customized login flows for users doing session-based logins, it provides SSH access
through this portal.

It's quite a bit weaker on the M2M side though, as I cannot find much in the way of ACL or RBAC settings
for this. Also, by forcing users through a browser based terminal, the suite of apps around SSH are no longer an
option.

#### Zitadel (zitadel app + login + step CA (short-lived certs) )
It handles session based OIDC through the login container, first class handling of M2M with RBAC, and
integrates with Step CA for short-lived certificates through existing SSH tooling.

The M2M side is flawless. I am unlikely to have authorization exceptions for services, so RBAC is the
better fit here. The front end is nowhere near as polished or feature complete as Authentik. Also,
using Zitadel with my existing Nginx proxy requires Nginx to establish connections to Zitadel using
unencrypted HTTP/2 over TCP.

## Decision
It's quite easy to dismiss 3 of the 5 offered here:
* Keycloak is too much for my needs and too heavy to setup
* Authelia is a session-based OIDC provider only, not what I need
* Ory looks like it is designed for teams building their own Identification Provider. That's not me.

So now the choice is between Authentik and Zitadel + Step CA. In passing, neither one looks much heavier or more
difficult to wire up. So the decision comes down to where I want to target, the session-based OIDC or M2M OIDC. In this
case, my current problem is M2M communications and PKI replacement, so the decision becomes clear:

It's Zitadel.

## Footgun
Once the stack becomes more fully mature, the very decision criteria I used here is probably going to switch back
in favor of Authentik. Unfortunately, I cannot place the distant future in front of the immediate future.