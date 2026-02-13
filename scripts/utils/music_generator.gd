class_name MusicGenerator

const SAMPLE_RATE := 44100
const MAX_16BIT := 32767.0
const BPM := 128.0
const BEAT_SEC := 60.0 / BPM  # ~0.46875s per beat
const BARS := 8
const BEATS_PER_BAR := 4
const TOTAL_BEATS := BARS * BEATS_PER_BAR  # 32 beats
const TOTAL_SAMPLES := int(SAMPLE_RATE * BEAT_SEC * TOTAL_BEATS)

# Note frequencies (Hz)
const C3 := 130.81; const D3 := 146.83; const E3 := 164.81
const F3 := 174.61; const G3 := 196.00; const A3 := 220.00; const B3 := 246.94
const C4 := 261.63; const D4 := 293.66; const E4 := 329.63
const F4 := 349.23; const G4 := 392.00; const A4 := 440.00; const B4 := 493.88
const C5 := 523.25; const D5 := 587.33; const E5 := 659.26
const F5 := 698.46; const G5 := 783.99; const A5 := 880.00

# Chord roots per bar (2 bars each): C - G - Am - F
const BASS_PATTERN: Array = [C3, C3, G3, G3, A3, A3, F3, F3]

# Chord triads per bar
const CHORD_NOTES: Array = [
	[C4, E4, G4], [C4, E4, G4],  # C major
	[G3, B3, D4], [G3, B3, D4],  # G major
	[A3, C4, E4], [A3, C4, E4],  # A minor
	[F3, A3, C4], [F3, A3, C4],  # F major
]

# Melody: eighth notes (2 per beat = 64 total). 0 = rest.
const MELODY: Array = [
	# Bar 1-2 (C)
	C5, E5, G5, E5, C5, D5, E5, 0.0,
	D5, E5, G5, A5, G5, E5, D5, C5,
	# Bar 3-4 (G)
	B4, D5, G5, D5, B4, D5, E5, 0.0,
	D5, E5, G5, A5, G5, D5, E5, D5,
	# Bar 5-6 (Am)
	A4, C5, E5, C5, A4, C5, D5, 0.0,
	C5, D5, E5, G5, E5, C5, D5, C5,
	# Bar 7-8 (F)
	A4, C5, F5, C5, A4, C5, D5, 0.0,
	G4, A4, C5, E5, D5, C5, A4, C5,
]


static func generate_bgm() -> AudioStreamWAV:
	var samples := PackedByteArray()
	var eighth := BEAT_SEC / 2.0  # duration of one eighth note

	for i in TOTAL_SAMPLES:
		var t := float(i) / SAMPLE_RATE
		var beat := t / BEAT_SEC
		var bar := int(beat) / BEATS_PER_BAR
		if bar >= BARS:
			bar = BARS - 1

		var sample := 0.0

		# --- Layer 1: Bass (triangle wave, quarter notes) ---
		var bass_freq: float = BASS_PATTERN[bar]
		var beat_t := fmod(t, BEAT_SEC)
		var bass_env := _smooth_env(beat_t, 0.01, BEAT_SEC * 0.9, 0.05)
		sample += _triangle(t, bass_freq) * bass_env * 0.18

		# --- Layer 2: Chords (soft square, half notes) ---
		var chord: Array = CHORD_NOTES[bar]
		var half_t := fmod(t, BEAT_SEC * 2.0)
		var chord_env := _smooth_env(half_t, 0.02, BEAT_SEC * 1.8, 0.1)
		for note_freq in chord:
			sample += _soft_square(t, note_freq) * chord_env * 0.06

		# --- Layer 3: Melody (square wave, eighth notes) ---
		var eighth_idx := int(t / eighth)
		if eighth_idx < MELODY.size():
			var mel_freq: float = MELODY[eighth_idx]
			if mel_freq > 0.0:
				var mel_t := fmod(t, eighth)
				var mel_env := _smooth_env(mel_t, 0.005, eighth * 0.85, 0.02)
				sample += _soft_square(t, mel_freq) * mel_env * 0.13

		# --- Layer 4: Hi-hat (noise, eighth notes) ---
		var hh_t := fmod(t, eighth)
		var hh_env := exp(-hh_t * 60.0) * _attack(hh_t, 0.001)
		# Deterministic noise from sample position
		var noise_val := sin(float(i) * 12345.6789) * sin(float(i) * 6789.1234)
		sample += noise_val * hh_env * 0.04

		# --- Layer 5: Kick (sine, beats 1 and 3) ---
		var beat_in_bar := int(beat) % BEATS_PER_BAR
		if beat_in_bar == 0 or beat_in_bar == 2:
			var kick_t := fmod(t, BEAT_SEC)
			var kick_freq := lerpf(150.0, 60.0, minf(kick_t * 10.0, 1.0))
			var kick_env := exp(-kick_t * 15.0) * _attack(kick_t, 0.002)
			sample += sin(kick_t * kick_freq * TAU) * kick_env * 0.15

		_write_sample(samples, sample)

	return _make_looping_wav(samples)


# ── Waveform helpers ──

static func _soft_square(t: float, freq: float) -> float:
	# Band-limited square approximation (first 3 odd harmonics)
	var phase := t * freq * TAU
	var s := sin(phase)
	s += sin(phase * 3.0) / 3.0
	s += sin(phase * 5.0) / 5.0
	return s * 0.63  # normalize roughly

static func _triangle(t: float, freq: float) -> float:
	var phase := fmod(t * freq, 1.0)
	return (4.0 * absf(phase - 0.5) - 1.0)

static func _attack(t: float, ramp: float) -> float:
	return minf(t / ramp, 1.0) if ramp > 0.0 else 1.0

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
	wav.loop_end = samples.size() / 2  # 16-bit = 2 bytes per sample
	return wav
