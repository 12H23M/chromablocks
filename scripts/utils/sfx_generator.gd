class_name SFXGenerator
## Procedural SFX — designed for mobile puzzle games.
## All sounds optimised to be satisfying after thousands of plays.
## Sonic palette: warm bells, soft pops, crystalline chimes.

const SAMPLE_RATE := 44100
const MAX_16BIT := 32767.0

# ── Musical constants (C major pentatonic, octave 5-6) ──
# Using pentatonic avoids dissonance no matter how sounds overlap.
const NOTE_C5  := 523.25
const NOTE_D5  := 587.33
const NOTE_E5  := 659.26
const NOTE_G5  := 783.99
const NOTE_A5  := 880.00
const NOTE_C6  := 1046.50
const NOTE_E6  := 1318.51
const NOTE_G6  := 1567.98

# ── Public generators ──

static func generate_block_place() -> AudioStreamWAV:
	## Soft bubble-wrap pop: rounded sine body + gentle filtered noise burst.
	## Short, warm, zero harshness. The sound you never get tired of.
	var samples := PackedByteArray()
	var duration := 0.08
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Rounded body — pitch drops quickly (300→140Hz) for that "pop" feel
		var pop_freq := lerpf(300.0, 140.0, minf(t / 0.04, 1.0))
		var body_env := _smooth_bump(t, 0.003, 0.015, 0.06) * 0.45
		sample += sin(t * pop_freq * TAU) * body_env

		# Soft air release — very gentle filtered noise
		var air_env := _smooth_bump(t, 0.001, 0.005, 0.035) * 0.08
		# Pseudo band-limited noise via summed detuned sines
		sample += (sin(t * 1200.0 * TAU) + sin(t * 1731.0 * TAU) + sin(t * 2317.0 * TAU)) / 3.0 * air_env

		# Tiny harmonic ring for "satisfying" aftertaste
		var ring_env := _exp_decay(t, 25.0) * _attack(t, 0.005) * 0.06
		sample += sin(t * NOTE_G5 * TAU) * ring_env

		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_line_clear(line_count: int = 1) -> AudioStreamWAV:
	## Clean sparkle chime — ascending shimmer sweep.
	## Higher line counts = brighter, more harmonics. Think Block Blast "ting!✨"
	var samples := PackedByteArray()
	var duration := 0.22
	var total := int(SAMPLE_RATE * duration)

	# Pitch shifts up per line count — stays in pentatonic
	var base_freqs := [NOTE_E5, NOTE_G5, NOTE_A5, NOTE_C6]
	var idx := clampi(line_count - 1, 0, base_freqs.size() - 1)
	var base: float = base_freqs[idx]

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Main bell tone — soft attack, smooth decay
		var bell_env := _attack(t, 0.004) * _exp_decay(t, 6.0) * 0.30
		sample += _soft_bell(t, base) * bell_env

		# Sparkle layer — high detuned shimmer that sweeps up
		var sparkle_freq := lerpf(base * 2.0, base * 3.5, minf(t / 0.12, 1.0))
		var sparkle_env := _attack(t, 0.008) * _exp_decay(t, 9.0) * 0.10
		sample += sin(t * sparkle_freq * TAU) * sparkle_env
		sample += sin(t * sparkle_freq * 1.007 * TAU) * sparkle_env * 0.6  # chorus width

		# Extra shimmer on multi-line clears
		if line_count >= 3:
			var high_env := _attack(t, 0.01) * _exp_decay(t, 7.0) * 0.07
			sample += sin(t * base * 4.0 * TAU) * high_env

		# Gentle fade-out
		sample *= _fade_out(t, duration, 0.04)
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_color_match() -> AudioStreamWAV:
	## Warm harmonic bell — like a soft marimba hit with overtones.
	var samples := PackedByteArray()
	var duration := 0.15
	var total := int(SAMPLE_RATE * duration)
	var freq := NOTE_A5

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _attack(t, 0.003) * _exp_decay(t, 7.0) * 0.35
		# Marimba-like: fundamental strong, even harmonics present, odd weaker
		var sample := sin(t * freq * TAU) * 1.0
		sample += sin(t * freq * 2.0 * TAU) * 0.35
		sample += sin(t * freq * 3.0 * TAU) * 0.08
		sample += sin(t * freq * 4.0 * TAU) * 0.15
		# Slight detune for warmth
		sample += sin(t * freq * 1.003 * TAU) * 0.15
		sample *= env / 1.73  # normalise
		sample *= _fade_out(t, duration, 0.02)
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_combo_clear(combo_level: int) -> AudioStreamWAV:
	## Musical escalating combo sounds.
	## x2: two-note interval. x3: arpeggio. x4+: bright chord + sparkle.
	## All notes from pentatonic scale → always sounds good together.
	var samples := PackedByteArray()

	if combo_level <= 1:
		# Simple single bell (shouldn't normally play)
		var duration := 0.10
		var total := int(SAMPLE_RATE * duration)
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var env := _attack(t, 0.003) * _exp_decay(t, 12.0) * 0.30
			_write_sample(samples, _soft_bell(t, NOTE_C5) * env)

	elif combo_level == 2:
		# x2: Quick double note — C5 → E5 (major third, sweet)
		var duration := 0.15
		var total := int(SAMPLE_RATE * duration)
		var notes := [NOTE_C5, NOTE_E5]
		var gap := 0.055
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var sample := 0.0
			for n in notes.size():
				var nt := t - float(n) * gap
				if nt < 0.0:
					continue
				var env := _attack(nt, 0.003) * _exp_decay(nt, 14.0) * 0.32
				sample += _soft_bell(nt, notes[n]) * env
			_write_sample(samples, sample)

	elif combo_level == 3:
		# x3: Quick ascending arpeggio — C5 → E5 → G5
		var duration := 0.20
		var total := int(SAMPLE_RATE * duration)
		var notes := [NOTE_C5, NOTE_E5, NOTE_G5]
		var gap := 0.045
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var sample := 0.0
			for n in notes.size():
				var nt := t - float(n) * gap
				if nt < 0.0:
					continue
				var env := _attack(nt, 0.003) * _exp_decay(nt, 10.0) * 0.28
				sample += _soft_bell(nt, notes[n]) * env
			sample *= _fade_out(t, duration, 0.03)
			_write_sample(samples, sample)

	else:
		# x4+: Full chord + ascending sparkle sweep. Gets brighter per level.
		var duration := 0.25
		var total := int(SAMPLE_RATE * duration)
		var pitch_shift := 1.0 + float(clampi(combo_level - 4, 0, 6)) * 0.04
		var chord := [NOTE_C5 * pitch_shift, NOTE_E5 * pitch_shift, NOTE_G5 * pitch_shift]

		for i in total:
			var t := float(i) / SAMPLE_RATE
			var sample := 0.0

			# Simultaneous chord — soft bell tones
			var chord_env := _attack(t, 0.005) * _exp_decay(t, 4.5) * 0.22
			for freq in chord:
				sample += _soft_bell(t, freq) * chord_env

			# Rising sparkle sweep
			var sw_t := maxf(0.0, t - 0.02)
			if sw_t > 0.0:
				var sweep_freq := lerpf(chord[2] * 2.0, chord[2] * 4.0, minf(sw_t / 0.15, 1.0))
				var sw_env := _attack(sw_t, 0.008) * _exp_decay(sw_t, 7.0) * 0.09
				sample += sin(sw_t * sweep_freq * TAU) * sw_env
				sample += sin(sw_t * sweep_freq * 1.006 * TAU) * sw_env * 0.5

			sample *= _fade_out(t, duration, 0.04)
			_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_level_up() -> AudioStreamWAV:
	## Celebratory ascending scale — pentatonic run ending on a bright resolve.
	var samples := PackedByteArray()
	var duration := 0.45
	var total := int(SAMPLE_RATE * duration)
	var notes := [NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6, NOTE_E6]
	var note_spacing := 0.075

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		for n in notes.size():
			var nt := t - float(n) * note_spacing
			if nt < 0.0:
				continue
			var freq: float = notes[n]
			# Last note rings longer
			var decay_rate := 3.0 if n == notes.size() - 1 else 6.0
			var env := _attack(nt, 0.005) * _exp_decay(nt, decay_rate) * 0.28
			sample += _soft_bell(nt, freq) * env

		# Gentle pad underneath for warmth
		if t > 0.15:
			var pad_t := t - 0.15
			var pad_env := _attack(pad_t, 0.05) * _exp_decay(pad_t, 3.0) * 0.08
			sample += (sin(pad_t * NOTE_C5 * TAU) + sin(pad_t * NOTE_G5 * TAU)) * 0.5 * pad_env

		sample *= _fade_out(t, duration, 0.06)
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_game_over() -> AudioStreamWAV:
	## Gentle descending — not sad, more "aww, nice try". Warm, not depressing.
	## Descending minor pentatonic with soft bell tones.
	var samples := PackedByteArray()
	var duration := 0.50
	var total := int(SAMPLE_RATE * duration)
	# A4 → G4 → E4 → D4 (minor pentatonic descent, warm)
	var notes := [440.0, 392.0, 329.63, 293.66]
	var note_spacing := 0.10

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		for n in notes.size():
			var nt := t - float(n) * note_spacing
			if nt < 0.0:
				continue
			var freq: float = notes[n]
			var decay_rate := 3.5 if n == notes.size() - 1 else 5.0
			var env := _attack(nt, 0.008) * _exp_decay(nt, decay_rate) * 0.30
			# Warmer tone: stronger fundamental, gentle harmonics
			sample += sin(nt * freq * TAU) * env
			sample += sin(nt * freq * 2.0 * TAU) * env * 0.12
			# Slight chorus for emotional warmth
			sample += sin(nt * freq * 1.004 * TAU) * env * 0.10

		sample *= _fade_out(t, duration, 0.08)
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_perfect_clear() -> AudioStreamWAV:
	## Magical sparkle cascade — shimmering arpeggiated chord + high twinkle layer.
	var samples := PackedByteArray()
	var duration := 0.55
	var total := int(SAMPLE_RATE * duration)
	# Full bright arpeggio: C5 → E5 → G5 → C6 → E6 → G6
	var notes := [NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6, NOTE_E6, NOTE_G6]
	var gap := 0.055
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Arpeggio cascade
		for n in notes.size():
			var nt := t - float(n) * gap
			if nt < 0.0:
				continue
			var freq: float = notes[n]
			var env := _attack(nt, 0.004) * _exp_decay(nt, 3.5) * 0.20
			sample += _soft_bell(nt, freq) * env

		# Sparkle dust — random high pings (pre-seeded for consistency)
		if i % 800 == 0:
			rng.seed = 42 + i
		var sparkle_phase := t * (2500.0 + sin(t * 3.0) * 500.0)
		var sparkle_env := _attack(t, 0.05) * _exp_decay(maxf(0.0, t - 0.1), 3.0) * 0.06
		sample += sin(sparkle_phase * TAU) * sparkle_env

		# Sustained pad for fullness
		if t > 0.15:
			var pad_t := t - 0.15
			var pad_env := _attack(pad_t, 0.06) * _exp_decay(pad_t, 2.5) * 0.07
			var pad := (sin(pad_t * NOTE_C5 * TAU) + sin(pad_t * NOTE_E5 * TAU) + sin(pad_t * NOTE_G5 * TAU)) / 3.0
			sample += pad * pad_env

		sample *= _fade_out(t, duration, 0.08)
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_button_press() -> AudioStreamWAV:
	## Tiny soft UI click — like tapping glass gently. Barely there.
	var samples := PackedByteArray()
	var duration := 0.04
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		# Quick high ping + micro noise transient
		var env := _exp_decay(t, 45.0) * _attack(t, 0.001) * 0.12
		var sample := sin(t * 1800.0 * TAU) * env
		sample += sin(t * 2700.0 * TAU) * env * 0.3
		# Tiny body
		sample += sin(t * 600.0 * TAU) * _exp_decay(t, 50.0) * _attack(t, 0.001) * 0.05
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_place_fail() -> AudioStreamWAV:
	## Soft rejection thud — low, muffled, not harsh. "Nope" not "WRONG!"
	var samples := PackedByteArray()
	var duration := 0.08
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		# Muffled low thud
		var env := _smooth_bump(t, 0.002, 0.01, 0.06) * 0.20
		var sample := sin(t * 120.0 * TAU) * env
		# Subtle buzz — two close frequencies for slight wobble
		sample += sin(t * 145.0 * TAU) * env * 0.3
		# Dampen high freqs by keeping it purely low
		sample += sin(t * 80.0 * TAU) * env * 0.4
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_chain_sound(cascade_level: int) -> AudioStreamWAV:
	## Crystalline ascending chimes — each cascade level shifts the chord up.
	## Musical intervals from pentatonic scale. Sounds like wind chimes.
	var chord_table: Array = [
		[NOTE_C5, NOTE_E5, NOTE_G5],      # Level 1: C major
		[NOTE_E5, NOTE_G5, NOTE_C6],      # Level 2: 1st inversion, higher
		[NOTE_G5, NOTE_C6, NOTE_E6],      # Level 3: 2nd inversion, brighter
		[NOTE_C6, NOTE_E6, NOTE_G6],      # Level 4+: octave up
	]
	var idx := clampi(cascade_level - 1, 0, chord_table.size() - 1)
	var chord: Array = chord_table[idx]

	var samples := PackedByteArray()
	var duration := 0.25
	var total := int(SAMPLE_RATE * duration)
	var note_gap := 0.05

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Staggered chime notes
		for n in chord.size():
			var nt := t - float(n) * note_gap
			if nt < 0.0:
				continue
			var freq: float = chord[n]
			var env := _attack(nt, 0.003) * _exp_decay(nt, 6.0) * 0.28
			sample += _soft_bell(nt, freq) * env

		# Subtle echo/tail for depth
		for n in chord.size():
			var nt := t - float(n) * note_gap - 0.07
			if nt < 0.0:
				continue
			var freq: float = chord[n]
			var env := _attack(nt, 0.005) * _exp_decay(nt, 9.0) * 0.08
			sample += sin(nt * freq * TAU) * env

		# Higher cascades get a twinkle top
		if cascade_level >= 3:
			var top: float = chord[chord.size() - 1]
			var twinkle_env := _attack(t, 0.02) * _exp_decay(t, 8.0) * 0.05
			sample += sin(t * top * 2.0 * TAU) * twinkle_env

		sample *= _fade_out(t, duration, 0.04)
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_blast_sound() -> AudioStreamWAV:
	## Satisfying impact + sparkle tail. Deep but NOT harsh.
	## Think: bass drop + crystal shatter, but gentle.
	var samples := PackedByteArray()
	var duration := 0.35
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Layer 1: Soft sub impact — rounded sine, not noise
		var impact_freq := lerpf(180.0, 55.0, minf(t / 0.05, 1.0))
		var impact_env := _smooth_bump(t, 0.002, 0.008, 0.12) * 0.35
		sample += sin(t * impact_freq * TAU) * impact_env

		# Layer 2: Warm mid body
		var body_env := _attack(t, 0.004) * _exp_decay(t, 6.0) * 0.18
		sample += sin(t * 165.0 * TAU) * body_env
		sample += sin(t * 220.0 * TAU) * body_env * 0.4

		# Layer 3: Crystal sparkle cascade (delayed, rising)
		var sp_t := maxf(0.0, t - 0.04)
		if sp_t > 0.0:
			var sp_env := _attack(sp_t, 0.01) * _exp_decay(sp_t, 4.0) * 0.14
			var sp_freq := lerpf(NOTE_G5, NOTE_G6, minf(sp_t / 0.2, 1.0))
			sample += _soft_bell(sp_t, sp_freq) * sp_env

		# Layer 4: High shimmer tail
		var tail_t := maxf(0.0, t - 0.08)
		if tail_t > 0.0:
			var tail_env := _attack(tail_t, 0.02) * _exp_decay(tail_t, 3.5) * 0.08
			sample += sin(tail_t * NOTE_E6 * TAU) * tail_env
			sample += sin(tail_t * NOTE_E6 * 1.005 * TAU) * tail_env * 0.6  # chorus

		sample *= _fade_out(t, duration, 0.06)
		_write_sample(samples, sample)

	return _make_wav(samples)


