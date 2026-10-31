#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'midi_reader'

# Example: Real-time MIDI Event Recording
# Saves all MIDI events to a file while displaying them

class MIDIRecorder < MIDIReader
  def initialize(device_index = nil, output_file = 'midi_events.log')
    super(device_index)
    @output_file = output_file
    @event_count = 0
    @start_time = nil
  end

  def start
    @start_time = Time.now
    puts "\n✅ Connected to: #{@input.name}"
    puts "📝 Recording to: #{@output_file}"
    puts "👂 Listening for MIDI events... (Press Ctrl+C to stop)\n"
    puts "-" * 80

    trap('INT') { stop }

    File.open(@output_file, 'w') do |file|
      file.puts "# MIDI Events Log"
      file.puts "# Device: #{@input.name}"
      file.puts "# Started: #{@start_time}"
      file.puts "# ----"
      file.puts

      begin
        @input.gets do |message, _timestamp|
          @event_count += 1
          elapsed = Time.now - @start_time
          formatted = format_event(message)
          
          timestamp = "[#{elapsed.round(3)}s]"
          event_line = "#{timestamp} #{formatted}"
          
          puts event_line
          file.puts event_line
          file.flush
        end
      ensure
        stop
      end
    end
  end

  def stop
    puts "\n" + "-" * 80
    puts "🛑 MIDI recorder stopped."
    puts "📊 Events recorded: #{@event_count}"
    puts "📁 Saved to: #{@output_file}"
    exit 0
  end
end

if __FILE__ == $PROGRAM_NAME
  recorder = MIDIRecorder.new
  recorder.start
end
