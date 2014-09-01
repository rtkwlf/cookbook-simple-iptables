include_recipe "simple_iptables::default"


simple_iptables_policy "INPUT" do
  policy "ACCEPT"
  ip_version :ipv4
end

simple_iptables_rule "established" do
  chain "INPUT"
  rule "-m conntrack --ctstate ESTABLISHED,RELATED"
  jump "ACCEPT"
  weight 1
  ip_version :ipv4
end

simple_iptables_rule "icmp" do
  chain "INPUT"
  rule "--proto icmp"
  jump "ACCEPT"
  weight 2
  ip_version :ipv4
end

simple_iptables_rule "loopback" do
  chain "INPUT"
  rule "--in-interface lo"
  jump "ACCEPT"
  weight 3
  ip_version :ipv4
end

simple_iptables_rule "ssh" do
  chain "INPUT"
  rule "--proto tcp --dport 22 -m conntrack --ctstate NEW"
  jump "ACCEPT"
  weight 70
  ip_version :ipv4
end

simple_iptables_rule "reject" do
  chain "INPUT"
  rule ""
  jump "REJECT --reject-with icmp-host-prohibited"
  weight 90
  ip_version :ipv4
end

simple_iptables_rule "reject" do
  direction "FORWARD"
  chain "FORWARD"
  rule ""
  jump "REJECT --reject-with icmp-host-prohibited"
  weight 90
  ip_version :ipv4
end
