ESX = exports['es_extended']:getSharedObject()

_menuPool = NativeUI.CreatePool()
local mainMenu

local helmet = 1
local mask = 1
local glasses = 1
local ears = 1
local chain = 1
local torso = 1
local tshirt = 1
local bag = 1
local pants = 1
local shoes = 1

local handsup = false
local isEscorting = false
local triggerOnClose = true
local blips = {}
local autopilotActive = false
local cruiseControlActive = false
local headbag = false


local gps
local gpsCode

local handsUpAnim = 'missminuteman_1ig_2'

local carry = {
	InProgress = false,
	targetSrc = -1,
	type = "",
	personCarrying = {
		animDict = "missfinale_c2mcs_1",
		anim = "fin_c2_mcs_1_camman",
		flag = 49,
	},
	personCarried = {
		animDict = "nm",
		anim = "firemans_carry",
		attachX = 0.27,
		attachY = 0.15,
		attachZ = 0.63,
		flag = 33,
	}
}


local job
local jobgrade


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(newjob)
    job = newjob.name
    jobgrade = newjob.grade_name
end)

Citizen.CreateThread(function()
    while true do

        if _menuPool:IsAnyMenuOpen() then
            _menuPool:ProcessMenus()
        end

        Wait(1)
    end
end)

RegisterCommand('playermenuv2', function()
    TriggerEvent('primePlayermenuV2:openPlayermenu')
end)
RegisterCommand('playermenu_handsup', function()
    handsUp()
end)

RegisterKeyMapping('playermenuv2', 'Open Interaction Menu', 'keyboard', Config.OpenMenu)
RegisterKeyMapping('playermenu_handsup', 'Hands Up', 'keyboard', Config.HandsUp)

Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    ESX.PlayerData = ESX.GetPlayerData()
    job = ESX.PlayerData.job.name
    jobgrade = ESX.PlayerData.job.grade_name

    while true do
        Wait(0)

        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            if IsControlPressed(0, 71) and not GetIsVehicleEngineRunning(vehicle) then
                SetVehicleEngineOn(vehicle, false, true, true)
            end
        end
    end
end)

function handsUp()

    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local seatIndex = -2
        
        for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 1 do
            if GetPedInVehicleSeat(vehicle, i) == playerPed then
                seatIndex = i
                break
            end
        end

        if seatIndex == -1 then
            if handsup then
                TriggerServerEvent('primePlayermenuV2:handsUp', GetPlayerServerId(PlayerId()), false)
                handsup = false
                ClearPedTasks(playerPed)
            end
            ShowNotification(Translation[Config.Locale]['handsup_error'])
            return
        end

    end

    if not handsup then
        TriggerServerEvent('primePlayermenuV2:handsUp', GetPlayerServerId(PlayerId()), true)
        ESX.Streaming.RequestAnimDict(handsUpAnim, function()
            TaskPlayAnim(playerPed, handsUpAnim, 'handsup_enter', 8.0, 8.0, -1, 50, 0, false, false, false)
            RemoveAnimDict(handsUpAnim)
        end)
        handsup = true
    else
        TriggerServerEvent('primePlayermenuV2:handsUp', GetPlayerServerId(PlayerId()), false)
        handsup = false
        ClearPedTasks(playerPed)
    end

end

RegisterNetEvent('primePlayermenuV2:openRobMenu', function(target)

    _menuPool:CloseAllMenus()
    collectgarbage()

    local RobMenu = NativeUI.CreateMenu(Translation[Config.Locale]['robmenu_title'], Translation[Config.Locale]['robmenu_subtitle'], Config.MenuPosition.X, Config.MenuPosition.Y)
    RobMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
    _menuPool:Add(RobMenu)

    RobMenu.OnMenuClosed = function()
        TriggerServerEvent('primePlayermenuV2:RobMenuClosed', target)
        ClearPedTasks(PlayerPedId())
    end

    local showIdcard = NativeUI.CreateItem(Translation[Config.Locale]['robmenu_idcard'], '')
    RobMenu:AddItem(showIdcard)

    showIdcard.Activated = function()

        ShowNotification(Translation[Config.Locale]['robmenu_idcard_notify'])
        if Config.JsfourIDCard then
            TriggerServerEvent('jsfour-idcard:open', target, GetPlayerServerId(PlayerId()))
        elseif Config.CustomIDCard then
            openTargetIDCard(target, GetPlayerServerId(PlayerId()))
        end
        TriggerServerEvent('primePlayermenuV2:showIDCard', target)
    end

    ESX.TriggerServerCallback('primePlayermenuV2:getTargetInventory', function(inventory)
        for k, v in pairs(inventory) do
            if v.count > 0 then

                local item = NativeUI.CreateItem(v.count .. 'x ' .. v.label, '')
                item:RightLabel(v.count * v.weight .. 'kg')
                RobMenu:AddItem(item)
                _menuPool:RefreshIndex()

                item.Activated = function()

                    local amountInput = lib.inputDialog(v.label, {
                        {type = 'number', label = Translation[Config.Locale]['amount'], description = Translation[Config.Locale]['amount_desc'], required = false, default = v.count, min = 1, max = v.count}
                    })

                    if not amountInput then return end

                    TriggerServerEvent('primePlayermenuV2:RobInventoryItem', target, v.name, amountInput[1], v.label, 'item')
                    TriggerEvent('primePlayermenuV2:openRobMenu', target)
                end

            end
        end

    end, target)

    ESX.TriggerServerCallback('primePlayermenuV2:getTargetLoadout', function(loadout)
    
        for k, v in pairs(loadout) do

            local weapon = NativeUI.CreateItem(v.label, '')
            weapon:RightLabel(v.ammo .. Translation[Config.Locale]['ammo'])
            RobMenu:AddItem(weapon)
            _menuPool:RefreshIndex()

            weapon.Activated = function(sender, index)

                TriggerServerEvent('primePlayermenuV2:RobInventoryItem', target, v.name, 1, v.label, 'weapon')
                TriggerEvent('primePlayermenuV2:openRobMenu', target)
               
            end

        end
    
    end, target)


    RobMenu:RefreshIndex()
    RobMenu:Visible(true)
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)

end)

