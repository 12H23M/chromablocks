class_name SFXGenerator
## Retro Arcade SFX — 8-bit/16-bit inspired electronic sounds.
## Square wave + triangle wave + noise for authentic chiptune feel.
## Designed for colorful block puzzle game (ChromaBlocks).

const SAMPLE_RATE := 44100
const MAX_16BIT := 32767.0
const TAU_CONST := TAU

# ── Musical constants (C major pentatonic) ──
const NOTE_C5  := 523.25
const NOTE_D5  := 587.33
const NOTE_E5  := 659.26
const NOTE_F5  := 698.46
const NOTE_G5  := 783.99
const NOTE_A5  := 880.00
const NOTE_C6  := 1046.50
const NOTE_E6  := 1318.51
const NOTE_G6  := 1567.98
const NOTE_C7  := 2093.00

# ── Retro Waveforms ──

static func _square(t: float, freq: float) -> float:
	return 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0

static func _triangle(t: float, freq: float) -> float:
	var p := fmod(t * freq, 1.0)
	return 4.0 * absf(p - 0.5) - 1.0

static func _noise_bit(t: float) -> float:
	var n := int(t * SAMPLE_RATE)
	var x := (n * 1103515245 + 12345) & 0x7FFFFFFF
	return float(x) / float(0x7FFFFFFF) * 2.0 - 1.0

# ── Envelopes ──

static func _exp_decay(t: float, rate: float) -> float:
	return exp(-t * rate)

static func _attack(t: float, ramp: float) -> float:
	if ramp <= 0.0:
		return 1.0
	return minf(1.0, t / ramp)

static func _fade_out(t: float, duration: float, fade_time: float) -> float:
	var remaining := duration - t
	if remaining < fade_time:
		return maxf(0.0, remaining / fade_time)
	return 1.0

# ── Public Generators ──

