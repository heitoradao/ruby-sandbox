#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced MIDI Examples

require_relative 'midi_reader'

# Example 1: Filter events by type
class EventFilterReader < MIDIReader
  def initialize(device_index = nil, event_types = [:note_on, :note_off, :cc])
    super(device_index)
    @event_types = event_types
  end

  def start
    puts "\n✅ Connected to: #{@input.name}"
    puts "🔍 Filtering events: #{@event_types.join(', ')}"
    puts "👂 Listening... (Press Ctrl+C to stop)\n"
    puts "-" * 80

    trap('INT') { stop }

    begin
      @input.gets do |message, _timestamp|
        if should_process?(message)
          puts "[#{Time.now.strftime('%H:%M:%S.%L')}] #{format_event(message)}"
        end
      end
    ensure
      stop
    end
  end

  private

  def should_process?(message)
    status_byte = message[0] & 0xF0
    
    cases = {
      0x90 => :note_on,
      0x80 => :note_off,
      0xB0 => :cc,
      0xC0 => :program_change,
      0xE0 => :pitch_bend
    }

    event_type = cases[status_byte]
    @event_types.include?(event_type)
  end
end

# Example 2: Detect note sequences
class SequenceDetector < MIDIReader
  def initialize(device_index = nil)
    super(device_index)
    @note_sequence = []
    @target_sequence = [60, 62, 64, 65, 67] # C Major scale
  end

  def start
    puts "\n✅ Connected to: #{@input.name}"
    puts "🎼 Looking for sequence: #{@target_sequence.map { |n| get_note_name(n) }.join(' -> ')}"
    puts "👂 Play the sequence... (Press Ctrl+C to stop)\n"
    puts "-" * 80

    trap('INT') { stop }

    begin
      @input.gets do |message, _timestamp|
        if (message[0] & 0xF0) == 0x90
          note = message[1]
          @note_sequence << note
          
          formatted = format_event(message)
          puts "[#{Time.now.strftime('%H:%M:%S.%L')}] #{formatted}"

          if @note_sequence.size > @target_sequence.size
            @note_sequence.shift
          end

          if @note_sequence == @target_sequence
            puts "\n🎉 SEQUENCE DETECTED! 🎉\n"
            @note_sequence = []
          end
        end
      end
    ensure
      stop
    end
  end
end

# Example 3: CC Value Monitoring
class CCMonitor < MIDIReader
  def initialize(device_index = nil, cc_numbers = [7, 10, 64])
    super(device_index)
    @cc_values = {}
    @cc_numbers = cc_numbers
  end

  def start
    puts "\n✅ Connected to: #{@input.name}"
    puts "📊 Monitoring CCs: #{@cc_numbers.map { |n| get_cc_name(n) }.join(', ')}"
    puts "👂 Adjusting controls... (Press Ctrl+C to stop)\n"
    puts "-" * 80

    trap('INT') { stop }

    begin
      @input.gets do |message, _timestamp|
        if (message[0] & 0xF0) == 0xB0
          cc_number = message[1]
          if @cc_numbers.include?(cc_number)
            cc_value = message[2]
            @cc_values[cc_number] = cc_value
            
            puts "[#{Time.now.strftime('%H:%M:%S.%L')}] #{format_event(message)}"
            
            display_cc_map
          end
        end
      end
    ensure
      stop
    end
  end

  private

  def display_cc_map
    puts "\n--- CC Values ---"
    @cc_numbers.each do |cc_num|
      value = @cc_values[cc_num] || 0
      bar = "█" * (value / 127.0 * 30).to_i
      puts "#{get_cc_name(cc_num).ljust(20)} #{value.to_s.rjust(3)}/127 #{bar}"
    end
    puts "─" * 40 + "\n"
  end
end

puts "\n🎹 MIDI Controller Stream Reader - Advanced Examples\n"
puts "1. Event Filter (show only specific event types)"
puts "2. Sequence Detector (detect note patterns)"
puts "3. CC Monitor (visualize control change values)"
puts "\nExample usage:"
puts "  ruby -e \"require_relative 'examples'; EventFilterReader.new.start\""
puts "  ruby -e \"require_relative 'examples'; SequenceDetector.new.start\""
puts "  ruby -e \"require_relative 'examples'; CCMonitor.new.start\""
