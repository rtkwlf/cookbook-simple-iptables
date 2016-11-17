include_recipe "simple_iptables"

simple_iptables_rule "rule1" do
  direction "INPUT"
  rule "rule1 content"
  jump "ACCEPT"
end

simple_iptables_rule "rule2" do
  direction "INPUT"
  rule "rule2 content"
  jump "ACCEPT"
end

simple_iptables_rule "rule3" do
  direction "INPUT"
  rule "rule3 content"
  jump "REJECT"
  weight 95
end

simple_iptables_rule "rule4" do
  direction "INPUT"
  rule ["rule4.1 content", "rule4.2 content"]
  jump "ACCEPT"
end

simple_iptables_rule "rule5" do
  direction "INPUT"
  rule "rule5 content"
  jump "ACCEPT"
end

simple_iptables_rule "rule6" do
  direction "INPUT"
  rule "rule6 content"
  jump "REJECT"
  weight 95
end
