class_name SFXGenerator

const SAMPLE_RATE := 44100
const MAX_16BIT := 32767.0

# ── Public generators ──

static func generate_block_place() -> AudioStreamWAV:
	# Soft thud: low sine with quick exponential decay + subtle click
	var samples := PackedByteArray()
	var duration := 0.1
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _exp_decay(t, 12.0) * _attack(t, 0.004) * 0.28
		var sample := sin(t * 180.0 * TAU) * env
		# Subtle click transient at the start
		sample += sin(t * 400.0 * TAU) * _exp_decay(t, 40.0) * _attack(t, 0.002) * 0.10
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_line_clear(line_count: int = 1) -> AudioStreamWAV:
	# Swoosh (noise sweep high→low) + ding (pure tone) — pitch shifts up per line
	var samples := PackedByteArray()
	var duration := 0.30
	var total := int(SAMPLE_RATE * duration)
	var rng := RandomNumberGenerator.new()
	rng.seed = 123 + line_count

	# Pitch multiplier: shift up per additional line
	var pitch_mult := 1.0 + float(line_count - 1) * 0.12
	var ding_freq := 800.0 * pitch_mult

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Layer 1: Swoosh — filtered noise sweep high→low (0.15s)
		if t < 0.15:
			var swoosh_ratio := t / 0.15
			# Sweep frequency for noise filter center
			var sweep_center := lerpf(4000.0, 400.0, swoosh_ratio) * pitch_mult
			var swoosh_env := _attack(t, 0.005) * (1.0 - swoosh_ratio) * 0.28
			# Shaped noise with sine approximation of bandpass
			var noise := rng.randf_range(-1.0, 1.0)
			sample += noise * swoosh_env * sin(t * sweep_center * TAU) * 0.5
			# Add a sine sweep for tonal whoosh
			sample += sin(t * sweep_center * TAU) * swoosh_env * 0.5

		# Layer 2: Ding — pure tone at 800Hz * pitch_mult (starts at 0.08s, 0.15s duration)
		var ding_t := t - 0.08
		if ding_t > 0.0:
			var ding_env := _exp_decay(ding_t, 6.0) * _attack(ding_t, 0.005) * 0.38
			sample += sin(ding_t * ding_freq * TAU) * ding_env
			# Bell harmonic
			sample += sin(ding_t * ding_freq * 2.0 * TAU) * ding_env * 0.15
			sample += sin(ding_t * ding_freq * 3.0 * TAU) * ding_env * 0.04

		# Layer 3: Impact transient (first 15ms)
		var impact_env := _exp_decay(t, 60.0) * _attack(t, 0.001) * 0.20
		sample += sin(t * 1200.0 * pitch_mult * TAU) * impact_env

		# Layer 4: Sub-bass thump
		sample += sin(t * 90.0 * TAU) * _exp_decay(t, 6.0) * _attack(t, 0.004) * 0.15

		# Fade out
		var remaining := duration - t
		if remaining < 0.04:
			sample *= remaining / 0.04

		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_color_match() -> AudioStreamWAV:
	# Warm bell-like tone with harmonics
	var samples := PackedByteArray()
	var duration := 0.2
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _exp_decay(t, 6.0) * _attack(t, 0.005) * 0.40
		var sample := sin(t * 784.0 * TAU) * env
		sample += sin(t * 784.0 * 2.0 * TAU) * env * 0.2
		sample += sin(t * 784.0 * 3.0 * TAU) * env * 0.05
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_combo_clear(combo_level: int) -> AudioStreamWAV:
	var samples := PackedByteArray()

	if combo_level <= 1:
		# x1: not really a combo, simple tone (shouldn't normally play)
		var duration := 0.12
		var total := int(SAMPLE_RATE * duration)
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var env := _exp_decay(t, 10.0) * _attack(t, 0.004) * 0.40
			var sample := sin(t * 440.0 * TAU) * env
			_write_sample(samples, sample)

	elif combo_level == 2:
		# x2: Quick double-tap — two short tones 0.05s apart
		var duration := 0.15
		var total := int(SAMPLE_RATE * duration)
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var sample := 0.0
			# First tap
			var env1 := _exp_decay(t, 20.0) * _attack(t, 0.003) * 0.45
			sample += sin(t * 523.0 * TAU) * env1
			# Second tap (0.05s later, slightly higher)
			var t2 := t - 0.05
			if t2 > 0.0:
				var env2 := _exp_decay(t2, 20.0) * _attack(t2, 0.003) * 0.45
				sample += sin(t2 * 587.0 * TAU) * env2
			_write_sample(samples, sample)

	elif combo_level == 3:
		# x3: Triple ascending arpeggio (C-E-G quick)
		var duration := 0.20
		var total := int(SAMPLE_RATE * duration)
		var notes := [523.0, 659.0, 784.0]  # C5-E5-G5
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var sample := 0.0
			for n in notes.size():
				var note_t := t - float(n) * 0.04
				if note_t < 0.0:
					continue
				var freq: float = notes[n]
				var env := _exp_decay(note_t, 14.0) * _attack(note_t, 0.003) * 0.40
				sample += sin(note_t * freq * TAU) * env
				sample += sin(note_t * freq * 2.0 * TAU) * env * 0.15
			_write_sample(samples, sample)

	else:
		# x4+: Chord + shimmer (simultaneous tones + high sweep)
		var duration := 0.25
		var total := int(SAMPLE_RATE * duration)
		# Shift chord up per combo level
		var pitch_shift := 1.0 + float(combo_level - 4) * 0.05
		var chord := [523.0 * pitch_shift, 659.0 * pitch_shift, 784.0 * pitch_shift]
		var rng := RandomNumberGenerator.new()
		rng.seed = combo_level * 31
		for i in total:
			var t := float(i) / SAMPLE_RATE
			var sample := 0.0
			# Simultaneous chord
			var env := _exp_decay(t, 5.0) * _attack(t, 0.005) * 0.30
			for freq in chord:
				sample += sin(t * freq * TAU) * env
			# High shimmer sweep (3000→5000Hz)
			var shimmer_t := maxf(0.0, t - 0.03)
			if shimmer_t > 0.0:
				var sweep_freq := lerpf(3000.0, 5000.0, shimmer_t / 0.2)
				var shimmer_env := _exp_decay(shimmer_t, 8.0) * _attack(shimmer_t, 0.008) * 0.12
				sample += sin(shimmer_t * sweep_freq * TAU) * shimmer_env
			# Sparkle noise
			if t < 0.1:
				sample += rng.randf_range(-1.0, 1.0) * _exp_decay(t, 18.0) * 0.06
			_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_level_up() -> AudioStreamWAV:
	# Warm rising progression with gentle sustain
	var samples := PackedByteArray()
	var duration := 0.5
	var total := int(SAMPLE_RATE * duration)
	var freqs := [523.0, 659.0, 784.0, 1047.0]
	var note_len := 0.12

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		for n in freqs.size():
			var note_start: float = n * note_len * 0.85
			var note_t := t - note_start
			if note_t < 0.0:
				continue
			var env := _exp_decay(note_t, 4.0) * _attack(note_t, 0.008) * 0.45
			sample += sin(note_t * freqs[n] * TAU) * env
			sample += sin(note_t * freqs[n] * 2.0 * TAU) * env * 0.10

		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_game_over() -> AudioStreamWAV:
	# Gentle descending sweep with soft fade
	var samples := PackedByteArray()
	var duration := 0.6
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var ratio := t / duration
		# Smooth frequency curve (exponential descent)
		var freq := lerpf(400.0, 180.0, ratio * ratio)
		var env := _exp_decay(t, 2.5) * _attack(t, 0.01) * 0.35
		var sample := sin(t * freq * TAU) * env
		# Add subtle sub bass
		sample += sin(t * freq * 0.5 * TAU) * env * 0.2
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_perfect_clear() -> AudioStreamWAV:
	# Shimmering chord resolving to a bright note
	var samples := PackedByteArray()
	var duration := 0.6
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _exp_decay(t, 2.5) * _attack(t, 0.008) * 0.45
		# Major chord (C5-E5-G5)
		var chord := sin(t * 523.0 * TAU) + sin(t * 659.0 * TAU) + sin(t * 784.0 * TAU)
		chord /= 3.0
		var chord_env := env * maxf(0.0, 1.0 - t * 2.5)

		# High resolve note fades in
		var high_t := maxf(0.0, t - 0.2)
		var high_env := _exp_decay(high_t, 3.0) * _attack(high_t, 0.01) * 0.40
		var high := sin(high_t * 1047.0 * TAU) * high_env
		high += sin(high_t * 1047.0 * 2.0 * TAU) * high_env * 0.1

		var sample := chord * chord_env + high
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_button_press() -> AudioStreamWAV:
	# Tiny soft click
	var samples := PackedByteArray()
	var duration := 0.05
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _exp_decay(t, 30.0) * _attack(t, 0.002) * 0.15
		var sample := sin(t * 600.0 * TAU) * env
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_place_fail() -> AudioStreamWAV:
	# Dissonant buzz: 150Hz + 160Hz (minor 2nd) with fast decay
	var samples := PackedByteArray()
	var duration := 0.1
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _exp_decay(t, 15.0) * _attack(t, 0.003) * 0.2
		var sample := sin(t * 150.0 * TAU) * env
		# Dissonant second tone (minor 2nd interval)
		sample += sin(t * 160.0 * TAU) * env * 0.8
		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_chain_sound(cascade_level: int) -> AudioStreamWAV:
	# Rising arpeggio — major chord notes shift up per cascade level
	# Cascade 1: C-E-G, Cascade 2: D-F#-A, Cascade 3+: E-G#-B
	var chord_table: Array = [
		[523.0, 659.0, 784.0],    # C5-E5-G5
		[587.0, 740.0, 880.0],    # D5-F#5-A5
		[659.0, 831.0, 988.0],    # E5-G#5-B5
	]
	var idx := clampi(cascade_level - 1, 0, chord_table.size() - 1)
	var chord: Array = chord_table[idx]

	var samples := PackedByteArray()
	var duration := 0.3
	var total := int(SAMPLE_RATE * duration)
	var note_gap := 0.06  # Time between arpeggio notes

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Play each note in the arpeggio with staggered starts
		for n in chord.size():
			var note_start: float = float(n) * note_gap
			var note_t := t - note_start
			if note_t < 0.0:
				continue
			var freq: float = chord[n]
			var env := _exp_decay(note_t, 5.0) * _attack(note_t, 0.004) * 0.35
			# Main tone + bell harmonics
			sample += sin(note_t * freq * TAU) * env
			sample += sin(note_t * freq * 2.0 * TAU) * env * 0.20
			sample += sin(note_t * freq * 3.0 * TAU) * env * 0.06
			# Detuned shimmer for width
			sample += sin(note_t * (freq * 1.005) * TAU) * env * 0.12

		# Echo/reverb layer: delayed, quieter copy of the signal
		var echo_delay := 0.08
		var echo_t := t - echo_delay
		if echo_t > 0.0:
			for n in chord.size():
				var note_start: float = float(n) * note_gap
				var note_t := echo_t - note_start
				if note_t < 0.0:
					continue
				var freq: float = chord[n]
				var env := _exp_decay(note_t, 7.0) * _attack(note_t, 0.004) * 0.12
				sample += sin(note_t * freq * TAU) * env

		# Sparkle on higher cascades
		if cascade_level >= 2:
			var top_freq: float = chord[chord.size() - 1]
			sample += sin(t * top_freq * 4.0 * TAU) * _exp_decay(t, 12.0) * _attack(t, 0.005) * 0.05

		_write_sample(samples, sample)

	return _make_wav(samples)


