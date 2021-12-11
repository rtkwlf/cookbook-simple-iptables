maintainer       "Arctic Wolf Networks"
maintainer_email "dev@arcticwolf.com"
license          "BSD"
description      "Simple LWRP and recipe for managing iptables rules"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.8.0"
name             "simple_iptables"
issues_url 'https://github.com/rtkwlf/cookbook-simple-iptables/issues'
source_url 'https://github.com/rtkwlf/cookbook-simple-iptables/'

supports "debian", ">= 6.0"
supports "centos", ">= 5.8"
supports "redhat", ">= 5.8"
supports "ubuntu", ">= 10.04"

chef_version '> 12.5.0'