RegisterNetEvent('primePlayermenuV2:openWallet', function()

    _menuPool:CloseAllMenus()
    -- collectgarbage()

    local WalletMenu = NativeUI.CreateMenu(Translation[Config.Locale]['playeractions_title'], Translation[Config.Locale]['playeractions_title'], Config.MenuPosition.X, Config.MenuPosition.Y)
    WalletMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
    _menuPool:Add(WalletMenu)

    WalletMenu.OnMenuClosed = function(menu)
        TriggerEvent('primePlayermenuV2:openPlayermenu')
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local playersInArea = ESX.Game.GetPlayersInArea(playerCoords, 3.0)
    local selectedIndex = 1
    local selectedPlayerCoords

    local licenses = {
        Translation[Config.Locale]['license_idcard'],
        Translation[Config.Locale]['license_driver'],
        Translation[Config.Locale]['license_gun']
    }

    if #playersInArea > 0 then

        local hasInviteAccess = false
        if Config.JobBossAccess ~= nil and #Config.JobBossAccess > 0 then
            for k, v in pairs(Config.JobBossAccess) do
                if v == jobgrade then
                    hasInviteAccess = true
                    break
                end

            end
        else
            hasInviteAccess = true
        end

        for k, v in pairs(playersInArea) do

            selectedPlayerCoords = GetEntityCoords(GetPlayerPed(playersInArea[selectedIndex]))

            local distance = GetDistanceBetweenCoords(selectedPlayerCoords.x, selectedPlayerCoords.y, selectedPlayerCoords.z, playerCoords, true)
            local player = _menuPool:AddSubMenu(WalletMenu, Translation[Config.Locale]['player_nearby'], '', true, true)
            player.Item:RightLabel(math.floor(distance) .. 'm')
            player.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

            if Config.PlayerInteractions.carry then
                local carryPlayer = NativeUI.CreateItem(Translation[Config.Locale]['carry'], '')
                player.SubMenu:AddItem(carryPlayer)

                carryPlayer.Activated = function()

                    if not carry.InProgress then
                        local targetSrc = GetPlayerServerId(playersInArea[selectedIndex])
                        if targetSrc ~= -1 then
                            carry.InProgress = true
                            carry.targetSrc = targetSrc
                            TriggerServerEvent("primePlayermenuV2:sync",targetSrc)
                            ensureAnimDict(carry.personCarrying.animDict)
                            carry.type = "carrying"
                        else
                            ShowNotification(Translation[Config.Locale]['noplayers_nearby'])
                        end
                        
                    else
                        carry.InProgress = false
                        ClearPedSecondaryTask(PlayerPedId())
                        DetachEntity(PlayerPedId(), true, false)
                        TriggerServerEvent("primePlayermenuV2:stop",carry.targetSrc)
                        carry.targetSrc = 0
                    end
    
                end

            end

            local cuffuncuffPlayer
            if Config.PlayerInteractions.handcuff then
                cuffuncuffPlayer = NativeUI.CreateListItem(Translation[Config.Locale]['handcuff'], {Translation[Config.Locale]['handcuff_apply'], Translation[Config.Locale]['handcuff_release']}, 1, '')
                player.SubMenu:AddItem(cuffuncuffPlayer)
            end

            if Config.PlayerInteractions.escort then
                local escortPlayer = NativeUI.CreateItem(Translation[Config.Locale]['escort'], '')
                player.SubMenu:AddItem(escortPlayer)

                escortPlayer.Activated = function()
                    ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                        if not cuffed then
                            ShowNotification(Translation[Config.Locale]['escort_error'])
                        else
                            TriggerServerEvent('primePlayermenuV2:EscortPlayer', GetPlayerServerId(playersInArea[selectedIndex]))
                        end
                        
                    end, GetPlayerServerId(playersInArea[selectedIndex]))
                end
            end

            if Config.PlayerInteractions.search then
                local searchPlayer = NativeUI.CreateItem(Translation[Config.Locale]['search'], '')
                player.SubMenu:AddItem(searchPlayer)

                searchPlayer.Activated = function()

                    local isHandsup = true
                    local iscuffed
                    -- ESX.TriggerServerCallback('primePlayermenuV2:checkHandsUp', function(handsup)
                    --     isHandsup = handsup
                    -- end, GetPlayerServerId(playersInArea[selectedIndex]))
    
                    ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                        iscuffed = cuffed
                    end, GetPlayerServerId(playersInArea[selectedIndex]))
    
                    while isHandsup == nil and iscuffed == nil do
                        Wait(10)
                    end
    
                    if not iscuffed and not isHandsup then
                        ShowNotification(Translation[Config.Locale]['search_error'])
                    else

                        if lib.progressBar({
                            duration = 2000,
                            label = Translation[Config.Locale]['search'],
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                            },
                            anim = {
                                dict = 'anim@gangops@morgue@table@',
                                clip = 'player_search'
                            },
                        }) then
                            
                            local anim = 'anim@gangops@morgue@table@'
                            ESX.Streaming.RequestAnimDict(anim, function()
                                TaskPlayAnim(PlayerPedId(), anim, "player_search", 8.0, 8.0, -1, 1, 0, false, false, false)
                                RemoveAnimDict(anim)
                            end)
    
                            if Config.RobberyMenu.ox_inventory then
                                exports.ox_inventory:openInventory('player', GetPlayerServerId(playersInArea[selectedIndex]))
                                _menuPool:CloseAllMenus()
                            elseif Config.RobberyMenu.playermenuV2 then
                                TriggerEvent('primePlayermenuV2:openRobMenu', GetPlayerServerId(playersInArea[selectedIndex]))
                            end
                            TriggerServerEvent('primePlayermenuV2:gettingRobbedNotify', GetPlayerServerId(playersInArea[selectedIndex]))                            
                        
                        else


                        end

                    end
    
                end

            end

            if Config.PlayerInteractions.putInVehicle then
                local putInVehicle = NativeUI.CreateItem(Translation[Config.Locale]['putInVehicle'], '')
                player.SubMenu:AddItem(putInVehicle)

                putInVehicle.Activated = function()

                    ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                        if not cuffed then
                            ShowNotification(Translation[Config.Locale]['putInVehicle_error'])
                        else
                            TriggerServerEvent('primePlayermenuV2:PutInVehicleServer', GetPlayerServerId(playersInArea[selectedIndex]))
                        end
                        
                    end, GetPlayerServerId(playersInArea[selectedIndex]))
                    
                end

            end

            if Config.PlayerInteractions.takeFromVehicle then
                local takePlayerFromVehicle = NativeUI.CreateItem(Translation[Config.Locale]['takeFromVehicle'], '')
                player.SubMenu:AddItem(takePlayerFromVehicle)

                takePlayerFromVehicle.Activated = function()

                    ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                        if not cuffed then
                            ShowNotification(Translation[Config.Locale]['putInVehicle_error'])
                        else
                            TriggerServerEvent('primePlayermenuV2:TakePlayerFromVehicleServer', GetPlayerServerId(playersInArea[selectedIndex]))
                        end
                        
                    end, GetPlayerServerId(playersInArea[selectedIndex]))
    
                end

            end

            if Config.PlayerInteractions.takeOffMask then
                local takeOffMask = NativeUI.CreateItem(Translation[Config.Locale]['takeoffmask'], '')
                player.SubMenu:AddItem(takeOffMask)

                takeOffMask.Activated = function()

                    ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                        if not cuffed then
                            ShowNotification(Translation[Config.Locale]['takeoffmask_error'])
                        else
                            TriggerServerEvent('primePlayermenuV2:takeOffMask', GetPlayerServerId(playersInArea[selectedIndex]))
                        end
                        
                    end, GetPlayerServerId(playersInArea[selectedIndex]))

                end
            end

            if Config.PlayerInteractions.headbag then
                local headbag = NativeUI.CreateItem(Translation[Config.Locale]['headbag'], '')
                player.SubMenu:AddItem(headbag)

                headbag.Activated = function()

                    ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                        if not cuffed then
                            ShowNotification(Translation[Config.Locale]['headbag_error'])
                        else
                            ShowNotification(Translation[Config.Locale]['headbag_sender'])
                            TriggerServerEvent('primePlayermenuV2:useHeadbag', GetPlayerServerId(playersInArea[selectedIndex]))
                        end
                        
                    end, GetPlayerServerId(playersInArea[selectedIndex]))
                end
            end

            local showLicenses
            if Config.PlayerInteractions.licenses then
                showLicenses = NativeUI.CreateListItem(Translation[Config.Locale]['licenses'], licenses, 1, '')
                player.SubMenu:AddItem(showLicenses)

            end

            if Config.PlayerInteractions.job then
                local company = _menuPool:AddSubMenu(player.SubMenu, Translation[Config.Locale]['job_options'], '', true, true)
                company.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

                if Config.PlayerInteractions.inviteJob then
                    local jobinvite = NativeUI.CreateItem(Translation[Config.Locale]['invitejob'], '')
                    if not hasInviteAccess then
                        jobinvite:SetRightBadge(21)
                    end
                    company.SubMenu:AddItem(jobinvite)

                    jobinvite.Activated = function()

                        if hasInviteAccess then
                            TriggerServerEvent('primePlayermenuV2:InvitePlayer', GetPlayerServerId(playersInArea[selectedIndex]))
                            ShowNotification(Translation[Config.Locale]['invite_sent'])
                        end

                    end
                end

                if Config.PlayerInteractions.fire then
                    local jobfire = NativeUI.CreateItem(Translation[Config.Locale]['jobfire'], '')
                    if not hasInviteAccess then
                        jobfire:SetRightBadge(21)
                    end
                    company.SubMenu:AddItem(jobfire)

                    jobfire.Activated = function()
                        if hasInviteAccess then
                            TriggerServerEvent('primePlayermenuV2:JobKick', GetPlayerServerId(playersInArea[selectedIndex]), job)
                        end
                    end
                end

                if Config.PlayerInteractions.promote then
                    local jobpromote = NativeUI.CreateItem(Translation[Config.Locale]['promote'], '')
                    if not hasInviteAccess then
                        jobpromote:SetRightBadge(21)
                    end
                    company.SubMenu:AddItem(jobpromote)

                    jobpromote.Activated = function()
                        if hasInviteAccess then
                            TriggerServerEvent('primePlayermenuV2:JobPromote', GetPlayerServerId(playersInArea[selectedIndex]), job)
                        end
                    end
                end

                if Config.PlayerInteractions.degrade then
                    local jobdegrade = NativeUI.CreateItem(Translation[Config.Locale]['degrade'], '')
                    if not hasInviteAccess then
                        jobdegrade:SetRightBadge(21)
                    end
                    company.SubMenu:AddItem(jobdegrade)

                    jobdegrade.Activated = function()
                        if hasInviteAccess then
                            TriggerServerEvent('primePlayermenuV2:JobDegrade', GetPlayerServerId(playersInArea[selectedIndex]), job)
                        end
                    end
                end
            end

            player.SubMenu.OnListSelect = function(sender, item, index)
                if item == showLicenses then 
                    if index == 1 then
                        if Config.JsfourIDCard then
                            TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(playersInArea[selectedIndex]))
                        elseif Config.CustomIDCard then
                            showMyLicense(GetPlayerServerId(PlayerId()), GetPlayerServerId(playersInArea[selectedIndex]))
                        end
                        ShowNotification(Translation[Config.Locale]['idcard_showed'])
                    elseif index == 2 then
                        if Config.JsfourIDCard then
                            TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(playersInArea[selectedIndex]), 'driver')
                        elseif Config.CustomIDCard then
                            showMyLicense(GetPlayerServerId(PlayerId()), GetPlayerServerId(playersInArea[selectedIndex]), 'driver')
                        end
                        ShowNotification(Translation[Config.Locale]['driverslicense_showed'])
                    elseif index == 3 then
                        if Config.JsfourIDCard then
                            TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(playersInArea[selectedIndex]), 'weapon')
                        elseif Config.CustomIDCard then
                            showMyLicense(GetPlayerServerId(PlayerId()), GetPlayerServerId(playersInArea[selectedIndex]), 'weapon')
                        end
                        ShowNotification(Translation[Config.Locale]['gunlicense_showed'])
                    end
                elseif item == cuffuncuffPlayer then
                    if index == 1 then
                        local itemCount
                        if Config.HandcuffItem ~= nil then

                            ESX.TriggerServerCallback('primePlayermenuV2:hasInventoryItem', function(count)
                                itemCount = count
                                if itemCount > 0 then
                                    local isPedInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
                                    if not isPedInVehicle then
                                        ESX.TriggerServerCallback('primePlayermenuV2:checkHandsUp', function(isHandsUp)
                                            if isHandsUp then                                        
                                                TriggerEvent("primePlayermenuV2:checkCuff", playersInArea[selectedIndex])
                                            else
                                                ShowNotification(Translation[Config.Locale]['handcuff_error'])
                                            end
                                        end, GetPlayerServerId(playersInArea[selectedIndex]))
                                    else
                                        ShowNotification(Translation[Config.Locale]['handcuff_vehicle_error'])
                                    end
                                else
                                    ShowNotification(Translation[Config.Locale]['no_handcuff_item'])
                                end
                            end, Config.HandcuffItem)

                        else

                            local isPedInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
                            if not isPedInVehicle then
                                ESX.TriggerServerCallback('primePlayermenuV2:checkHandsUp', function(isHandsUp)
                                    if isHandsUp then                                        
                                        TriggerEvent("primePlayermenuV2:checkCuff", playersInArea[selectedIndex])
                                    else
                                        ShowNotification(Translation[Config.Locale]['handcuff_error'])
                                    end
                                end, GetPlayerServerId(playersInArea[selectedIndex]))
                            else
                                ShowNotification(Translation[Config.Locale]['handcuff_vehicle_error'])
                            end
                            
                        end

                        
                        
                        
                    elseif index == 2 then
                        local isPedInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
                        if not isPedInVehicle then
                            ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                                if cuffed then
                                    TriggerEvent("primePlayermenuV2:uncuff", playersInArea[selectedIndex])
                                    ShowNotification(Translation[Config.Locale]['player_cuffed'])
                                else
                                    ShowNotification(Translation[Config.Locale]['uncuff_error'])
                                end
                            end, GetPlayerServerId(playersInArea[selectedIndex]))
                        else
                            ShowNotification(Translation[Config.Locale]['handcuff_vehicle_error'])
                        end
                    end
                end

            end

            WalletMenu.OnMenuChanged = function(menu, newmenu)
                if newmenu == player.SubMenu then 
        
                    Citizen.CreateThread(function()
                        while true do
        
                            playerCoords = GetEntityCoords(PlayerPedId())
                            selectedPlayerCoords = GetEntityCoords(GetPlayerPed(playersInArea[selectedIndex]))
                            local distance = GetDistanceBetweenCoords(selectedPlayerCoords.x, selectedPlayerCoords.y, selectedPlayerCoords.z, playerCoords, true)
                            
                            if distance >= 3.0 then
                                ShowNotification(Translation[Config.Locale]['player_toofar'])
                                TriggerEvent('primePlayermenuV2:openPlayermenu')
                                break
                            end

                            if not _menuPool:IsAnyMenuOpen() then
                                break
                            end
        
                            Wait(1)
                        end
                    end)
        
                end
        
            end

        end

    else
        local noPlayers = NativeUI.CreateItem(Translation[Config.Locale]['noplayers_nearby'], '')
        WalletMenu:AddItem(noPlayers)
    end

    WalletMenu.OnIndexChange = function(sender, index)
        selectedIndex = index
        selectedPlayerCoords = GetEntityCoords(GetPlayerPed(playersInArea[selectedIndex]))
    end

    Citizen.CreateThread(function()
        while true do

            if selectedPlayerCoords ~= nil then
                selectedPlayerCoords = GetEntityCoords(GetPlayerPed(playersInArea[selectedIndex]))
                DrawMarker(Config.DrawMarker.type, selectedPlayerCoords.x, selectedPlayerCoords.y, selectedPlayerCoords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, Config.DrawMarker.size, Config.DrawMarker.size, Config.DrawMarker.size, Config.DrawMarker.r, Config.DrawMarker.g, Config.DrawMarker.b, Config.DrawMarker.opacity, false, true, 2, nil, nil, false)
            end

            if not _menuPool:IsAnyMenuOpen() then
                break
            end

            Wait(1)
        end
    end)


    _menuPool:RefreshIndex()
    WalletMenu:Visible(true)
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)

