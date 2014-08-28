require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut


action :append do
  if [:ipv4, :both].include?(new_resource.ip_version)
    handle_rule(new_resource, "ipv4")
  end
  if [:ipv6, :both].include?(new_resource.ip_version)
    handle_rule(new_resource, "ipv6")
  end
end

def handle_rule(new_resource, ip_version)
  if new_resource.rule.kind_of?(String)
    rules = [new_resource.rule]
  else
    rules = new_resource.rule
  end
  if not node["simple_iptables"][ip_version]["chains"][new_resource.table].include?(new_resource.chain)
    node.set["simple_iptables"][ip_version]["chains"][new_resource.table] = node["simple_iptables"][ip_version]["chains"][new_resource.table].dup << new_resource.chain unless ["PREROUTING", "INPUT", "FORWARD", "OUTPUT", "POSTROUTING"].include?(new_resource.chain)
    unless new_resource.chain == new_resource.direction || new_resource.direction == :none
      node.set["simple_iptables"][ip_version]["rules"][new_resource.table] << {:rule => "-A #{new_resource.direction} #{new_resource.chain_condition} --jump #{new_resource.chain}", :weight => new_resource.weight}
    end
  end

  # Then apply the rules to the node
  rules.each do |rule|
    new_rule = rule_string(new_resource, rule, false)
    if not node["simple_iptables"][ip_version]["rules"][new_resource.table].include?({:rule => new_rule, :weight => new_resource.weight})
      node.set["simple_iptables"][ip_version]["rules"][new_resource.table] << {:rule => new_rule, :weight => new_resource.weight}
      node.set["simple_iptables"][ip_version]["rules"][new_resource.table].sort! {|a,b| a[:weight] <=> b[:weight]}
      new_resource.updated_by_last_action(true)
      Chef::Log.debug("[#{ip_version}] added rule '#{new_rule}'")
    else
      Chef::Log.debug("[#{ip_version}] ignoring duplicate simple_iptables_rule '#{new_rule}'")
    end
  end
end

def rule_string(new_resource, rule, include_table)
  jump = new_resource.jump ? "--jump #{new_resource.jump} " : ""
  table = include_table ? "--table #{new_resource.table} " : ""
  rule = "#{table}-A #{new_resource.chain} #{jump}#{rule}"
  rule
end

