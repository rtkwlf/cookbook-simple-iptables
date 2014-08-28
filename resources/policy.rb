actions :set

attribute :chain, :name_attribute => true, :equal_to => ["INPUT", "FORWARD", "OUTPUT", "PREROUTING", "POSTROUTING"], :default => "INPUT"
attribute :table, :equal_to => ["filter", "nat", "mangle", "raw"], :default => "filter"
attribute :policy, :equal_to => ["ACCEPT", "DROP"], :required => true
attribute :ip_version, :equal_to => [:ipv4, :ipv6, :both], :default => :ipv4


def initialize(*args)
  super
  @action = :set
end

