local gui = {}
function gui.build_shutdown_combinator_gui(player, entity, unit_data)
    -- You don't need to fetch unit_data from storage here anymore.
    -- We're already passing it as a parameter.

    if not unit_data then return end  -- Ensure unit_data exists

    -- Get the switch state, checkbox state, value number, and dummy signal from unit_data
    local switch_state = unit_data.switch_state
    local checkbox_state = unit_data.checkbox_state
    local value_number = unit_data.value_number
    local dummy_signal = unit_data.dummy_signal 
    local sc_state = unit_data.speed_control_state
    local sc_value = unit_data.speed_control_value
    -- Fixing this variable name to match the one used in storage

    -- Get the player-specific data from storage (for per-player states)
    local player_switch_state = unit_data.shutdown_gui_switch_state and unit_data.shutdown_gui_switch_state[player.index] or switch_state
    local player_checkbox_state = unit_data.shutdown_gui_checkbox_state and unit_data.shutdown_gui_checkbox_state[player.index] or checkbox_state


    local frame = player.gui.screen.add{
        type = "frame",
        name = "shutdown-combinator-frame",
        style = "frame",
        direction = "vertical"
    }
    frame.force_auto_center()

    -- Titlebar
    local title_flow = frame.add{
        type = "flow",
        name = "shutdown-combinator-titlebar",
        direction = "horizontal"
    }
    title_flow.drag_target = frame

    local title_label = title_flow.add{
        type = "label",
        caption = "Hub Control Panel",
        style = "frame_title"
    }
    title_label.style.left_padding = 4
    title_label.style.right_padding = 4
    title_label.ignored_by_interaction = true

    local spacer = title_flow.add{
        type = "empty-widget",
        style = "draggable_space_header",
        ignored_by_interaction = true
    }
    spacer.style.horizontally_stretchable = true
    spacer.style.height = 24

    local close_button = title_flow.add{
        type = "sprite-button",
        name = "shutdown-combinator-close-button",
        style = "close_button",
        sprite = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black"
    }
    close_button.style.width = 24
    close_button.style.height = 24

    -- Centering flow
    local center_flow = frame.add{
        type = "flow",
        name = "center_flow",
        direction = "horizontal"
    }
    center_flow.style.horizontal_align = "center"
    center_flow.style.vertically_stretchable = true

    -- Content frame
    local content_frame = center_flow.add{
        type = "frame",
        name = "shutdown-combinator-content",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical"
    }
    content_frame.style.horizontally_stretchable = true
    content_frame.style.vertically_stretchable = true
    -- Flow for toggle-buttons and labels (Centered)
    local centered_flow = content_frame.add{
        type = "flow",
        direction = "vertical"
    }
    centered_flow.style.horizontal_align = "center"
    centered_flow.style.vertical_align = "center"

    -- Label 1
    local label1 = centered_flow.add{
        type = "label",
        name = "shutdown-gui-firstline",
        caption = "[font=default-bold][color=red]Force[/color] if Input > 0[/font]",
        rich_text = true
    }
    label1.style.left_margin = 25

    -- Toggle Button 1 (Switch)
    local switch_row = centered_flow.add{
        type = "flow",
        direction = "horizontal"
    }
    
    -- Invisible spacer to push switch to the right
    local spacer = switch_row.add{
        type = "empty-widget"
    }
    spacer.style.width = 25  -- adjust this to control how far right the switch moves
    spacer.style.horizontally_stretchable = false
    
    -- Your switch
    local button1 = switch_row.add{
        type = "switch",
        name = "shutdown-gui-switch",
        switch_state = switch_state or "right",
        left_label_caption = "Manual",
        right_label_caption = "Automatic",
        tags = { unit_number = entity.unit_number }  -- 👈 store unit_number here
    }
    


    -- Label 2
   local label2 = centered_flow.add{
        type = "label",
        name = "shutdown-gui-thirdline",
        caption = "connect to Hub via Output",
        rich_text = true
    }
    label2.style.left_margin = 25
    -- Add a vertical spacer (gap)
    centered_flow.add{
        type = "empty-widget",
        style = "draggable_space_header",
        ignored_by_interaction = true
    }.style.height = 20

    -- Button Row (Sprite button and checkbox)
    local button_row = content_frame.add{
        type = "flow",
        name = "button_row",
        direction = "horizontal"
    }
    button_row.style.horizontal_align = "center"
    button_row.style.vertical_align = "center"

    button_row.add{
        type = "checkbox",
        name = "shutdown-true-signal",
        caption = "Read Hub Signal",
        state = checkbox_state or false,
        tags = { unit_number = entity.unit_number, id = "checkbox1" }
    }

    local spacer2 = button_row.add{
        type = "flow",
        direction = "horizontal",
        ignored_by_interaction = true
    }
    spacer2.style.horizontally_stretchable = true
    spacer2.style.width = 40

    local value_number = storage.shutdown_gui_value_number or 0
    button_row.add{
        type = "sprite-button",
        name = "my_sprite_button",
        sprite = "virtual-signal/signal-H",
        style = "tool_button",
        tooltip = "Click to perform action",
        enabled = checkbox_state or false,
        number = (value_number ~= 0) and value_number or nil,
        tags = {
            unit_number = entity.unit_number,
            id = "Sprite_id",
            checkbox_state = checkbox_state,
            value_number = value_number
        }
    }

    local my_sprite_button = button_row["my_sprite_button"]
    my_sprite_button.style.width = 30
    my_sprite_button.style.height = 30
    my_sprite_button.style.padding = -10

    -----------------------------------------------------------------------------------------
    ---GAP
    -----------------------------------------------------------------------------------------

    -- NEW LEFT-ALIGNED ROW WITH CHECKBOX
    local final_row = content_frame.add{
        type = "flow",
        name = "final_left_row",
        direction = "horizontal"
    }
    final_row.style.horizontal_align = "left"
    
    final_row.add{
        type = "checkbox",
        name = "shutdown-dummy-signal",
        caption = "DummyInput",
        state = dummy_signal or false,
        tags = { unit_number = entity.unit_number, id = "checkbox2"}
    }

