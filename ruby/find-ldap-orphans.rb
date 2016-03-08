#!/usr/bin/env ruby
# find-ldap-orphans.rb
#
# description: List objects that exist in the target directory that do not exist in the source.
#   Pass -d argument to perform delete on matching target orphans.

require 'rubygems'
require 'date'
require 'io/console'
require 'set'

require 'net/ldap'
require 'toml'

if ARGV.length == 0
  [
    "Usage: #{$0} [-d] <config.tml>",
    "",
    " -d delete orphans as they are found"
  ].each { |line| STDERR.puts(line) }
  exit(1)
end

# Should we delete?
delete = ARGV.length > 0 && ARGV[0] == '-d'
if delete
  ARGV.shift
end

# Loading configuration in TOML format: https://github.com/toml-lang/toml
config = TOML.load_file(ARGV[0], symbolize_keys: true)

# Attributes we include in the output
show_attribs = config[:target][:show_attribs]
show_attribs.unshift(config[:target][:name])

if delete
  STDERR.puts("WARN: Will delete orphans from #{config[:target][:host]}")
end

# Prompt for password
STDERR.puts config[:source][:user]
STDERR.puts config[:target][:user]
STDERR.print "Password: "
password = STDIN.noecho(&:gets).chomp
STDERR.puts

# Setup source container search bases
source_containers = [ config[:source][:base] ]
if config[:source][:containers]
  source_containers = config[:source][:containers].map do |cont|
    "#{cont},#{config[:source][:base]}"
  end
end

# Connect to LDAP
source = Net::LDAP.new(
  :host => config[:source][:host],
  :port => config[:source][:port],
  :encryption => :simple_tls,
  :auth => {
    :method => :simple,
    :username => config[:source][:user],
    :password => password
  })
source.bind || abort("Failed to authenticate to #{config[:source][:host]}")

target = Net::LDAP.new(
  :host => config[:target][:host],
  :port => config[:target][:port],
  :base => config[:target][:base],
  :encryption => :simple_tls,
  :auth => {
    :method => :simple,
    :username => config[:target][:user],
    :password => password
  })
target.bind || abort("Failed to authenticate to #{config[:target][:host]}")

# Counters
source_count = 0
target_count = 0
matches = 0
orphans = 0

STDERR.puts("Orphans present in #{config[:target][:host]} matching #{config[:target][:filter]}:")
STDERR.puts
puts show_attribs.join(',')

# Conduct an LDAP search for each letter
"abcdefghijklmnopqrstuvwxyz".each_char do |letter|
  # Get source attributes
  source_values = Set::new
  filter = "(&(objectClass=#{config[:source][:class]})(#{config[:source][:name]}=#{letter}*))"
  source_containers.each do |container|
    source.search(
      :filter => filter,
      :base => container,
      :attributes => [ config[:source][:name] ],
      :return_result => false
    ) do |entry|
      name = entry.first(config[:source][:name]).downcase
      source_values.add(name)
      source_count += 1
    end
  end

  # Get target attributes
  filter = "(&(objectClass=#{config[:target][:class]})(#{config[:target][:name]}=#{letter}*)#{config[:target][:filter]})"
  target.search(
    :filter => filter,
    :attributes => show_attribs,
    :return_result => false
  ) do |entry|
    name = entry.first(config[:target][:name]).downcase
    target_count += 1
    if source_values.member?(name)
      matches += 1
    else
      orphans += 1
      row = []
      show_attribs.each do |attr|
        row.push(entry.first(attr))
      end
      puts row.join(',')
      if delete
        target.delete(entry.dn)
      end
    end
  end
end

STDERR.puts
STDERR.puts("Source entries: #{source_count}")
STDERR.puts("Target entries: #{target_count}")
STDERR.puts("Matches #{matches}")
STDERR.puts("Orphans: #{orphans}")
