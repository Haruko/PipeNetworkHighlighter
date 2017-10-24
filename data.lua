local function spritesheet_to_picture(file, row, col)
  return {
      filename = file,
      priority = "extra-high",
      x = col * 32,
      y = row * 32,
      width = 32,
      height = 32
    }
end

local pipe_con_file = "__PipeNetworkHighlighter__/graphics/pipe-connection.png"

local pipe_connections = {
  type = "simple-entity",
  name = "pnh-pipe-connection",
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
    -- Row 0 is generic pipe connections             WSEN
    spritesheet_to_picture(pipe_con_file, 0, 0),  -- 0000
    spritesheet_to_picture(pipe_con_file, 0, 1),  -- 0001
    spritesheet_to_picture(pipe_con_file, 0, 2),  -- 0010
    spritesheet_to_picture(pipe_con_file, 0, 3),  -- 0011
    spritesheet_to_picture(pipe_con_file, 0, 4),  -- 0100
    spritesheet_to_picture(pipe_con_file, 0, 5),  -- 0101
    spritesheet_to_picture(pipe_con_file, 0, 6),  -- 0110
    spritesheet_to_picture(pipe_con_file, 0, 7),  -- 0111
    spritesheet_to_picture(pipe_con_file, 0, 8),  -- 1000
    spritesheet_to_picture(pipe_con_file, 0, 9),  -- 1001
    spritesheet_to_picture(pipe_con_file, 0, 10), -- 1010
    spritesheet_to_picture(pipe_con_file, 0, 11), -- 1011
    spritesheet_to_picture(pipe_con_file, 0, 12), -- 1100
    spritesheet_to_picture(pipe_con_file, 0, 13), -- 1101
    spritesheet_to_picture(pipe_con_file, 0, 14), -- 1110
    spritesheet_to_picture(pipe_con_file, 0, 15)--, -- 1111
    -- Row 1 is directional arrows                   WSEN
    --spritesheet_to_picture(pipe_con_file, 1, 0),  -- 0000
    --spritesheet_to_picture(pipe_con_file, 1, 1),  -- 0001
    --spritesheet_to_picture(pipe_con_file, 1, 2),  -- 0010
    --spritesheet_to_picture(pipe_con_file, 1, 4)   -- 0100
  }
}

local hotkey = {
  type = "custom-input",
  name = "pnh-hotkey",
  key_sequence = "KEY69", -- '/"
  consuming = "none"
}

data:extend{pipe_connections,
            hotkey}