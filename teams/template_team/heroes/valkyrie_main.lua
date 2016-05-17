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

object.bReportBehavior = true
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
object.nTime = 0

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
behaviorLib.LaneItems  = 
			{"Item_Bottle", "Item_Marchers", "Item_Pierce", "Item_Immunity"}
local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading valkyrie_main...')

object.heroName = 'Hero_Valkyrie'

object.nCallUp = 25
object.nArrowUp = 30
object.nLeapUp = 30
object.nUltUp = 15
object.nEnergUp = 10

-- Bonus agression points that are applied to the bot upon successfully using a skill/item
object.nCallUse = 35
object.nArrowUse = 40
object.nLeapUse = 10
object.nUltUse = 0
object.nEnergUse = 10

-- Thresholds of aggression the bot must reach to use these abilities
object.nCallThreshold = 30
object.nArrowThreshold = 25
object.nLeapThreshold = 95
object.nUltThreshold = 30
object.nEnergThreshold = 35
object.nNullThreshold = 45

-- tavarat


-- Skillbuildi
object.tSkills = {
	2, 1, 0, 0, 0,
	1, 0, 1, 1, 3, 
	3, 2, 2, 2, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4,
}
--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 2, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if skills.abilCall == nil then
    skills.call = unitSelf:GetAbility(0)
    skills.javelin = unitSelf:GetAbility(1)
    skills.leap = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
	return
  end

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  for i = nlev, nlev+nlevpts do
	unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
  end
 

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  if skills.ulti:CanLevelUp() then
    skills.ulti:LevelUp()
  elseif skills.javelin:CanLevelUp() then
    skills.javelin:LevelUp()
  elseif skills.leap:CanLevelUp() then
    skills.leap:LevelUp()
  elseif skills.call:CanLevelUp() then
    skills.call:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end
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

-- CHECK IF SOMETHING IS BLOCKING THE JAVELIN ( ARROW ) 
function NoObstructions(me, enemy, obstructions, size)
local bDebugLines = true
	local path = Vector3.Distance2DSq(me, enemy)
	for _, blocker in pairs(obstructions) do
		if blocker and Vector3.Distance2DSq(me, blocker) < path then
			if Vector3.Distance2DSq(core.unitSelf, vecTargetPosition) < (range*range) and NoObstructions(unitSelf:GetPosition(), vecTargetPosition, units, 110) then
				local point = core.GetFurthestPointOnLine(me:GetPosition(), me, enemy)
				local blockerRadius = blocker:GetBoundsRadius() * sqrt(2)
				local blockerradiussq = blockerRadius * blockerRadius
			
				if Vector3.Distance2DSq(candidate:GetPosition(), point) <= 1500+ blockerradiussq then
					return false
				end 
			end

		return true
		end
	end
end
	
local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil then
		return object.harassExecuteOld(botBrain)
	end
	
	
	if core.CanSeeUnit(botBrain, unitTarget) and skills.javelin:CanActivate() and unitTarget.storedPosition and unitTarget.lastStoredPosition then
		range = skills.javelin:GetRange()
		local targetspeed = unitTarget.storedPosition - unitTarget.lastStoredPosition
		local vecTargetPosition = unitTarget:GetPosition() + targetspeed
		local units = core.CopyTable(core.localUnits["AllyCreeps"])
		for key, unit in pairs(core.localUnits["EnemyCreeps"]) do
			units[key] = unit
		end
		for key, unit in pairs(core.localUnits["AllyHeroes"]) do
			units[key] = unit
		end
		
	
	return object.harassExecuteOld(botBrain)
end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride




function TurnTheShip(botBrain, vecHero, vecEnemy, nType)
	local unitSelf = core.unitSelf
	local nDelay = 300
	local vecNegEnemy = vecEnemy * -1
	local bActionTaken = false
	local nCurTime = 0
	object.nTime = HoN.GetGameTime()
	
	if nType == 0 then
		bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, vecEnemy)
	end
	if nType == 1 then
		bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, vecNegEnemy)
	end
	
	for nCurTime = HoN.GetGameTime(), object.nTime + 500 do
		if nCurTime - object.nTime >= nDelay then
			return true
		end
		nCurTime = HoN.GetGameTime()
	end
	
	return false
end





----------------------------------------------
-- Enemies nearby???? --
----------------------------------------------

