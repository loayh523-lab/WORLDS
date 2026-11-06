extends Node3D

const WORLD_SIZE := 120.0
const GRID_STEPS := 100
const PLAYER_SPEED := 7.0
const GRAVITY := 22.0
const JUMP_VELOCITY := 8.0
const CAMERA_DRAG_SENSITIVITY := 0.006

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var pressed_actions: Dictionary = {}
var hud_label: Label
var mobile_controls: Control
var world_environment: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D
var world_clock := 8.0

func _ready() -> void:
    _create_environment()
    _create_terrain()
    _create_river()
    _create_forest()
    _create_player()
    _create_hud()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        pressed_actions.clear()

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
    var hills := sin(x * 0.055) * 1.7 + cos(z * 0.047) * 1.5
    hills += sin((x + z) * 0.025) * 2.2
    var river_bank := abs(x - sin(z * 0.035) * 8.0)
    var valley := -max(0.0, 1.0 - river_bank / 13.0) * 1.1
    return hills + valley

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

            var tint := Color(0.22, 0.42, 0.20)
            var variation := clamp((y + 4.0) / 12.0, 0.0, 1.0)
            tint = tint.lerp(Color(0.38, 0.48, 0.29), variation * 0.55)
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
        var center_x := sin(z * 0.035) * 8.0
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
    var water_material := StandardMaterial3D.new()
    water_material.albedo_color = Color(0.10, 0.42, 0.62, 0.88)
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water_material.roughness = 0.18
    water_material.metallic = 0.12
    water_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    water.mesh.surface_set_material(0, water_material)
    add_child(water)

func _create_forest() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261106

    var tree_positions: Array[Dictionary] = []
    for i in range(95):
        var x := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        var z := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        if abs(x - sin(z * 0.035) * 8.0) < 7.0:
            continue
        if Vector2(x, z).length() < 12.0:
            continue
        tree_positions.append({
            "position": Vector3(x, _height_at(x, z), z),
            "scale": rng.randf_range(0.8, 1.35)
        })

    _create_tree_instances(tree_positions)

func _create_tree_instances(tree_positions: Array[Dictionary]) -> void:
    if tree_positions.is_empty():
        return

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.28
    trunk_mesh.height = 2.1

    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.27, 0.16, 0.09)
    bark.roughness = 1.0

    var trunk_multi := MultiMesh.new()
    trunk_multi.transform_format = MultiMesh.TRANSFORM_3D
    trunk_multi.mesh = trunk_mesh
    trunk_multi.instance_count = tree_positions.size()

    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.05
    crown_mesh.height = 2.0

    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.12, 0.31, 0.15)
    leaves.roughness = 0.92

    var crown_multi := MultiMesh.new()
    crown_multi.transform_format = MultiMesh.TRANSFORM_3D
    crown_multi.mesh = crown_mesh
    crown_multi.instance_count = tree_positions.size()

    for i in range(tree_positions.size()):
        var tree_data: Dictionary = tree_positions[i]
        var tree_position: Vector3 = tree_data["position"]
        var tree_scale: float = tree_data["scale"]

        var trunk_basis := Basis.from_scale(Vector3(tree_scale, tree_scale, tree_scale))
        var trunk_transform := Transform3D(trunk_basis, tree_position + Vector3(0, 1.05 * tree_scale, 0))
        trunk_multi.set_instance_transform(i, trunk_transform)

        var crown_basis := Basis.from_scale(Vector3(tree_scale, tree_scale, tree_scale))
        var crown_transform := Transform3D(crown_basis, tree_position + Vector3(0, 2.45 * tree_scale, 0))
        crown_multi.set_instance_transform(i, crown_transform)

    var trunks := MultiMeshInstance3D.new()
    trunks.name = "TreeTrunks"
    trunks.multimesh = trunk_multi
    trunks.material_override = bark
    add_child(trunks)

    var crowns := MultiMeshInstance3D.new()
    crowns.name = "TreeCanopies"
    crowns.multimesh = crown_multi
    crowns.material_override = leaves
    add_child(crowns)

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

    var body_mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.42
    capsule_mesh.height = 1.8
    body_mesh.mesh = capsule_mesh
    body_mesh.position.y = 0.9
    var player_material := StandardMaterial3D.new()
    player_material.albedo_color = Color(0.82, 0.72, 0.48)
    body_mesh.material_override = player_material
    player.add_child(body_mesh)

    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, 1.55, 0)
    player.add_child(camera_pivot)

    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.position = Vector3(0, 2.8, 7.0)
    camera.rotation_degrees = Vector3(-14, 0, 0)
    camera.current = true
    camera_pivot.add_child(camera)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(250, 62)
    layer.add_child(panel)

    hud_label = Label.new()
    hud_label.text = "WORLDS  •  EARLY ACCESS PROTOTYPE\nExplore the valley"
    hud_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88))
    hud_label.add_theme_font_size_override("font_size", 16)
    panel.add_child(hud_label)

    mobile_controls = Control.new()
    mobile_controls.name = "TouchControls"
    mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(mobile_controls)

    var screen_size := get_viewport().get_visible_rect().size
    _add_control_button("◀", Vector2(24, screen_size.y - 112), "left")
    _add_control_button("▶", Vector2(144, screen_size.y - 112), "right")
    _add_control_button("▲", Vector2(84, screen_size.y - 172), "forward")
    _add_control_button("▼", Vector2(84, screen_size.y - 52), "back")
    _add_control_button("JUMP", Vector2(screen_size.x - 136, screen_size.y - 104), "jump", true)

