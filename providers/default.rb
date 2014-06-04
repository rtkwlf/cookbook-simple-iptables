action :reset do
  Chef::Log.debug("resetting iptables")
  # TODO: check to see if these attribute values are something other than default and
  # only call updated_by_last_action if true.
  node.set["simple_iptables"]["chains"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
  node.set["simple_iptables"]["rules"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
  node.set["simple_iptables"]["policy"] = {"filter" => {}, "nat" => {}, "mangle" => {}, "raw" => {}}
  new_resource.updated_by_last_action(true)
end