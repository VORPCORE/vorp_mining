VorpInv = exports.vorp_inventory:vorp_inventoryApi()

local VorpCore = {}

TriggerEvent("getCore",function(core)
    VorpCore = core
end)

RegisterServerEvent("vorp_mining:pickaxecheck")
AddEventHandler("vorp_mining:pickaxecheck", function(rock)
	math.randomseed(os.time())
	local _source = source
	local miningrock = rock
	local pickaxe = VorpInv.getItem(_source, Config.Pickaxe)
	if pickaxe ~= nil then
		local meta =  pickaxe["metadata"]
		if next(meta) == nil then 
			VorpInv.subItem(_source, Config.Pickaxe, 1,{})
			VorpInv.addItem(_source, Config.Pickaxe, 1,{description = "Durability = 98",durability = 99})
			TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
		else
			local durability = meta.durability - 1
			local description = "Durability = "
			VorpInv.subItem(_source, Config.Pickaxe, 1,meta)
			if 0 >= durability then 
				local random = math.random(1,2)
				if random == 1 then 
					TriggerClientEvent("vorp:TipRight", _source, "Your pickaxe broke", 2000)
					TriggerClientEvent("vorp_mining:nopickaxe", _source)
				else
					VorpInv.addItem(_source, Config.Pickaxe, 1,{description = description.."1",durability = 1})
					TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
				end
			else
				VorpInv.addItem(_source, Config.Pickaxe, 1,{description = description..durability,durability = durability})
				TriggerClientEvent("vorp_mining:pickaxechecked", _source, miningrock)
			end
		end
	else
		TriggerClientEvent("vorp_mining:nopickaxe", _source)
		TriggerClientEvent("vorp:TipRight", _source, "You don't have a pickaxe", 2000)
	end
end)

local keysx = function(table)
    local keys = 0

    for k,v in pairs(table) do
       keys = keys + 1
    end

    return keys
end

RegisterServerEvent('vorp_mining:addItem')
AddEventHandler('vorp_mining:addItem', function()
	--math.randomseed(os.time()) -- why s this even here? 
	local _source = source
	--local Character = VorpCore.getUser(_source).getUsedCharacter -- why is this even here ?
	local chance =  math.random(1,20)
	local reward = {}
	for k,v in pairs(Config.Items) do 
		if v.chance >= chance then
			table.insert(reward,v)
		end
	end

        local randomtotal = keysx(reward) -- localize 
	if randomtotal == 0 then -- if 0 add at least 1 or maybe do a return
		--randomtotal = 1 -- ensure its not 0 so it doesnt throw error, you can uncomment so players get at least one 
           return -- dont run amount is 0 , comment if the top one is uncommented
	end
	local chance2 = math.random(1,amount2) -- if 0 the interval will be empty since minimum is 1
	local count = math.random(1,reward[chance2].amount)
	TriggerEvent("vorpCore:canCarryItems", tonumber(_source), count, function(canCarry)
		TriggerEvent("vorpCore:canCarryItem", tonumber(_source), reward[chance2].name,count, function(canCarry2)
			if canCarry and canCarry2 then
				VorpInv.addItem(_source, reward[chance2].name, count)
				TriggerClientEvent("vorp:TipRight", _source, "You found "..reward[chance2].label, 3000)
			else
				TriggerClientEvent("vorp:TipRight", _source, "You can't carry any more "..reward[chance2].label, 3000)
			end
		end)
	end) 
end)
