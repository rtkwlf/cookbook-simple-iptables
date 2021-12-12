require 'serverspec'
set :backend, :exec

describe iptables do
  it { should have_rule('-A INPUT.* -j simple_rule') }
  it { should have_rule('-A simple_rule -p tcp -m tcp --dport 80.* -j ACCEPT') }
  it { should have_rule('-A INPUT -p tcp -m tcp --dport 81.* -j ACCEPT') }
  it { should have_rule('-A FORWARD -p tcp -m tcp --dport 82.* -j ACCEPT') }
  it { should have_rule('-A INPUT -m state --state NEW.* -j jump_with_rule') }
  it { should have_rule('-A jump_with_rule -p tcp -m tcp --dport 83.* -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 84.* -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 85.* -j ACCEPT') }
  it { should have_rule('-A INPUT.* -j array_of_rules') }
end

describe file('/etc/sysconfig/iptables') do
  its(:content) { should_not match /\*nat/ }
  its(:content) { should match /\*mangle/ }
  its(:content) { should match /\*filter/ }
  its(:content) { should_not match /\*raw/ }
end

describe ip6tables do
  it { should have_rule('-A INPUT.* -j simple_rule') }
  it { should have_rule('-A simple_rule -p tcp -m tcp --dport 80.* -j ACCEPT') }
  it { should have_rule('-A INPUT -p tcp -m tcp --dport 81.* -j ACCEPT') }
  it { should_not have_rule('-A FORWARD -p tcp -m tcp --dport 82.* -j ACCEPT') }
  it { should_not have_rule('-A INPUT -m state --state NEW.* -j jump_with_rule') }
  it { should_not have_rule('-A jump_with_rule -p tcp -m tcp --dport 83.* -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 84.* -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 85.* -j ACCEPT') }
  it { should have_rule('-A INPUT.* -j array_of_rules') }
end

describe file('/etc/sysconfig/ip6tables') do
  its(:content) { should_not match /\*nat/ }
  its(:content) { should match /\*mangle/ }
  its(:content) { should match /\*filter/ }
  its(:content) { should_not match /\*raw/ }
end
