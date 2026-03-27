class_name MissionSystem
## Mission Run system — generates random missions and tracks progress.

enum MissionType {
	CLEAR_LINES,
	REACH_COMBO,
	TRIGGER_CHAIN,
	TRIGGER_BLAST,
	SCORE_POINTS,
	PLACE_PIECES,
}

class Mission:
	var type: MissionType
	var target: int
	var progress: int = 0
	var xp_reward: int
	var description: String
	var completed: bool = false

	func update(value: int) -> bool:
		if completed:
			return false
		progress = mini(progress + value, target)
		if progress >= target:
			completed = true
			return true
		return false

	func set_if_higher(value: int) -> bool:
		if completed:
			return false
		progress = maxi(progress, mini(value, target))
		if progress >= target:
			completed = true
			return true
		return false


## Mission pool definitions: [type, target, xp_reward, description]
const EASY_POOL: Array = [
	[MissionType.CLEAR_LINES, 3, 35, "Clear 3 lines"],
	[MissionType.PLACE_PIECES, 8, 25, "Place 8 pieces"],
	[MissionType.SCORE_POINTS, 800, 30, "Score 800 pts"],
	[MissionType.TRIGGER_BLAST, 1, 40, "Trigger a blast"],
]

const MEDIUM_POOL: Array = [
	[MissionType.REACH_COMBO, 3, 65, "Reach combo x3"],
	[MissionType.CLEAR_LINES, 6, 55, "Clear 6 lines"],
	[MissionType.TRIGGER_CHAIN, 1, 75, "Trigger a chain"],
	[MissionType.PLACE_PIECES, 12, 50, "Place 12 pieces"],
]

const HARD_POOL: Array = [
	[MissionType.REACH_COMBO, 5, 110, "Reach combo x5"],
	[MissionType.TRIGGER_BLAST, 2, 140, "Trigger 2 blasts"],
	[MissionType.SCORE_POINTS, 3000, 90, "Score 3,000 pts"],
	[MissionType.CLEAR_LINES, 10, 120, "Clear 10 lines"],
]


static func generate_missions() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var missions: Array = []
	missions.append(_pick_from_pool(EASY_POOL, rng))
	missions.append(_pick_from_pool(MEDIUM_POOL, rng))
	missions.append(_pick_from_pool(HARD_POOL, rng))
	return missions


static func _pick_from_pool(pool: Array, rng: RandomNumberGenerator) -> Mission:
	var idx: int = rng.randi_range(0, pool.size() - 1)
	var def: Array = pool[idx]
	var m := Mission.new()
	m.type = int(def[0])
	m.target = int(def[1])
	m.xp_reward = int(def[2])
	m.description = str(def[3])
	return m


static func all_completed(missions: Array) -> bool:
	for m in missions:
		var mission: Mission = m
		if not mission.completed:
			return false
	return true


static func total_xp(missions: Array) -> int:
	var total: int = 0
	for m in missions:
		var mission: Mission = m
		if mission.completed:
			total += mission.xp_reward
	return total


## Update mission progress after a game event.
## event_type maps to MissionType enum values.
## For REACH_COMBO, use set_if_higher (combo is a high-water mark).
## For SCORE_POINTS, pass the running total score.
## For all others, pass the delta (lines cleared, pieces placed, etc.).
static func update_progress(missions: Array, event_type: MissionType, value: int) -> Array:
	var newly_completed: Array = []
	for m in missions:
		var mission: Mission = m
		if mission.type != event_type:
			continue
		var did_complete: bool = false
		match event_type:
			MissionType.REACH_COMBO:
				did_complete = mission.set_if_higher(value)
			MissionType.SCORE_POINTS:
				mission.progress = mini(value, mission.target)
				if mission.progress >= mission.target and not mission.completed:
					mission.completed = true
					did_complete = true
				elif mission.progress >= mission.target:
					did_complete = false
			_:
				did_complete = mission.update(value)
		if did_complete:
			newly_completed.append(mission)
	return newly_completed
