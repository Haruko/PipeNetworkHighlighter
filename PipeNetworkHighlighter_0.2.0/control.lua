local DEBUG_PLAYER = nil

-- Cardinal directions as seen by game
local DIRECTIONS =  {
                      NORTH = 1,
                      EAST = 2,
                      SOUTH = 3,
                      WEST = 4
                    }

-- Entity types in game that are considered valid
local TYPES = {
                PIPE = "pipe",
                PIPE_TO_GROUND = "pipe-to-ground",
                PUMP = "pump"
              }

-- Entity names (types?) made by this mod
local ENTITY_NAMES = {
                        PIPE = "pnh-pipe-connections",
                        PIPE_TO_GROUND = "pnh-pipe-connections",
                        PUMP = "pnh-pump-connections"
                     }

-- Press the hotkey to enable/disable like the alt-overlay
local enable_overlay = false

-- Keep track of last visited pipes and last created connections for cleanup
local last_visited = {}
local last_connections = {}

-- Distance between two points
local function distance(pos1, pos2)
  return math.sqrt(math.pow(pos1.x - pos2.x, 2) + math.pow(pos1.y - pos2.y, 2))
end

-- Search table for value
local function contains_value(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  
  return false
end

-- Clear out saved data from last network
local function delete_entities()
  if last_connections then
    for _, e in pairs(last_connections) do
      e.destroy()
    end
    
    last_visited = {}
    last_connections = {}
  end
end

local function find_all_connected_pipes(entity, visited)
  -- Optional parameters
  visited = visited or {}
  
  if entity and not contains_value(visited, entity) and contains_value(TYPES, entity.type) then
    -- Do this pipe
    table.insert(visited, entity)
    -- Iterate through neighbors
    for i, neighbor in pairs(entity.neighbours) do
      find_all_connected_pipes(neighbor, visited)
    end
  end
  
  return visited
end

-- Creates the actual connection overlay entity
local function build_connection_entity(surface, name, position, variation)
  -- Create the entity
  local connection_entity = surface.create_entity{
                                                    name = name,
                                                    position = position
                                                  }
  connection_entity.graphics_variation = variation + 1
  return connection_entity
end

local function create_entities_for_pipe(pipe_entity)
  local entity_table = {}
  
  -- If pipe_entity is pipe-to-ground, far_entity is p.t.g at other end of underground length
  local far_entity = nil
  local far_distance = nil
  
  -- pipe-to-ground and pump directions are N=0, E=2, S=4, W=6, need N=1, E=2, S=3, W=4
  -- NORTH means above-ground connection is facing NORTH
  local real_direction = nil
  if pipe_entity.type == TYPES.PIPE_TO_GROUND or pipe_entity.type == TYPES.PUMP then
    real_direction = (pipe_entity.direction / 2) + 1
  end
  
  -- connection_flags is the bitfield of neighbor directions
  local connection_flags = 0
  local pipe_position = pipe_entity.position
  for i, entity in pairs(pipe_entity.neighbours) do
    -- direction is calculated differently depending on entity
    local direction = 0
    if pipe_entity.type == TYPES.PIPE then
      direction = i
    elseif pipe_entity.type == TYPES.PIPE_TO_GROUND then
      -- Calculate direction of pipe-to-ground based on where the neighbors are
      local entity_position = entity.position
      if pipe_position.x > entity_position.x then
        direction = DIRECTIONS.WEST
      elseif pipe_position.x < entity_position.x then
        direction = DIRECTIONS.EAST
      elseif pipe_position.y > entity_position.y then
        direction = DIRECTIONS.NORTH
      elseif pipe_position.y < entity_position.y then
        direction = DIRECTIONS.SOUTH
      end
      
      -- Don't calculate if it's not another ptg
      if entity.type == TYPES.PIPE_TO_GROUND then
        -- Calculate distance to find the far entity for an underground pipe
        local entity_distance = distance(pipe_position, entity_position)
        -- Only need this if the other end is far away
        if entity_distance > 1 then
          far_entity = entity
          far_distance = entity_distance
        end
      end
    end
    
    -- Bitwise-OR the direction (N=1->1, E=2->2, S=3->4, W=4->8)
    connection_flags = bit32.bor(connection_flags, math.pow(2, direction - 1))
  end
  
  -- Need to build connecting entities between two underground pipes
  -- Only build briding entities from the pipe facing north or west so we don't double up entities
  if pipe_entity.type == TYPES.PIPE_TO_GROUND and far_entity
        and (real_direction == DIRECTIONS.NORTH or real_direction == DIRECTIONS.WEST) then
    -- If it's a PTG then there are only 2 connection directions
    local under_connection_flags = nil
    if real_direction == DIRECTIONS.NORTH then
      under_connection_flags = bit32.bor(math.pow(2, DIRECTIONS.NORTH - 1), 
                                  math.pow(2, DIRECTIONS.SOUTH - 1))
    else
      under_connection_flags = bit32.bor(math.pow(2, DIRECTIONS.EAST - 1), 
                                  math.pow(2, DIRECTIONS.WEST - 1))
    end
    
    -- Add an entity for every tile between the PTGs
    for i = 1, far_distance - 1, 1 do
      -- Tables are references, so copy the values
      local position = {x = pipe_position.x, y = pipe_position.y}
      if real_direction == DIRECTIONS.NORTH then
        position.y = position.y + i
      else
        position.x = position.x + i
      end
      
      new_connection_entity = build_connection_entity(pipe_entity.surface, ENTITY_NAMES.PIPE, 
                                                                  position, under_connection_flags)
      table.insert(entity_table, new_connection_entity)
    end
  end
  
  -- If it's a pump then it only goes one direction depending on rotation
  if pipe_entity.type == TYPES.PUMP then
    connection_flags = real_direction - 1
  end
  
  -- Get the connection entity name from the table
  local entity_name = nil
  if pipe_entity.type == TYPES.PIPE then
    entity_name = ENTITY_NAMES.PIPE
  elseif pipe_entity.type == TYPES.PIPE_TO_GROUND then
    entity_name = ENTITY_NAMES.PIPE_TO_GROUND
  elseif pipe_entity.type == TYPES.PUMP then
    entity_name = ENTITY_NAMES.PUMP
  end
  
  local connection_entity = build_connection_entity(pipe_entity.surface, entity_name, 
                                                                  pipe_position, connection_flags)
  table.insert(entity_table, connection_entity)
  return entity_table
end

-- Go through the network topology and make all connection entities
local function create_all_connection_entities(pipe_entities)
  local connection_entities = {}
  for _, entity in pairs(pipe_entities) do
    local new_connections = create_entities_for_pipe(entity)
    -- Merge tables
    for _, con in pairs(new_connections) do
      table.insert(connection_entities, con)
    end
  end
  
  return connection_entities
end

-- Event handlers
local event_handler = function (e)
  if enable_overlay then
    -- game.player only works in console
    local player = game.players[e.player_index]
    DEBUG_PLAYER = player
    
    -- Only rebuild network if we are actually looking at a new network
    if last_visited and not contains_value(last_visited, player.selected) then
      -- Clear out previous network data
      delete_entities()
      -- Get the network topology
      last_visited = find_all_connected_pipes(player.selected)
      -- Create connection entities
      last_connections = create_all_connection_entities(last_visited)
    end
  end
end

local hotkey_handler = function(e)
  local player = game.players[e.player_index]
  enable_overlay = not enable_overlay
  if not enable_overlay then
    delete_entities()
  end
end

-- Register event handlers
script.on_event(defines.events.on_selected_entity_changed, event_handler)
script.on_event("pnh-hotkey", hotkey_handler)