end)

RegisterNetEvent('primePlayermenuV2:openPlayermenu', function()

    local isPedInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)

    local fullname
    local birthdate
    local joblabel
    local jobgrade
    local jobgradelabel
    local salary
    local playtime

    local cash
    local blackmoney
    local bank

    local skin

    ESX.TriggerServerCallback('primePlayermenuV2:getPlayerDatas', function(getfullname, getjoblabel, getjobgrade, getjobgradelabel, getsalary, getcash, getblackmoney, getbank, getbirthdate, getplaytime)
    
        fullname = getfullname
        birthdate = getbirthdate
        joblabel = getjoblabel
        jobgrade = getjobgrade
        jobgradelabel = getjobgradelabel
        salary = getsalary
        if getplaytime == nil then
            getplaytime = 0
        end
        playtime = getplaytime

        cash = getcash
        blackmoney = getblackmoney
        bank = getbank

    
    end)

    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(playerSkin)
        skin = playerSkin
    end)

    _menuPool:Remove()
    _menuPool = NativeUI.CreatePool()

    while birthdate == nil do
        Wait(0)
    end

    mainMenu = NativeUI.CreateMenu(Translation[Config.Locale]['playermenu_title'], Translation[Config.Locale]['playermenu_subtitle'], Config.MenuPosition.X, Config.MenuPosition.Y)
    mainMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
    _menuPool:Add(mainMenu)

    if Config.MenuContent.playerInteraction then
        local wallet_item = NativeUI.CreateItem(Translation[Config.Locale]['playerinteractions'], '')
        mainMenu:AddItem(wallet_item)

        wallet_item.Activated = function()
            ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
                if not cuffed then
                    local playersInArea = ESX.Game.GetPlayersInArea(playerCoords, 3.0)
                    if #playersInArea > 0 then
                        TriggerEvent('primePlayermenuV2:openWallet')
                    else
                        ShowNotification(Translation[Config.Locale]['noplayers_nearby'])
                    end
                else
                    ShowNotification(Translation[Config.Locale]['interactions_error'])
                end
            end, GetPlayerServerId(PlayerId()))
        end

    end

    if Config.MenuContent.vehicleInteraction then
        if isPedInVehicle then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                local engineStatus = GetIsVehicleEngineRunning(vehicle)
                local vehicleModel = GetEntityModel(vehicle)
                local spawnName = GetDisplayNameFromVehicleModel(vehicleModel)

                local autopilotAllowed = false
                if Config.AutopilotForEveryVehicle then
                    autopilotAllowed = true
                else
                    if #Config.AutopilotVehicleList > 0 then
                        for k, v in pairs(Config.AutopilotVehicleList) do
                            if v == spawnName then
                                autopilotAllowed = true
                                break
                            end
                        end
                    else
                        autopilotAllowed = false
                    end
                end

                local doors = {
                    Translation[Config.Locale]['driver'],
                    Translation[Config.Locale]['passenger'],
                    Translation[Config.Locale]['backleft'],
                    Translation[Config.Locale]['backright'],
                    Translation[Config.Locale]['trunk'],
                    Translation[Config.Locale]['hood']
                }

                local windows = {
                    Translation[Config.Locale]['driver'],
                    Translation[Config.Locale]['passenger'],
                    Translation[Config.Locale]['backleft'],
                    Translation[Config.Locale]['backright'],
                }

                local doorState = {
                    FrontLeft = false,
                    FrontRight = false,
                    BackLeft = false,
                    BackRight = false,
                    trunk = false,
                    hood = false,
                }

                local windowState = {
                    FrontLeft = false,
                    FrontRight = false,
                    BackLeft = false,
                    BackRight = false,
                }

                local vehicle_interaction = _menuPool:AddSubMenu(mainMenu, Translation[Config.Locale]['vehicleinteractions'], '', true, true)
                vehicle_interaction.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

                local toggle_engine = NativeUI.CreateCheckboxItem(Translation[Config.Locale]['toggleengine'], engineStatus, '')
                vehicle_interaction.SubMenu:AddItem(toggle_engine)

                local vehicle_doors = NativeUI.CreateListItem(Translation[Config.Locale]['doors'], doors, 1, '')
                vehicle_interaction.SubMenu:AddItem(vehicle_doors)

                local vehicle_windows = NativeUI.CreateListItem(Translation[Config.Locale]['windows'], windows, 1, '')
                vehicle_interaction.SubMenu:AddItem(vehicle_windows)

                local autopilot
                if autopilotAllowed then
                    autopilot = NativeUI.CreateCheckboxItem(Translation[Config.Locale]['autopilot'], autopilotActive, '')
                    vehicle_interaction.SubMenu:AddItem(autopilot)
                else
                    local autopilotNotSupported = NativeUI.CreateItem(Translation[Config.Locale]['autopilot'], Translation[Config.Locale]['noautopilot'])
                    autopilotNotSupported:SetRightBadge(4)
                    vehicle_interaction.SubMenu:AddItem(autopilotNotSupported)
                end

                local cruiseControl = NativeUI.CreateCheckboxItem(Translation[Config.Locale]['cruisecontrol'], cruiseControlActive, '')
                vehicle_interaction.SubMenu:AddItem(cruiseControl)
                
                vehicle_interaction.SubMenu.OnListSelect = function(sender, item, index)
                    if item == vehicle_doors then

                        if index == 1 then
                                            
                            if doorState.FrontLeft == false then
                                doorState.FrontLeft = true
                                SetVehicleDoorOpen(vehicle, 0, false, false)
                            else
                                doorState.FrontLeft = false
                                SetVehicleDoorShut(vehicle, 0, false)
                            end
                        elseif index == 2 then

                            if doorState.FrontRight == false then
                                doorState.FrontRight = true
                                SetVehicleDoorOpen(vehicle, 1, false, false)
                            else
                                doorState.FrontRight = false
                                SetVehicleDoorShut(vehicle, 1, false)
                            end
                        
                        elseif index == 3 then

                            if doorState.BackLeft == false then
                                doorState.BackLeft = true
                                SetVehicleDoorOpen(vehicle, 2, false, false)
                            else
                                doorState.BackLeft = false
                                SetVehicleDoorShut(vehicle, 2, false)
                            end
                        
                        elseif index == 4 then

                            if doorState.BackRight == false then
                                doorState.BackRight = true
                                SetVehicleDoorOpen(vehicle, 3, false, false)
                            else
                                doorState.BackRight = false
                                SetVehicleDoorShut(vehicle, 3, false)
                            end

                        elseif index == 5 then

                            if doorState.trunk == false then
                                doorState.trunk = true
                                SetVehicleDoorOpen(vehicle, 5, false, false)
                            else
                                doorState.trunk = false
                                SetVehicleDoorShut(vehicle, 5, false)
                            end

                        elseif index == 6 then

                            if doorState.hood == false then
                                doorState.hood = true
                                SetVehicleDoorOpen(vehicle, 4, false, false)
                            else
                                doorState.hood = false
                                SetVehicleDoorShut(vehicle, 4, false)
                            end

                        end

                    elseif item == vehicle_windows then

                        if index == 1 then
                            if windowState.FrontLeft == false then
                                windowState.FrontLeft = true
                                RollDownWindow(vehicle, 0)
                            else
                                windowState.FrontLeft = false
                                RollUpWindow(vehicle, 0)
                            end
                            
                        elseif index == 2 then
                            if windowState.FrontRight == false then
                                windowState.FrontRight = true
                                RollDownWindow(vehicle, 1)
                            else
                                windowState.FrontRight = false
                                RollUpWindow(vehicle, 1)
                            end

                        elseif index == 3 then
                            if windowState.BackLeft == false then
                                windowState.BackLeft = true
                                RollDownWindow(vehicle, 2)
                            else
                                windowState.BackLeft = false
                                RollUpWindow(vehicle, 2)
                            end

                        elseif index == 4 then
                            if windowState.BackRight == false then
                                windowState.BackRight = true
                                RollDownWindow(vehicle, 3)
                            else
                                windowState.BackRight = false
                                RollUpWindow(vehicle, 3)
                            end
                        end


                    end

                end

                local bCoords
                vehicle_interaction.SubMenu.OnCheckboxChange = function(sender, item, checked)
                    if item == toggle_engine then
                        engineStatus = checked
                        if checked == true then
                            SetVehicleEngineOn(vehicle, true, true, false)
                            ShowNotification(Translation[Config.Locale]['engine_on'])
                        else
                            SetVehicleEngineOn(vehicle, false, true, false)
                            ShowNotification(Translation[Config.Locale]['engine_off'])
                        end

                    elseif item == autopilot then
                        toggleAutopilot(checked)
                    elseif item == cruiseControl then
                        toggleCruiseControl(checked)
                    end

                end

            else
                local locked_vehicle = NativeUI.CreateItem(Translation[Config.Locale]['vehicleinteraction_locked'], '')
                locked_vehicle:SetRightBadge(21)
                mainMenu:AddItem(locked_vehicle)
            end

        else

            local closestVehicle, closestDistance = GetClosestVehicleToPlayer()

            if closestVehicle ~= nil and closestDistance < 3.0 then
                local vehicle_interaction = _menuPool:AddSubMenu(mainMenu, Translation[Config.Locale]['vehicleinteractions'], '', true, true)
                vehicle_interaction.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

                mainMenu.OnMenuChanged = function(menu, newmenu)
                    if newmenu == vehicle_interaction.SubMenu then

                        Citizen.CreateThread(function()
                            local playerPed = PlayerPedId()
                            while true do

                                local playerCoords = GetEntityCoords(playerPed)
                                local vehicleCoords = GetEntityCoords(closestVehicle)
                                local distance = GetDistanceBetweenCoords(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, playerCoords, true)

                                if distance > 3.0 then
                                    ShowNotification(Translation[Config.Locale]['vehicle_toofar'])
                                    vehicle_interaction.SubMenu:GoBack()
                                    break
                                end

                                if not _menuPool:IsAnyMenuOpen() then
                                    break
                                end

                                Wait(1000)
                            end
                        end)

                    end
                end

                local hoodTrunkList = {
                    Translation[Config.Locale]['open'],
                    Translation[Config.Locale]['close']
                }

                local hood = NativeUI.CreateListItem(Translation[Config.Locale]['hood'], hoodTrunkList, 1, '')
                vehicle_interaction.SubMenu:AddItem(hood)

                local trunk = NativeUI.CreateListItem(Translation[Config.Locale]['trunk'], hoodTrunkList, 1, '')
                vehicle_interaction.SubMenu:AddItem(trunk)

                vehicle_interaction.SubMenu.OnListSelect = function(sender, item, index)
                    if item == hood then
                        if index == 1 then
                            local lockStatus = GetVehicleDoorLockStatus(closestVehicle)
                            if lockStatus == 1 then
                                SetVehicleDoorOpen(closestVehicle, 4, false, false)
                            else
                                ShowNotification(Translation[Config.Locale]['vehicle_locked'])
                            end

                        elseif index == 2 then
                            SetVehicleDoorShut(closestVehicle, 4, false)
                        end

                    elseif item == trunk then
                        if index == 1 then
                            local lockStatus = GetVehicleDoorLockStatus(closestVehicle)
                            if lockStatus == 1 then
                                SetVehicleDoorOpen(closestVehicle, 5, false, false)
                            else
                                ShowNotification(Translation[Config.Locale]['vehicle_locked'])
                            end

                        elseif index == 2 then
                            SetVehicleDoorShut(closestVehicle, 5, false)
                        end
                    end
                end
            else
                local locked_vehicle = NativeUI.CreateItem(Translation[Config.Locale]['vehicleinteraction_locked'], '')
                locked_vehicle:SetRightBadge(21)
                mainMenu:AddItem(locked_vehicle)
            end

        end

    end

    if Config.MenuContent.clothing then
        local clothings = _menuPool:AddSubMenu(mainMenu, Translation[Config.Locale]['clothing'], '', true, true)
        clothings.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

        -- clothings

        local clothing_options = {Translation[Config.Locale]['on'], Translation[Config.Locale]['off']}

        local clothing_hat = NativeUI.CreateListItem(Translation[Config.Locale]['hat'], clothing_options, helmet, '')
        clothings.SubMenu:AddItem(clothing_hat)

        local clothing_mask = NativeUI.CreateListItem(Translation[Config.Locale]['mask'], clothing_options, mask, '')
        clothings.SubMenu:AddItem(clothing_mask)

        local clothing_glasses = NativeUI.CreateListItem(Translation[Config.Locale]['glasses'], clothing_options, glasses, '')
        clothings.SubMenu:AddItem(clothing_glasses)

        local clothing_ears = NativeUI.CreateListItem(Translation[Config.Locale]['ears'], clothing_options, ears, '')
        clothings.SubMenu:AddItem(clothing_ears)

        local clothing_chain = NativeUI.CreateListItem(Translation[Config.Locale]['chain'], clothing_options, chain, '')
        clothings.SubMenu:AddItem(clothing_chain)

        local clothing_bag = NativeUI.CreateListItem(Translation[Config.Locale]['bag'], clothing_options, bag, '')
        clothings.SubMenu:AddItem(clothing_bag)

        local clothing_torso = NativeUI.CreateListItem(Translation[Config.Locale]['torso'], clothing_options, torso, '')
        clothings.SubMenu:AddItem(clothing_torso)

        local clothing_tshirt = NativeUI.CreateListItem(Translation[Config.Locale]['tshirt'], clothing_options, tshirt, '')
        clothings.SubMenu:AddItem(clothing_tshirt)

        local clothing_pants = NativeUI.CreateListItem(Translation[Config.Locale]['pants'], clothing_options, pants, '')
        clothings.SubMenu:AddItem(clothing_pants)

        local clothing_shoes = NativeUI.CreateListItem(Translation[Config.Locale]['shoes'], clothing_options, shoes, '')
        clothings.SubMenu:AddItem(clothing_shoes)

        clothing_shoes.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'shoes_1', skin['shoes_1'])
                TriggerEvent('skinchanger:change', 'shoes_2', skin['shoes_2'])
                shoes = 1
            elseif index == 2 then
                if skin.sex == 0 then
                    TriggerEvent('skinchanger:change', 'shoes_1', 34)
                    TriggerEvent('skinchanger:change', 'shoes_2', 0)
                else
                    TriggerEvent('skinchanger:change', 'shoes_1', 35)
                    TriggerEvent('skinchanger:change', 'shoes_2', 0)
                end
                shoes = 2
            end

        end

        clothing_pants.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'pants_1', skin['pants_1'])
                TriggerEvent('skinchanger:change', 'pants_2', skin['pants_2'])
                pants = 1
            elseif index == 2 then
                if skin.sex == 0 then
                    TriggerEvent('skinchanger:change', 'pants_1', 61)
                    TriggerEvent('skinchanger:change', 'pants_2', 1)
                else
                    TriggerEvent('skinchanger:change', 'pants_1', 15)
                    TriggerEvent('skinchanger:change', 'pants_2', 0)
                end
                pants = 2
            end

        end

        clothing_bag.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'bags_1', skin['bags_1'])
                TriggerEvent('skinchanger:change', 'bags_2', skin['bags_2'])
                bag = 1
            elseif index == 2 then
                TriggerEvent('skinchanger:change', 'bags_1', -1)
                TriggerEvent('skinchanger:change', 'bags_2', 0)
                bag = 2
            end

        end

        clothing_tshirt.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'tshirt_1', skin['tshirt_1'])
                TriggerEvent('skinchanger:change', 'tshirt_2', skin['tshirt_2'])
                tshirt = 1
            elseif index == 2 then
                TriggerEvent('skinchanger:change', 'tshirt_1', -1)
                TriggerEvent('skinchanger:change', 'tshirt_2', 0)
                tshirt = 2
            end

        end

        clothing_torso.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'torso_1', skin['torso_1'])
                TriggerEvent('skinchanger:change', 'torso_2', skin['torso_2'])
                torso = 1
            elseif index == 2 then
                TriggerEvent('skinchanger:change', 'torso_1', -1)
                TriggerEvent('skinchanger:change', 'torso_2', 0)
                TriggerEvent('skinchanger:change', 'arms', 15)
                torso = 2
            end

        end

        clothing_chain.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'chain_1', skin['chain_1'])
                TriggerEvent('skinchanger:change', 'chain_2', skin['chain_2'])
                chain = 1
            elseif index == 2 then
                TriggerEvent('skinchanger:change', 'chain_1', -1)
                TriggerEvent('skinchanger:change', 'chain_2', 0)
                chain = 2
            end

        end

        clothing_ears.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'ears_1', skin['ears_1'])
                TriggerEvent('skinchanger:change', 'ears_2', skin['ears_2'])
                ears = 1
            elseif index == 2 then
                TriggerEvent('skinchanger:change', 'ears_1', -1)
                TriggerEvent('skinchanger:change', 'ears_2', 0)
                ears = 2
            end

        end


        clothing_glasses.OnListChanged = function(sender, item, index)
            if index == 1 then
                TriggerEvent('skinchanger:change', 'glasses_1', skin['glasses_1'])
                TriggerEvent('skinchanger:change', 'glasses_2', skin['glasses_2'])
                glasses = 1
            elseif index == 2 then
                TriggerEvent('skinchanger:change', 'glasses_1', -1)
                TriggerEvent('skinchanger:change', 'glasses_2', 0)
                glasses = 2
            end

        end

        clothing_mask.OnListChanged = function(sender, item, index)
            -- ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                if index == 1 then
                    TriggerEvent('skinchanger:change', 'mask_1', skin['mask_1'])
                    TriggerEvent('skinchanger:change', 'mask_2', skin['mask_2'])
                    mask = 1
                elseif index == 2 then
                    TriggerEvent('skinchanger:change', 'mask_1', -1)
                    TriggerEvent('skinchanger:change', 'mask_2', 0)
                    mask = 2
                end
            -- end)

        end

        clothing_hat.OnListChanged = function(sender, item, index)
            -- ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                if item == clothing_hat then
                    if index == 1 then
                        TriggerEvent('skinchanger:change', 'helmet_1', skin['helmet_1'])
                        TriggerEvent('skinchanger:change', 'helmet_2', skin['helmet_2'])
                        helmet = 1
                    elseif index == 2 then
                        TriggerEvent('skinchanger:change', 'helmet_1', -1)
                        TriggerEvent('skinchanger:change', 'helmet_2', 0)
                        helmet = 2
                    end
                end

            -- end)

        end

        -- clothings
    end

    if Config.MenuContent.inventory then
        local inventory = NativeUI.CreateItem(Translation[Config.Locale]['inventory'], '')
        mainMenu:AddItem(inventory)

        inventory.Activated = function()
            if Config.Inventory.playermenuV2 then
                TriggerEvent('primePlayermenuV2:openInventory')
            elseif Config.Inventory.ox_inventory then
                exports.ox_inventory:openInventory('player', GetPlayerServerId(PlayerId()))
            end
        end

    end

    if Config.MenuContent.billing then
        local bills = _menuPool:AddSubMenu(mainMenu, Translation[Config.Locale]['bills'], '', true, true)
        bills.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)


        if Config.Billing.default then
            ESX.TriggerServerCallback('esx_billing:getBills', function(result)
                for k, v in pairs(result) do

                    local bill = NativeUI.CreateItem(v.label, '')
                    bill:RightLabel(reformatInt(v.amount) .. ' ' .. Config.Currency)
                    bills.SubMenu:AddItem(bill)

                    bill.Activated = function()
                        ESX.TriggerServerCallback('esx_billing:payBill', function(resp)
                            _menuPool:CloseAllMenus()
                        end, v.id)

                    end

                end
            
            end)

        elseif Config.Billing.myBilling then

            ESX.TriggerServerCallback('esx_billing:getBills', function(result)
                for k, v in pairs(result) do
                    local charName
                    local label
                    if v.targetType == 'player' then
                        label = v.label .. ' (~y~Privat~s~)'
                    else
                        local targetlabel = v.target:gsub("society_", "")
                        local targetlabelStr = targetlabel:gsub("^%l", string.upper)
                        label = v.label .. ' (~y~' .. targetlabelStr .. '~s~)'
                    end

                    local bill = NativeUI.CreateItem(label, '')
                    bill:RightLabel(reformatInt(v.amount) .. ' ' .. Config.Currency)
                    bills.SubMenu:AddItem(bill)

                    bill.Activated = function()
                        TriggerServerEvent('myBills:payBill', 'billing', v.id, v.targetType, v.target, v.amount, v.sender)
                        _menuPool:CloseAllMenus()
                    end

                end
            
            end)
            
        end

    end

    if Config.MenuContent.animation then
        local animations = NativeUI.CreateItem(Translation[Config.Locale]['animations_title'], '')
        mainMenu:AddItem(animations)

        animations.Activated = function()
            TriggerEvent('primePlayermenuV2:openAnimationMenu')
        end
    end
    

    if Config.MenuContent.waypoint then
        local waypointsList = {
            Translation[Config.Locale]['closestatm'],
            Translation[Config.Locale]['closestgasstation'],
        }

        for k, v in pairs(Config.Waypoints) do
            table.insert(waypointsList, v.label)
        end

        local waypoint = NativeUI.CreateListItem(Translation[Config.Locale]['waypoint'], waypointsList, 1, '')
        mainMenu:AddItem(waypoint)

        -- waypoint

        mainMenu.OnListSelect = function(sender, item, index)
            if item == waypoint then
                if index == 1 then
                    SetClosestATMWaypoint()
                elseif index == 2 then
                    SetClosestGasstationWaypoint()
                else
                    if Config.Waypoints[index - 2].x ~= nil then
                        local posx = Config.Waypoints[index - 2].x
                        local posy = Config.Waypoints[index - 2].y
                        local waypointlabel = Config.Waypoints[index - 2].label
                        SetNewWaypoint(posx, posy)
                        ShowNotification(Translation[Config.Locale]['new_waypoint1'] .. waypointlabel .. Translation[Config.Locale]['new_waypoint2'])
                    else
                        SetWaypointOff()
                        ShowNotification(Translation[Config.Locale]['waypoint_removed'])
                    end
                end

            end

        end

    end


    -- waypoint

    if Config.MenuContent.gps then
        gps = NativeUI.CreateItem(Translation[Config.Locale]['gps'], '')
        if gpsCode == nil then
            gps:RightLabel('-')
        else
            gps:RightLabel(gpsCode)
        end
        mainMenu:AddItem(gps)

        gps.Activated = function()

            local hasItem
            if Config.GPSItem ~= nil then
                ESX.TriggerServerCallback('primePlayermenuV2:checkItemCount', function(count)
                    if count > 0 then
                        hasItem = true
                    else
                        hasItem = false
                    end

                end, Config.GPSItem)
            else
                hasItem = true
            end

            while hasItem == nil do
                Wait(0)
            end

            if hasItem then

                local codeNum = lib.inputDialog(Translation[Config.Locale]['gps_code'], {
                    {type = 'number', label = Translation[Config.Locale]['gps_code_input'], required = false, icon = 'hashtag', precision = 2, default = gpsCode, max = 1000},
                    {type = 'checkbox', label = Translation[Config.Locale]['gps_off']}
                })

                if not codeNum then return end

                if codeNum[2] then
                    TriggerServerEvent('primePlayermenuV2:DeactivateGPS', gpsCode)
                    gpsCode = nil
                    ShowNotification(Translation[Config.Locale]['gps_off_notify'])
                    refreshGPS()
                    gps:RightLabel('-')
                    PlaySound(l_208, "CANCEL", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
                else
                    if codeNum[1] ~= nil then
                        -- gpsCode = codeNum[1]
                        TriggerServerEvent('primePlayermenuV2:joinGPSChannel', codeNum[1])
                        -- refreshGPS()
                        -- ShowNotification('Du hast den GPS Kanal ~g~' .. codeNum[1] .. ' ~s~betreten!')
                        -- gps:RightLabel(codeNum[1])
                        PlaySound(l_208, "SELECT", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
                    end
                end

            else
                ShowNotification(Translation[Config.Locale]['no_gps_item'])
            end

        end

    end


    if Config.MenuContent.information then
        local infos = _menuPool:AddSubMenu(mainMenu, Translation[Config.Locale]['informations'], '', true, true)
        infos.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

        -- infos submenu

        local fullname_info = NativeUI.CreateItem(Translation[Config.Locale]['charname'], '')
        fullname_info:RightLabel(fullname)
        infos.SubMenu:AddItem(fullname_info)

        local birthdate_info = NativeUI.CreateItem(Translation[Config.Locale]['birthdate'], '')
        birthdate_info:RightLabel(birthdate)
        infos.SubMenu:AddItem(birthdate_info)

        local job_info = NativeUI.CreateItem(Translation[Config.Locale]['job'], '')
        job_info:RightLabel(joblabel .. ' - ' .. jobgradelabel .. ' (Rang ' .. jobgrade .. ')')
        infos.SubMenu:AddItem(job_info)

        local salary_info = NativeUI.CreateItem(Translation[Config.Locale]['salary'], '')
        salary_info:RightLabel('~g~' .. reformatInt(salary) .. ' ' .. Config.Currency)
        infos.SubMenu:AddItem(salary_info)
        
        local playtime_info = NativeUI.CreateItem(Translation[Config.Locale]['playtime'], '')
        playtime_info:RightLabel(math.round(playtime / 3600) .. 'h')
        infos.SubMenu:AddItem(playtime_info)

        local playerid_info = NativeUI.CreateItem('ID:', '')
        playerid_info:RightLabel(GetPlayerServerId(PlayerId()))
        infos.SubMenu:AddItem(playerid_info)

        -- infos submenu

    end
    

    _menuPool:RefreshIndex()
    mainMenu:Visible(true)
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)

end)

