shader_type spatial;
// Superfícies procedurais do Valdora PvP (sem textura externa): o padrão é calculado no mundo
// (projeção nas três direções), então não precisa de UV e combina entre peças vizinhas.
// tipo: 0 paralelepípedo · 1 tijolo · 2 reboco · 3 concreto · 4 madeira · 5 metal ondulado
//       6 grama · 7 azulejo · 8 asfalto · 9 pedra portuguesa (ondas) · 10 terra · 11 telha
render_mode diffuse_burley, specular_schlick_ggx;

uniform int tipo = 2;
uniform vec4 cor_a : source_color = vec4(0.85, 0.8, 0.7, 1.0);
uniform vec4 cor_b : source_color = vec4(0.6, 0.55, 0.48, 1.0);
uniform float escala = 1.0;
uniform float sujeira = 0.35;     // escurece perto do chão e em manchas
uniform float rugosidade = 0.85;
uniform float metal = 0.0;

varying vec3 p_mundo;
varying vec3 n_mundo;

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { return ruido(p) * 0.5 + ruido(p * 2.1) * 0.3 + ruido(p * 4.3) * 0.2; }

// distância à borda da célula de Voronoi (pedras irregulares) e id da pedra
vec2 voronoi(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0; float id = 0.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 g = vec2(float(x), float(y));
		vec2 o = h22(i + g) * 0.8 + 0.1;
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; id = h21(i + g); } else if (d < d2) { d2 = d; }
	}
	return vec2(d2 - d1, id);
}

void vertex() {
	p_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	n_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// padrão num plano 2D; devolve (mistura entre cor_a e cor_b, sulco 0..1)
vec2 padrao(vec2 uv, float y_mundo) {
	if (tipo == 0) { // paralelepípedo: blocos irregulares
		vec2 q = uv * vec2(3.2, 4.2);
		float lin = floor(q.y);
		q.x += lin * 0.5;
		vec2 c = fract(q);
		float borda = min(min(c.x, 1.0 - c.x) * 1.3, min(c.y, 1.0 - c.y));
		float id = h21(floor(q));
		return vec2(id * 0.7 + fbm(uv * 6.0) * 0.3, smoothstep(0.03, 0.09, borda));
	} else if (tipo == 9) { // pedra portuguesa: pedrinhas com ondas pretas e brancas
		vec2 v = voronoi(uv * 9.0);
		float onda = step(0.5, fract(uv.x * 0.25 + sin(uv.y * 0.9) * 0.35));
		return vec2(onda, smoothstep(0.02, 0.1, v.x));
	} else if (tipo == 1) { // tijolo
		vec2 q = uv * vec2(4.0, 8.0);
		q.x += step(1.0, mod(floor(q.y), 2.0)) * 0.5;
		vec2 c = fract(q);
		float junta = min(min(c.x, 1.0 - c.x) * 2.0, min(c.y, 1.0 - c.y));
		return vec2(h21(floor(q)) * 0.8 + fbm(uv * 8.0) * 0.2, smoothstep(0.04, 0.1, junta));
	} else if (tipo == 3) { // concreto em placas
		vec2 c = fract(uv * 0.5);
		float junta = min(min(c.x, 1.0 - c.x), min(c.y, 1.0 - c.y));
		return vec2(fbm(uv * 3.0), smoothstep(0.004, 0.012, junta));
	} else if (tipo == 4) { // madeira em tábuas
		vec2 q = uv * vec2(1.0, 5.0);
		float tab = floor(q.y);
		float veio = sin((uv.x + h21(vec2(tab, 1.0)) * 7.0) * 9.0 + fbm(uv * vec2(1.0, 12.0)) * 6.0) * 0.5 + 0.5;
		float junta = min(fract(q.y), 1.0 - fract(q.y));
		return vec2(veio * 0.5 + h21(vec2(tab, 3.0)) * 0.5, smoothstep(0.03, 0.08, junta));
	} else if (tipo == 5) { // metal ondulado
		float o = sin(uv.x * 18.0) * 0.5 + 0.5;
		return vec2(o, 1.0);
	} else if (tipo == 6) { // grama
		return vec2(fbm(uv * 4.0) * 0.6 + ruido(uv * 40.0) * 0.4, 1.0);
	} else if (tipo == 7) { // azulejo
		vec2 q = uv * 3.0;
		vec2 c = fract(q);
		float junta = min(min(c.x, 1.0 - c.x), min(c.y, 1.0 - c.y));
		vec2 d = abs(c - 0.5);
		float desenho = step(abs(d.x - d.y), 0.06) + step(length(c - 0.5), 0.17) - step(length(c - 0.5), 0.11);
		return vec2(clamp(desenho, 0.0, 1.0), smoothstep(0.02, 0.05, junta));
	} else if (tipo == 8) { // asfalto
		return vec2(ruido(uv * 30.0) * 0.5 + fbm(uv * 2.0) * 0.5, 1.0);
	} else if (tipo == 10) { // terra
		return vec2(fbm(uv * 1.5) * 0.7 + ruido(uv * 25.0) * 0.3, 1.0);
	} else if (tipo == 11) { // telha
		vec2 q = uv * vec2(4.0, 3.0);
		q.x += step(1.0, mod(floor(q.y), 2.0)) * 0.5;
		vec2 c = fract(q);
		float arco = smoothstep(0.0, 0.25, c.y) * (0.6 + 0.4 * sin(c.x * 3.14159));
		return vec2(h21(floor(q)) * 0.5 + arco * 0.5, smoothstep(0.05, 0.15, c.y));
	}
	// reboco
	return vec2(fbm(uv * 1.2) * 0.6 + ruido(uv * 14.0) * 0.4, 1.0);
}

void fragment() {
	vec3 n = abs(n_mundo);
	vec2 uv;
	if (n.y > n.x && n.y > n.z) { uv = p_mundo.xz; }
	else if (n.x > n.z) { uv = p_mundo.zy; }
	else { uv = p_mundo.xy; }
	uv *= escala;
	vec2 r = padrao(uv, p_mundo.y);
	vec3 cor = mix(cor_a.rgb, cor_b.rgb, clamp(r.x, 0.0, 1.0));
	cor *= mix(0.45, 1.0, r.y);                                  // sulcos e juntas
	float mancha = fbm(p_mundo.xz * 0.15 + p_mundo.y * 0.1);
	float baixo = 1.0 - smoothstep(0.0, 1.6, p_mundo.y);         // sujeira perto do chão
	cor *= 1.0 - sujeira * (0.35 * baixo * step(n.y, 0.5) + 0.25 * smoothstep(0.55, 0.85, mancha));
	// paredes um pouco mais escuras embaixo e mais claras no alto (oclusão falsa, dá volume)
	cor *= mix(1.0, mix(0.82, 1.04, smoothstep(0.0, 8.0, p_mundo.y)), step(n.y, 0.5));
	ALBEDO = cor;
	ROUGHNESS = rugosidade * mix(1.0, 0.85, r.y);
	METALLIC = metal;
	SPECULAR = 0.35;
}
