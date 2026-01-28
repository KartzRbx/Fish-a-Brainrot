--!native
--!strict
local CollectionService = game:GetService("CollectionService")

-- Quadtree configuration defaults
local DEFAULT_CAPACITY: number = 8
local DEFAULT_MAX_DEPTH: number = 6
local DEFAULT_BOUNDS_SIZE: number = 10000
local DEFAULT_SEARCH_RADIUS: number = 1000

-- Quadtree node type
type quadtree_node = {
	x: number,
	z: number,
	size: number,
	depth: number,
	models: { Model },
	subdivided: boolean,
	northwest: quadtree_node?,
	northeast: quadtree_node?,
	southwest: quadtree_node?,
	southeast: quadtree_node?,
}

-- Quadtree instance type
export type npc_quadtree = {
	query: (self: npc_quadtree_internal, position: Vector3) -> (Model?, number),
	destroy: (self: npc_quadtree_internal) -> (),
}

type npc_quadtree_internal = npc_quadtree & {
	root: quadtree_node,
	capacity: number,
	max_depth: number,
	search_radius: number,
	tag: string?,
	connections: { RBXScriptConnection },
}

-- Create a new quadtree node
local function create_quadtree_node(x: number, z: number, size: number, depth: number): quadtree_node
	return {
		x = x,
		z = z,
		size = size,
		depth = depth,
		models = {},
		subdivided = false,
		northwest = nil,
		northeast = nil,
		southwest = nil,
		southeast = nil,
	}
end

-- Check if a point is within the bounds of a quadtree node
local function point_in_bounds(node: quadtree_node, x: number, z: number): boolean
	local half_size: number = node.size / 2
	return x >= node.x - half_size and x <= node.x + half_size and z >= node.z - half_size and z <= node.z + half_size
end

-- Check if a circle intersects with a quadtree node's bounds
local function circle_intersects_bounds(node: quadtree_node, x: number, z: number, radius: number): boolean
	local half_size: number = node.size / 2
	local closest_x: number = math.clamp(x, node.x - half_size, node.x + half_size)
	local closest_z: number = math.clamp(z, node.z - half_size, node.z + half_size)

	local distance_x: number = x - closest_x
	local distance_z: number = z - closest_z
	local distance_squared: number = distance_x * distance_x + distance_z * distance_z

	return distance_squared <= radius
end

-- Subdivide a quadtree node into four children
local function subdivide_node(node: quadtree_node, max_depth: number): ()
	if node.subdivided or node.depth >= max_depth then
		return
	end

	local quarter_size: number = node.size / 4
	local half_size: number = node.size / 2
	local new_depth: number = node.depth + 1

	node.northwest = create_quadtree_node(node.x - quarter_size, node.z - quarter_size, half_size, new_depth)
	node.northeast = create_quadtree_node(node.x + quarter_size, node.z - quarter_size, half_size, new_depth)
	node.southwest = create_quadtree_node(node.x - quarter_size, node.z + quarter_size, half_size, new_depth)
	node.southeast = create_quadtree_node(node.x + quarter_size, node.z + quarter_size, half_size, new_depth)

	node.subdivided = true

	-- Redistribute existing models to children
	local models_to_redistribute: { Model } = node.models
	node.models = {}

	for _, model in models_to_redistribute do
		local primary_part: BasePart? = model.PrimaryPart
		if not primary_part then
			continue
		end

		local position: Vector3 = primary_part.Position
		if point_in_bounds(node.northwest :: quadtree_node, position.X, position.Z) then
			quadtree_insert_internal(
				node.northwest :: quadtree_node,
				model,
				max_depth,
				table.maxn(models_to_redistribute)
			)
		elseif point_in_bounds(node.northeast :: quadtree_node, position.X, position.Z) then
			quadtree_insert_internal(
				node.northeast :: quadtree_node,
				model,
				max_depth,
				table.maxn(models_to_redistribute)
			)
		elseif point_in_bounds(node.southwest :: quadtree_node, position.X, position.Z) then
			quadtree_insert_internal(
				node.southwest :: quadtree_node,
				model,
				max_depth,
				table.maxn(models_to_redistribute)
			)
		elseif point_in_bounds(node.southeast :: quadtree_node, position.X, position.Z) then
			quadtree_insert_internal(
				node.southeast :: quadtree_node,
				model,
				max_depth,
				table.maxn(models_to_redistribute)
			)
		end
	end
