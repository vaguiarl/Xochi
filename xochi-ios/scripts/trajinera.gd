extends AnimatableBody2D
## Stable identity, dwell/travel timing and a single visible, one-way deck.
var boat_id := "lupita"
var display_name := "La Lupita"
var width := 220.0
var start := Vector2.ZERO
var end := Vector2.ZERO
var clock := 0.0
var frozen := false
var departing := false
var passenger: Node2D
var texture: Texture2D
var accent := Color("f6d36c")
var canopy_alpha := 1.0

func configure(id: String, title: String, a: Vector2, b: Vector2, art: int, color: Color) -> void:
	boat_id = id
	display_name = title
	start = a
	end = b
	position = a
	accent = color
	texture = load("res://assets/companion/trajinera_%d.png" % art)
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width,18)
	collision.shape = shape
	collision.position.y = 9
	collision.one_way_collision = true
	add_child(collision)

func at_time(t: float) -> Vector2:
	var phase := fposmod(t,8.0)
	if phase < 2: return start
	if phase < 4: return start.lerp(end,(phase-2)/2)
	if phase < 6: return end
	return end.lerp(start,(phase-6)/2)

func reset_state() -> void:
	clock = 0
	position = start
	departing = false
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	if not frozen:
		if departing: position.x += delta*85
		else:
			clock += delta
			position = at_time(clock)
	var occluded := is_instance_valid(passenger) and absf(passenger.global_position.x-global_position.x)<width*.5 and absf(passenger.global_position.y-global_position.y)<180
	canopy_alpha = move_toward(canopy_alpha,0.4 if occluded else 1.0,delta*3)
	queue_redraw()

func _draw() -> void:
	# Full original illustration; faded canopy stays decorative, never collidable.
	if texture:
		var height := (width+35)*texture.get_height()/texture.get_width()
		draw_texture_rect(texture,Rect2(-width/2-17,-height*.80,width+35,height),false,Color(1,1,1,canopy_alpha))
	draw_line(Vector2(-width/2,0),Vector2(width/2,0),accent,5,true)
	var font := ThemeDB.fallback_font
	var label_width := font.get_string_size(display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
	draw_style_box(_plaque(),Rect2(-label_width/2-10,-151,label_width+20,34))
	draw_string(font,Vector2(-label_width/2,-126),display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,22,accent)
	for i in 7:
		var p := Vector2(-width*.42+i*width*.14,15)
		draw_circle(p,5,accent)
		draw_circle(p,2,Color("fff4d8"))

func _plaque() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("123f48")
	s.set_corner_radius_all(8)
	return s
