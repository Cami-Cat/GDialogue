shader_type canvas_item;

uniform float cell_size = 32.0;
uniform float dot_size_px = 4.0;
uniform vec4 background_color : source_color = vec4(0.12, 0.12, 0.12, 1.0);
uniform vec4 dot_color : source_color = vec4(0.22, 0.22, 0.22, 1.0);
uniform vec2 world_offset;

void fragment() {
    // Snap to pixel grid
    vec2 pixel_pos = floor(FRAGCOORD.xy) + world_offset;

    // Grid calculation
    vec2 grid_pos = fract(pixel_pos / cell_size + 0.5) - 0.5;
    float dist_px = length(grid_pos) * cell_size;
    
    // Constant dot size in screen pixels
    float radius = dot_size_px * 0.5;
    
    // Smooth edges with 1px AA
    float alpha = smoothstep(radius - 1.0, radius, dist_px);
    
    COLOR = mix(dot_color, background_color, alpha);
}