static func generate_blast_sound() -> AudioStreamWAV:
	# Punchy blast: white noise impact + low boom + high shimmer sweep
	var samples := PackedByteArray()
	var duration := 0.45
	var total := int(SAMPLE_RATE * duration)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0

		# Layer 1: White noise burst (first 0.05s) — impact hit
		if t < 0.05:
			var noise_env := _exp_decay(t, 40.0) * _attack(t, 0.001) * 0.40
			sample += rng.randf_range(-1.0, 1.0) * noise_env

		# Layer 2: Low frequency boom (60Hz, 0.2s decay)
		var boom_env := _exp_decay(t, 5.0) * _attack(t, 0.003) * 0.38
		sample += sin(t * 60.0 * TAU) * boom_env
		# Sub-harmonic for weight
		sample += sin(t * 30.0 * TAU) * boom_env * 0.3

		# Layer 3: Impact transient (first 30ms)
		var impact_env := _exp_decay(t, 55.0) * _attack(t, 0.001) * 0.28
		sample += sin(t * 200.0 * TAU) * impact_env
		sample += sin(t * 350.0 * TAU) * impact_env * 0.4

		# Layer 4: Shimmer sweep (2000→4000Hz, 0.3s, starts at 0.05s)
		var shimmer_t := maxf(0.0, t - 0.05)
		if shimmer_t > 0.0 and shimmer_t < 0.35:
			var shimmer_ratio := shimmer_t / 0.35
			var shimmer_freq := lerpf(2000.0, 4000.0, shimmer_ratio)
			var shimmer_env := _exp_decay(shimmer_t, 4.5) * _attack(shimmer_t, 0.01) * 0.18
			sample += sin(shimmer_t * shimmer_freq * TAU) * shimmer_env
			# Detuned copy for stereo-like width
			sample += sin(shimmer_t * (shimmer_freq * 1.01) * TAU) * shimmer_env * 0.5

		# Layer 5: Crystal sparkle (delayed)
		var sparkle_t := maxf(0.0, t - 0.08)
		var sparkle_env := _exp_decay(sparkle_t, 7.0) * _attack(sparkle_t, 0.01) * 0.12
		sample += sin(sparkle_t * 1047.0 * TAU) * sparkle_env
		sample += sin(sparkle_t * 1568.0 * TAU) * sparkle_env * 0.4

		# Fade out
		var remaining := duration - t
		if remaining < 0.06:
			sample *= remaining / 0.06

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
