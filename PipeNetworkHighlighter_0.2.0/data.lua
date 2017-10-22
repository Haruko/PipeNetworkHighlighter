local function spritesheet_to_picture(file, index)
  return {
      filename = file,
      priority = "extra-high",
      x = index * 32,
      y = 0,
      width = 32,
      height = 32
    }
end

local pipe_con_file = "__PipeNetworkHighlighter__/graphics/pipe-connections.png"

local pipe_connections = {
  type = "simple-entity",
  name = "pnh-pipe-connections",
  flags = {"not-blueprintable",
           "not-deconstructable",
           "not-on-map",
           "placeable-off-grid"},
  max_health = 100,
  selectable_in_game = false,
  minable = nil,
  collision_box = nil,
  collision_mask = {},
  selection_box = nil,
  bounding_box = {0, 0},
  secondary_bounding_box = nil,
  render_layer = "arrow",
  destructible = false,
  operable = false,
  rotatable = false,
  pictures =
  {                                            -- WSEN
    spritesheet_to_picture(pipe_con_file, 0),  -- 0000
    spritesheet_to_picture(pipe_con_file, 1),  -- 0001
    spritesheet_to_picture(pipe_con_file, 2),  -- 0010
    spritesheet_to_picture(pipe_con_file, 3),  -- 0011
    spritesheet_to_picture(pipe_con_file, 4),  -- 0100
    spritesheet_to_picture(pipe_con_file, 5),  -- 0101
    spritesheet_to_picture(pipe_con_file, 6),  -- 0110
    spritesheet_to_picture(pipe_con_file, 7),  -- 0111
    spritesheet_to_picture(pipe_con_file, 8),  -- 1000
    spritesheet_to_picture(pipe_con_file, 9),  -- 1001
    spritesheet_to_picture(pipe_con_file, 10), -- 1010
    spritesheet_to_picture(pipe_con_file, 11), -- 1011
    spritesheet_to_picture(pipe_con_file, 12), -- 1100
    spritesheet_to_picture(pipe_con_file, 13), -- 1101
    spritesheet_to_picture(pipe_con_file, 14), -- 1110
    spritesheet_to_picture(pipe_con_file, 15)  -- 1111
  }
}

local pump_connections = {
  type = "simple-entity",
  name = "pnh-pump-connections",
  flags = {"not-blueprintable",
           "not-deconstructable",
           "not-on-map",
           "placeable-off-grid"},
  max_health = 100,
  selectable_in_game = false,
  minable = nil,
  collision_box = nil,
  collision_mask = {},
  selection_box = nil,
  bounding_box = {0, 0},
  secondary_bounding_box = nil,
  render_layer = "arrow",
  destructible = false,
  operable = false,
  rotatable = false,
  pictures =
  {
    { -- North
      filename = "__PipeNetworkHighlighter__/graphics/pump-connections.png",
      priority = "extra-high",
      x = 0,
      y = 0,
      width = 32,
      height = 64
    },
    { -- East
      filename = "__PipeNetworkHighlighter__/graphics/pump-connections.png",
      priority = "extra-high",
      x = 64,
      y = 0,
      width = 64,
      height = 32
    },
    { -- South
      filename = "__PipeNetworkHighlighter__/graphics/pump-connections.png",
      priority = "extra-high",
      x = 32,
      y = 0,
      width = 32,
      height = 64
    },
    { -- West
      filename = "__PipeNetworkHighlighter__/graphics/pump-connections.png",
      priority = "extra-high",
      x = 64,
      y = 32,
      width = 64,
      height = 32
    }
  }
}

local hotkey = {
  type = "custom-input",
  name = "pnh-hotkey",
  key_sequence = "LSHIFT",
  consuming = "none"
}

data:extend{pipe_connections,
            pump_connections,
            hotkey}