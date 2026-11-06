extends Node3D

const WORLD_SIZE := 512.0
const GRID_STEPS := 160
const PLAYER_SPEED := 7.0
const GRAVITY := 22.0
const JUMP_VELOCITY := 8.0
const CAMERA_DRAG_SENSITIVITY := 0.006
const LAN_PORT := 24560
const LAN_MAX_CLIENTS := 1
const NETWORK_SEND_INTERVAL := 0.05
const SAVE_PATH := "user://worlds_save.cfg"

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var gait_time := 0.0
var pressed_actions: Dictionary = {}
var hud_label: Label
var health_bar: ProgressBar
var mobile_controls: Control
var world_environment: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D
var tree_trunks: MultiMeshInstance3D
var tree_canopies: MultiMeshInstance3D
var pine_trunks: MultiMeshInstance3D
var pine_canopies: MultiMeshInstance3D
var grass_field: MultiMeshInstance3D
var rock_field: MultiMeshInstance3D
var total_tree_instances := 0
var total_pine_instances := 0
var total_grass_instances := 0
var total_rock_instances := 0
var current_tree_density := 1.0
var world_clock := 8.0
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var rest := 100.0
var berry_bushes: Array[Dictionary] = []
var resource_nodes: Array[Dictionary] = []
var wildlife_agents: Array[Dictionary] = []
var village_agents: Array[Dictionary] = []
var wildlife_rng := RandomNumberGenerator.new()
var shared_inventory: Dictionary = {"wood": 0, "stone": 0, "fiber": 0}
var placed_buildings: Array[Dictionary] = []
var inventory_label: Label
var build_panel: PanelContainer
var build_recipe_buttons: Dictionary = {}
var build_rotation_offset := 0.0
var build_preview: MeshInstance3D
var build_preview_material: StandardMaterial3D
var camp_position := Vector3.ZERO
var memory_position := Vector3.ZERO
var memory_awakened := false
var status_note := ""
var status_note_time := 0.0
var touch_button_layer: Node2D
var normal_touch_texture: Texture2D
var pressed_touch_texture: Texture2D
var network_panel: PanelContainer
var network_status_label: Label
var host_ip_label: Label
var address_input: LineEdit
var quality_option: OptionButton
var fps_option: OptionButton
var fps_label: Label
var lan_active := false
var network_send_timer := 0.0
var network_remote_players: Dictionary = {}
var network_remote_targets: Dictionary = {}
var memory_crystal: MeshInstance3D
var save_elapsed := 0.0
var quality_index := 0
var current_render_scale := 0.76
var adaptive_check_timer := 0.0
var hud_refresh_timer := 0.0
var current_fps_target := 60
var lan_smoke_client_passed := false
var joystick_base: TextureRect
var joystick_knob: TextureRect
var joystick_center := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joystick_touch_index := -1
var camera_sensitivity := CAMERA_DRAG_SENSITIVITY
var camera_distance := 7.0
var camera_fov := 70.0
var button_opacity := 0.82
var control_scale := 1.0
var minimap_panel: PanelContainer
var minimap_background: TextureRect
var minimap_marker: Polygon2D
var minimap_region_label: Label
var minimap_toggle_button: Button
var minimap_size := 176.0
var control_layout_edit_mode := false
var layout_drag_action := ""
var layout_touch_index := -1
var action_buttons: Dictionary = {}
var action_captions: Dictionary = {}
var settings_panel: PanelContainer
var layout_status_label: Label
var metrics_label: Label
var camera_sensitivity_slider: HSlider
var camera_distance_slider: HSlider
var camera_fov_slider: HSlider
var control_scale_slider: HSlider
var button_opacity_slider: HSlider
var metrics_refresh_timer := 0.0

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    _create_environment()
    print("WORLDS_STAGE environment")
    _create_terrain()
    print("WORLDS_STAGE terrain")
    _create_river()
    _create_riverbank_details()
    print("WORLDS_STAGE riverbank_details")
    print("WORLDS_STAGE river")
    _create_forest()
    print("WORLDS_STAGE forest")
    _create_pine_forest()
    print("WORLDS_STAGE pine_forest")
    _create_environment_details()
    print("WORLDS_STAGE environment_details")
    _create_foraging_bushes()
    print("WORLDS_STAGE forage")
    _create_resource_nodes()
    print("WORLDS_STAGE resources")
    _create_wildlife()
    print("WORLDS_STAGE wildlife")
    _create_village()
    print("WORLDS_STAGE village")
    _create_campsite()
    print("WORLDS_STAGE campsite")
    _create_memory_stone()
    print("WORLDS_STAGE memory")
    _create_player()
    print("WORLDS_STAGE player")
    _create_hud()
    print("WORLDS_STAGE hud")
    var startup_args := OS.get_cmdline_user_args()
    if startup_args.has("--gameplay-smoke") or startup_args.has("--lan-smoke-host") or startup_args.has("--lan-smoke-client"):
        if FileAccess.file_exists(SAVE_PATH):
            var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
            if remove_error != OK:
                push_warning("Could not clear isolated smoke-test save: %d" % remove_error)
    _load_game()
    _on_camera_distance_changed(camera_distance)
    _on_camera_fov_changed(camera_fov)
    _on_button_opacity_changed(button_opacity)
    _on_control_scale_changed(control_scale)
    _sync_settings_sliders()
    _apply_quality_preset(0)
    Engine.max_fps = current_fps_target
    var command_args := OS.get_cmdline_user_args()
    if command_args.has("--gameplay-smoke"):
        call_deferred("_start_gameplay_smoke_test")
    elif command_args.has("--lan-smoke-host"):
        call_deferred("_start_lan_smoke_host")
    elif command_args.has("--lan-smoke-client"):
        call_deferred("_start_lan_smoke_client")

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        pressed_actions.clear()
        _save_game()
    elif what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_game()

func _create_environment() -> void:
    var world_env := WorldEnvironment.new()
    world_environment = Environment.new()
    world_environment.background_mode = Environment.BG_SKY

    var sky := Sky.new()
    sky_material = ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.16, 0.35, 0.56)
    sky_material.sky_horizon_color = Color(0.72, 0.82, 0.86)
    sky_material.ground_bottom_color = Color(0.12, 0.18, 0.15)
    sky_material.ground_horizon_color = Color(0.48, 0.58, 0.48)
    sky.sky_material = sky_material
    world_environment.sky = sky
    world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world_environment.ambient_light_color = Color(0.72, 0.82, 0.92)
    world_environment.ambient_light_energy = 0.65
    world_environment.fog_enabled = true
    world_environment.fog_light_color = Color(0.61, 0.72, 0.70)
    world_environment.fog_density = 0.0025
    world_env.environment = world_environment
    add_child(world_env)

    sun_light = DirectionalLight3D.new()
    sun_light.rotation_degrees = Vector3(-48, -32, 0)
    sun_light.light_energy = 1.05
    sun_light.shadow_enabled = true
    add_child(sun_light)

func _height_at(x: float, z: float) -> float:
    var broad_hills := sin(x * 0.013) * 6.5 + cos(z * 0.011) * 7.0
    broad_hills += sin((x + z) * 0.008) * 5.0
    var desert_weight := clampf((x - 125.0) / 105.0, 0.0, 1.0)
    var dunes := sin(x * 0.031 + cos(z * 0.022) * 1.8) * 1.25 + cos(z * 0.038) * 0.75
    broad_hills = lerpf(broad_hills, dunes, desert_weight)
    var snow_weight := clampf((-z - 125.0) / 100.0, 0.0, 1.0)
    var alpine := sin(x * 0.018) * 8.0 + cos(z * 0.021) * 6.0
    alpine += maxf(0.0, sin((x + z) * 0.028)) * 15.0
    broad_hills = lerpf(broad_hills, alpine, snow_weight)
    var ridge_wave := maxf(0.0, sin((x - z) * 0.021 + cos(z * 0.009)))
    var ridges := ridge_wave * ridge_wave * lerpf(8.5, 3.0, desert_weight)
    var river_bank: float = absf(x - sin(z * 0.018) * 18.0)
    var valley: float = -maxf(0.0, 1.0 - river_bank / 26.0) * 2.8
    var upland := maxf(0.0, sin(x * 0.004 + z * 0.006)) * 4.0
    return broad_hills + ridges + upland + valley

