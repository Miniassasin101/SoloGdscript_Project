shader_type spatial;
render_mode unshaded, blend_add;

uniform vec4 line_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float glow_intensity = 1.0;

void fragment() {
	float glow = smoothstep(0.3, 0.7, sin(TIME * 3.0) * 0.5 + 0.5);
	ALBEDO = line_color.rgb;
	EMISSION = line_color.rgb * glow_intensity * glow;
}
