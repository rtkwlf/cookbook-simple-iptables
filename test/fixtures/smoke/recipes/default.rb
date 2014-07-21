include_recipe "simple_iptables::default"

simple_iptables_rule 'simple_rule' do
  rule '-p tcp --dport 80'
  jump 'ACCEPT'
end

simple_iptables_rule 'rule_in_input_chain' do
  chain 'INPUT'
  rule '-p tcp --dport 81'
  jump 'ACCEPT'
end

simple_iptables_rule 'rule_in_forward_chain' do
  chain 'FORWARD'
  direction 'FORWARD'
  rule '-p tcp --dport 82'
  jump 'ACCEPT'
end

simple_iptables_rule 'jump_with_rule' do
  rule '-p tcp --dport 83'
  chain_condition '-m state --state NEW'
  jump 'ACCEPT'
end

simple_iptables_rule 'array_of_rules' do
  rule ['-p tcp --dport 84',
        '-p tcp --dport 85']
  jump 'ACCEPT'
end