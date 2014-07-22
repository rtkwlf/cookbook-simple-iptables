require_relative '../../../kitchen/data/spec_helper'

describe iptables do
  it { should have_rule('-A INPUT -j simple_rule') }
  it { should have_rule('-A simple_rule -p tcp -m tcp --dport 80 -j ACCEPT') }
  it { should have_rule('-A INPUT -p tcp -m tcp --dport 81 -j ACCEPT') }
  it { should have_rule('-A FORWARD -p tcp -m tcp --dport 82 -j ACCEPT') }
  it { should have_rule('-A INPUT -m state --state NEW -j jump_with_rule') }
  it { should have_rule('-A jump_with_rule -p tcp -m tcp --dport 83 -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 84 -j ACCEPT') }
  it { should have_rule('-A array_of_rules -p tcp -m tcp --dport 85 -j ACCEPT') }
  it { should have_rule('-A INPUT -j array_of_rules') }
  it { should_not have_rule('*nat') }
  it { should have_rule('*mangle') }
  it { should have_rule('*filter') }
  it { should_not have_rule('*raw') }
end
