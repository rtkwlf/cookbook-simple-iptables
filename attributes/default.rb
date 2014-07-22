default["simple_iptables"]["rules"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
default["simple_iptables"]["chains"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
default["simple_iptables"]["policy"] = {"filter" => {}, "nat" => {}, "mangle" => {}, "raw" => {}}

default["simple_iptables"]["tables"] = %w(filter nat mangle raw)