func _create_terrain() -> void:
    var vertices := PackedVector3Array()
    var colors := PackedColorArray()
    var indices := PackedInt32Array()
    var step := WORLD_SIZE / float(GRID_STEPS)

    for z_index in range(GRID_STEPS + 1):
        for x_index in range(GRID_STEPS + 1):
            var x := -WORLD_SIZE * 0.5 + float(x_index) * step
            var z := -WORLD_SIZE * 0.5 + float(z_index) * step
            var y := _height_at(x, z)
            vertices.append(Vector3(x, y, z))

            var tint := Color(0.20, 0.39, 0.18)
            var variation: float = clampf((y + 3.0) / 24.0, 0.0, 1.0)
            var ground_breakup := sin(x * 0.19) * cos(z * 0.16) * 0.045
            tint = tint.lerp(Color(0.43, 0.49, 0.30), clampf(variation * 0.62 + ground_breakup, 0.0, 0.72))
            var desert_weight := clampf((x - 125.0) / 105.0, 0.0, 1.0)
            var snow_weight := clampf((-z - 125.0) / 100.0, 0.0, 1.0)
            tint = tint.lerp(Color(0.66, 0.53, 0.31), desert_weight)
            tint = tint.lerp(Color(0.76, 0.82, 0.83), snow_weight)
            var exposed_rock := clampf((y - 20.0) / 12.0, 0.0, 0.68)
            tint = tint.lerp(Color(0.42, 0.44, 0.43), exposed_rock)
            colors.append(tint)

    for z_index in range(GRID_STEPS):
        for x_index in range(GRID_STEPS):
            var a := z_index * (GRID_STEPS + 1) + x_index
            var b := a + 1
            var c := a + GRID_STEPS + 1
            var d := c + 1
            indices.append(a)
            indices.append(c)
            indices.append(b)
            indices.append(b)
            indices.append(c)
            indices.append(d)

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    mesh.surface_set_material(0, material)

    var terrain := MeshInstance3D.new()
    terrain.name = "Terrain"
    terrain.mesh = mesh
    add_child(terrain)

    var body := StaticBody3D.new()
    body.name = "TerrainCollision"
    var collision := CollisionShape3D.new()
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(_vertices_to_faces(vertices, indices))
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func _vertices_to_faces(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
    var faces := PackedVector3Array()
    for index in indices:
        faces.append(vertices[index])
    return faces

func _create_river() -> void:
    var river_mesh := ArrayMesh.new()
    var vertices := PackedVector3Array()
    var indices := PackedInt32Array()
    var segments := 180

    for i in range(segments + 1):
        var z := -WORLD_SIZE * 0.5 + float(i) * WORLD_SIZE / float(segments)
        var center_x := sin(z * 0.018) * 18.0
        var water_y := _height_at(center_x, z) - 0.12
        vertices.append(Vector3(center_x - 4.2, water_y, z))
        vertices.append(Vector3(center_x + 4.2, water_y, z))

    for i in range(segments):
        var a := i * 2
        indices.append(a)
        indices.append(a + 2)
        indices.append(a + 1)
        indices.append(a + 1)
        indices.append(a + 2)
        indices.append(a + 3)

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices
    river_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

    var water := MeshInstance3D.new()
    water.name = "River"
    water.mesh = river_mesh
    var water_shader := Shader.new()
    water_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 water_tint : source_color = vec4(0.05, 0.34, 0.52, 0.88);
varying vec3 river_world_position;

void vertex() {
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    river_world_position = world_vertex;
    float long_wave = sin(world_vertex.x * 0.14 + TIME * 0.9) * 0.045;
    float cross_wave = cos(world_vertex.z * 0.18 - TIME * 0.65) * 0.035;
    VERTEX.y += long_wave + cross_wave;
}

void fragment() {
    float ripple_a = sin(river_world_position.x * 0.23 + TIME * 1.05);
    float ripple_b = cos(river_world_position.z * 0.17 - TIME * 0.8);
    float ripple = (ripple_a * ripple_b + 1.0) * 0.5;
    ALBEDO = water_tint.rgb * (0.84 + ripple * 0.22);
    METALLIC = 0.08;
    ROUGHNESS = 0.16;
    SPECULAR = 0.78;
    ALPHA = water_tint.a;
}
"""
    var water_material := ShaderMaterial.new()
    water_material.shader = water_shader
    water.mesh.surface_set_material(0, water_material)
    add_child(water)

func _create_riverbank_details() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261112

    var pebble_mesh := SphereMesh.new()
    pebble_mesh.radius = 0.34
    pebble_mesh.height = 0.42
    pebble_mesh.radial_segments = 7
    pebble_mesh.rings = 4
    var pebble_multi := MultiMesh.new()
    pebble_multi.transform_format = MultiMesh.TRANSFORM_3D
    pebble_multi.use_colors = true
    pebble_multi.mesh = pebble_mesh
    pebble_multi.instance_count = 260

    var pebble_material := StandardMaterial3D.new()
    pebble_material.vertex_color_use_as_albedo = true
    pebble_material.roughness = 0.98

    for i in range(pebble_multi.instance_count):
        var z := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        var center_x := sin(z * 0.018) * 18.0
        var side := -1.0 if rng.randf() < 0.5 else 1.0
        var x := center_x + side * rng.randf_range(5.2, 10.5)
        var scale := rng.randf_range(0.45, 1.35)
        var pebble_position := Vector3(x, _height_at(x, z) + scale * 0.12, z)
        var pebble_basis := Basis.from_euler(Vector3(
            rng.randf_range(-0.2, 0.2),
            rng.randf_range(0.0, TAU),
            rng.randf_range(-0.2, 0.2)
        )).scaled(Vector3(scale * 1.35, scale * 0.72, scale))
        pebble_multi.set_instance_transform(i, Transform3D(pebble_basis, pebble_position))
        pebble_multi.set_instance_color(i, Color(0.30, 0.34, 0.33).lerp(Color(0.62, 0.58, 0.48), rng.randf() * 0.72))

    var pebbles := MultiMeshInstance3D.new()
    pebbles.name = "RiverbankPebbles"
    pebbles.multimesh = pebble_multi
    pebbles.material_override = pebble_material
    add_child(pebbles)

    var reed_mesh := CylinderMesh.new()
    reed_mesh.top_radius = 0.012
    reed_mesh.bottom_radius = 0.045
    reed_mesh.height = 0.82
    reed_mesh.radial_segments = 4
    var reed_multi := MultiMesh.new()
    reed_multi.transform_format = MultiMesh.TRANSFORM_3D
    reed_multi.use_colors = true
    reed_multi.mesh = reed_mesh
    reed_multi.instance_count = 180

    var reed_material := StandardMaterial3D.new()
    reed_material.vertex_color_use_as_albedo = true
    reed_material.roughness = 1.0

    for i in range(reed_multi.instance_count):
        var z := rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
        var center_x := sin(z * 0.018) * 18.0
        var side := -1.0 if rng.randf() < 0.5 else 1.0
        var x := center_x + side * rng.randf_range(6.0, 10.0)
        var height_scale := rng.randf_range(0.65, 1.35)
        var lean := rng.randf_range(-0.16, 0.16)
        var reed_position := Vector3(x, _height_at(x, z) + 0.35 * height_scale, z)
        var reed_basis := Basis.from_euler(Vector3(lean, rng.randf_range(0.0, TAU), lean * 0.6)).scaled(
            Vector3(1.0, height_scale, 1.0)
        )
        reed_multi.set_instance_transform(i, Transform3D(reed_basis, reed_position))
        reed_multi.set_instance_color(i, Color(0.24, 0.34, 0.14).lerp(Color(0.55, 0.52, 0.25), rng.randf() * 0.65))

    var reeds := MultiMeshInstance3D.new()
    reeds.name = "RiverbankReeds"
    reeds.multimesh = reed_multi
    reeds.material_override = reed_material
    add_child(reeds)

func _create_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261106

    var tree_positions: Array[Dictionary] = []
    for i in range(750):
        var x := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        var z := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        if abs(x - sin(z * 0.018) * 18.0) < 13.0:
            continue
        if x > 145.0 or z < -145.0:
            continue
        if Vector2(x, z).length() < 12.0:
            continue
        tree_positions.append({
            "position": Vector3(x, _height_at(x, z), z),
            "scale": rng.randf_range(0.8, 1.35)
        })

    _create_tree_instances(tree_positions)

func _create_pine_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261109
    var pine_positions: Array[Dictionary] = []
    for i in range(190):
        var x := rng.randf_range(-WORLD_SIZE * 0.43, WORLD_SIZE * 0.43)
        var z := rng.randf_range(-WORLD_SIZE * 0.44, -WORLD_SIZE * 0.29)
        if absf(x - sin(z * 0.018) * 18.0) < 14.0:
            continue
        pine_positions.append({
            "position": Vector3(x, _height_at(x, z), z),
            "scale": rng.randf_range(0.85, 1.35)
        })

    if pine_positions.is_empty():
        return

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.10
    trunk_mesh.bottom_radius = 0.19
    trunk_mesh.height = 1.8
    var canopy_mesh := CylinderMesh.new()
    canopy_mesh.top_radius = 0.035
    canopy_mesh.bottom_radius = 1.0
    canopy_mesh.height = 3.7
    canopy_mesh.radial_segments = 7

    var trunk_multi := MultiMesh.new()
    trunk_multi.transform_format = MultiMesh.TRANSFORM_3D
    trunk_multi.use_colors = true
    trunk_multi.mesh = trunk_mesh
    trunk_multi.instance_count = pine_positions.size()
    var canopy_multi := MultiMesh.new()
    canopy_multi.transform_format = MultiMesh.TRANSFORM_3D
    canopy_multi.use_colors = true
    canopy_multi.mesh = canopy_mesh
    canopy_multi.instance_count = pine_positions.size()

    var trunk_material := StandardMaterial3D.new()
    trunk_material.vertex_color_use_as_albedo = true
    trunk_material.albedo_color = Color(0.28, 0.19, 0.12)
    trunk_material.roughness = 1.0
    var canopy_material := StandardMaterial3D.new()
    canopy_material.vertex_color_use_as_albedo = true
    canopy_material.albedo_color = Color(0.065, 0.20, 0.16)
    canopy_material.roughness = 0.95

    for i in range(pine_positions.size()):
        var data: Dictionary = pine_positions[i]
        var pos: Vector3 = data["position"]
        var scale: float = data["scale"]
        trunk_multi.set_instance_transform(i, Transform3D(
            Basis.from_scale(Vector3(scale, scale, scale)),
            pos + Vector3(0, 0.9 * scale, 0)
        ))
        trunk_multi.set_instance_color(i, Color(0.22, 0.14, 0.09))
        canopy_multi.set_instance_transform(i, Transform3D(
            Basis.from_scale(Vector3(scale, scale * 1.1, scale)),
            pos + Vector3(0, 2.55 * scale, 0)
        ))
        canopy_multi.set_instance_color(i, Color(0.035, 0.15, 0.12).lerp(Color(0.11, 0.29, 0.23), rng.randf() * 0.8))

    pine_trunks = MultiMeshInstance3D.new()
    pine_trunks.name = "SnowPineTrunks"
    pine_trunks.multimesh = trunk_multi
    pine_trunks.material_override = trunk_material
    add_child(pine_trunks)

    pine_canopies = MultiMeshInstance3D.new()
    pine_canopies.name = "SnowPineCanopies"
    pine_canopies.multimesh = canopy_multi
    pine_canopies.material_override = canopy_material
    add_child(pine_canopies)
    total_pine_instances = pine_positions.size()

func _create_tree_instances(tree_positions: Array[Dictionary]) -> void:
    if tree_positions.is_empty():
        return

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.28
    trunk_mesh.height = 2.1

    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.27, 0.16, 0.09)
    bark.vertex_color_use_as_albedo = true
    bark.roughness = 1.0

    var trunk_multi := MultiMesh.new()
    trunk_multi.transform_format = MultiMesh.TRANSFORM_3D
    trunk_multi.use_colors = true
    trunk_multi.mesh = trunk_mesh
    trunk_multi.instance_count = tree_positions.size()

    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.05
    crown_mesh.height = 2.0

    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.12, 0.31, 0.15)
    leaves.vertex_color_use_as_albedo = true
    leaves.roughness = 0.92

    var crown_multi := MultiMesh.new()
    crown_multi.transform_format = MultiMesh.TRANSFORM_3D
    crown_multi.use_colors = true
    crown_multi.mesh = crown_mesh
    crown_multi.instance_count = tree_positions.size()

    var tree_rng := RandomNumberGenerator.new()
    tree_rng.seed = 20261107
    for i in range(tree_positions.size()):
        var tree_data: Dictionary = tree_positions[i]
        var tree_position: Vector3 = tree_data["position"]
        var tree_scale: float = tree_data["scale"]

        var trunk_basis := Basis.from_scale(Vector3(tree_scale, tree_scale, tree_scale))
        var trunk_transform := Transform3D(trunk_basis, tree_position + Vector3(0, 1.05 * tree_scale, 0))
        trunk_multi.set_instance_transform(i, trunk_transform)
        trunk_multi.set_instance_color(i, Color(0.23, 0.13, 0.075).lerp(Color(0.38, 0.24, 0.13), tree_rng.randf() * 0.55))

        var crown_scale := Vector3(
            tree_scale * tree_rng.randf_range(0.92, 1.28),
            tree_scale * tree_rng.randf_range(0.88, 1.25),
            tree_scale * tree_rng.randf_range(0.92, 1.30)
        )
        var crown_basis := Basis.from_euler(Vector3(0.0, tree_rng.randf_range(0.0, TAU), 0.0)).scaled(crown_scale)
        var crown_transform := Transform3D(crown_basis, tree_position + Vector3(0, 2.45 * tree_scale, 0))
        crown_multi.set_instance_transform(i, crown_transform)
        crown_multi.set_instance_color(i, Color(0.075, 0.24, 0.105).lerp(Color(0.24, 0.42, 0.16), tree_rng.randf() * 0.8))

    tree_trunks = MultiMeshInstance3D.new()
    tree_trunks.name = "TreeTrunks"
    tree_trunks.multimesh = trunk_multi
    tree_trunks.material_override = bark
    add_child(tree_trunks)

    tree_canopies = MultiMeshInstance3D.new()
    tree_canopies.name = "TreeCanopies"
    tree_canopies.multimesh = crown_multi
    tree_canopies.material_override = leaves
    add_child(tree_canopies)
    total_tree_instances = tree_positions.size()

func _create_environment_details() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261108

    var grass_mesh := CylinderMesh.new()
    grass_mesh.top_radius = 0.018
    grass_mesh.bottom_radius = 0.075
    grass_mesh.height = 0.48
    grass_mesh.radial_segments = 4
    var grass_multi := MultiMesh.new()
    grass_multi.transform_format = MultiMesh.TRANSFORM_3D
    grass_multi.use_colors = true
    grass_multi.mesh = grass_mesh
    grass_multi.instance_count = 4200

    var grass_material := StandardMaterial3D.new()
    grass_material.vertex_color_use_as_albedo = true
    grass_material.albedo_color = Color(0.20, 0.38, 0.14)
    grass_material.roughness = 1.0

    for i in range(grass_multi.instance_count):
        var x := rng.randf_range(-WORLD_SIZE * 0.47, WORLD_SIZE * 0.47)
        var z := rng.randf_range(-WORLD_SIZE * 0.47, WORLD_SIZE * 0.47)
        var desert_zone := x > 145.0
        var snow_zone := z < -145.0
        if absf(x - sin(z * 0.018) * 18.0) < 9.0 or Vector2(x, z).length() < 20.0 or (desert_zone and rng.randf() < 0.94) or (snow_zone and rng.randf() < 0.70):
            grass_multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(0, -1000, 0)))
            continue
        var height_scale := rng.randf_range(0.65, 1.35)
        var blade_scale := rng.randf_range(0.75, 1.35)
        var basis := Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(
            Vector3(blade_scale, blade_scale * height_scale, blade_scale)
        )
        var pos := Vector3(x, _height_at(x, z) + 0.18 * height_scale, z)
        grass_multi.set_instance_transform(i, Transform3D(basis, pos))
        grass_multi.set_instance_color(i, Color(0.12, 0.30, 0.10).lerp(Color(0.34, 0.47, 0.18), rng.randf() * 0.75))

    grass_field = MultiMeshInstance3D.new()
    grass_field.name = "MeadowGrass"
    grass_field.multimesh = grass_multi
    grass_field.material_override = grass_material
    add_child(grass_field)
    total_grass_instances = grass_multi.instance_count

    var rock_mesh := SphereMesh.new()
    rock_mesh.radius = 0.72
    rock_mesh.height = 1.0
    rock_mesh.radial_segments = 8
    rock_mesh.rings = 4
    var rock_multi := MultiMesh.new()
    rock_multi.transform_format = MultiMesh.TRANSFORM_3D
    rock_multi.use_colors = true
    rock_multi.mesh = rock_mesh
    rock_multi.instance_count = 260

    var rock_material := StandardMaterial3D.new()
    rock_material.vertex_color_use_as_albedo = true
    rock_material.albedo_color = Color(0.40, 0.42, 0.39)
    rock_material.roughness = 0.96

    for i in range(rock_multi.instance_count):
        var x := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        var z := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        var river_distance := absf(x - sin(z * 0.018) * 18.0)
        var scale := rng.randf_range(0.55, 1.65)
        var rock_basis := Basis.from_euler(Vector3(
            rng.randf_range(-0.18, 0.18),
            rng.randf_range(0.0, TAU),
            rng.randf_range(-0.18, 0.18)
        )).scaled(Vector3(scale * 1.25, scale * 0.72, scale))
        var rock_position := Vector3(x, _height_at(x, z) + scale * 0.22, z)
        if river_distance < 8.0:
            rock_position.y -= 1000.0
        rock_multi.set_instance_transform(i, Transform3D(rock_basis, rock_position))
        rock_multi.set_instance_color(i, Color(0.31, 0.34, 0.33).lerp(Color(0.58, 0.56, 0.49), rng.randf() * 0.7))

    rock_field = MultiMeshInstance3D.new()
    rock_field.name = "FieldRocks"
    rock_field.multimesh = rock_multi
    rock_field.material_override = rock_material
    add_child(rock_field)
    total_rock_instances = rock_multi.instance_count

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(18.0, _height_at(18.0, 0.0) + 2.0, 0.0)
    add_child(player)

    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    collider.shape = capsule
    collider.position.y = 0.9
    player.add_child(collider)

    var visual := Node3D.new()
    visual.name = "CharacterVisual"
    player.add_child(visual)

    var torso := _make_capsule_part(0.34, 1.12, Color(0.16, 0.30, 0.23))
    torso.position = Vector3(0, 1.16, 0)
    visual.add_child(torso)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.245
    head_mesh.height = 0.49
    head.mesh = head_mesh
    head.position = Vector3(0, 1.88, 0)
    var skin_material := StandardMaterial3D.new()
    skin_material.albedo_color = Color(0.66, 0.46, 0.32)
    head.material_override = skin_material
    visual.add_child(head)

    var hair := MeshInstance3D.new()
    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.25
    hair_mesh.height = 0.22
    hair.mesh = hair_mesh
    hair.position = Vector3(0, 2.04, -0.025)
    var hair_material := StandardMaterial3D.new()
    hair_material.albedo_color = Color(0.12, 0.10, 0.08)
    hair.material_override = hair_material
    visual.add_child(hair)

    left_arm = _make_capsule_part(0.13, 0.78, Color(0.19, 0.34, 0.26))
    left_arm.position = Vector3(-0.40, 1.25, 0)
    left_arm.rotation.z = PI * 0.5
    visual.add_child(left_arm)

    right_arm = _make_capsule_part(0.13, 0.78, Color(0.19, 0.34, 0.26))
    right_arm.position = Vector3(0.40, 1.25, 0)
    right_arm.rotation.z = PI * 0.5
    visual.add_child(right_arm)

    left_leg = _make_capsule_part(0.15, 0.82, Color(0.18, 0.20, 0.21))
    left_leg.position = Vector3(-0.17, 0.43, 0)
    visual.add_child(left_leg)

    right_leg = _make_capsule_part(0.15, 0.82, Color(0.18, 0.20, 0.21))
    right_leg.position = Vector3(0.17, 0.43, 0)
    visual.add_child(right_leg)

    var backpack := MeshInstance3D.new()
    var backpack_mesh := BoxMesh.new()
    backpack_mesh.size = Vector3(0.48, 0.56, 0.24)
    backpack.mesh = backpack_mesh
    backpack.position = Vector3(0, 1.23, 0.29)
    var backpack_material := StandardMaterial3D.new()
    backpack_material.albedo_color = Color(0.29, 0.22, 0.13)
    backpack.material_override = backpack_material
    visual.add_child(backpack)

    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = player.position + Vector3(0, 1.55, 0)
    add_child(camera_pivot)

    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.position = Vector3(0, 2.8, 7.0)
    camera.rotation_degrees = Vector3(-14, 0, 0)
    camera.current = true
    camera_pivot.add_child(camera)

func _make_capsule_part(radius: float, height: float, color: Color) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    part.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.92
    part.material_override = material
    return part

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(300, 120)
    layer.add_child(panel)

    var hud_column := VBoxContainer.new()
    hud_column.add_theme_constant_override("separation", 3)
    panel.add_child(hud_column)

    hud_label = Label.new()
    hud_label.text = "WORLDS  •  CONNECTING WORLD"
    hud_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88))
    hud_label.add_theme_font_size_override("font_size", 16)
    hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hud_column.add_child(hud_label)

    health_bar = ProgressBar.new()
    health_bar.name = "HealthBar"
    health_bar.min_value = 0.0
    health_bar.max_value = 100.0
    health_bar.value = health
    health_bar.show_percentage = false
    health_bar.custom_minimum_size.y = 12.0
    hud_column.add_child(health_bar)

    mobile_controls = Control.new()
    mobile_controls.name = "TouchLabels"
    mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
    mobile_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(mobile_controls)

    touch_button_layer = Node2D.new()
    touch_button_layer.name = "MultiTouchButtons"
    layer.add_child(touch_button_layer)

    normal_touch_texture = _make_touch_texture(Color(0.08, 0.28, 0.25, 0.76))
    pressed_touch_texture = _make_touch_texture(Color(0.16, 0.58, 0.46, 0.94))
    var screen_size := get_viewport().get_visible_rect().size
    _create_virtual_joystick(screen_size)
    _add_control_button("USE", Vector2(screen_size.x * 0.75, screen_size.y * 0.70), "interact", true)
    _add_control_button("BUILD", Vector2(screen_size.x * 0.88, screen_size.y * 0.70), "build", true)
    _add_control_button("RUN", Vector2(screen_size.x * 0.75, screen_size.y * 0.86), "run", true)
    _add_control_button("JUMP", Vector2(screen_size.x * 0.88, screen_size.y * 0.86), "jump", true)

    _create_network_panel(layer)
    _create_settings_panel(layer)
    _create_build_panel(layer)
    _create_minimap(layer)

func _create_virtual_joystick(screen_size: Vector2) -> void:
    joystick_center = Vector2(screen_size.x * 0.16, screen_size.y * 0.79)

    joystick_base = TextureRect.new()
    joystick_base.name = "VirtualJoystickBase"
    joystick_base.texture = normal_touch_texture
    joystick_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    joystick_base.stretch_mode = TextureRect.STRETCH_SCALE
    joystick_base.size = Vector2(142.0, 142.0)
    joystick_base.position = joystick_center - joystick_base.size * 0.5
    joystick_base.modulate = Color(1.0, 1.0, 1.0, 0.72)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mobile_controls.add_child(joystick_base)

    joystick_knob = TextureRect.new()
    joystick_knob.name = "VirtualJoystickKnob"
    joystick_knob.texture = pressed_touch_texture
    joystick_knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    joystick_knob.stretch_mode = TextureRect.STRETCH_SCALE
    joystick_knob.size = Vector2(58.0, 58.0)
    joystick_knob.position = joystick_center - joystick_knob.size * 0.5
    joystick_knob.modulate = Color(1.0, 1.0, 1.0, 0.92)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mobile_controls.add_child(joystick_knob)

func _update_virtual_joystick(pointer_position: Vector2) -> void:
    var offset := pointer_position - joystick_center
    var radius := 52.0
    if offset.length() > radius:
        offset = offset.normalized() * radius
    joystick_vector = offset / radius
    if joystick_knob:
        joystick_knob.position = joystick_center + offset - joystick_knob.size * 0.5

func _reset_virtual_joystick() -> void:
    joystick_touch_index = -1
    joystick_vector = Vector2.ZERO
    if joystick_knob:
        joystick_knob.position = joystick_center - joystick_knob.size * 0.5

func _make_touch_texture(fill_color: Color) -> Texture2D:
    var image := Image.create(112, 112, false, Image.FORMAT_RGBA8)
    var edge_color := Color(0.86, 0.92, 0.82, 0.92)
    for y in range(112):
        for x in range(112):
            var distance := Vector2(float(x) - 55.5, float(y) - 55.5).length()
            if distance <= 53.0:
                image.set_pixel(x, y, edge_color if distance >= 48.0 else fill_color)
    return ImageTexture.create_from_image(image)

func _add_control_button(label_text: String, center: Vector2, action: String, is_action_button := false) -> void:
    var button := TouchScreenButton.new()
    button.name = "Touch_%s" % action
    button.position = center
    button.scale = Vector2.ONE * control_scale
    var hit_shape := CircleShape2D.new()
    hit_shape.radius = (53.0 if is_action_button else 47.0)
    button.shape = hit_shape
    button.texture_normal = normal_touch_texture
    button.texture_pressed = pressed_touch_texture
    button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
    button.pressed.connect(_on_control_pressed.bind(action))
    button.released.connect(_on_control_released.bind(action))
    touch_button_layer.add_child(button)
    action_buttons[action] = button

    var caption := Label.new()
    caption.text = label_text
    caption.position = center - Vector2(42, 20) * control_scale
    caption.size = Vector2(84, 40) * control_scale
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    caption.add_theme_color_override("font_color", Color(0.98, 1.0, 0.94))
    caption.add_theme_font_size_override("font_size", roundi((14 if is_action_button else 27) * control_scale))
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mobile_controls.add_child(caption)
    action_captions[action] = caption

func _move_action_button(action: String, center: Vector2) -> void:
    if not action_buttons.has(action) or not action_captions.has(action):
        return
    var screen_size := get_viewport().get_visible_rect().size
    var safe_center := Vector2(
        clampf(center.x, 58.0 * control_scale, screen_size.x - 58.0 * control_scale),
        clampf(center.y, 58.0 * control_scale, screen_size.y - 58.0 * control_scale)
    )
    var button: TouchScreenButton = action_buttons[action]
    var caption: Label = action_captions[action]
    button.position = safe_center
    caption.position = safe_center - Vector2(42.0, 20.0) * control_scale

func _action_button_at(pointer_position: Vector2) -> String:
    for action in action_buttons:
        var button: TouchScreenButton = action_buttons[action]
        if pointer_position.distance_to(button.position) <= 64.0 * control_scale:
            return str(action)
    return ""

func _set_control_layout_edit(enabled: bool) -> void:
    control_layout_edit_mode = enabled
    layout_drag_action = ""
    layout_touch_index = -1
    pressed_actions.clear()
    if layout_status_label:
        layout_status_label.text = "Drag buttons to move them. Tap Done when finished." if enabled else "Touch layout saved."
    if joystick_base:
        joystick_base.modulate = Color(1.0, 0.8, 0.35, 0.92) if enabled else Color(1.0, 1.0, 1.0, 0.72)

func _reset_control_layout() -> void:
    var screen_size := get_viewport().get_visible_rect().size
    _move_action_button("interact", Vector2(screen_size.x * 0.75, screen_size.y * 0.70))
    _move_action_button("build", Vector2(screen_size.x * 0.88, screen_size.y * 0.70))
    _move_action_button("run", Vector2(screen_size.x * 0.75, screen_size.y * 0.86))
    _move_action_button("jump", Vector2(screen_size.x * 0.88, screen_size.y * 0.86))
    _save_game()
    if layout_status_label:
        layout_status_label.text = "Default touch layout restored."

func _on_control_pressed(action: String) -> void:
    if control_layout_edit_mode:
        return
    if action == "build":
        if build_panel:
            build_panel.visible = not build_panel.visible
            _update_inventory_ui()
        return
    if action == "interact":
        _try_interact()
        return
    pressed_actions[action] = true

func _on_control_released(action: String) -> void:
    pressed_actions.erase(action)

func _create_minimap(layer: CanvasLayer) -> void:
    var map_image := Image.create(192, 192, false, Image.FORMAT_RGBA8)
    for y in range(192):
        for x in range(192):
            var world_x := (float(x) / 191.0 - 0.5) * WORLD_SIZE
            var world_z := (float(y) / 191.0 - 0.5) * WORLD_SIZE
            var pixel_color := Color(0.20, 0.39, 0.18)
            if world_x > 125.0:
                pixel_color = Color(0.66, 0.53, 0.31)
            if world_z < -125.0:
                pixel_color = Color(0.76, 0.82, 0.83)
            var river_center := sin(world_z * 0.018) * 18.0
            if absf(world_x - river_center) < 5.0:
                pixel_color = Color(0.10, 0.40, 0.58)
            map_image.set_pixel(x, y, pixel_color)

    var map_texture := ImageTexture.create_from_image(map_image)
    minimap_panel = PanelContainer.new()
    minimap_panel.name = "WorldMinimap"
    minimap_panel.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 96.0, 58.0)
    minimap_panel.custom_minimum_size = Vector2(192.0, 218.0)
    layer.add_child(minimap_panel)

    var map_column := VBoxContainer.new()
    map_column.add_theme_constant_override("separation", 3)
    minimap_panel.add_child(map_column)

    var header := HBoxContainer.new()
    map_column.add_child(header)

    var title := Label.new()
    title.text = "WORLD MAP"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 14)
    header.add_child(title)

    minimap_region_label = Label.new()
    minimap_region_label.text = "Green Valley"
    minimap_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    minimap_region_label.add_theme_font_size_override("font_size", 12)
    map_column.add_child(minimap_region_label)

    var map_frame := Control.new()
    map_frame.custom_minimum_size = Vector2(minimap_size, minimap_size)
    map_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    map_column.add_child(map_frame)

    minimap_background = TextureRect.new()
    minimap_background.texture = map_texture
    minimap_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    minimap_background.stretch_mode = TextureRect.STRETCH_SCALE
    minimap_background.size = Vector2(minimap_size, minimap_size)
    map_frame.add_child(minimap_background)

    var border := ReferenceRect.new()
    border.border_color = Color(0.85, 0.89, 0.79, 0.85)
    border.editor_only = false
    border.mouse_filter = Control.MOUSE_FILTER_IGNORE
    border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    map_frame.add_child(border)

    minimap_marker = Polygon2D.new()
    minimap_marker.name = "PlayerMapArrow"
    minimap_marker.polygon = PackedVector2Array([
        Vector2(0.0, -7.0),
        Vector2(5.5, 6.0),
        Vector2(0.0, 3.2),
        Vector2(-5.5, 6.0)
    ])
    minimap_marker.color = Color(1.0, 0.93, 0.54)
    minimap_marker.position = Vector2(minimap_size * 0.5, minimap_size * 0.5)
    minimap_background.add_child(minimap_marker)

    minimap_toggle_button = Button.new()
    minimap_toggle_button.name = "ToggleWorldMap"
    minimap_toggle_button.text = "MAP  •  HIDE"
    minimap_toggle_button.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 72.0, 18.0)
    minimap_toggle_button.custom_minimum_size = Vector2(144.0, 34.0)
    minimap_toggle_button.pressed.connect(_toggle_minimap)
    layer.add_child(minimap_toggle_button)
    _update_minimap()

func _toggle_minimap() -> void:
    if not minimap_panel:
        return
    minimap_panel.visible = not minimap_panel.visible
    if minimap_toggle_button:
        minimap_toggle_button.text = "MAP  •  HIDE" if minimap_panel.visible else "MAP  •  SHOW"

func _update_minimap() -> void:
    if not player or not minimap_marker:
        return
    var half_world := WORLD_SIZE * 0.5
    var normalized_x := clampf((player.global_position.x + half_world) / WORLD_SIZE, 0.0, 1.0)
    var normalized_z := clampf((player.global_position.z + half_world) / WORLD_SIZE, 0.0, 1.0)
    minimap_marker.position = Vector2(normalized_x * minimap_size, normalized_z * minimap_size)
    minimap_marker.rotation = player.rotation.y
    if minimap_region_label:
        if player.global_position.x > 125.0:
            minimap_region_label.text = "Eastern Dunes"
        elif player.global_position.z < -125.0:
            minimap_region_label.text = "Northern Highlands"
        else:
            minimap_region_label.text = "Green Valley"

func _create_network_panel(layer: CanvasLayer) -> void:
    var screen_size := get_viewport().get_visible_rect().size
    network_panel = PanelContainer.new()
    network_panel.name = "LANPanel"
    network_panel.position = Vector2(screen_size.x - 330.0, 18.0)
    network_panel.custom_minimum_size = Vector2(310.0, 0.0)
    layer.add_child(network_panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    network_panel.add_child(column)

    var title := Label.new()
    title.text = "WORLDS  •  PLAY TOGETHER"
    title.add_theme_color_override("font_color", Color(0.75, 0.92, 0.78))
    title.add_theme_font_size_override("font_size", 17)
    column.add_child(title)

    var host_button := Button.new()
    host_button.text = "CREATE WORLD"
    host_button.custom_minimum_size.y = 40
    host_button.pressed.connect(_host_lan_game)
    column.add_child(host_button)

    host_ip_label = Label.new()
    host_ip_label.text = "Your Wi-Fi IP will appear here"
    host_ip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(host_ip_label)

    address_input = LineEdit.new()
    address_input.placeholder_text = "Enter your brother's IP"
    address_input.virtual_keyboard_enabled = true
    address_input.clear_button_enabled = true
    column.add_child(address_input)

    var join_button := Button.new()
    join_button.text = "JOIN WORLD"
    join_button.custom_minimum_size.y = 40
    join_button.pressed.connect(_join_lan_game)
    column.add_child(join_button)

    var leave_button := Button.new()
    leave_button.text = "LEAVE SESSION"
    leave_button.pressed.connect(_disconnect_lan_game)
    column.add_child(leave_button)

    network_status_label = Label.new()
    network_status_label.text = "Offline • Both phones must use the same Wi-Fi"
    network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(network_status_label)

func _create_settings_panel(layer: CanvasLayer) -> void:
    var screen_size := get_viewport().get_visible_rect().size
    settings_panel = PanelContainer.new()
    settings_panel.name = "PerformancePanel"
    settings_panel.position = Vector2(screen_size.x - 330.0, maxf(120.0, screen_size.y - 390.0))
    settings_panel.custom_minimum_size = Vector2(310.0, 360.0)
    layer.add_child(settings_panel)

    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(310.0, 350.0)
    settings_panel.add_child(scroll)

    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 4)
    scroll.add_child(column)

    var title := Label.new()
    title.text = "DEVICE PERFORMANCE"
    title.add_theme_font_size_override("font_size", 15)
    column.add_child(title)

    var quality_row := HBoxContainer.new()
    var quality_label := Label.new()
    quality_label.text = "Quality"
    quality_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    quality_row.add_child(quality_label)

    quality_option = OptionButton.new()
    quality_option.add_item("Auto", 0)
    quality_option.add_item("Low", 1)
    quality_option.add_item("Balanced", 2)
    quality_option.add_item("High", 3)
    quality_option.add_item("Ultra", 4)
    quality_option.select(0)
    quality_option.item_selected.connect(_on_quality_selected)
    quality_row.add_child(quality_option)
    column.add_child(quality_row)

    var fps_row := HBoxContainer.new()
    var fps_text := Label.new()
    fps_text.text = "FPS limit"
    fps_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fps_row.add_child(fps_text)

    fps_option = OptionButton.new()
    for fps_value in [20, 30, 45, 60, 90, 120]:
        fps_option.add_item("%d FPS" % fps_value, fps_value)
    fps_option.select(3)
    fps_option.item_selected.connect(_on_fps_selected)
    fps_row.add_child(fps_option)
    column.add_child(fps_row)

    fps_label = Label.new()
    fps_label.text = "Actual FPS depends on the device and scene load."
    fps_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(fps_label)

    metrics_label = Label.new()
    metrics_label.text = "Live: waiting for frame sample..."
    metrics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(metrics_label)

    var sensitivity_label := Label.new()
    sensitivity_label.text = "Camera sensitivity"
    column.add_child(sensitivity_label)
    camera_sensitivity_slider = HSlider.new()
    camera_sensitivity_slider.min_value = 0.003
    camera_sensitivity_slider.max_value = 0.012
    camera_sensitivity_slider.step = 0.001
    camera_sensitivity_slider.value = camera_sensitivity
    camera_sensitivity_slider.value_changed.connect(_on_camera_sensitivity_changed)
    column.add_child(camera_sensitivity_slider)

    var camera_distance_label := Label.new()
    camera_distance_label.text = "Camera distance"
    column.add_child(camera_distance_label)
    camera_distance_slider = HSlider.new()
    camera_distance_slider.min_value = 4.0
    camera_distance_slider.max_value = 12.0
    camera_distance_slider.step = 0.5
    camera_distance_slider.value = camera_distance
    camera_distance_slider.value_changed.connect(_on_camera_distance_changed)
    column.add_child(camera_distance_slider)

    var fov_label := Label.new()
    fov_label.text = "Camera field of view"
    column.add_child(fov_label)
    camera_fov_slider = HSlider.new()
    camera_fov_slider.min_value = 55.0
    camera_fov_slider.max_value = 85.0
    camera_fov_slider.step = 1.0
    camera_fov_slider.value = camera_fov
    camera_fov_slider.value_changed.connect(_on_camera_fov_changed)
    column.add_child(camera_fov_slider)

    var scale_label := Label.new()
    scale_label.text = "Touch button size"
    column.add_child(scale_label)
    control_scale_slider = HSlider.new()
    control_scale_slider.min_value = 0.75
    control_scale_slider.max_value = 1.35
    control_scale_slider.step = 0.05
    control_scale_slider.value = control_scale
    control_scale_slider.value_changed.connect(_on_control_scale_changed)
    column.add_child(control_scale_slider)

    var opacity_label := Label.new()
    opacity_label.text = "Touch button opacity"
    column.add_child(opacity_label)
    button_opacity_slider = HSlider.new()
    button_opacity_slider.min_value = 0.4
    button_opacity_slider.max_value = 1.0
    button_opacity_slider.step = 0.05
    button_opacity_slider.value = button_opacity
    button_opacity_slider.value_changed.connect(_on_button_opacity_changed)
    column.add_child(button_opacity_slider)

    var layout_button := Button.new()
    layout_button.text = "EDIT TOUCH BUTTONS"
    layout_button.pressed.connect(_set_control_layout_edit.bind(true))
    column.add_child(layout_button)

    var done_layout_button := Button.new()
    done_layout_button.text = "DONE / SAVE LAYOUT"
    done_layout_button.pressed.connect(_finish_control_layout_edit)
    column.add_child(done_layout_button)

    var reset_layout_button := Button.new()
    reset_layout_button.text = "RESET BUTTON POSITIONS"
    reset_layout_button.pressed.connect(_reset_control_layout)
    column.add_child(reset_layout_button)

    layout_status_label = Label.new()
    layout_status_label.text = "Move buttons and save your layout."
    layout_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(layout_status_label)

func _on_camera_sensitivity_changed(value: float) -> void:
    camera_sensitivity = clampf(value, 0.003, 0.012)

func _sync_settings_sliders() -> void:
    if camera_sensitivity_slider:
        camera_sensitivity_slider.value = camera_sensitivity
    if camera_distance_slider:
        camera_distance_slider.value = camera_distance
    if camera_fov_slider:
        camera_fov_slider.value = camera_fov
    if control_scale_slider:
        control_scale_slider.value = control_scale
    if button_opacity_slider:
        button_opacity_slider.value = button_opacity

func _on_camera_distance_changed(value: float) -> void:
    camera_distance = clampf(value, 4.0, 12.0)
    if camera:
        camera.position = Vector3(0.0, camera_distance * 0.4, camera_distance)

func _on_camera_fov_changed(value: float) -> void:
    camera_fov = clampf(value, 55.0, 85.0)
    if camera:
        camera.fov = camera_fov

func _on_button_opacity_changed(value: float) -> void:
    button_opacity = clampf(value, 0.4, 1.0)
    for action in action_buttons:
        var button: TouchScreenButton = action_buttons[action]
        button.modulate = Color(1.0, 1.0, 1.0, button_opacity)

func _on_control_scale_changed(value: float) -> void:
    control_scale = clampf(value, 0.75, 1.35)
    for action in action_buttons:
        var button: TouchScreenButton = action_buttons[action]
        var caption: Label = action_captions[action]
        button.scale = Vector2.ONE * control_scale
        var shape := CircleShape2D.new()
        shape.radius = 53.0 if str(action) in ["interact", "jump", "run", "build"] else 47.0
        button.shape = shape
        caption.position = button.position - Vector2(42.0, 20.0) * control_scale
        caption.size = Vector2(84.0, 40.0) * control_scale
    for action in action_captions:
        var caption: Label = action_captions[action]
        caption.add_theme_font_size_override("font_size", roundi((14 if str(action) in ["interact", "jump", "run", "build"] else 27) * control_scale))

func _finish_control_layout_edit() -> void:
    _set_control_layout_edit(false)
    _save_game()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E:
            _try_interact()
        elif event.keycode == KEY_SHIFT:
            pressed_actions["run"] = true
    elif event is InputEventKey and not event.pressed and event.keycode == KEY_SHIFT:
        pressed_actions.erase("run")
    elif event is InputEventScreenTouch:
        if control_layout_edit_mode:
            if event.pressed:
                var action := _action_button_at(event.position)
                if action != "":
                    layout_drag_action = action
                    layout_touch_index = event.index
                    get_viewport().set_input_as_handled()
            elif event.index == layout_touch_index:
                layout_drag_action = ""
                layout_touch_index = -1
                _save_game()
                get_viewport().set_input_as_handled()
        elif event.pressed and joystick_touch_index == -1 and event.position.distance_to(joystick_center) <= 82.0:
            joystick_touch_index = event.index
            _update_virtual_joystick(event.position)
            get_viewport().set_input_as_handled()
        elif not event.pressed and event.index == joystick_touch_index:
            _reset_virtual_joystick()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        if control_layout_edit_mode and event.index == layout_touch_index and layout_drag_action != "":
            _move_action_button(layout_drag_action, event.position)
            get_viewport().set_input_as_handled()
        elif event.index == joystick_touch_index:
            _update_virtual_joystick(event.position)
            get_viewport().set_input_as_handled()
        else:
            _rotate_camera(event.relative, event.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _rotate_camera(event.relative, event.position)

func _rotate_camera(relative: Vector2, pointer_position: Vector2) -> void:
    if not camera or not camera_pivot:
        return
    if network_panel and network_panel.get_global_rect().has_point(pointer_position):
        return
    if settings_panel and settings_panel.get_global_rect().has_point(pointer_position):
        return

    var screen_size := get_viewport().get_visible_rect().size
    # Keep the lower control area free for movement and jump buttons.
    if pointer_position.y > screen_size.y - 185.0:
        return
    if pointer_position.x < screen_size.x * 0.40:
        return

    camera_pivot.rotation.y -= relative.x * camera_sensitivity
    camera.rotation.x = clamp(
        camera.rotation.x - relative.y * camera_sensitivity,
        deg_to_rad(-38.0),
        deg_to_rad(-5.0)
    )

func _process(delta: float) -> void:
    _update_day_cycle(delta)
    _update_survival(delta)
    _update_network(delta)
    _update_remote_players(delta)
    _update_build_preview()
    _update_wildlife(delta)
    _update_village_agents(delta)
    _update_adaptive_quality(delta)
    metrics_refresh_timer += delta
    if minimap_marker and player:
        _update_minimap()
    if metrics_refresh_timer >= 0.75 and metrics_label:
        metrics_refresh_timer = 0.0
        var current_fps := Engine.get_frames_per_second()
        var frame_time_ms := 1000.0 / maxf(1.0, float(current_fps))
        var current_memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
        metrics_label.text = "Live  •  %d FPS  •  %.1f ms/frame  •  %.0f MB process memory  •  cap %d" % [
            current_fps,
            frame_time_ms,
            current_memory_mb,
            current_fps_target
        ]
    save_elapsed += delta
    if save_elapsed >= 15.0:
        _save_game()
    if status_note_time > 0.0:
        status_note_time = maxf(0.0, status_note_time - delta)
    hud_refresh_timer += delta
    if hud_refresh_timer >= 0.2 and hud_label and player:
        hud_refresh_timer = 0.0
        var hours := int(world_clock)
        var minutes := int((world_clock - float(hours)) * 60.0)
        var time_text := "%02d:%02d" % [hours, minutes]
        var prompt := _get_interaction_prompt()
        var note := status_note if status_note_time > 0.0 else prompt
        hud_label.text = "WORLDS  •  %s  |  HP %d%%\nFood %d%%   Water %d%%   Rest %d%%\n%s" % [
            time_text,
            roundi(health),
            roundi(hunger),
            roundi(thirst),
            roundi(rest),
            note
        ]
        if health_bar:
            health_bar.value = health


func _nearest_interaction_for(position: Vector3) -> Dictionary:
    var best_distance := INF
    var result := {"action": "", "index": -1}

    var river_center := sin(position.z * 0.018) * 18.0
    var river_distance: float = absf(position.x - river_center)
    if river_distance < 5.5 and absf(position.z) < WORLD_SIZE * 0.5:
        best_distance = river_distance
        result["action"] = "drink"

    for index in range(berry_bushes.size()):
        var bush: Dictionary = berry_bushes[index]
        if int(bush["servings"]) <= 0:
            continue
        var bush_position: Vector3 = bush["position"]
        var distance := Vector2(position.x - bush_position.x, position.z - bush_position.z).length()
        if distance < 3.8 and distance < best_distance:
            best_distance = distance
            result["action"] = "forage"
            result["index"] = index

    for index in range(resource_nodes.size()):
        var resource: Dictionary = resource_nodes[index]
        if int(resource["amount"]) <= 0:
            continue
        var resource_position: Vector3 = resource["position"]
        var resource_distance := Vector2(position.x - resource_position.x, position.z - resource_position.z).length()
        if resource_distance < 3.7 and resource_distance < best_distance:
            best_distance = resource_distance
            result["action"] = "gather"
            result["index"] = index

    if not memory_awakened:
        var memory_distance := Vector2(position.x - memory_position.x, position.z - memory_position.z).length()
        if memory_distance < 4.5 and memory_distance < best_distance:
            best_distance = memory_distance
            result["action"] = "memory"
            result["index"] = -1

    var camp_distance := Vector2(position.x - camp_position.x, position.z - camp_position.z).length()
    if camp_distance < 4.5 and camp_distance < best_distance:
        result["action"] = "sleep"
        result["index"] = -1

    return result

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_interaction() -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    if not network_remote_players.has(sender):
        return
    var remote_avatar: Node3D = network_remote_players[sender]
    if not is_instance_valid(remote_avatar):
        return

    var nearby := _nearest_interaction_for(remote_avatar.global_position)
    var action: String = nearby["action"]
    print("LAN_SMOKE_HOST_INTERACTION  •  sender %d  •  position %s  •  action %s  •  index %d" % [sender, str(remote_avatar.global_position), action, int(nearby["index"])])
    match action:
        "drink":
            rpc_id(sender, "_rpc_apply_personal_interaction", "drink")
        "forage":
            var bush_index := int(nearby["index"])
            var bush: Dictionary = berry_bushes[bush_index]
            var remaining := maxi(0, int(bush["servings"]) - 1)
            bush["servings"] = remaining
            berry_bushes[bush_index] = bush
            rpc("_rpc_set_berry_servings", bush_index, remaining)
            rpc_id(sender, "_rpc_apply_personal_interaction", "forage")
        "gather":
            _server_gather_resource(int(nearby["index"]), sender)
        "sleep":
            world_clock = 7.0
            rpc("_rpc_set_shared_clock", world_clock)
            rpc_id(sender, "_rpc_apply_personal_interaction", "sleep")
        "memory":
            _apply_world_memory()
            rpc("_rpc_world_memory_activated")
        _:
            rpc_id(sender, "_rpc_apply_personal_interaction", "nothing")

@rpc("authority", "call_remote", "reliable")
func _rpc_apply_personal_interaction(action: String) -> void:
    match action:
        "drink":
            thirst = minf(100.0, thirst + 42.0)
            health = minf(100.0, health + 3.0)
            _show_status_note("You drank water from the river.")
        "forage":
            hunger = minf(100.0, hunger + 34.0)
            health = minf(100.0, health + 4.0)
            _show_status_note("You gathered wild berries.")
        "sleep":
            rest = 100.0
            hunger = maxf(0.0, hunger - 7.0)
            thirst = maxf(0.0, thirst - 10.0)
            health = minf(100.0, health + 12.0)
            _show_status_note("You rested at the campsite.")
        _:
            _show_status_note("Nothing nearby to use.")

func _set_resource_amount_local(index: int, amount: int) -> void:
    if index < 0 or index >= resource_nodes.size():
        return
    var resource: Dictionary = resource_nodes[index]
    var safe_amount := clampi(amount, 0, 10)
    resource["amount"] = safe_amount
    resource_nodes[index] = resource
    var visual: Node3D = resource["visual"]
    if is_instance_valid(visual):
        visual.visible = safe_amount > 0

func _server_gather_resource(index: int, requester_id: int) -> void:
    if index < 0 or index >= resource_nodes.size():
        return
    var resource: Dictionary = resource_nodes[index]
    var actor_position := player.global_position
    if lan_active and multiplayer.is_server() and requester_id > 1:
        if not network_remote_players.has(requester_id):
            return
        var remote_avatar: Node3D = network_remote_players[requester_id]
        if not is_instance_valid(remote_avatar):
            return
        actor_position = remote_avatar.global_position
    var resource_position: Vector3 = resource["position"]
    if Vector2(actor_position.x - resource_position.x, actor_position.z - resource_position.z).length() > 3.7:
        return
    var remaining := int(resource["amount"])
    if remaining <= 0:
        return
    var kind: String = resource["kind"]
    if OS.get_cmdline_user_args().has("--lan-smoke-host"):
        print("LAN_SMOKE_HOST_GATHER  •  requester %d  •  resource %d  •  kind %s  •  before %d" % [requester_id, index, kind, remaining])
    if not shared_inventory.has(kind):
        return

    remaining -= 1
    _set_resource_amount_local(index, remaining)
    shared_inventory[kind] = int(shared_inventory[kind]) + 1
    _update_inventory_ui()
    _show_status_note("Collected 1 %s. Shared supplies increased." % kind)

    if lan_active and multiplayer.is_server():
        rpc("_rpc_set_resource_amount", index, remaining)
        rpc("_rpc_set_shared_inventory", shared_inventory)
    _save_game()

@rpc("authority", "call_remote", "reliable")
func _rpc_set_resource_amount(index: int, amount: int) -> void:
    _set_resource_amount_local(index, amount)

@rpc("authority", "call_remote", "reliable")
func _rpc_set_shared_inventory(inventory: Dictionary) -> void:
    for key in ["wood", "stone", "fiber"]:
        shared_inventory[key] = maxi(0, int(inventory.get(key, 0)))
    _update_inventory_ui()
    _show_status_note("Shared supplies synchronized.")

@rpc("authority", "call_remote", "reliable")
func _rpc_set_berry_servings(index: int, servings: int) -> void:
    if index < 0 or index >= berry_bushes.size():
        return
    var bush: Dictionary = berry_bushes[index]
    bush["servings"] = clampi(servings, 0, 3)
    berry_bushes[index] = bush

@rpc("authority", "call_remote", "reliable")
func _rpc_set_shared_clock(new_clock: float) -> void:
    world_clock = fposmod(new_clock, 24.0)

@rpc("authority", "call_remote", "reliable")
func _rpc_world_memory_activated() -> void:
    _apply_world_memory()

func _broadcast_shared_world_state() -> void:
    if not lan_active or not multiplayer.is_server():
        return
    rpc("_rpc_set_shared_clock", world_clock)
    for index in range(berry_bushes.size()):
        var bush: Dictionary = berry_bushes[index]
        rpc("_rpc_set_berry_servings", index, int(bush["servings"]))
    rpc("_rpc_set_shared_inventory", shared_inventory)
    for index in range(resource_nodes.size()):
        var resource: Dictionary = resource_nodes[index]
        rpc("_rpc_set_resource_amount", index, int(resource["amount"]))

func _update_survival(delta: float) -> void:
    # Needs decline slowly so exploration stays relaxed rather than punishing.
    hunger = maxf(0.0, hunger - delta * 0.012)
    thirst = maxf(0.0, thirst - delta * 0.022)
    rest = maxf(0.0, rest - delta * 0.016)

    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - delta * 0.18)
    elif hunger >= 80.0 and thirst >= 80.0 and rest >= 45.0:
        health = minf(100.0, health + delta * 0.08)

    if health <= 0.0 and player:
        player.global_position = camp_position + Vector3(0.0, 1.3, 0.0)
        player.velocity = Vector3.ZERO
        health = 65.0
        hunger = maxf(hunger, 55.0)
        thirst = maxf(thirst, 55.0)
        rest = maxf(rest, 45.0)
        _show_status_note("You recovered at the campsite. Take supplies before leaving.")
        _save_game()

func _get_interaction_prompt() -> String:
    match _nearest_interaction():
        "drink":
            return "USE / E: Drink from the river"
        "forage":
            return "USE / E: Gather wild berries"
        "gather":
            var nearby := _nearest_interaction_for(player.global_position)
            var resource_index := int(nearby.get("index", -1))
            if resource_index >= 0 and resource_index < resource_nodes.size():
                return "USE / E: Collect %s" % str(resource_nodes[resource_index]["kind"])
            return "USE / E: Gather materials"
        "sleep":
            return "USE / E: Rest at the campsite"
        "memory":
            return "USE / E: Listen to the world's memory"
        _:
            if memory_awakened:
                return "Explore the valley and follow the glowing memory trail"
            return "Explore the valley"

func _nearest_interaction() -> String:
    if not player:
        return ""
    var nearby := _nearest_interaction_for(player.global_position)
    return str(nearby.get("action", ""))

func _try_interact() -> void:
    if lan_active and not multiplayer.is_server():
        rpc_id(1, "_rpc_request_interaction")
        return

    match _nearest_interaction():
        "drink":
            thirst = minf(100.0, thirst + 42.0)
            health = minf(100.0, health + 3.0)
            _show_status_note("You drank fresh water.")
        "gather":
            var nearest_resource := _nearest_interaction_for(player.global_position)
            _server_gather_resource(int(nearest_resource.get("index", -1)), 1)
        "forage":
            var nearest_index := -1
            var nearest_distance := INF
            for i in range(berry_bushes.size()):
                var bush: Dictionary = berry_bushes[i]
                if int(bush["servings"]) <= 0:
                    continue
                var bush_position: Vector3 = bush["position"]
                var distance := Vector2(
                    player.position.x - bush_position.x,
                    player.position.z - bush_position.z
                ).length()
                if distance < nearest_distance:
                    nearest_distance = distance
                    nearest_index = i
            if nearest_index >= 0:
                var selected: Dictionary = berry_bushes[nearest_index]
                selected["servings"] = int(selected["servings"]) - 1
                berry_bushes[nearest_index] = selected
                hunger = minf(100.0, hunger + 34.0)
                health = minf(100.0, health + 4.0)
                _show_status_note("You gathered and ate wild berries.")
        "sleep":
            world_clock = 7.0
            rest = 100.0
            hunger = maxf(0.0, hunger - 7.0)
            thirst = maxf(0.0, thirst - 10.0)
            health = minf(100.0, health + 12.0)
            _show_status_note("You rested at the campsite until morning.")
        "memory":
            _awaken_world_memory()
        _:
            _show_status_note("Nothing nearby to use.")

    if lan_active and multiplayer.is_server():
        _broadcast_shared_world_state()

func _show_status_note(message: String) -> void:
    status_note = message
    status_note_time = 3.5

func _create_foraging_bushes() -> void:
    var locations := [
        Vector2(-17.0, -14.0),
        Vector2(31.0, 14.0),
        Vector2(-37.0, 29.0),
        Vector2(39.0, -34.0)
    ]
    for location in locations:
        var bush_position := Vector3(
            location.x,
            _height_at(location.x, location.y),
            location.y
        )
        berry_bushes.append({
            "position": bush_position,
            "servings": 3
        })

        var shrub := MeshInstance3D.new()
        var shrub_mesh := SphereMesh.new()
        shrub_mesh.radius = 0.72
        shrub_mesh.height = 0.95
        shrub.mesh = shrub_mesh
        shrub.position = bush_position + Vector3(0, 0.55, 0)
        var shrub_material := StandardMaterial3D.new()
        shrub_material.albedo_color = Color(0.13, 0.29, 0.12)
        shrub_material.roughness = 1.0
        shrub.material_override = shrub_material
        add_child(shrub)

        for berry_index in range(5):
            var berry := MeshInstance3D.new()
            var berry_mesh := SphereMesh.new()
            berry_mesh.radius = 0.12
            berry_mesh.height = 0.18
            berry.mesh = berry_mesh
            var angle := TAU * float(berry_index) / 5.0
            berry.position = bush_position + Vector3(
                cos(angle) * 0.48,
                0.72 + float(berry_index % 2) * 0.18,
                sin(angle) * 0.48
            )
            var berry_material := StandardMaterial3D.new()
            berry_material.albedo_color = Color(0.68, 0.12, 0.16)
            berry_material.roughness = 0.7
            berry.material_override = berry_material
            add_child(berry)

func _get_build_recipe(build_type: String) -> Dictionary:
    match build_type:
        "campfire":
            return {"wood": 3, "stone": 2, "fiber": 0}
        "storage":
            return {"wood": 5, "stone": 2, "fiber": 0}
        "shelter":
            return {"wood": 12, "stone": 4, "fiber": 6}
        _:
            return {}

func _request_build(build_type: String) -> void:
    if not player:
        return
    if lan_active and not multiplayer.is_server():
        rpc_id(1, "_rpc_request_place_building", build_type, build_rotation_offset)
        _show_status_note("Requesting a place from the host...")
        return
    _server_place_building(build_type, player.global_position, player.rotation.y, build_rotation_offset)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_place_building(build_type: String, rotation_offset: float) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    if not network_remote_players.has(sender):
        return
    var avatar: Node3D = network_remote_players[sender]
    if not is_instance_valid(avatar):
        return
    _server_place_building(build_type, avatar.global_position, avatar.rotation.y, rotation_offset)

func _server_place_building(build_type: String, actor_position: Vector3, actor_facing: float, rotation_offset := 0.0) -> void:
    var recipe := _get_build_recipe(build_type)
    if recipe.is_empty():
        _show_status_note("Unknown building plan.")
        return

    for key in recipe:
        if int(shared_inventory.get(key, 0)) < int(recipe[key]):
            _show_status_note("Not enough materials for this structure.")
            return

    var facing := actor_facing + clampf(rotation_offset, -TAU, TAU)
    var forward := Vector3(sin(facing), 0.0, -cos(facing))
    var placement := actor_position + forward * 4.0
    placement.x = clampf(placement.x, -WORLD_SIZE * 0.47, WORLD_SIZE * 0.47)
    placement.z = clampf(placement.z, -WORLD_SIZE * 0.47, WORLD_SIZE * 0.47)
    var river_center := sin(placement.z * 0.018) * 18.0
    if absf(placement.x - river_center) < 9.0:
        _show_status_note("Choose a dry place away from the river.")
        return
    if Vector2(placement.x, placement.z).distance_to(Vector2(camp_position.x, camp_position.z)) < 3.2:
        _show_status_note("Move a little farther from the starting campsite.")
        return
    for building in placed_buildings:
        var other: Vector3 = building["position"]
        if Vector2(placement.x, placement.z).distance_to(Vector2(other.x, other.z)) < 3.4:
            _show_status_note("There is already a structure too close.")
            return

    placement.y = _height_at(placement.x, placement.z)
    for key in recipe:
        shared_inventory[key] = int(shared_inventory.get(key, 0)) - int(recipe[key])

    _spawn_building_visual(build_type, placement, facing, true)
    _update_inventory_ui()
    _show_status_note("Structure placed. The shared world has changed.")
    if lan_active and multiplayer.is_server():
        rpc("_rpc_set_shared_inventory", shared_inventory)
        rpc("_rpc_spawn_building", build_type, placement, facing)
    _save_game()

func _spawn_building_visual(build_type: String, position: Vector3, facing: float, record: bool) -> void:
    var root := Node3D.new()
    root.name = "Built_%s_%02d" % [build_type, placed_buildings.size()]
    root.position = position
    root.rotation.y = facing
    add_child(root)

    match build_type:
        "campfire":
            for i in range(3):
                var log := MeshInstance3D.new()
                var log_mesh := CylinderMesh.new()
                log_mesh.top_radius = 0.13
                log_mesh.bottom_radius = 0.13
                log_mesh.height = 1.2
                log.mesh = log_mesh
                log.position = Vector3(cos(float(i) * TAU / 3.0) * 0.22, 0.14, sin(float(i) * TAU / 3.0) * 0.22)
                log.rotation.z = PI * 0.5
                log.material_override = _build_material(Color(0.30, 0.18, 0.10))
                root.add_child(log)
            var flame := MeshInstance3D.new()
            var flame_mesh := SphereMesh.new()
            flame_mesh.radius = 0.30
            flame_mesh.height = 0.70
            flame.mesh = flame_mesh
            flame.position.y = 0.42
            flame.material_override = _build_material(Color(1.0, 0.22, 0.035), true)
            root.add_child(flame)
            var light := OmniLight3D.new()
            light.position.y = 0.85
            light.light_color = Color(1.0, 0.38, 0.12)
            light.light_energy = 0.7
            light.omni_range = 6.0
            root.add_child(light)
        "storage":
            var box := MeshInstance3D.new()
            var box_mesh := BoxMesh.new()
            box_mesh.size = Vector3(1.35, 0.92, 1.05)
            box.mesh = box_mesh
            box.position.y = 0.48
            box.material_override = _build_material(Color(0.38, 0.23, 0.12))
            root.add_child(box)
            var lid := MeshInstance3D.new()
            var lid_mesh := BoxMesh.new()
            lid_mesh.size = Vector3(1.42, 0.16, 1.12)
            lid.mesh = lid_mesh
            lid.position.y = 1.02
            lid.material_override = _build_material(Color(0.25, 0.15, 0.09))
            root.add_child(lid)
            _add_building_collision(root, Vector3(1.4, 1.0, 1.1), Vector3(0.0, 0.5, 0.0))
        "shelter":
            var wood_material := _build_material(Color(0.34, 0.22, 0.13))
            for x in [-1.7, 1.7]:
                for z in [-1.45, 1.45]:
                    var post := MeshInstance3D.new()
                    var post_mesh := CylinderMesh.new()
                    post_mesh.top_radius = 0.13
                    post_mesh.bottom_radius = 0.17
                    post_mesh.height = 2.6
                    post.mesh = post_mesh
                    post.position = Vector3(x, 1.3, z)
                    post.material_override = wood_material
                    root.add_child(post)
            var roof := MeshInstance3D.new()
            var roof_mesh := BoxMesh.new()
            roof_mesh.size = Vector3(4.0, 0.22, 3.7)
            roof.mesh = roof_mesh
            roof.position.y = 2.68
            roof.material_override = _build_material(Color(0.25, 0.18, 0.12))
            root.add_child(roof)
            _add_building_collision(root, Vector3(3.6, 0.2, 3.1), Vector3(0.0, 0.1, 0.0))

    if record:
        placed_buildings.append({
            "type": build_type,
            "position": position,
            "rotation": facing
        })

func _build_material(color: Color, emissive := false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.92
    if emissive:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.4
    return material

func _add_building_collision(root: Node3D, size: Vector3, offset: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = offset
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    root.add_child(body)

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_building(build_type: String, position: Vector3, facing: float) -> void:
    _spawn_building_visual(build_type, position, facing, true)

func _create_resource_nodes() -> void:
    var resource_layout := [
        {"kind": "wood", "position": Vector2(31.0, -11.0), "amount": 4},
        {"kind": "wood", "position": Vector2(-54.0, 32.0), "amount": 4},
        {"kind": "wood", "position": Vector2(65.0, 46.0), "amount": 4},
        {"kind": "wood", "position": Vector2(-82.0, -44.0), "amount": 4},
        {"kind": "wood", "position": Vector2(102.0, -72.0), "amount": 4},
        {"kind": "stone", "position": Vector2(40.0, -11.0), "amount": 4},
        {"kind": "stone", "position": Vector2(78.0, 5.0), "amount": 4},
        {"kind": "stone", "position": Vector2(-88.0, 16.0), "amount": 4},
        {"kind": "stone", "position": Vector2(5.0, 93.0), "amount": 4},
        {"kind": "stone", "position": Vector2(117.0, 111.0), "amount": 4},
        {"kind": "fiber", "position": Vector2(16.0, 45.0), "amount": 5},
        {"kind": "fiber", "position": Vector2(-28.0, 82.0), "amount": 5},
        {"kind": "fiber", "position": Vector2(75.0, -93.0), "amount": 5},
        {"kind": "fiber", "position": Vector2(-98.0, -8.0), "amount": 5},
        {"kind": "fiber", "position": Vector2(111.0, 43.0), "amount": 5}
    ]

    var resource_rng := RandomNumberGenerator.new()
    resource_rng.seed = 20261112
    for generated_index in range(48):
        var resource_x := resource_rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
        var resource_z := resource_rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
        var river_center := sin(resource_z * 0.018) * 18.0
        if absf(resource_x - river_center) < 13.0:
            continue
        if Vector2(resource_x, resource_z).length() < 24.0:
            continue
        var resource_kind := "fiber"
        if resource_x > 125.0:
            resource_kind = "stone" if generated_index % 2 == 0 else "fiber"
        elif resource_z < -125.0:
            resource_kind = "wood" if generated_index % 2 == 0 else "stone"
        else:
            match generated_index % 3:
                0:
                    resource_kind = "wood"
                1:
                    resource_kind = "stone"
                _:
                    resource_kind = "fiber"
        resource_layout.append({
            "kind": resource_kind,
            "position": Vector2(resource_x, resource_z),
            "amount": 3 if resource_kind == "wood" else 4
        })

    for entry in resource_layout:
        var kind: String = entry["kind"]
        var point: Vector2 = entry["position"]
        var ground_position := Vector3(point.x, _height_at(point.x, point.y), point.y)
        var visual := Node3D.new()
        visual.name = "Resource_%s_%02d" % [kind, resource_nodes.size()]
        visual.position = ground_position
        add_child(visual)

        if kind == "wood":
            var bark := StandardMaterial3D.new()
            bark.albedo_color = Color(0.31, 0.19, 0.11)
            bark.roughness = 1.0
            for piece in range(3):
                var log := MeshInstance3D.new()
                var log_mesh := CylinderMesh.new()
                log_mesh.top_radius = 0.17
                log_mesh.bottom_radius = 0.17
                log_mesh.height = 1.45
                log.mesh = log_mesh
                log.position = Vector3(0.0, 0.20 + float(piece) * 0.22, (float(piece) - 1.0) * 0.24)
                log.rotation.z = PI * 0.5
                log.material_override = bark
                visual.add_child(log)
        elif kind == "stone":
            var stone_material := StandardMaterial3D.new()
            stone_material.albedo_color = Color(0.40, 0.43, 0.42)
            stone_material.roughness = 0.98
            for piece in range(4):
                var rock := MeshInstance3D.new()
                var rock_mesh := SphereMesh.new()
                rock_mesh.radius = 0.48
                rock_mesh.height = 0.78
                rock_mesh.radial_segments = 8
                rock_mesh.rings = 4
                rock.mesh = rock_mesh
                rock.position = Vector3(cos(float(piece) * TAU / 4.0) * 0.36, 0.24, sin(float(piece) * TAU / 4.0) * 0.36)
                rock.scale = Vector3(1.0 + float(piece % 2) * 0.25, 0.78, 0.9)
                rock.material_override = stone_material
                visual.add_child(rock)
        else:
            var fiber_material := StandardMaterial3D.new()
            fiber_material.albedo_color = Color(0.19, 0.40, 0.15)
            fiber_material.roughness = 1.0
            for piece in range(5):
                var stem := MeshInstance3D.new()
                var stem_mesh := CapsuleMesh.new()
                stem_mesh.radius = 0.10
                stem_mesh.height = 0.85
                stem.mesh = stem_mesh
                stem.position = Vector3(cos(float(piece) * TAU / 5.0) * 0.30, 0.48, sin(float(piece) * TAU / 5.0) * 0.30)
                stem.rotation.z = -0.28 if piece % 2 == 0 else 0.28
                stem.material_override = fiber_material
                visual.add_child(stem)

        resource_nodes.append({
            "kind": kind,
            "position": ground_position,
            "amount": int(entry["amount"]),
            "visual": visual
        })

func _create_build_panel(layer: CanvasLayer) -> void:
    var screen_size := get_viewport().get_visible_rect().size
    build_panel = PanelContainer.new()
    build_panel.name = "CraftAndBuildPanel"
    build_panel.position = Vector2(screen_size.x * 0.32, screen_size.y * 0.24)
    build_panel.custom_minimum_size = Vector2(420.0, 0.0)
    build_panel.visible = false
    layer.add_child(build_panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    build_panel.add_child(column)

    var title := Label.new()
    title.text = "FIELD CRAFTING  •  SHARED SUPPLIES"
    title.add_theme_font_size_override("font_size", 18)
    column.add_child(title)

    inventory_label = Label.new()
    inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(inventory_label)

    var hint := Label.new()
    hint.text = "Collect nearby materials with USE, then place structures in front of you."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(hint)

    var rotate_row := HBoxContainer.new()
    var rotate_left := Button.new()
    rotate_left.text = "ROTATE  -15°"
    rotate_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rotate_left.pressed.connect(_rotate_build_preview.bind(-15.0))
    rotate_row.add_child(rotate_left)
    var rotate_right := Button.new()
    rotate_right.text = "ROTATE  +15°"
    rotate_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rotate_right.pressed.connect(_rotate_build_preview.bind(15.0))
    rotate_row.add_child(rotate_right)
    column.add_child(rotate_row)

    var fire_button := Button.new()
    fire_button.text = "PLACE CAMPFIRE  •  3 WOOD + 2 STONE"
    fire_button.custom_minimum_size.y = 46.0
    fire_button.pressed.connect(_request_build.bind("campfire"))
    column.add_child(fire_button)
    build_recipe_buttons["campfire"] = fire_button

    var crate_button := Button.new()
    crate_button.text = "PLACE STORAGE CRATE  •  5 WOOD + 2 STONE"
    crate_button.custom_minimum_size.y = 46.0
    crate_button.pressed.connect(_request_build.bind("storage"))
    column.add_child(crate_button)
    build_recipe_buttons["storage"] = crate_button

    var shelter_button := Button.new()
    shelter_button.text = "PLACE WOOD SHELTER  •  12 WOOD + 6 FIBER + 4 STONE"
    shelter_button.custom_minimum_size.y = 46.0
    shelter_button.pressed.connect(_request_build.bind("shelter"))
    column.add_child(shelter_button)
    build_recipe_buttons["shelter"] = shelter_button

    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.pressed.connect(_toggle_build_panel.bind(false))
    column.add_child(close_button)

    _update_inventory_ui()
    _create_build_preview()

func _create_build_preview() -> void:
    var preview_mesh := CylinderMesh.new()
    preview_mesh.top_radius = 1.25
    preview_mesh.bottom_radius = 1.25
    preview_mesh.height = 0.035
    build_preview = MeshInstance3D.new()
    build_preview.name = "BuildPlacementPreview"
    build_preview.mesh = preview_mesh
    build_preview_material = StandardMaterial3D.new()
    build_preview_material.albedo_color = Color(0.28, 0.88, 0.63, 0.32)
    build_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    build_preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    build_preview_material.no_depth_test = true
    build_preview.material_override = build_preview_material
    build_preview.visible = false
    add_child(build_preview)

func _rotate_build_preview(degrees: float) -> void:
    build_rotation_offset = fposmod(build_rotation_offset + deg_to_rad(degrees), TAU)
    _show_status_note("Build rotation: %d°" % roundi(rad_to_deg(build_rotation_offset)))

func _update_build_preview() -> void:
    if not build_preview or not player or not build_panel or not build_panel.visible:
        if build_preview:
            build_preview.visible = false
        return
    var facing := player.rotation.y + build_rotation_offset
    var forward := Vector3(sin(facing), 0.0, -cos(facing))
    var target := player.global_position + forward * 4.0
    target.x = clampf(target.x, -WORLD_SIZE * 0.47, WORLD_SIZE * 0.47)
    target.z = clampf(target.z, -WORLD_SIZE * 0.47, WORLD_SIZE * 0.47)
    target.y = _height_at(target.x, target.z) + 0.035
    build_preview.global_position = target
    build_preview.rotation.y = facing
    var river_center := sin(target.z * 0.018) * 18.0
    var blocked := absf(target.x - river_center) < 9.0
    blocked = blocked or Vector2(target.x, target.z).distance_to(Vector2(camp_position.x, camp_position.z)) < 3.2
    blocked = blocked or absf(target.x) > WORLD_SIZE * 0.47 or absf(target.z) > WORLD_SIZE * 0.47
    for building in placed_buildings:
        var other: Vector3 = building["position"]
        if Vector2(target.x, target.z).distance_to(Vector2(other.x, other.z)) < 3.4:
            blocked = true
            break
    build_preview_material.albedo_color = Color(0.92, 0.25, 0.20, 0.36) if blocked else Color(0.28, 0.88, 0.63, 0.32)
    build_preview.visible = true

func _toggle_build_panel(visible_state: bool) -> void:
    if build_panel:
        build_panel.visible = visible_state
        if visible_state:
            _update_inventory_ui()

func _update_inventory_ui() -> void:
    if inventory_label:
        inventory_label.text = "WOOD  %d     STONE  %d     FIBER  %d" % [
            int(shared_inventory.get("wood", 0)),
            int(shared_inventory.get("stone", 0)),
            int(shared_inventory.get("fiber", 0))
        ]
    for build_type in build_recipe_buttons:
        var recipe := _get_build_recipe(str(build_type))
        var can_afford := true
        for material in recipe:
            if int(shared_inventory.get(material, 0)) < int(recipe[material]):
                can_afford = false
                break
        var recipe_button: Button = build_recipe_buttons[build_type]
        recipe_button.disabled = not can_afford

func _create_wildlife() -> void:
    wildlife_rng.seed = 20261110
    for index in range(10):
        var x := wildlife_rng.randf_range(-115.0, 115.0)
        var z := wildlife_rng.randf_range(-135.0, 135.0)
        if absf(x - sin(z * 0.018) * 18.0) < 15.0:
            x += 24.0
        var root := Node3D.new()
        root.name = "WildDeer_%02d" % index
        root.position = Vector3(x, _height_at(x, z), z)
        add_child(root)

        var coat := StandardMaterial3D.new()
        coat.albedo_color = Color(0.34, 0.20, 0.12).lerp(Color(0.50, 0.32, 0.18), wildlife_rng.randf() * 0.55)
        coat.roughness = 0.98
        var dark_coat := StandardMaterial3D.new()
        dark_coat.albedo_color = Color(0.22, 0.13, 0.08)
        dark_coat.roughness = 1.0
        var muzzle_material := StandardMaterial3D.new()
        muzzle_material.albedo_color = Color(0.72, 0.57, 0.42)
        muzzle_material.roughness = 0.95
        var antler_material := StandardMaterial3D.new()
        antler_material.albedo_color = Color(0.68, 0.57, 0.39)
        antler_material.roughness = 0.94

        var body := MeshInstance3D.new()
        var body_mesh := CapsuleMesh.new()
        body_mesh.radius = 0.39
        body_mesh.height = 1.45
        body.mesh = body_mesh
        body.position = Vector3(0.0, 1.12, 0.0)
        body.rotation.x = PI * 0.5
        body.material_override = coat
        root.add_child(body)

        var neck := MeshInstance3D.new()
        var neck_mesh := CapsuleMesh.new()
        neck_mesh.radius = 0.17
        neck_mesh.height = 0.67
        neck.mesh = neck_mesh
        neck.position = Vector3(0.0, 1.55, -0.40)
        neck.rotation.x = -0.38
        neck.material_override = coat
        root.add_child(neck)

        var head := MeshInstance3D.new()
        var head_mesh := SphereMesh.new()
        head_mesh.radius = 0.23
        head_mesh.height = 0.42
        head.mesh = head_mesh
        head.position = Vector3(0.0, 1.91, -0.66)
        head.material_override = coat
        root.add_child(head)

        var muzzle := MeshInstance3D.new()
        var muzzle_mesh := SphereMesh.new()
        muzzle_mesh.radius = 0.12
        muzzle_mesh.height = 0.18
        muzzle.mesh = muzzle_mesh
        muzzle.position = Vector3(0.0, 1.80, -0.86)
        muzzle.material_override = muzzle_material
        root.add_child(muzzle)

        for side in [-1.0, 1.0]:
            var ear := MeshInstance3D.new()
            var ear_mesh := CapsuleMesh.new()
            ear_mesh.radius = 0.055
            ear_mesh.height = 0.34
            ear.mesh = ear_mesh
            ear.position = Vector3(side * 0.19, 2.08, -0.57)
            ear.rotation.z = side * 0.48
            ear.material_override = dark_coat
            root.add_child(ear)

            var antler_stem := MeshInstance3D.new()
            var stem_mesh := CylinderMesh.new()
            stem_mesh.top_radius = 0.012
            stem_mesh.bottom_radius = 0.035
            stem_mesh.height = 0.48
            antler_stem.mesh = stem_mesh
            antler_stem.position = Vector3(side * 0.13, 2.18, -0.55)
            antler_stem.rotation.z = -side * 0.18
            antler_stem.material_override = antler_material
            root.add_child(antler_stem)

            var antler_branch := MeshInstance3D.new()
            var branch_mesh := CylinderMesh.new()
            branch_mesh.top_radius = 0.008
            branch_mesh.bottom_radius = 0.022
            branch_mesh.height = 0.28
            antler_branch.mesh = branch_mesh
            antler_branch.position = Vector3(side * 0.22, 2.35, -0.55)
            antler_branch.rotation.z = -side * 0.95
            antler_branch.material_override = antler_material
            root.add_child(antler_branch)

        for leg_x in [-0.23, 0.23]:
            for leg_z in [-0.43, 0.39]:
                var leg := MeshInstance3D.new()
                var leg_mesh := CylinderMesh.new()
                leg_mesh.top_radius = 0.055
                leg_mesh.bottom_radius = 0.075
                leg_mesh.height = 0.72
                leg.mesh = leg_mesh
                leg.position = Vector3(leg_x, 0.43, leg_z)
                leg.material_override = dark_coat
                root.add_child(leg)

        var tail := MeshInstance3D.new()
        var tail_mesh := SphereMesh.new()
        tail_mesh.radius = 0.13
        tail_mesh.height = 0.23
        tail.mesh = tail_mesh
        tail.position = Vector3(0.0, 1.24, 0.55)
        tail.material_override = muzzle_material
        root.add_child(tail)

        wildlife_agents.append({
            "root": root,
            "target": Vector3(x, _height_at(x, z), z),
            "timer": wildlife_rng.randf_range(1.0, 4.0),
            "speed": wildlife_rng.randf_range(0.9, 1.35)
        })
    _create_small_wildlife("Rabbit", 8, Color(0.55, 0.45, 0.35), 0.55, 1.35)
    _create_small_wildlife("Fox", 5, Color(0.65, 0.27, 0.10), 0.82, 1.75)
    _create_small_wildlife("Boar", 4, Color(0.25, 0.19, 0.15), 0.95, 1.05)

func _create_small_wildlife(species: String, count: int, coat_color: Color, size_scale: float, move_speed: float) -> void:
    for index in range(count):
        var x := wildlife_rng.randf_range(-112.0, 112.0)
        var z := wildlife_rng.randf_range(-130.0, 130.0)
        if absf(x - sin(z * 0.018) * 18.0) < 16.0:
            x += 25.0 if x < 0.0 else -25.0
        var root := Node3D.new()
        root.name = "%s_%02d" % [species, index + 1]
        root.position = Vector3(x, _height_at(x, z), z)
        add_child(root)
        var coat := StandardMaterial3D.new()
        coat.albedo_color = coat_color.lerp(Color(0.75, 0.62, 0.45), wildlife_rng.randf() * 0.16)
        coat.roughness = 0.98
        var dark := StandardMaterial3D.new()
        dark.albedo_color = coat_color.darkened(0.35)
        dark.roughness = 1.0
        var body := MeshInstance3D.new()
        var body_mesh := SphereMesh.new()
        body_mesh.radius = 0.52 * size_scale
        body_mesh.height = 0.75 * size_scale
        body.mesh = body_mesh
        body.position.y = 0.55 * size_scale
        body.scale = Vector3(1.0, 0.78, 1.38)
        body.material_override = coat
        root.add_child(body)
        var head := MeshInstance3D.new()
        var head_mesh := SphereMesh.new()
        head_mesh.radius = 0.27 * size_scale
        head_mesh.height = 0.42 * size_scale
        head.mesh = head_mesh
        head.position = Vector3(0.0, 0.72 * size_scale, -0.48 * size_scale)
        head.material_override = coat
        root.add_child(head)
        for side in [-1.0, 1.0]:
            var ear := MeshInstance3D.new()
            var ear_mesh := CapsuleMesh.new()
            ear_mesh.radius = (0.055 if species == "Rabbit" else 0.075) * size_scale
            ear_mesh.height = (0.48 if species == "Rabbit" else 0.22) * size_scale
            ear.mesh = ear_mesh
            ear.position = Vector3(side * 0.16 * size_scale, 1.03 * size_scale, -0.48 * size_scale)
            ear.rotation.z = side * 0.16
            ear.material_override = dark
            root.add_child(ear)
        for leg_x in [-0.25, 0.25]:
            for leg_z in [-0.36, 0.34]:
                var leg := MeshInstance3D.new()
                var leg_mesh := CylinderMesh.new()
                leg_mesh.top_radius = 0.045 * size_scale
                leg_mesh.bottom_radius = 0.065 * size_scale
                leg_mesh.height = 0.38 * size_scale
                leg.mesh = leg_mesh
                leg.position = Vector3(leg_x * size_scale, 0.20 * size_scale, leg_z * size_scale)
                leg.material_override = dark
                root.add_child(leg)
        var tail := MeshInstance3D.new()
        var tail_mesh := SphereMesh.new()
        tail_mesh.radius = (0.16 if species == "Fox" else 0.10) * size_scale
        tail_mesh.height = 0.28 * size_scale
        tail.mesh = tail_mesh
        tail.position = Vector3(0.0, 0.65 * size_scale, 0.58 * size_scale)
        tail.material_override = dark if species != "Fox" else coat
        root.add_child(tail)
        wildlife_agents.append({
            "root": root,
            "target": root.position,
            "timer": wildlife_rng.randf_range(1.0, 4.0),
            "speed": move_speed * wildlife_rng.randf_range(0.8, 1.2)
        })

func _village_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = position
    node.material_override = material
    parent.add_child(node)
    return node

func _create_village() -> void:
    # A small settlement on the west bank, with a clear pedestrian lane and varied homes.
    var village_center := Vector3(-82.0, 0.0, 76.0)
    var ground := _height_at(village_center.x, village_center.z)
    var path_material := StandardMaterial3D.new()
    path_material.albedo_color = Color(0.42, 0.35, 0.24)
    path_material.roughness = 1.0
    var wall_materials: Array[StandardMaterial3D] = []
    for tint in [Color(0.68, 0.53, 0.37), Color(0.58, 0.43, 0.31), Color(0.72, 0.65, 0.48)]:
        var material := StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = 0.94
        wall_materials.append(material)
    var roof_material := StandardMaterial3D.new()
    roof_material.albedo_color = Color(0.24, 0.19, 0.16)
    roof_material.roughness = 0.9
    var wood_material := StandardMaterial3D.new()
    wood_material.albedo_color = Color(0.25, 0.16, 0.10)
    wood_material.roughness = 0.98
    var glass_material := StandardMaterial3D.new()
    glass_material.albedo_color = Color(0.24, 0.43, 0.48, 0.78)
    glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass_material.roughness = 0.22

    var road := _village_box(self, "Village_Dirt_Lane", Vector3(7.0, 0.12, 58.0), Vector3(village_center.x, ground + 0.04, village_center.z), path_material)
    road.rotation.y = 0.08
    var house_offsets := [
        Vector3(-13.0, 0.0, -15.0), Vector3(12.0, 0.0, -12.0),
        Vector3(-15.0, 0.0, 7.0), Vector3(13.0, 0.0, 10.0),
        Vector3(-2.0, 0.0, 25.0)
    ]
    for index in range(house_offsets.size()):
        var offset: Vector3 = house_offsets[index]
        var x := village_center.x + offset.x
        var z := village_center.z + offset.z
        var base_y := _height_at(x, z)
        var house := Node3D.new()
        house.name = "Village_Home_%02d" % (index + 1)
        house.position = Vector3(x, base_y, z)
        add_child(house)
        var wall := _village_box(house, "Plastered_Walls", Vector3(8.0, 4.1, 7.0), Vector3(0.0, 2.05, 0.0), wall_materials[index % wall_materials.size()])
        var roof_left := _village_box(house, "Roof_Left", Vector3(4.7, 0.28, 7.8), Vector3(-2.0, 4.25, 0.0), roof_material)
        roof_left.rotation.z = -0.48
        var roof_right := _village_box(house, "Roof_Right", Vector3(4.7, 0.28, 7.8), Vector3(2.0, 4.25, 0.0), roof_material)
        roof_right.rotation.z = 0.48
        _village_box(house, "Front_Door", Vector3(1.25, 2.25, 0.14), Vector3(0.0, 1.12, -3.58), wood_material)
        for side in [-1.0, 1.0]:
            _village_box(house, "Window", Vector3(1.15, 1.05, 0.12), Vector3(side * 2.35, 2.35, -3.59), glass_material)
        var chimney := _village_box(house, "Chimney", Vector3(0.75, 1.7, 0.75), Vector3(2.3, 4.8, 1.6), wall_materials[1])
        chimney.rotation.y = 0.15

    for lamp_index in range(4):
        var lamp_x := village_center.x + ( -1.0 if lamp_index % 2 == 0 else 1.0) * 5.5
        var lamp_z := village_center.z - 22.0 + float(lamp_index) * 15.0
        var pole := _village_box(self, "Village_Lamp_Post", Vector3(0.16, 3.4, 0.16), Vector3(lamp_x, _height_at(lamp_x, lamp_z) + 1.7, lamp_z), wood_material)
        var glow := StandardMaterial3D.new()
        glow.albedo_color = Color(1.0, 0.73, 0.38)
        glow.emission_enabled = true
        glow.emission = Color(1.0, 0.55, 0.2)
        glow.emission_energy_multiplier = 1.2
        var lantern := _village_box(self, "Warm_Lantern", Vector3(0.42, 0.48, 0.42), pole.position + Vector3(0.0, 1.72, 0.0), glow)

    var clothing_colors := [Color(0.25, 0.36, 0.48), Color(0.55, 0.29, 0.18), Color(0.36, 0.43, 0.25), Color(0.54, 0.48, 0.34), Color(0.30, 0.27, 0.38), Color(0.62, 0.42, 0.25), Color(0.24, 0.42, 0.40), Color(0.48, 0.32, 0.29)]
    var skin_material := StandardMaterial3D.new()
    skin_material.albedo_color = Color(0.66, 0.46, 0.33)
    skin_material.roughness = 0.9
    var npc_rng := RandomNumberGenerator.new()
    npc_rng.seed = 20261112
    for index in range(8):
        var npc := Node3D.new()
        npc.name = "Villager_%02d" % (index + 1)
        var x := village_center.x + npc_rng.randf_range(-13.0, 13.0)
        var z := village_center.z + npc_rng.randf_range(-24.0, 25.0)
        npc.position = Vector3(x, _height_at(x, z), z)
        add_child(npc)
        var outfit := StandardMaterial3D.new()
        outfit.albedo_color = clothing_colors[index]
        outfit.roughness = 0.95
        var torso := MeshInstance3D.new()
        var torso_mesh := CapsuleMesh.new()
        torso_mesh.radius = 0.32
        torso_mesh.height = 1.05
        torso.mesh = torso_mesh
        torso.position.y = 1.05
        torso.material_override = outfit
        npc.add_child(torso)
        var head := MeshInstance3D.new()
        var head_mesh := SphereMesh.new()
        head_mesh.radius = 0.23
        head_mesh.height = 0.44
        head.mesh = head_mesh
        head.position.y = 1.78
        head.material_override = skin_material
        npc.add_child(head)
        for side in [-1.0, 1.0]:
            var arm := MeshInstance3D.new()
            var arm_mesh := CapsuleMesh.new()
            arm_mesh.radius = 0.095
            arm_mesh.height = 0.72
            arm.mesh = arm_mesh
            arm.position = Vector3(side * 0.39, 1.08, 0.0)
            arm.rotation.z = side * -0.12
            arm.material_override = outfit
            npc.add_child(arm)
            var leg := MeshInstance3D.new()
            var leg_mesh := CapsuleMesh.new()
            leg_mesh.radius = 0.12
            leg_mesh.height = 0.78
            leg.mesh = leg_mesh
            leg.position = Vector3(side * 0.16, 0.39, 0.0)
            leg.material_override = wood_material
            npc.add_child(leg)
        village_agents.append({
            "root": npc,
            "home": npc.position,
            "target": npc.position,
            "timer": npc_rng.randf_range(1.0, 4.0),
            "speed": npc_rng.randf_range(0.65, 1.05),
            "phase": npc_rng.randf_range(0.0, TAU)
        })

func _update_village_agents(delta: float) -> void:
    for index in range(village_agents.size()):
        var villager: Dictionary = village_agents[index]
        var root: Node3D = villager["root"]
        if not is_instance_valid(root):
            continue
        var home: Vector3 = villager["home"]
        var target: Vector3 = villager["target"]
        var timer := float(villager["timer"]) - delta
        if timer <= 0.0 or Vector2(root.position.x - target.x, root.position.z - target.z).length() < 0.55:
            var angle := randf() * TAU
            var distance := randf_range(1.5, 7.0)
            target = home + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
            timer = randf_range(2.0, 6.0)
        var direction := Vector3(target.x - root.position.x, 0.0, target.z - root.position.z)
        if direction.length() > 0.12:
            root.position += direction.normalized() * float(villager["speed"]) * delta
            root.rotation.y = lerp_angle(root.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 3.0))
        root.position.y = lerpf(root.position.y, _height_at(root.position.x, root.position.z), minf(1.0, delta * 8.0))
        villager["target"] = target
        villager["timer"] = timer
        village_agents[index] = villager

func _constrain_wildlife_target(target: Vector3, origin: Vector3) -> Vector3:
    # Deer remain in the temperate valley and do not deliberately route through deep water.
    target.x = clampf(target.x, -135.0, 135.0)
    target.z = clampf(target.z, -145.0, 145.0)
    var river_center := sin(target.z * 0.018) * 18.0
    var origin_side := -1.0 if origin.x < sin(origin.z * 0.018) * 18.0 else 1.0
    var river_offset := target.x - river_center
    if absf(river_offset) < 10.0:
        target.x = river_center + origin_side * 10.0
    # Keep the destination on the animal's current bank when the river bends.
    var local_center := sin(target.z * 0.018) * 18.0
    if (origin.x - sin(origin.z * 0.018) * 18.0) * (target.x - local_center) < 0.0:
        target.x = local_center + origin_side * 10.0
    return target

func _update_wildlife(delta: float) -> void:
    if wildlife_agents.is_empty():
        return
    for index in range(wildlife_agents.size()):
        var animal: Dictionary = wildlife_agents[index]
        var root: Node3D = animal["root"]
        if not is_instance_valid(root) or not root.visible:
            continue

        var timer := float(animal["timer"]) - delta
        var target: Vector3 = animal["target"]
        var away := Vector3.ZERO
        var fleeing := false
        if player:
            var from_player := root.global_position - player.global_position
            from_player.y = 0.0
            if from_player.length() < 11.0 and from_player.length() > 0.1:
                fleeing = true
                away = from_player.normalized()

        if fleeing:
            target = root.global_position + away * wildlife_rng.randf_range(16.0, 24.0)
            target.x = clampf(target.x, -WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
            timer = wildlife_rng.randf_range(2.0, 3.5)
        elif timer <= 0.0 or Vector2(root.position.x - target.x, root.position.z - target.z).length() < 1.2:
            var angle := wildlife_rng.randf_range(0.0, TAU)
            var distance := wildlife_rng.randf_range(7.0, 18.0)
            target = root.position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
            timer = wildlife_rng.randf_range(3.0, 7.0)

        target = _constrain_wildlife_target(target, root.position)
        var direction := Vector3(target.x - root.position.x, 0.0, target.z - root.position.z)
        var animal_speed := 3.8 if fleeing else float(animal["speed"])
        if direction.length() > 0.1:
            var movement := direction.normalized() * animal_speed * delta
            root.position.x += movement.x
            root.position.z += movement.z
            var target_angle := atan2(-direction.x, -direction.z)
            root.rotation.y = lerp_angle(root.rotation.y, target_angle, minf(1.0, delta * 4.0))
        var ground_height := _height_at(root.position.x, root.position.z)
        root.position.y = lerpf(root.position.y, ground_height, minf(1.0, delta * 8.0))
        animal["target"] = target
        animal["timer"] = timer
        wildlife_agents[index] = animal

func _create_campsite() -> void:
    camp_position = Vector3(18.0, _height_at(18.0, 0.0), 0.0)

    var bedroll := MeshInstance3D.new()
    var bedroll_mesh := BoxMesh.new()
    bedroll_mesh.size = Vector3(2.2, 0.16, 1.0)
    bedroll.mesh = bedroll_mesh
    bedroll.position = camp_position + Vector3(2.3, 0.12, 0.0)
    var bedroll_material := StandardMaterial3D.new()
    bedroll_material.albedo_color = Color(0.46, 0.34, 0.21)
    bedroll.material_override = bedroll_material
    add_child(bedroll)

    for i in range(3):
        var log := MeshInstance3D.new()
        var log_mesh := CylinderMesh.new()
        log_mesh.top_radius = 0.15
        log_mesh.bottom_radius = 0.15
        log_mesh.height = 1.15
        log.mesh = log_mesh
        log.position = camp_position + Vector3(
            cos(TAU * float(i) / 3.0) * 0.42,
            0.18,
            sin(TAU * float(i) / 3.0) * 0.42
        )
        log.rotation.z = PI * 0.5
        var log_material := StandardMaterial3D.new()
        log_material.albedo_color = Color(0.29, 0.17, 0.09)
        log.material_override = log_material
        add_child(log)

    var fire := MeshInstance3D.new()
    var fire_mesh := SphereMesh.new()
    fire_mesh.radius = 0.32
    fire_mesh.height = 0.72
    fire.mesh = fire_mesh
    fire.position = camp_position + Vector3(0, 0.42, 0)
    var fire_material := StandardMaterial3D.new()
    fire_material.albedo_color = Color(1.0, 0.31, 0.07)
    fire_material.emission_enabled = true
    fire_material.emission = Color(1.0, 0.16, 0.025)
    fire_material.emission_energy_multiplier = 1.6
    fire.material_override = fire_material
    add_child(fire)

    var fire_light := OmniLight3D.new()
    fire_light.position = camp_position + Vector3(0, 1.0, 0)
    fire_light.light_color = Color(1.0, 0.39, 0.12)
    fire_light.light_energy = 0.75
    fire_light.omni_range = 7.0
    add_child(fire_light)

func _create_memory_stone() -> void:
    memory_position = Vector3(-26.0, _height_at(-26.0, -28.0), -28.0)

    var stone := MeshInstance3D.new()
    stone.name = "WorldMemoryStone"
    var stone_mesh := CylinderMesh.new()
    stone_mesh.top_radius = 0.65
    stone_mesh.bottom_radius = 0.82
    stone_mesh.height = 1.45
    stone.mesh = stone_mesh
    stone.position = memory_position + Vector3(0, 0.72, 0)
    var stone_material := StandardMaterial3D.new()
    stone_material.albedo_color = Color(0.27, 0.39, 0.38)
    stone_material.roughness = 0.88
    stone.material_override = stone_material
    add_child(stone)

    memory_crystal = MeshInstance3D.new()
    var crystal_mesh := SphereMesh.new()
    crystal_mesh.radius = 0.22
    crystal_mesh.height = 0.52
    memory_crystal.mesh = crystal_mesh
    memory_crystal.position = memory_position + Vector3(0, 1.62, 0)
    var crystal_material := StandardMaterial3D.new()
    crystal_material.albedo_color = Color(0.20, 0.72, 0.66)
    crystal_material.emission_enabled = true
    crystal_material.emission = Color(0.08, 0.48, 0.42)
    crystal_material.emission_energy_multiplier = 0.55
    memory_crystal.material_override = crystal_material
    add_child(memory_crystal)

func _awaken_world_memory() -> void:
    if lan_active and not multiplayer.is_server():
        rpc_id(1, "_rpc_request_interaction")
        return
    _apply_world_memory()
    if lan_active and multiplayer.is_server():
        rpc("_rpc_world_memory_activated")

func _apply_world_memory() -> void:
    if memory_awakened:
        return
    memory_awakened = true
    if is_instance_valid(memory_crystal):
        memory_crystal.visible = false

    var trail_mesh := SphereMesh.new()
    trail_mesh.radius = 0.18
    trail_mesh.height = 0.36
    var trail_material := StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.22, 0.92, 0.78)
    trail_material.emission_enabled = true
    trail_material.emission = Color(0.10, 0.72, 0.58)
    trail_material.emission_energy_multiplier = 1.25

    for i in range(12):
        var progress := float(i) / 11.0
        var trail_x: float = lerpf(memory_position.x, -7.0, progress) + sin(progress * PI * 2.0) * 1.7
        var trail_z: float = lerpf(memory_position.z, -8.0, progress)
        var marker := MeshInstance3D.new()
        marker.mesh = trail_mesh
        marker.material_override = trail_material
        marker.position = Vector3(
            trail_x,
            _height_at(trail_x, trail_z) + 0.32 + sin(progress * PI) * 0.45,
            trail_z
        )
        add_child(marker)

    _show_status_note("A forgotten path returned to the world.")


func _update_day_cycle(delta: float) -> void:
    if not sun_light or not world_environment or not sky_material:
        return

    # One full in-game day lasts 20 real minutes.
    world_clock = fposmod(world_clock + delta * 24.0 / 1200.0, 24.0)
    var daylight: float = clampf(sin((world_clock - 6.0) / 12.0 * PI), 0.0, 1.0)
    var day_sky := Color(0.16, 0.35, 0.56)
    var night_sky := Color(0.012, 0.025, 0.075)

    sun_light.rotation_degrees = Vector3(lerp(15.0, -195.0, world_clock / 24.0), -32.0, 0.0)
    sun_light.light_energy = lerp(0.025, 1.05, daylight)
    sun_light.light_color = Color(0.42, 0.52, 0.82).lerp(Color(1.0, 0.91, 0.76), daylight)

    world_environment.ambient_light_energy = lerp(0.18, 0.65, daylight)
    world_environment.fog_light_color = Color(0.10, 0.14, 0.25).lerp(Color(0.61, 0.72, 0.70), daylight)
    sky_material.sky_top_color = night_sky.lerp(day_sky, daylight)
    sky_material.sky_horizon_color = Color(0.06, 0.08, 0.17).lerp(Color(0.72, 0.82, 0.86), daylight)
    sky_material.ground_bottom_color = Color(0.015, 0.025, 0.055).lerp(Color(0.12, 0.18, 0.15), daylight)
    sky_material.ground_horizon_color = Color(0.08, 0.11, 0.18).lerp(Color(0.48, 0.58, 0.48), daylight)

func _physics_process(delta: float) -> void:
    if not player or not camera:
        return

    var camera_target := player.global_position + Vector3(0, 1.55, 0)
    camera_pivot.global_position = camera_pivot.global_position.lerp(camera_target, minf(1.0, delta * 16.0))

    var horizontal := joystick_vector
    horizontal.x += float(Input.is_key_pressed(KEY_D) or _button_down("right")) - float(Input.is_key_pressed(KEY_A) or _button_down("left"))
    horizontal.y += float(Input.is_key_pressed(KEY_S) or _button_down("back")) - float(Input.is_key_pressed(KEY_W) or _button_down("forward"))
    if horizontal.length() > 1.0:
        horizontal = horizontal.normalized()

    var camera_forward := -camera.global_transform.basis.z
    var camera_right := camera.global_transform.basis.x
    camera_forward.y = 0.0
    camera_right.y = 0.0
    camera_forward = camera_forward.normalized()
    camera_right = camera_right.normalized()

    var direction := camera_right * horizontal.x - camera_forward * horizontal.y
    direction = direction.normalized()

    var move_speed := PLAYER_SPEED * (1.48 if _button_down("run") or Input.is_key_pressed(KEY_SHIFT) else 1.0)
    var target_horizontal_velocity := Vector2(direction.x, direction.z) * move_speed
    player.velocity.x = move_toward(player.velocity.x, target_horizontal_velocity.x, 28.0 * delta)
    player.velocity.z = move_toward(player.velocity.z, target_horizontal_velocity.y, 28.0 * delta)

    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    elif Input.is_key_pressed(KEY_SPACE) or _button_down("jump"):
        player.velocity.y = JUMP_VELOCITY
    else:
        player.velocity.y = 0.0

    player.move_and_slide()
    if direction.length_squared() > 0.01:
        var target_angle := atan2(-direction.x, -direction.z)
        player.rotation.y = lerp_angle(player.rotation.y, target_angle, delta * 10.0)
    _update_character_animation(delta, direction.length_squared() > 0.01)

func _update_character_animation(delta: float, is_moving: bool) -> void:
    if not left_arm or not right_arm or not left_leg or not right_leg:
        return
    if is_moving and player.is_on_floor():
        gait_time += delta * 8.5
        var swing := sin(gait_time) * 0.48
        left_leg.rotation.x = swing
        right_leg.rotation.x = -swing
        left_arm.rotation.x = -swing * 0.72
        right_arm.rotation.x = swing * 0.72
    else:
        left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 8.0)
        right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 8.0)
        left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.0, delta * 8.0)
        right_arm.rotation.x = lerp_angle(right_arm.rotation.x, 0.0, delta * 8.0)


func _set_network_status(message: String) -> void:
    if network_status_label:
        network_status_label.text = message
    print("[WORLDS LAN] ", message)

func _get_lan_ipv4() -> String:
    for address in IP.get_local_addresses():
        if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254."):
            continue
        var octets := address.split(".")
        if octets.size() != 4:
            continue
        var valid := true
        for octet in octets:
            if not octet.is_valid_int() or int(octet) < 0 or int(octet) > 255:
                valid = false
                break
        if valid and (address.begins_with("192.168.") or address.begins_with("10.") or address.begins_with("172.")):
            return address
    return "Wi-Fi IP not detected"

func _is_valid_ipv4(address: String) -> bool:
    var octets := address.split(".")
    if octets.size() != 4:
        return false
    for octet in octets:
        if not octet.is_valid_int() or int(octet) < 0 or int(octet) > 255:
            return false
    return true

func _host_lan_game() -> void:
    _disconnect_lan_game()
    var network_peer := ENetMultiplayerPeer.new()
    var error := network_peer.create_server(LAN_PORT, LAN_MAX_CLIENTS)
    if error != OK:
        _set_network_status("Could not host  •  Error %d" % error)
        return
    multiplayer.multiplayer_peer = network_peer
    lan_active = true
    host_ip_label.text = "HOST IP: %s  •  UDP %d" % [_get_lan_ipv4(), LAN_PORT]
    _set_network_status("World hosted  •  Ask your brother to enter this IP")

func _join_lan_game() -> void:
    var address := address_input.text.strip_edges()
    if not _is_valid_ipv4(address):
        _set_network_status("Enter a valid local IPv4 address first.")
        return
    _disconnect_lan_game()
    var network_peer := ENetMultiplayerPeer.new()
    var error := network_peer.create_client(address, LAN_PORT)
    if error != OK:
        _set_network_status("Could not start connection  •  Error %d" % error)
        return
    multiplayer.multiplayer_peer = network_peer
    lan_active = true
    _set_network_status("Connecting to %s..." % address)

func _disconnect_lan_game() -> void:
    lan_active = false
    network_send_timer = 0.0
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    for peer_id in network_remote_players.keys():
        var avatar: Node3D = network_remote_players[peer_id]
        if is_instance_valid(avatar):
            avatar.queue_free()
    network_remote_players.clear()
    network_remote_targets.clear()
    if network_status_label:
        _set_network_status("Offline  •  Ready to host or join")

func _on_peer_connected(peer_id: int) -> void:
    if not multiplayer.is_server():
        return
    var spawn_position := Vector3(18.0, _height_at(18.0, 0.0) + 1.2, float(peer_id % 2) * 3.0 + 2.0)
    _ensure_remote_player(peer_id, spawn_position, 0.0)
    rpc("_rpc_spawn_remote_player", peer_id, spawn_position, 0.0)
    _set_network_status("Player connected  •  Waiting for first movement")

func _on_peer_disconnected(peer_id: int) -> void:
    _remove_remote_player(peer_id)
    if multiplayer.is_server():
        rpc("_rpc_remove_remote_player", peer_id)
    _set_network_status("A player left the world")

func _on_connected_to_server() -> void:
    lan_active = true
    _set_network_status("Connected  •  Synchronizing world...")
    rpc_id(1, "_rpc_request_player_roster")
    if OS.get_cmdline_user_args().has("--lan-smoke-client"):
        get_tree().create_timer(1.2).timeout.connect(_move_lan_smoke_client)

func _on_connection_failed() -> void:
    _disconnect_lan_game()
    _set_network_status("Connection failed  •  Check Wi-Fi and host IP")

func _on_server_disconnected() -> void:
    _disconnect_lan_game()
    _set_network_status("Host disconnected  •  Session ended")
    if OS.get_cmdline_user_args().has("--lan-smoke-client"):
        if lan_smoke_client_passed:
            print("LAN_SMOKE_CLIENT_EXIT_PASS")
            get_tree().quit(0)
        else:
            push_error("LAN_SMOKE_CLIENT_EXIT_FAIL: host ended session before shared state passed")
            get_tree().quit(1)

func _create_remote_player_visual(peer_id: int, spawn_position: Vector3, facing: float) -> Node3D:
    var avatar := Node3D.new()
    avatar.name = "RemotePlayer_%d" % peer_id
    avatar.position = spawn_position
    avatar.rotation.y = facing

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.34
    body_mesh.height = 1.16
    body.mesh = body_mesh
    body.position.y = 1.16
    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(0.20, 0.42, 0.72) if peer_id % 2 == 0 else Color(0.66, 0.38, 0.18)
    body.material_override = body_material
    avatar.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head_mesh.height = 0.48
    head.mesh = head_mesh
    head.position.y = 1.88
    var head_material := StandardMaterial3D.new()
    head_material.albedo_color = Color(0.66, 0.46, 0.32)
    head.material_override = head_material
    avatar.add_child(head)

    var label := Label3D.new()
    label.text = "PLAYER %d" % peer_id
    label.position.y = 2.35
    label.font_size = 30
    label.pixel_size = 0.008
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    avatar.add_child(label)

    add_child(avatar)
    return avatar

func _ensure_remote_player(peer_id: int, spawn_position: Vector3, facing: float) -> void:
    if peer_id == multiplayer.get_unique_id():
        return
    if not network_remote_players.has(peer_id) or not is_instance_valid(network_remote_players[peer_id]):
        var avatar := _create_remote_player_visual(peer_id, spawn_position, facing)
        network_remote_players[peer_id] = avatar
    _set_remote_player_target(peer_id, spawn_position, facing)

func _set_remote_player_target(peer_id: int, target_position: Vector3, facing: float) -> void:
    network_remote_targets[peer_id] = {
        "position": target_position,
        "facing": facing
    }

func _remove_remote_player(peer_id: int) -> void:
    if network_remote_players.has(peer_id):
        var avatar: Node3D = network_remote_players[peer_id]
        if is_instance_valid(avatar):
            avatar.queue_free()
    network_remote_players.erase(peer_id)
    network_remote_targets.erase(peer_id)

func _update_remote_players(delta: float) -> void:
    for peer_id in network_remote_players.keys():
        var avatar: Node3D = network_remote_players[peer_id]
        if not is_instance_valid(avatar):
            continue
        if not network_remote_targets.has(peer_id):
            continue
        var target: Dictionary = network_remote_targets[peer_id]
        var weight := clampf(delta * 12.0, 0.0, 1.0)
        avatar.position = avatar.position.lerp(target["position"], weight)
        avatar.rotation.y = lerp_angle(avatar.rotation.y, float(target["facing"]), weight)

func _update_network(delta: float) -> void:
    if not lan_active:
        return
    network_send_timer += delta
    if network_send_timer >= NETWORK_SEND_INTERVAL:
        network_send_timer = 0.0
        _send_local_network_state()

func _send_local_network_state() -> void:
    if not lan_active:
        return
    if multiplayer.is_server():
        if multiplayer.get_peers().is_empty():
            return
        rpc("_rpc_apply_remote_player_state", 1, player.global_position, player.rotation.y, world_clock)
    elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        rpc_id(1, "_rpc_receive_player_state", player.global_position, player.rotation.y)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_player_roster() -> void:
    if not multiplayer.is_server():
        return
    var requester := multiplayer.get_remote_sender_id()
    rpc_id(requester, "_rpc_spawn_remote_player", 1, player.global_position, player.rotation.y)
    for peer_id in network_remote_players.keys():
        if int(peer_id) == requester:
            continue
        var avatar: Node3D = network_remote_players[peer_id]
        if is_instance_valid(avatar):
            rpc_id(requester, "_rpc_spawn_remote_player", int(peer_id), avatar.global_position, avatar.rotation.y)
    rpc_id(requester, "_rpc_set_shared_clock", world_clock)
    rpc_id(requester, "_rpc_set_shared_inventory", shared_inventory)
    for index in range(berry_bushes.size()):
        var bush: Dictionary = berry_bushes[index]
        rpc_id(requester, "_rpc_set_berry_servings", index, int(bush["servings"]))
    for index in range(resource_nodes.size()):
        var resource: Dictionary = resource_nodes[index]
        rpc_id(requester, "_rpc_set_resource_amount", index, int(resource["amount"]))
    for building in placed_buildings:
        rpc_id(requester, "_rpc_spawn_building", str(building["type"]), building["position"], float(building["rotation"]))
    if memory_awakened:
        rpc_id(requester, "_rpc_world_memory_activated")

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_remote_player(peer_id: int, spawn_position: Vector3, facing: float) -> void:
    _ensure_remote_player(peer_id, spawn_position, facing)

@rpc("authority", "call_remote", "reliable")
func _rpc_remove_remote_player(peer_id: int) -> void:
    _remove_remote_player(peer_id)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_receive_player_state(world_position: Vector3, facing: float) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    if sender <= 1 or not network_remote_players.has(sender):
        return
    var safe_position := Vector3(
        clampf(world_position.x, -WORLD_SIZE * 0.48, WORLD_SIZE * 0.48),
        clampf(world_position.y, -10.0, 30.0),
        clampf(world_position.z, -WORLD_SIZE * 0.48, WORLD_SIZE * 0.48)
    )
    _set_remote_player_target(sender, safe_position, facing)
    for peer_id in multiplayer.get_peers():
        if peer_id != sender:
            rpc_id(peer_id, "_rpc_apply_remote_player_state", sender, safe_position, facing, world_clock)

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_apply_remote_player_state(peer_id: int, world_position: Vector3, facing: float, synced_clock: float) -> void:
    _ensure_remote_player(peer_id, world_position, facing)
    _set_remote_player_target(peer_id, world_position, facing)
    world_clock = fposmod(synced_clock, 24.0)




func _start_gameplay_smoke_test() -> void:
    if resource_nodes.size() < 11 or wildlife_agents.size() < 27 or village_agents.size() < 8 or build_panel == null or minimap_panel == null or minimap_marker == null:
        push_error("GAMEPLAY_SMOKE_FAIL: resources or crafting interface missing")
        get_tree().quit(1)
        return

    var wildlife_origin := Vector3(-42.0, 0.0, 20.0)
    var wildlife_destination := _constrain_wildlife_target(Vector3(70.0, 0.0, 20.0), wildlife_origin)
    var wildlife_river_center := sin(wildlife_destination.z * 0.018) * 18.0
    if wildlife_destination.x < -135.0 or wildlife_destination.x > 135.0 or wildlife_destination.z < -145.0 or wildlife_destination.z > 145.0:
        push_error("GAMEPLAY_SMOKE_FAIL: wildlife target escaped its habitat bounds")
        get_tree().quit(1)
        return
    if absf(wildlife_destination.x - wildlife_river_center) < 9.9 or (wildlife_destination.x - wildlife_river_center) * (wildlife_origin.x - sin(wildlife_origin.z * 0.018) * 18.0) <= 0.0:
        push_error("GAMEPLAY_SMOKE_FAIL: wildlife target crossed the river or entered deep water")
        get_tree().quit(1)
        return

    for build_type in ["campfire", "storage", "shelter"]:
        if not build_recipe_buttons.has(build_type) or not (build_recipe_buttons[build_type] as Button).disabled:
            push_error("GAMEPLAY_SMOKE_FAIL: unaffordable recipe should be disabled")
            get_tree().quit(1)
            return

    var test_resource: Dictionary = resource_nodes[0]
    var test_resource_position: Vector3 = test_resource["position"]
    player.global_position = test_resource_position + Vector3(0.0, 1.2, 0.0)
    var interaction := _nearest_interaction_for(player.global_position)
    if str(interaction.get("action", "")) != "gather" or int(interaction.get("index", -1)) != 0:
        push_error("GAMEPLAY_SMOKE_FAIL: nearest resource interaction did not resolve")
        get_tree().quit(1)
        return

    var stone_resource: Dictionary = resource_nodes[5]
    var stone_position: Vector3 = stone_resource["position"]
    for amount in range(3):
        player.global_position = test_resource_position + Vector3(0.0, 1.2, 0.0)
        _server_gather_resource(0, 1)
    for amount in range(2):
        player.global_position = stone_position + Vector3(0.0, 1.2, 0.0)
        _server_gather_resource(5, 1)

    if int(shared_inventory["wood"]) != 3 or int(shared_inventory["stone"]) != 2:
        push_error("GAMEPLAY_SMOKE_FAIL: gathering did not update shared inventory")
        get_tree().quit(1)
        return
    if (build_recipe_buttons["campfire"] as Button).disabled:
        push_error("GAMEPLAY_SMOKE_FAIL: affordable campfire recipe remained disabled")
        get_tree().quit(1)
        return

    var inventory_before_invalid_place := shared_inventory.duplicate(true)
    var previous_build_count := placed_buildings.size()
    _server_place_building("campfire", Vector3(0.0, _height_at(0.0, -4.0) + 1.2, -4.0), 0.0)
    if placed_buildings.size() != previous_build_count or shared_inventory != inventory_before_invalid_place:
        push_error("GAMEPLAY_SMOKE_FAIL: invalid river-side placement consumed materials")
        get_tree().quit(1)
        return

    var test_build_position := Vector3(70.0, _height_at(70.0, 80.0) + 1.2, 80.0)
    _server_place_building("campfire", test_build_position, 0.0, PI * 0.5)
    if not is_equal_approx(float(placed_buildings.back()["rotation"]), PI * 0.5):
        push_error("GAMEPLAY_SMOKE_FAIL: requested structure rotation was not preserved")
        get_tree().quit(1)
        return
    if placed_buildings.size() != previous_build_count + 1:
        push_error("GAMEPLAY_SMOKE_FAIL: campfire recipe or placement failed")
        get_tree().quit(1)
        return
    if int(shared_inventory["wood"]) != 0 or int(shared_inventory["stone"]) != 0:
        push_error("GAMEPLAY_SMOKE_FAIL: crafting did not consume recipe materials")
        get_tree().quit(1)
        return
    if not (build_recipe_buttons["campfire"] as Button).disabled:
        push_error("GAMEPLAY_SMOKE_FAIL: depleted campfire recipe remained enabled")
        get_tree().quit(1)
        return

    _save_game()
    var saved := ConfigFile.new()
    if saved.load(SAVE_PATH) != OK:
        push_error("GAMEPLAY_SMOKE_FAIL: save file could not be reopened")
        get_tree().quit(1)
        return
    var saved_inventory: Variant = saved.get_value("world", "shared_inventory", {})
    var saved_buildings: Variant = saved.get_value("world", "placed_buildings", [])
    var saved_resources: Variant = saved.get_value("world", "resource_amounts", [])
    if not (saved_inventory is Dictionary) or int(saved_inventory.get("wood", -1)) != 0:
        push_error("GAMEPLAY_SMOKE_FAIL: inventory was not persisted")
        get_tree().quit(1)
        return
    if not (saved_buildings is Array) or saved_buildings.size() != placed_buildings.size():
        push_error("GAMEPLAY_SMOKE_FAIL: placed structures were not persisted")
        get_tree().quit(1)
        return
    if not (saved_resources is Array) or int(saved_resources[0]) != 1:
        push_error("GAMEPLAY_SMOKE_FAIL: depleted resource state was not persisted")
        get_tree().quit(1)
        return

    print("GAMEPLAY_SMOKE_PASS  •  gathering, recipes, placement, and persistence")
    get_tree().quit(0)

func _request_lan_smoke_gather() -> void:
    if not lan_active or multiplayer.is_server():
        return
    _try_interact()
    print("LAN_SMOKE_CLIENT_REQUESTED_GATHER")

func _start_lan_smoke_host() -> void:
    _host_lan_game()
    if not lan_active:
        push_error("LAN_SMOKE_HOST_FAIL: host could not bind UDP port")
        get_tree().quit(1)
        return
    print("LAN_SMOKE_HOST_READY")
    get_tree().create_timer(12.0).timeout.connect(_finish_lan_smoke_host)

func _start_lan_smoke_client() -> void:
    address_input.text = "127.0.0.1"
    _join_lan_game()
    if not lan_active:
        push_error("LAN_SMOKE_CLIENT_FAIL: client could not start")
        get_tree().quit(1)
        return
    print("LAN_SMOKE_CLIENT_STARTED")
    get_tree().create_timer(8.0).timeout.connect(_finish_lan_smoke_client)

func _move_lan_smoke_client() -> void:
    if not lan_active or multiplayer.is_server():
        return
    player.global_position = Vector3(31.0, _height_at(31.0, -11.0) + 1.2, -11.0)
    print("LAN_SMOKE_CLIENT_MOVED")
    get_tree().create_timer(0.3).timeout.connect(_request_lan_smoke_gather)

func _finish_lan_smoke_client() -> void:
    var inventory_synced := int(shared_inventory.get("wood", 0)) >= 1
    var resource_synced := resource_nodes.size() > 0 and int(resource_nodes[0]["amount"]) == 3
    var host_avatar_seen := network_remote_players.has(1)
    print("LAN_SMOKE_CLIENT_STATE  •  connected %s  •  host avatar %s  •  wood %d  •  resource amount %d" % [
        str(lan_active and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED),
        str(host_avatar_seen),
        int(shared_inventory.get("wood", 0)),
        int(resource_nodes[0]["amount"]) if resource_nodes.size() > 0 else -1
    ])
    if lan_active and multiplayer.get_unique_id() > 1 and host_avatar_seen and inventory_synced and resource_synced:
        lan_smoke_client_passed = true
        print("LAN_SMOKE_CLIENT_PASS  •  shared gathering state synchronized")
    else:
        push_error("LAN_SMOKE_CLIENT_FAIL: shared gather state not synchronized; keeping connection open for host diagnostics")

func _finish_lan_smoke_host() -> void:
    if OS.get_cmdline_user_args().has("--lan-smoke-host"):
        print("LAN_SMOKE_HOST_STATE  •  peers %d  •  wood %d  •  resource amount %d" % [
            multiplayer.get_peers().size(),
            int(shared_inventory.get("wood", 0)),
            int(resource_nodes[0]["amount"]) if resource_nodes.size() > 0 else -1
        ])
    var peers := multiplayer.get_peers()
    if peers.size() != 1:
        push_error("LAN_SMOKE_HOST_FAIL: expected one connected client, got %d" % peers.size())
        get_tree().quit(1)
        return
    var remote_id: int = peers[0]
    if not network_remote_players.has(remote_id):
        push_error("LAN_SMOKE_HOST_FAIL: remote avatar was not created")
        get_tree().quit(1)
        return
    var remote_avatar: Node3D = network_remote_players[remote_id]
    if int(shared_inventory.get("wood", 0)) < 1 or int(resource_nodes[0]["amount"]) != 3:
        push_error("LAN_SMOKE_HOST_FAIL: gathered resource was not applied by host")
        get_tree().quit(1)
        return
    var moved_distance := Vector2(remote_avatar.position.x - 18.0, remote_avatar.position.z - 2.0).length()
    if moved_distance < 2.0:
        push_error("LAN_SMOKE_HOST_FAIL: player movement did not synchronize (%.2f)" % moved_distance)
        get_tree().quit(1)
        return
    print("LAN_SMOKE_HOST_PASS  •  remote displacement %.2f" % moved_distance)
    _disconnect_lan_game()
    get_tree().quit(0)

func _save_game() -> void:
    if not player:
        return
    var config := ConfigFile.new()
    config.set_value("world", "clock", world_clock)
    config.set_value("world", "memory_awakened", memory_awakened)
    config.set_value("player", "health", health)
    config.set_value("player", "hunger", hunger)
    config.set_value("player", "thirst", thirst)
    config.set_value("player", "rest", rest)
    config.set_value("player", "position", player.global_position)
    config.set_value("controls", "camera_sensitivity", camera_sensitivity)
    config.set_value("controls", "camera_distance", camera_distance)
    config.set_value("controls", "camera_fov", camera_fov)
    config.set_value("controls", "button_opacity", button_opacity)
    config.set_value("controls", "button_scale", control_scale)
    for action in action_buttons:
        var button: TouchScreenButton = action_buttons[action]
        config.set_value("controls", str(action), button.position)

    var berry_servings: Array[int] = []
    for bush in berry_bushes:
        berry_servings.append(int(bush["servings"]))
    config.set_value("world", "berry_servings", berry_servings)

    var resource_amounts: Array[int] = []
    for resource in resource_nodes:
        resource_amounts.append(int(resource["amount"]))
    config.set_value("world", "resource_amounts", resource_amounts)
    config.set_value("world", "shared_inventory", shared_inventory)
    config.set_value("world", "placed_buildings", placed_buildings)

    var error := config.save(SAVE_PATH)
    if error == OK:
        save_elapsed = 0.0
    else:
        push_warning("Could not save WORLDS progress. Error: %d" % error)

func _load_game() -> void:
    if not player:
        return
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return

    world_clock = fposmod(float(config.get_value("world", "clock", world_clock)), 24.0)
    health = clampf(float(config.get_value("player", "health", health)), 0.0, 100.0)
    hunger = clampf(float(config.get_value("player", "hunger", hunger)), 0.0, 100.0)
    thirst = clampf(float(config.get_value("player", "thirst", thirst)), 0.0, 100.0)
    if health_bar:
        health_bar.value = health
    rest = clampf(float(config.get_value("player", "rest", rest)), 0.0, 100.0)
    camera_sensitivity = clampf(float(config.get_value("controls", "camera_sensitivity", camera_sensitivity)), 0.003, 0.012)
    camera_distance = clampf(float(config.get_value("controls", "camera_distance", camera_distance)), 4.0, 12.0)
    camera_fov = clampf(float(config.get_value("controls", "camera_fov", camera_fov)), 55.0, 85.0)
    button_opacity = clampf(float(config.get_value("controls", "button_opacity", button_opacity)), 0.4, 1.0)
    _on_camera_distance_changed(camera_distance)
    _on_camera_fov_changed(camera_fov)
    _on_button_opacity_changed(button_opacity)
    control_scale = clampf(float(config.get_value("controls", "button_scale", control_scale)), 0.75, 1.35)
    _on_control_scale_changed(control_scale)
    for action in action_buttons:
        var saved_control_position: Variant = config.get_value("controls", str(action), action_buttons[action].position)
        if typeof(saved_control_position) == TYPE_VECTOR2:
            _move_action_button(str(action), saved_control_position)

    var saved_position: Variant = config.get_value("player", "position", player.global_position)
    if typeof(saved_position) == TYPE_VECTOR3:
        var restored_position: Vector3 = saved_position
        restored_position.x = clampf(restored_position.x, -WORLD_SIZE * 0.48, WORLD_SIZE * 0.48)
        restored_position.z = clampf(restored_position.z, -WORLD_SIZE * 0.48, WORLD_SIZE * 0.48)
        restored_position.y = _height_at(restored_position.x, restored_position.z) + 1.2
        player.global_position = restored_position

    var saved_berries: Variant = config.get_value("world", "berry_servings", [])
    if saved_berries is Array:
        for index in range(mini(saved_berries.size(), berry_bushes.size())):
            var bush: Dictionary = berry_bushes[index]
            bush["servings"] = clampi(int(saved_berries[index]), 0, 3)
            berry_bushes[index] = bush

    var saved_inventory: Variant = config.get_value("world", "shared_inventory", {})
    if saved_inventory is Dictionary:
        for key in ["wood", "stone", "fiber"]:
            shared_inventory[key] = maxi(0, int(saved_inventory.get(key, 0)))
    _update_inventory_ui()

    var saved_resources: Variant = config.get_value("world", "resource_amounts", [])
    if saved_resources is Array:
        for index in range(mini(saved_resources.size(), resource_nodes.size())):
            _set_resource_amount_local(index, int(saved_resources[index]))

    var saved_buildings: Variant = config.get_value("world", "placed_buildings", [])
    if saved_buildings is Array:
        for building in saved_buildings:
            if not (building is Dictionary):
                continue
            var build_type := str(building.get("type", ""))
            var build_position: Variant = building.get("position", Vector3.ZERO)
            var build_facing := float(building.get("rotation", 0.0))
            if build_type in ["campfire", "storage", "shelter"] and typeof(build_position) == TYPE_VECTOR3:
                _spawn_building_visual(build_type, build_position, build_facing, true)

    if bool(config.get_value("world", "memory_awakened", false)):
        _apply_world_memory()
    save_elapsed = 0.0

func _on_quality_selected(index: int) -> void:
    _apply_quality_preset(index)

func _apply_quality_preset(index: int) -> void:
    quality_index = index
    var density := 0.74
    var shadows := false
    var fog_enabled := true
    match index:
        0: # Auto starts from a safe balanced profile; the adaptive loop tunes it.
            density = 0.70 if OS.get_processor_count() <= 4 else 0.82
            shadows = false
            fog_enabled = true
        1: # Low
            density = 0.48
            shadows = false
            fog_enabled = false
        2: # Balanced
            density = 0.72
            shadows = false
            fog_enabled = true
        3: # High
            density = 0.90
            shadows = true
            fog_enabled = true
        4: # Ultra
            density = 1.0
            shadows = true
            fog_enabled = true

    _set_tree_density(density)
    if sun_light:
        sun_light.shadow_enabled = shadows
    if world_environment:
        world_environment.fog_enabled = fog_enabled
        world_environment.fog_density = 0.0024 if fog_enabled else 0.0

func _set_tree_density(density: float) -> void:
    current_tree_density = clampf(density, 0.35, 1.0)
    if total_tree_instances <= 0:
        return
    var visible_count := clampi(roundi(float(total_tree_instances) * current_tree_density), 1, total_tree_instances)
    if tree_trunks and tree_trunks.multimesh:
        tree_trunks.multimesh.visible_instance_count = visible_count
    if tree_canopies and tree_canopies.multimesh:
        tree_canopies.multimesh.visible_instance_count = visible_count
    var visible_pines := clampi(roundi(float(total_pine_instances) * current_tree_density), 1, maxi(1, total_pine_instances))
    if pine_trunks and pine_trunks.multimesh:
        pine_trunks.multimesh.visible_instance_count = visible_pines
    if pine_canopies and pine_canopies.multimesh:
        pine_canopies.multimesh.visible_instance_count = visible_pines
    if grass_field and grass_field.multimesh:
        grass_field.multimesh.visible_instance_count = clampi(roundi(float(total_grass_instances) * current_tree_density), 1, total_grass_instances)
    if rock_field and rock_field.multimesh:
        rock_field.multimesh.visible_instance_count = clampi(roundi(float(total_rock_instances) * current_tree_density), 1, total_rock_instances)
    var visible_animals := clampi(roundi(float(wildlife_agents.size()) * current_tree_density), 0, wildlife_agents.size())
    for index in range(wildlife_agents.size()):
        var animal: Dictionary = wildlife_agents[index]
        var root: Node3D = animal["root"]
        if is_instance_valid(root):
            root.visible = index < visible_animals

func _on_fps_selected(index: int) -> void:
    current_fps_target = fps_option.get_item_id(index)
    Engine.max_fps = current_fps_target
    if fps_label:
        fps_label.text = "FPS cap: %d  •  Device limit may be lower" % current_fps_target

func _update_adaptive_quality(delta: float) -> void:
    if quality_index != 0:
        return
    adaptive_check_timer += delta
    if adaptive_check_timer < 3.0:
        return
    adaptive_check_timer = 0.0

    var actual_fps := Engine.get_frames_per_second()
    var next_density := current_tree_density
    if actual_fps > 0 and actual_fps < float(current_fps_target) * 0.78:
        next_density = maxf(0.40, current_tree_density - 0.08)
        if sun_light:
            sun_light.shadow_enabled = false
        if world_environment:
            world_environment.fog_enabled = false
    elif actual_fps >= float(current_fps_target) * 0.96:
        next_density = minf(0.90, current_tree_density + 0.025)

    if not is_equal_approx(next_density, current_tree_density):
        _set_tree_density(next_density)
    if fps_label:
        fps_label.text = "Auto  •  %d FPS  •  Trees %d%%" % [
            actual_fps,
            roundi(current_tree_density * 100.0)
        ]

func _button_down(action: String) -> bool:
    return pressed_actions.has(action)
