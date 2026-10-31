#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

options = { lines: false, words: false, chars: false }

parser = OptionParser.new do |o|
  o.banner = 'Usage: wc.rb [options] [FILE...]'
  o.on('-l', '--lines', 'Count lines') { options[:lines] = true }
  o.on('-w', '--words', 'Count words') { options[:words] = true }
  o.on('-c', '--chars', 'Count characters') { options[:chars] = true }
  o.on('-h', '--help', 'Show help') do
    puts o
    exit
  end
end

begin
  parser.parse!
rescue OptionParser::ParseError => e
  warn e.message, parser
  exit 1
end

options.transform_values! { true } unless options.values.any?

inputs = ARGV.empty? ? { 'stdin' => $stdin.read } : ARGV.to_h { |f| [f, File.read(f)] }

inputs.each do |name, text|
  counts = []
  counts << text.lines.size if options[:lines]
  counts << text.split.size if options[:words]
  counts << text.size if options[:chars]
  puts "#{counts.join(' ')} #{name}"
end
