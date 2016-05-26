local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true

object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"
runfile "bots/teams/TietokoneJoukkueParas_team/generics.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading puppetmaster_main...')

object.heroName = 'Hero_PuppetMaster'


behaviorLib.StartingItems = {"3 Item_MinorTotem", "Item_PretendersCrown", "Item_ManaBattery"}
behaviorLib.EarlyItems = {}
behaviorLib.MidItems = {"Item_PowerSupply", "Item_Bottle", "Item_Strength5", "Item_Astrolabe"}
behaviorLib.LateItems = {}

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.hold = unitSelf:GetAbility(0)
    skills.show = unitSelf:GetAbility(1)
    skills.whip = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.courier = core.unitSelf:GetAbility(12)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.hold and skills.show and skills.whip and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  if skills.ulti:CanLevelUp() then
    skills.ulti:LevelUp()
  elseif skills.whip:CanLevelUp() then
    skills.whip:LevelUp()
  elseif skills.hold:CanLevelUp() then
    skills.hold:LevelUp()
  elseif skills.show:CanLevelUp() then
    skills.show:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end

end

local heroWeight = 3

local function myDistanceTo(unitEnemy) 

	local myPos = core.unitSelf:GetPosition()
	local enemyPos = unitEnemy:GetPosition()

	return Vector3.Distance2D(enemyPos, myPos)

end



local function allyCount(range)
	local count = 0
	local tLocalEnemyCreeps = core.CopyTable(core.localUnits["AllyCreeps"])
	local tLocalEnemyHeroes = core.CopyTable(core.localUnits["AllyHeroes"])

	for _, unitEnemy in pairs(tLocalEnemyHeroes) do
		if myDistanceTo(unitEnemy) < range then
			count = count + heroWeight
		end
	end

	for _, unitEnemy in pairs(tLocalEnemyCreeps) do
		if myDistanceTo(unitEnemy) < range then
			count = count + 1
		end
	end
	return count
end



local function enemyCount(range)
	local count = 0
	local tLocalEnemyCreeps = core.CopyTable(core.localUnits["EnemyCreeps"])
	local tLocalEnemyHeroes = core.CopyTable(core.localUnits["EnemyHeroes"])

	for _, unitEnemy in pairs(tLocalEnemyHeroes) do
		if myDistanceTo(unitEnemy) < range then
			count = count + heroWeight
		end
	end

	for _, unitEnemy in pairs(tLocalEnemyCreeps) do
		if myDistanceTo(unitEnemy) < range then
			count = count + 1
		end
	end
	return count
end










local function CustomHarassUtilityOverride(hero)
	local unitSelf = core.unitSelf
	local myHealth = unitSelf:GetHealthPercent()
	local otherHealth = hero:GetHealthPercent()
	local allyCount = allyCount(600)
	local enemyCount = enemyCount(600)

  local nUtility = 20 * myHealth + allyCount - enemyCount


	if 0.8 * myHealth > otherHealth then

		nUtility = nUtility + 20

	end

	if myHealth < 0.6 * otherHealth then

		nUtility = nUtility - 50

	end

  if core.GetClosestEnemyTower(unitSelf:GetPosition(), 600) and allyCount < heroWeight + 1 then
    nUtility = nUtility - 150
  end


  if hero:IsChanneling() or hero:IsDisarmed() or hero:IsImmobilized() or hero:IsPerplexed() or hero:IsSilenced() or hero:IsStunned() or unitSelf:IsStealth() then
    nUtility = nUtility + 20
  end


  if skills.hold:CanActivate() then
    nUtility = nUtility + 20
  end


  if skills.whip:CanActivate() then
    nUtility = nUtility + 30
  end

  if skills.ulti:CanActivate() then
    nUtility = nUtility + 50
  end

  return nUtility

end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride



local function findNearestHero(angle) 
	local tLocalEnemyHeroes = core.CopyTable(core.localUnits["EnemyHeroes"])
	local dist = 999999999

	local found = nil

	for _, unitEnemy in pairs(tLocalEnemyHeroes) do
		
		local distToEnemy = myDistanceTo(unitEnemy)
	    	    	    
		local angleDiff = core.HeadingDifference(core.unitSelf, unitEnemy:GetPosition())
		
		if dist > distToEnemy and angleDiff < angle then

			dist = distToEnemy
			found = unitEnemy
	    
		end

	end

	return found

end




local function findNearestEnemyCreep(angle) 
	local tLocalEnemyCreeps = core.CopyTable(core.localUnits["EnemyCreeps"])
	local dist = 999999999
	local found = nil
	for _, unitEnemy in pairs(tLocalEnemyCreeps) do
		

	local distToEnemy = myDistanceTo(unitEnemy)
	local angleDiff = core.HeadingDifference(core.unitSelf, unitEnemy:GetPosition())
		
		if dist > distToEnemy and angleDiff < angle then

			dist = distToEnemy
			found = unitEnemy
    
    		end

	end

	return found

end




local function HoldBehaviorUtility(botBrain)

	local enemyHero = findNearestHero(pi)
	if not enemyHero then
		return 0
	end

	
	local dist = myDistanceTo(enemyHero)
	local hold = skills.hold

	if hold and hold:CanActivate() and dist < hold:GetRange() then
		--BotEcho('Hold')
		return 60

	end
	
	return 0


end

local function HoldBehaviorExecute(botBrain)
	

	local enemyHero = findNearestHero(pi)
	if not enemyHero then
		return false
	end


	local dist = myDistanceTo(enemyHero)
	local hold = skills.hold

	--[[
	BotEcho('Distance to hero: ' .. dist)
	BotEcho('Range: ' .. hold:GetRange())

	--]]
	if hold and hold:CanActivate() and dist < hold:GetRange()  then
		--BotEcho('Hold execute')
		return core.OrderAbilityEntity(botBrain, hold, enemyHero)

	end
	
	return false



end


holdBehavior = {}
holdBehavior["Utility"] = HoldBehaviorUtility
holdBehavior["Execute"] = HoldBehaviorExecute
holdBehavior["Name"] = "Hold"
tinsert(behaviorLib.tBehaviors, holdBehavior)




local function ShowBehaviorUtility(botBrain)

	local enemyHero = findNearestHero(pi)
	if not enemyHero then
		return 0
	end



	local dist = myDistanceTo(enemyHero)
	local show = skills.show
	--[[
	BotEcho('Distance to hero: ' .. dist)
	BotEcho('Range: ' .. show:GetRange())
	

	BotEcho('show')
	--]]
	if show and show:CanActivate() and dist < show:GetRange() then
		
		return 70

	end
	
	return 0


end

local function ShowBehaviorExecute(botBrain)
	

	local enemyHero = findNearestHero(pi)
	if not enemyHero then
		return false
	end


	local dist = myDistanceTo(enemyHero)
	local show = skills.show
	--[[BotEcho('Distance to hero: ' .. dist)--]]
	--[[BotEcho('Range: ' .. show:GetRange())--]]
	if show and show:CanActivate() and dist < show:GetRange()  then
		--[[BotEcho('show execute')--]]
		return core.OrderAbilityEntity(botBrain, show, enemyHero)

	end
	
	return false
end

showBehavior = {}
showBehavior["Utility"] = ShowBehaviorUtility
showBehavior["Execute"] = ShowBehaviorExecute
showBehavior["Name"] = "show"
tinsert(behaviorLib.tBehaviors, showBehavior)

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

BotEcho('finished loading puppetmaster_main')