static func generate_block_place() -> AudioStreamWAV:
	## Retro placement — triangle body with square click.
	var samples := PackedByteArray()
	var duration := 0.08
	var total := int(SAMPLE_RATE * duration)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var freq := 300.0 + 200.0 * _exp_decay(t, 30.0)
		var s := _triangle(t, freq) * _exp_decay(t, 25.0) * 0.30
		s += _square(t, freq * 2.0) * _exp_decay(t, 40.0) * 0.08
		s += _noise_bit(t) * _exp_decay(t, 60.0) * 0.04
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_line_clear(line_count: int = 1) -> AudioStreamWAV:
	## Bright ascending chiptune sweep — higher for more lines.
	var samples := PackedByteArray()
	var duration := 0.25
	var total := int(SAMPLE_RATE * duration)
	# Pitch range scales with line count
	var base_freq := 400.0 + float(clampi(line_count - 1, 0, 3)) * 200.0
	var top_freq := base_freq + 2000.0 + float(clampi(line_count - 1, 0, 3)) * 500.0
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(base_freq, top_freq, t / duration)
		var s := _square(t, freq) * 0.20
		s += _triangle(t, freq * 0.5) * 0.10
		s += _square(t, freq * 2.01) * 0.05  # shimmer
		var env := _attack(t, 0.005) * _exp_decay(t, 3.0)
		s *= env * _fade_out(t, duration, 0.05)
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_color_match() -> AudioStreamWAV:
	## Quick retro ping — square wave with pitch drop.
	var samples := PackedByteArray()
	var duration := 0.10
	var total := int(SAMPLE_RATE * duration)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var freq := 1000.0 + 500.0 * _exp_decay(t, 20.0)
		var s := _square(t, freq) * _exp_decay(t, 30.0) * 0.18
		s += _triangle(t, freq * 0.5) * _exp_decay(t, 35.0) * 0.10
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_combo_clear(combo_level: int) -> AudioStreamWAV:
	## 8-bit escalating combo — ascending notes, more notes per level.
	var samples := PackedByteArray()

	if combo_level <= 1:
		var duration := 0.08
		var total := int(SAMPLE_RATE * duration)
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var s := _square(t, NOTE_C5) * _exp_decay(t, 20.0) * 0.20
			s += _triangle(t, NOTE_C5) * _exp_decay(t, 25.0) * 0.10
			_write_sample(samples, s)

	elif combo_level == 2:
		# Double note: C5 → E5
		var duration := 0.15
		var total := int(SAMPLE_RATE * duration)
		var notes := [NOTE_C5, NOTE_E5]
		var gap := 0.055
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var s := 0.0
			for n in notes.size():
				var nt := t - float(n) * gap
				if nt < 0.0:
					continue
				var env := _attack(nt, 0.003) * _exp_decay(nt, 14.0) * 0.25
				s += _square(nt, notes[n]) * env * 0.6
				s += _triangle(nt, notes[n]) * env * 0.4
			_write_sample(samples, s)

	elif combo_level == 3:
		# Triple arpeggio: C5 → E5 → G5
		var duration := 0.20
		var total := int(SAMPLE_RATE * duration)
		var notes := [NOTE_C5, NOTE_E5, NOTE_G5]
		var gap := 0.045
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var s := 0.0
			for n in notes.size():
				var nt := t - float(n) * gap
				if nt < 0.0:
					continue
				var env := _attack(nt, 0.003) * _exp_decay(nt, 10.0) * 0.22
				s += _square(nt, notes[n]) * env * 0.6
				s += _triangle(nt, notes[n]) * env * 0.4
			s *= _fade_out(t, duration, 0.03)
			_write_sample(samples, s)

	else:
		# x4+: Full ascending run with sparkle
		var duration := 0.30
		var total := int(SAMPLE_RATE * duration)
		var pitch_shift := 1.0 + float(clampi(combo_level - 4, 0, 6)) * 0.04
		var notes := [NOTE_C5 * pitch_shift, NOTE_E5 * pitch_shift, NOTE_G5 * pitch_shift, NOTE_C6 * pitch_shift]
		var gap := 0.04
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var s := 0.0
			for n in notes.size():
				var nt := t - float(n) * gap
				if nt < 0.0:
					continue
				var is_last := (n == notes.size() - 1)
				var decay := 3.5 if is_last else 6.0
				var env := _attack(nt, 0.003) * _exp_decay(nt, decay) * 0.20
				s += _square(nt, notes[n]) * env * 0.5
				s += _triangle(nt, notes[n]) * env * 0.5
			# Sparkle glitch on top
			var sp_t := maxf(0.0, t - 0.12)
			if sp_t > 0.0:
				var sp_freq := lerpf(NOTE_C6, NOTE_C7, minf(sp_t / 0.1, 1.0)) * pitch_shift
				var sp_env := _attack(sp_t, 0.005) * _exp_decay(sp_t, 8.0) * 0.08
				s += _square(sp_t, sp_freq) * sp_env
			s *= _fade_out(t, duration, 0.04)
			_write_sample(samples, s)

	return _make_wav(samples)


