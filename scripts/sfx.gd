extends Node

# Pooled one-shot sound effects from the 8-Bit Arcade SFX Vol.2 pack
# (assets/8-Bit-Arcade-SFX-Vol2-Platformer-Essentials). Each entry is a
# group of interchangeable takes; a random take is played each time and the
# same take never repeats back to back.

const ROOT := "res://assets/8-Bit-Arcade-SFX-Vol2-Platformer-Essentials/ogg/"

# sound name -> [folder, number of takes]
const SOUNDS := {
	"plat_jump_heavy": ["01_jump", 5],
	"plat_land_heavy": ["02_land", 4],
	"plat_land_hard": ["02_land", 4],
	"plat_land_soft": ["02_land", 4],
	"plat_dash_start": ["04_dash", 3],
	"plat_stomp": ["08_stomp", 5],
	"plat_enemy_pop": ["08_stomp", 3],
}

const DEFAULT_VOLUME_DB := -6.0
const POOL_SIZE := 8

var _cache := {}
var _last := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)


func play(sound: String, volume_db := DEFAULT_VOLUME_DB, pitch_jitter := 0.05) -> void:
	if not SOUNDS.has(sound):
		push_warning("Sfx: unknown sound '%s'" % sound)
		return
	var folder: String = SOUNDS[sound][0]
	var count: int = SOUNDS[sound][1]
	var take := randi() % count
	# Avoid playing the exact same take twice in a row.
	if count > 1 and int(_last.get(sound, -1)) == take:
		take = (take + 1 + randi() % (count - 1)) % count
	_last[sound] = take
	var path := "%s%s/%s_%02d.ogg" % [ROOT, folder, sound, take + 1]
	var stream := _get_stream(path)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func _get_stream(path: String) -> AudioStream:
	if not _cache.has(path):
		var res := load(path)
		if res == null:
			push_warning("Sfx: could not load '%s'" % path)
			return null
		_cache[path] = res
	return _cache[path]
