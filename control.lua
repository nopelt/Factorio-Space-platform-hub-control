local gui = require("gui")

script.on_init(function()
    storage.shutdown_combinator_everything = {}
    storage.gui_open_unit = {}
end)

-- BUILD -----------------------------------------------------------------------------------------------------
script.on_event({
    defines.events.on_built_entity, 
    defines.events.on_space_platform_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
    defines.events.on_entity_cloned
}, function(event)
---@diagnostic disable-next-line: undefined-field
    local entity = event.created_entity or event.entity
    if not entity then return end

    if entity.name == "shutdown-combinator" then
        local unit_number = entity.unit_number
        if unit_number ~= nil then
            storage.shutdown_combinator_everything[unit_number] = {
                shutdown_combinator_signals = {},
                switch_state = "left",
                checkbox_state = false,
                value_number = 0,
                connected_state = false,
                dummy_signal = false,
                speed_control_state = false,
                speed_control_value = 0,
                entity = entity,
                position = entity.position,
                surface = entity.surface
            }
            table.insert(storage.scan_queue, unit_number)
            game.print("Shutdown combinator with unit_number " .. unit_number .. " has been initialized.")
        end

        local behavior = entity.get_or_create_control_behavior() --[[@as LuaDeciderCombinatorControlBehavior]]
        if behavior and behavior.valid then
            behavior.parameters = {
                conditions = {
                    {
                        comparator = "<",
                        first_signal = { type = "virtual", name = "" },
                        constant = 9999999
                    }
                },
                outputs = {
                    {
                        signal = { type = "virtual", name = "signal-H" },
                        copy_count_from_input = false,
                        constant = 0
                    }
                }
            }
        end
    end
end)

-- DESTROY -----------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_player_mined_entity, function(event)
    local entity = event.entity
    if not (entity and entity.valid and entity.name == "shutdown-combinator") then return end

    local unit_number = entity.unit_number
    if unit_number and storage.shutdown_combinator_everything then
        storage.shutdown_combinator_everything[unit_number] = nil
    end

    if event.player_index then
        local player = game.get_player(event.player_index)
        if player and player.valid then
            local inserted = player.insert({ name = "shutdown-combinator", count = 1 })
            if inserted == 0 then
                player.surface.spill_item_stack({
                    position = {x = player.position.x, y = player.position.y},
                    stack = { name = "shutdown-combinator", count = 1 }
                })
            end
        end
    end
end)

-- GUI OPEN -----------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_opened, function(event)
    -- Ensure the event is valid and contains a valid entity
    if not event or not event.entity or not event.entity.valid then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Only handle the shutdown-combinator entity
    if event.entity.name ~= "shutdown-combinator" then return end

    -- Prevent vanilla GUI from opening
    player.opened = nil

    local entity = event.entity
    if not entity then return end -- additional check for valid entity
    
    local unit_number = entity.unit_number
    if not unit_number then return end

    local unit_data = storage.shutdown_combinator_everything[unit_number]
    if not unit_data then return end

    -- Build your custom GUI
    gui.build_shutdown_combinator_gui(player, entity, unit_data)

    -- Track the opened GUI
    storage.gui_open_unit = storage.gui_open_unit or {}
    storage.gui_open_unit[player.index] = unit_number

    -- Play sound
    player.play_sound{ path = "utility/gui_click" }
end)







script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    -- Check if the closed GUI is your custom GUI
    if player.gui.screen["shutdown-combinator-frame"] then
        -- Destroy the custom GUI
        player.gui.screen["shutdown-combinator-frame"].destroy()

        -- Optionally clean up any stored data related to the GUI
    
    end
end)


