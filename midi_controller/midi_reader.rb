#!/usr/bin/env ruby
# frozen_string_literal: true

require 'unimidi'
begin
  require 'colorize'
rescue LoadError
  # colorize is optional
end

# MIDI Controller Stream Reader
# Reads MIDI events from a connected controller and displays them for debugging

class MIDIReader
  CONTROL_CHANGE = 0xB0
  NOTE_ON = 0x90
  NOTE_OFF = 0x80
  PROGRAM_CHANGE = 0xC0
  PITCH_BEND = 0xE0

  def initialize(device_index = nil)
    @input = select_input_device(device_index)
    @running = false
  end

  def select_input_device(index = nil)
    inputs = UniMIDI::Input.all

    if inputs.empty?
      puts "❌ No MIDI input devices found!"
      puts "Please connect a MIDI controller and try again."
      exit 1
    end

    if index.nil?
      puts "\n📟 Available MIDI Input Devices:"
      inputs.each_with_index do |device, i|
        puts "  [#{i}] #{device.name}"
      end

      print "\n🎛️  Select device (0-#{inputs.length - 1}): "
      index = gets.chomp.to_i
    end

    if index < 0 || index >= inputs.length
      puts "❌ Invalid device index"
      exit 1
    end

    inputs[index]
  end

  def format_event(message)
    status_byte = message[0]
    channel = (status_byte & 0x0F) + 1

    case status_byte & 0xF0
    when NOTE_ON
      note = message[1]
      velocity = message[2]
      note_name = get_note_name(note)
      "🎵 NOTE ON  | Ch#{channel} | Note: #{note_name} (#{note}) | Velocity: #{velocity}"

    when NOTE_OFF
      note = message[1]
      velocity = message[2]
      note_name = get_note_name(note)
      "🔇 NOTE OFF | Ch#{channel} | Note: #{note_name} (#{note}) | Velocity: #{velocity}"

    when CONTROL_CHANGE
      cc_number = message[1]
      cc_value = message[2]
      cc_name = get_cc_name(cc_number)
      "🎚️  CC       | Ch#{channel} | #{cc_name} (#{cc_number}) = #{cc_value}"

    when PROGRAM_CHANGE
      program = message[1]
      "🎼 PROGRAM  | Ch#{channel} | Program: #{program}"

    when PITCH_BEND
      lsb = message[1]
      msb = message[2]
      value = (msb << 7) | lsb
      bend_amount = ((value - 8192) / 8192.0 * 100).round(2)
      "🎛️  PITCH    | Ch#{channel} | Bend: #{bend_amount}%"

    else
      "❓ UNKNOWN  | Status: 0x#{status_byte.to_s(16).upcase} | Data: #{message.inspect}"
    end
  end

  def get_note_name(note)
    notes = %w[C C# D D# E F F# G G# A A# B]
    octave = (note / 12) - 1
    note_name = notes[note % 12]
    "#{note_name}#{octave}"
  end

  def get_cc_name(cc_number)
    cc_names = {
      1 => 'Modulation',
      7 => 'Volume',
      10 => 'Pan',
      11 => 'Expression',
      64 => 'Sustain Pedal',
      65 => 'Portamento',
      120 => 'All Sound Off',
      121 => 'Reset All Controllers',
      123 => 'All Notes Off'
    }

    cc_names[cc_number] || "CC#{cc_number}"
  end

  def start
    @running = true
    puts "\n✅ Connected to: #{@input.name}"
    puts "👂 Listening for MIDI events... (Press Ctrl+C to stop)\n"
    puts "-" * 80

    trap('INT') { stop }

    begin
      @input.gets do |_message, timestamp|
        # UniMIDI returns an array of bytes and timestamp
        puts "[#{Time.now.strftime('%H:%M:%S.%L')}] #{format_event(_message)}"
      end
    ensure
      stop
    end
  end

  def stop
    @running = false
    puts "\n" + "-" * 80
    puts "🛑 MIDI reader stopped."
    exit 0
  end
end

if __FILE__ == $PROGRAM_NAME
  reader = MIDIReader.new
  reader.start
end
