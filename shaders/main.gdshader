shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.361, 0.251, 0.200);
uniform vec3 light_color : source_color = vec3(0.627, 0.502, 0.439);
uniform vec3 chip_color : source_color = vec3(0.180, 0.102, 0.063);
uniform float lightness : hint_range(0.0, 1.0) = 0.0;
uniform float chip_density : hint_range(1.0, 10.0) = 2.5;
uniform float chip_world_size : hint_range(0.05, 0.5) = 0.18;
uniform float chip_probability : hint_range(0.0, 1.0) = 0.35;
uniform vec2 chip_offset = vec2(0.0, 0.0);
uniform vec3 cookie_scale = vec3(1.0, 1.0, 1.0);

varying vec3 model_normal;
varying vec3 model_vertex;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

bool is_chip(vec2 local_uv, vec2 cookie_bounds) {
	// Grid cell size in world units.
	float cell_size = 1.0 / chip_density;

	// Apply offset for pattern lookup.
	vec2 pattern_uv = local_uv + chip_offset;

	// Grid cell coordinates.
	vec2 grid_cell = floor(pattern_uv / cell_size);

	// Check if this cell contains a chip.
	float cell_hash = hash(grid_cell);
	if (cell_hash > chip_probability) {
		return false;
	}

	// Center of this cell in pattern space.
	vec2 cell_center_pattern = (grid_cell + 0.5) * cell_size;

	// Convert back to local space for bounds checking.
	vec2 cell_center_local = cell_center_pattern - chip_offset;

	// Check if chip would be cut off at cookie edges.
	float half_chip = chip_world_size * 0.5;
	vec2 half_bounds = cookie_bounds * 0.5;
	if (cell_center_local.x - half_chip < -half_bounds.x || cell_center_local.x + half_chip > half_bounds.x) {
		return false;
	}
	if (cell_center_local.y - half_chip < -half_bounds.y || cell_center_local.y + half_chip > half_bounds.y) {
		return false;
	}

	// Distance from cell center.
	vec2 dist_from_center = abs(local_uv - cell_center_local);

	// Check if we're inside the square chip bounds.
	return dist_from_center.x < half_chip && dist_from_center.y < half_chip;
}

void vertex() {
	model_normal = NORMAL;
	model_vertex = VERTEX;
}

void fragment() {
	vec3 cookie_color = mix(base_color, light_color, lightness);
	vec3 final_color = cookie_color;

	// Calculate local UV and bounds based on face orientation.
	vec2 local_uv;
	vec2 cookie_bounds;
	if (abs(model_normal.y) > 0.9) {
		// Top or bottom face.
		local_uv = model_vertex.xz * cookie_scale.xz;
		cookie_bounds = cookie_scale.xz;
	} else if (abs(model_normal.x) > 0.9) {
		// Left or right face.
		local_uv = model_vertex.zy * cookie_scale.zy;
		cookie_bounds = cookie_scale.zy;
	} else {
		// Front or back face.
		local_uv = model_vertex.xy * cookie_scale.xy;
		cookie_bounds = cookie_scale.xy;
	}

	if (is_chip(local_uv, cookie_bounds)) {
		final_color = chip_color;
	}

	ALBEDO = final_color;
	ROUGHNESS = 0.85;
}
