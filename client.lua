local horseVisible = false
local hudEditing = false
local playerData = { money = 0, gold = 0, blackmoney = 0, job = "Citizen", jobGrade = "" }
local cinematicEnabled = false
local masterDisplayOn = true 

RegisterNetEvent("tpz_core:isPlayerReady")
AddEventHandler("tpz_core:isPlayerReady", function(newChar)
   TriggerServerEvent('tpz_advancehud:server:requestLoad')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Citizen.Wait(1000)
    TriggerServerEvent('tpz_advancehud:server:requestLoad')
end)

RegisterNetEvent('tpz_advancehud:client:applySavedSettings', function(rawJson)
    local data = json.decode(rawJson)
    SendNUIMessage({
        action = "applySavedSettings",
        layout = data.layout,
        scale = data.scale,
        styles = data.styles
    })
end)

RegisterCommand(Config.CommandName, function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openSettings"
    })
end)

RegisterNUICallback('CloseEdit', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        showhud = not cinematicEnabled
    })
    cb('ok')
end)


RegisterNUICallback('saveHUDData', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('tpz_advancehud:server:saveData', data.layout, data.scale, data.styles)
    cb('ok')
end)



RegisterNUICallback('toggleMasterDisplay', function(data, cb)
    masterDisplayOn = data.visible

    SendNUIMessage({
        showhud = masterDisplayOn
    })
    
    cb('ok')
end)


RegisterNUICallback('toggleCinematic', function(data, cb)
    cinematicEnabled = not cinematicEnabled
    
    if cinematicEnabled then
        Citizen.InvokeNative(0x69D65E89FFD72313, true, true) 
        SendNUIMessage({ showhud = false }) 
    else
        Citizen.InvokeNative(0x69D65E89FFD72313, false, false) 
        SendNUIMessage({ showhud = true })
    end
    
    cb('ok')
end)



UpdateHud = function(isTalking)
    local player = PlayerPedId()
    local serverId = GetPlayerServerId(PlayerId())
    local levels = {}
    local hunger  = exports["tpz_metabolism"]:getHunger() or 100
    local thirst  = exports["tpz_metabolism"]:getThirst() or 100
    local alcohol = exports["tpz_metabolism"]:getAlcohol() or 0
    local stress  = exports["tpz_metabolism"]:getStress() or 0
    local coords = GetEntityCoords(player)
    Citizen.InvokeNative(0xB98B78C3768AF6E0, true) 
    local temperature = GetTemperatureAtCoords(coords) or 20.0


    if Config.BodyTemp then
        for _, item in ipairs(Config.ClothingData) do
            if Citizen.InvokeNative(0xFB4891BD7578CDC1, player, item.hash) then
                temperature = temperature + item.bonus
            end
        end
    end

    if Config.tpz_leveling then
        local GetLevelData = function (levelType)
            local data = exports.tpz_leveling:GetLevelTypeExperienceData(levelType)
            if data then
                return { 
                    level = data.level, 
                    experience = math.floor((data.experience * 100) / 1000) 
                }
            end
            return { level = 0, experience = 0 }
        end

        levels = {
            lumberjack = GetLevelData("lumberjack"),
            hunting    = GetLevelData("hunting"),
            farming    = GetLevelData("farming"),
            mining     = GetLevelData("mining"),
            fishing    = GetLevelData("fishing")
        }
    end

    local isHudVisible = not (IsRadarHidden() or IsPauseMenuActive() or IsHudHidden())

    SendNUIMessage({
        showhud = (isHudVisible and masterDisplayOn),
        hp            = GetEntityHealth(player),
        stamina       = GetPedStamina(player),
        temperature   = math.floor(temperature) .. "°C",
        hunger        = hunger,
        thirst        = thirst,
        alcohol       = alcohol,
        stress        = stress,
        serverId      = serverId,
        money         = playerData.money,
        gold          = playerData.gold,
        blackMoney    = playerData.blackmoney,
        jobLabel      = playerData.job,
        isTalking     = isTalking,
        levelingConfig = Config.tpz_leveling,
        levels         = levels
    })
end