static func generate_level_up() -> AudioStreamWAV:
	## 8-bit triumphant fanfare — ascending pentatonic run.
	var samples := PackedByteArray()
	var duration := 0.50
	var total := int(SAMPLE_RATE * duration)
	var notes := [NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6, NOTE_E6]
	var gap := 0.08
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		for n in notes.size():
			var nt := t - float(n) * gap
			if nt < 0.0:
				continue
			var is_last := (n == notes.size() - 1)
			var decay := 2.5 if is_last else 5.0
			var env := _attack(nt, 0.005) * _exp_decay(nt, decay) * 0.25
			s += _square(nt, notes[n]) * env * 0.5
			s += _triangle(nt, notes[n]) * env * 0.5
		# Warm pad under final note
		if t > 0.3:
			var pt := t - 0.3
			var pe := _attack(pt, 0.05) * _exp_decay(pt, 2.0) * 0.06
			s += (_triangle(pt, NOTE_C5) + _triangle(pt, NOTE_G5)) * 0.5 * pe
		s *= _fade_out(t, duration, 0.08)
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_game_over() -> AudioStreamWAV:
	## Descending retro arcade tone — not too sad, classic game over feel.
	var samples := PackedByteArray()
	var duration := 0.55
	var total := int(SAMPLE_RATE * duration)
	var notes := [NOTE_G5, NOTE_E5, NOTE_C5, 440.0, 349.23]  # G5 E5 C5 A4 F4
	var gap := 0.09
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		for n in notes.size():
			var nt := t - float(n) * gap
			if nt < 0.0:
				continue
			var is_last := (n == notes.size() - 1)
			var decay := 2.0 if is_last else 4.0
			var env := _attack(nt, 0.008) * _exp_decay(nt, decay) * 0.28
			s += _square(nt, notes[n]) * env * 0.4
			s += _triangle(nt, notes[n]) * env * 0.6
		s *= _fade_out(t, duration, 0.10)
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_perfect_clear() -> AudioStreamWAV:
	## Full 8-bit sparkle cascade — bright ascending arpeggio + glitch dust.
	var samples := PackedByteArray()
	var duration := 0.60
	var total := int(SAMPLE_RATE * duration)
	var notes := [NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6, NOTE_E6, NOTE_G6]
	var gap := 0.055
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		for n in notes.size():
			var nt := t - float(n) * gap
			if nt < 0.0:
				continue
			var env := _attack(nt, 0.004) * _exp_decay(nt, 3.0) * 0.20
			s += _square(nt, notes[n]) * env * 0.4
			s += _triangle(nt, notes[n]) * env * 0.4
			s += _square(nt, notes[n] * 2.003) * env * 0.08  # shimmer
		# Sparkle noise dust
		if t > 0.1:
			s += _noise_bit(t) * _exp_decay(t - 0.1, 3.0) * 0.04
		s *= _fade_out(t, duration, 0.10)
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_button_press() -> AudioStreamWAV:
	## Clean digital UI tap — square tick.
	var samples := PackedByteArray()
	var duration := 0.035
	var total := int(SAMPLE_RATE * duration)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := _square(t, 1500.0) * _exp_decay(t, 70.0) * 0.15
		s += _triangle(t, 800.0) * _exp_decay(t, 80.0) * 0.10
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_place_fail() -> AudioStreamWAV:
	## Low retro buzz — soft rejection.
	var samples := PackedByteArray()
	var duration := 0.08
	var total := int(SAMPLE_RATE * duration)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _attack(t, 0.002) * _exp_decay(t, 20.0) * 0.20
		var s := _square(t, 120.0) * env
		s += _square(t, 145.0) * env * 0.3
		s += _triangle(t, 80.0) * env * 0.4
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_chain_sound(cascade_level: int) -> AudioStreamWAV:
	## Ascending chiptune chimes — staggered notes, higher per cascade.
	var chord_table: Array = [
		[NOTE_C5, NOTE_E5, NOTE_G5],
		[NOTE_E5, NOTE_G5, NOTE_C6],
		[NOTE_G5, NOTE_C6, NOTE_E6],
	]
	var idx := clampi(cascade_level - 1, 0, chord_table.size() - 1)
	var chord: Array = chord_table[idx]

	var samples := PackedByteArray()
	var duration := 0.25
	var total := int(SAMPLE_RATE * duration)
	var note_gap := 0.05

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		for n in chord.size():
			var nt := t - float(n) * note_gap
			if nt < 0.0:
				continue
			var freq: float = chord[n]
			var env := _attack(nt, 0.003) * _exp_decay(nt, 6.0) * 0.25
			s += _square(nt, freq) * env * 0.5
			s += _triangle(nt, freq) * env * 0.5
		# Echo tail
		for n in chord.size():
			var nt := t - float(n) * note_gap - 0.07
			if nt < 0.0:
				continue
			var freq: float = chord[n]
			var env := _attack(nt, 0.005) * _exp_decay(nt, 9.0) * 0.06
			s += _triangle(nt, freq) * env
		# High twinkle on cascade 3
		if cascade_level >= 3:
			var top: float = chord[chord.size() - 1]
			var tw_env := _attack(t, 0.02) * _exp_decay(t, 8.0) * 0.05
			s += _square(t, top * 2.0) * tw_env
		s *= _fade_out(t, duration, 0.04)
		_write_sample(samples, s)
	return _make_wav(samples)


