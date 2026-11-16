shader_type sky;
// Céu do Valdora PvP: gradiente saturado, halo dourado do sol e nuvens fofas de desenho
// animado (ruído barato projetado no domo). Estático: o Godot só recalcula o reflexo
// quando um parâmetro muda, então o custo no celular é só o pixel do fundo.

uniform vec4 topo : source_color = vec4(0.18, 0.52, 0.88, 1.0);
uniform vec4 horizonte : source_color = vec4(0.97, 0.89, 0.75, 1.0);
uniform vec4 chao : source_color = vec4(0.62, 0.56, 0.48, 1.0);
uniform vec4 cor_sol : source_color = vec4(1.0, 0.86, 0.6, 1.0);
uniform vec4 nuvem_luz : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform vec4 nuvem_sombra : source_color = vec4(0.72, 0.78, 0.9, 1.0);
uniform float nuvens = 0.5;      // 0 = céu limpo, 1 = carregado
uniform float semente = 0.0;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { return ruido(p) * 0.55 + ruido(p * 2.03) * 0.28 + ruido(p * 4.1) * 0.17; }

void sky() {
	vec3 d = normalize(EYEDIR);
	float y = d.y;
	// gradiente: horizonte quente e largo, topo azul saturado
	vec3 cor = mix(horizonte.rgb, topo.rgb, pow(smoothstep(0.0, 0.85, y), 0.62));
	cor = mix(cor, chao.rgb, smoothstep(0.0, -0.12, y));
	// sol: disco suave e halo amplo dourado
	if (LIGHT0_ENABLED) {
		float s = max(dot(d, LIGHT0_DIRECTION), 0.0);
		cor += cor_sol.rgb * (pow(s, 6.0) * 0.32 + pow(s, 60.0) * 0.5 + smoothstep(0.9993, 0.9997, s) * 2.0);
	}
	// nuvens: bolhas projetadas no domo, sombra na base e borda clara
	if (y > 0.0 && nuvens > 0.0) {
		vec2 uv = d.xz / (y + 0.18) * 1.6 + vec2(semente, semente * 0.37);
		float n = fbm(uv);
		float limiar = mix(0.78, 0.48, nuvens);
		float massa = smoothstep(limiar, limiar + 0.025, n);
		float dentro = smoothstep(limiar, limiar + 0.22, fbm(uv + vec2(0.0, 0.12)));
		vec3 nc = mix(nuvem_sombra.rgb, nuvem_luz.rgb, 0.35 + 0.65 * (1.0 - dentro * 0.7));
		float some = smoothstep(0.0, 0.12, y) * (1.0 - smoothstep(0.55, 0.95, y) * 0.6);
		cor = mix(cor, nc, massa * some);
	}
	COLOR = cor;
}
