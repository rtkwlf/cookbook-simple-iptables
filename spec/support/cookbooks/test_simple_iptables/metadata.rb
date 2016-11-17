maintainer       "Arctic Wolf Networks"
maintainer_email "dev@arcticwolf.com"
license          "BSD"
description      "Support cookbook for ChefSpec tests for simple_iptables"
version          "1.0.0"
name             "test_simple_iptables"

supports "debian", ">= 6.0"
supports "centos", ">= 5.8"
supports "redhat", ">= 5.8"
supports "ubuntu", ">= 10.04"

depends "simple_iptables"
