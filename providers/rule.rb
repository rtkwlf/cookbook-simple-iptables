action :append do
  if not node["simple_iptables"]["chains"].include?(new_resource.chain)
    node["simple_iptables"]["chains"] << new_resource.chain
    node["simple_iptables"]["rules"] << "-A #{new_resource.direction} --jump #{new_resource.chain}"
  end
  new_rule = rule_string(new_resource)
  if not node["simple_iptables"]["rules"].include?(new_rule)
    node["simple_iptables"]["rules"] << new_rule
    Chef::Log.debug("added rule '#{new_rule}'")
  else
    Chef::Log.debug("ignoring duplicate simple_iptables_rule '#{new_rule}'")
  end
end

def rule_string(new_resource)
  rule = "-A #{new_resource.chain} #{new_resource.rule} --jump #{new_resource.jump}"
  rule
end

