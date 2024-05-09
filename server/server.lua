local Core = exports.vorp_core:GetCore()
local T = Translation.Langs[Lang]

RegisterNetEvent("vorp_mining:pickaxecheck", function(rock)
	local _source = source
	local miningrock = rock
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
		local description = T.NotifyLabels.descDurabilityTwo
		local metadata = { description = description, durability = durability }

		if durability < 20 then     -- less than 20 then add break check
			local random = math.random(1, 3) -- difficulty to break pickaxe
			if random == 1 then
				exports.vorp_inventory:subItem(_source, Config.Pickaxe, 1, metadata)
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
end)

local keysx = function(table)
	local keys = 0
	for k, v in pairs(table) do
		keys = keys + 1
	end
	return keys
end

RegisterNetEvent('vorp_mining:addItem', function()
	local _source = source
	local chance = math.random(1, 20)
	local reward = {}

	for k, v in pairs(Config.Items) do
		if v.chance >= chance then
			table.insert(reward, v)
		end
	end

	local randomtotal = keysx(reward)
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
