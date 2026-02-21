class_name MusicGenerator
## Procedural BGM generator with multiple original tracks.
## All melodies are original compositions — no copyrighted material.

const SAMPLE_RATE := 44100
const MAX_16BIT := 32767.0

# ── Note frequencies (Hz) ──
const R := 0.0  # Rest
const A2 := 110.00; const Bb2 := 116.54
const C3 := 130.81; const D3 := 146.83; const E3 := 164.81
const F3 := 174.61; const G3 := 196.00; const A3 := 220.00
const Bb3 := 233.08; const B3 := 246.94
const C4 := 261.63; const D4 := 293.66; const E4 := 329.63
const F4 := 349.23; const G4 := 392.00; const A4 := 440.00
const Bb4 := 466.16; const B4 := 493.88
const C5 := 523.25; const D5 := 587.33; const E5 := 659.26
const F5 := 698.46; const G5 := 783.99; const A5 := 880.00

# ── Track metadata ──
const TRACK_LIST: Array = [
	{"id": "classic", "name": "Classic"},
	{"id": "puzzle_fever", "name": "Puzzle Fever"},
	{"id": "neon_rush", "name": "Neon Rush"},
	{"id": "zen_flow", "name": "Zen Flow"},
]

static func get_track_list() -> Array:
	return TRACK_LIST


static func generate_track(track_id: String) -> AudioStreamWAV:
	return _render_track(_get_config(track_id))


## Backward-compatible entry point
static func generate_bgm() -> AudioStreamWAV:
	return generate_track("classic")


static func _get_config(track_id: String) -> Dictionary:
	match track_id:
		"puzzle_fever": return _config_puzzle_fever()
		"neon_rush": return _config_neon_rush()
		"zen_flow": return _config_zen_flow()
		_: return _config_classic()


# ═══════════════════════════════════════════════════════════════════
# Track Configurations — each defines tempo, melody, harmony, timbre
# ═══════════════════════════════════════════════════════════════════

## Classic: Bright C-major pop feel, 128 BPM
static func _config_classic() -> Dictionary:
	return {
		"bpm": 128.0, "bars": 8,
		"melody_wave": "square",
		"melody": [
			C5, E5, G5, E5, C5, D5, E5, R,
			D5, E5, G5, A5, G5, E5, D5, C5,
			B4, D5, G5, D5, B4, D5, E5, R,
			D5, E5, G5, A5, G5, D5, E5, D5,
			A4, C5, E5, C5, A4, C5, D5, R,
			C5, D5, E5, G5, E5, C5, D5, C5,
			A4, C5, F5, C5, A4, C5, D5, R,
			G4, A4, C5, E5, D5, C5, A4, C5,
		],
		"bass_pattern": [C3, C3, G3, G3, A3, A3, F3, F3],
		"chord_notes": [
			[C4, E4, G4], [C4, E4, G4],
			[G3, B3, D4], [G3, B3, D4],
			[A3, C4, E4], [A3, C4, E4],
			[F3, A3, C4], [F3, A3, C4],
		],
		"kick_beats": [0, 2],
		"snare_beats": [],
		"hihat_eighths": true,
		"melody_vol": 0.13, "bass_vol": 0.18,
		"chord_vol": 0.06, "kick_vol": 0.15,
		"snare_vol": 0.0, "hihat_vol": 0.04,
	}


## Puzzle Fever: Driving A-minor, 144 BPM — addictive energy
## Am → Em → F → G progression with scalar runs
static func _config_puzzle_fever() -> Dictionary:
	return {
		"bpm": 144.0, "bars": 8,
		"melody_wave": "square",
		"melody": [
			# Bar 1 (Am): Strong descending opening
			E5, E5, D5, C5, B4, A4, B4, C5,
			# Bar 2 (Am): Echo and rise
			D5, E5, D5, C5, A4, R, A4, C5,
			# Bar 3 (Em): New phrase — leap and descend
			B4, B4, D5, E5, G5, E5, D5, B4,
			# Bar 4 (Em): Answer phrase
			E5, D5, B4, G4, A4, B4, D5, R,
			# Bar 5 (F): Contrasting brighter section
			C5, C5, F5, E5, C5, A4, C5, F5,
			# Bar 6 (F): Development
			E5, F5, E5, C5, A4, R, A4, C5,
			# Bar 7 (G): Climactic build
			D5, D5, G5, F5, D5, B4, D5, G5,
			# Bar 8 (G): Resolution
			F5, E5, D5, C5, B4, A4, E5, R,
		],
		"bass_pattern": [A2, A2, E3, E3, F3, F3, G3, G3],
		"chord_notes": [
			[A3, C4, E4], [A3, C4, E4],
			[E3, G3, B3], [E3, G3, B3],
			[F3, A3, C4], [F3, A3, C4],
			[G3, B3, D4], [G3, B3, D4],
		],
		"kick_beats": [0, 1, 2, 3],  # Four-on-the-floor
		"snare_beats": [1, 3],
		"hihat_eighths": true,
		"melody_vol": 0.15, "bass_vol": 0.20,
		"chord_vol": 0.07, "kick_vol": 0.16,
		"snare_vol": 0.06, "hihat_vol": 0.035,
	}