-- Spacer between the two rows
content_frame.add{
    type = "flow",
    direction = "vertical",
    ignored_by_interaction = true
}.style.height = 8

    -- NEW LEFT-ALIGNED ROW WITH CHECKBOX
    local finalafter_final = content_frame.add{
        type = "flow",
        name = "speed_control_row",
        direction = "horizontal"
    }
    finalafter_final.style.horizontal_align = "left"
    
    finalafter_final.add{
        type = "checkbox",
        name = "speed_control",
        caption = "speed control",
        state = sc_state or false,
        tags = { unit_number = entity.unit_number, id = "checkbox3"}
    }

    -- Spacer between checkbox row and slider row
content_frame.add{
    type = "empty-widget",
    name = "spacer_between_rows",
    style = "draggable_space_header",
    direction = "vertical"
}.style.height = 8  -- You can adjust this value for more or less spacing

-- Horizontal flow to hold slider and label in one row
local speed_row = content_frame.add{
    type = "flow",
    name = "speed_row",
    direction = "horizontal"
}
speed_row.style.horizontal_align = "center"
speed_row.style.vertical_align = "center"
speed_row.style.horizontally_stretchable = true


-- Slider for speed control
speed_row.add{
    type = "slider",
    name = "speed_slider",
    minimum_value = 1,
    maximum_value = 100,
    value = sc_value or 50,
    value_step = 1,
    discrete_slider = true,
    discrete_values = true,
    tags = {
        unit_number = entity.unit_number,
        id = "sc_value_id",
        sc_value = sc_value
    }
}

-- Label showing slider value
-- Textfield for manual speed input
local speed_value_field = speed_row.add{
    type = "textfield",
    name = "speed_value",
    text = tostring(sc_value),  -- Ensure this displays the actual value of sc_value
    numeric = true,
    allow_decimal = false,
    allow_negative = false,
    tags = {
        unit_number = entity.unit_number,
        id = "sc_value_id",
        sc_value = sc_value
    }
}
speed_value_field.style.width = 40
speed_value_field.style.horizontal_align = "center"


    player.opened = frame -- ✅ This makes ESC or E trigger on_gui_closed!
end

return gui
