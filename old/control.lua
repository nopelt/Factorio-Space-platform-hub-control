local gui = require("gui")

script.on_init(function()
    -- Initialize storage at script init
    storage.shutdown_combinator_signals = {}
    storage.shutdown_gui_switch_state = {}
    storage.shutdown_gui_checkbox_state = {}
    storage.previous_connected_state = {}
    storage.shutdown_gui_value_number = 0
    storage.shutdown_gui_dummy_signal = {}
end)

script.on_event(defines.events.on_space_platform_built_entity, function(event)
    local entity = event.entity

    if entity and entity.valid and entity.name == "shutdown-combinator" then
        local unit_number = entity.unit_number
        if not unit_number then return end  -- Safety check

        -- Initialize the storage for this specific entity if not already initialized
        if not storage[unit_number] then
            storage[unit_number] = {
                shutdown_combinator_signals = {},
                shutdown_gui_value_number = 0,
                shutdown_gui_switch_state = {},
                shutdown_gui_checkbox_state = {},
                previous_connected_state = {},
                shutdown_gui_dummy_signal = {}
            }
        end

        -- Initialize GUI state for each player (per unit_number)
        for _, player in pairs(game.players) do
            local idx = player.index
            local unit_data = storage[unit_number]  -- Fetch unit-specific data

            unit_data.shutdown_gui_switch_state[idx] = unit_data.shutdown_gui_switch_state[idx] or "left"
            unit_data.shutdown_gui_checkbox_state[idx] = unit_data.shutdown_gui_checkbox_state[idx] or false
            unit_data.previous_connected_state[idx] = unit_data.previous_connected_state[idx] or false
            unit_data.shutdown_gui_dummy_signal[idx] = unit_data.shutdown_gui_dummy_signal[idx] or false
        end

        -- Set the dummy signal settings
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

script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.entity

    if entity and entity.valid and entity.name == "shutdown-combinator" then
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
                        constant = 0  -- Use the stored value here
                    }
                }
            }
        end
    end
end)

script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local shutdown_gui = player.gui.screen["shutdown-combinator-frame"]
    if shutdown_gui and shutdown_gui.valid then
        -- If shutdown-combinator GUI is open and the newly opened GUI is not shutdown-combinator
        if not (event.entity and event.entity.name == "shutdown-combinator") then
            shutdown_gui.destroy()
            return
        end
    end

    -- Now continue if player is opening a shutdown-combinator
    if not (event and event.entity and event.entity.valid) then return end

    local entity = event.entity
    if not entity or entity.name ~= "shutdown-combinator" then return end

    local unit_number = entity.unit_number
    if not unit_number then return end

    -- Initialize per-entity storage if not already present
    if not storage[unit_number] then
        storage[unit_number] = {
            shutdown_gui_switch_state = {},
            shutdown_gui_checkbox_state = {},
            previous_connected_state = {},
            shutdown_gui_dummy_signal = {}
        }
    end

    local unit_data = storage[unit_number]
    if not unit_data then return end

    local switch_state = unit_data.shutdown_gui_switch_state[event.player_index] or "left"
    local checkbox = unit_data.shutdown_gui_checkbox_state[event.player_index] or false

    gui.build_shutdown_combinator_gui(player, entity)

    player.play_sound{ path = "utility/gui_click" }
end)



script.on_event(defines.events.on_gui_click, function(event)
    if not (event and event.element and event.element.valid) then return end

    if event.element.name == "shutdown-combinator-close-button" then
        local player = game.get_player(event.player_index)
        if player and player.gui.screen["shutdown-combinator-frame"] then
            player.gui.screen["shutdown-combinator-frame"].destroy()
            player.play_sound{ path = "utility/gui_click" }
            player.opened = nil
        end
    end
end)

-- Handle switch changes (toggle button)
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    -- Initialize storage for the first time if necessary
    local player = game.players[event.player_index]
    local switch = event.element
    local unit_number = switch.unit_number  -- Get the unit number for the current entity

    if not unit_number then return end

    -- Ensure storage exists for this unit_number
    if not storage[unit_number] then
        storage[unit_number] = {
            shutdown_gui_switch_state = {},
            shutdown_gui_checkbox_state = {},
            previous_connected_state = {},
            shutdown_gui_dummy_signal = {}
        }
    end

    -- Save the switch state to storage for this unit_number and player
    storage[unit_number].shutdown_gui_switch_state[event.player_index] = switch.switch_state
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    local player = game.players[event.player_index]
    local checkbox = event.element
    local unit_number = checkbox.unit_number  -- Get the unit number for the current entity

    if not unit_number then return end

    -- Ensure storage exists for this unit_number
    if not storage[unit_number] then
        storage[unit_number] = {
            shutdown_gui_switch_state = {},
            shutdown_gui_checkbox_state = {},
            previous_connected_state = {},
            shutdown_gui_dummy_signal = {}
        }
    end

    -- Save checkbox state for this unit_number and player
    storage[unit_number].shutdown_gui_checkbox_state[event.player_index] = checkbox.state
