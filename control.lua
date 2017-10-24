require("utilities")

local DEBUG_PLAYER = nil

--[[
    VARIABLES
--]]

-- Name of a PipeNetworkHighlighter entity
local ENTITY_NAME = "pnh-pipe-connection"

-- N/W=-y/-x
local CONNECTIONS = {
  NONE  = 0,
  NORTH = 1,
  EAST  = 2,
  SOUTH = 4,
  WEST  = 8
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

--[[
    BOUNDING BOXES
--]]

-- Round the x and y values in the bounding box
function round_bounding_box(bbox)
  return {
    left_top = {
      y = math.round(bbox.left_top.y),
      x = math.round(bbox.left_top.x)
    },
    right_bottom = {
      y = math.round(bbox.right_bottom.y),
      x = math.round(bbox.right_bottom.x)
    }
  }
end

-- Get the center of the bounding box
function get_bounding_box_center(bbox)
  return {
    y = (bbox.left_top.y + bbox.right_bottom.y) / 2,
    x = (bbox.left_top.x + bbox.right_bottom.x) / 2
  }
end

-- Get the dimensions of the bounding box
function get_bounding_box_size(bbox)
  return {
    height = bbox.right_bottom.y - bbox.left_top.y,
    width = bbox.right_bottom.x - bbox.left_top.x
  }
end

-- Merge two bounding boxes into one large one
function merge_bounding_boxes(bbox1, bbox2)
  return {
    left_top = {
      y = math.min(bbox1.left_top.y, bbox2.left_top.y),
      x = math.min(bbox1.left_top.x, bbox2.left_top.x)
    },
    right_bottom = {
      y = math.max(bbox1.right_bottom.y, bbox2.right_bottom.y),
      x = math.max(bbox1.right_bottom.x, bbox2.right_bottom.x)
    }
  }
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
  local entity_bbox = round_bounding_box(entity.bounding_box)
  local entity_size = get_bounding_box_size(entity_bbox)
  
  if entity_size.width > 1 or entity_size.height > 1 then
    connection_flags = CONNECTIONS.NONE
  else
    for _, neighbor in pairs(entity.neighbours) do
      --[[if neighbor.position.x < entity.position.x then -- WEST
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.WEST)
      elseif neighbor.position.x > entity.position.x then -- EAST
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.EAST)
      elseif neighbor.position.y < entity.position.y then -- NORTH
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.NORTH)
      elseif neighbor.position.y > entity.position.y then -- SOUTH
        connection_flags = bit32.bor(connection_flags, CONNECTIONS.SOUTH)
      end--]]
        
      local neigh_bbox = round_bounding_box(neighbor.bounding_box)
      -- Since it can't be overlapping, assume that being inside of 
      -- the bounding box on one axis means it is on a certain side
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
  end
  
  return connection_flags
end

local function create_connection(surface, position, connection_flags)
  global.connections = global.connections or {}
  
  local connection = surface.create_entity{name = ENTITY_NAME, position = position}
  connection.graphics_variation = connection_flags + 1
  table.insert(global.connections, connection)
end

local function outline_bounding_box(surface, bbox)
  local size = get_bounding_box_size(bbox)
  
  local position = {}
  local connection_flags = 0
  for x = 0, size.width - 1 do
    if x == 0 or x == size.width - 1 then
      -- If we are in the left-most or right-most columns, go down the entire side
      connection_flags = bit32.bor(CONNECTIONS.NORTH, CONNECTIONS.SOUTH)
      for y = 1, size.height - 2 do
        position = {y = bbox.left_top.y + y + 0.5, x = bbox.left_top.x + x + 0.5}
        create_connection(surface, position, connection_flags)
      end
      -- Special for corners
      connection_flags = CONNECTIONS.EAST
      if x == size.width - 1 then
        connection_flags = CONNECTIONS.WEST
      end
      position = {y = bbox.left_top.y + 0.5, x = bbox.left_top.x + x+ 0.5}
      create_connection(surface, position, bit32.bor(connection_flags, CONNECTIONS.SOUTH))
      position = {y = bbox.right_bottom.y - 1 + 0.5, x = bbox.left_top.x + x + 0.5}
      create_connection(surface, position, bit32.bor(connection_flags, CONNECTIONS.NORTH))
    else
      -- If we are in a central column, only do the top and bottom edges
      connection_flags = bit32.bor(CONNECTIONS.EAST, CONNECTIONS.WEST)
      position = {y = bbox.left_top.y + 0.5, x = bbox.left_top.x + x + 0.5}
      create_connection(surface, position, connection_flags)
      position.y = bbox.right_bottom.y - 1 + 0.5
      create_connection(surface, position, connection_flags)
    end
  end
  
  create_connection(surface, get_bounding_box_center(bbox), 15)
end

local function visit_all_entities(entity)
  global.last_visited = global.last_visited or {}
  
  if table.contains(VALID_ENTITY_TYPES, entity.type) and not table.contains(global.last_visited, entity) then
    create_connection(entity.surface, 
      entity.position, 
      get_connection_directions(entity))
    table.insert(global.last_visited, entity)
    
    for _, neighbor in pairs(entity.neighbours) do
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
  
  if global.enable_overlay then
    local player = game.players[e.player_index]
    DEBUG_PLAYER = DEBUG_PLAYER or player
    
    local selected = player.selected
    -- Only rebuild if the previous last_visited didn't contain this entity
    if selected then
      if not table.contains(global.last_visited, selected) then
        clear_connections()
        visit_all_entities(selected)
      end
    else
      clear_connections()
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