-- GUI CLOSE -----------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    if not (event and event.element and event.element.valid) then return end

    if event.element.name == "shutdown-combinator-close-button" then
        local player = game.get_player(event.player_index)
        if player and player.gui.screen["shutdown-combinator-frame"] then
            player.gui.screen["shutdown-combinator-frame"].destroy()
            player.opened = nil
            player.play_sound{ path = "utility/gui_click" }

            -- ❌ Remove tracking
            if storage.gui_open_unit then
                storage.gui_open_unit[player.index] = nil
            end
        end
    end
end)



-- SWITCH -----------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    local player = game.players[event.player_index]
    local switch = event.element
    local unit_number = switch.tags.unit_number 
    if not unit_number then return end

    if not storage.shutdown_combinator_everything[unit_number] then
        storage.shutdown_combinator_everything[unit_number] = {
            shutdown_combinator_signals = {},
            switch_state = "left",
            checkbox_state = false,
            value_number = 0,
            connected_state = false,
            dummy_signal = false,
            speed_control_state = false,
            speed_control_value = 0
        }
    end

    storage.shutdown_combinator_everything[unit_number].switch_state = switch.switch_state
end)

-- CHECKBOX -----------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    local element = event.element
    local tags = element.tags
    local unit_number = tags.unit_number
    local id = tags.id
    if not unit_number or not id then return end

    if not storage.shutdown_combinator_everything[unit_number] then
        storage.shutdown_combinator_everything[unit_number] = {
            shutdown_combinator_signals = {},
            switch_state = "left",
            checkbox_state = false,
            value_number = 0,
            connected_state = false,
            dummy_signal = false,
            speed_control_state = false,
            speed_control_value = 0
        }
    end

    if id == "checkbox1" then
        storage.shutdown_combinator_everything[unit_number].checkbox_state = element.state
    elseif id == "checkbox2" then
        storage.shutdown_combinator_everything[unit_number].dummy_signal = element.state
    elseif id == "checkbox3" then
        storage.shutdown_combinator_everything[unit_number].speed_control_state = element.state
    end
end)

-- Speed_value_text -----------------------------------------------------------------------------------------
script.on_event({defines.events.on_gui_text_changed, defines.events.on_gui_value_changed}, function(event)
---@diagnostic disable-next-line: undefined-field
    local element = event.element
    if not element then return end  -- Early return if there's no element

    local tags = element.tags
    local unit_number = tags.unit_number
    local id = tags.id
    if not unit_number or not id then return end

    -- Initialize storage if it doesn't exist
    if not storage.shutdown_combinator_everything[unit_number] then
        storage.shutdown_combinator_everything[unit_number] = {
            shutdown_combinator_signals = {},
            switch_state = "left",
            checkbox_state = false,
            value_number = 0,
            connected_state = false,
            dummy_signal = false,
            speed_control_state = false,
            speed_control_value = 0
        }
    end

    -- Handle the speed control (slider and text field changes)
    if id == "sc_value_id" then
        local new_value

        if event.name == defines.events.on_gui_value_changed then
            -- Slider value changed, get slider value
            new_value = element.slider_value
        elseif event.name == defines.events.on_gui_text_changed then
            -- Text field changed, get text value
            new_value = tonumber(element.text)

            if new_value then
                -- Clamp the value between 1 and 10,000
                new_value = math.min(math.max(new_value, 1), 9999)
            elseif element.text == "" then
                -- Allow empty field and set the value to 0
                new_value = 0
            else
                -- Invalid input, revert to the last valid value
                new_value = storage.shutdown_combinator_everything[unit_number].speed_control_value
            end
        end

        -- Update storage with the new value
        storage.shutdown_combinator_everything[unit_number].speed_control_value = new_value

        -- Update the slider and text field to reflect the new value
        local parent = element.parent
        local slider = parent and parent["speed_slider"]
        local text_field = parent and parent["speed_value"]

        if slider then
            slider.slider_value = new_value
        end

        if text_field then
            text_field.text = tostring(new_value)
        end
    end
end)







