local function isSpear(item)
        return item and item:getCategory() == 'Weapon' and  WeaponType.getWeaponType(item) == WeaponType.spear
end


-- find a spear in your inventory excluding those that are broken, equipped, or attached to a slot (ie back)
local function find_spear_in_inventory(player)
	local playerInv = player:getInventory():getItems()
	for i=0, playerInv:size()-1 do
		local item = playerInv:get(i)
		local attached_slot = item:getAttachedSlot()
		if isSpear(item) and attached_slot ~= 1 and not item:isEquipped() and not item:isBroken() then
				return item
		end
	end
end


local function find_broken_spear_in_inventory(player)
	local playerInv = player:getInventory():getItems()
	for i=0, playerInv:size()-1 do
		local item = playerInv:get(i)
		if isSpear(item) and item:isBroken() then
			return item
		end
	end
end


local function get_equipped_backpack(player)
	local playerInv = player:getInventory():getItems()
	for i=0, playerInv:size()-1 do
		local item = playerInv:get(i)
		category = item:getCategory()
		if category == 'Container' then
			isBack = item:canBeEquipped() == 'Back'
			isEquipped = item:isEquipped()

			if isBack and isEquipped then
				return item
			end
		end
	end
end


local function get_equipped_inventory_containers(player)
    local containers = {}
    local inv = player:getInventory()
    local items = inv:getItems()

	for i=0, items:size()-1 do
		local item = items:get(i)
		local category = item:getCategory()
		local isEquipped = item:isEquipped()

		if category == 'Container' and isEquipped then
            containers.insert(item)
		end
	end

	return containers
end



-- The spear is attached to teh back slot in the same way the shovel is.
-- There are two slots currently "Shovel Back" and "Shovel Back with bag", depending on if a back p[ack is attached
-- this function will try any slot that has Shovel Back in the title and return the first result
local function get_back_slot_spear(player)
	local back_slots = {}
	for i=0,player:getAttachedItems():getGroup():size()-1 do
		local slot_id = player:getAttachedItems():getGroup():getLocationByIndex(i):getId()
		if string.find(slot_id, "Shovel Back") then
			local item = player:getAttachedItem(slot_id)
			if item and isSpear(item) then
				return item
			end
		end
	end
end


-- When a spear breaks, drop it and grab the one in your back slot
local function swapSpears(player, weapon)

	-- This is a hack because there is no BrokenItem event AFAIK.  When a spear breaks during an attack, weapon returns
	-- as nil in the OnPlayerAttackFinished event (I've never observed a nil value in any other circumstance) .
	-- When this happens, check for the presence of a broken spear
	-- and if we find one, then we assume a broken spear just occurred.
	if not weapon then
		broken_spear = find_broken_spear_in_inventory(player)
		if broken_spear then
			ISTimedActionQueue.add(ISDropItemAction:new(player, broken_spear, 0))

          	local attached_item = get_back_slot_spear(player)
		    if attached_item then
			    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, attached_item, 2, true, true))
			end
		end
	end
end
Events.OnPlayerAttackFinished.Add(swapSpears)

-- Take one spear from main inventory and equip it to the back slot
local function reloadSpearFromInventory(keynum)
  if keynum == 19 then
	local player = getPlayer()
	local item = player:getPrimaryHandItem()
        if isSpear(item) then

    		local back_attached_item = get_back_slot_spear(player)

		    if not back_attached_item then
  			    local new_spear = find_spear_in_inventory(player)
			    if new_spear then

					-- Another hack.  I cant figure out how to identify which slot to use programmatically so i
					-- just look for a backpack and determine which slot to use that way.  Need to look into hotbar
					local slot
					if get_equipped_backpack(player) then
					    slot = "Shovel Back with Bag"
				    else
					    slot = "Shovel Back"
				    end

				    ISTimedActionQueue.add(ISAttachItemHotbar:new(player, new_spear, slot , 1, 'Back'))
			    end
		    end
	    end
  end
end
Events.OnKeyPressed.Add(reloadSpearFromInventory)


---------------------------------------------------------------------------------------------------------

-- Not Implemented
local function reloadSpearFromBackpack(keynum)
    if keynum == 19 then
        local player = getPlayer()
        tab = get_equipped_inventory_containers(player)
    end
end
-- Events.OnKeyKeepPressed.Add(reloadSpearFromBackpack)

-- break spears faster for testing
local function degradeSpear(player, weapon)
	if weapon and  weapon:getCondition() > 1 then
		weapon:setCondition(1)
	end
end
-- Events.OnPlayerAttackFinished.Add(degradeSpear)
