shader_type spatial;
// Água estilizada: ondas suaves, brilho do sol e espuma leve (sem textura externa).
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

uniform vec4 cor_rasa : source_color = vec4(0.25, 0.75, 0.8, 1.0);
uniform vec4 cor_funda : source_color = vec4(0.05, 0.35, 0.5, 1.0);

varying vec3 p_mundo;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	p_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = p_mundo.xz * 0.35;
	float t = TIME * 0.35;
	float o = ruido(uv + vec2(t, t * 0.6)) * 0.6 + ruido(uv * 2.3 - vec2(t * 0.8, -t)) * 0.4;
	vec3 cor = mix(cor_funda.rgb, cor_rasa.rgb, smoothstep(0.25, 0.85, o));
	float brilho = smoothstep(0.82, 0.95, ruido(uv * 4.0 + vec2(t * 1.5, 0.0)));
	ALBEDO = cor + vec3(brilho * 0.35);
	ROUGHNESS = 0.08;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	NORMAL_MAP = normalize(vec3(o - 0.5, 1.0, ruido(uv * 1.7 + t) - 0.5) * 0.5 + 0.5);
}