## Neon Rush: Synth-wave D-minor, 136 BPM — arpeggiated electronic
## Dm → Bb → C → Am with saw-wave lead
static func _config_neon_rush() -> Dictionary:
	return {
		"bpm": 136.0, "bars": 8,
		"melody_wave": "saw",
		"melody": [
			# Bar 1 (Dm): Arpeggio sweep up
			D5, F5, A5, F5, D5, A4, D5, F5,
			# Bar 2 (Dm): Descending answer
			A5, F5, D5, E5, F5, D5, A4, R,
			# Bar 3 (Bb): Shift to Bb
			Bb4, D5, F5, D5, Bb4, F4, Bb4, D5,
			# Bar 4 (Bb): Develop
			F5, D5, Bb4, C5, D5, Bb4, F4, R,
			# Bar 5 (C): Brighter — C major arpeggio
			C5, E5, G5, E5, C5, G4, C5, E5,
			# Bar 6 (C): Build energy
			G5, E5, C5, D5, E5, G5, A5, R,
			# Bar 7 (Am): Tension
			A4, C5, E5, C5, A4, E4, A4, C5,
			# Bar 8 (Am): Resolve
			E5, C5, A4, B4, C5, D5, E5, R,
		],
		"bass_pattern": [D3, D3, Bb2, Bb2, C3, C3, A2, A2],
		"chord_notes": [
			[D4, F4, A4], [D4, F4, A4],
			[Bb3, D4, F4], [Bb3, D4, F4],
			[C4, E4, G4], [C4, E4, G4],
			[A3, C4, E4], [A3, C4, E4],
		],
		"kick_beats": [0, 2],
		"snare_beats": [1, 3],
		"hihat_eighths": true,
		"melody_vol": 0.11, "bass_vol": 0.18,
		"chord_vol": 0.05, "kick_vol": 0.17,
		"snare_vol": 0.07, "hihat_vol": 0.03,
	}


## Zen Flow: Gentle C-major, 88 BPM — spacious and relaxing
## Cmaj7 → Fmaj7 → Am7 → G with triangle-wave melody
static func _config_zen_flow() -> Dictionary:
	return {
		"bpm": 88.0, "bars": 8,
		"melody_wave": "triangle",
		"melody": [
			# Bar 1 (Cmaj7): Gentle opening
			E5, R, G5, R, E5, D5, C5, R,
			# Bar 2 (Cmaj7): Echo
			D5, R, E5, R, G5, R, E5, R,
			# Bar 3 (Fmaj7): New color
			F5, R, A5, R, F5, E5, C5, R,
			# Bar 4 (Fmaj7): Gentle movement
			E5, R, F5, R, A5, R, F5, R,
			# Bar 5 (Am7): Shift down
			A4, R, C5, R, E5, D5, C5, R,
			# Bar 6 (Am7): Linger
			B4, R, C5, R, E5, R, C5, R,
			# Bar 7 (G): Brighten
			G4, R, B4, R, D5, C5, B4, R,
			# Bar 8 (G): Resolve
			C5, R, D5, R, G5, R, E5, R,
		],
		"bass_pattern": [C3, C3, F3, F3, A3, A3, G3, G3],
		"chord_notes": [
			[C4, E4, G4], [C4, E4, G4],
			[F3, A3, C4], [F3, A3, C4],
			[A3, C4, E4], [A3, C4, E4],
			[G3, B3, D4], [G3, B3, D4],
		],
		"kick_beats": [0],
		"snare_beats": [],
		"hihat_eighths": false,
		"melody_vol": 0.14, "bass_vol": 0.14,
		"chord_vol": 0.05, "kick_vol": 0.10,
		"snare_vol": 0.0, "hihat_vol": 0.0,
	}


# ═══════════════════════════════════════════════════════════════════
# Generic track renderer — turns any config into an AudioStreamWAV
# ═══════════════════════════════════════════════════════════════════

