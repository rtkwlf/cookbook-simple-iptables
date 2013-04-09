action :set do  
  unless policy_set?(new_resource)
    Chef::Log.debug("setting policy for #{new_resource.chain} chain to #{new_resource.policy} for #{new_resource.table} table")
    node.set["simple_iptables"][new_resource.table]["policy"][new_resource.chain] = new_resource.policy
    new_resource.updated_by_last_action(true)
  end
end

def policy_set?(new_resource)
  begin
    shell_out!("iptables -L -t #{new_resource.table} | grep 'Chain #{new_resource.chain} (policy #{new_resource.policy})'")
    true
  rescue
    false    
  end  
end