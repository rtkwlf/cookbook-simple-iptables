default["simple_iptables"]["ipv4"]["rules"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
default["simple_iptables"]["ipv4"]["chains"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
default["simple_iptables"]["ipv4"]["policy"] = {"filter" => {}, "nat" => {}, "mangle" => {}, "raw" => {}}
default["simple_iptables"]["ipv6"]["rules"] = {"filter" => [], "mangle" => [], "raw" => []}
default["simple_iptables"]["ipv6"]["chains"] = {"filter" => [], "mangle" => [], "raw" => []}
default["simple_iptables"]["ipv6"]["policy"] = {"filter" => {}, "mangle" => {}, "raw" => {}}

default["simple_iptables"]["ipv4"]["tables"] = %w(filter nat mangle raw)
default["simple_iptables"]["ipv6"]["tables"] = %w(filter mangle raw)
default["simple_iptables"]["ip_versions"] = ["ipv4"]
