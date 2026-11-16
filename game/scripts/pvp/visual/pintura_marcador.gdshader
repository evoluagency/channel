shader_type spatial;
// Pintura procedural do marcador de paintball (sessão 1.8): as 30 aparências da loja
// saem deste shader, sem textura pintada. Os padrões usam a posição local da malha
// (o marcador tem cerca de 0,8 m no eixo -Z), então a pintura acompanha a arma.
// tipo: 0 sólido, 1 camuflagem, 2 respingos, 3 chamas, 4 raio, 5 listras diagonais,
//       6 digital, 7 colmeia, 8 tigre, 9 metal gravado, 10 gelo, 11 floral,
//       12 neon, 13 galáxia, 14 folhagem (ghillie)
// emblema: 0 nenhum, 1 coração, 2 estrela, 3 caveira, 4 X, 5 coroa, 6 raio
render_mode cull_back;

uniform int tipo = 0;
uniform vec3 c1 : source_color = vec3(0.2, 0.4, 0.8);
uniform vec3 c2 : source_color = vec3(1.0, 0.8, 0.1);
uniform vec3 c3 : source_color = vec3(0.1, 0.1, 0.1);
uniform float escala = 1.0;
uniform int emblema = 0;
uniform vec3 cor_emblema : source_color = vec3(1.0);
uniform float metal = 0.0;
uniform float neon = 0.0;
uniform float hopper = 0.0;   // 1 no funil: padrão maior e mais respingos

varying vec3 lp;
varying vec3 ln;

void vertex() {
	lp = VERTEX;
	ln = NORMAL;
}