# ── Private Helpers ──

## Exponential decay envelope: fast natural falloff
static func _exp_decay(t: float, rate: float) -> float:
	return exp(-t * rate)

## Soft attack ramp to prevent click artifacts
static func _attack(t: float, ramp_time: float) -> float:
	if t >= ramp_time:
		return 1.0
	return t / ramp_time

## Smooth bump envelope: attack → hold → decay (prevents clicks on both ends)
static func _smooth_bump(t: float, attack: float, peak: float, end: float) -> float:
	if t < 0.0 or t > end:
		return 0.0
	if t < attack:
		return t / attack
	if t < peak:
		return 1.0
	return maxf(0.0, 1.0 - (t - peak) / (end - peak))

## Fade-out ramp for the last `fade_time` seconds of a sound
static func _fade_out(t: float, duration: float, fade_time: float) -> float:
	var remaining := duration - t
	if remaining < fade_time:
		return maxf(0.0, remaining / fade_time)
	return 1.0

## Soft bell tone: fundamental + detuned copy + gentle harmonics.
## Rich but never harsh. The core timbre of the whole game.
static func _soft_bell(t: float, freq: float) -> float:
	var s := sin(t * freq * TAU)                       # fundamental
	s += sin(t * freq * 1.004 * TAU) * 0.25            # slight detune = warmth
	s += sin(t * freq * 2.0 * TAU) * 0.18              # octave harmonic
	s += sin(t * freq * 3.0 * TAU) * 0.05              # 2nd harmonic (gentle)
	s += sin(t * freq * 4.0 * TAU) * 0.08              # bell-like even harmonic
	return s / 1.56  # normalise to ~1.0

## Write a float sample (-1..1) as 16-bit PCM
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
