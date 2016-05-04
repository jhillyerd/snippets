#!/usr/bin/env ruby
# tsvtosql.rb: convert tab sep values to SQL inserts

if ARGV.length != 2
  $stderr.puts "Usage: tsvtosql.rb <tab sep values> <table name>"
  exit 1
end

tsv_file, table = ARGV

# Read a tab sep values file
def read_tsv(file_name)
  File.open(file_name, "r") do |file|
    file.each_line do |line|
      yield line.chomp.split("\t")
    end
  end
end

headers = nil
ins_prefix = nil
ins_postfix = nil

qre = /'/

read_tsv(tsv_file) do |cols|
  if ! headers
    headers = cols
    ins_prefix = "insert into #{table} (" + headers.join(", ") + ") values ("
    ins_postfix = ");"
    next
  end

  fmt_row = cols.map do |el|
    if el != nil and el != 'NULL'
      "'" + el.gsub(qre, "''") + "'"
    else
      "null"
    end
  end
  puts ins_prefix + fmt_row.join(", ") + ins_postfix
  puts
end
