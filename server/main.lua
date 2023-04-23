local ESX = nil

Citizen.CreateThread(function()
    for k, v in pairs(Config.grupperinger) do
        TriggerEvent('esx_society:registerSociety', k, k, 'society_'..k, 'society_'..k, 'society_'..k, {type = 'private'})
    end
end)

-- CALLBACKS

ESX.RegisterServerCallback('eske_gangmenu:gangJob', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        for k, v in pairs(Config.grupperinger) do
            if xPlayer.getJob().name == k then
                if xPlayer.getJob().grade_name == 'boss' then
                    cb(k)
                end
            end
        end
    end
    cb(false)
end)

ESX.RegisterServerCallback('eske_gangmenu:seMedlemmer', function(source, cb, job)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM users WHERE job = @job ORDER BY job_grade DESC", {['@job'] = job})
    if rawdata ~= nil then
        local medlemmer = {}
        for k, v in pairs(rawdata) do
            table.insert(medlemmer, {
                navn = v.firstname .. ' ' .. v.lastname,
                stilling = v.job_grade,
                identifier = v.identifier
            })
        end
        cb(medlemmer)
    end
end)

ESX.RegisterServerCallback('eske_gangmenu:seRanks', function(source, cb, job)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM job_grades WHERE job_name = @job ORDER BY grade DESC", {['@job'] = job})
    if rawdata ~= nil then
        local ranks = {}
        for k, v in pairs(rawdata) do
            table.insert(ranks, {
                rangering = v.label,
                grade = v.grade
            })
        end
        cb(ranks)
    end
end)

ESX.RegisterServerCallback('eske_gangmenu:seSpillere', function(source, cb)
    local spillere = ESX.GetExtendedPlayers()
    local _spillere = {}
    for _, xPlayer in pairs(spillere) do 
        table.insert(_spillere, {
            id = xPlayer.source
        })
    end
    cb(_spillere)
end)

ESX.RegisterServerCallback('eske_gangmenu:bandeKasse', function(source, cb, job)
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account) 
        if account ~= nil then
            if account.money ~= nil then
                cb(account.money)
            else
                cb(0)
            end
        else
            cb(0)
        end
    end)
end)

