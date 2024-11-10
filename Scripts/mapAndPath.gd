extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	createMap()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
var ramerDouglasPeuckerValue = 2
static var map_cell_size: float = 0.25
static var chunk_size: int = 250
static var cell_size: float = 0.5
static var agent_radius: float = 1
static var chunk_id_to_region: Dictionary = {}
@onready var Chunks = $"../Chunks"

func createMap():
	NavigationServer3D.set_debug_enabled(true)


	var map: RID = get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, map_cell_size)

	# Disable performance costly edge connection margin feature.
	# This feature is not needed to merge navigation mesh edges.
	# If edges are well aligned they will merge just fine by edge key.
	NavigationServer3D.map_set_use_edge_connections(map, false)

	# Parse the collision shapes below our parse root node.
	var source_geometry: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	var parse_settings: NavigationMesh = NavigationMesh.new()
	parse_settings.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	NavigationServer3D.parse_source_geometry_data(parse_settings, source_geometry, self)

	create_region_chunks(Chunks, source_geometry, chunk_size * cell_size, agent_radius)
	
static func create_region_chunks(chunks_root_node: Node, p_source_geometry: NavigationMeshSourceGeometryData3D, p_chunk_size: float, p_agent_radius: float) -> void:
	# We need to know how many chunks are required for the input geometry.
	# So first get an axis aligned bounding box that covers all vertices.
	var input_geometry_bounds: AABB = calculate_source_geometry_bounds(p_source_geometry)

	# Rasterize bounding box into chunk grid to know range of required chunks.
	var start_chunk: Vector3 = floor(
		input_geometry_bounds.position / p_chunk_size
	)
	var end_chunk: Vector3 = floor(
		(input_geometry_bounds.position + input_geometry_bounds.size)
		/ p_chunk_size
	)

	# NavigationMesh.border_size is limited to the xz-axis.
	# So we can only bake one chunk for the y-axis and also
	# need to span the bake bounds over the entire y-axis.
	# If we dont do this we would create duplicated polygons
	# and stack them on top of each other causing merge errors.
	var bounds_min_height: float = start_chunk.y
	var bounds_max_height: float = end_chunk.y + p_chunk_size
	var chunk_y: int = 0

	for chunk_z in range(start_chunk.z, end_chunk.z + 1):
		for chunk_x in range(start_chunk.x, end_chunk.x + 1):
			var chunk_id: Vector3i = Vector3i(chunk_x, chunk_y, chunk_z)

			var chunk_bounding_box: AABB = AABB(
				Vector3(chunk_x, bounds_min_height, chunk_z) * p_chunk_size,
				Vector3(p_chunk_size, bounds_max_height, p_chunk_size),
			)
			# We grow the chunk bounding box to include geometry
			# from all the neighbor chunks so edges can align.
			# The border size is the same value as our grow amount so
			# the final navigation mesh ends up with the intended chunk size.
			var baking_bounds: AABB = chunk_bounding_box.grow(p_chunk_size)

			var chunk_navmesh: NavigationMesh = NavigationMesh.new()
			chunk_navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
			chunk_navmesh.cell_size = cell_size
			chunk_navmesh.cell_height = 0.1
			chunk_navmesh.filter_baking_aabb = baking_bounds
			chunk_navmesh.border_size = p_chunk_size
			chunk_navmesh.agent_radius = p_agent_radius
			chunk_navmesh.agent_max_climb = 2
			NavigationServer3D.bake_from_source_geometry_data(chunk_navmesh, p_source_geometry)

			# The only reason we reset the baking bounds here is to not render its debug.
			chunk_navmesh.filter_baking_aabb = AABB()

			# Snap vertex positions to avoid most rasterization issues with float precision.
			var navmesh_vertices: PackedVector3Array = chunk_navmesh.vertices
			for i in navmesh_vertices.size():
				var vertex: Vector3 = navmesh_vertices[i]
				navmesh_vertices[i] = vertex.snappedf(map_cell_size * 0.1)
			chunk_navmesh.vertices = navmesh_vertices

			var chunk_region: NavigationRegion3D = NavigationRegion3D.new()
			chunk_region.navigation_mesh = chunk_navmesh
			chunks_root_node.add_child(chunk_region)

			chunk_id_to_region[chunk_id] = chunk_region
			
			
			
static func calculate_source_geometry_bounds(p_source_geometry: NavigationMeshSourceGeometryData3D) -> AABB:
	if p_source_geometry.has_method("get_bounds"):
		# Godot 4.3 Patch added get_bounds() function that does the same but faster.
		return p_source_geometry.call("get_bounds")

	var bounds: AABB = AABB()
	var first_vertex: bool = true

	var vertices: PackedFloat32Array = p_source_geometry.get_vertices()
	var vertices_count: int = vertices.size() / 3
	for i in vertices_count:
		var vertex: Vector3 = Vector3(vertices[i * 3], vertices[i * 3 + 1], vertices[i * 3 + 2])
		if first_vertex:
			first_vertex = false
			bounds.position = vertex
		else:
			bounds = bounds.expand(vertex)

	for projected_obstruction: Dictionary in p_source_geometry.get_projected_obstructions():
		var projected_obstruction_vertices: PackedFloat32Array = projected_obstruction["vertices"]
		for i in projected_obstruction_vertices.size() / 3:
			var vertex: Vector3 = Vector3(projected_obstruction.vertices[i * 3], projected_obstruction.vertices[i * 3 + 1], projected_obstruction.vertices[i * 3 + 2]);
			if first_vertex:
				first_vertex = false
				bounds.position = vertex
			else:
				bounds = bounds.expand(vertex)

	return bounds
	
	
	
	
func getPath(startPoint, finalPoint):
	var map: RID = get_world_3d().navigation_map
	var path = ramer_douglas_peucker(NavigationServer3D.map_get_path(map,startPoint,finalPoint,true),ramerDouglasPeuckerValue)
	return path
	
	
static func ramer_douglas_peucker(points: PackedVector3Array, epsilon: float) -> PackedVector3Array:
	if points.size() < 3:
		return points.duplicate()
	var epsilon_squared = pow(epsilon, 2)	
	var result := PackedVector3Array()
	_simplify(result, points, 0, points.size() - 1, epsilon_squared)
	result.append(points[-1])
	return result

# Recursive calculation
static func _simplify(result: PackedVector3Array, points: PackedVector3Array, start: int, end: int, epsilon_squared: float) -> void:
	var max_distance_squared = 0
	var index = 0
	
	for i in range(start, end + 1):
		var distance = _perpendicular_squared(points[i], points[start], points[end])
		if distance > max_distance_squared:
			max_distance_squared = distance
			index = i
	
	if max_distance_squared <= epsilon_squared:
		result.append(points[start])
	else:
		_simplify(result, points, start, index, epsilon_squared)
		_simplify(result, points, index, end, epsilon_squared)

static func _perpendicular_squared(target: Vector3, p1: Vector3, p2: Vector3) -> float:
	var to_target = target - p1
	var to_end = p2 - p1
	var project = to_target.project(to_end)
	return to_target.length_squared() - project.length_squared()
