local ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

----------

RegisterKeyMapping('opengangmenu', 'Åben grupperingsmenu', 'keyboard', 'F6')
RegisterCommand('opengangmenu', function()
    aabenBandeMenu()
end)

function seMedlemmer(gang)
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_gangmenu:seMedlemmer', function(result)
        if result ~= nil then
            local elements = {
                head = {'Navn', 'Rangering'},
                rows = {}
            }
    
            for k, v in pairs(result) do
                table.insert(elements.rows, {
                    data = result[k],
                    cols = {
                        v.navn,
                        v.stilling
                    }
                })
            end
            ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_gangmenu_'..gang, elements, function(data, menu)
                end, function(data, menu)
                    menu.close()
            end)
        end
    end, gang)
end

function admMedlemmer(gang)
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_gangmenu:seMedlemmer', function(result)
        if result ~= nil then
            local elements = {
                head = {'Navn', 'Rangering', 'Handlinger'},
                rows = {}
            }
    
            for k, v in pairs(result) do
                table.insert(elements.rows, {
                    data = result[k],
                    cols = {
                        v.navn,
                        v.stilling,
                        '{{Skift rangering|skift}} {{Fjern|fjern}}'
                    }
                })
            end
            ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_gangmenu_'..gang, elements, function(data, menu)
                local spiller = data.data
                if data.value == 'skift' then
                    ESX.UI.Menu.CloseAll()
                    ESX.TriggerServerCallback('eske_gangmenu:seRanks', function(result)
                        local elements = {}
                        for k, v in pairs(result) do
                            table.insert(elements, {
                                label = v.rangering, value = v.grade})
                        end
                        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_gangmenu', {
                            title    = 'Grupperingsmenu - ' .. gang,
                            align    = 'top-left',
                            elements = elements
                        }, function(data2, menu2)
                            ESX.UI.Menu.CloseAll()
                            TriggerServerEvent('eske_gangmenu:skiftRangering', gang, spiller.identifier, data2.current.value)
                          end, function(data2, menu2)
                              menu2.close()
                        end)
                    end, gang)
                elseif data.value == 'fjern' then
                    ESX.UI.Menu.CloseAll()
                    TriggerServerEvent('eske_gangmenu:fjernMedlem', gang, spiller.identifier)
                end
                end, function(data, menu)
                    menu.close()
            end)
        end
    end, gang)
end

function seRanks(gang)
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_gangmenu:seRanks', function(result)
        local elements = {}
        for k, v in pairs(result) do
            table.insert(elements, {
                label = v.rangering, value = v.grade})
        end
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_gangmenu', {
            title    = 'Grupperingsmenu - ' .. gang,
            align    = 'top-left',
            elements = elements
        }, function(data, menu)
            ESX.UI.Menu.CloseAll()
          end, function(data, menu)
              menu.close()
        end)
    end, gang)
end

function nytMedlem(gang)
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_gangmenu:seSpillere', function(result)
        local elements = {
            head = {'Vælg en spiller'},
            rows = {}
        }
        for a, b in pairs(result) do
            table.insert(elements.rows, {
                data = result[a],
                cols = {
                    '{{'..b.id..'|'.. b.id ..'}}'
                }
            })
        end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_gangmenu_nytmedlem', elements, function(data, menu)
            local spiller = data.data
            ESX.UI.Menu.CloseAll()
            TriggerServerEvent('eske_gangmenu:tilføjMedlem', gang, spiller.id)
        end, function(data, menu)
            menu.close()
    end)
    end)
end

function grpKasse(gang)
    ESX.UI.Menu.CloseAll()
    print('1')
    ESX.TriggerServerCallback('eske_gangmenu:bandeKasse', function(result)
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_gangmenu', {
            title    = 'Grupperingsmenu - ' .. gang,
            align    = 'top-left',
            elements = {
                {label = format_thousand(result) .. ' DKK', value = 'nothing'}, 
                {label = 'Læg penge i kassen', value = 'læg'},
                {label = 'Tag penge fra kassen', value = 'tag'}
            }
        }, function(data, menu)
            if data.current.value == 'læg' then 
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'eske_gangmenu', {
                    title = 'Tilføj penge til ' .. gang
                }, function(data2, menu2)
                    local amount = tonumber(data2.value)

                    if amount == nil then
                        ESX.ShowNotification(_U('invalid_amount'))
                    else
                        ESX.UI.Menu.CloseAll()
                        TriggerServerEvent('eske_gangmenu:tilføjPenge', gang, amount)
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            elseif data.current.value == 'tag' then
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'eske_gangmenu', {
                    title = 'Tag penge fra ' .. gang
                }, function(data2, menu2)
                    local amount = tonumber(data2.value)

                    if amount == nil then
                        ESX.ShowNotification(_U('invalid_amount'))
                    else
                        ESX.UI.Menu.CloseAll()
                        TriggerServerEvent('eske_gangmenu:fjernPenge', gang, amount)
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            end
          end, function(data, menu)
              menu.close()
        end)
    end, gang)
end

function aabenBandeMenu()
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_gangmenu:gangJob', function(result)
        if result ~= false then
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_gangmenu', {
                title    = 'Grupperingsmenu - ' .. result,
                align    = 'top-left',
                elements = {
                    {label = 'Liste over medlemmer', value = 'medlemmer'}, 
                    {label = 'Administrer medlemmer', value = 'current'},
                    {label = 'Tilføj medlem', value = 'new'},
                    {label = 'Grupperingskasse', value = 'kasse'},
                    {label = 'Se rangeringer', value = 'ranks'}
                }
            }, function(data, menu)
                if data.current.value == 'medlemmer' then 
                    seMedlemmer(result)
                elseif data.current.value == 'current' then
                    admMedlemmer(result)
                elseif data.current.value == 'kasse' then
                    grpKasse(result)
                elseif data.current.value == 'ranks' then
                    seRanks(result)
                elseif data.current.value == 'new' then
                    nytMedlem(result)
                end
              end, function(data, menu)
                  menu.close()
            end)
        end
    end)
end

-- funktioner
function format_thousand(v)
    if not v then v = 0 end
    v = tonumber(v)
    if v > 999 then
        local s = string.format("%d", math.floor(v))
        local pos = string.len(s) % 3
        if pos == 0 then pos = 3 end
        return string.sub(s, 1, pos)
        .. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
    else
        return v
    end
end
