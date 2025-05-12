local Core = exports.vorp_core:GetCore()
local T = Translation.Langs[Lang]
local minning_rocks = {}

RegisterNetEvent("vorp_mining:pickaxecheck", function(rock)
	local _source = source
	local miningrock = rock

	if minning_rocks[_source] then
		return
	end

	local pickaxe = exports.vorp_inventory:getItem(_source, Config.Pickaxe)
	if not pickaxe then
		TriggerClientEvent("vorp_mining:nopickaxe", _source)
		Core.NotifyObjective(_source, T.NotifyLabels.notHavePickaxe, 5000)
		return
	end

	local meta = pickaxe.metadata
	if not next(meta) then
		local metadata = { description = T.NotifyLabels.descDurabilityOne, durability = 99 }
		exports.vorp_inventory:setItemMetadata(_source, pickaxe.id, metadata, 1)
		TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
	else
		local durability = meta.durability - 1
		local description = T.NotifyLabels.descDurabilityTwo .. " " .. durability
		local metadata = { description = description, durability = durability }

		if durability < Config.PickaxeDurabilityThreshold then                            -- Less than Config.PickaxeDurabilityThreshold then add break check
			local random = math.random(Config.PickaxeBreakChanceMin, Config.PickaxeBreakChanceMax) -- Difficulty to break pickaxe
			if random == 1 then
				exports.vorp_inventory:subItem(_source, Config.Pickaxe, 1, meta)
				Core.NotifyObjective(_source, T.NotifyLabels.brokePickaxe, 5000)
				TriggerClientEvent("vorp_mining:nopickaxe", _source)
			else
				exports.vorp_inventory:setItemMetadata(_source, pickaxe.id, metadata, 1)
				TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
			end
		else
			exports.vorp_inventory:setItemMetadata(_source, pickaxe.id, metadata, 1)
			TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
		end
	end
	minning_rocks[_source] = { coords = rock, count = 0 }
end)

CreateThread(function()
	while true do
		Wait(1000)
		for k, v in pairs(minning_rocks) do
			if os.time() - v.time > 60 then
				minning_rocks[k] = nil
			end
		end
	end
end)


RegisterNetEvent('vorp_mining:addItem', function(max_swings)
	local _source = source
	local chance = math.random(1, 20)
	local reward = {}
	local rock = minning_rocks[_source]
	if not rock then
		return
	end

	-- check distance between player and rock
	local playerCoords = GetEntityCoords(GetPlayerPed(_source))
	local rockCoords = rock.coords
	local distance = #(playerCoords - rockCoords)
	if distance > 10.0 then
		return
	end

	if max_swings > Config.MaxSwing then
		return
	end

	rock.count = rock.count + 1
	if rock.count >= max_swings then
		minning_rocks[_source] = nil
	end

	for _, v in ipairs(Config.Items) do
		if v.chance >= chance then
			table.insert(reward, v)
		end
	end

	local randomtotal = #reward
	if randomtotal == 0 then
		Core.NotifyObjective(_source, T.NotifyLabels.gotNothing, 5000)
		return
	end

	local chance2 = math.random(1, randomtotal) -- if 0 the interval will be empty since minimum is 1
	local count = math.random(1, reward[chance2].amount)

	local canCarryItem = exports.vorp_inventory:canCarryItem(_source, reward[chance2].name, count)
	if not canCarryItem then
		Core.NotifyObjective(_source, T.NotifyLabels.fullBag .. reward[chance2].label, 3000)
		return
	end

	exports.vorp_inventory:addItem(_source, reward[chance2].name, count)
	Core.NotifyObjective(_source, T.NotifyLabels.yourGot .. reward[chance2].label, 3000)
end)


--on playerdropped
AddEventHandler('playerDropped', function()
	local _source = source
	if minning_rocks[_source] then
		minning_rocks[_source] = nil
	end
end)
