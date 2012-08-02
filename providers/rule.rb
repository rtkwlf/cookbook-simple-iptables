action :append do
  if not node["simple_iptables"]["chains"].include?(new_resource.chain)
    node["simple_iptables"]["chains"] << new_resource.chain
    node["simple_iptables"]["rules"] << "-A #{new_resource.direction} --jump #{new_resource.chain}"
  end

  if new_resource.rule.kind_of?(String)
    rules = [new_resource.rule]
  else
    rules = new_resource.rule
  end
  rules.each do |rule|
    new_rule = rule_string(new_resource, rule)
    if not node["simple_iptables"]["rules"].include?(new_rule)
      node["simple_iptables"]["rules"] << new_rule
      new_resource.updated_by_last_action(true)
      Chef::Log.debug("added rule '#{new_rule}'")
    else
      Chef::Log.debug("ignoring duplicate simple_iptables_rule '#{new_rule}'")
    end
  end
end

def rule_string(new_resource, rule)
  rule = "-A #{new_resource.chain} #{rule} --jump #{new_resource.jump}"
  rule
end

