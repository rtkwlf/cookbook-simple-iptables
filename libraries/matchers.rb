if defined?(ChefSpec)
  ChefSpec.define_matcher :simple_iptables_policy
  ChefSpec.define_matcher :simple_iptables_rule

  def set_simple_iptables_policy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:simple_iptables_policy,
                                            :set,
                                            resource_name)
  end

  def append_simple_iptables_rule(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:simple_iptables_rule,
                                            :append,
                                            resource_name)
  end
end