end)

-- Handle shutdown-combinator destruction and reset data
script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end  -- Safety check for entity validity

    if entity.name == "shutdown-combinator" then
        local unit_number = entity.unit_number
        if not unit_number then return end  -- Safety check for unit_number

        -- Check if the storage exists for the specific entity, and clear it if it does
        if storage[unit_number] then
            storage[unit_number] = nil
        end
    end
end)





-- Handle switch changes (toggle button)
-------------------------------------------------------------------------------------
----- Saving the switch_state
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    -- Initialize storage for the first time if necessary
    storage.shutdown_gui_switch_state = storage.shutdown_gui_switch_state or {}

    local player = game.players[event.player_index]
    local switch = event.element
    
    -- Debug: Check if the switch state is captured
    --game.print("Switch state: " .. tostring(switch.switch_state) .. " for player " .. event.player_index)

    -- Save the switch state to storage, using the player index as the key
    if switch.name == "shutdown-gui-switch" then
        storage.shutdown_gui_switch_state[event.player_index] = switch.switch_state
       -- game.print("Saved switch state: " .. tostring(switch.switch_state))
    end
end)
----- Saving the checkbox 

-- Save checkbox state when it's toggled
script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    storage.shutdown_gui_checkbox_state = storage.shutdown_gui_checkbox_state or {}
    storage.shutdown_gui_dummy_signal = storage.shutdown_gui_dummy_signal or {}
    
    local player = game.players[event.player_index]
    local checkbox = event.element

    if checkbox.name == "shutdown-true-signal" then
        local new_state = checkbox.state
        storage.shutdown_gui_checkbox_state[event.player_index] = new_state
      --  game.print("Saved checkbox state: " .. tostring(new_state)) 
    end
    
    -- Saving the dummy signal state
    if event.element.name == "shutdown-dummy-signal" then
        local dummy_state = event.element.state
        storage.shutdown_gui_dummy_signal[event.player_index] = dummy_state
       -- game.print("Saved dummy signal state: " .. tostring(dummy_state))
    end
end)




---------------------------------------------------------------------------------