RegisterNetEvent('primePlayermenuV2:joinGPSChannel', function(code)

    gpsCode = code
    ShowNotification(Translation[Config.Locale]['channel_joined1'] .. code .. Translation[Config.Locale]['channel_joined2'])
    gps:RightLabel(gpsCode)
    refreshGPS()

end)

RegisterNetEvent('primePlayermenuV2:RefreshGPS', function()

    -- ShowNotification('Jemand hat deinen GPS Kanal verlassen')
    refreshGPS()

end)

RegisterNetEvent('primePlayermenuV2:openAnimationMenu', function()

    _menuPool:CloseAllMenus()
    collectgarbage()
    triggerOnClose = true

    local AnimationMenu = NativeUI.CreateMenu(Translation[Config.Locale]['animations_title'], Translation[Config.Locale]['animations_subtitle'], Config.MenuPosition.X, Config.MenuPosition.Y)
    AnimationMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
    _menuPool:Add(AnimationMenu)

    AnimationMenu.OnMenuClosed = function(menu, newmenu)
        if triggerOnClose then
            TriggerEvent('primePlayermenuV2:openPlayermenu')
        end
    end

    local addAnimation = NativeUI.CreateItem(Translation[Config.Locale]['save_anim'], '')
    addAnimation:RightLabel('~g~→')
    AnimationMenu:AddItem(addAnimation)
    
    local manageAnimations = _menuPool:AddSubMenu(AnimationMenu, Translation[Config.Locale]['manage_anims'], '', true, true)
    manageAnimations.Item:RightLabel('→→→')
    manageAnimations.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)

    addAnimation.Activated = function()

        local animationName = lib.inputDialog(Translation[Config.Locale]['save_anim_input'], {
            {type = 'input', label = Translation[Config.Locale]['animlabel_input'], description = Translation[Config.Locale]['animlabel_input_desc'], required = true},
            {type = 'input', label = Translation[Config.Locale]['anim_input'], required = true, placeholder = 'dance3'}
        })

        if not animationName then return end

        TriggerServerEvent('primePlayermenuV2:SaveAnimation', animationName[1], animationName[2])
        triggerOnClose = false
        TriggerEvent('primePlayermenuV2:openAnimationMenu')

    end

    ESX.TriggerServerCallback('primePlayermenuV2:getSavedAnimations', function(result)

        for k, v in pairs(result) do

            local manage_savedAnim = _menuPool:AddSubMenu(manageAnimations.SubMenu, v.label, '', true, true)
            manage_savedAnim.Item:SetLeftBadge(18)
            manage_savedAnim.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
            
            local renameAnim = NativeUI.CreateItem(Translation[Config.Locale]['rename_anim'], '')
            renameAnim:RightLabel('"~b~' .. v.label .. '~s~"')
            manage_savedAnim.SubMenu:AddItem(renameAnim)

            local deleteAnim = NativeUI.CreateItem(Translation[Config.Locale]['delete_anim'], '')
            manage_savedAnim.SubMenu:AddItem(deleteAnim)

            deleteAnim.Activated = function()
                TriggerServerEvent('primePlayermenuV2:DeleteSavedAnim', v.id)
                triggerOnClose = false
                TriggerEvent('primePlayermenuV2:openAnimationMenu')
            end

            renameAnim.Activated = function()
                
                local newAnimName = lib.inputDialog(Translation[Config.Locale]['rename_anim'], {
                    {type = 'input', label = Translation[Config.Locale]['new_animlabel'], required = false, min = 1}
                })

                if not newAnimName then return end

                renameAnim:RightLabel('"~b~' .. newAnimName[1] .. '~s~"')
                TriggerServerEvent('primePlayermenuV2:RenameSavedAnim', v.id, newAnimName[1])

            end

        end

        for k, v in pairs(result) do

            local savedAnim = NativeUI.CreateItem(v.label, Translation[Config.Locale]['anim_desc'] .. v.anim)
            savedAnim:SetLeftBadge(18)
            AnimationMenu:AddItem(savedAnim)
            _menuPool:RefreshIndex()

            savedAnim.Activated = function()
                ExecuteCommand('e ' .. v.anim)
            end

        end
        -- _menuPool:RefreshIndex()
        AnimationMenu:Visible(true)
        _menuPool:MouseControlsEnabled(false)
        _menuPool:MouseEdgeEnabled(false)
        _menuPool:ControlDisablingEnabled(false)
    end)

    _menuPool:RefreshIndex()
    AnimationMenu:Visible(true)
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)

