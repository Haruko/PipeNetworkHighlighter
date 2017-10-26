require("utilities")

local DEBUG_PLAYER = nil

--[[
    VARIABLES
--]]

-- Name of a PipeNetworkHighlighter entity
local ENTITY_NAME = "pnh-connection"

--    -y
-- -x    +x
--    +y
local CONNECTIONS = {
  NONE  = 0,
  NORTH = 1,
  EAST  = 2,
  SOUTH = 4,
  WEST  = 8,
  CENTER = 16 + 0,
  EDGE_NORTH  = 16 + 1,
  EDGE_EAST   = 16 + 2,
  EDGE_SOUTH  = 16 + 3,
  EDGE_WEST   = 16 + 4,
  CORNER_NORTHWEST = 16 + 5,
  CORNER_NORTHEAST = 16 + 6,
  CORNER_SOUTHEAST = 16 + 7,
  CORNER_SOUTHWEST = 16 + 8
}

local VALID_ENTITY_TYPES = {
  "assembling-machine",
  "boiler",
  "fluid-turret",
  "generator",
  "mining-drill",
  "offshore-pump",
  "pipe",
  "pipe-to-ground",
  "pump",
  "storage-tank"
}

local ENTITY_NAME_BLACKLIST = {
  "factory-fluid-dummy-connector",      -- Factorissimo2
  "factory-fluid-dummy-connector-south" -- Factorissimo2
}

local function is_fluid_recipe(recipe)
  for _, ingredient in pairs(recipe.ingredients) do
    if ingredient.type == "fluid" then
      return true
    end
  end
  return false
end

--[[
    CONNECTIONS
--]]

local function clear_connections()
  global.connections = global.connections or {}
  global.last_visited = global.last_visited or {}
  
  if #global.connections > 0 then
    for _, con in pairs(global.connections) do
      con.destroy()
    end
    global.connections = {}
    global.last_visited = {}
  end
end

local function get_connection_directions(entity)
  local connection_flags = 0
  for _, neighbor in pairs(entity.neighbours) do
    local neigh_bbox = round_bounding_box(neighbor.bounding_box)
    -- Since it can't be overlapping, assume that being inside the range of 
    -- the bounding box on one axis means it is on a side intersecting that axis
    if math.inrange(entity.position.x, neigh_bbox.left_top.x, neigh_bbox.right_bottom.x) then
      if entity.position.y < neigh_bbox.left_top.y then
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.SOUTH)
      else
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.NORTH)
      end
    elseif math.inrange(entity.position.y, neigh_bbox.left_top.y, neigh_bbox.right_bottom.y) then
      if entity.position.x < neigh_bbox.left_top.x then
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.EAST)
      else
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.WEST)
      end
    end
  end
  
  return connection_flags
end

local function create_connection(surface, position, connection_flags)
  global.connections = global.connections or {}
  
  local connection = surface.create_entity{name = ENTITY_NAME, position = position}
  connection.graphics_variation = connection_flags + 1
  table.insert(global.connections, connection)
end

local function create_large_entity_connections(surface, bbox)
  local bbox_size = get_bounding_box_size(bbox)
  -- corners
  create_connection(surface, 
    bbox.left_top, 
    CONNECTIONS.CORNER_NORTHWEST)
  
  create_connection(surface, 
    {x = bbox.right_bottom.x, y = bbox.left_top.y}, 
    CONNECTIONS.CORNER_NORTHEAST)
  
  create_connection(surface, 
    bbox.right_bottom, 
    CONNECTIONS.CORNER_SOUTHEAST)
  
  create_connection(surface, 
    {x = bbox.left_top.x, y = bbox.right_bottom.y}, 
    CONNECTIONS.CORNER_SOUTHWEST)
  
  for x = 0, bbox_size.width do
    -- top and bottom edge
    if x > 0 and x < bbox_size.width then
      create_connection(surface, 
        shift_position(bbox.left_top, x, defines.direction.east),
        CONNECTIONS.EDGE_NORTH)
      
      create_connection(surface, 
        shift_position(bbox.right_bottom, x, defines.direction.west),
        CONNECTIONS.EDGE_SOUTH)
    end
    
    for y = 1, bbox_size.height - 1 do
      if x == 0 then
        -- left edge
        create_connection(surface, 
          shift_position(bbox.left_top, y, defines.direction.south),
          CONNECTIONS.EDGE_WEST)
      elseif x == bbox_size.width then
        -- right edge
        create_connection(surface, 
          shift_position(bbox.right_bottom, y, defines.direction.north),
          CONNECTIONS.EDGE_EAST)
      else
        -- center
        create_connection(surface, 
          {x = bbox.left_top.x + x, y = bbox.left_top.y + y},
          CONNECTIONS.CENTER)
      end
    end
  end
end

local function visit_all_entities(entity)
  global.last_visited = global.last_visited or {}
  
  if table.contains(VALID_ENTITY_TYPES, entity.type) 
    and not table.contains(global.last_visited, entity) 
    and not table.contains(ENTITY_NAME_BLACKLIST, entity.name) then
    -- Assembling machines are a valid entity type, but don't always allow pipe connections.
    if entity.type == "assembling-machine"
      and (not entity.recipe or not is_fluid_recipe(entity.recipe)) then
      return
    end
    
    local rounded_bbox = round_bounding_box(entity.bounding_box)
    local entity_size = get_bounding_box_size(rounded_bbox)
    if entity_size.width > 1 or entity_size.height > 1 then
      create_large_entity_connections(entity.surface, rounded_bbox)
    else
      create_connection(entity.surface, 
        entity.position, 
        get_connection_directions(entity))
    end
    table.insert(global.last_visited, entity)
    
    -- Don't want to connect these pipes to the output pipes of the assembler
    -- If there is only one item in global.last_visited, then this is the selected entity.
    --    In that case we DO want to get output pipes.
    if entity.type == "assembling-machine" and #global.last_visited > 1 then
      return
    end
    
    for _, neighbor in pairs(entity.neighbours) do
      -- Need to do long connections to underground neighbor.
      if entity.type == "pipe-to-ground" 
        and (entity.direction == defines.direction.north 
          or entity.direction == defines.direction.east)
          and direction_to(entity.position, neighbor.position) == mirror_direction(entity.direction) then
        for i = 1, math.distance(entity.position, neighbor.position) - 1 do
          create_connection(entity.surface, 
            shift_position(entity.position, i, mirror_direction(entity.direction)), 
            get_connection_directions(entity))
        end
      end
      
      visit_all_entities(neighbor)
    end
  end
end

--[[
    EVENT HANDLERS
--]]

-- General event handler to handle all events that would force an update of the connections
local event_handler = function (e)
  global.connections = global.connections or {}
  global.last_visited = global.last_visited or {}
  
  local player = game.players[e.player_index]
  DEBUG_PLAYER = DEBUG_PLAYER or player
  local selected = player.selected
  
  if global.enable_overlay and selected then
    -- Only rebuild if the previous last_visited didn't contain this entity
    if not table.contains(global.last_visited, selected) then
      clear_connections()
      visit_all_entities(selected)
    end
  else
    clear_connections()
  end
end

-- Hotkey toggles overlay
local hotkey_handler = function(e)
  global.enable_overlay = not global.enable_overlay
  if not global.enable_overlay then
    clear_connections()
  end
end

-- Initialize variables on first run
local init_handler = function()
  global.enable_overlay = true
  global.connections = {}
  global.last_visited = {}
end

-- Register events
script.on_event(defines.events.on_selected_entity_changed, event_handler)
script.on_event("pnh-hotkey", hotkey_handler)

script.on_init(init_handler)