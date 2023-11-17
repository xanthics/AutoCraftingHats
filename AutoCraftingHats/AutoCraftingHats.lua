local _, ACH = ...
ACH.__index = ACH

local AceTimer = LibStub('AceTimer-3.0')

ACH.frame = CreateFrame("Frame") -- used to track events
ACH.tradeOpen = false
ACH.originalGear = {}
ACH.grabqueue = {}
ACH.equipqueue = {}

ACH.vanityHats = {
--	["Herbalism"] = {1004000, "Herbalist's Hat"},
	["Smelting"] = {1004001, "Miner's Hat"},
--	["Skinning"] = {1004002, "Skinner's Hat"},
	["Alchemy"] = {1004003, "Alchemist's Hat"},
	["Blacksmithing"] = {1004004, "Blacksmith's Hat"},
	["Enchanting"] = {1004006, "Enchanter's Hat"},
	["Engineering"] = {1004007, "Engineer's Goggles"},
	["Jewelcrafting"] = {1004011, "Jewelcrafter's Hat"},
	["Leatherworking"] = {1004012, "Leatherworker's Hat"},
	["Tailoring"] = {1004013, "Tailor's Hat"},
	["Cooking"] = {1004017, "Chef's Hat"},
	["First Aid"] = {1004014, "Field Medic's Hat"},
}
ACH.vanityItems = {
	{97769, "Battleplate of the Master Crafter"},
	{97770, "Belt of the Master Crafter"},
	{97842, "Boots of the Master Crafter"},
	{97851, "Bracers of the Master Crafter"},
--	{97852, "Faceguard of the Master Crafter"},
	{97853, "Guantlets of the Master Crafter"},
	{97854, "Greaves of the Master Crafter"},
	{97855, "Mantle of the Master Crafter"},
	{174069, "Artisan's Guild Tabard"},
}

function ACH:FindEmptyBag() 
	local empty = 0
	for bagID=1,5 do
		local numberOfFreeSlots, BagType = GetContainerNumFreeSlots(bagID)
		if numberOfFreeSlots > 0 and BagType == 0 then
			empty = empty + numberOfFreeSlots
		end
	end
	return empty
end

function AceTimer:GetGear()
	AceTimer:ScheduleTimer("ProcessGetGear", 1)
end

