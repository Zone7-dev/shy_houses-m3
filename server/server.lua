ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

ItemData = {}
local disc_ok = false
local doorState = {}
local stashState = {}

------------ Satın Alma ------------

------------ Kıyafet --------

ESX.RegisterServerCallback('shy_house:getPlayerDressing', function(source, cb)
	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local count  = store.count('dressing')
        local labels = {}
        
		for i=1, count, 1 do
			local entry = store.get('dressing', i)
			table.insert(labels, entry.label)
		end
		cb(labels)
	end)
end)

RegisterServerEvent('shy_house:updateState')
AddEventHandler('shy_house:updateState', function(doorIndex, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer and type(doorIndex) == 'number' and type(state) == 'boolean' then
		doorState[doorIndex] = state
		TriggerClientEvent('shy_house:setDoorState', -1, doorIndex, state)
	end
end)

ESX.RegisterServerCallback('shy_house:getDoorState', function(source, cb)
	cb(doorState)
end)

ESX.RegisterServerCallback('shy_house:checkItem', function(source, cb, house)
    local xPlayer = ESX.GetPlayerFromId(source)
    item = 'evkey' .. tostring(house)
    local xItem = xPlayer.getInventoryItem(item)
    if xItem.count >= 1 then
        cb(true)
    else
        cb(false)
    end
end)
--------- Kıyafet -------

ESX.RegisterServerCallback('shy_house:getPlayerOutfit', function(source, cb, num)
	local xPlayer  = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local outfit = store.get('dressing', num)
		cb(outfit.skin)
	end)
end)

RegisterServerEvent('shy_house:removeOutfit')
AddEventHandler('shy_house:removeOutfit', function(label)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_datastore:getDataStore', 'property', xPlayer.identifier, function(store)
		local dressing = store.get('dressing') or {}

		table.remove(dressing, label)
		store.set('dressing', dressing)
	end)
end)

------------- Stash -----------------
RegisterServerEvent("shy_house:toggleStash")
AddEventHandler("shy_house:toggleStash", function(stashIndex, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer and type(stashIndex) == 'number' and type(state) == 'boolean' then
		stashState[stashIndex] = state
		TriggerClientEvent('shy_house:setDoorState', -1, stashIndex, state)
	end
end)


ESX.RegisterServerCallback('shy_house:getStashState', function(source, cb)
	cb(stashState)
end)

--------- Evi -----------

RegisterServerEvent("shy_house:deleteHouse")
AddEventHandler("shy_house:deleteHouse", function(houseid)
	local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Sync.execute("UPDATE `houses` SET `owner` = @owner WHERE houseid = @houseid", { 
        ['@owner'] = "",
        ['@houseid'] = houseid,
    })

    Citizen.Wait(200)
    itemname = 'evkey' .. houseid
    count = xPlayer.getInventoryItem(itemname).count
    xPlayer.removeInventoryItem(itemname, count)
    Citizen.Wait(50)
    xPlayer.addMoney(Config.HousePrice / 2)
end)

RegisterServerEvent("shy_house:copyKey")
AddEventHandler("shy_house:copyKey", function(houseid)
	local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= Config.KeyPrice then
        itemname = 'evkey' .. houseid
        xPlayer.addInventoryItem(itemname, 1)
        Citizen.Wait(50)
        xPlayer.removeMoney(Config.KeyPrice)
    end
end)

RegisterServerEvent("shy_house:BuyHouse")
AddEventHandler("shy_house:BuyHouse", function(houseid)
	local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= Config.HousePrice then
        xPlayer.removeMoney(Config.HousePrice)

        MySQL.Sync.execute("UPDATE `houses` SET `owner` = @owner WHERE houseid = @houseid", { 
            ['@owner'] = xPlayer.identifier,
            ['@houseid'] = houseid,
        })
    
        itemname = 'evkey' .. houseid
        xPlayer.addInventoryItem(itemname, 1)
    elseif xPlayer.getAccount('bank').money >= Config.HousePrice then
        xPlayer.removeAccountMoney('bank', Config.HousePrice)

        MySQL.Sync.execute("UPDATE `houses` SET `owner` = @owner WHERE houseid = @houseid", { 
            ['@owner'] = xPlayer.identifier,
            ['@houseid'] = houseid,
        })
    
        itemname = 'evkey' .. houseid
        xPlayer.addInventoryItem(itemname, 1)
    end
end)

ESX.RegisterServerCallback('shy_house:getEmptyHouses', function(source, cb)
    local houses = MySQL.Sync.fetchAll("SELECT * FROM houses")
    local emptyhouses = {}
    for i = 1, #houses, 1 do
        if houses[i].owner == '' then
            table.insert(emptyhouses, houses[i].houseid)
        end
    end
    cb(emptyhouses)
end)

ESX.RegisterServerCallback('shy_house:checkPlayerHouses', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT houseid FROM houses WHERE owner = @owner', {
        ['@owner'] = xPlayer.identifier
    }, function(houseid)
        if #houseid ~= 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

ESX.RegisterServerCallback('shy_house:getPlayerHouses', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT houseid FROM houses WHERE owner = @owner', {
        ['@owner'] = xPlayer.identifier
    }, function(houseid)
        if houseid ~= nil then
            cb(houseid)
        else
            cb(nil)
        end
    end)
end)