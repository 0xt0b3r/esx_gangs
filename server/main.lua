ESX = nil

local ls_gangs = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

for _,gang in pairs(Config.Gangs) do
    TriggerEvent('esx_society:registerSociety', gang.JobName, gang.JobLabel, gang.society, gang.society, gang.society, {type = 'public'})
    print("[esx_gangs]: Registered society for " .. gang.JobLabel .. "!")
end

RegisterServerEvent('esx_gangs:openBossMenu')
AddEventHandler('esx_gangs:openBossMenu', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local pGang = xPlayer.job.name

    for _,g in pairs(Config.Gangs) do
        if g.JobName == pGang then
            TriggerClientEvent('esx_gangs:BossMenu', _source, g.society)
        end
    end
end)

RegisterServerEvent('esx_gangs:getStockItem')
AddEventHandler('esx_gangs:getStockItem', function(itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. xPlayer.job.name, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and inventoryItem.count >= count then

			-- can the player carry the said amount of x item?
			if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
				TriggerClientEvent('esx:showNotification', _source, "Invalid Amount")
			else
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent('esx:showNotification', _source, "Successfully withdrew ", count, inventoryItem.label)
			end
		else
			TriggerClientEvent('esx:showNotification', _source, "Invalid Amount")
		end
	end)
end)

RegisterServerEvent('esx_gangs:putStockItems')
AddEventHandler('esx_gangs:putStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. xPlayer.job.name, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- does the player have enough of the item?
		if sourceItem.count >= count and count > 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			TriggerClientEvent('esx:showNotification', xPlayer.source, "Successfully deposited ", count, inventoryItem.label)
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, "Invalid Amount!")
		end
	end)
end)

ESX.RegisterServerCallback('esx_gangs:getArmoryWeapons', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
	TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job.name, function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		cb(weapons)
	end)
end)

ESX.RegisterServerCallback('esx_gangs:addArmoryWeapon', function(source, cb, weaponName, removeWeapon)
	local xPlayer = ESX.GetPlayerFromId(source)

	if removeWeapon then
		xPlayer.removeWeapon(weaponName)
	end

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job.name, function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = weapons[i].count + 1
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 1
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

ESX.RegisterServerCallback('esx_gangs:removeArmoryWeapon', function(source, cb, weaponName)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addWeapon(weaponName, 500)

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_' .. xPlayer.job.name, function(store)

		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 0
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

ESX.RegisterServerCallback('esx_gangs:getStockItems', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_' .. xPlayer.job.name, function(inventory)
		cb(inventory.items)
	end)
end)

ESX.RegisterServerCallback('esx_gangs:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb( { items = items } )
end)