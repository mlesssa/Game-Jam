shader_type canvas_item;
// Drains colour toward grey near the advancing ink. ink_f is the ink front as a fraction of screen width.
uniform float ink_f = -1.0;
uniform float halo_f = 0.34;

void fragment() {
	float gr = clamp(1.0 - (SCREEN_UV.x - ink_f) / halo_f, 0.0, 1.0);
	float l = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(l), gr) * (1.0 - 0.22 * gr);
}
