#
# Cookbook Name:: simple_iptables
# Recipe:: default
#
# Copyright 2012, Dan Crosta
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package "iptables"

# This block runs during the "execute" phase, so that we can gather the
# resources before we generate the iptables-rules template. If you know of a
# better way to do this, please let me know!
ruby_block "run-iptables-resources-early" do
  block do
    # Before executing the simple_iptables_* resources, reset the
    # node attributes to their defaults. This gives "action :delete"
    # semantics for free by removing a resource from a recipe.
    node.set["simple_iptables"]["chains"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
    node.set["simple_iptables"]["rules"] = {"filter" => [], "nat" => [], "mangle" => [], "raw" => []}
    node.set["simple_iptables"]["policy"] = {"filter" => {}, "nat" => {}, "mangle" => {}, "raw" => {}}

    # Then run all the simple_iptables_* resources
    run_context.resource_collection.each do |resource|
      if resource.kind_of?(Chef::Resource::SimpleIptablesRule)
        Chef::Log.debug("about to run simple_iptables_rule[#{resource.chain}]")
        resource.run_action(resource.action)
      elsif resource.kind_of?(Chef::Resource::SimpleIptablesPolicy)
        Chef::Log.debug("about to run simple_iptables_policy[#{resource.chain}]")
        resource.run_action(resource.action)
      end
    end

    Chef::Log.debug("After run-iptables-resources-early data is: #{node['simple_iptables'].inspect}")
  end
end

case node['platform_family']
when 'debian'
  iptable_rules = '/etc/iptables-rules'
when 'rhel', 'fedora'
  iptable_rules = '/etc/sysconfig/iptables'
end

ruby_block "test-iptables" do
  block do
    cmd = Mixlib::ShellOut.new("iptables-restore --test < #{iptable_rules}",
                               :user => "root")
    cmd.run_command
    if !Array(cmd.valid_exit_codes).include?(cmd.exitstatus)
      msg = <<-eos
iptables-restore exited with code #{cmd.exitstatus} while testing new rules
STDOUT:
#{cmd.stdout}
STDERR:
#{cmd.stderr}
eos
      match = cmd.stderr.match /line:?\s*(\d+)/
      if match
        line_no = match[1].to_i
        msg << "Line #{line_no}: #{IO.readlines(iptable_rules)[line_no-1]}"
      end
      # Delete the file so that the next Chef run is forced to recreate it
      # and retest it. Otherwise, if the rules remain unchanged, the template
      # resource won't recreate the file, won't notify the test resource,
      # and the Chef run will be allowed to complete successfully despite
      # and invalid rule being present.
      File.delete(iptable_rules)
      raise msg
    end
  end
  notifies :run, "execute[reload-iptables]"
  action :nothing
end

execute "reload-iptables" do
  command "iptables-restore < #{iptable_rules}"
  user "root"
  action :nothing
end

template iptable_rules do
  source "iptables-rules.erb"
  cookbook "simple_iptables"
  notifies :create, "ruby_block[test-iptables]"
  action :create
end

case node['platform_family']
when 'debian'

  # TODO: Generalize this for other platforms somehow
  file "/etc/network/if-up.d/iptables-rules" do
    owner "root"
    group "root"
    mode "0755"
    content "#!/bin/bash\niptables-restore < #{iptable_rules}\n"
    action :create
  end
end