static func _render_track(cfg: Dictionary) -> AudioStreamWAV:
	var bpm: float = cfg["bpm"]
	var bars: int = cfg["bars"]
	var beat_sec := 60.0 / bpm
	var beats_per_bar := 4
	var total_beats := bars * beats_per_bar
	var total_samples := int(SAMPLE_RATE * beat_sec * total_beats)
	var eighth := beat_sec / 2.0

	var melody: Array = cfg["melody"]
	var bass_pattern: Array = cfg["bass_pattern"]
	var chord_notes: Array = cfg["chord_notes"]
	var kick_beats: Array = cfg["kick_beats"]
	var snare_beats: Array = cfg["snare_beats"]
	var hihat_on: bool = cfg["hihat_eighths"]
	var melody_wave: String = cfg["melody_wave"]

	var samples := PackedByteArray()

	for i in total_samples:
		var t := float(i) / SAMPLE_RATE
		var beat := t / beat_sec
		var bar := mini(int(beat) / beats_per_bar, bars - 1)
		var beat_in_bar := int(beat) % beats_per_bar

		var sample := 0.0

		# ── Layer 1: Bass (triangle wave, quarter notes) ──
		var bass_freq: float = bass_pattern[bar]
		var beat_t := fmod(t, beat_sec)
		var bass_env := _smooth_env(beat_t, 0.01, beat_sec * 0.9, 0.05)
		sample += _triangle(t, bass_freq) * bass_env * cfg["bass_vol"]

		# ── Layer 2: Chords (soft square, half notes) ──
		var chord: Array = chord_notes[bar]
		var half_t := fmod(t, beat_sec * 2.0)
		var chord_env := _smooth_env(half_t, 0.02, beat_sec * 1.8, 0.1)
		for note_freq in chord:
			sample += _soft_square(t, note_freq) * chord_env * cfg["chord_vol"]

		# ── Layer 3: Melody (configurable waveform, eighth notes) ──
		var eighth_idx := int(t / eighth)
		if eighth_idx < melody.size():
			var mel_freq: float = melody[eighth_idx]
			if mel_freq > 0.0:
				var mel_t := fmod(t, eighth)
				var mel_env := _smooth_env(mel_t, 0.005, eighth * 0.85, 0.02)
				var mel_sample: float
				match melody_wave:
					"triangle": mel_sample = _triangle(t, mel_freq)
					"saw": mel_sample = _saw(t, mel_freq)
					_: mel_sample = _soft_square(t, mel_freq)
				sample += mel_sample * mel_env * cfg["melody_vol"]

		# ── Layer 4: Hi-hat (noise, eighth notes) ──
		if hihat_on:
			var hh_t := fmod(t, eighth)
			var hh_env := exp(-hh_t * 60.0) * _attack(hh_t, 0.001)
			var noise_val := sin(float(i) * 12345.6789) * sin(float(i) * 6789.1234)
			sample += noise_val * hh_env * cfg["hihat_vol"]

		# ── Layer 5: Kick (sine sweep, configurable beats) ──
		if beat_in_bar in kick_beats:
			var kick_t := fmod(t, beat_sec)
			var kick_freq := lerpf(150.0, 60.0, minf(kick_t * 10.0, 1.0))
			var kick_env := exp(-kick_t * 15.0) * _attack(kick_t, 0.002)
			sample += sin(kick_t * kick_freq * TAU) * kick_env * cfg["kick_vol"]

		# ── Layer 6: Snare (noise + tonal body, configurable beats) ──
		if not snare_beats.is_empty() and beat_in_bar in snare_beats:
			var snare_t := fmod(t, beat_sec)
			var snare_env := exp(-snare_t * 25.0) * _attack(snare_t, 0.001)
			var snare_noise := sin(float(i) * 7891.234) * sin(float(i) * 3456.789)
			var snare_tone := sin(snare_t * 180.0 * TAU) * exp(-snare_t * 35.0)
			sample += (snare_noise * 0.7 + snare_tone * 0.3) * snare_env * cfg["snare_vol"]

		_write_sample(samples, sample)

	return _make_looping_wav(samples)


# ═══════════════════════════════════════════════════════════════════
# Waveform helpers
# ═══════════════════════════════════════════════════════════════════

## Band-limited square approximation (first 3 odd harmonics)
static func _soft_square(t: float, freq: float) -> float:
	var phase := t * freq * TAU
	var s := sin(phase)
	s += sin(phase * 3.0) / 3.0
	s += sin(phase * 5.0) / 5.0
	return s * 0.63

## Triangle wave
static func _triangle(t: float, freq: float) -> float:
	var phase := fmod(t * freq, 1.0)
	return (4.0 * absf(phase - 0.5) - 1.0)

## Band-limited sawtooth approximation (first 6 harmonics)
static func _saw(t: float, freq: float) -> float:
	var phase := t * freq * TAU
	var s := 0.0
	s -= sin(phase)
	s -= sin(phase * 2.0) / 2.0
	s -= sin(phase * 3.0) / 3.0
	s -= sin(phase * 4.0) / 4.0
	s -= sin(phase * 5.0) / 5.0
	s -= sin(phase * 6.0) / 6.0
	return s * 0.4

## Linear attack ramp
static func _attack(t: float, ramp: float) -> float:
	return minf(t / ramp, 1.0) if ramp > 0.0 else 1.0

## Attack-sustain-release envelope
static func _smooth_env(t: float, att: float, sustain_end: float, rel: float) -> float:
	if t < att:
		return t / att
	if t < sustain_end:
		return 1.0
	var rel_t := t - sustain_end
	return maxf(0.0, 1.0 - rel_t / rel)

static func _write_sample(buffer: PackedByteArray, sample: float) -> void:
	var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
	buffer.append(s16 & 0xFF)
	buffer.append((s16 >> 8) & 0xFF)

static func _make_looping_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = samples
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples.size() / 2
	return wav
