#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'microkorg'

class FakeOutput
  attr_reader :sent

  def initialize = @sent = []
  def puts(bytes) = @sent << bytes
end

class FakeInput
  def initialize(*messages) = @queue = messages

  def gets
    raise 'no more data' if @queue.empty?

    [{ data: @queue.shift, timestamp: 0 }]
  end
end

class MicroKorgTest < Minitest::Test
  MK = MicroKorg

  def setup
    @out = FakeOutput.new
  end

  def device(*replies, channel: 0)
    MK::Device.new(output: @out, input: FakeInput.new(*replies), channel: channel)
  end

  def test_codec_roundtrip_and_size
    data = Array.new(254) { |i| (i * 37) % 256 }
    enc = MK::Codec.encode(data)
    assert_equal 291, enc.size
    assert enc.all? { |b| b < 0x80 }
    assert_equal data, MK::Codec.decode(enc)
  end

  def test_codec_bit_layout
    assert_equal [0b0000101, 0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00], MK::Codec.encode([0x81, 0x02, 0x83, 0, 0, 0, 0])
  end

  def test_channel_messages
    d = device(channel: 2)
    d.note_on(60, 100)
    d.note_off(60)
    d.program_change(5)
    d.pitch_bend(0)
    d.all_notes_off
    assert_equal [[0x92, 60, 100], [0x82, 60, 64], [0xC2, 5], [0xE2, 0, 64], [0xB2, 123, 0]], @out.sent
  end

  def test_rejects_out_of_range
    assert_raises(ArgumentError) { device.note_on(128) }
  end

  def test_nrpn
    d = device
    d.nrpn(:arp_type, :random)
    d.nrpn(:arp_octaves, 3)
    d.nrpn(:patch2_destination, :cutoff)
    assert_equal [[0xB0, 99, 0], [0xB0, 98, 7], [0xB0, 6, 0x56]], @out.sent[0, 3]
    assert_equal [0xB0, 6, 2], @out.sent[5]
    assert_equal [[0xB0, 99, 4], [0xB0, 98, 9], [0xB0, 6, 0x40]], @out.sent[6, 3]
  end

  def test_master_volume_and_fine_tune
    d = device
    d.master_volume(16_383)
    d.master_fine_tune(0)
    assert_equal [0xF0, 0x7F, 0, 0x04, 0x01, 0x7F, 0x7F, 0xF7], @out.sent[0]
    assert_equal [0xF0, 0x7F, 0, 0x04, 0x03, 0x00, 0x40, 0xF7], @out.sent[1]
  end

  def test_device_inquiry
    reply = [0xF0, 0x7E, 0x00, 0x06, 0x02, 0x42, 0x58, 0x00, 0x11, 0x00, 0x01, 0x00, 0x02, 0x00, 0xF7]
    info = device(reply).device_inquiry
    assert_equal [0xF0, 0x7E, 0x7F, 0x06, 0x01, 0xF7], @out.sent[0]
    assert info[:micro_korg]
    assert_equal 2, info[:major]
  end

  def test_program_fields
    prog = MK::Program.new
    prog.name = 'Test Patch'
    assert_equal 'Test Patch', prog.name
    t = prog.timbre(1)
    t[:cutoff] = 99
    t[:tune] = -10
    t[:osc1_wave] = :dwgs
    t[:distortion] = true
    t[:amp_sw] = :gate
    t[:patch3_source] = :lfo2
    t[:patch3_destination] = :amp
    prog[:voice_mode] = :layer
    prog[:arp_tempo] = 120
    prog.timbre(2)[:cutoff] = 5

    assert_equal 99, t[:cutoff]
    assert_equal 54, prog.bytes[38 + 3]
    assert_equal :dwgs, t[:osc1_wave]
    assert_equal 0x41, prog.bytes[38 + 27]
    assert_equal :lfo2, t[:patch3_source]
    assert_equal :amp, t[:patch3_destination]
    assert_equal :layer, prog[:voice_mode]
    assert_equal 120, prog[:arp_tempo]
    assert_equal 5, prog.timbre(2)[:cutoff]
    assert_equal 99, MK::Program.from_dump(prog.to_dump).timbre(1)[:cutoff]
  end

  def test_request_current_program
    prog = MK::Program.new.tap { |p| p.name = 'Hello' }
    reply = [0xF0, 0x42, 0x30, 0x58, 0x40, *prog.to_dump, 0xF7]
    got = device(reply).request_current_program
    assert_equal [0xF0, 0x42, 0x30, 0x58, 0x10, 0xF7], @out.sent[0]
    assert_equal 'Hello', got.name
  end

  def test_sysex_split_across_reads_and_realtime_ignored
    prog = MK::Program.new
    reply = [0xF0, 0x42, 0x30, 0x58, 0x40, *prog.to_dump, 0xF7]
    d = device(reply[0, 100], [0xFE, 0xF8], reply[100..])
    assert_equal 254, d.request_current_program.bytes.size
  end

  def test_send_program_and_write
    d = device([0xF0, 0x42, 0x30, 0x58, 0x23, 0xF7], [0xF0, 0x42, 0x30, 0x58, 0x22, 0xF7])
    assert d.send_current_program(MK::Program.new)
    assert_equal 5 + 291 + 1, @out.sent[0].size
    err = assert_raises(MK::DeviceError) { d.write_program(10) }
    assert_match(/write_error/, err.message)
    assert_equal [0xF0, 0x42, 0x30, 0x58, 0x11, 0x00, 10, 0xF7], @out.sent[1]
  end

  def test_load_cc_map_from_global
    global = Array.new(200, 0xFF)
    global[18 + 12] = 74 # cutoff
    reply = [0xF0, 0x42, 0x30, 0x58, 0x51, *MK::Codec.encode(global), 0xF7]
    d = device(reply)
    d.load_cc_map
    assert_equal({ cutoff: 74 }, d.cc_map)
    d.control(:cutoff, 100)
    assert_equal [0xB0, 74, 100], @out.sent.last
    assert_raises(MK::Error) { d.control(:resonance, 1) }
  end

  def test_timeout
    d = device
    d.instance_variable_set(:@input, Class.new { def gets = (sleep 0.01; []) }.new)
    assert_raises(MK::DeviceError) { d.read_sysex(0.1) }
  end

  def test_program_label
    assert_equal 'A11', MK.program_label(0)
    assert_equal 'A88', MK.program_label(63)
    assert_equal 'b11', MK.program_label(64)
    assert_equal 'b88', MK.program_label(127)
  end
end