end

-- Internal recursive insert function
function quadtree_insert_internal(node: quadtree_node, model: Model, max_depth: number, capacity: number): boolean
	local primary_part: BasePart? = model.PrimaryPart
	if not primary_part then
		return false
	end

	local position: Vector3 = primary_part.Position

	if not point_in_bounds(node, position.X, position.Z) then
		return false
	end

	if not node.subdivided then
		if #node.models < capacity or node.depth >= max_depth then
			table.insert(node.models, model)
			return true
		end

		subdivide_node(node, max_depth)
	end

	if node.subdivided then
		if point_in_bounds(node.northwest :: quadtree_node, position.X, position.Z) then
			return quadtree_insert_internal(node.northwest :: quadtree_node, model, max_depth, capacity)
		elseif point_in_bounds(node.northeast :: quadtree_node, position.X, position.Z) then
			return quadtree_insert_internal(node.northeast :: quadtree_node, model, max_depth, capacity)
		elseif point_in_bounds(node.southwest :: quadtree_node, position.X, position.Z) then
			return quadtree_insert_internal(node.southwest :: quadtree_node, model, max_depth, capacity)
		elseif point_in_bounds(node.southeast :: quadtree_node, position.X, position.Z) then
			return quadtree_insert_internal(node.southeast :: quadtree_node, model, max_depth, capacity)
		end
	end

	return false
end

-- Internal recursive remove function
local function quadtree_remove_internal(node: quadtree_node, model: Model): boolean
	local primary_part: BasePart? = model.PrimaryPart
	if not primary_part then
		return false
	end

	local position: Vector3 = primary_part.Position

	if not point_in_bounds(node, position.X, position.Z) then
		return false
	end

	-- Check if model is in this node
	local index: number? = table.find(node.models, model)
	if index then
		table.remove(node.models, index)
		return true
	end

	-- Check children if subdivided
	if node.subdivided then
		local removed = false
		if point_in_bounds(node.northwest :: quadtree_node, position.X, position.Z) then
			removed = quadtree_remove_internal(node.northwest :: quadtree_node, model)
		elseif point_in_bounds(node.northeast :: quadtree_node, position.X, position.Z) then
			removed = quadtree_remove_internal(node.northeast :: quadtree_node, model)
		elseif point_in_bounds(node.southwest :: quadtree_node, position.X, position.Z) then
			removed = quadtree_remove_internal(node.southwest :: quadtree_node, model)
		elseif point_in_bounds(node.southeast :: quadtree_node, position.X, position.Z) then
			removed = quadtree_remove_internal(node.southeast :: quadtree_node, model)
		end
		return removed
	end

	return false
end

-- Internal recursive query function for models within radius
local function quadtree_query_internal(
	node: quadtree_node,
	x: number,
	z: number,
	radius: number,
	results: { Model }
): ()
	if not circle_intersects_bounds(node, x, z, radius) then
		return
	end

	-- Check models in this node
	for _, model in node.models do
		local primary_part: BasePart? = model.PrimaryPart
		if not primary_part then
			continue
		end

		local position: Vector3 = primary_part.Position
		local distance_x: number = position.X - x
		local distance_z: number = position.Z - z
		local distance_squared: number = distance_x * distance_x + distance_z * distance_z

		if distance_squared <= radius then
			table.insert(results, model)
		end
	end

	-- Check children if subdivided
	if node.subdivided then
		quadtree_query_internal(node.northwest :: quadtree_node, x, z, radius, results)
		quadtree_query_internal(node.northeast :: quadtree_node, x, z, radius, results)
		quadtree_query_internal(node.southwest :: quadtree_node, x, z, radius, results)
		quadtree_query_internal(node.southeast :: quadtree_node, x, z, radius, results)
	end
