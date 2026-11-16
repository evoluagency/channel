shader_type spatial;
// Respingo de tinta do paintball (sessão 1.8). Um quadrado por respingo, num MultiMesh:
// a cor vem de COLOR (cor da instância) e a semente do formato de INSTANCE_CUSTOM.x.
// Formato procedural: miolo com borda ondulada, pingos em volta e escorrido leve.
// Corte por alpha scissor (sem ordenar transparência; barato no celular).
render_mode cull_disabled, depth_prepass_alpha;

varying vec4 v_cor;
varying float v_semente;

void vertex() {
	v_cor = COLOR;
	v_semente = INSTANCE_CUSTOM.x;
}

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float s = v_semente * 97.0;
	float a = atan(p.y, p.x);
	float r = length(p);
	// borda ondulada: soma de senos com fase pela semente
	float borda = 0.48 + 0.07 * sin(a * 5.0 + s) + 0.05 * sin(a * 9.0 + s * 1.7) + 0.04 * sin(a * 13.0 + s * 2.3);
	float m = step(r, borda);
	// pontas que saem do miolo
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float ang = hash(s + fi * 3.1) * 6.2832;
		float comp = 0.55 + hash(s + fi * 7.7) * 0.3;
		vec2 d = vec2(cos(ang), sin(ang));
		float t = clamp(dot(p, d), 0.0, comp);
		float larg = 0.09 * (1.0 - t / comp) + 0.02;
		m = max(m, step(length(p - d * t), larg));
		// pingo solto
		vec2 c = d * (comp + 0.12 + hash(s + fi) * 0.15);
		m = max(m, step(length(p - c), 0.05 + hash(s + fi * 5.0) * 0.05));
	}
	if (m < 0.5) { discard; }
	// brilho de tinta molhada: mais claro no centro, aro mais escuro
	float aro = smoothstep(borda - 0.12, borda, r);
	ALBEDO = mix(v_cor.rgb * 1.08, v_cor.rgb * 0.78, aro * 0.6);
	ROUGHNESS = 0.32;
	SPECULAR = 0.6;
}
