action :set do
  updated = false
  if [:ipv4, :both].include?(new_resource.ip_version)
    updated |= handle_policy(new_resource, "ipv4")
  end
  if [:ipv6, :both].include?(new_resource.ip_version)
    updated |= handle_policy(new_resource, "ipv6")
  end
  new_resource.updated_by_last_action(updated)
end

def handle_policy(new_resource, ip_version)
  Chef::Log.debug("[#{ip_version}] setting policy for #{new_resource.chain} to #{new_resource.policy}")
  node.default["simple_iptables"][ip_version]["policy"][new_resource.table][new_resource.chain] = new_resource.policy
  return true
end