end)

Citizen.CreateThread(function()
    while true do

        if gpsCode ~= nil then
            refreshGPS()
        end

        Wait(Config.RefreshRate)
    end
end)

function refreshGPS()

    ESX.TriggerServerCallback('primePlayermenuV2:getMyGPSData', function(mygps, itemCount)

        if Config.GPSItem ~= nil then
            if itemCount == 0 then
                TriggerServerEvent('primePlayermenuV2:DeactivateGPS', gpsCode)
                gpsCode = nil
                ShowNotification(Translation[Config.Locale]['gps_off_notify'])
                refreshGPS()
                PlaySound(l_208, "CANCEL", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)

                if #blips > 0 then
                    for k, v in pairs(blips) do
                        RemoveBlip(v)
                    end
                end

                return
            end
        end

        if #blips > 0 then
            for k, v in pairs(blips) do
                RemoveBlip(v)
            end
        end

        for k, v in pairs(mygps) do

            v.blip = AddBlipForCoord(v.coords.x, v.coords.y)
            SetBlipSprite(v.blip, Config.GPSBlip.id)
            SetBlipDisplay(v.blip, 4)
            SetBlipScale  (v.blip, Config.GPSBlip.size)
            SetBlipColour (v.blip, Config.GPSBlip.color)
            SetBlipAsShortRange(v.blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.name)
            EndTextCommandSetBlipName(v.blip)
            table.insert(blips, v.blip)

        end
    
    end, gpsCode)


end