float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * ruido(p); p *= 2.03; a *= 0.5; }
	return v;
}
// distância à célula de Voronoi mais próxima (x) e à segunda (y)
vec2 voronoi(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 g = vec2(float(x), float(y));
		vec2 o = h22(i + g);
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	return vec2(d1, d2);
}
float sd_coracao(vec2 p) {
	p.x = abs(p.x);
	if (p.y + p.x > 1.0) return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
	return sqrt(min(dot(p - vec2(0.0, 1.0), p - vec2(0.0, 1.0)), dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}
float sd_estrela(vec2 p, float r) {
	const vec2 k1 = vec2(0.809016994, -0.587785252);
	const vec2 k2 = vec2(-k1.x, k1.y);
	p.x = abs(p.x);
	p -= 2.0 * max(dot(k1, p), 0.0) * k1;
	p -= 2.0 * max(dot(k2, p), 0.0) * k2;
	p.x = abs(p.x);
	p.y -= r;
	vec2 ba = 0.42 * vec2(-k1.y, k1.x) - vec2(0, 1);
	float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
	return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}
float caixa2(vec2 p, vec2 b) { vec2 d = abs(p) - b; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }

// máscara do emblema (1 dentro), em coordenadas do lado da arma
float mascara_emblema(vec2 q) {
	if (emblema == 1) return step(sd_coracao(q * vec2(1.0, -1.0) + vec2(0.0, 0.55)), 0.0);
	if (emblema == 2) return step(sd_estrela(q, 0.9), 0.0);
	if (emblema == 3) {
		float cranio = step(length(q - vec2(0.0, 0.15)), 0.62) + step(caixa2(q - vec2(0.0, -0.45), vec2(0.32, 0.22)), 0.0);
		float olhos = step(length(vec2(abs(q.x) - 0.24, q.y - 0.12)), 0.16) + step(caixa2(vec2(abs(q.x) - 0.1, q.y + 0.5), vec2(0.04, 0.12)), 0.0);
		float ossos = step(caixa2(mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * q, vec2(1.0, 0.09)), 0.0) + step(caixa2(mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * q, vec2(1.0, 0.09)), 0.0);
		return clamp(cranio + ossos, 0.0, 1.0) * (1.0 - clamp(olhos, 0.0, 1.0));
	}
	if (emblema == 4) return step(min(caixa2(mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * q, vec2(0.85, 0.16)), caixa2(mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * q, vec2(0.85, 0.16))), 0.0);
	if (emblema == 5) {
		float base = step(caixa2(q - vec2(0.0, -0.35), vec2(0.7, 0.18)), 0.0);
		float corpo = step(caixa2(q - vec2(0.0, -0.05), vec2(0.62, 0.2)), 0.0);
		float picos = 0.0;
		for (int i = -2; i <= 2; i++) {
			vec2 c = vec2(float(i) * 0.3, 0.35 - abs(float(i)) * 0.08);
			picos += step(length(q - c), 0.12);
			picos += step(caixa2(q - vec2(c.x, 0.1), vec2(0.06, 0.25)), 0.0);
		}
		return clamp(base + corpo + picos, 0.0, 1.0);
	}
	if (emblema == 6) {
		vec2 a = q * vec2(1.0, 0.8);
		float zig = abs(a.x - 0.35 * sign(sin(a.y * 3.2)) * fract(a.y * 1.6) + 0.1);
		return step(zig, 0.14) * step(abs(a.y), 1.0);
	}
	return 0.0;
}

void fragment() {
	// lado da arma: z ao longo do cano, y para cima
	vec2 uv = vec2(lp.z, lp.y) * 12.0 / escala + vec2(lp.x * 3.0, 0.0);
	if (hopper > 0.5) { uv *= 0.8; }
	vec3 cor = c1;
	float rug = 0.45;
	float emi = 0.0;
	if (tipo == 1) {
		float n1 = fbm(uv * 0.9);
		float n2 = fbm(uv * 1.1 + 13.7);
		cor = n1 > 0.52 ? c2 : c1;
		if (n2 > 0.58) { cor = c3; }
	} else if (tipo == 2) {
		vec2 v = voronoi(uv * 0.8);
		float n = fbm(uv * 2.5);
		float gota = step(v.x + n * 0.25, 0.32);
		vec2 v2 = voronoi(uv * 0.8 + 5.3);
		cor = c1;
		if (gota > 0.5) { cor = c2; }
		if (step(v2.x + n * 0.2, 0.2) > 0.5) { cor = c3; }
	} else if (tipo == 3) {
		// chamas que nascem da frente (z negativo) e lambem para trás
		float t = clamp((lp.z + 0.45) / 0.7, 0.0, 1.0);
		float onda = fbm(vec2(lp.z * 6.0, lp.y * 14.0)) * 0.5 + sin(lp.z * 30.0) * 0.08;
		float f = t + onda - 0.35;
		cor = c3;
		if (f < 0.55) { cor = c2; }
		if (f < 0.3) { cor = c1; }
	} else if (tipo == 4) {
		float y = lp.y * 18.0;
		float zig = abs(y - 1.4 * (abs(fract(lp.z * 6.0) - 0.5) * 2.0 - 0.5));
		cor = c1;
		if (zig < 0.38) { cor = c2; }
		if (zig < 0.12) { cor = vec3(1.0); emi = neon; }
	} else if (tipo == 5) {
		float d = fract((lp.z + lp.y) * 7.0 / escala);
		cor = d < 0.5 ? c1 : c2;
		if (d > 0.9) { cor = c3; }
	} else if (tipo == 6) {
		vec2 q = floor(uv * 1.6);
		float n = ruido(q * 0.35) * 0.7 + h21(q) * 0.3;
		cor = n > 0.62 ? c3 : (n > 0.42 ? c2 : c1);
	} else if (tipo == 7) {
		vec2 q = uv * 1.4;
		vec2 r = vec2(1.0, 1.732);
		vec2 a = mod(q, r) - r * 0.5;
		vec2 b = mod(q - r * 0.5, r) - r * 0.5;
		vec2 g = dot(a, a) < dot(b, b) ? a : b;
		float hx = max(abs(g.x) * 0.866 + abs(g.y) * 0.5, abs(g.y));
		cor = hx > 0.4 ? c2 : c1;
	} else if (tipo == 8) {
		float l = sin(lp.z * 34.0 + fbm(uv * 1.3) * 5.0);
		cor = l > 0.55 ? c2 : c1;
		if (l > 0.85) { cor = c3; }
	} else if (tipo == 9) {
		float g = fbm(uv * 3.0);
		float fili = abs(sin(uv.x * 2.0 + sin(uv.y * 3.0) * 1.5));
		cor = mix(c1, c1 * 1.25, g);
		if (fili < 0.12) { cor = c2; }
		rug = 0.25;
	} else if (tipo == 10) {
		vec2 v = voronoi(uv * 1.1);
		float aresta = v.y - v.x;
		cor = mix(c1, c2, h21(floor(uv * 1.1)));
		if (aresta < 0.08) { cor = c3; }
		rug = 0.2;
	} else if (tipo == 11) {
		vec2 g = fract(uv * 0.55) - 0.5;
		vec2 id = floor(uv * 0.55);
		float ang = atan(g.y, g.x) + h21(id) * 6.28;
		float r = length(g);
		float petala = 0.28 + 0.12 * cos(ang * 5.0);
		cor = c1;
		if (r < petala && h21(id + 3.1) > 0.25) { cor = h21(id) > 0.5 ? c2 : c3; }
		if (r < 0.07) { cor = vec3(1.0, 0.85, 0.3); }
	} else if (tipo == 12) {
		float l1 = abs(fract((lp.z - lp.y * 0.6) * 5.0) - 0.5);
		float l2 = abs(fract((lp.z + lp.y * 1.4) * 3.0) - 0.5);
		cor = c3;
		if (l1 < 0.06) { cor = c1; emi = neon; }
		if (l2 < 0.04) { cor = c2; emi = neon; }
	} else if (tipo == 13) {
		float n = fbm(uv * 0.6);
		cor = mix(c1, c2, smoothstep(0.35, 0.75, n));
		float est = step(0.985, h21(floor(uv * 6.0)));
		if (est > 0.5) { cor = vec3(1.0); emi = 0.6; }
		vec2 v = voronoi(uv * 0.7 + 2.0);
		if (v.x < 0.18) { cor = c3; }
	} else if (tipo == 14) {
		float n = fbm(uv * 1.6);
		float f = fbm(uv * 4.0 + 7.0);
		cor = mix(c1, c2, step(0.5, n));
		if (f > 0.62) { cor = c3; }
		rug = 0.85;
	}
	// emblema grande no lado do corpo (centro em z = -0.12, y = 0.0)
	if (emblema > 0 && hopper < 0.5 && abs(ln.x) > 0.5) {
		vec2 q = (vec2(-lp.z * sign(ln.x), lp.y) - vec2(0.12 * sign(ln.x), 0.0)) / 0.055;
		if (mascara_emblema(q) > 0.5) { cor = cor_emblema; rug = 0.35; }
	}
	ALBEDO = cor;
	ROUGHNESS = rug;
	METALLIC = metal;
	SPECULAR = 0.55;
	EMISSION = cor * emi;
}
