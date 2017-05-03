require "serverspec"

set :backend, :exec

describe iptables do
  it { should have_rule('-A INPUT -j simple_rule') }
  it { should have_rule('-A simple_rule -p tcp -m tcp --dport 80 -m comment --comment simple_rule -j ACCEPT') }
  it { should have_rule('-A INPUT -p tcp -m tcp --dport 81 -m comment --comment rule_in_input_chain -j ACCEPT') }
  it { should have_rule('-A FORWARD -p tcp -m tcp --dport 82 -m comment --comment rule_in_forward_chain -j ACCEPT') }
  it { should have_rule('-A INPUT -m state --state NEW -j jump_with_rule') }
  it { should have_rule('-A jump_with_rule -p tcp -m tcp --dport 83 -m comment --comment jump_with_rule -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 84 -m comment --comment array_of_rules -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 85 -m comment --comment array_of_rules -j ACCEPT') }
  it { should have_rule('-A INPUT -j array_of_rules') }
end
