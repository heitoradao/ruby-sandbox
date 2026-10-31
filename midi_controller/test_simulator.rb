#!/usr/bin/env ruby
# frozen_string_literal: true

# MIDI Event Simulator
# Generates synthetic MIDI messages for testing without a physical controller

class MIDISimulator
  def self.generate_note_on(note, velocity = 100, channel = 0)
    [0x90 + channel, note, velocity]
  end

  def self.generate_note_off(note, velocity = 0, channel = 0)
    [0x80 + channel, note, velocity]
  end

  def self.generate_cc(cc_number, value, channel = 0)
    [0xB0 + channel, cc_number, value]
  end

  def self.generate_program_change(program, channel = 0)
    [0xC0 + channel, program]
  end

  def self.generate_pitch_bend(bend_amount, channel = 0)
    value = ((bend_amount / 100.0) * 8192).to_i + 8192
    value = value.clamp(0, 16383)
    lsb = value & 0x7F
    msb = (value >> 7) & 0x7F
    [0xE0 + channel, lsb, msb]
  end
end

class MockMIDIReader
  CONTROL_CHANGE = 0xB0
  NOTE_ON = 0x90
  NOTE_OFF = 0x80
  PROGRAM_CHANGE = 0xC0
  PITCH_BEND = 0xE0

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
end

puts "\n🧪 MIDI Event Format Testing\n"
puts "-" * 80

mock = MockMIDIReader.new

test_events = [
  { name: 'Note On (C4, velocity 100)', data: MIDISimulator.generate_note_on(60, 100) },
  { name: 'Note Off (C4, velocity 0)', data: MIDISimulator.generate_note_off(60, 0) },
  { name: 'Note On (D#5, velocity 127)', data: MIDISimulator.generate_note_on(75, 127) },
  { name: 'Control Change (Volume = 85)', data: MIDISimulator.generate_cc(7, 85) },
  { name: 'Control Change (Pan = 64)', data: MIDISimulator.generate_cc(10, 64) },
  { name: 'Control Change (Sustain = 127)', data: MIDISimulator.generate_cc(64, 127) },
  { name: 'Program Change (Program 0)', data: MIDISimulator.generate_program_change(0) },
  { name: 'Program Change (Program 42)', data: MIDISimulator.generate_program_change(42) },
  { name: 'Pitch Bend (+50%)', data: MIDISimulator.generate_pitch_bend(50) },
  { name: 'Pitch Bend (-75%)', data: MIDISimulator.generate_pitch_bend(-75) },
  { name: 'Note On (A0, velocity 64)', data: MIDISimulator.generate_note_on(21, 64) },
  { name: 'Note On (G#8, velocity 1)', data: MIDISimulator.generate_note_on(127, 1) }
]

puts "Generated MIDI Events:\n\n"

test_events.each do |event|
  formatted = mock.format_event(event[:data])
  puts "[#{Time.now.strftime('%H:%M:%S.%L')}] #{formatted}"
  puts "  Raw: #{event[:data].inspect}"
  puts
  sleep 0.2
end

puts "-" * 80
puts "✅ Simulator test complete!\n\n"
puts "💡 To test with a real MIDI controller:"
puts "   ruby midi_reader.rb"
