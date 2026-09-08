extends AnimatableBody2D
var width := 200.0
var boat := false
var anchor := Vector2.ZERO
var amplitude := Vector2.ZERO
var time := 0.0
var tint := Color("247b83")
var quay_texture: Texture2D
var boat_texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists("res://assets/garden-quay.png"):
		quay_texture = load("res://assets/garden-quay.png")
	if ResourceLoader.exists("res://assets/trajinera.png"):
		boat_texture = load("res://assets/trajinera.png")

func configure(rect: Rect2, is_boat: bool, motion: Vector2 = Vector2.ZERO) -> void:
	position = rect.position
	anchor = position
	width = rect.size.x
	boat = is_boat
	amplitude = motion
	collision_layer = 1
	collision_mask = 0
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, 18)
	collider.shape = shape
	collider.position = Vector2(width / 2, 9)
	add_child(collider)
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	time += delta
	position = anchor + amplitude * sin(time * 1.25)
	queue_redraw()

func reset_state() -> void:
	time = 0.0
	position = anchor
	reset_physics_interpolation()

func _draw() -> void:
	if boat:
		if boat_texture:
			draw_texture_rect_region(boat_texture,Rect2(-10,-19,width+20,55),Rect2(0,180,boat_texture.get_width(),335))
			draw_line(Vector2(0,0),Vector2(width,0),Color("f3d49f"),3)
			return
		# A sharp golden deck is the collision surface. Decoration stays below it.
		draw_colored_polygon(PackedVector2Array([Vector2(-14,5), Vector2(width+14,5), Vector2(width-15,54), Vector2(22,54)]), Color("103d4d"))
		draw_colored_polygon(PackedVector2Array([Vector2(-6,9), Vector2(width+6,9), Vector2(width-17,43), Vector2(23,43)]), tint)
		for x in range(26, int(width)-16, 25):
			draw_line(Vector2(x,12),Vector2(x+5,42),Color("194e5b"),2)
		for x in range(36, int(width)-15, 54):
			flower(Vector2(x,27), 7, Color("e9989e"))
		draw_line(Vector2(0,3),Vector2(width,3),Color("ebc378"),7)
		draw_line(Vector2(10,50),Vector2(width-10,50),Color("67b9aa"),2)
	else:
		if quay_texture:
			var start := 0.0
			while start < width:
				var span = minf(650,width-start)
				draw_texture_rect_region(quay_texture,Rect2(start,-2,span,190),Rect2(0,84,quay_texture.get_width()*span/650,quay_texture.get_height()-84))
				start += span
			draw_line(Vector2(0,0),Vector2(width,0),Color("f3d49f"),3)
			return
		draw_rect(Rect2(0,5,width,160),Color("33433f"))
		draw_rect(Rect2(0,7,width,28),Color("59695a"))
		for y in range(38,165,28):
			for x in range(-30 if y % 2 == 0 else 0, int(width), 64):
				draw_style_box(stone_style(),Rect2(maxf(x,0),y,minf(59,width-maxf(x,0)),23))
		draw_rect(Rect2(-3,0,width+6,8),Color("dfc28d"))
		draw_line(Vector2(0,0),Vector2(width,0),Color("fff0c7"),2)
		for x in range(20,int(width),65):
			draw_line(Vector2(x,30),Vector2(x+8,63+sin(x)*12),Color("315f48"),4)
			flower(Vector2(x+8,40),5,Color("de9a62"))

func stone_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color("48564a")
	s.corner_radius_top_left = 4
	s.corner_radius_bottom_right = 5
	return s

func flower(p: Vector2, r: float, color: Color) -> void:
	for i in 5:
		draw_circle(p + Vector2.from_angle(i * TAU/5) * r*.55, r*.52, color)
	draw_circle(p,r*.25,Color("ffdc83"))
