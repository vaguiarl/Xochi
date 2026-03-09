shader_type canvas_item;

uniform float alpha_cutoff : hint_range(0.0, 0.4) = 0.12;
uniform float feather : hint_range(0.001, 0.25) = 0.08;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha = smoothstep(alpha_cutoff, alpha_cutoff + feather, tex.a);
	if (alpha <= 0.001) {
		discard;
	}
	COLOR = vec4(tex.rgb, alpha);
}