function AceTimer:ProcessGetGear()
	if ACH:FindEmptyBag() > 0 then
		RequestDeliverVanityCollectionItem(ACH.grabqueue[#ACH.grabqueue])
	end

	ACH.grabqueue[#ACH.grabqueue] = nil

	if #ACH.grabqueue > 0 then
		AceTimer:ScheduleTimer("GetGear", 1)
	else
		AceTimer:ScheduleTimer("EquipGear", .5)
	end
end

function AceTimer:EquipGear()
	for _,id in ipairs(ACH.equipqueue) do
		EquipItemByName(id)
	end
--	AceTimer:DestroyVanity()
end

function AceTimer:DestroyVanity()
	AceTimer:ScheduleTimer("DestroyItems", .5)
end

-- destroy a vanity item we don't need anymore
function AceTimer:DestroyItems()
	local vanitylist = {}
	for _,data in pairs(ACH.vanityHats) do
		vanitylist[data[1]] = true
	end
	for _,data in ipairs(ACH.vanityItems) do
		vanitylist[data[1]] = true
	end
	vanitylist[1004001] = nil -- keep mining hat
	-- scan bag
	for bag=0, 4 do
		for slot=1, GetContainerNumSlots(bag) do
			local inventoryLink = GetContainerItemLink(bag, slot)
			if inventoryLink then
				local _, _, id, name = string.find(inventoryLink, "^.-|Hitem:(%d+).-%[(.-)%]")
				if id and vanitylist[tonumber(id)] then
					ClearCursor()
					PickupContainerItem(bag, slot)
					DeleteCursorItem()
				end
			end
		end
	end	
end

-- check if we already have an item
function ACH:HasItem(itemid, itemname)
	-- scan player
	if itemname and IsEquippedItem(itemname) then
		return true, false
	else
		for i=1,19 do
			local inventoryLink = GetInventoryItemLink("player", i)
			if inventoryLink then
				local _, _, id, name = string.find(inventoryLink, "^.-|Hitem:(%d+).-%[(.-)%]")
				if id and tonumber(id) == itemid then
					return true, false
				end
			end
		end
	end
	-- scan bag
	for bag=0, 4 do
		for slot=1, GetContainerNumSlots(bag) do
			local inventoryLink = GetContainerItemLink(bag, slot)
			if inventoryLink then
				local _, _, id, name = string.find(inventoryLink, "^.-|Hitem:(%d+).-%[(.-)%]")
				if id and tonumber(id) == itemid then
					return true, true
				end
			end
		end
	end
	-- item not found
	return false
end



-- called when a tradeskill window is opened
function ACH:EquipItems(craft)
	ACH.grabqueue = {}
	ACH.equipqueue = {}
	

	-- check if we have the item already, otherwise if we own the item get it
	for _,data in ipairs(ACH.vanityItems) do
		local id = data[1]
		if C_VanityCollection.IsCollectionItemOwned(id) then -- add logic for master crafter hat if vanity helm is owned
			if not ACH:HasItem(id) then
				ACH.grabqueue[#ACH.grabqueue+1] = id
			end
			ACH.equipqueue[#ACH.equipqueue+1] = id
		end
	end
	local hatid = ACH.vanityHats[craft][1]
	if C_VanityCollection.IsCollectionItemOwned(hatid) then
		if not ACH:HasItem(hatid) then
			ACH.grabqueue[#ACH.grabqueue+1] = hatid
		end
		ACH.equipqueue[#ACH.equipqueue+1] = hatid
	end
	AceTimer:GetGear()
end

-- At character login set up a command handler and our variables
function ACH:EventHandler(event, ...)
	self[event](self, event, ...)
end

-- check that addon variables are initialized
function ACH.frame:ADDON_LOADED(event, ...)
	self:UnregisterEvent("ADDON_LOADED")
	ACH.tradeOpen = false
	ACH.originalGear = {}
end

function ACH.frame:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, ...)
	-- if not an event we care about, bail
	if unit ~= "player" or not ACH.vanityHats[spell] then return end

	if not ACH.tradeOpen then
		ACH.originalGear = {}
		ACH.tradeOpen = true
		for i=1,19 do
			local inventoryLink = GetInventoryItemLink("player", i)
			if inventoryLink then
				local _, _, id, name = string.find(inventoryLink, "^.-|Hitem:(%d+).-%[(.-)%]")
				if id then
					ACH.originalGear[i] = id
				end
			else
				ACH.originalGear[i] = -1
			end
		end
	end
	ACH:EquipItems(spell)
end

-- called when there is no longer an open tradeskill window
function ACH.frame:TRADE_SKILL_CLOSE(event, ...)
	ACH.tradeOpen = false
	for slot, idold in pairs(ACH.originalGear) do
		if idold == -1 then
			local empty = ACH:FindEmptyBag()
			if empty > 0 then
				PickupInventoryItem(slot)
				PutItemInBackpack()
			end
		else
			local inventoryLink = GetInventoryItemLink("player", slot)
			if inventoryLink then
				local _, _, id, name = string.find(inventoryLink, "^.-|Hitem:(%d+).-%[(.-)%]")
				if id and id ~= idold then
					EquipItemByName(idold, slot)
				end
			else
				EquipItemByName(idold, slot)
			end
		end
	end
	ACH.originalGear = {}
	AceTimer:DestroyVanity()
end

-- Main
ACH.frame:RegisterEvent("ADDON_LOADED")
ACH.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
ACH.frame:RegisterEvent("TRADE_SKILL_CLOSE")
ACH.frame:SetScript("OnEvent", ACH.EventHandler)