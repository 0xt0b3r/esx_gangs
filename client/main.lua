local curGang = {}
local PlayerData = {}
local isInMarker = false
local curMarker = nil

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job

	Citizen.Wait(5000)
end)

--Blips
Citizen.CreateThread(function()
    for k,v in pairs(Config.Gangs) do
        local blip = AddBlipForCoord(v.Blip.coords)

        SetBlipSprite (blip, v.Blip.sprite)
        SetBlipScale  (blip, v.Blip.scale)
        SetBlipColour (blip, v.Blip.color)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(v.Blip.name)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNetEvent('esx_gangs:BossMenu')
AddEventHandler('esx_gangs:BossMenu', function(society)
    TriggerEvent('esx_society:openBossMenu', PlayerData.job.name, function(data, menu)
        print(society)
        menu.close()

        CurrentAction     = 'menu_boss_actions'
        CurrentActionMsg  = 'boss'
        CurrentActionData = {}
    end, { wash = false })
end)

--Menus

function OpenBossMenu()
    TriggerServerEvent('esx_gangs:openBossMenu')
end

function OpenArmoryMenu()
	local elements = {}
    table.insert(elements, {label = "Take Weapon",     value = 'get_weapon'})
    table.insert(elements, {label = "Deposit Weapon",     value = 'put_weapon'})
    table.insert(elements, {label = "Take Item",  value = 'get_stock'})
    table.insert(elements, {label = "Deposit Item", value = 'put_stock'})

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_armory', {
		title    = "Gang Armory",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'get_weapon' then
			OpenGetWeaponMenu()
		elseif data.current.value == 'put_weapon' then
			OpenPutWeaponMenu()
		elseif data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		end

	end, function(data, menu)
        menu.close()

		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = "gang_armory_open"
		CurrentActionData = {}
	end)
end

function OpenGetWeaponMenu()
	ESX.TriggerServerCallback('esx_gangs:getArmoryWeapons', function(weapons)
		local elements = {}

		for i=1, #weapons, 1 do
			if weapons[i].count > 0 then
				table.insert(elements, {
					label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name),
					value = weapons[i].name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_armory_get_weapon', {
			title    = "Weapon Retrieval",
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			ESX.TriggerServerCallback('esx_gangs:removeArmoryWeapon', function()
				OpenGetWeaponMenu()
			end, data.current.value)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutWeaponMenu()
	local elements   = {}
	local playerPed  = PlayerPedId()
	local weaponList = ESX.GetWeaponList()

	for i=1, #weaponList, 1 do
		local weaponHash = GetHashKey(weaponList[i].name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			table.insert(elements, {
				label = weaponList[i].label,
				value = weaponList[i].name
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_armory_put_weapon', {
		title    = "Weapon Deposition",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		menu.close()

		ESX.TriggerServerCallback('esx_gangs:addArmoryWeapon', function()
			OpenPutWeaponMenu()
		end, data.current.value, true)
	end, function(data, menu)
		menu.close()
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_gangs:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_stocks_menu', {
			title    = "Gang Inventory",
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_stocks_menu_get_item_count', {
				title = "Amount"
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification("Invalid Amount!")
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_gangs:getStockItem', itemName, count)

					Citizen.Wait(300)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('esx_gangs:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_stocks_menu', {
			title    = "Item Inventory",
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'gang_' .. PlayerData.job.name .. '_stocks_menu_put_item_count', {
				title = "Amount"
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification("Invalid Amount!")
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_gangs:putStockItems', itemName, count)

					Citizen.Wait(300)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

--Markers
--[ Absolute trash marker drawing and distance detection, I'm still learning :P (I know it's shit lmao)]
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        local markers = {}
        if PlayerData.job ~= nil then
            for k,v in pairs(Config.Gangs) do
                if PlayerData.job.name == v.JobName then
                    markers = v.Markers
                end
			end
			for k,v in pairs(markers) do
				local coords = GetEntityCoords(PlayerPedId())
				local distance = GetDistanceBetweenCoords(coords, v.coords.x, v.coords.y, v.coords.z, true)
				if(distance < Config.DrawDistance) then
					DrawMarker(1, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 0.5, 1.5, 0.5, 0, 100, false, true, 2, false, false, false, false)   

					if distance < 1.5 then --[ TRASSSHHHHHH ]
						curMarker = v.name
					else
						curMarker = nil
					end
				end
				if IsControlJustReleased(1, 38) then
					if curMarker == "boss" and PlayerData.job.grade == 5 then
						OpenBossMenu()
					elseif curMarker == "armory" and PlayerData.job.grade >= 1 then
						OpenArmoryMenu()
					end
				end
			end
        end
    end
end)