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


static func generate_line_clear() -> AudioStreamWAV:
	# Punchy ascending sweep: impact transient + sub-bass + whoosh noise
	var samples := PackedByteArray()
	var duration := 0.3
	var total := int(SAMPLE_RATE * duration)
	var fade_out_time := 0.06
	var rng := RandomNumberGenerator.new()
	rng.seed = 123  # Deterministic noise

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var ratio := t / duration

		# Smooth ascending frequency sweep (C5 → G5)
		var freq := lerpf(523.0, 784.0, ratio * ratio)

		# Envelope: soft attack, gentle sustain, smooth fade
		var env := _attack(t, 0.01) * _exp_decay(t, 2.5) * 0.38

		# Initial impact transient (first 20ms)
		var impact := sin(t * 1200.0 * TAU) * _exp_decay(t, 60.0) * _attack(t, 0.001) * 0.22

		# Main tone + soft harmonics for warmth
		var sample := sin(t * freq * TAU) * env
		sample += sin(t * freq * 2.0 * TAU) * env * 0.10
		sample += sin(t * freq * 0.5 * TAU) * env * 0.08

		# Sub-bass layer (90Hz)
		sample += sin(t * 90.0 * TAU) * _exp_decay(t, 6.0) * _attack(t, 0.005) * 0.18

		# Whoosh noise layer
		var whoosh := rng.randf_range(-1.0, 1.0) * _exp_decay(t, 5.0) * _attack(t, 0.01) * 0.10

		sample += impact + whoosh

		# Subtle shimmer (amplitude modulation)
		sample *= 1.0 + sin(t * 12.0 * TAU) * 0.06

		# Smooth fade-out
		var remaining := duration - t
		if remaining < fade_out_time:
			sample *= remaining / fade_out_time

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
	# Pitched combo tone: higher combo → higher frequency
	var freq_table := [440.0, 523.0, 587.0, 659.0, 784.0, 880.0, 988.0]
	var idx := clampi(combo_level - 1, 0, freq_table.size() - 1)
	var base_freq: float = freq_table[idx]

	var samples := PackedByteArray()
	var duration := 0.15
	var total := int(SAMPLE_RATE * duration)

	for i in total:
		var t := float(i) / SAMPLE_RATE
		var env := _exp_decay(t, 8.0) * _attack(t, 0.005) * 0.55
		var sample := sin(t * base_freq * TAU) * env
		# Soft harmonic for brightness
		sample += sin(t * base_freq * 2.0 * TAU) * env * 0.12
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
