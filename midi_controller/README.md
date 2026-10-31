# MIDI Controller Stream Reader

Uma prova de conceito em Ruby que lê um stream MIDI de um controlador e exibe os dados na tela para fins de depuração.

## Funcionalidades

- 📟 **Seleção de dispositivo**: Lista todos os dispositivos MIDI conectados
- 🎵 **Detecção de eventos**: NOTE ON, NOTE OFF, Control Change (CC), Program Change, Pitch Bend
- 🎹 **Conversão de notas**: Exibe notas em formato C4, D#3, etc.
- 🎚️ **Nomes de CC**: Identifica CCs conhecidos (Volume, Sustain, etc.)
- ⏱️ **Timestamp**: Mostra hora precisa de cada evento
- 🔍 **Debug**: Exibe bytes brutos para eventos desconhecidos

## Dependências

Usa a gem `unimidi`, que já está instalada no sistema:

```ruby
require 'unimidi'
```

O `unimidi` suporta:
- **macOS**: CoreMIDI (nativo)
- **Linux**: ALSA (via `alsa-rawmidi`)
- **Windows**: WINMM (via `midi-winmm`)

## Uso

### Execução básica

```bash
ruby midi_reader.rb
```

### Exemplo de saída

```
📟 Available MIDI Input Devices:
  [0] Oxygen 25 (USB Audio Device)
  [1] Virtual MIDI Port

🎛️  Select device (0-1): 0

✅ Connected to: Oxygen 25 (USB Audio Device)
👂 Listening for MIDI events... (Press Ctrl+C to stop)

--------------------------------------------------------------------------------
[14:32:45.123] 🎵 NOTE ON  | Ch1 | Note: C4 (60) | Velocity: 100
[14:32:46.234] 🎚️  CC       | Ch1 | Volume (7) = 85
[14:32:47.345] 🔇 NOTE OFF | Ch1 | Note: C4 (60) | Velocity: 0
[14:32:48.456] 🎛️  PITCH    | Ch1 | Bend: -20.50%
```

## Estrutura de eventos MIDI

### NOTE ON (0x90)
- Status: 0x90 + canal (0-15)
- Byte 1: Número da nota (0-127)
- Byte 2: Velocidade (0-127)

### NOTE OFF (0x80)
- Status: 0x80 + canal
- Byte 1: Número da nota
- Byte 2: Velocidade de soltura

### CONTROL CHANGE (0xB0)
- Status: 0xB0 + canal
- Byte 1: Número do CC (0-127)
- Byte 2: Valor (0-127)

### PROGRAM CHANGE (0xC0)
- Status: 0xC0 + canal
- Byte 1: Número do programa (0-127)

### PITCH BEND (0xE0)
- Status: 0xE0 + canal
- Byte 1: LSB (7 bits)
- Byte 2: MSB (7 bits)
- Range: -100% a +100%

## Depuração

Para adicionar mais CCs conhecidos, edite a função `get_cc_name`:

```ruby
cc_names = {
  1 => 'Modulation',
  7 => 'Volume',
  10 => 'Pan',
  # ... adicione mais aqui
}
```

Para eventos desconhecidos, o script mostra os bytes brutos:

```
❓ UNKNOWN  | Status: 0xF0 | Data: [240, 126, 0, 127, ...]
```

## Troubleshooting

### Nenhum dispositivo encontrado
```
❌ No MIDI input devices found!
```
**Solução**: Conecte um controlador MIDI ou crie uma porta virtual MIDI.

### Linux (ALSA)
```bash
# Listar dispositivos
aconnect -i

# Criar porta MIDI virtual
aseqview
```

### macOS (CoreMIDI)
Use o "Audio MIDI Setup" para criar portas virtuais.

### Windows (WINMM)
Instale um software como loopMIDI para criar portas virtuais.

## Referências

- [UnIMIDI](https://github.com/arirusso/unimidi)
- [MIDI Status Bytes](https://www.midi.org/specifications-old/item/table-1-status-byte)
- [General MIDI](https://en.wikipedia.org/wiki/General_MIDI)
