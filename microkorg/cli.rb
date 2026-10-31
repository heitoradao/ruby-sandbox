#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative 'microkorg'

# Usage: ruby cli.rb [-c CHANNEL] [-p PORT_REGEX] COMMAND [ARGS]
#   ports                 list MIDI ports
#   inquiry               Device Inquiry
#   play NOTE [SECONDS]   play a note (0..127)
#   program N             program change (0..127, A11=0 ... b88=127)
#   current               dump current program (edit buffer)
#   cc NAME VALUE         panel control by name (reads CC map from the unit)
#   nrpn NAME VALUE       arpeggiator/patch NRPN (e.g. arp_on true, arp_type random)
#   volume 0..16383       master volume

opts = { channel: 1, port: /microkorg/i }
OptionParser.new do |o|
  o.banner = 'Usage: cli.rb [options] COMMAND [ARGS]'
  o.on('-c', '--channel N', Integer, 'MIDI channel 1..16 (default 1)') { |v| opts[:channel] = v }
  o.on('-p', '--port REGEX', 'Port name regex (default /microkorg/i)') { |v| opts[:port] = Regexp.new(v, Regexp::IGNORECASE) }
end.parse!

cmd, *args = ARGV
abort 'missing COMMAND (see header of cli.rb)' unless cmd

# alsa-rawmidi segfaults on hosts without an ALSA sound subsystem
abort 'no /dev/snd: ALSA MIDI unavailable' if RUBY_PLATFORM.include?('linux') && !Dir.exist?('/dev/snd')

if cmd == 'ports'
  require 'unimidi'
  puts 'Inputs:', UniMIDI::Input.all.map { |d| "  #{d.id}: #{d.name}" }
  puts 'Outputs:', UniMIDI::Output.all.map { |d| "  #{d.id}: #{d.name}" }
  exit
end

mk = MicroKorg::Device.open(name: opts[:port], channel: opts[:channel] - 1)

case cmd
when 'inquiry' then p mk.device_inquiry
when 'play' then mk.play(Integer(args.fetch(0)), duration: Float(args.fetch(1, 0.5)))
when 'program' then mk.program_change(Integer(args.fetch(0)))
when 'current'
  prog = mk.request_current_program
  puts "#{prog.name} (#{prog[:voice_mode]})"
  pp prog.timbre(1).to_h
when 'cc'
  mk.load_cc_map
  mk.control(args.fetch(0).to_sym, Integer(args.fetch(1)))
when 'nrpn'
  raw = args.fetch(1)
  value = { 'true' => true, 'false' => false }.fetch(raw) { raw =~ /\A\d+\z/ ? raw.to_i : raw.to_sym }
  mk.nrpn(args.fetch(0).to_sym, value)
when 'volume' then mk.master_volume(Integer(args.fetch(0)))
else abort "unknown command #{cmd}"
end
