local TPZ = exports.tpz_core:getCoreAPI()

-- SAVE DATA
RegisterNetEvent('tpz_advancehud:server:saveData', function(layoutTable, scaleValue, styleTable) -- Added styleTable
    local src = source
    local xPlayer = TPZ.GetPlayer(src)
    
    if not xPlayer then return end
    
    local charidentifier = xPlayer.getCharacterIdentifier()
    

    local dataToSave = json.encode({
        layout = layoutTable, 
        scale = scaleValue,
        styles = styleTable 
    })

    exports.oxmysql:update('UPDATE characters SET hud_settings = ? WHERE charidentifier = ?', 
    {dataToSave, charidentifier})
end)

-- LOAD DATA 
RegisterNetEvent('tpz_advancehud:server:requestLoad', function()
    local src = source
    local xPlayer = TPZ.GetPlayer(src)
    
    if not xPlayer then return end
    
    local charidentifier = xPlayer.getCharacterIdentifier()
    
    exports.oxmysql:single('SELECT hud_settings FROM characters WHERE charidentifier = ?', 
    {charidentifier}, function(result)
        if result and result.hud_settings then
            TriggerClientEvent('tpz_advancehud:client:applySavedSettings', src, result.hud_settings)
        end
    end)
end)



local githubUser = "tucan1312" 

AddEventHandler('onResourceStart', function(resourceName)
    -- Only check for your specific HUD script
    if resourceName ~= GetCurrentResourceName() then return end

    PerformHttpRequest('https://raw.githubusercontent.com/'..githubUser..'/' .. resourceName .. '/main/version.txt', function(err, latestVersion, headers)
        local currentVersion = GetResourceMetadata(resourceName, 'version')
        
        if not latestVersion then 
            print('^3['.. resourceName..'] Version check failed (GitHub down?)^7')
            return 
        end

        -- Clean up strings (removes invisible characters/newlines)
        currentVersion = currentVersion:gsub("%s+", "")
        latestVersion = latestVersion:gsub("%s+", "")

        if isOutdated(currentVersion, latestVersion) then
            print('^1---------------------------------------------------------------^7')
            print('^5['.. resourceName..']^7 is ^1OUTDATED^7!')
            print('^5Current:^7 ^1'..currentVersion..'^7')
            print('^5Latest:^7  ^2'..latestVersion..'^7')
            print('^5Download:^7 https://github.com/'..githubUser..'/'..resourceName)
            print('^1---------------------------------------------------------------^7')
        else
            print('^5['.. resourceName..']^7 is up to date (^2v'..currentVersion..'^7).')
        end
    end)
end)