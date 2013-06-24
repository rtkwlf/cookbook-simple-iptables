simple_iptables_rule "http" do
  rule [ "--proto tcp --dport 80" ]
  jump "ACCEPT"
end