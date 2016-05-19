
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

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

local itemHandler = object.itemHandler

BotEcho('loading monkeyking_main...')

object.heroName = 'Hero_MonkeyKing'

local heroWeight = 3
--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}



--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.dash = unitSelf:GetAbility(0)
    skills.pole = unitSelf:GetAbility(1)
    skills.rock = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.dash and skills.pole and skills.rock and skills.ulti and skills.attributeBoost then
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
  elseif skills.dash:CanLevelUp() then
    skills.dash:LevelUp()
  elseif skills.pole:CanLevelUp() then
    skills.pole:LevelUp()
  elseif skills.rock:CanLevelUp() then
    skills.rock:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end


behaviorLib.StartingItems = {"Item_HealthPotion", "Item_ManaPotion", "Item_MinorTotem", "Item_RunesOfTheBlight", "Item_LoggersHatchet"}
behaviorLib.LaneItems = {"Item_Bottle", "Item_Energizer",}
behaviorLib.MidItems = {"Item_EnhancedMarchers", "Item_Dawnbringer", "Item_PowerSupply"}
behaviorLib.LateItems = {"Item_DaemonicBreastplate", "Item_Protect"}


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


  if skills.rock:CanActivate() then
    nUtility = nUtility + 20
  end


  if skills.dash:CanActivate() then
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


local function selectTargetForSkill(skill, angle)
	local range = skill:GetRange()
	local enemyHero = findNearestHero(angle)

	if enemyHero then
		local distToEnemy = myDistanceTo(enemyHero)


		if distToEnemy < range then
			return enemyHero
		end
	end


	--[[BotEcho('enemy hero is null or distant')--]]



	local enemyCreep = findNearestEnemyCreep(angle)

	if enemyCreep then
		local distToEnemy = myDistanceTo(enemyCreep)

		if distToEnemy < range then
			return enemyHero
		end
	end

	
	--[[BotEcho('enemy creep is null or distant')--]]

	return nil


end 

local function DashBehaviorUtility(botBrain)

	

	if not skills.dash or not skills.dash:CanActivate() then
		return 0
	end
	
	local target = selectTargetForSkill(skills.dash, pi / 4)

	if target then
		BotEcho('DashBehaviorUtility')
		return 100
	end


	return 0

end





local function DashBehaviorExecute(botBrain)
	--[[BotEcho('DashBehaviorExecute')--]]
	local target = selectTargetForSkill(skills.dash, pi / 4)
	local dash = skills.dash


	if dash and dash:CanActivate() and target then
	
		return core.OrderAbility(botBrain, dash)	

	end

	return false
end

dashBehavior = {}
dashBehavior["Utility"] = DashBehaviorUtility
dashBehavior["Execute"] = DashBehaviorExecute
dashBehavior["Name"] = "Dashing"
tinsert(behaviorLib.tBehaviors, dashBehavior)

local rockThresh = 4

local function RockBehaviorUtility(botBrain)

	if not skills.rock or not skills.rock:CanActivate() then
		return 0
	end
	--[[BotEcho('RockBehaviorUtility')
	BotEcho('Range: ')
	BotEcho(skills.rock:GetTargetRadius())--]]
	local count = enemyCount(skills.rock:GetTargetRadius())
	--[[
	BotEcho('Enemy count '); 
	BotEcho(count); --]]
	if count >= rockThresh then
		return 30 * count
	end




	return 0

end

local function RockBehaviorExecute(botBrain)
  local rock = skills.rock


	if rock and rock:CanActivate() then
	
		return core.OrderAbility(botBrain, rock)	

	end

	return false
end

rockBehavior = {}
rockBehavior["Utility"] = RockBehaviorUtility
rockBehavior["Execute"] = RockBehaviorExecute
rockBehavior["Name"] = "Rock"
tinsert(behaviorLib.tBehaviors, rockBehavior)

local function selectTargetHero(skill, minDist) 

	if not skill or not skill:CanActivate() then
		return nil
	end

	local enemyHero = findNearestHero(pi)

	local range = skill:GetRange()


	if enemyHero then
		local distToEnemy = myDistanceTo(enemyHero)


		if distToEnemy < range and distToEnemy > minDist then
			return enemyHero
		end
	end

	return nil
end 


local function PoleBehaviorUtility(botBrain) 
	local pole = skills.pole

	local target = selectTargetHero(pole, 150)

	if target then
	
		return 100

	end

	return 0
	

end

local function PoleBehaviorExecute(botBrain) 
	local pole = skills.pole

	local target = selectTargetHero(pole, 150)

	if target then
		return core.OrderAbilityEntity(botBrain, pole, target)
	end

	return false

end


poleBehavior = {}
poleBehavior["Utility"] = PoleBehaviorUtility
poleBehavior["Execute"] = PoleBehaviorExecute
poleBehavior["Name"] = "Pole"
tinsert(behaviorLib.tBehaviors, poleBehavior)



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

BotEcho('finished loading monkeyking_main')
