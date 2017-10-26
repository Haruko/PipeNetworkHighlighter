--[[
    TABLE
--]]

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function table.contains(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  
  return false
end

--[[
    MATH
--]]

function math.round(value)
  return math.floor(value + 0.5)
end

function math.inrange(value, min, max)
  return min <= value and value <= max
end

function math.distance(a, b)
  return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2))
end

--[[
    BOUNDING BOX
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

--[[
    DIRECTIONS
--]]
-- Maps 0->4->0, 2->6->2
function mirror_direction(direction)
  return (direction + 4) % 8
end

--    -y
-- -x    +x
--    +y
function direction_to(from, to)
  if from.x < to.x then
    return defines.direction.east
  elseif from.x > to.x then
    return defines.direction.west
  end
  
  if from.y < to.y then
    return defines.direction.south
  elseif from.y > to.y then
    return defines.direction.north
  end
end

--[[
    POSITIONS
--]]
--    -y
-- -x    +x
--    +y
-- shift2 and direction2 optional, does second shift
function shift_position(position, shift, direction)
  local ret = {x = position.x, y = position.y}
  if direction == defines.direction.northwest
    or direction == defines.direction.north
    or direction == defines.direction.northeast then -- -y
    ret.y = ret.y - shift
  end
  
  if direction == defines.direction.northeast
    or direction == defines.direction.east
    or direction == defines.direction.southeast then -- +x
    ret.x = ret.x + shift
  end
  
  if direction == defines.direction.southeast
    or direction == defines.direction.south
    or direction == defines.direction.southwest then -- +y
    ret.y = ret.y + shift
  end
  
  if direction == defines.direction.southwest
    or direction == defines.direction.west
    or direction == defines.direction.northwest then -- -x
    ret.x = ret.x - shift
  end
  
  return ret
end