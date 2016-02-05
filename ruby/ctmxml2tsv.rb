#!/usr/bin/ruby
# ctmxml2tsv.rb
#
# Convert Control-M XML to tab separated values

require 'rubygems'
require 'nokogiri'

# Fields we are interested in for our tsv file
FIELDS = %w{PARENT_FOLDER APPLICATION SUB_APPLICATION JOBNAME TASKTYPE APPL_TYPE}

# Open and parse XML
xml_file = ARGV[0]
xml = File.open(xml_file) { |f| Nokogiri::XML(f) }

puts FIELDS.join("\t")

# Iterate over each <JOB> entry
jobs = xml.xpath("//JOB")
jobs.each do |job|
  row = []
  FIELDS.each do |field|
    row << job[field]
  end
  puts row.join("\t")
end

