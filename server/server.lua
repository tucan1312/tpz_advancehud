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

local function compareVersions(v1, v2)
    local a, b = {}, {}
    for num in string.gmatch(v1, "%d+") do table.insert(a, tonumber(num)) end
    for num in string.gmatch(v2, "%d+") do table.insert(b, tonumber(num)) end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x < y then return true end
        if x > y then return false end
    end
    return false
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    local githubUser = "tucan1312"
    local url = ('https://raw.githubusercontent.com/%s/%s/main/version.txt'):format(githubUser, resourceName)

    PerformHttpRequest(url, function(err, latestVersion, headers)
        local currentVersion = GetResourceMetadata(resourceName, 'version') 
        
        if err == 200 and latestVersion then
            local cleanLatest = latestVersion:gsub("%s+", "")
            local cleanCurrent = currentVersion:gsub("%s+", "")

            if compareVersions(cleanCurrent, cleanLatest) then
                print('^1---------------------------------------------------------------^7')
                print(string.format("^5[%s]^7 is ^1OUTDATED^7!", resourceName))
                print(string.format("^5Current:^7 ^1%s^7 | ^5Latest:^7 ^2%s^7", cleanCurrent, cleanLatest))
                print(string.format("^5Download:^7 https://github.com/%s/%s", githubUser, resourceName))
                print('^1---------------------------------------------------------------^7')
            else
                print(string.format("^2[%s] Running latest version (v%s)^7", resourceName, cleanCurrent))
            end
        else
            print("^3["..resourceName.."] Version check failed. HTTP: "..err.." (Check version.txt on GitHub)^7")
        end
    end)
end)