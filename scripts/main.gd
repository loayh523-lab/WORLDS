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
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var gait_time := 0.0
var pressed_actions: Dictionary = {}
var hud_label: Label
var mobile_controls: Control
var world_environment: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D
var world_clock := 8.0
const SAVE_PATH := "user://worlds_save.cfg"
var save_elapsed := 0.0
var memory_crystal: MeshInstance3D
var hunger := 100.0
var thirst := 100.0
var rest := 100.0
var berry_bushes: Array[Dictionary] = []
var camp_position := Vector3.ZERO
var memory_position := Vector3.ZERO
var memory_awakened := false
var status_note := ""
var status_note_time := 0.0

func _ready() -> void:
    _create_environment()
    _create_terrain()
    _create_river()
    _create_forest()
    _create_foraging_bushes()
    _create_campsite()
    _create_memory_stone()
    _create_player()
    _create_hud()
    _load_game()

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
    camera_pivot.global_position = player.global_position + Vector3(0, 1.55, 0)
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
    _add_control_button("USE", Vector2(screen_size.x - 132, screen_size.y - 178), "interact", true)
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
    if action == "interact":
        _try_interact()
        return
    pressed_actions[action] = true

func _on_control_released(action: String) -> void:
    pressed_actions.erase(action)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        _try_interact()
    elif event is InputEventScreenDrag:
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
    _update_survival(delta)
    save_elapsed += delta
    if save_elapsed >= 15.0:
        _save_game()
    if status_note_time > 0.0:
        status_note_time = max(0.0, status_note_time - delta)
    if hud_label and player:
        var hours := int(world_clock)
        var minutes := int((world_clock - float(hours)) * 60.0)
        var time_text := "%02d:%02d" % [hours, minutes]
        var prompt := _get_interaction_prompt()
        var note := status_note if status_note_time > 0.0 else prompt
        hud_label.text = "WORLDS  •  PROTOTYPE  |  %s\nFood %d%%   Water %d%%   Rest %d%%\n%s" % [
            time_text,
            roundi(hunger),
            roundi(thirst),
            roundi(rest),
            note
        ]

func _update_survival(delta: float) -> void:
    # Needs decline slowly so exploration stays relaxed rather than punishing.
    hunger = max(0.0, hunger - delta * 0.012)
    thirst = max(0.0, thirst - delta * 0.022)
    rest = max(0.0, rest - delta * 0.016)

func _get_interaction_prompt() -> String:
    match _nearest_interaction():
        "drink":
            return "USE / E: Drink from the river"
        "forage":
            return "USE / E: Gather wild berries"
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

    var best_distance := INF
    var best_action := ""

    var river_center := sin(player.position.z * 0.035) * 8.0
    var river_distance := abs(player.position.x - river_center)
    if river_distance < 5.5 and abs(player.position.z) < WORLD_SIZE * 0.5:
        best_distance = river_distance
        best_action = "drink"

    for bush in berry_bushes:
        if int(bush["servings"]) <= 0:
            continue
        var bush_position: Vector3 = bush["position"]
        var distance := Vector2(
            player.position.x - bush_position.x,
            player.position.z - bush_position.z
        ).length()
        if distance < 3.8 and distance < best_distance:
            best_distance = distance
            best_action = "forage"

    if not memory_awakened:
        var memory_distance := Vector2(
            player.position.x - memory_position.x,
            player.position.z - memory_position.z
        ).length()
        if memory_distance < 4.5 and memory_distance < best_distance:
            best_distance = memory_distance
            best_action = "memory"

    var camp_distance := Vector2(
        player.position.x - camp_position.x,
        player.position.z - camp_position.z
    ).length()
    if camp_distance < 4.5 and camp_distance < best_distance:
        best_action = "sleep"

    return best_action

func _try_interact() -> void:
    match _nearest_interaction():
        "drink":
            thirst = min(100.0, thirst + 42.0)
            _show_status_note("You drank fresh water.")
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
                hunger = min(100.0, hunger + 34.0)
                _show_status_note("You gathered and ate wild berries.")
        "sleep":
            world_clock = 7.0
            rest = 100.0
            hunger = max(0.0, hunger - 7.0)
            thirst = max(0.0, thirst - 10.0)
            _show_status_note("You rested at the campsite until morning.")
        "memory":
            _awaken_world_memory()
        _:
            _show_status_note("Nothing nearby to use.")

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
        var trail_x := lerp(memory_position.x, -7.0, progress) + sin(progress * PI * 2.0) * 1.7
        var trail_z := lerp(memory_position.z, -8.0, progress)
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


func _save_game() -> void:
    if not player:
        return

    var config := ConfigFile.new()
    config.set_value("world", "clock", world_clock)
    config.set_value("world", "memory_awakened", memory_awakened)
    config.set_value("player", "hunger", hunger)
    config.set_value("player", "thirst", thirst)
    config.set_value("player", "rest", rest)
    config.set_value("player", "position", player.global_position)

    var bush_servings: Array[int] = []
    for bush in berry_bushes:
        bush_servings.append(int(bush["servings"]))
    config.set_value("world", "berry_servings", bush_servings)

    var save_error := config.save(SAVE_PATH)
    if save_error == OK:
        save_elapsed = 0.0
    else:
        push_warning("WORLDS could not save progress. Error code: %d" % save_error)

func _load_game() -> void:
    if not player:
        return

    var config := ConfigFile.new()
    var load_error := config.load(SAVE_PATH)
    if load_error != OK:
        return

    world_clock = fposmod(float(config.get_value("world", "clock", world_clock)), 24.0)
    hunger = clampf(float(config.get_value("player", "hunger", hunger)), 0.0, 100.0)
    thirst = clampf(float(config.get_value("player", "thirst", thirst)), 0.0, 100.0)
    rest = clampf(float(config.get_value("player", "rest", rest)), 0.0, 100.0)

    var saved_position: Variant = config.get_value("player", "position", player.global_position)
    if typeof(saved_position) == TYPE_VECTOR3:
        var restored_position: Vector3 = saved_position
        restored_position.x = clampf(restored_position.x, -WORLD_SIZE * 0.48, WORLD_SIZE * 0.48)
        restored_position.z = clampf(restored_position.z, -WORLD_SIZE * 0.48, WORLD_SIZE * 0.48)
        player.global_position = restored_position

    var saved_servings: Variant = config.get_value("world", "berry_servings", [])
    if saved_servings is Array:
        for index in range(mini(saved_servings.size(), berry_bushes.size())):
            var bush: Dictionary = berry_bushes[index]
            bush["servings"] = clampi(int(saved_servings[index]), 0, 3)
            berry_bushes[index] = bush

    if bool(config.get_value("world", "memory_awakened", false)):
        _awaken_world_memory()

    save_elapsed = 0.0

func _physics_process(delta: float) -> void:
    if not player or not camera:
        return

    camera_pivot.global_position = player.global_position + Vector3(0, 1.55, 0)

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

func _button_down(action: String) -> bool:
    return pressed_actions.has(action)