func _add_control_button(label_text: String, position: Vector2, action: String, is_jump := false) -> void:
    var button := Button.new()
    button.text = label_text
    button.position = position
    button.custom_minimum_size = Vector2(56, 56) if not is_jump else Vector2(112, 64)
    button.focus_mode = Control.FOCUS_NONE
    button.modulate = Color(1.0, 1.0, 1.0, 0.82)
    button.add_theme_font_size_override("font_size", 18 if not is_jump else 15)
    button.button_down.connect(_on_control_pressed.bind(action))
    button.button_up.connect(_on_control_released.bind(action))
    mobile_controls.add_child(button)

func _on_control_pressed(action: String) -> void:
    pressed_actions[action] = true

func _on_control_released(action: String) -> void:
    pressed_actions.erase(action)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        _rotate_camera(event.relative, event.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _rotate_camera(event.relative, event.position)

func _rotate_camera(relative: Vector2, pointer_position: Vector2) -> void:
    if not camera or not camera_pivot:
        return

    var screen_size := get_viewport().get_visible_rect().size
    # Keep the lower control area free for movement and jump buttons.
    if pointer_position.y > screen_size.y - 185.0:
        return
    if pointer_position.x < screen_size.x * 0.40:
        return

    camera_pivot.rotation.y -= relative.x * CAMERA_DRAG_SENSITIVITY
    camera.rotation.x = clamp(
        camera.rotation.x - relative.y * CAMERA_DRAG_SENSITIVITY,
        deg_to_rad(-38.0),
        deg_to_rad(-5.0)
    )

func _process(delta: float) -> void:
    _update_day_cycle(delta)
    if hud_label and player:
        var hours := int(world_clock)
        var minutes := int((world_clock - float(hours)) * 60.0)
        var time_text := "%02d:%02d" % [hours, minutes]
        hud_label.text = "WORLDS  •  PROTOTYPE\nWorld time: %s   •   Position: %d, %d" % [
            time_text,
            roundi(player.position.x),
            roundi(player.position.z)
        ]

func _update_day_cycle(delta: float) -> void:
    if not sun_light or not world_environment or not sky_material:
        return

    # One full in-game day lasts 20 real minutes.
    world_clock = fposmod(world_clock + delta * 24.0 / 1200.0, 24.0)
    var daylight := clamp(sin((world_clock - 6.0) / 12.0 * PI), 0.0, 1.0)
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

    var horizontal := Vector2.ZERO
    horizontal.x = float(Input.is_key_pressed(KEY_D) or _button_down("right")) - float(Input.is_key_pressed(KEY_A) or _button_down("left"))
    horizontal.y = float(Input.is_key_pressed(KEY_S) or _button_down("back")) - float(Input.is_key_pressed(KEY_W) or _button_down("forward"))
    horizontal = horizontal.normalized()

    var camera_forward := -camera.global_transform.basis.z
    var camera_right := camera.global_transform.basis.x
    camera_forward.y = 0.0
    camera_right.y = 0.0
    camera_forward = camera_forward.normalized()
    camera_right = camera_right.normalized()

    var direction := camera_right * horizontal.x - camera_forward * horizontal.y
    direction = direction.normalized()

    player.velocity.x = direction.x * PLAYER_SPEED
    player.velocity.z = direction.z * PLAYER_SPEED

    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    elif Input.is_key_pressed(KEY_SPACE) or _button_down("jump"):
        player.velocity.y = JUMP_VELOCITY
    else:
        player.velocity.y = 0.0

    player.move_and_slide()

func _button_down(action: String) -> bool:
    return pressed_actions.has(action)
