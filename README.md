[![Build Status](https://travis-ci.org/rtkwlf/cookbook-simple-iptables.png?branch=master)](https://travis-ci.org/rtkwlf/cookbook-simple-iptables)

Description
===========

Simple cookbook with LWRPs for managing iptables rules and policies.

Requirements
============

None, other than a system that supports iptables.


Platforms
=========

The following platforms are supported and known to work:

* Debian (6.0 and later)
* RedHat (5.8 and later)
* CentOS (5.8 and later)
* Ubuntu (10.04 and later)

Other platforms that support `iptables` and the `iptables-restore` script
are likely to work as well; if you use one, please let me know so that I can
update the supported platforms list.

Attributes
==========

This cookbook uses node attributes to track internal state when generating
the iptables rules and policies. These attributes _should not_ be overridden
by roles, other recipes, etc.

Usage
=====

Include the recipe `simple_iptables` somewhere in your run list, then use
the LWRPs `simple_iptables_rule` and `simple_iptables_policy` in your
recipes.

`simple_iptables_rule` Resource
-------------------------------

Defines a single iptables rule, composed of a rule string (passed as-is to
iptables), and a jump target. The name attribute defines an iptables chain
that this rule will live in (and, thus, that other rules can jump to). For
instance:

    # Allow SSH
    simple_iptables_rule "ssh" do
      rule "--proto tcp --dport 22"
      jump "ACCEPT"
    end

For convenience, you may also specify an array of rule strings in a single
LWRP invocation:

    # Allow HTTP, HTTPS
    simple_iptables_rule "http" do
      rule [ "--proto tcp --dport 80",
             "--proto tcp --dport 443" ]
      jump "ACCEPT"
    end

Additionally, if you want to declare a module (such as log) you can define jump as false:

    # Log
    simple_iptables_rule "system" do
      rule "--match limit --limit 5/min --jump LOG --log-prefix \"iptables denied: \" --log-level 7"
      jump false
    end

By default rules are added to the filter table but the nat and mangle tables are also supported. For example:

    # Tomcat redirects
    simple_iptables_rule "tomcat" do
      table "nat"
      direction "PREROUTING"
      rule [ "--protocol tcp --dport 80 --jump REDIRECT --to-port 8080",
             "--protocol tcp --dport 443 --jump REDIRECT --to-port 8443" ]
      jump false
    end

    #mangle example
    #NOTE: set jump to false since iptables expects the -j MARK --set-mark in that order
    simple_iptables_rule "mangle" do
      table "mangle"
      direction "PREROUTING"
      jump false
      rule "-i eth0 -j MARK --set-mark 0x6
    end

    #reject all outbound connections attempts to 10/8 on a dual-homed host
    simple_iptables_rule "reset_10slash8_outbound" do
      direction "OUTPUT"
      jump false
      rule "-p tcp -o eth0 -d 10/8 --jump REJECT --reject-with tcp-reset"
    end

By default rules are added to the chain, in the order in which its occur in the recipes.
You may use the weight parameter for control the order of the rules in chains. For example:

    simple_iptables_rule "reject" do
      direction "INPUT"
      rule ""
      jump "REJECT --reject-with icmp-host-prohibited"
      weight 90
    end

    simple_iptables_rule "established" do
      direction "INPUT"
      rule "-m conntrack --ctstate ESTABLISHED,RELATED"
      jump "ACCEPT"
      weight 1
    end

    simple_iptables_rule "icmp" do
      direction "INPUT"
      rule "--proto icmp"
      jump "ACCEPT"
      weight 2
    end

This would generate the rules:

    -A INPUT --jump ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED
    -A INPUT --jump ACCEPT --proto icmp
    -A INPUT --jump REJECT --reject-with icmp-host-prohibited

Defining a `simple_iptables_rule` resource actually creates a new chain with the name of
the resource and a jump to the chain from the chain specified in the `direction` attribute.
By default, the jump is unconditional. However, the `chain_condition` attribute can be
specified to make the jump conditional. For example:

    simple_iptables_rule "management_interface" do
      direction "INPUT"
      chain_condition "-i eth1"
      rule [ "-p tcp --dport 80", "-p tcp --dport 443" ]
      jump "ACCEPT"
    end

The rules specified under the `rule` attribute will only be evaluate for packets for which
the rule in `chain_condition` holds.

Sometimes we might want to define a chain where we only want to jump from another chain we define. 
By default, an automatic jump will be made to chains defined using the `simple_iptables_rule` resource
from the chain specified using the `direction` attribute of the resource. To prevent jumping to the
chain from the direction chains, we can set the direction attribute to the symbol `:none`.
For example, consider a chain used to log

    simple_iptables_rule "logging_drop" do
      direction :none
      rule ['-j LOG --log-level 4 --log-prefix "IPTABLES_DROP: "',
            '-j DROP']
      jump false
    end

We can then jump to this chain from other simple_iptables_rule chains, but an automatic jump to
this chain won't be added.

By default, the name of the `simple_iptables_resource` is also used for an `iptables` comment.
This default can be overridden by explicitly specifying a `comment` attribute.


`simple_iptables_policy` Resource
---------------------------------

Defines a default action for a given iptables chain. This is usually used to
switch from a default-accept policy to a default-reject policy. For
instance:

    # Reject packets other than those explicitly allowed
    simple_iptables_policy "INPUT" do
      policy "DROP"
    end

As with the `simple_iptables_rules` resource, policies are applied to the filter table
by default. You may change the target table to nat as follows:

    # Reject packets other than those explicitly allowed
    simple_iptables_policy "INPUT" do
      table "nat"
      policy "DROP"
    end

`redhat.rb` recipe
------------------
`redhat.rb` recipe contains default iptables rules for redhat based distributions, such as RHEL, CentOS and etc. You may include `simple_iptables::redhat` on your linux and get following rules:
```
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed
# This file generated by Chef. Changes will be overwritten.
*mangle
:PREROUTING ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
# Completed
# This file generated by Chef. Changes will be overwritten.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT --jump ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED
-A INPUT --jump ACCEPT --proto icmp
-A INPUT --jump ACCEPT --in-interface lo
-A INPUT --jump ACCEPT --proto tcp --dport 22 -m conntrack --ctstate NEW
-A INPUT --jump REJECT --reject-with icmp-host-prohibited
-A FORWARD --jump REJECT --reject-with icmp-host-prohibited
COMMIT
# Completed
# This file generated by Chef. Changes will be overwritten.
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
# Completed
```

`IPv6` support
--------------

To support IPv6, you will need to add `ipv6` the attribute like:
default["simple_iptables"]["ip_versions"] = ["ipv4", "ipv6"]

When using `simple_iptables_policy` or `simple_iptables_rule` resources, you
can enable the policy/rule for either `:ipv4`, `:ipv6` or `:both` using the
`ip_version` parameter. For example:

    simple_iptables_rule "management_interface" do
      direction "INPUT"
      chain_condition "-i eth1"
      rule [ "-p tcp --dport 80", "-p tcp --dport 443" ]
      jump "ACCEPT"
      ip_version :both
    end

will set the rule for both IPv4 and IPv6,

    simple_iptables_rule "management_interface" do
      direction "INPUT"
      chain_condition "-i eth1"
      rule [ "-p tcp --dport 80", "-p tcp --dport 443" ]
      jump "ACCEPT"
      ip_version :ipv6
    end

will set it for IPv6 only. The default is to set the rule/policy for ipv4 only.


Example
=======

Suppose you had the following `simple_iptables` configuration:

    # Reject packets other than those explicitly allowed
    simple_iptables_policy "INPUT" do
      policy "DROP"
    end
    
    # The following rules define a "system" chain; chains
    # are used as a convenient way of grouping rules together,
    # for logical organization.
    
    # Allow all traffic on the loopback device
    simple_iptables_rule "system" do
      rule [ # Allow all traffic on the loopback device
             "--in-interface lo",
             # Allow any established connections to continue, even
             # if they would be in violation of other rules.
             "-m conntrack --ctstate ESTABLISHED,RELATED",
             # Allow SSH
             "--proto tcp --dport 22",
           ]
      jump "ACCEPT"
    end
    
    # Allow HTTP, HTTPS
    simple_iptables_rule "http" do
      rule [ "--proto tcp --dport 80",
             "--proto tcp --dport 443" ]
      jump "ACCEPT"
    end
    
    # Tomcat redirects
    simple_iptables_rule "tomcat" do
      table "nat"
      direction "PREROUTING"
      rule [ "--protocol tcp --dport 80 --jump REDIRECT --to-port 8080",
             "--protocol tcp --dport 443 --jump REDIRECT --to-port 8443" ]
      jump false
    end

This would generate a file `/etc/iptables-rules` with the contents:

    # This file generated by Chef. Changes will be overwritten.
    *nat
    :PREROUTING ACCEPT [0:0]
    :INPUT ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :POSTROUTING ACCEPT [0:0]
    :tomcat - [0:0]
    -A PREROUTING --jump tomcat
    -A tomcat --protocol tcp --dport 80 --jump REDIRECT --to-port 8080
    -A tomcat --protocol tcp --dport 443 --jump REDIRECT --to-port 8443
    COMMIT
    # Completed
    # This file generated by Chef. Changes will be overwritten.
    :PREROUTING ACCEPT [0:0]
    :INPUT ACCEPT [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :POSTROUTING ACCEPT [0:0]
    COMMIT
    # Completed
    # This file generated by Chef. Changes will be overwritten.
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :system - [0:0]
    :http - [0:0]
    -A INPUT --jump system
    -A system --in-interface lo --jump ACCEPT
    -A system -m conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
    -A system --proto tcp --dport 22 --jump ACCEPT
    -A INPUT --jump http
    -A http --proto tcp --dport 80 --jump ACCEPT
    -A http --proto tcp --dport 443 --jump ACCEPT
    COMMIT
    # Completed
    # This file generated by Chef. Changes will be overwritten.
    *raw
    :PREROUTING ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    COMMIT
    # Completed

Which results in the following iptables configuration:

    # iptables -L
    Chain INPUT (policy DROP)
    target     prot opt source               destination         
    system     all  --  anywhere             anywhere            
    http       all  --  anywhere             anywhere            
    
    Chain FORWARD (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain http (1 references)
    target     prot opt source               destination         
    ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:http
    ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:https
    
    Chain system (1 references)
    target     prot opt source               destination         
    ACCEPT     all  --  anywhere             anywhere            
    ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
    ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:ssh

    #iptables -L -t nat
    Chain PREROUTING (policy ACCEPT)
    target     prot opt source               destination         
    tomcat     all  --  anywhere             anywhere            
    
    Chain INPUT (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain OUTPUT (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain POSTROUTING (policy ACCEPT)
    target     prot opt source               destination         
    
    Chain tomcat (1 references)
    target     prot opt source               destination         
    REDIRECT   tcp  --  anywhere             anywhere             tcp dpt:http redir ports 8080
    REDIRECT   tcp  --  anywhere             anywhere             tcp dpt:https redir ports 8443

Changes
=======
* 0.7.1 (Feburary 5, 2015)
    * Allow setting comment for rule (#57 - TheMeier)
    * Load rules on reboot on RHEL 7 and later (#58 - TheMeier)
    * Use the `simple_iptables_rule` resource name as the comment by default (#63 - dblessing)
    * Fix bug allowing duplicate entries (#60 - roman-yepishev-enoc)
    * Add ChefSpec matchers (#64 - dblessing)
* 0.7.0 (September 6, 2014)
    * Add ip6tables (IPv6) support (#56 - chantra)
    * Add `:none` to one of the values that the attribute `direction` can be set to.
      When set to :none, a rule to jump to the chain created will not be added to any
      direction chains (#54 - Kevin Deng)
    * Add `node.simple_iptables.tables` attribute to specify the tables for which rules
      will be generated (#53 - Pavel Yudin)
    * Add Test Kitchen tests (#51 - Pavel Yudin)
* 0.6.5 (July 20, 2014)
    * Fix one-shot testing code to work with Chef versions prior to 11.12.
    * Make one-shot testing error line detection code more robust (#48 - Kim Tore Jensen)
    * Add `chain_condition` attribute to `rule` provider. This allows to specify
      a condition which is tested before jumping to the chain.
      If a `chain_condition` is not specified, the jump is unconditional, as before.
    * Fix README examples to use `direction` attribute rather than `chain`.
* 0.6.4 (June 8, 2014)
    * Change testing mechanism to use `iptables-restore --test`. This tests
      all rules at once and results in much better performance. In case of a
      failure, the rule causing it is included in the exception raised.
* 0.6.3 (May 30, 2014)
    * Change how default attributes are set in `attributes/default.rb` file for
      consistency with how they are set when they are cleared in
      `simple_iptables` recipe
    * Clarify in the README that the `simple_iptables` recipe needs to be included
      before any of the resources provided by the cookbook are used
    * The changes in this version are to address #37
* 0.6.2 (May 27, 2014)
    * Add default iptables rules for redhat platfrom (#41 - Pavel Yudin)
    * Add case for fedora platform (#38 - Jordan Evans)
* 0.6.1 (April 14, 2014)
    * Add support mechanism weights.
* 0.6.0 (March 19, 2014)
    * Add support for the raw table (#33 - Ray Ruvinskiy)
    * Add :delete semantics to iptables rules (#34 - Michael Parrott)
* 0.5.2 (March 19, 2014)
    * Fix #21, error parsing node\['kernel'\]\['release'\] (#30 - Michael Parrott)
* 0.5.1 (March 18, 2014)
    * Update README example so Chef doesn't warn duplicate resources (#32 - Michael Parrott)
* 0.5.0 (March 18, 2014)
    * Extend cleanup and test code (#31 - Sander van Harmelen)
    * Disallow adding built-in chains multiple times (#31 - Sander van Harmelen)
* 0.4.0 (May 9, 2013)
    * Update foodcritic version used in Travis-CI (#29 - Michael Parrott)
    * Added support for mangle table (#18 - Michael Hart)
    * Updated Gemfile to 11.4.4 (#18 - Michael Hart)
* 0.3.0 (March 5, 2013)
    * Added support for nat table (#10 - Nathan Mische)
    * Updated Gemfile for Travis-CI integration (#10 - Nathan Mische)
* 0.2.4 (Feb 13, 2013)
    * Fixed attribute precedence issues in Chef 11 (#9 - Warwick Poole)
    * Added `name` to metadata to satisfy recent foodcritic versions
* 0.2.3 (Nov 10, 2012)
    * Fixed a warning in Chef 11+ (#7 - Hector Castro)
* 0.2.2 (Oct 13, 2012)
    * Added support for logging module and other non-jump rules (#6 - phoolish)
* 0.2.1 (Aug 5, 2012)
    * Fixed a bug using `simple_iptables` with chef-solo (#5)
* 0.2.0 (Aug 1, 2012)
    * Allow an array of rules in `simple_iptables_rule` LWRP (Johannes Becker)
    * RedHat/CentOS compatibility (David Stainton)
    * Failing `simple_iptables_rule`s now fail with a more helpful error message
* 0.1.2 (July 24, 2012)
    * Fixed examples in README (SchraderMJ11)
* 0.1.1 (May 22, 2012)
    * Added Travis-CI integration (Nathen Harvey)
    * Fixed foodcritic warnings (Nathen Harvey)
* 0.1.0 (May 12, 2012)
    * Initial release