RegisterNetEvent('primePlayermenuV2:openInventory', function()

    local weight
    local maxWeight
    ESX.TriggerServerCallback('primePlayermenuV2:getWeight', function(getweight, getmaxWeight)
        weight = getweight
        maxWeight = getmaxWeight
    end)

    _menuPool:CloseAllMenus()
    collectgarbage()

    while weight == nil and maxWeight == nil do
        Wait(0)
    end

    local InventoryMenu = NativeUI.CreateMenu(Translation[Config.Locale]['inventory_title'], Translation[Config.Locale]['weight'] .. weight .. '/' .. maxWeight .. 'kg', Config.MenuPosition.X, Config.MenuPosition.Y)
    InventoryMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
    _menuPool:Add(InventoryMenu)

    InventoryMenu.OnMenuClosed = function()
        TriggerEvent('primePlayermenuV2:openPlayermenu')
    end

    ESX.TriggerServerCallback('primePlayermenuV2:getMyInventory', function(inventory, loadout)
        for k, v in pairs(inventory) do
            if v.count > 0 then
                local item = _menuPool:AddSubMenu(InventoryMenu, v.count .. 'x ' .. v.label, '', true, true)
                item.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
                item.Item:RightLabel(v.count * v.weight .. 'kg')

                local useItem = NativeUI.CreateItem(Translation[Config.Locale]['use'], '')
                item.SubMenu:AddItem(useItem)

                local giveItem = NativeUI.CreateItem(Translation[Config.Locale]['give'], '')
                item.SubMenu:AddItem(giveItem)

                local dropItem = NativeUI.CreateItem(Translation[Config.Locale]['drop'], '')
                item.SubMenu:AddItem(dropItem)

                dropItem.Activated = function()

                    local dropAmount = lib.inputDialog(Translation[Config.Locale]['drop'], {
                        {type = 'number', label = Translation[Config.Locale]['amount'], required = false, min = 1, max = v.count}
                    })

                    if not dropAmount then return end

                    TriggerServerEvent('esx:removeInventoryItem', 'item_standard', v.name, dropAmount[1])
                    -- Wait(100)
                    TriggerEvent('primePlayermenuV2:openInventory')
                end

                giveItem.Activated = function()
                    local playersInArea = ESX.Game.GetPlayersInArea(playerCoords, 3.0)
                    if #playersInArea > 0 then
                        TriggerEvent('primePlayermenuV2:giveItem', v.name, v.label, v.count, 'item')
                    else
                        ShowNotification(Translation[Config.Locale]['noplayers_nearby'])
                    end
                end

                useItem.Activated = function()
                    if v.count > 0 then
                        TriggerServerEvent('esx:useItem', v.name)
                    else
                        ShowNotification(Translation[Config.Locale]['use_error'] .. v.label)
                    end
                end

                _menuPool:RefreshIndex()
            end

        end

        for k, v in pairs(loadout) do

            local weapon = _menuPool:AddSubMenu(InventoryMenu, v.label, '', true, true)
            weapon.SubMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
            weapon.Item:RightLabel(v.ammo .. Translation[Config.Locale]['ammo'])

            local giveWeapon = NativeUI.CreateItem(Translation[Config.Locale]['give'], '')
            weapon.SubMenu:AddItem(giveWeapon)

            local dropWeapon = NativeUI.CreateItem(Translation[Config.Locale]['drop'], '')
            weapon.SubMenu:AddItem(dropWeapon)

            dropWeapon.Activated = function()
                TriggerServerEvent('esx:removeInventoryItem', 'item_weapon', v.name)
                TriggerEvent('primePlayermenuV2:openInventory')
            end

            giveWeapon.Activated = function()
                local playersInArea = ESX.Game.GetPlayersInArea(playerCoords, 3.0)
                if #playersInArea > 0 then
                    TriggerEvent('primePlayermenuV2:giveItem', v.name, v.label, v.ammo, 'weapon')
                else
                    ShowNotification(Translation[Config.Locale]['noplayers_nearby'])
                end
            end

        end
    
        _menuPool:RefreshIndex()
        InventoryMenu:Visible(true)
        _menuPool:MouseControlsEnabled(false)
        _menuPool:MouseEdgeEnabled(false)
        _menuPool:ControlDisablingEnabled(false)
    end)


    InventoryMenu:RefreshIndex()
    InventoryMenu:Visible(true)
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)

end)

RegisterNetEvent('primePlayermenuV2:giveItem', function(item, label, count, itemType)

    _menuPool:CloseAllMenus()
    collectgarbage()

    local playerCoords = GetEntityCoords(PlayerPedId())

    local playersInArea = ESX.Game.GetPlayersInArea(playerCoords, 3.0)
    local selectedIndex = 1

    local GiveItemMenu = NativeUI.CreateMenu(Translation[Config.Locale]['give'], Translation[Config.Locale]['select_player'], Config.MenuPosition.X, Config.MenuPosition.Y)
    GiveItemMenu:SetMenuWidthOffset(Config.MenuWidthOffset)
    _menuPool:Add(GiveItemMenu)

    GiveItemMenu.OnMenuClosed = function()
        TriggerEvent('primePlayermenuV2:openInventory')
        selectedPlayerCoords = nil
    end

    for k, v in pairs(playersInArea) do

        local selectedPlayerCoords = GetEntityCoords(GetPlayerPed(playersInArea[selectedIndex]))
        local distance = GetDistanceBetweenCoords(selectedPlayerCoords.x, selectedPlayerCoords.y, selectedPlayerCoords.z, playerCoords, true)

        local player = NativeUI.CreateItem(Translation[Config.Locale]['player_nearby'] .. math.round(distance) .. 'm)', '')
        GiveItemMenu:AddItem(player)

        player.Activated = function()
            
            if itemType == 'item' then
                local giveAmount = lib.inputDialog(label, {
                    {type = 'number', label = Translation[Config.Locale]['amount'], required = false, min = 1, max = count}
                })

                if not giveAmount then return end

                TriggerServerEvent('primePlayermenuV2:giveItemRequest', GetPlayerServerId(playersInArea[selectedIndex]), item, label, giveAmount[1], itemType)
                ShowNotification('Du hast eine Anfrage ~g~gesendet!') 
                _menuPool:CloseAllMenus()
            
            else
                TriggerServerEvent('primePlayermenuV2:giveItemRequest', GetPlayerServerId(playersInArea[selectedIndex]), item, label, count, itemType)
                -- ShowNotification('Du hast eine Anfrage ~g~gesendet!')
                _menuPool:CloseAllMenus()
            end

        end

        Citizen.CreateThread(function()
            while true do
    
                if selectedPlayerCoords ~= nil then
                    selectedPlayerCoords = GetEntityCoords(GetPlayerPed(playersInArea[selectedIndex]))
                    DrawMarker(Config.DrawMarker.type, selectedPlayerCoords.x, selectedPlayerCoords.y, selectedPlayerCoords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, Config.DrawMarker.size, Config.DrawMarker.size, Config.DrawMarker.size, Config.DrawMarker.r, Config.DrawMarker.g, Config.DrawMarker.b, Config.DrawMarker.opacity, false, true, 2, nil, nil, false)
                end
    
                if not _menuPool:IsAnyMenuOpen() then
                    break
                end
    
                Wait(1)
            end
        end)

    end


    GiveItemMenu.OnIndexChange = function(sender, index)
        selectedIndex = index
    end

    _menuPool:RefreshIndex()
    GiveItemMenu:Visible(true)
    _menuPool:MouseControlsEnabled(false)
    _menuPool:MouseEdgeEnabled(false)
    _menuPool:ControlDisablingEnabled(false)
end)

RegisterNetEvent('primePlayermenuV2:useHeadbagClient', function(sender)

    if not headbag then
        if Config.HeadbagItem ~= nil then
            ESX.TriggerServerCallback('primePlayermenuV2:checkSenderItemCount', function(count)
                if count > 0 then
                    TriggerServerEvent('primePlayermenuV2:useHeadbagItem', sender)
                    ShowNotification(Translation[Config.Locale]['headbag_target'])
                    Wait(1000)
                    headbag = true
                    TriggerEvent('skinchanger:change', 'mask_1', 49)
                    TriggerEvent('skinchanger:change', 'mask_2', 0)
            
                    SendNUIMessage({
                        type = 'openGeneral'
                    })
                else
                    ShowNotification(Translation[Config.Locale]['need_headbag'])
                end
            
            end, sender)

        else
            ShowNotification(Translation[Config.Locale]['headbag_target'])
            Wait(1000)
            headbag = true
            TriggerEvent('skinchanger:change', 'mask_1', 49)
            TriggerEvent('skinchanger:change', 'mask_2', 0)
    
            SendNUIMessage({
                type = 'openGeneral'
            })

        end
        
    else

        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(playerSkin)
        
            ShowNotification(Translation[Config.Locale]['headbag_removed'])
            headbag = false
            SendNUIMessage({
                type = "closeAll"
            })
    
            TriggerEvent('skinchanger:change', 'mask_1', playerSkin['mask_1'])
            TriggerEvent('skinchanger:change', 'mask_2', playerSkin['mask_2'])
        
        end)

    end

end)

RegisterNetEvent('primePlayermenuV2:takeOffMaskClient', function(target)

    mask = 2
    ShowNotification(Translation[Config.Locale]['takeoffmask_target'])
    TriggerEvent('skinchanger:change', 'mask_1', -1)
    TriggerEvent('skinchanger:change', 'mask_2', 0)

end)

RegisterNetEvent('primePlayermenuV2:giveItemRequest', function(item, label, count, sender, itemType)

    ShowNotification(Translation[Config.Locale]['give_request1'] .. count .. 'x ' .. label .. Translation[Config.Locale]['give_request2'])
    local isExpired = false

    Citizen.CreateThread(function()
        while true do

            if IsControlJustReleased(0, 246) then
                if itemType == 'item' then
                    ShowNotification(Translation[Config.Locale]['item_accepted1'] .. count .. 'x ' .. label .. Translation[Config.Locale]['item_accepted2'])
                else
                    ShowNotification(Translation[Config.Locale]['weapon_accepted1'] .. label .. Translation[Config.Locale]['weapon_accepted2'])
                end
                TriggerServerEvent('primePlayermenuV2:ItemAccepted', item, label, count, sender, itemType)
                break
            end

            if IsControlJustReleased(0, 73) then
                ShowNotification(Translation[Config.Locale]['decline_item'])
                TriggerServerEvent('primePlayermenuV2:DeclineItem', sender)
                break
            end

            if isExpired then
                -- ShowNotification('Das Angebot ist ~r~abgelaufen!')
                break
            end
            
            Wait(1)
        end
    end)

    Wait(15000)
    isExpired = true

end)