script.on_event(defines.events.on_tick, function(event)
    -- Ensure storage tables exist
    storage.shutdown_gui_dummy_signal     = storage.shutdown_gui_dummy_signal     or {}
    storage.shutdown_gui_checkbox_state   = storage.shutdown_gui_checkbox_state   or {}
    storage.shutdown_gui_value_number     = storage.shutdown_gui_value_number     or 0
    storage.shutdown_gui_switch_state     = storage.shutdown_gui_switch_state     or {}
    storage.previous_connected_state      = storage.previous_connected_state      or {}

    -- Optional: Aliases for convenience (references)
    local dummy_signal     = storage.shutdown_gui_dummy_signal
    local checkbox_state   = storage.shutdown_gui_checkbox_state
    local value_number     = storage.shutdown_gui_value_number
    local switch_state     = storage.shutdown_gui_switch_state

    for _, player in pairs(game.connected_players) do
        local index = player.index
        if index ~= 0 then 
            -- Ensure the storage for this player is initialized
            local switch = switch_state[index] or "left"  -- Add default value in case it's nil
            local check = checkbox_state and checkbox_state[index] or false
            local dummy = dummy_signal and dummy_signal[index] or false
            local value = value_number or 0
            local connected = false
            
            -- Process each shutdown-combinator
            for _, combinator in pairs(player.surface.find_entities_filtered{ name = "shutdown-combinator" }) do
                if combinator.valid then
                    local behavior = combinator.get_or_create_control_behavior()

                    -- Read only input wires for signals
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

                    -- Ensure storage for this unit_number exists
                    local unit_number = combinator.unit_number
                    if unit_number then  -- Check if unit_number is valid (not nil or invalid)
                        if not storage[unit_number] then
                            -- Initialize storage for this unit_number if it doesn't exist
                            storage[unit_number] = {
                                shutdown_gui_switch_state = {},
                                shutdown_gui_checkbox_state = {},
                                shutdown_gui_value_number = 0,
                                shutdown_gui_dummy_signal = {},
                                previous_connected_state = {}
                            }
                        end

                        -- Store whether there is a signal
                        storage[unit_number].shutdown_combinator_signals = has_signal
                    else
                        -- If unit_number is invalid, log an error or handle it
                        game.print("Invalid unit_number for shutdown combinator!")
                    end

                    -- Get output network IDs of shutdown-combinator
                    local output_network_ids = {}
                    for _, net in pairs({
                        combinator.get_circuit_network(defines.wire_connector_id.combinator_output_red),
                        combinator.get_circuit_network(defines.wire_connector_id.combinator_output_green)
                    }) do
                        if net and net.valid then
                            output_network_ids[net.network_id] = true
                        end
                    end
                    
                    -- Control matching space-platform-hubs
                    for _, hub in pairs(player.surface.find_entities_filtered{ name = "space-platform-hub" }) do
                        if hub.valid then
                            -- Get input networks from the hub
                            local hub_inputs = {
                                hub.get_circuit_network(defines.wire_connector_id.combinator_input_red),
                                hub.get_circuit_network(defines.wire_connector_id.combinator_input_green)
                            }

                            for _, net in pairs(hub_inputs) do
                                if net and net.valid and output_network_ids[net.network_id] then
                                    connected = true
                                    break
                                end
                            end
                            if connected then
                                if not storage.previous_connected_state[index] then
                                    game.print("Connected to the HUB!")
                                    storage.previous_connected_state[index] = true
                                end
                            else
                                storage.previous_connected_state[index] = false
                            end

                            if connected then
                                 
                                -- IF Manual And Signal True Pause
                                if switch == "left" and has_signal then
                                    hub.surface.platform.paused = true
                                -- IF Automatic And Signal True Unpause
                                elseif switch == "right" and has_signal then
                                    hub.surface.platform.paused = false
                                end

                                -- Manual Pause based on checkbox state
                                if switch == "left" and dummy == true then
                                    hub.surface.platform.paused = true
                                elseif switch == "right" and dummy == true then
                                    hub.surface.platform.paused = false
                                end

                                -- Sync checkbox state based on platform paused state
                                if check == true then
                                    if hub.surface.platform.paused then
                                        storage.shutdown_gui_value_number = 0
                                    else
                                        storage.shutdown_gui_value_number = 1
                                    end
                                end

                                -- Update checkbox state in GUI
                                local frame = player.gui.screen["shutdown-combinator-frame"]
                                if frame and frame.valid then
                                    local checkbox = frame["center_flow"]["shutdown-combinator-content"]["shutdown-true-signal"]
                                    if checkbox and checkbox.valid then
                                        local should_be_checked = (value == 1)
                                        if checkbox.state ~= should_be_checked then
                                            checkbox.state = should_be_checked
                                            storage.shutdown_gui_checkbox_state[player.index] = should_be_checked
                                           -- game.print("Checkbox synced to " .. tostring(should_be_checked) .. " for player " .. player.index)
                                        end
                                    end
                                end

                                -- Update the control behavior dynamically
                                if behavior and behavior.valid then
                                    ---@cast behavior LuaDeciderCombinatorControlBehavior ----- VSL ANTI ERROR
                                    
                                    local signal_value = 0
                                    if check == true and hub.surface.platform.paused == false and storage.shutdown_gui_value_number == 1 then
                                        signal_value = 1
                                    else
                                        signal_value = 0
                                    end

                                    -- Update the control behavior parameters based on the signal value 
                                  
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
            
            -- Update the sprite button in real-time
            local frame = player.gui.screen["shutdown-combinator-frame"]
            if frame and frame.valid then
                local button_row = frame["center_flow"]["shutdown-combinator-content"]["button_row"]
                if button_row and button_row.valid then
                    local sprite_button = button_row["my_sprite_button"]
                    if sprite_button and sprite_button.valid then
                        local new_state = switch_state[player.index] or "left"  -- Correct assignment

                        -- Update the number and enabled state in real-time
                        local value_number = storage.shutdown_gui_value_number or 0
                        local checkbox_state = storage.shutdown_gui_checkbox_state[player.index] or false

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
end)




