local Core = exports.vorp_core:GetCore()
local T = Translation.Langs[Lang]

local mining_rocks = {}

local mining_rocks_cooldown = {}

local function getKey(coords)
	local x = math.floor(coords.x * 100) / 100
	local y = math.floor(coords.y * 100) / 100
	local z = math.floor(coords.z * 100) / 100
	return string.format("%.2f,%.2f,%.2f", x, y, z)
end

-- reset table
RegisterNetEvent("vorp_mining:resetTable", function(coords)
	local _source = source
	if mining_rocks[_source] then
		if mining_rocks[_source].coords == coords then
			mining_rocks[_source] = nil
		end
	end
end)

RegisterServerEvent("vorp_mining:pickaxecheck", function(rock)
	local _source = source
	local miningrock = rock
	-- is player already mining this rock?

	if mining_rocks[_source] then
		return
	end

	-- is location in cool down?
	local key <const> = getKey(miningrock)
	if mining_rocks_cooldown[key] then
		Core.NotifyObjective(_source, T.NotifyLabels.Rockoncooldown, 5000)
		TriggerClientEvent("vorp_mining:nopickaxe", _source)
		return
	end

	local pickaxe <const> = exports.vorp_inventory:getItem(_source, Config.Pickaxe)
	if not pickaxe then
		TriggerClientEvent("vorp_mining:nopickaxe", _source)
		Core.NotifyObjective(_source, T.NotifyLabels.notHavePickaxe, 5000)
		return
	end

	local meta = pickaxe.metadata
	if not next(meta) then
		local metadata = { description = T.NotifyLabels.descDurabilityOne .. " " .. "99", durability = 99 }
		exports.vorp_inventory:setItemMetadata(_source, pickaxe.id, metadata, 1)
		TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
	else
		local durability = meta.durability - 1
		local description = T.NotifyLabels.descDurabilityTwo .. " " .. durability
		local metadata = { description = description, durability = durability }

		if durability < Config.PickaxeDurabilityThreshold then
			local random = math.random(Config.PickaxeBreakChanceMin, Config.PickaxeBreakChanceMax)
			if random == 1 then
				Core.NotifyObjective(_source, T.NotifyLabels.brokePickaxe, 5000)
				exports.vorp_inventory:subItem(_source, Config.Pickaxe, 1, meta)
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
	-- player is mining this rock at this location
	mining_rocks[_source] = { coords = miningrock, count = 0 }
end)

-- location cooldown
CreateThread(function()
	while true do
		Wait(1000)
		for k, v in pairs(mining_rocks_cooldown) do
			if os.time() - v.time > (Config.CoolDown * 60) then
				mining_rocks_cooldown[k] = nil
			end
		end
	end
end)


RegisterServerEvent('vorp_mining:addItem', function(max_swings)
	math.randomseed(os.time())
	local _source = source

	-- is player mining this rock?
	local miningrock = mining_rocks[_source]
	if not miningrock then
		return
	end

	-- is location in cool down?
	local key <const> = getKey(miningrock.coords)
	if mining_rocks_cooldown[key] then
		Core.NotifyObjective(_source, "nothing to mine here", 5000)
		return
	end

	-- is player near the location?
	local rock_coords = miningrock.coords
	local player_coords = GetEntityCoords(GetPlayerPed(_source))
	local distance = #(rock_coords - player_coords)
	if distance > 10.0 then
		return
	end

	-- max swings cant be more than config
	if max_swings > Config.MaxSwing then
		return
	end

	miningrock.count = miningrock.count + 1
	-- if max swings is reached
	if miningrock.count >= max_swings then
		-- remove player from mining table
		mining_rocks[_source] = nil
		-- start cool down after all swings
		if not mining_rocks_cooldown[key] then
			mining_rocks_cooldown[key] = { time = os.time() }
		end
	end

	local chance = math.random(1, 20) --todo: config this
	local reward = {}
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

	local chance2 = math.random(1, randomtotal)
	local count = math.random(1, reward[chance2].amount)
	local canCarry = exports.vorp_inventory:canCarryItem(_source, reward[chance2].name, count)
	if not canCarry then
		return Core.NotifyObjective(_source, T.NotifyLabels.fullBag .. reward[chance2].label, 5000)
	end

	exports.vorp_inventory:addItem(_source, reward[chance2].name, count)
	Core.NotifyObjective(_source, T.NotifyLabels.yourGot .. reward[chance2].label, 3000)
end)


AddEventHandler('playerDropped', function()
	local _source = source
	-- player left the server, remove from mining table if it was mining
	if mining_rocks[_source] then
		mining_rocks[_source] = nil
	end
end)
