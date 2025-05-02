-- Step 1: Clone the base constant-combinator as our prototype
local base = data.raw["decider-combinator"]["decider-combinator"]
if not base then error("Constant combinator not found.") end

local shutdownCombinator = table.deepcopy(base)
shutdownCombinator.name = "shutdown-combinator"
shutdownCombinator.icon = "__shutdown-combinator__/graphics/icons/shutdown-combinator.png"
shutdownCombinator.icon_size = 64

shutdownCombinator.icons = {
  {
    icon = shutdownCombinator.icon,
    icon_size = 64,
    tint = {r=1, g=0, b=0, a=0.3}  -- Optional: tint the icon to make it look different
  }

}

-- Optional changes to match the shutdown-custom's characteristics
shutdownCombinator.flags = {"placeable-neutral", "player-creation"}
shutdownCombinator.max_health = 150
shutdownCombinator.collision_box = base.collision_box
shutdownCombinator.selection_box = base.selection_box



-- Circuit logic setup (from constant-combinator)
shutdownCombinator.circuit_wire_max_distance = base.circuit_wire_max_distance

-- Correct circuit_wire_connection_points for input and output








-- Set the circuit connector sprites manually (no longer uses base)
sprites = {
  filename = "__shutdown-combinator__/graphics/entity/shutdown-combinator/shutdown-combinator.png",
  width = 32, height = 32,
  direction_count = 1,
  shift = {0, 0},
  hr_version = {
    filename = "__shutdown-combinator__/graphics/entity/shutdown-combinator/hr-shutdown-combinator.png",
    width = 64, height = 64,
    direction_count = 1,
    shift = {0, 0},
    scale = 0.5
  }
}

-- Step 2: Add the shutdown-combinator entity to the game
data:extend({shutdownCombinator})

-- Item definition for shutdown-combinator
local shutdownCombinatorItem = {
  type = "item",
  name = "shutdown-combinator",
  icon = "__shutdown-combinator__/graphics/icons/shutdown-combinator.png",
  icon_size = 64,
  subgroup = "circuit-network",
  place_result = "shutdown-combinator",
  order = "c[combinators]-z[shutdown-combinator]",
  stack_size = 50
}

-- Recipe definition for shutdown-combinator
local shutdownCombinatorRecipe = {
  type = "recipe",
  name = "shutdown-combinator",
  enabled = true,
  ingredients = {
    {type = "item", name = "electronic-circuit", amount = 5},
    {type = "item", name = "iron-plate", amount = 5}
  },
  results = {
    {type = "item", name = "shutdown-combinator", amount = 1}
  }
}

-- Step 3: Add item and recipe to the game
data:extend({shutdownCombinatorItem, shutdownCombinatorRecipe})


