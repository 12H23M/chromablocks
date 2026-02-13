extends Node

## Manages ad display logic (banner, interstitial, rewarded).
## Currently uses placeholder stubs — replace with AdMob GDExtension for production.

signal rewarded_ad_completed(type: String)
signal interstitial_closed()

const INTERSTITIAL_GAME_INTERVAL := 3
const INTERSTITIAL_COOLDOWN_SEC := 300.0  # 5 minutes

var _games_since_interstitial := 0
var _last_interstitial_time := 0.0


# --- Ad-free IAP ---

func is_ad_free() -> bool:
	return SaveManager.get_value("iap", "ad_free", false)


func purchase_ad_free() -> void:
	# TODO: Replace with actual IAP flow via platform plugin
	SaveManager.set_value("iap", "ad_free", true)
	SaveManager.flush()
	hide_banner()


# --- Banner ---

func show_banner() -> void:
	if is_ad_free():
		return
	# TODO: Call AdMob banner show
	# GodotAdMob.banner.show()


func hide_banner() -> void:
	# TODO: Call AdMob banner hide
	# GodotAdMob.banner.hide()
	pass


# --- Interstitial ---

func on_game_ended() -> void:
	_games_since_interstitial += 1


func should_show_interstitial() -> bool:
	if is_ad_free():
		return false
	if _games_since_interstitial < INTERSTITIAL_GAME_INTERVAL:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_interstitial_time < INTERSTITIAL_COOLDOWN_SEC:
		return false
	return true


func show_interstitial() -> void:
	if not should_show_interstitial():
		interstitial_closed.emit()
		return
	_games_since_interstitial = 0
	_last_interstitial_time = Time.get_ticks_msec() / 1000.0
	# TODO: Replace with actual AdMob interstitial
	# GodotAdMob.interstitial.show()
	# For now, simulate immediate close
	interstitial_closed.emit()


# --- Rewarded ---

func show_rewarded(reward_type: String) -> void:
	if is_ad_free():
		# Ad-free users get rewards for free
		rewarded_ad_completed.emit(reward_type)
		return
	# TODO: Replace with actual AdMob rewarded ad
	# GodotAdMob.rewarded.show()
	# For now, simulate immediate reward
	rewarded_ad_completed.emit(reward_type)


func is_rewarded_available() -> bool:
	# TODO: Check if a rewarded ad is loaded
	return true
