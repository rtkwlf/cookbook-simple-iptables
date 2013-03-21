require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :append do
  if new_resource.rule.kind_of?(String)
    rules = [new_resource.rule]
  else
    rules = new_resource.rule
  end

  test_rules(new_resource, rules)

  if not node["simple_iptables"][new_resource.table]["chains"].include?(new_resource.chain)
    node.set["simple_iptables"][new_resource.table]["chains"][new_resource.chain] = ["-A #{new_resource.direction} --jump #{new_resource.chain}"]
  end

  # Then apply the rules to the node
  rules.each do |rule|
    new_rule = rule_string(new_resource, rule, false)
    if not node["simple_iptables"][new_resource.table]["chains"][new_resource.chain].include?(new_rule)
      node.set["simple_iptables"][new_resource.table]["chains"][new_resource.chain] = node["simple_iptables"][new_resource.table]["chains"][new_resource.chain].dup << new_rule
      new_resource.updated_by_last_action(true)
      Chef::Log.debug("added rule '#{new_rule}' to #{new_resource.chain} chain")
    else
      Chef::Log.debug("ignoring duplicate simple_iptables_rule '#{new_rule}' for #{new_resource.chain} chain")
    end
  end
end

action :delete do
  if new_resource.rule.kind_of?(String)
    rules = [new_resource.rule]
  else
    rules = new_resource.rule
  end

  # Remove the rules from the chain
  rules.each do |rule|
    new_rule = rule_string(new_resource, rule, false)
    if node["simple_iptables"][new_resource.table]["chains"].include?(new_resource.chain) && node["simple_iptables"][new_resource.table]["chains"][new_resource.chain].include?(new_rule)
      rules = node["simple_iptables"][new_resource.table]["chains"][new_resource.chain].dup
      rules.delete(new_rule)
      node.set["simple_iptables"][new_resource.table]["chains"][new_resource.chain] = rules
      new_resource.updated_by_last_action(true)
      Chef::Log.debug("removed rule '#{new_rule}' from #{new_resource.chain} chain")
    else
      Chef::Log.debug("simple_iptables_rule '#{new_rule}' not found in #{new_resource.chain} chain")
    end
  end

  # If only one rule is left in chain and it is the base rule, delete the chain
  if node["simple_iptables"][new_resource.table]["chains"].include?(new_resource.chain) && node["simple_iptables"][new_resource.table]["chains"][new_resource.chain].length == 1 && node["simple_iptables"][new_resource.table]["chains"][new_resource.chain][0] == "-A #{new_resource.direction} --jump #{new_resource.chain}" 
    node.set["simple_iptables"][new_resource.table]["chains"].delete(new_resource.chain) 
  end

end

def test_rules(new_resource, rules)
  # ensure the test rule has been removed before we try to create it
  delete_test_rule(new_resource)
  shell_out!("iptables --table #{new_resource.table} --new-chain _chef_lwrp_test")
  begin
    rules.each do |rule|
      new_rule = rule_string(new_resource, rule, true)
      new_rule.gsub!("-A #{new_resource.chain}", "-A _chef_lwrp_test")
      shell_out!("iptables #{new_rule}")
    end
  ensure
    # clean up the test rule
    delete_test_rule(new_resource)
  end
end

def delete_test_rule(new_resource)
  shell_out("iptables --table #{new_resource.table} --flush _chef_lwrp_test")
  shell_out("iptables --table #{new_resource.table} --delete-chain _chef_lwrp_test")
end

def rule_string(new_resource, rule, include_table)
  jump = new_resource.jump ? " --jump #{new_resource.jump}" : ""
  table = include_table ? "--table #{new_resource.table} " : ""
  rule = "#{table}-A #{new_resource.chain} #{rule}#{jump}"
  rule
end
