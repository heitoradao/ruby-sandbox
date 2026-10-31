# frozen_string_literal: true

require 'timeout'

# Driver for the KORG microKORG (MIDI Implementation rev. 1.4, see
# ../microKORG_MIDIimp.TXT).
#
# The driver is transport-agnostic: it only needs an +output+ responding to
# +puts(Array<Integer>)+ and, optionally, an +input+ whose +gets+ returns an
# Array of { data: [bytes], timestamp: n } (both match UniMIDI devices).
module MicroKorg
  class Error < StandardError; end
  class DeviceError < Error; end

  SYSEX_START = 0xF0
  SYSEX_END = 0xF7
  KORG_ID = 0x42
  FAMILY_ID = 0x58

  FUNC = {
    current_program_request: 0x10, program_request: 0x1C,
    global_request: 0x0E, all_request: 0x0F, program_write: 0x11,
    current_program_dump: 0x40, program_dump: 0x4C,
    global_dump: 0x51, all_dump: 0x50,
    format_error: 0x26, load_ok: 0x23, load_error: 0x24,
    write_ok: 0x21, write_error: 0x22
  }.freeze
  FUNC_NAMES = FUNC.invert.freeze

  CURRENT_PROGRAM_SIZE = 254
  GLOBAL_SIZE = 200

  # Pure 7-bit "MIDI-safe" conversion (spec NOTE 5): every 7 data bytes become
  # 8 MIDI bytes; the first holds the MSBs (bit i = MSB of data byte i).
  module Codec
    module_function

    def encode(bytes)
      bytes.each_slice(7).flat_map do |group|
        msbs = 0
        group.each_with_index { |b, i| msbs |= ((b >> 7) & 1) << i }
        [msbs, *group.map { |b| b & 0x7F }]
      end
    end

    def decode(midi_bytes)
      midi_bytes.each_slice(8).flat_map do |group|
        msbs = group.first
        group.drop(1).each_with_index.map { |b, i| b | (((msbs >> i) & 1) << 7) }
      end
    end
  end

  # NRPN parameters (spec 2-1 *6): name => [MSB, LSB]
  NRPN = {
    arp_on: [0x00, 0x02], arp_octaves: [0x00, 0x03], arp_latch: [0x00, 0x04],
    arp_type: [0x00, 0x07], arp_gate: [0x00, 0x0A],
    **(1..4).to_h { |n| [:"patch#{n}_source", [0x04, n - 1]] },
    **(1..4).to_h { |n| [:"patch#{n}_destination", [0x04, 0x07 + n]] },
    **(1..8).to_h { |n| [:"band#{n}_level", [0x04, 0x10 + 2 * (n - 1)]] },
    **(1..8).to_h { |n| [:"band#{n}_pan", [0x04, 0x20 + 2 * (n - 1)]] }
  }.freeze

  ARP_TYPES = { up: 0x00, down: 0x16, alt1: 0x2B, alt2: 0x40, random: 0x56, trigger: 0x6B }.freeze
  PATCH_SOURCES = %i[eg1 eg2 lfo1 lfo2 velocity kbd_track pitch_bend mod].freeze
  PATCH_DESTINATIONS = %i[pitch osc2_pitch osc1_ctrl1 noise_level cutoff amp pan lfo2_freq].freeze

  # Panel controls reachable through Control Change; order = Global data
  # bytes 18..59 (*T-9). CC numbers are user-configurable on the device.
  CC_PARAMETERS = %i[
    portamento osc1_wave osc1_ctrl1 osc1_ctrl2 osc2_wave osc2_mod osc2_semitone osc2_tune
    osc1_level osc2_level noise_level filter_type cutoff resonance eg1_int filter_kbd_track
    amp_level pan eg2_gate distortion eg1_attack eg1_decay eg1_sustain eg1_release
    eg2_attack eg2_decay eg2_sustain eg2_release lfo1_wave lfo1_freq lfo2_wave lfo2_freq
    patch1_int patch2_int patch3_int patch4_int arp_on mod_speed mod_depth delay_time
    delay_feedback unused
  ].freeze

  # Field description: offset, mask, shift, plus :bias (value = raw - bias),
  # :enum (symbols by raw value), :bool, :s8 (signed byte) or :u16 (MSB,LSB).
  Field = Struct.new(:offset, :mask, :shift, :bias, :enum, :bool, :kind, keyword_init: true)

  def self.field(offset, mask: 0xFF, shift: 0, bias: 0, enum: nil, bool: false, kind: nil)
    Field.new(offset: offset, mask: mask, shift: shift, bias: bias, enum: enum, bool: bool, kind: kind)
  end

  TIMBRE_FIELDS = {
    midi_channel: field(0, kind: :s8),
    assign_mode: field(1, mask: 0xC0, shift: 6, enum: %i[mono poly unison]),
    eg2_reset: field(1, mask: 0x20, shift: 5, bool: true),
    eg1_reset: field(1, mask: 0x10, shift: 4, bool: true),
    trigger_mode: field(1, mask: 0x08, shift: 3, enum: %i[single multi]),
    key_priority: field(1, mask: 0x03),
    unison_detune: field(2),
    tune: field(3, bias: 64), bend_range: field(4, bias: 64),
    transpose: field(5, bias: 64), vibrato_int: field(6, bias: 64),
    osc1_wave: field(7, enum: %i[saw pulse tri sin vox dwgs noise audio_in]),
    osc1_ctrl1: field(8), osc1_ctrl2: field(9), dwgs_wave: field(10),
    osc2_mod: field(12, mask: 0x30, shift: 4, enum: %i[off ring sync ring_sync]),
    osc2_wave: field(12, mask: 0x03, enum: %i[saw squ tri]),
    osc2_semitone: field(13, bias: 64), osc2_tune: field(14, bias: 64),
    portamento: field(15, mask: 0x7F),
    osc1_level: field(16), osc2_level: field(17), noise_level: field(18),
    filter_type: field(19, enum: %i[lpf24 lpf12 bpf12 hpf12]),
    cutoff: field(20), resonance: field(21), eg1_int: field(22, bias: 64),
    filter_vel_sense: field(23, bias: 64), filter_kbd_track: field(24, bias: 64),
    amp_level: field(25), pan: field(26),
    amp_sw: field(27, mask: 0x40, shift: 6, enum: %i[eg2 gate]),
    distortion: field(27, mask: 0x01, bool: true),
    amp_vel_sense: field(28, bias: 64), amp_kbd_track: field(29, bias: 64),
    eg1_attack: field(30), eg1_decay: field(31), eg1_sustain: field(32), eg1_release: field(33),
    eg2_attack: field(34), eg2_decay: field(35), eg2_sustain: field(36), eg2_release: field(37),
    lfo1_key_sync: field(38, mask: 0x30, shift: 4, enum: %i[off timbre voice]),
    lfo1_wave: field(38, mask: 0x03, enum: %i[saw squ tri sh]),
    lfo1_freq: field(39),
    lfo1_tempo_sync: field(40, mask: 0x80, shift: 7, bool: true),
    lfo1_sync_note: field(40, mask: 0x1F),
    lfo2_key_sync: field(41, mask: 0x30, shift: 4, enum: %i[off timbre voice]),
    lfo2_wave: field(41, mask: 0x03, enum: %i[saw squ_pos sin sh]),
    lfo2_freq: field(42),
    lfo2_tempo_sync: field(43, mask: 0x80, shift: 7, bool: true),
    lfo2_sync_note: field(43, mask: 0x1F),
    **(1..4).flat_map do |n|
      base = 44 + 2 * (n - 1)
      [[:"patch#{n}_destination", field(base, mask: 0xF0, shift: 4, enum: PATCH_DESTINATIONS)],
       [:"patch#{n}_source", field(base, mask: 0x0F, enum: PATCH_SOURCES)],
       [:"patch#{n}_intensity", field(base + 1, bias: 64)]]
    end.to_h
  }.freeze

  PROGRAM_FIELDS = {
    voice_mode: field(16, mask: 0x30, shift: 4, enum: { 0 => :single, 2 => :layer, 3 => :vocoder }),
    scale_key: field(17, mask: 0xF0, shift: 4), scale_type: field(17, mask: 0x0F),
    delay_sync: field(19, mask: 0x80, shift: 7, bool: true),
    delay_time_base: field(19, mask: 0x0F),
    delay_time: field(20), delay_depth: field(21),
    delay_type: field(22, enum: %i[stereo cross lr]),
    mod_fx_speed: field(23), mod_fx_depth: field(24),
    mod_fx_type: field(25, enum: %i[cho_flg ensemble phaser]),
    eq_hi_freq: field(26), eq_hi_gain: field(27, bias: 64),
    eq_low_freq: field(28), eq_low_gain: field(29, bias: 64),
    arp_tempo: field(30, kind: :u16),
    arp_on: field(32, mask: 0x80, shift: 7, bool: true),
    arp_latch: field(32, mask: 0x40, shift: 6, bool: true),
    arp_target: field(32, mask: 0x30, shift: 4, enum: %i[both timbre1 timbre2]),
    arp_key_sync: field(32, mask: 0x01, bool: true),
    arp_type: field(33, mask: 0x0F, enum: %i[up down alt1 alt2 random trigger]),
    arp_range: field(33, mask: 0xF0, shift: 4),
    arp_gate_time: field(34), arp_resolution: field(35), arp_swing: field(36, kind: :s8),
    kbd_octave: field(37, kind: :s8)
  }.freeze

  TIMBRE_OFFSETS = { 1 => 38, 2 => 146 }.freeze

  # A single program (254 bytes). Access fields with [] / []=.
  #   prog[:name], prog[:voice_mode], prog.timbre(1)[:cutoff] = 80
  class Program
    attr_reader :bytes

    def self.from_dump(midi_bytes)
      new(Codec.decode(midi_bytes))
    end

    def initialize(bytes = nil)
      @bytes = (bytes || Array.new(CURRENT_PROGRAM_SIZE, 0)).dup
      raise Error, "program must have #{CURRENT_PROGRAM_SIZE} bytes, got #{@bytes.size}" unless @bytes.size == CURRENT_PROGRAM_SIZE
    end

    def name
      @bytes[0, 12].pack('C*').delete("\0").rstrip
    end

    def name=(text)
      chars = text.to_s.encode('ASCII', undef: :replace, replace: '?').ljust(12)[0, 12].bytes
      @bytes[0, 12] = chars
    end

    def [](field)
      return name if field == :name

      MicroKorg.read_field(@bytes, 0, PROGRAM_FIELDS.fetch(field) { raise ArgumentError, "unknown program field #{field}" })
    end

    def []=(field, value)
      return (self.name = value) if field == :name

      MicroKorg.write_field(@bytes, 0, PROGRAM_FIELDS.fetch(field) { raise ArgumentError, "unknown program field #{field}" }, value)
    end

    def timbre(number)
      Timbre.new(@bytes, TIMBRE_OFFSETS.fetch(number) { raise ArgumentError, 'timbre must be 1 or 2' })
    end

    def to_dump
      Codec.encode(@bytes)
    end
  end

  # View over one timbre (synth parameters, TABLE 2) inside a program.
  class Timbre
    def initialize(bytes, base)
      @bytes = bytes
      @base = base
    end

    def [](field)
      MicroKorg.read_field(@bytes, @base, TIMBRE_FIELDS.fetch(field) { raise ArgumentError, "unknown timbre field #{field}" })
    end

    def []=(field, value)
      MicroKorg.write_field(@bytes, @base, TIMBRE_FIELDS.fetch(field) { raise ArgumentError, "unknown timbre field #{field}" }, value)
    end

    def to_h
      TIMBRE_FIELDS.keys.to_h { |k| [k, self[k]] }
    end
  end

  def self.read_field(bytes, base, f)
    raw = bytes[base + f.offset]
    case f.kind
    when :s8 then return raw > 127 ? raw - 256 : raw
    when :u16 then return (raw << 8) | bytes[base + f.offset + 1]
    end
    raw = (raw & f.mask) >> f.shift
    return raw != 0 if f.bool
    return (f.enum.is_a?(Hash) ? f.enum[raw] : f.enum[raw]) || raw if f.enum

    raw - f.bias
  end

  def self.write_field(bytes, base, f, value)
    case f.kind
    when :s8 then bytes[base + f.offset] = value & 0xFF
      return value
    when :u16
      bytes[base + f.offset] = (value >> 8) & 0xFF
      bytes[base + f.offset + 1] = value & 0xFF
      return value
    end
    raw =
      if f.bool then value ? 1 : 0
      elsif f.enum
        f.enum.is_a?(Hash) ? (f.enum.key(value) || value) : (f.enum.index(value) || value)
      else value + f.bias
      end
    raise ArgumentError, "invalid value #{value.inspect}" unless raw.is_a?(Integer) && raw >= 0 && (raw << f.shift) <= f.mask

    bytes[base + f.offset] = (bytes[base + f.offset] & ~f.mask) | (raw << f.shift)
    value
  end

  # Program number (0..127) as printed on the unit: A11..A88, b11..b88.
  def self.program_label(number)
    raise ArgumentError, 'program must be 0..127' unless (0..127).cover?(number)

    "#{number < 64 ? 'A' : 'b'}#{((number % 64) / 8) + 1}#{(number % 8) + 1}"
  end

  # Decoded SysEx message received from the unit.
  Message = Struct.new(:channel, :function, :body, keyword_init: true)

  class Device
    attr_reader :channel, :cc_map

    # channel: 0..15 (also used as SysEx "global channel"/device id)
    def initialize(output:, input: nil, channel: 0)
      @output = output
      @input = input
      @channel = channel
      @cc_map = {}
    end

    # Convenience: open the first UniMIDI ports whose name matches +name+.
    def self.open(name: /microkorg/i, channel: 0)
      require 'unimidi'
      pick = lambda do |klass|
        klass.all.find { |d| d.name =~ name } or raise DeviceError, "no #{klass.name} port matching #{name.inspect}"
      end
      out = pick.call(UniMIDI::Output)
      inp = pick.call(UniMIDI::Input)
      out.open
      inp.open
      new(output: out, input: inp, channel: channel)
    end

    # ---- channel messages -------------------------------------------------

    def note_on(note, velocity = 100)
      send_bytes(0x90 | @channel, check7(note), check7(velocity.clamp(1, 127)))
    end

    def note_off(note, velocity = 64)
      send_bytes(0x80 | @channel, check7(note), check7(velocity))
    end

    def play(note, duration: 0.5, velocity: 100)
      note_on(note, velocity)
      sleep duration
      note_off(note)
    end

    def program_change(number)
      send_bytes(0xC0 | @channel, check7(number))
    end

    def pitch_bend(value)
      v = (value.clamp(-8192, 8191) + 8192)
      send_bytes(0xE0 | @channel, v & 0x7F, v >> 7)
    end

    def mod_wheel(value) = control_change(1, value)
    def all_sound_off = control_change(120, 0)
    def reset_controllers = control_change(121, 0)
    def all_notes_off = control_change(123, 0)

    def control_change(number, value)
      send_bytes(0xB0 | @channel, check7(number), check7(value))
    end

    # Panel control by name, using the unit's CC map (see #load_cc_map).
    def control(name, value)
      number = @cc_map[name] or raise Error, "no CC assigned to #{name.inspect}; call load_cc_map or assign_cc_map"
      control_change(number, value)
    end

    def assign_cc_map(map)
      @cc_map = map.dup
    end

    # Reads the Global data and learns which CC# drives each panel control.
    def load_cc_map(timeout: 3)
      data = request_global(timeout: timeout)
      raise Error, 'short global data' if data.size < GLOBAL_SIZE

      @cc_map = CC_PARAMETERS.each_with_index.filter_map do |name, i|
        cc = data[18 + i]
        [name, cc] if cc && cc <= 95
      end.to_h
    end

    # NRPN + Data Entry (spec 2-1 *6). Value handling for named enums:
    # arp_type takes a symbol, patch sources/destinations take symbols,
    # arp_octaves is 1..4 and on/off params take booleans.
    def nrpn(name, value)
      msb, lsb = NRPN.fetch(name) { raise ArgumentError, "unknown NRPN #{name}" }
      control_change(99, msb)
      control_change(98, lsb)
      control_change(6, nrpn_value(name, value))
    end

    def arpeggiator(on)
      nrpn(:arp_on, on)
    end

    def clock = send_bytes(0xF8)
    def start = send_bytes(0xFA)
    def stop = send_bytes(0xFC)

    # ---- universal SysEx --------------------------------------------------

    def master_volume(level)
      sysex_raw(0x7F, 0x04, 0x01, *split14(level.clamp(0, 16_383)))
    end

    # cents: -100..+100
    def master_fine_tune(cents)
      sysex_raw(0x7F, 0x04, 0x03, *split14((8192 + (cents.clamp(-100, 100) * 8192 / 100.0).round).clamp(0, 16_383)))
    end

    # Returns { channel:, minor:, major:, member: } or raises on timeout.
    def device_inquiry(timeout: 2)
      sysex_raw(0x7E, 0x06, 0x01, device_id: 0x7F)
      msg = read_sysex(timeout)
      b = msg
      unless b[1] == 0x7E && b[3] == 0x06 && b[4] == 0x02 && b[5] == KORG_ID && b[6] == FAMILY_ID
        raise DeviceError, "unexpected inquiry reply #{hex(b)}"
      end

      { channel: b[2], member: b[8], minor: b[10] | (b[11] << 7), major: b[12] | (b[13] << 7), micro_korg: b[8] == 0x11 }
    end

    # ---- KORG SysEx -------------------------------------------------------

    def request_current_program(timeout: 3)
      Program.from_dump(request(:current_program_request, :current_program_dump, timeout))
    end

    # Returns all 128 programs in memory.
    def request_all_programs(timeout: 10)
      data = Codec.decode(request(:program_request, :program_dump, timeout))
      data.each_slice(CURRENT_PROGRAM_SIZE).first(128).map { |s| Program.new(s) }
    end

    def request_global(timeout: 3)
      Codec.decode(request(:global_request, :global_dump, timeout))
    end

    # Loads +program+ into the edit buffer. Needs "SystemEx" = ENA on the unit.
    def send_current_program(program, timeout: 3)
      korg_sysex(FUNC[:current_program_dump], *program.to_dump)
      expect_ack(timeout, :load_ok, :load_error)
    end

    # Stores the edit buffer into program slot 0..127.
    def write_program(number, timeout: 3)
      korg_sysex(FUNC[:program_write], 0x00, check7(number))
      expect_ack(timeout, :write_ok, :write_error)
    end

    # ---- low level --------------------------------------------------------

    def send_bytes(*bytes)
      @output.puts(bytes)
      bytes
    end

    def korg_sysex(function, *body)
      send_bytes(SYSEX_START, KORG_ID, 0x30 | @channel, FAMILY_ID, function, *body, SYSEX_END)
    end

    # Reads until a full SysEx (F0 ... F7) is received; returns its bytes.
    def read_sysex(timeout = 3)
      raise Error, 'no input port configured' unless @input

      buffer = nil
      Timeout.timeout(timeout) do
        loop do
          @input.gets.each do |m|
            m[:data].each do |byte|
              buffer = [] if byte == SYSEX_START
              next unless buffer
              next if byte >= 0xF8 && byte != SYSEX_END

              buffer << byte
              return buffer if byte == SYSEX_END
            end
          end
        end
      end
    rescue Timeout::Error
      raise DeviceError, "timeout waiting for SysEx (#{timeout}s)"
    end

    # Parses a KORG SysEx (F0 42 3g 58 func ... F7).
    def self.parse_korg(bytes)
      unless bytes[0] == SYSEX_START && bytes[1] == KORG_ID && (bytes[2] & 0xF0) == 0x30 && bytes[3] == FAMILY_ID && bytes.last == SYSEX_END
        raise DeviceError, "not a microKORG SysEx: #{bytes.map { |b| format('%02X', b) }.join(' ')}"
      end

      Message.new(channel: bytes[2] & 0x0F, function: FUNC_NAMES[bytes[4]] || bytes[4], body: bytes[5...-1])
    end

    private

    def request(request_func, reply_func, timeout)
      korg_sysex(FUNC.fetch(request_func))
      msg = self.class.parse_korg(read_sysex(timeout))
      return msg.body if msg.function == reply_func

      raise DeviceError, "expected #{reply_func}, got #{msg.function}"
    end

    def expect_ack(timeout, ok, error)
      msg = self.class.parse_korg(read_sysex(timeout))
      return true if msg.function == ok

      raise DeviceError, "#{msg.function} (expected #{ok}; #{error} means rejected, e.g. memory protect)"
    end

    def sysex_raw(kind, *body, device_id: @channel)
      send_bytes(SYSEX_START, kind, device_id, *body, SYSEX_END)
    end

    def nrpn_value(name, value)
      case name
      when :arp_on, :arp_latch then value ? 0x7F : 0x00
      when :arp_octaves then check7(value - 1).tap { raise ArgumentError, 'octaves 1..4' unless (1..4).cover?(value) }
      when :arp_type then value.is_a?(Symbol) ? ARP_TYPES.fetch(value) : check7(value)
      when /patch\d_source/ then value.is_a?(Symbol) ? PATCH_SOURCES.index(value).then { |i| (i or raise ArgumentError, "bad source #{value}") << 4 } : check7(value)
      when /patch\d_destination/ then value.is_a?(Symbol) ? PATCH_DESTINATIONS.index(value).then { |i| (i or raise ArgumentError, "bad destination #{value}") << 4 } : check7(value)
      else check7(value)
      end
    end

    def split14(v) = [v & 0x7F, v >> 7]

    def check7(v)
      raise ArgumentError, "value out of 0..127: #{v.inspect}" unless v.is_a?(Integer) && v.between?(0, 127)

      v
    end

    def hex(bytes) = bytes.map { |b| format('%02X', b) }.join(' ')
  end
end
