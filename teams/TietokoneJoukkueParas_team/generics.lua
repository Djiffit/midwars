local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

object.generics = {}
local generics = object.generics

BotEcho("loading default generics ..")

--count used slots in stash
local function StashSlots(inventory)
  local open = 0
  for slot = 7, 12, 1 do
    iteminSlot = inventory[slot]
    if iteminSlot == nil then
      open = open + 1
    end
  end
  return open
end


--Check if should send itemssssses
local function CourierUtility(botBrain)
  local inventory = core.unitSelf:GetInventory(true)
  local slots = StashSlots(inventory)
  for id,unit in pairs (HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 10012000, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)) do
    local name = unit:GetTypeName()
    local id = unit:GetOwnerPlayerID()
    if name == "Pet_AutomatedCourier" and id == core.unitSelf:GetOwnerPlayerID() then 
      return 0
    end

 end
  if slots ~= 6 then 
    return 100
  end
  return 0
end

local function CourierExecute(botBrain)
  return core.OrderAbility(botBrain, core.unitSelf:GetAbility(12), false)
end


local CourierBehavior = {}
CourierBehavior["Utility"] = CourierUtility
CourierBehavior["Execute"] = CourierExecute
CourierBehavior["Name"] = "Courier"
tinsert(behaviorLib.tBehaviors, CourierBehavior)

--Shopping BEHAVIOUR !! ! ! ! ! !
local function ShopUtilityOverride(botBrain)
  behaviorLib.DetermineBuyState(botBrain)
  local nextItemBought = behaviorLib.DetermineNextItemDef(botBrain)
  if nextItemBought and core.unitSelf:GetItemCostRemaining(nextItemBought) > 0 and botBrain:GetGold() > core.unitSelf:GetItemCostRemaining(nextItemBought) and StashSlots(core.unitSelf:GetInventory(true)) > 0  then  
    return 99.9
  end
  return 0
end

