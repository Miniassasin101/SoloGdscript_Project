
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_toon,specular_toon;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_g,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform sampler2D color_gradient;
uniform sampler2D color_ramp3;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);

	vec2 base_uv = UV;

	// Sample the texture
	vec4 albedo_tex = texture(texture_albedo, base_uv);

	// Desaturate the albedo texture (luminance formula)
	float luminance = dot(albedo_tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated_albedo_tex = vec3(luminance);

	// Multiply the desaturated albedo with the main albedo
	ALBEDO = albedo.rgb * desaturated_albedo_tex + (basic_fresnel * texture(color_ramp3, vec2(basic_fresnel, 0.0)).rgb * 1.0);

	// Handle metallic and roughness from textures
	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;

	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0); // Roughness texture channel as green
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	SPECULAR = 0.0; // Specular is set to 0, can be adjusted if needed

	// Handle normal mapping
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}

void light() {
	// Lighting based on the toon shading
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(color_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += (shaded.rgb * LIGHT_COLOR) / 2.0;
}
