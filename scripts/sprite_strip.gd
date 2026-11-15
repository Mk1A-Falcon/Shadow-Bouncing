class_name SpriteStrip
extends RefCounted


static func frames_from_strip(path: String, frame_count: int, anim_name: String, fps: float, loop: bool) -> SpriteFrames:
	var sheet := SpriteFrames.new()
	add_strip(sheet, path, frame_count, anim_name, fps, loop)
	return sheet


static func add_strip(sheet: SpriteFrames, path: String, frame_count: int, anim_name: String, fps: float, loop: bool) -> void:
	var tex := load(path) as Texture2D
	if tex == null or frame_count < 1:
		push_warning("SpriteStrip: missing texture %s" % path)
		return
	var frame_w := int(tex.get_width() / float(frame_count))
	var frame_h := tex.get_height()
	if not sheet.has_animation(anim_name):
		sheet.add_animation(anim_name)
	sheet.set_animation_loop(anim_name, loop)
	sheet.set_animation_speed(anim_name, fps)
	sheet.clear(anim_name)
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.filter_clip = true
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sheet.add_frame(anim_name, atlas)


static func add_still(sheet: SpriteFrames, path: String, frame_count: int, frame_index: int, anim_name: String) -> void:
	var tex := load(path) as Texture2D
	if tex == null or frame_count < 1:
		push_warning("SpriteStrip: missing texture %s" % path)
		return
	var frame_w := int(tex.get_width() / float(frame_count))
	var frame_h := tex.get_height()
	if not sheet.has_animation(anim_name):
		sheet.add_animation(anim_name)
	sheet.set_animation_loop(anim_name, true)
	sheet.set_animation_speed(anim_name, 1.0)
	sheet.clear(anim_name)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.filter_clip = true
	atlas.region = Rect2(clampi(frame_index, 0, frame_count - 1) * frame_w, 0, frame_w, frame_h)
	sheet.add_frame(anim_name, atlas)
