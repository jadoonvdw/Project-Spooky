shader_type spatial;
render_mode blend_mix,
	cull_disabled,
	shadows_disabled,
	vertex_lighting;
//psx shader variables
uniform float alpha_scissor : hint_range(0, 1) = 0.5;
uniform float jitter: hint_range(0, 1) = 0.25;
uniform bool affine_mapping = false;
uniform ivec2 resolution = ivec2(320, 240);
//Material Editing Options
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform vec3 albedo : source_color;
uniform vec3 albedo2 :source_color;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
//Wave Direction and Time
uniform sampler2D wave;
uniform vec2 wave_direction = vec2(2.0,0.0);
uniform vec2 wave_direction2 = vec2(0.0,1.0);
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
//Noise Textures
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
//Scalable Vertex Height
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;
//Varying Variables
varying float height;
varying vec3 world_position;
//color depth variables
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

vec4 snap_to_position(vec4 base_position)
{
	vec4 snapped_position = base_position;
	snapped_position.xyz = base_position.xyz / base_position.w;
	
	vec2 snap_resulotion = floor(vec2(resolution) * (1.0 - jitter));
	snapped_position.x = floor(snap_resulotion.x * snapped_position.x) / snap_resulotion.x;
	snapped_position.y = floor(snap_resulotion.y * snapped_position.y) / snap_resulotion.y;
	
	snapped_position.xyz *= base_position.w;
	return snapped_position;
}

void vertex()
{
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_position.xz / noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
	
	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (affine_mapping)
	{
		POSITION = snapped_position;
		POSITION /= abs(POSITION.w);
	}
	else
	{
		POSITION = snapped_position;
	}
}


void fragment() {
//Depth variables
float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r;
float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
vec3 depth_color = mix(color_deep.rgb, color_shallow.rgb, depth_blend_power);
vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);

//Wave animation 
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	
		//blend normal maps
	vec3 normal_blend = mix(texture(texture_normal,world_position.xz + time).rgb,texture(texture_normal2,world_position.xz + time2).rgb, 0.5);

	NORMAL_MAP = normal_blend;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	//albedo texture
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, fresnel);
		vec4 color_base = COLOR;
		ALBEDO = mix(surface_color, color, 0.75);
		ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