local atmModels = {
    {x = -1840.0875, y = -362.4951, z = 49.3868},
    {x = -1061.9327, y = -2835.0305, z = 27.7036},
    {x = -1053.8938, y = -2842.1338, z = 27.7087},
    {x = -1817.8, y = -1190.7, z = 14.3},
    {x = -386.733, y = 6045.953, z = 31.501},
    {x = -284.037, y = 6224.385, z = 31.187},
    {x = -284.037, y = 6224.385, z = 31.187},
    {x = -135.165, y = 6365.738, z = 31.101},
    {x = -110.753, y = 6467.703, z = 31.784},
    {x = -94.9690, y = 6455.301, z = 31.784},
    {x = 155.4300, y = 6641.991, z = 31.784},
    {x = 174.6720, y = 6637.218, z = 31.784},
    {x = 1703.138, y = 6426.783, z = 32.730},
    {x = 1735.114, y = 6411.035, z = 35.164},
    {x = 1702.842, y = 4933.593, z = 42.051},
    {x = 1967.333, y = 3744.293, z = 32.272},
    {x = 1821.917, y = 3683.483, z = 34.244},
    {x = 1174.532, y = 2705.278, z = 38.027},
    {x = 540.0420, y = 2671.007, z = 42.177},
    {x = 2564.399, y = 2585.100, z = 38.016},
    {x = 2558.683, y = 349.6010, z = 108.050},
    {x = 2558.051, y = 389.4817, z = 108.660},
    {x = 1077.692, y = -775.796, z = 58.218},
    {x = 1139.018, y = -469.886, z = 66.789},
    {x = 1168.975, y = -457.241, z = 66.641},
    {x = 1153.884, y = -326.540, z = 69.245},
    {x = 381.2827, y = 323.2518, z = 103.270},
    {x = 236.4638, y = 217.4718, z = 106.840},
    {x = 265.0043, y = 212.1717, z = 106.780},
    {x = 285.2029, y = 143.5690, z = 104.970},
    {x = 157.7698, y = 233.5450, z = 106.450},
    {x = -164.568, y = 233.5066, z = 94.919},
    {x = -1827.04, y = 785.5159, z = 138.020},
    {x = -1409.39, y = -99.2603, z = 52.473},
    {x = -1205.35, y = -325.579, z = 37.870},
    {x = -1215.64, y = -332.231, z = 37.881},
    {x = -2072.41, y = -316.959, z = 13.345},
    {x = -2975.72, y = 379.7737, z = 14.992},
    {x = -2962.60, y = 482.1914, z = 15.762},
    {x = -2955.70, y = 488.7218, z = 15.486},
    {x = -3044.22, y = 595.2429, z = 7.595},
    {x = -3144.13, y = 1127.415, z = 20.868},
    {x = -3241.10, y = 996.6881, z = 12.500},
    {x = -3241.11, y = 1009.152, z = 12.877},
    {x = -1305.40, y = -706.240, z = 25.352},
    {x = -538.225, y = -854.423, z = 29.234},
    {x = -711.156, y = -818.958, z = 23.768},
    {x = -717.614, y = -915.880, z = 19.268},
    {x = -526.566, y = -1222.90, z = 18.434},
    {x = -256.831, y = -719.646, z = 33.444},
    {x = -203.548, y = -861.588, z = 30.205},
    {x = 112.4102, y = -776.162, z = 31.427},
    {x = 112.9290, y = -818.710, z = 31.386},
    {x = 119.9000, y = -883.826, z = 31.191},
    {x = 149.4551, y = -1038.95, z = 29.366},
    {x = -846.304, y = -340.402, z = 38.687},
    {x = -1204.35, y = -324.391, z = 37.877},
    {x = -1216.27, y = -331.461, z = 37.773},
    {x = -56.1935, y = -1752.53, z = 29.452},
    {x = -261.692, y = -2012.64, z = 30.121},
    {x = -273.001, y = -2025.60, z = 30.197},
    {x = 314.187, y = -278.621, z = 54.170},
    {x = -351.534, y = -49.529, z = 49.042},
    {x = 24.589, y = -946.056, z = 29.357},
    {x = -254.112, y = -692.483, z = 33.616},
    {x = -1570.197, y = -546.651, z = 34.955},
    {x = -1415.909, y = -211.825, z = 46.500},
    {x = -1430.112, y = -211.014, z = 46.500},
    {x = 33.232, y = -1347.849, z = 29.497},
    {x = 129.216, y = -1292.347, z = 29.269},
    {x = 287.645, y = -1282.646, z = 29.659},
    {x = 289.012, y = -1256.545, z = 29.440},
    {x = 295.839, y = -895.640, z = 29.217},
    {x = 1686.753, y = 4815.809, z = 42.008},
    {x = -302.408, y = -829.945, z = 32.417},
    {x = 5.134, y = -919.949, z = 29.557},
    {x = 2682.6714, y = 3286.6953, z = 55.2411}
}

local fuelLocations = {
    {x = 49.4187, y = 2778.793, z = 58.043},
	{x = 263.894, y = 2606.463, z = 44.983},
	{x = 1039.958, y = 2671.134, z = 39.550},
	{x = 1207.260, y = 2660.175, z = 37.899},
	{x = 2539.685, y = 2594.192, z = 37.944},
	{x = 2679.858, y = 3263.946, z = 55.240},
	{x = 2005.055, y = 3773.887, z = 32.403},
	{x = 1687.156, y = 4929.392, z = 42.078},
	{x = 1701.314, y = 6416.028, z = 32.763},
	{x = 179.857, y = 6602.839, z = 31.868},
	{x = -94.4619, y = 6419.594, z = 31.489},
	{x = -2554.996, y = 2334.40, z = 33.078},
	{x = -1800.375, y = 803.661, z = 138.651},
	{x = -1437.622, y = -276.747, z = 46.207},
	{x = -2096.243, y = -320.286, z = 13.168},
	{x = -724.619, y = -935.1631, z = 19.213},
	{x = -526.019, y = -1211.003, z = 18.184},
	{x = -70.2148, y = -1761.792, z = 29.534},
	{x = 265.648, y = -1261.309, z = 29.292},
	{x = 819.653, y = -1028.846, z = 26.403},
	{x = 1208.951, y = -1402.567, z = 35.224},
	{x = 1181.381, y = -330.847, z = 69.316},
	{x = 620.843, y = 269.100, z = 103.089},
	{x = 2581.321, y = 362.039, z = 108.468},
	{x = 176.631, y = -1562.025, z = 29.263},
	{x = 176.631, y = -1562.025, z = 29.263},
	{x = -319.292, y = -1471.715, z = 30.549},
	{x = 1784.324, y = 3330.55, z = 41.253}
}

function SetClosestGasstationWaypoint()

    local closestStation = GetClosestGasstation()

    if closestStation then
        SetNewWaypoint(closestStation.x, closestStation.y)
        ShowNotification(Translation[Config.Locale]['gasstation_waypoint'])
    else
        ShowNotification(Translation[Config.Locale]['gasstation_error'])
    end

end

function GetClosestGasstation()

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local distanceTable = {}

    local closestStation = nil
    local closestDistance

    for k, v in pairs(fuelLocations) do
        local gasPos = v
        local gasDistance = GetDistanceBetweenCoords(gasPos.x, gasPos.y, gasPos.z, playerCoords, false)
        table.insert(distanceTable, {
            coords = gasPos,
            distance = math.floor(gasDistance)
        })
    end


    local closest = distanceTable[1].distance

    for k, v in pairs(distanceTable) do
        if v.distance < closest then
            closest = distanceTable[k].distance
            closestStation = v.coords
            closestDistance = v.distance
        end

    end

    return closestStation

end

function SetClosestATMWaypoint()

    local closestATM = GetClosestATMProp()

    if closestATM then
        SetNewWaypoint(closestATM.x, closestATM.y)
        ShowNotification(Translation[Config.Locale]['atm_waypoint'])
    else
        ShowNotification(Translation[Config.Locale]['atm_error'])
    end

end

function GetClosestATMProp()

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local distanceTable = {}

    local closestATM = nil
    local closestDistance

    for k, v in pairs(atmModels) do
        local atmPos = v
        local atmDistance = GetDistanceBetweenCoords(atmPos.x, atmPos.y, atmPos.z, playerCoords, false)
        table.insert(distanceTable, {
            coords = atmPos,
            distance = math.floor(atmDistance)
        })
    end


    local closest = distanceTable[1].distance

    for k, v in pairs(distanceTable) do
        if v.distance < closest then
            closest = distanceTable[k].distance
            closestATM = v.coords
            closestDistance = v.distance
        end

    end

    return closestATM

end

function GetClosestVehicleToPlayer()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local closestVehicle = nil
    local closestDistance = nil

    local vehicles = GetGamePool("CVehicle")

    for _, vehicle in ipairs(vehicles) do
        local vehiclePos = GetEntityCoords(vehicle)
        local distance = GetDistanceBetweenCoords(playerPos.x, playerPos.y, playerPos.z, vehiclePos.x, vehiclePos.y, vehiclePos.z)


        if closestDistance == nil or distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end

    return closestVehicle, closestDistance
end

function toggleAutopilot(checked)

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if checked then
        -- activate autopilot
        if DoesBlipExist(GetFirstBlipInfoId(8)) then
            autopilotActive = true
            ClearPedTasks(playerPed)
            local blip = GetFirstBlipInfoId(8)
            bCoords = GetBlipCoords(blip)
            TaskVehicleDriveToCoord(playerPed, vehicle, bCoords, Config.AutopilotDriveSpeed, 0, vehicle, Config.AutopilotDriveStyle, 0, true)
            SetDriveTaskDrivingStyle(playerPed, Config.AutopilotDriveStyle)
            ShowNotification(Translation[Config.Locale]['autopilot_activated'])
        else
            ShowNotification(Translation[Config.Locale]['no_waypoint'])
        end

        Citizen.CreateThread(function()
            while true do

                if autopilotActive then
                    local playerPed = PlayerPedId()
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = GetDistanceBetweenCoords(bCoords.x, bCoords.y, bCoords.z, playerCoords)
                    if distance <= 10.0 then
                        ShowNotification(Translation[Config.Locale]['waypoint_reached'])
                        ClearPedTasks(playerPed)
                        ClearVehicleTasks(vehicle)
                        autopilotActive = false
                        break
                    end
                else
                    break
                end

                Wait(1000)
            end
        end)

    else
        -- deactivate autopilot
        if autopilotActive then
            ClearPedTasks(playerPed)
            ClearVehicleTasks(vehicle)
            autopilotActive = false
            ShowNotification(Translation[Config.Locale]['autopilot_deactivated'])
        end
    end

end

function toggleCruiseControl(checked)

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local speed = GetEntitySpeed(vehicle)
    if checked then
        cruiseControlActive = true
        
        SetEntityMaxSpeed(vehicle, speed)
        ShowNotification(Translation[Config.Locale]['cruisecontrol_activated'] .. math.floor(speed * 3.6) .. Translation[Config.Locale]['cruisecontrol_activated2'])
    else
        cruiseControlActive = false
        SetEntityMaxSpeed(vehicle, speed * 1000)
        ShowNotification(Translation[Config.Locale]['cruisecontrol_deactivated'])
    end

end

RegisterCommand('playermenuV2_autopilot', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        if not autopilotActive then
            toggleAutopilot(true)
        else
            toggleAutopilot(false)
        end
    end
end)

RegisterCommand('playermenuv2_cruisecontrol', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        if not cruiseControlActive then
            toggleCruiseControl(true)
        else
            toggleCruiseControl(false)
        end
    end
end)

RegisterKeyMapping('playermenuV2_autopilot', 'Toggle Autopilot', 'keyboard', Config.AutopilotKey)
RegisterKeyMapping('playermenuv2_cruisecontrol', 'Toggle Cruise Control', 'keyboard', Config.CruiseControlKey)


RegisterNetEvent('primePlayermenuV2:TakePlayerFromVehicle', function()

    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        TaskLeaveVehicle(playerPed, vehicle, 64)
    end

end)

