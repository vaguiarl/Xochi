extends Node2D
var scroll := 0.0
var time := 0.0
var completed := false
var texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://assets/canal-dawn.png"):
		texture = load("res://assets/canal-dawn.png")

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var size = get_viewport_rect().size
	if texture:
		var h = maxf(size.y,720)
		var w = maxf(h * texture.get_width()/texture.get_height(), size.x+750)
		draw_texture_rect(texture,Rect2(-scroll*.16,0,w,h),false)
	else:
		draw_rect(Rect2(Vector2.ZERO,size),Color("668e83"))
	# The water remains alive through every retry; layered glints are inexpensive.
	for i in 48:
		var x = fposmod(i*147.3 + sin(time*.15+i)*24-scroll*.28,size.x+120)-60
		var y = 555 + fposmod(i*39.7,160)
		var alpha = .10 + .08*sin(time*1.8+i)
		draw_line(Vector2(x,y),Vector2(x+18+i%5*8,y),Color(0.8,1,.87,alpha),1.4)
	for i in 25:
		var x = fposmod(i*97.8 + time*(8+i%4)-scroll*.35,size.x+80)-40
		var y = fposmod(i*71.4+sin(time*.3+i)*20,520)
		draw_circle(Vector2(x,y),1.4+(i%3)*.6,Color(1,.89,.64,.28+.12*sin(time+i)))
	# Foreground foliage at the edges, kept below the playable silhouette.
	for side in [0,1]:
		var base = Vector2(0 if side==0 else size.x,size.y+30)
		for i in 8:
			var tip = base + Vector2((1 if side==0 else -1)*(20+i*13),-20-i*12)
			var sway = sin(time*.8+i)*5
			draw_line(base,tip+Vector2(sway,0),Color("164942"),5)
			draw_colored_polygon(PackedVector2Array([tip+Vector2(sway,0),tip+Vector2(25*(1 if side==0 else -1),20),base]),Color("1f5a4b"))
