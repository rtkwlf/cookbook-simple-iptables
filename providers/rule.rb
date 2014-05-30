require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :append do
  if new_resource.rule.kind_of?(String)
    rules = [new_resource.rule]
  else
    rules = new_resource.rule
  end
  # Ensure that the rules are actually valid iptable rules by testing with a temporary chain
  test_rules(new_resource, rules)

  if not node["simple_iptables"]["chains"][new_resource.table].include?(new_resource.chain)
    node.set["simple_iptables"]["chains"][new_resource.table] = node["simple_iptables"]["chains"][new_resource.table].to_a << new_resource.chain unless ["PREROUTING", "INPUT", "FORWARD", "OUTPUT", "POSTROUTING"].include?(new_resource.chain)
    unless new_resource.chain == new_resource.direction
      node.set["simple_iptables"]["rules"][new_resource.table] = node["simple_iptables"]["rules"][new_resource.table].to_a << {:rule => "-A #{new_resource.direction} --jump #{new_resource.chain}", :weight => new_resource.weight}
    end
  end

  # Then apply the rules to the node
  rules.each do |rule|
    new_rule = rule_string(new_resource, rule, false)
    if not node["simple_iptables"]["rules"][new_resource.table].include?({:rule => new_rule, :weight => new_resource.weight})
      node.set["simple_iptables"]["rules"][new_resource.table] = node["simple_iptables"]["rules"][new_resource.table].to_a << {:rule => new_rule, :weight => new_resource.weight}
      node.set["simple_iptables"]["rules"][new_resource.table].sort! {|a,b| (a[:weight]||50) <=> (b[:weight]||50)}
      new_resource.updated_by_last_action(true)
      Chef::Log.debug("added rule '#{new_rule}'")
    else
      Chef::Log.debug("ignoring duplicate simple_iptables_rule '#{new_rule}'")
    end
  end
end

def test_rules(new_resource, rules)
  test_chains = ["_chef_lwrp_test1"]
  cleanup_test_chain(new_resource.table, test_chains.first)
  shell_out!("iptables --table #{new_resource.table} --new-chain #{test_chains.first}")
  begin
    rules.each do |rule|
      new_rule = rule_string(new_resource, rule, true)
      new_rule.gsub!("-A #{new_resource.chain}", "-A #{test_chains.first}")

      # Test for jumps to chains that are not actually created on the system yet, but are already processed in the current recipe
      if node["simple_iptables"]["chains"][new_resource.table].include?(new_resource.jump)
        test_chains.push("_chef_lwrp_test2")
        cleanup_test_chain(new_resource.table, test_chains.last)
        shell_out!("iptables --table #{new_resource.table} --new-chain #{test_chains.last}")
        new_rule.gsub!("--jump #{new_resource.jump}", "--jump #{test_chains.last}")
      end
      shell_out!("iptables #{new_rule}")
    end
  ensure
    test_chains.each do |test_chain|
      cleanup_test_chain(new_resource.table, test_chain)
    end
  end
end

def cleanup_test_chain(table, chain)
  #always flush and remove first in case the previous run left it lying around. Ignore any return values.
  shell_out("iptables --table #{table} --flush #{chain}")
  shell_out("iptables --table #{table} --delete-chain #{chain}")
end

def rule_string(new_resource, rule, include_table)
  jump = new_resource.jump ? "--jump #{new_resource.jump} " : ""
  table = include_table ? "--table #{new_resource.table} " : ""
  rule = "#{table}-A #{new_resource.chain} #{jump}#{rule}"
  rule
end