function EnemiesNear(herolocation, enemies, range, style)
	local dangerarea = range
	local howmanyenemies = 0
	for index, danger in pairs(enemies) do
		local wheredanger = danger:GetPosition()
		if wheredanger then
			dangerproximity = math.sqrt(Vector3.Distance2DSq(herolocation, wheredanger))
		end
		if dangerproximity < dangerarea then
			howmanyenemies = howmanyenemies + 1
			if style == 0 then
				return true
			end
		end
	end
	if howmanyenemies >= 1 and style == 1 then
		return true
	elseif howmanyenemies >= 3 then
		return true
	end
	return false
end

--------------------------------------------------------------
-- Prism
--------------------------------------------------------------
function PrismUtility(botBrain)
	local nUtility = 0
	local ulti = skills.ulti
	local nBadIdea = 1

	if ulti:CanActivate() then
		local allies = HoN.GetHeroes(core.myTeam)
		for _, health in pairs(allies) do
			local low = health:GetHealthPercent()
			if low <= 0.2 and low > 0 then
				local allyposition = health:GetPosition()
				local enemies = HoN.GetHeroes(core.enemyTeam)
				if EnemiesNear(allyposition, enemies, 700, 0) then
					nUtility = 100
					return nUtility
				end
			end
		end
	end
	
	
	
	nUtility = nBadIdea
	return nUtility
end

function PrismExecute(botBrain)
	local ulti = skills.ulti
	
	if ulti:CanActivate() then
		core.OrderAbility(botBrain, ulti)
	end
end

PrismBehavior = {}
PrismBehavior["Utility"] = PrismUtility
PrismBehavior["Execute"] = PrismExecute
PrismBehavior["Name"] = "Prism"
tinsert(behaviorLib.tBehaviors, PrismBehavior)


--------------------------------------------------------------
-- Call of Valkyrie
--------------------------------------------------------------

function CallUtility(botBrain)
	local call = skills.call
	local unitSelf = core.unitSelf
	local range = 650
	if call:CanActivate() then
		local heroesNearby = HoN.GetHeroes(core.enemyTeam)
		local creepsNearby = core.CopyTable(core.localUnits["EnemyCreeps"])
		local currentMana = unitSelf:GetManaPercent()
		if currentMana * 100 > 60 then
			if EnemiesNear(unitSelf:GetPosition(), creepsNearby, range, 2) then
				return 100
			end
		end
		if EnemiesNear(unitSelf:GetPosition(), heroesNearby, range, 1) then
			return 100
		end
	end
	return 1
end

function CallExecute(botBrain)
	local call = skills.call
	if call:CanActivate() then
		core.OrderAbility(botBrain, call)
	end
end

CallBehavior = {}
CallBehavior["Utility"] = CallUtility
CallBehavior["Execute"] = CallExecute
CallBehavior["Name"] = "Call"
tinsert(behaviorLib.tBehaviors, CallBehavior)

--------------------------------------------------------------
-- RETREAAAAAAAAAAT
--------------------------------------------------------------

local function RetreatFromThreatExecuteOverride(botBrain)
	local unitSelf = core.unitSelf
	local leap = skills.leap
	local ulti = skills.ulti
	local arrow = skills.javelin
	local danger = 650
	local bActionTaken = false
	
	if not bActionTaken then
		local heroes = HoN.GetHeroes(core.enemyTeam)
		if EnemiesNear(unitSelf:GetPosition(), heroes, 400, 0) and leap:CanActivate() then
			for index, enemy in pairs(heroes) do
				if leap:CanActivate() then
					bActionTaken = core.OrderAbility(botBrain, leap)
				end
			end
		else
			if arrow and arrow:CanActivate() then
				local dangerdistance = 0
				heroes = HoN.GetHeroes(core.enemyTeam)
				if EnemiesNear(unitSelf:GetPosition(), heroes, 2000, 0) then
					for index, enemy in pairs(heroes) do
						if enemy:GetPosition() then
							dangerdistance = Vector3.Distance2DSq(unitSelf:GetPosition(), enemy:GetPosition())
							if TurnTheShip(botBrain, unitSelf:GetPosition(), enemy:GetPosition(), 1) then
								bActionTaken = core.OrderAbilityPosition(botBrain, arrow, enemy:GetPosition())
							end
						end
						BotEcho("ARROW???????????????????????????????????????????????????????????????")
					end
				end
			end
		end
	end
	if not bActionTaken then
		object.retreatFromThreatOld(botBrain)
	end
end

object.retreatFromThreatOld = behaviorLib.RetreatFromThreatBehavior["Execute"]
behaviorLib.RetreatFromThreatBehavior["Execute"] = RetreatFromThreatExecuteOverride

BotEcho('finished loading valkyrie_main')
