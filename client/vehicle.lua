local coreVehicles = exports.qbx_core:GetVehiclesByName()
local DrivingStyles = GetDrivingStyles()
local Selected = {}

---@param tbl table
---@param value any
---@return boolean, number
local function isValueInTable(tbl, value)
    local index = 0
    local found = false
    for i = 1, #tbl do
        if tbl[i] == value then
            found = true
            index = i
            break
        end
    end
    return found, index
end

lib.locale()

local function setupStyleOptions()
    local options = {
        {
            label = '0',
            defaultIndex = 1,
            icon = 'car'
        }, {
        label = locale('reset'),
        close = true,
        defaultIndex = 2,
        icon = 'rotate-right',
        args = Selected
    }, {
        label = locale('calculate'),
        close = true,
        defaultIndex = 3,
        icon = 'calculator',
        args = Selected
    } }
    for i = 1, #DrivingStyles - 1 do
        local index = #options + 1
        options[index] = {
            label = locale('df_' .. ((i < 10 and '0' .. i) or i) .. '_name'),
            defaultIndex = index,
            description = locale('df_' .. ((i < 10 and '0' .. i) or i) .. '_des'),
            checked = false
        }
    end
    return options
end

function GenerateVehiclesSpawnMenu()
    local canUseMenu = lib.callback.await('qbx_admin:server:canUseMenu', false)
    if not canUseMenu then
        lib.showMenu('qbx_adminmenu_main_menu', MenuIndexes.qbx_adminmenu_main_menu)
        return
    end

    local indexedCategories = {}
    local categories = {}
    local vehs = {}
    for _, v in pairs(coreVehicles) do
        categories[v.category] = true
    end

    local categoryIndex = 1
    local newCategories = {}
    for k in pairs(categories) do
        newCategories[categoryIndex] = k
        categoryIndex += 1
    end

    categories = newCategories

    table.sort(categories, function(a, b)
        return a < b
    end)

    for i = 1, #categories do
        lib.setMenuOptions('qbx_adminmenu_spawn_vehicles_menu',
            { label = qbx.string.capitalize(categories[i]), args = { ('qbx_adminmenu_spawn_vehicles_menu_%s'):format(categories[i]) } },
            i)

        lib.registerMenu({
            id = ('qbx_adminmenu_spawn_vehicles_menu_%s'):format(categories[i]),
            title = categories[i],
            position = 'top-right',
            onClose = function(keyPressed)
                CloseMenu(false, keyPressed, 'qbx_adminmenu_spawn_vehicles_menu')
            end,
            onSelected = function(selected)
                MenuIndexes[('qbx_adminmenu_spawn_vehicles_menu_%s'):format(categories[i])] = selected
            end,
            options = {}
        }, function(_, _, args)
            local vehNetId = lib.callback.await('qbx_admin:server:spawnVehicle', false, args[1])
            if not vehNetId then return end
            local veh
            repeat
                veh = NetToVeh(vehNetId)
                Wait(100)
            until DoesEntityExist(veh)
            TriggerEvent('qb-vehiclekeys:client:AddKeys', qbx.getVehiclePlate(veh))
            SetVehicleNeedsToBeHotwired(veh, false)
            SetVehicleHasBeenOwnedByPlayer(veh, true)
            SetEntityAsMissionEntity(veh, true, false)
            SetVehicleIsStolen(veh, false)
            SetVehicleIsWanted(veh, false)
            SetVehicleEngineOn(veh, true, true, true)
            SetPedIntoVehicle(cache.ped, veh, -1)
            SetVehicleOnGroundProperly(veh)
            SetVehicleRadioEnabled(veh, true)
            SetVehRadioStation(veh, 'OFF')
        end)
        indexedCategories[categories[i]] = 1
    end

    for k in pairs(coreVehicles) do
        vehs[#vehs + 1] = k
    end

    table.sort(vehs, function(a, b)
        return a < b
    end)

    for i = 1, #vehs do
        local v = coreVehicles[vehs[i]]
        lib.setMenuOptions(('qbx_adminmenu_spawn_vehicles_menu_%s'):format(v.category),
            { label = v.name, args = { v.model } }, indexedCategories[v.category])
        indexedCategories[v.category] += 1
    end

    lib.showMenu('qbx_adminmenu_spawn_vehicles_menu', MenuIndexes.qbx_adminmenu_spawn_vehicles_menu)
end

lib.registerMenu({
    id = 'qbx_adminmenu_vehicles_menu',
    title = 'Vehicles',
    position = 'top-right',
    onClose = function(keyPressed)
        CloseMenu(false, keyPressed, 'qbx_adminmenu_main_menu')
    end,
    onSelected = function(selected)
        MenuIndexes.qbx_adminmenu_vehicles_menu = selected
    end,
    options = {
        { label = 'Spawn Vehicle' },
        { label = 'Fix Vehicle',    close = false },
        { label = 'Buy Vehicle',    close = true },
        { label = 'Remove Vehicle', close = false },
        { label = 'Tune Vehicle' },
        { label = 'Change Plate' },
        { label = 'Driving Style Calc', close = true },
    }
}, function(selected)
    if selected == 1 then
        GenerateVehiclesSpawnMenu()
    elseif selected == 2 then
        ExecuteCommand('fix')
    elseif selected == 3 then
        ExecuteCommand('admincar')
    elseif selected == 4 then
        ExecuteCommand('dv')
    elseif selected == 5 then
        if not cache.vehicle then
            exports.qbx_core:Notify('You have to be in a vehicle, to use this', 'error')
            lib.showMenu('qbx_adminmenu_vehicles_menu', MenuIndexes.qbx_adminmenu_vehicles_menu)
            return
        end
        local override = {
            coords = GetEntityCoords(cache.ped),
            heading = GetEntityHeading(cache.ped),
            categories = {
                mods = true,
                repair = true,
                armor = true,
                respray = true,
                liveries = true,
                wheels = true,
                tint = true,
                plate = true,
                extras = true,
                neons = true,
                xenons = true,
                horn = true,
                turbo = true,
                cosmetics = true,
            },
        }
        print("Vehicle Upgrade Event")
        TriggerEvent('qb-customs:client:EnterCustoms', override)
        lib.callback.await('qbx_customs:client:openCustomsMenu', false, source)
    elseif selected == 6 then
        if not cache.vehicle then
            exports.qbx_core:Notify('You have to be in a vehicle, to use this', 'error')
            lib.showMenu('qbx_adminmenu_vehicles_menu', MenuIndexes.qbx_adminmenu_vehicles_menu)
            return
        end
        local dialog = lib.inputDialog('Custom License Plate (Max. 8 characters)', { 'License Plate' })

        if not dialog or not dialog[1] or dialog[1] == '' then
            Wait(200)
            lib.showMenu('qbx_adminmenu_vehicles_menu', MenuIndexes.qbx_adminmenu_vehicles_menu)
            return
        end

        if #dialog[1] > 8 then
            Wait(200)
            exports.qbx_core:Notify('You can only enter a maximum of 8 characters', 'error')
            lib.showMenu('qbx_adminmenu_vehicles_menu', MenuIndexes.qbx_adminmenu_vehicles_menu)
            return
        end

        SetVehicleNumberPlateText(cache.vehicle, dialog[1])
    elseif selected == 7 then
        Selected = {}
        lib.showMenu('drivingstyle_calc')
    end
end)

lib.registerMenu({
    id = 'qbx_adminmenu_spawn_vehicles_menu',
    title = 'Spawn Vehicle',
    position = 'top-right',
    onClose = function(keyPressed)
        CloseMenu(false, keyPressed, 'qbx_adminmenu_main_menu')
    end,
    onSelected = function(selected)
        MenuIndexes.qbx_adminmenu_spawn_vehicles_menu = selected
    end,
    options = {}
}, function(_, _, args)
    lib.showMenu(args[1], MenuIndexes[args[1]])
end)


lib.registerMenu(
    {
        id = 'drivingstyle_calc',
        title = locale('title.calc_menu'),
        position = 'top-right',
        canClose = true,
        onCheck = function(selected, checked)
            lib.hideMenu(false)
            for i = 1, #DrivingStyles - 1 do
                local inTable, index = isValueInTable(Selected, i)
                if selected - 3 == i then
                    if checked and not inTable then
                        Selected[#Selected + 1] = i
                        inTable = true
                    elseif not checked and inTable then
                        table.remove(Selected, index)
                        inTable = false
                    end
                    local bits = Selected and #Selected > 0 and tostring(CalculateBits(Selected)) or '0'
                    lib.setMenuOptions('drivingstyle_calc', { label = bits, icon = 'car' }, 1)
                end
                lib.setMenuOptions('drivingstyle_calc', {
                    label = locale('df_' .. ((i < 10 and '0' .. i) or i) .. '_name'),
                    description = locale('df_' .. ((i < 10 and '0' .. i) or i) .. '_des'),
                    checked = inTable
                }, i + 3)
            end
            Wait(0)
            lib.showMenu('drivingstyle_calc')
        end,
        onClose = function()
            Selected = {}
            lib.setMenuOptions('drivingstyle_calc', setupStyleOptions())
        end,
        options = setupStyleOptions()
    }, function(selected)
        if Selected and #Selected > 0 and (selected == 2 or selected == 3) then
            lib.setMenuOptions('drivingstyle_calc', { label = '0', icon = 'car' }, 1)
            for i = 1, #Selected do
                lib.setMenuOptions('drivingstyle_calc', {
                    label = locale('df_' .. ((i < 10 and '0' .. i) or i) .. '_name'),
                    description = locale('df_' .. ((i < 10 and '0' .. i) or i) .. '_des'),
                    checked = false
                }, Selected[i] + 3)
            end
            if selected == 3 then
                local bits = CalculateBits(Selected)
                if lib.alertDialog({
                        header = locale('header'),
                        content = locale('content', tostring(bits), tostring(To32Bit(bits)), tostring(ToHex(bits))),
                        centered = true,
                        cancel = true,
                        size = 'md',
                        labels = { cancel = locale('discard'), confirm = locale('copy') }
                    }) == 'confirm' then
                    lib.setClipboard(tostring(bits))
                end
            else
                Wait(0)
                lib.showMenu('drivingstyle_calc')
            end
        end
    end)

-------------------------------- NET EVENTS --------------------------------

RegisterNetEvent('qbx_admin:client:drivingstyle_calc:ShowMenu', function()
    Selected = {}; lib.showMenu('drivingstyle_calc')
end)