local function ShopExecuteOverride(botBrain) 
    if behaviorLib.nextBuyTime > HoN.GetGameTime() then
		return
	end

	behaviorLib.nextBuyTime = HoN.GetGameTime() + behaviorLib.buyInterval

	--Determine where in the pattern we are (mostly for reloads)
	if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
		behaviorLib.DetermineBuyState(botBrain)
	end
	
	local unitSelf = core.unitSelf
	local bShuffled = false
	local bGoldReduced = false
	local tInventory = core.unitSelf:GetInventory(true)
	local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
	local bBuyTPStone = false
	local bBuyTPStone = false
	local bBuyTPStone = false 

	if nextItemDef ~= nil then
		core.teamBotBrain.bPurchasedThisFrame = true
		
		--open up slots if we don't have enough room in the stash + inventory
		local componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
		local slotsOpen = behaviorLib.NumberSlotsOpen(tInventory)


		if #componentDefs > slotsOpen + 1 then --1 for provisional slot
			behaviorLib.SellLowestItems(botBrain, #componentDefs - slotsOpen - 1)
		elseif #componentDefs == 0 then
			behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
		end

		local nGoldAmountBefore = botBrain:GetGold()
		
		if nextItemDef ~= nil and unitSelf:GetItemCostRemaining(nextItemDef) < nGoldAmountBefore then
			unitSelf:PurchaseRemaining(nextItemDef)
		end

		local nGoldAmountAfter = botBrain:GetGold()
		bGoldReduced = (nGoldAmountAfter < nGoldAmountBefore)

		--Check to see if this purchased item has uncombined parts
		componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
		if #componentDefs == 0 then
			behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
		end
		behaviorLib.addItemBehavior(nextItemDef:GetName())
	end
	bShuffled = behaviorLib.SortInventoryAndStash(botBrain)
end

behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride
behaviorLib.ShopBehavior["Execute"] = ShopExecuteOverride



-- isClose() returns true if target is near
local function isClose(target)
	
	local unitSelf = core.unitSelf

	local a = unitSelf:GetPosition()
	local b = target:GetPosition()

	if a == nil or b == nil then

		return false

	end

	return Vector3.Distance2D(a, b) < 500

end

-- isAliveEnemyHero() returns true if and only if target is enemy hero and alive
local function isAliveEnemyHero(target)

	if not target then 

		return false

	end

	return target:IsHero() and target:IsAlive() and target:GetTeam() == core.enemyTeam
	
end

-- setAsTeamTargetHeroIfOk() sets parameter target as team's target if the target is ok
local function setAsTeamTargetHeroIfOk(target) 

	local teamBotBrain = core.teamBotBrain



	if not teamBotBrain or not teamBotBrain.SetTeamTarget then
		return
	end

	if isAliveEnemyHero(target) and isClose(target) then
		
		BotEcho('Setting hero as target for the team')
		teamBotBrain:SetTeamTarget(target)

	end
end


onCombatEventOld = object.oncombatevent

local function onCombatEventCustom(botBrain, EventData)


	onCombatEventOld(botBrain, EventData)


	-- Setting target hero for the team 
	local source = EventData.SourceUnit
	local target = EventData.TargetUnit

	setAsTeamTargetHeroIfOk(source)
	setAsTeamTargetHeroIfOk(target)

end



local ProcessKillOld = behaviorLib.ProcessKill
local function ProcessKillOverride(unit)
  ProcessKillOld(unit)
  local teamBotBrain = core.teamBotBrain
  if teamBotBrain.GetTeamTarget then
    teamBotBrain:SetTeamTarget(nil)
  end
end
behaviorLib.ProcessKill = ProcessKillOverride






object.oncombatevent = onCombatEventCustom

local function GetDistanceToClosestEnemyTower()
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local actionTaken = false
  local enemyTowers = core.enemyTowers
  local closestEnemyTowerDistance = -1
  for _, enemyTower in pairs(enemyTowers) do
    local enemyTowerDistance = Vector3.Distance2DSq(myPos, enemyTower:GetPosition())
    if (closestEnemyTowerDistance == -1 or enemyTowerDistance < closestEnemyTowerDistance) then
      closestEnemyTowerDistance = enemyTowerDistance
    end
  end
  return closestEnemyTowerDistance
end

local function enemyHeroClosestToAllyTower(botBrain, distance)
  local enemyHeroesNearby = core.CopyTable(core.localUnits["EnemyHeroes"])
  local allyTowers = core.CopyTable(core.allyTowers)
  local closestHero
  local closestDistance = -1
  for _, enemyHero in pairs(enemyHeroesNearby) do
    for _, tower in pairs(allyTowers) do
      local towerPos = tower:GetPosition()
      local heroPos = enemyHero:GetPosition()
      local enemyHeroDistanceToTower = Vector3.Distance2DSq(towerPos, heroPos)
      if enemyHeroDistanceToTower < distance*distance and (closestDistance == -1 or enemyHeroDistanceToTower < closestDistance) then
        closestHero = enemyHero
        closestDistance = enemyHeroDistanceToTower
      end
    end
  end
  return closestHero
end



local function CountLocalHeroesHealth() 

	local count = 0
	local tLocalAllyHeroes = core.CopyTable(core.localUnits["AllyHeroes"])

	for _, unitHero in pairs(tLocalAllyHeroes) do
	

		count = count + unitHero:GetHealthPercent()




	end

	return count



end


local function CountLocalEnemyHeroesHealth() 

	local count = 0
	local tLocalEnemyHeroes = core.CopyTable(core.localUnits["EnemyHeroes"])

	for _, unitHero in pairs(tLocalEnemyHeroes) do
	

		count = count + unitHero:GetHealthPercent()


	end

	return count



end



local HarassHeroUtilityOld = behaviorLib.HarassHeroBehavior["Utility"]
local function TeamHarassHeroUtility(botBrain)
  local me = core.unitSelf
  local teamBotBrain = core.teamBotBrain
  local enemyHeroCloseToAllyTower = enemyHeroClosestToAllyTower(botBrain, 600)
  if enemyHeroCloseToAllyTower and me:GetHealthPercent() > 0.3 then
    Echo("begin ally tower harass")
    return 80
  end
  if GetDistanceToClosestEnemyTower() < 1000*1000 then
    Echo("don't harass close to enemy tower")
    return 0
  end
  if teamBotBrain.GetTeamTarget then
    local target = teamBotBrain:GetTeamTarget()
    if target then
	
      local util = 100 * (0.9 * CountLocalHeroesHealth() - CountLocalEnemyHeroesHealth()) / 2
      BotEcho("found team target util: " .. util)
      behaviorLib.lastHarassUtil = util
      behaviorLib.heroTarget = target
      return util
    end
    return 0
  end
  Echo("running old behavior")
  return HarassHeroUtilityOld(botBrain)
end
behaviorLib.HarassHeroBehavior["Utility"] = TeamHarassHeroUtility



local UseRunesOfTheBlightUtilityOld = behaviorLib.UseRunesOfTheBlightUtility
local function TeamUseRunesOfTheBlightUtility(botBrain)
  return 0
end
behaviorLib.UseRunesOfTheBlightUtility = TeamUseRunesOfTheBlightUtility


local function PassiveState()
  local tLane = core.tMyLane
  if tLane then
    local creepPos = core.GetFurthestCreepWavePos(tLane, core.bTraverseForward)
    local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
    local myTower = core.GetClosestAllyTower(enemyBasePos)
    local towerPos = myTower:GetPosition()
    local enemyTower = core.GetClosestEnemyTower(towerPos)
    local otherTowerPos = enemyTower:GetPosition()
    local distanceAlly = Vector3.Distance2D(creepPos, towerPos)
    local distanceEnemy = Vector3.Distance2D(creepPos, otherTowerPos)
    --BotEcho("DA:"..distanceAlly..";DE:"..distanceEnemy)
    if distanceEnemy < 2300 and  distanceAlly < 2300 then
      return true
    end
  end
  return false
end


local function FurthestPositionEarlyAdjust(position)
  if PassiveState() then


    local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
    local myTower = core.GetClosestAllyTower(enemyBasePos)

    local towerPos = myTower:GetPosition()
    
    local factor = 1

    if string.find(object.myName, "Valkyrie") or string.find(object.myName, "Nymphora") or string.find(object.myName, "PuppetMaster") then
       factor = 0.7
    end

    local offset = Vector3.Normalize(enemyBasePos - towerPos) * 220 * CountLocalHeroesHealth() * factor
    

    local middlePos = towerPos + offset
    local vector = middlePos - towerPos


    local pos1 = towerPos + core.RotateVec2D(vector, -10)
    local pos2 = towerPos + core.RotateVec2D(vector, 10)
    local wantedVec = pos1 - pos2
    local wantedPos = pos2 + wantedVec * core.RandomReal()
    return wantedPos
  end
  return position
end

local PositionSelfLogicOld = behaviorLib.PositionSelfLogic
local function PositionSelfLogicOverride(botBrain)
  return FurthestPositionEarlyAdjust(PositionSelfLogicOld(botBrain))
end
behaviorLib.PositionSelfLogic = PositionSelfLogicOverride

local skillshot_spots_file = "/bots/teams/default/metadata/skillshot_spots.botmetadata"
local function RegisterSkillshots()
  if not metadata.tMetadataFileNames[skillshot_spots_file] then
    metadata.tMetadataFileNames[skillshot_spots_file] = true
    BotEcho("Trying to register \""..skillshot_spots_file.."\"")
    BotMetaData.RegisterLayer(skillshot_spots_file)
  end
end

function generics.GetOwnSkillshotSpots()
  metadata.SetActiveLayer(skillshot_spots_file)
  local tNodes = BotMetaData.GetAllNodes()
  metadata.SetActiveLayer(metadata.MapMetadataFile)
  local tOwnNodes = {}
  local team = nil
  if core.myTeam == HoN.GetLegionTeam() then
    team = "legion"
  else
    team = "hellbourne"
  end
  for _, node in pairs(tNodes) do
    if node:GetProperty("zone") == team then
      tinsert(tOwnNodes, node)
    end
  end
  return tOwnNodes
end

--[[
local function TeamAvoidHookUtility(botBrain)
  local enemyHeroesNearby = core.CopyTable(core.localUnits["EnemyHeroes"])
  for _, hero in pairs(enemyHeroesNearby) do

  end
  return 0
end

local function TeamAvoidHookExecute(botBrain)

end

local AvoidHookBehavior = {}
AvoidHookBehavior["Utility"] = TeamAvoidHookUtility
AvoidHookBehavior["Execute"] = TeamAvoidHookExecute
AvoidHookBehavior["Name"] = "AvoidHook"
tinsert(behaviorLib.tBehaviors, AvoidHookBehavior)
]]

