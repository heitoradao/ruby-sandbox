# 🎹 MIDI Controller Stream Reader - Quickstart

## Instalação rápida

As gems MIDI já estão instaladas globalmente. Nenhuma configuração adicional necessária.

## Testes (sem hardware)

```bash
ruby test_simulator.rb
```

Isso gera eventos MIDI sintéticos e mostra como são parseados.

**Saída esperada:**
```
🧪 MIDI Event Format Testing

[19:42:51.857] 🎵 NOTE ON  | Ch1 | Note: C4 (60) | Velocity: 100
[19:42:52.057] 🔇 NOTE OFF | Ch1 | Note: C4 (60) | Velocity: 0
[19:42:52.458] 🎚️  CC       | Ch1 | Volume (7) = 85
...
✅ Simulator test complete!
```

## Com um controlador MIDI real

```bash
ruby midi_reader.rb
```

**Primeira execução:**
```
📟 Available MIDI Input Devices:
  [0] Oxygen 25 (USB Audio Device)
  [1] Virtual MIDI Port

🎛️  Select device (0-1): 0

✅ Connected to: Oxygen 25 (USB Audio Device)
👂 Listening for MIDI events... (Press Ctrl+C to stop)

[14:32:45.123] 🎵 NOTE ON  | Ch1 | Note: C4 (60) | Velocity: 100
```

## Recursos

- **midi_reader.rb** – Leitor de eventos em tempo real
- **midi_recorder.rb** – Grava eventos em arquivo com timestamps
- **examples.rb** – Exemplos avançados (filtro, sequência, monitor)
- **test_simulator.rb** – Teste sem hardware

## Arquivos de eventos MIDI

| Tipo | Bytes | Significado |
|------|-------|------------|
| NOTE ON | 0x90 | Tecla pressionada |
| NOTE OFF | 0x80 | Tecla solta |
| CONTROL CHANGE | 0xB0 | Knob/fader movido |
| PROGRAM CHANGE | 0xC0 | Instrumento selecionado |
| PITCH BEND | 0xE0 | Wheel de pitch |

Veja `README.md` para documentação completa.
