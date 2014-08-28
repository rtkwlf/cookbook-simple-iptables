action :set do
  if [:ipv4, :both].include?(new_resource.ip_version)
    handle_policy(new_resource, "ipv4")
  end
  if [:ipv6, :both].include?(new_resource.ip_version)
    handle_policy(new_resource, "ipv6")
  end
end

def handle_policy(new_resource, ip_version)
  Chef::Log.debug("[#{ip_version}] setting policy for #{new_resource.chain} to #{new_resource.policy}")
  node.set["simple_iptables"][ip_version]["policy"][new_resource.table][new_resource.chain] = new_resource.policy
  new_resource.updated_by_last_action(true)
end