static func generate_blast_sound() -> AudioStreamWAV:
	## Retro impact — low square punch + ascending sparkle sweep.
	var samples := PackedByteArray()
	var duration := 0.35
	var total := int(SAMPLE_RATE * duration)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		# Low impact — pitch-dropping square
		var impact_freq := lerpf(200.0, 60.0, minf(t / 0.05, 1.0))
		var impact_env := _attack(t, 0.002) * _exp_decay(t, 12.0) * 0.35
		s += _square(t, impact_freq) * impact_env
		# Mid body
		var body_env := _attack(t, 0.004) * _exp_decay(t, 6.0) * 0.18
		s += _triangle(t, 165.0) * body_env
		s += _square(t, 220.0) * body_env * 0.3
		# Ascending sparkle (delayed)
		var sp_t := maxf(0.0, t - 0.04)
		if sp_t > 0.0:
			var sp_freq := lerpf(NOTE_G5, NOTE_G6, minf(sp_t / 0.2, 1.0))
			var sp_env := _attack(sp_t, 0.01) * _exp_decay(sp_t, 4.0) * 0.12
			s += _square(sp_t, sp_freq) * sp_env * 0.6
			s += _triangle(sp_t, sp_freq) * sp_env * 0.4
		# Noise burst
		s += _noise_bit(t) * _exp_decay(t, 25.0) * _attack(t, 0.002) * 0.06
		s *= _fade_out(t, duration, 0.06)
		_write_sample(samples, s)
	return _make_wav(samples)


## Generate a combo sound with sequential pitch-up based on combo level.
## Combo x2 = pitch 1.0, x3 = 1.1, x4 = 1.2, etc.
static func generate_combo_sound(combo_level: int) -> AudioStreamWAV:
	var base_pitch: float = 1.0 + maxf(0.0, float(combo_level - 2)) * 0.1
	# Reuse combo_clear generation with pitch applied via frequency scaling
	var samples := PackedByteArray()
	var duration := 0.20
	var total := int(SAMPLE_RATE * duration)
	var notes := [NOTE_C5 * base_pitch, NOTE_E5 * base_pitch, NOTE_G5 * base_pitch]
	var gap := 0.045
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var s := 0.0
		for n in notes.size():
			var nt := t - float(n) * gap
			if nt < 0.0:
				continue
			var env := _attack(nt, 0.003) * _exp_decay(nt, 10.0) * 0.22
			s += _square(nt, notes[n]) * env * 0.6
			s += _triangle(nt, notes[n]) * env * 0.4
		# Sparkle on high combos
		if combo_level >= 4:
			var sp_t := maxf(0.0, t - 0.10)
			if sp_t > 0.0:
				var sp_freq := lerpf(NOTE_C6, NOTE_C7, minf(sp_t / 0.08, 1.0)) * base_pitch
				var sp_env := _attack(sp_t, 0.005) * _exp_decay(sp_t, 8.0) * 0.08
				s += _square(sp_t, sp_freq) * sp_env
		s *= _fade_out(t, duration, 0.03)
		_write_sample(samples, s)
	return _make_wav(samples)


# ── Helpers ──

static func _write_sample(buffer: PackedByteArray, sample: float) -> void:
	var s16 := int(clampf(sample, -1.0, 1.0) * MAX_16BIT)
	buffer.append(s16 & 0xFF)
	buffer.append((s16 >> 8) & 0xFF)

static func _make_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = samples
	wav.stereo = false
	return wav