-- EVENTS
AddEventHandler('eske_gangmenu:skiftRangering')
RegisterNetEvent('eske_gangmenu:skiftRangering', function(gang, identifier, grade)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade_name == 'boss' then
            local xTarget = ESX.GetPlayerFromIdentifier(identifier)
            if xTarget then
                xTarget.setJob(gang, grade)
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tildelt ' .. xTarget.getName() .. ' en anden rangering.', length = 10000})
                TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'success', text = xPlayer.getName() .. ' tildelte en anden rangering.', length = 10000})
                PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' satte ' .. xTarget.getName() .. ' til at have rangeringsgraden ' .. grade .. ' i ' .. gang .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' satte ' .. xTarget.getName() .. ' til at have rangeringsgrad ' .. grade .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
            else
                MySQL.Async.execute("UPDATE users SET job_grade = @grade WHERE identifier = @identifier", {
                    ['@identifier'] = identifier, ['@grade'] = grade
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tildelt medlemmet en ny rangering.', length = 10000})
                    PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' satte ' .. identifier .. ' til at have rangeringsgraden ' .. grade .. ' i ' .. gang .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                    PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' satte ' .. identifier .. ' til at have rangeringsgrad ' .. grade .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at forfremme en person.', length = 10000})
        end
    else 
        print('[ESKE GANGMENU] Der skete en fejl ved forfremmelse af et medlem. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved forfremmelse af et medlem. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

AddEventHandler('eske_gangmenu:fjernMedlem')
RegisterNetEvent('eske_gangmenu:fjernMedlem', function(gang, identifier)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade_name == 'boss' then
            local xTarget = ESX.GetPlayerFromIdentifier(identifier)
            if xTarget then
                xTarget.setJob('unemployed', 0)
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har fjernet ' .. xTarget.getName() .. ' fra grupperingen.', length = 10000})
                TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'success', text = xPlayer.getName() .. ' fjernede dig fra grupperingen.', length = 10000})
                PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' fjernede ' .. xTarget.getName() .. ' fra  ' .. gang .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' fjernede ' .. xTarget.getName() .. ' fra grupperingen.', tts = false}), { ['Content-Type'] = 'application/json' })
            else
                MySQL.Async.execute("UPDATE users SET job_grade = @grade, job = @job, job_grade = @job_grade WHERE identifier = @identifier", {
                    ['@identifier'] = identifier, ['@grade'] = grade, ['@job'] = 'unemployed', ['@job_grade'] = 0
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har fjernet medlemmet fra grupperingen.', length = 10000})
                    PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' fjernede ' ..identifier .. ' fra  ' .. gang .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                    PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' fjernede ' .. identifier .. ' fra grupperingen.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at forfremme en person.', length = 10000})
        end
    else 
        print('[ESKE GANGMENU] Der skete en fejl ved fjernelse af et medlem. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved fjernelse af et medlem. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

AddEventHandler('eske_gangmenu:tilføjMedlem')
RegisterNetEvent('eske_gangmenu:tilføjMedlem', function(gang, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade_name == 'boss' then
            local xTarget = ESX.GetPlayerFromId(id)
            if xTarget ~= nil then
                if xTarget.source ~= xPlayer.source then
                    xTarget.setJob(gang, 0)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tilføjet ' .. xTarget.getName() .. ' til grupperingen.', length = 10000})
                    TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'success', text = xPlayer.getName() .. ' til dig til grupperingen.', length = 10000})
                    PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tilføjede ' .. xTarget.getName() .. ' til ' .. gang .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                    PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tilføjede ' .. xTarget.getName() .. ' til grupperingen.', tts = false}), { ['Content-Type'] = 'application/json' })
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du kan ikke vælge dig selv.', length = 10000})
                end
            else
                print('[ESKE GANGMENU] Der skete en fejl ved ansættelse af et medlem. Kontakt support. [2]')
                PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
                    local ip =  tostring(text)
                    PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved ansættelse af et medlem. [2]', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at tilføje en person.', length = 10000})
        end
    else 
        print('[ESKE GANGMENU] Der skete en fejl ved ansættelse af et medlem. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved ansættelse af et medlem. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

AddEventHandler('eske_gangmenu:tilføjPenge')
RegisterNetEvent('eske_gangmenu:tilføjPenge', function(gang, penge)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade_name == 'boss' then
            if xPlayer.getMoney() >= penge then
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..gang, function(account)
                    xPlayer.removeMoney(penge)
                    account.addMoney(penge)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tilføjet ' .. penge .. ' til jeres kasse.', length = 10000})
                    PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' lagde ' .. penge .. ' i ' .. gang .. '. Der er nu ' .. account.money + penge .. ' DKK.', tts = false}), { ['Content-Type'] = 'application/json' })
                    PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tilføjede ' .. penge .. ' til jeres bandekasse. Der er nu ' .. account.money + penge .. ' DKK.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            else
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Dette har du desværre ikke råd til.', length = 10000})
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at tilføje penge til kassen.', length = 10000})
        end
    else 
        print('[ESKE GANGMENU] Der skete en fejl ved tilføjelse af penge. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved tilføjelse af penge. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end 
end)

AddEventHandler('eske_gangmenu:fjernPenge')
RegisterNetEvent('eske_gangmenu:fjernPenge', function(gang, penge)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade_name == 'boss' then
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..gang, function(account)
                if account.money >= penge then
                    xPlayer.addMoney(penge)
                    account.removeMoney(penge)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har fjernet ' .. penge .. ' fra jeres kasse.', length = 10000})
                    PerformHttpRequest(Config.serverwebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tog ' .. penge .. ' fra ' .. gang .. '. Der er nu ' .. account.money - penge .. ' DKK.', tts = false}), { ['Content-Type'] = 'application/json' })
                    PerformHttpRequest(Config.grupperinger[gang].webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tog ' .. penge .. ' fra jeres bandekasse. Der er nu ' .. account.money - penge .. ' DKK.', tts = false}), { ['Content-Type'] = 'application/json' })
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Der er ikke nok penge i kassen til dette.', length = 10000})
                end
            end)
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at tilføje penge til kassen.', length = 10000})
        end
    else 
        print('[ESKE GANGMENU] Der skete en fejl ved fjernelse af penge. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved fjernelse af penge. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end 
end)