RegisterNetEvent('primePlayermenuV2:PutInVehicle', function()
    
    local playerPed = PlayerPedId()
    local closestVehicle, vehicleDistance = GetClosestVehicleToPlayer()

    local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(closestVehicle)

    for i=maxSeats - 1, 0, -1 do
        if IsVehicleSeatFree(closestVehicle, i) then
            freeSeat = i
            break
        end
    end

    if closestVehicle ~= nil and vehicleDistance < 3.0 then
        if freeSeat then
            TaskWarpPedIntoVehicle(playerPed, closestVehicle, freeSeat)
            ShowNotification(Translation[Config.Locale]['putInVehicle_targetnotify'])
        end
    end

end)

RegisterNetEvent('primePlayermenuV2:EscortPlayerClient', function(target, sender)

    local targetPed = GetPlayerPed(GetPlayerFromServerId(target))

    local senderPed = GetPlayerPed(GetPlayerFromServerId(sender))
    local senderCoords = GetEntityCoords(senderPed)
    local senderHeading = GetEntityHeading(senderPed)
    if not isEscorting then
        isEscorting = true
        AttachEntityToEntity(senderPed, GetPlayerPed(GetPlayerFromServerId(target)), 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    else
        isEscorting = false
        DetachEntity(senderPed, true, false)
    end

end)

RegisterNetEvent("primePlayermenuV2:syncTarget")
AddEventHandler("primePlayermenuV2:syncTarget", function(targetSrc)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	carry.InProgress = true
	ensureAnimDict(carry.personCarried.animDict)
	AttachEntityToEntity(PlayerPedId(), targetPed, 0, carry.personCarried.attachX, carry.personCarried.attachY, carry.personCarried.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
	carry.type = "beingcarried"
end)

RegisterNetEvent("primePlayermenuV2:cl_stop")
AddEventHandler("primePlayermenuV2:cl_stop", function()
	carry.InProgress = false
	ClearPedSecondaryTask(PlayerPedId())
	DetachEntity(PlayerPedId(), true, false)
    carry.type = ""
end)

Citizen.CreateThread(function()
	while true do
		if carry.InProgress then
			if carry.type == "beingcarried" then
				if not IsEntityPlayingAnim(PlayerPedId(), carry.personCarried.animDict, carry.personCarried.anim, 3) then
					TaskPlayAnim(PlayerPedId(), carry.personCarried.animDict, carry.personCarried.anim, 8.0, -8.0, 100000, carry.personCarried.flag, 0, false, false, false)
				end
			elseif carry.type == "carrying" then
				if not IsEntityPlayingAnim(PlayerPedId(), carry.personCarrying.animDict, carry.personCarrying.anim, 3) then
					TaskPlayAnim(PlayerPedId(), carry.personCarrying.animDict, carry.personCarrying.anim, 8.0, -8.0, 100000, carry.personCarrying.flag, 0, false, false, false)
				end
                if Config.DisableSprintWhenCarrying then
                    DisableControlAction(0, 21, true)
                end
			end
		end
		Wait(0)
	end
end)

function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end        
    end
    return animDict
end

RegisterNetEvent('primePlayermenuV2:notify')
AddEventHandler('primePlayermenuV2:notify', function(message)
    ShowNotification(message)
end)

function reformatInt(i)
	return tostring(i):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function ShowNotification(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, true)
end

function GetClosestVehicleToPlayer()
    local playerPed = PlayerPedId()  -- Spieler-Ped
    local playerPos = GetEntityCoords(playerPed)  -- Position des Spielers
    local closestVehicle = nil
    local closestDistance = nil

    -- Hole alle Fahrzeuge im Umkreis
    local vehicles = GetGamePool("CVehicle")

    for _, vehicle in ipairs(vehicles) do
        local vehiclePos = GetEntityCoords(vehicle)
        local distance = GetDistanceBetweenCoords(playerPos.x, playerPos.y, playerPos.z, vehiclePos.x, vehiclePos.y, vehiclePos.z)

        -- Überprüfe, ob dieses Fahrzeug näher ist als das bisherige nächstgelegene
        if closestDistance == nil or distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end

    return closestVehicle, closestDistance
end

function GetPlayerCoords(playerId)
    local playerPed = GetPlayerPed(playerId)
    return GetEntityCoords(playerPed)
end

function TeleportBehindPlayer(targetPlayerId)
    local targetCoords = GetPlayerCoords(targetPlayerId)

    if targetCoords then

        local heading = GetEntityHeading(GetPlayerPed(targetPlayerId))

        local offsetDistance = 0.9
        local offsetX = offsetDistance * math.sin(math.rad(heading))
        local offsetY = -offsetDistance * math.cos(math.rad(heading))

        local newCoords = vector3(targetCoords.x + offsetX, targetCoords.y + offsetY, targetCoords.z - 1.0)

        SetEntityCoords(PlayerPedId(), newCoords.x, newCoords.y, newCoords.z, false, false, false, true)
        SetEntityHeading(PlayerPedId(), heading)
    end
end

RegisterNetEvent('primePlayermenuV2:InvitePlayerControls', function(job, sender)

    local inviteExpired = false
    Citizen.CreateThread(function()
        Wait(15000)
        inviteExpired = true
    end)

    Citizen.CreateThread(function()
        while true do

            if IsControlJustReleased(0, 246) then
                TriggerServerEvent('primePlayermenuV2:AcceptJobInvite', job, sender)
                ShowNotification(Translation[Config.Locale]['jobinvite_accepted'])
                break
            end 
            if IsControlJustReleased(0, 73) then
                TriggerServerEvent('primePlayermenuV2:DeclineInvite', sender)
                ShowNotification(Translation[Config.Locale]['jobinvite_declined'])
                break
            end

            if inviteExpired then
                ShowNotification(Translation[Config.Locale]['jobinvite_expired'])
                TriggerServerEvent('primePlayermenuV2:InviteExpired', sender)
                break
            end

            Wait(1)
        end
    end)

end)

RegisterNetEvent("primePlayermenuV2:checkCuff")
AddEventHandler("primePlayermenuV2:checkCuff", function(player)
        ESX.TriggerServerCallback("primePlayermenuV2:isCuffed",function(cuffed)
            if not cuffed then
                TeleportBehindPlayer(player)
                -- TaskPlayAnim(PlayerPedId(), 'mp_arresting', 'a_uncuff', 8.0, -8, 3000, 49, 0, 0, 0, 0)
                FreezeEntityPosition(GetPlayerPed(player), true)
                if lib.progressBar({
                    duration = 4000,
                    label = Translation[Config.Locale]['handcuff'],
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                    },
                    anim = {
                        dict = 'mp_arresting',
                        clip = 'a_uncuff'
                    },
                }) then
                    
                    TriggerServerEvent("primePlayermenuV2:handcuff",GetPlayerServerId(player),true)
                    ShowNotification(Translation[Config.Locale]['handcuff_applied'])                         
                    FreezeEntityPosition(GetPlayerPed(player), false)
                else

                    FreezeEntityPosition(GetPlayerPed(player), false)
                end

            end

        end,GetPlayerServerId(player))
end)

RegisterNetEvent("primePlayermenuV2:uncuff")
AddEventHandler("primePlayermenuV2:uncuff",function(player)
    TeleportBehindPlayer(player)

    if lib.progressBar({
        duration = 4000,
        label = Translation[Config.Locale]['handcuff'],
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = {
            dict = 'mp_arresting',
            clip = 'a_uncuff'
        },
    }) then
        
        TriggerServerEvent("primePlayermenuV2:uncuff",GetPlayerServerId(player))              
    
    else


    end

end)

RegisterNetEvent('primePlayermenuV2:forceUncuff')
AddEventHandler('primePlayermenuV2:forceUncuff',function()
    IsHandcuffed = false
    local playerPed = GetPlayerPed(-1)
    ClearPedSecondaryTask(playerPed)
    SetEnableHandcuffs(playerPed, false)
    DisablePlayerFiring(playerPed, false)
    SetPedCanPlayGestureAnims(playerPed, true)
    FreezeEntityPosition(playerPed, false)
    DisplayRadar(true)
    ShowNotification(Translation[Config.Locale]['handcuff_released'])
end)

RegisterNetEvent("primePlayermenuV2:handcuff")
AddEventHandler("primePlayermenuV2:handcuff",function()
    local playerPed = GetPlayerPed(-1)
    IsHandcuffed = not IsHandcuffed
    Citizen.CreateThread(function()
        if IsHandcuffed then
            ClearPedTasks(playerPed)
            SetPedCanPlayAmbientBaseAnims(playerPed, true)

            Citizen.Wait(10)
            -- RequestAnimDict('mp_arresting')
            -- while not HasAnimDictLoaded('mp_arresting') do
            --     Citizen.Wait(100)
            -- end
            -- RequestAnimDict('mp_arrest_paired')
            -- while not HasAnimDictLoaded('mp_arrest_paired') do
            --     Citizen.Wait(100)
            -- end
			-- TaskPlayAnim(playerPed, "mp_arrest_paired", "crook_p2_back_right", 8.0, -8, -1, 32, 0, 0, 0, 0)
			-- Citizen.Wait(5000)
            -- TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)

            SetEnableHandcuffs(playerPed, true)
            DisablePlayerFiring(playerPed, true)
            SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
            SetPedCanPlayGestureAnims(playerPed, false)
            -- DisplayRadar(false)

            DisableControlAction(0, 75, true)
            DisableControlAction(0, 23, true)
        else
            ClearPedSecondaryTask(playerPed)
            SetEnableHandcuffs(playerPed, false)
            DisablePlayerFiring(playerPed, false)
            SetPedCanPlayGestureAnims(playerPed, true)
            FreezeEntityPosition(playerPed, false)
            DisableControlAction(0, 75, false)
            DisableControlAction(0, 23, false)
            DisablePlayerFiring(playerPed, true)
            DisableControlAction(0, 37, true)
            DisplayRadar(true)
        end
        handsup = false
        ShowNotification(Translation[Config.Locale]['handcuff_applied_target'])
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = GetPlayerPed(-1)
        if IsHandcuffed then
            SetEnableHandcuffs(playerPed, true)
            DisablePlayerFiring(playerPed, true)
            SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
            SetPedCanPlayGestureAnims(playerPed, false)
            -- DisplayRadar(false)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 140, true)

            DisablePlayerFiring(playerPed, true)
            DisableControlAction(0, 37, true)
        end
        if not IsHandcuffed and not IsControlEnabled(0, 140) then EnableControlAction(0, 140, true) end
    end
end)

Citizen.CreateThread(function()
    local wasgettingup = false
    while true do
        Citizen.Wait(250)
        if IsHandcuffed then
            local ped = GetPlayerPed(-1)
            if not IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3) and carry.type ~= "beingcarried" and not IsEntityPlayingAnim(ped, "mp_arrest_paired", "crook_p2_back_right", 3) or (wasgettingup and not IsPedGettingUp(ped)) then ESX.Streaming.RequestAnimDict("mp_arresting", function() TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0) end) end
            wasgettingup = IsPedGettingUp(ped)
        end
    end
end)