Citizen.CreateThread(function()
    local timer1000 = 0
    local timer2000 = 0
    local timer5000 = 0
    local lastTalkingStatus = false
    local lastVoiceLevel = 0
    local horseVisible = false
    local PlayerPedId = PlayerPedId
    local PlayerId = PlayerId
    local GetGameTimer = GetGameTimer
    local IsPauseMenuActive = IsPauseMenuActive
    local DoesEntityExist = DoesEntityExist
    local IsPedOnMount = IsPedOnMount
    local GetEntityHealth = GetEntityHealth
    local IsPedInAnyVehicle = IsPedInAnyVehicle
    local DisplayRadar = DisplayRadar
    local SetRadarZoom = SetRadarZoom
    local SendNUIMessage = SendNUIMessage

    while true do
        local sleep = 500
        local player = PlayerPedId()
        local pId = PlayerId()
        local currentTime = GetGameTimer()
        

        local hudUpdate = {}

  
        local playerId = PlayerId()
        local isTalking = MumbleIsPlayerTalking(playerId)

        if isTalking ~= lastTalkingStatus then
            lastTalkingStatus = isTalking
            SendNUIMessage({
                action = "is_talking",
                talking = isTalking
            })
        end

        local mount = GetMount(player)
        local IsHorseHud = (mount ~= 0 and DoesEntityExist(mount) and IsPedOnMount(player) and not IsPauseMenuActive())
        
        if IsHorseHud then
            horseVisible = true

            local maxH = Citizen.InvokeNative(0x4700A416E8324EF3, mount, Citizen.ResultAsInteger())
            local maxS = Citizen.InvokeNative(0xCB42AFE2B613EE55, mount, Citizen.ResultAsFloat())
            local curS = Citizen.InvokeNative(0x775A1CA7893AA8B5, mount, Citizen.ResultAsFloat())
            
            hudUpdate.showHorse = true
            hudUpdate.horsehealth = math.floor((maxH > 0) and (GetEntityHealth(mount) / maxH) * 100 or 0)
            hudUpdate.horsestamina = math.floor((maxS > 0) and (curS / maxS) * 100 or 0)

        elseif horseVisible then
            horseVisible = false
            hudUpdate.showHorse = false
        end


        if currentTime >= timer1000 then
            UpdateHud(isTalking)

            local playerState = Entity(player).state
            local proximity = playerState.proximity
            if proximity then
                local level = 2
                if proximity.range < 5.0 then 
                    level = 1 
                elseif proximity.range > 15.0 then 
                    level = 3 
                end
                
                if level ~= lastVoiceLevel then
                    lastVoiceLevel = level
                    hudUpdate.voice_level_update = true
                    hudUpdate.voicelevel = level
                end
            end

            timer1000 = currentTime + 1000
        end


        if currentTime >= timer2000 then
            SetRadarZoom(1150)

            local shouldShowRadar = Config.AlwaysShowRadar 
                or IsPedInAnyVehicle(player, false) 
                or IsPedOnMount(player)

            DisplayRadar(shouldShowRadar)
            timer2000 = currentTime + 2000
        end


        if currentTime >= timer5000 then
            TriggerEvent("tpz_core:ExecuteServerCallBack", "tpz_core:getPlayerData", function(data)
                if data ~= nil then
                    playerData = data
                end
            end)

            timer5000 = currentTime + 5000
        end


        if next(hudUpdate) ~= nil then
            SendNUIMessage(hudUpdate)
        end

        Citizen.Wait(sleep)
    end
end)



Citizen.CreateThread(function()

        local playerCores = {
            playerhealth = 0,
            playerhealthcore = 1,
            playerdeadeye = 3,
            playerdeadeyecore = 2,
            playerstamina = 4,
            playerstaminacore = 5,
        }

        local horsecores = {
            horsehealth = 6,
            horsehealthcore = 7,
            horsedeadeye = 9,
            horsedeadeyecore = 8,
            horsestamina = 1,
            horsestaminacore = 11,
        }

        if Config.HidePlayersCore then
            for key, value in pairs(playerCores) do
                Citizen.InvokeNative(0xC116E6DF68DCE667, value, 2)
            end
        end

        if Config.HideHorseCores then
            for key, value in pairs(horsecores) do
                Citizen.InvokeNative(0xC116E6DF68DCE667, value, 2)
            end
        end

end)