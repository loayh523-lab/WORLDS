extends Node3D

const WORLD_SIZE := 120.0
const GRID_STEPS := 100
const PLAYER_SPEED := 7.0
const GRAVITY := 22.0
const JUMP_VELOCITY := 8.0

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var move_buttons: Dictionary = {}
var hud_label: Label
var mobile_controls: Control

func _ready() -> void:
    _create_environment()
    _create_terrain()
    _create_river()
    _create_forest()
    _create_player()
    _create_hud()

func _create_environment() -> void:
    var world_env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.16, 0.35, 0.56)
    sky_material.sky_horizon_color = Color(0.72, 0.82, 0.86)
    sky_material.ground_bottom_color = Color(0.12, 0.18, 0.15)
    sky_material.ground_horizon_color = Color(0.48, 0.58, 0.48)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.82, 0.92)
    environment.ambient_light_energy = 0.65
    world_env.environment = environment
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

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
            indices.append_array(PackedInt32Array([a, c, b, b, c, d]))

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
    terrain.mesh = mesh
    add_child(terrain)

    var body := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(vertices_to_faces(vertices, indices))
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func vertices_to_faces(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
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
        vertices.append(Vector3(center_x - 4.2, _height_at(center_x, z) - 0.16, z))
        vertices.append(Vector3(center_x + 4.2, _height_at(center_x, z) - 0.16, z))
    for i in range(segments):
        var a := i * 2
        indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices
    river_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var water := MeshInstance3D.new()
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
    for i in range(95):
        var x := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        var z := rng.randf_range(-WORLD_SIZE * 0.46, WORLD_SIZE * 0.46)
        if abs(x - sin(z * 0.035) * 8.0) < 7.0:
            continue
        if Vector2(x, z).length() < 12.0:
            continue
        _add_tree(Vector3(x, _height_at(x, z), z), rng.randf_range(0.8, 1.35))

func _add_tree(position: Vector3, scale_factor: float) -> void:
    var tree := Node3D.new()
    tree.position = position
    tree.scale = Vector3.ONE * scale_factor
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.28
    trunk_mesh.height = 2.1
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.05
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.27, 0.16, 0.09)
    trunk.material_override = bark
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.05
    crown_mesh.height = 2.0
    crown.mesh = crown_mesh
    crown.position.y = 2.45
    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.12, 0.31, 0.15)
    leaves.roughness = 0.92
    crown.material_override = leaves
    tree.add_child(crown)

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, _height_at(0, 0) + 2.0, 0)
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
    camera_pivot.position = Vector3(0, 1.55, 0)
    player.add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 2.8, 7.0)
    camera.rotation_degrees = Vector3(-14, 0, 0)
    camera.current = true
    camera_pivot.add_child(camera)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(250, 62)
    layer.add_child(panel)
    hud_label = Label.new()
    hud_label.text = "WORLDS  •  Early World Prototype\nExplore the valley"
    hud_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88))
    panel.add_child(hud_label)

    mobile_controls = Control.new()
    mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(mobile_controls)
    _add_control_button("◀", Vector2(28, -104), "left")
    _add_control_button("▶", Vector2(148, -104), "right")
    _add_control_button("▲", Vector2(88, -164), "forward")
    _add_control_button("▼", Vector2(88, -44), "back")
    _add_control_button("JUMP", Vector2(-132, -92), "jump", true)

func _add_control_button(label_text: String, offset: Vector2, action: String, right_side := false) -> void:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(56, 56) if not right_side else Vector2(112, 64)
    button.position = Vector2(get_viewport().get_visible_rect().size.x + offset.x, get_viewport().get_visible_rect().size.y + offset.y) if right_side else Vector2(24 + offset.x, get_viewport().get_visible_rect().size.y + offset.y)
    button.modulate = Color(1, 1, 1, 0.78)
    mobile_controls.add_child(button)
    move_buttons[action] = button

func _process(_delta: float) -> void:
    if hud_label and player:
        hud_label.text = "WORLDS  •  Prototype\nPosition: %d, %d" % [roundi(player.position.x), roundi(player.position.z)]

func _physics_process(delta: float) -> void:
    if not player:
        return
    var input_vector := Vector2.ZERO
    input_vector.x = float(Input.is_key_pressed(KEY_D) or _button_down("right")) - float(Input.is_key_pressed(KEY_A) or _button_down("left"))
    input_vector.y = float(Input.is_key_pressed(KEY_S) or _button_down("back")) - float(Input.is_key_pressed(KEY_W) or _button_down("forward"))
    input_vector = input_vector.normalized()
    var direction := Vector3(input_vector.x, 0, input_vector.y)
    direction = camera.global_basis * direction
    direction.y = 0
    direction = direction.normalized()

    player.velocity.x = direction.x * PLAYER_SPEED
    player.velocity.z = direction.z * PLAYER_SPEED
    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    elif Input.is_key_pressed(KEY_SPACE) or _button_down("jump"):
        player.velocity.y = JUMP_VELOCITY
    player.move_and_slide()

func _button_down(action: String) -> bool:
    if not move_buttons.has(action):
        return false
    var button: Button = move_buttons[action]
    return button.button_pressed
