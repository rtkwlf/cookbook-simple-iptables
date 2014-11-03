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
    new_rule_string = rule_string(new_resource, rule, false)
    new_rule = {:rule => new_rule_string, :weight => new_resource.weight}
    table_rules = node.set["simple_iptables"][ip_version]["rules"][new_resource.table]

    unless table_rules.include?(new_rule)
      table_rules << new_rule
      table_rules.sort! {|a,b| a[:weight] <=> b[:weight]}
      new_resource.updated_by_last_action(true)
      Chef::Log.debug("[#{ip_version}] added rule '#{new_rule_string}'")
    else
      Chef::Log.debug("[#{ip_version}] ignoring duplicate simple_iptables_rule '#{new_rule_string}'")
    end
  end
end

def rule_string(new_resource, rule, include_table)
  jump = new_resource.jump ? "--jump #{new_resource.jump} " : ""
  table = include_table ? "--table #{new_resource.table} " : ""
  comment = new_resource.comment ? %Q{ -m comment --comment "#{new_resource.comment}" } : ""
  rule = "#{table}-A #{new_resource.chain} #{jump}#{rule}#{comment}"
  rule
end