end

local npc_quadtree_module = {}

--[=[
	Creates a new NPC quadtree instance for spatial indexing.
	@param center_x number? -- X coordinate of quadtree center (default: 0)
	@param center_z number? -- Z coordinate of quadtree center (default: 0)
	@param bounds_size number? -- Size of the quadtree bounds (default: 10000)
    @param search_radius number? -- Search radius for queries (default: 1000)
	@param tag string? -- Optional CollectionService tag to auto-track NPCs
	@return npc_quadtree -- The quadtree instance
]=]
function npc_quadtree_module.new(
	center_x: number?,
	center_z: number?,
	bounds_size: number?,
	search_radius: number?,
	tag: string?
): npc_quadtree
	local self: npc_quadtree_internal = {
		root = create_quadtree_node(center_x or 0, center_z or 0, bounds_size or DEFAULT_BOUNDS_SIZE, 0),
		capacity = DEFAULT_CAPACITY,
		max_depth = DEFAULT_MAX_DEPTH,
		search_radius = (search_radius or DEFAULT_SEARCH_RADIUS) ^ 2,
		tag = tag,
		connections = {},
	} :: any

	-- Setup a new NPC model in the quadtree
	local function setup_npc(instance: Instance): ()
		if not instance:IsA("Model") then
			warn(string.format("NPC tag applied to non-Model instance: %s", instance:GetFullName()))
			return
		end

		local model = instance :: Model
		if not model.PrimaryPart then
			warn(string.format("NPC model %s has no PrimaryPart", model:GetFullName()))
			return
		end

		quadtree_insert_internal(self.root, model, self.max_depth, self.capacity)
	end

	-- Remove an NPC model from the quadtree
	local function destroy_npc(instance: Instance): ()
		if not instance:IsA("Model") then
			return
		end

		local model = instance :: Model
		quadtree_remove_internal(self.root, model)
	end

	-- If a tag is provided, set up CollectionService integration
	if tag then
		table.insert(self.connections, CollectionService:GetInstanceAddedSignal(tag):Connect(setup_npc))
		table.insert(self.connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(destroy_npc))

		-- Add existing tagged instances
		for _, instance in CollectionService:GetTagged(tag) do
			setup_npc(instance)
		end
	end

	--[=[
		Query the quadtree for the nearest NPC model to a given position.
		Optimized for high-frequency calls (multiple times per second).
		@param position Vector3 -- The world position to search from
		@return Model? -- The nearest NPC model, or nil if none found
		@return number -- The distance to the nearest NPC, or 0 if none found
	]=]
	function self.query(self: npc_quadtree_internal, position: Vector3): (Model?, number)
		local results: { Model } = {}
		local pos_x: number, pos_z: number = position.X, position.Z

		quadtree_query_internal(self.root, pos_x, pos_z, self.search_radius, results)

		if not next(results) then
			return nil, 0
		end

		-- Find the nearest model
		local nearest_model: Model? = nil
		local nearest_distance_squared: number = math.huge

		for _, model in results do
			local primary_part: BasePart? = model.PrimaryPart
			if not primary_part then
				continue
			end

			local model_position: Vector3 = primary_part.Position
			local distance_x: number = model_position.X - pos_x
			local distance_z: number = model_position.Z - pos_z
			local distance_squared: number = distance_x * distance_x + distance_z * distance_z

			if distance_squared < nearest_distance_squared then
				nearest_distance_squared = distance_squared
				nearest_model = model
			end
		end

		if nearest_model == nil then
			return nil, 0
		end

		-- Calculate actual distance only once for the nearest model
		return nearest_model, nearest_distance_squared
	end

	--[=[
		Destroys the quadtree instance and disconnects all CollectionService listeners.
		@return ()
	]=]
	function self.destroy(): ()
		for _, connection: RBXScriptConnection in self.connections do
			connection:Disconnect()
		end
		table.clear(self.connections)
		table.clear(self.root.models)
	end

	return self
end

return npc_quadtree_module