-- TICK -----------------------------------------------------------------------------------------------------
script.on_event(defines.events.on_tick, function(event)
    storage.shutdown_combinator_everything = storage.shutdown_combinator_everything or {}

    -- GUI CHECK
    -------------------------------------------------------------------------------------------------------------
    for _, player in pairs(game.connected_players) do
        local surface = player.surface
        local unit_number = storage.gui_open_unit and storage.gui_open_unit[player.index]
        local data = unit_number and storage.shutdown_combinator_everything[unit_number]
        local frame = player.gui.screen["shutdown-combinator-frame"] 

        if frame and frame.valid and data then
            local center_flow = frame["center_flow"]
            if center_flow and center_flow.valid then
                local content_frame = center_flow["shutdown-combinator-content"]
                if content_frame and content_frame.valid then
                    local button_row = content_frame["button_row"]
                    if button_row and button_row.valid then
                        local sprite_button = button_row["my_sprite_button"]
                        if sprite_button and sprite_button.valid then
                            local value_number = data.value_number or 0
                            local checkbox_state = data.checkbox_state or false
                            local connected = data.connected_state or false

                            sprite_button.tags = {
                                unit_number = unit_number,
                                value_number = value_number,
                                checkbox_state = checkbox_state
                            }

                            if not connected and checkbox_state then
                                sprite_button.number = nil
                                sprite_button.enabled = true
                            else
                                if checkbox_state then
                                    sprite_button.enabled = true
                                    sprite_button.number = value_number
                                else
                                    sprite_button.enabled = false
                                    sprite_button.number = nil
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Logic of the object
        -------------------------------------------------------------------------------------------------------------
        for unit_number, data in pairs(storage.shutdown_combinator_everything) do
            if not data.entity or not data.position then
                storage.shutdown_combinator_everything[unit_number] = nil
            else
                local combinator = data.entity
                local position = data.position
                local surface = combinator.valid and combinator.surface or nil

                if not combinator.valid then
                    storage.shutdown_combinator_everything[unit_number] = nil
                else
                    -- Scan once
                    if not data.scanned or data.scanned == false  then
                        local area = {
                            {position.x - 100, position.y - 100},
                            {position.x + 100, position.y + 100}
                        }
                        local nearby_entities = combinator.surface.find_entities_filtered{
                            area = area,
                            name = "space-platform-hub"
                        }
                        data.nearby_entities = nearby_entities
                        

                        for _, entity in pairs(nearby_entities) do
                            game.print("Found entity: " .. entity.name .. " at position: " .. serpent.line(entity.position))
                        end
                    end

                    local switch = data.switch_state or "left"
                    local check = data.checkbox_state or false
                    local dummy = data.dummy_signal or false
                    local value = data.value_number or 0
                    local sc_state = data.speed_control_state or false
                    local sc_value = data.speed_control_value or 0
                    local connected = false
                    local hub_speed = 0

                    local input_networks = {
                        combinator.get_circuit_network(defines.wire_connector_id.combinator_input_red),
                        combinator.get_circuit_network(defines.wire_connector_id.combinator_input_green)
                    }

                    local has_signal = false
                    for _, net in pairs(input_networks) do
                        if net and net.valid and net.signals then
                            for _, signal in pairs(net.signals) do
                                if signal.signal and signal.count > 0 then
                                    has_signal = true
                                    break
                                end
                            end
                        end
                        if has_signal then break end
                    end
                    data.shutdown_combinator_signals = has_signal

                    local output_network_ids = {}
                    for _, net in pairs({
                        combinator.get_circuit_network(defines.wire_connector_id.combinator_output_red),
                        combinator.get_circuit_network(defines.wire_connector_id.combinator_output_green)
                    }) do
                        if net and net.valid then
                            output_network_ids[net.network_id] = true
                        end
                    end

                    local nearby_entities = data.nearby_entities or {}
                    for _, hub in pairs(nearby_entities) do
                        if hub.valid then
                            local hub_inputs = {
                                hub.get_circuit_network(defines.wire_connector_id.combinator_input_red),
                                hub.get_circuit_network(defines.wire_connector_id.combinator_input_green)
                            }

                            for _, net in pairs(hub_inputs) do
                                if net and net.valid then
                                    output_network_ids[net.network_id] = true
                                    connected = true
                                end
                            end

                            for _, net in pairs(hub_inputs) do
                                if net and net.valid and output_network_ids[net.network_id] and net.signals then
                                    for _, signal in pairs(net.signals) do
                                        if signal.signal.type == "virtual" and signal.signal.name == "signal-V" then
                                            if signal.count >= 1 then
                                                hub_speed = signal.count
                                            end
                                        end
                                    end
                                end
                            end

                            data.connected_state = connected
                            if connected then 
                                data.scanned = true
                            else
                                data.scanned = false
                                 end
                            if connected then
                                local hub_speed_num = tonumber(hub_speed) or 0
                                local sc_value_num = tonumber(sc_value) or 0

                                if hub_speed_num >= sc_value_num and sc_state == true then
                                    hub.surface.platform.paused = true
                                end

                                if switch == "left" and has_signal then
                                    hub.surface.platform.paused = true
                                elseif switch == "right" and has_signal then
                                    if not (hub_speed_num >= sc_value_num and sc_state == true) then
                                        hub.surface.platform.paused = false
                                    end
                                end

                                if switch == "left" and dummy then
                                    hub.surface.platform.paused = true
                                elseif switch == "right" and dummy then
                                    if not (hub_speed_num >= sc_value_num and sc_state == true) then
                                        hub.surface.platform.paused = false
                                    end
                                end

                                -- Initialize previous speed if it doesn't exist
                                -- Ensure table for tracking last speeds exists
                                  -- Ensure storage tables exist
                                    -- Ensure storage tables exist
                                    local unit_data = storage.shutdown_combinator_everything[unit_number]
                                    if not unit_data then return end
                                    
                                    local curr = hub_speed_num
                                    local last = unit_data.last_speed or 0
                                    local diff = curr - sc_value_num
                                    local margin = 1
                                    
                                    -- Update trend state
                                    unit_data.is_increasing = unit_data.is_increasing or false
                                    if curr > last then
                                        unit_data.is_increasing = true
                                    elseif curr < last - 0.1 then
                                        unit_data.is_increasing = false
                                    end
                                    
                                    -- Core logic
                                    data.value_number =
                                        (curr == 0 or not check) and 0 or
                                        (not sc_state) and (hub.surface.platform.paused and 0 or 1) or
                                        (unit_data.is_increasing or math.abs(diff) <= margin) and 1 or 0
                                    
                                    -- Store for next tick
                                    unit_data.last_speed = curr
                                    
                                    






                                
                                

                                local frame = player.gui.screen["shutdown-combinator-frame"]
                                if frame and frame.valid then
                                    local checkbox = frame["center_flow"]["shutdown-combinator-content"]["shutdown-true-signal"]
                                    if checkbox and checkbox.valid then
                                        local should_be_checked = (data.value_number == 1)
                                        if checkbox.state ~= should_be_checked then
                                            checkbox.state = should_be_checked
                                            data.checkbox_state = should_be_checked
                                        end
                                    end
                                end

                                local behavior = combinator.get_or_create_control_behavior()
                                if behavior and behavior.valid then
                                    ---@cast behavior LuaDeciderCombinatorControlBehavior
                                    local signal_value = (check and not hub.surface.platform.paused and data.value_number == 1) and 1 or 0
                                    behavior.parameters = {
                                        conditions = {
                                            {
                                                comparator = "<",
                                                first_signal = { type = "virtual", name = "" },
                                                constant = 9999999
                                            }
                                        },
                                        outputs = {
                                            {
                                                signal = { type = "virtual", name = "signal-H" },
                                                copy_count_from_input = false,
                                                constant = signal_value
                                            }
                                        }
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)




