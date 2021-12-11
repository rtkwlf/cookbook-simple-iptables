provides :simple_iptables_policy

attribute :chain, :name_attribute => true, :equal_to => ["INPUT", "FORWARD", "OUTPUT", "PREROUTING", "POSTROUTING"]
attribute :table, :equal_to => ["filter", "nat", "mangle", "raw"], :default => "filter"
attribute :policy, :equal_to => ["ACCEPT", "DROP"], :required => true
attribute :ip_version, :equal_to => [:ipv4, :ipv6, :both], :default => :ipv4

default_action :set

def handle_policy(new_resource, ip_version)
  Chef::Log.debug("[#{ip_version}] setting policy for #{new_resource.chain} to #{new_resource.policy}")
  node.default["simple_iptables"][ip_version]["policy"][new_resource.table][new_resource.chain] = new_resource.policy
  return true
end

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
