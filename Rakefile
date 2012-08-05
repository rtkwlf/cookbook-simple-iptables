#!/usr/bin/env rake

require 'json'

task :default => 'test'

task :test => [:foodcritic, :knife]

desc "Creates a tarball for distribution to the community site"
task :tarball do
  Rake::Task[:foodcritic].execute
  Rake::Task[:knife].execute

  version = JSON.parse(File.read('metadata.json'))["version"]
  sh "knife cookbook metadata simple_iptables"
  sh "tar czvf simple_iptables-#{version}.tar.gz -C .. --exclude '*.tar.gz' --exclude '.git*' --exclude '.*.swp' --exclude tmp --exclude test --exclude .travis.yml --exclude Gemfile.lock simple_iptables"
end

desc "Runs foodcritic linter"
task :foodcritic do
  Rake::Task[:prepare_sandbox].execute

  if Gem::Version.new("1.9.2") <= Gem::Version.new(RUBY_VERSION.dup)
    sh "foodcritic -f any #{sandbox_path}"
  else
    puts "WARN: foodcritic run is skipped as Ruby #{RUBY_VERSION} is < 1.9.2."
  end
end

desc "Runs knife cookbook test"
task :knife do
  Rake::Task[:prepare_sandbox].execute

  ENV["BUNDLE_GEMFILE"] = "test/support/Gemfile"
  sh "bundle exec knife cookbook test cookbook -c #{sandbox_root}/knife.rb"
end

task :prepare_sandbox do
  files = %w{*.md *.rb attributes definitions files providers recipes resources templates}

  rm_rf sandbox_root
  mkdir_p sandbox_path
  mkdir_p File.join(sandbox_root, "cache")

  cp_r Dir.glob("{#{files.join(',')}}"), sandbox_path

  File.open(knife_rb, "w") do |fp|
    fp.write("cookbook_path ['#{sandbox_root}/cookbooks/']\n")
    fp.write("cache_type    'BasicFile'\n")
    fp.write("cache_options :path => '#{sandbox_root}/cache'\n")
  end
end

private
def sandbox_root
  File.join(File.dirname(__FILE__), %w(tmp))
end

def sandbox_path
  File.join(sandbox_root, %w(cookbooks cookbook))
end

def knife_rb
  File.join(sandbox_root, "knife.rb")
end
