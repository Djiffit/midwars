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
object.nTime = 0


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

BotEcho('loading valkyrie_main...')

object.heroName = 'Hero_Valkyrie'
behaviorLib.StartingItems  = 
			{"Item_Bottle"}
behaviorLib.LaneItems  = 
			{ "Item_PowerSupply", "Item_Steamboots"}
behaviorLib.MidItems  = 
			{ "Item_Soulscream", "Item_Energizer", "Item_Lightbrand"}
behaviorLib.LateItems  = 
			{"Item_Dawnbringer", "Item_ManaBurn1 2", "Item_Weapon3", "Item_Evasion"}

-- tavarat


-- Skillbuildi
object.tSkills = {
	2, 1, 1, 0, 1,
	0, 1, 0, 0, 3, 
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

end

-- Check if jumping under tower range  !! ! ! !!

local function isjumpundertower()
	local tTowers = core.CopyTable(core.enemyTowers)
	for _, tower in pairs(tTowers) do
  if Vector3.Distance2DSq((core.unitSelf:GetPosition() + core.unitSelf:GetHeading()*skills.leap:GetRange()), tower:GetPosition()) < 700*700 then
		return false
  end
	return true
end

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

  local addBonus = 0
  if EventData.Type == "Attack" then
    local unitTarget = EventData.TargetUnit
    if EventData.InflictorName == "Projectile_Valkyrie_Ability2" and unitTarget:IsHero() then
      addBonus = addBonus + 50
    end
  end

  if addBonus > 0 then
    core.nHarassBonus = core.nHarassBonus + addBonus
  end
  
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

-- CHECK IF SOMETHING IS BLOCKING THE JAVELIN ( ARROW ) 
function NoObstructionsMy(me, enemy, obstructions, size)
local bDebugLines = true
	local path = Vector3.Distance2DSq(me, enemy)
	local blocking = 0
	for _, blocker in pairs(obstructions) do
		if blocker and blocker:GetPosition() ~= enemy and Vector3.Distance2DSq(me, blocker:GetPosition()) < path then
			local point = core.GetFurthestPointOnLine(blocker:GetPosition(), me, enemy)
			local blockerRadius = blocker:GetBoundsRadius()
			local blockerradiussq = blockerRadius * blockerRadius
			if Vector3.Distance2DSq(blocker:GetPosition(), point) <= 2000 + blockerradiussq then
				blocking = blocking + 1
				return false
			end 
		end
	end
	return true
end

local function NoObstructions(pos1, pos2)
  core.DrawDebugLine(pos1, pos2, "yellow")
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 255 * 255
  for _, creep in pairs(tEnemies) do
    local posCreep = creep:GetPosition()
    local x3, y3 = posCreep.x, posCreep.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      core.DrawXPosition(posCreep, "red", 25)
      return false
    end
  end
  core.DrawDebugLine(pos1, pos2, "green")
  return true
end
	
-------------999999999---------------99999999------------	
---------------	-- JA VE LI N AKA AARROW----------------
------------------------999999999999999-------------9999--
function JavelinUtility(botBrain)
	local unitTarget = behaviorLib.heroTarget
	local unitSelf = core.unitSelf
	local bActionTaken = false
	if unitTarget and (unitSelf:GetLevel() > 3 or unitSelf:GetManaPercent() * 100 > 90) and core.CanSeeUnit(botBrain, unitTarget) and skills.javelin:CanActivate() and unitTarget.storedPosition and unitTarget.lastStoredPosition then
		range = skills.javelin:GetRange()
		local targetspeed = unitTarget.storedPosition - unitTarget.lastStoredPosition
		local targetposition = unitTarget:GetPosition()
		local units = core.CopyTable(core.localUnits["EnemyCreeps"])
		if NoObstructions(unitSelf:GetPosition(), targetposition) then
			return 100
		end
	end
	return 1
end

function JavelinExecute(botBrain)
	local javelin = skills.javelin
	local unitTarget = behaviorLib.heroTarget
	local unitSelf = core.unitSelf
	if javelin:CanActivate() then
		if unitTarget and core.CanSeeUnit(botBrain, unitTarget) and skills.javelin:CanActivate() and unitTarget.storedPosition and unitTarget.lastStoredPosition then
			range = skills.javelin:GetRange()
			local targetspeed = unitTarget.storedPosition - unitTarget.lastStoredPosition
			local targetposition = unitTarget:GetPosition() + targetspeed
			local units = core.CopyTable(core.localUnits["EnemyCreeps"])
			if NoObstructions(unitSelf:GetPosition(), targetposition) then
				local bActionTaken = core.OrderAbilityPosition(botBrain, javelin, targetposition)
				core.OrderAbilityPosition(botBrain, javelin, targetposition)
			end
		end
	end
end


JavelinBehavior = {}
JavelinBehavior["Utility"] = JavelinUtility
JavelinBehavior["Execute"] = JavelinExecute
JavelinBehavior["Name"] = "Javelin"
tinsert(behaviorLib.tBehaviors, JavelinBehavior)





----------------------------------------------
-- Enemies nearby???? --
----------------------------------------------

function EnemiesNear(herolocation, enemies, range, style)
	local dangerarea = range
	local howmanyenemies = 0
	local lowhealth = 0
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
	elseif howmanyenemies >= 4 then
		return true
	end
	return false
end

-- HARASSMENT REEEEEEEEEEEEEEEEEEEEEEEEEE

local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget

	
	if unitTarget == nil then
		return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	local attackrange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
	local extrarange = core.GetExtraRange(unitSelf)
	local bActionTaken = false
	local targetstunned = unitTarget:IsStunned()
  local angle = core.HeadingDifference(unitSelf, unitTarget:GetPosition())

	if core.CanSeeUnit(botBrain, unitTarget) then
		if targetstunned then
			if skills.leap:CanActivate() and isjumpundertower() and skills.call:CanActivate() and core.unitSelf:GetLevel() > 5 and unitSelf:GetManaPercent() and angle < 0.3  then
				local range = skills.leap:GetRange() * skills.leap:GetRange() + 250 * 250
				if Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition()) < range then
					bActionTaken = core.OrderAbility(botBrain, skills.leap)
				end
			end
		end
		if not bActionTaken and skills.call:CanActivate() and Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition()) < 250*250 then
			bActionTaken = core.OrderAbility(botBrain, skills.call)
		end
		if not bActionTaken and core.unitSelf:GetHealthPercent() > unitTarget:GetHealthPercent() * 2 and targetstunned and skills.call:CanActivate() and angle < 0.3  and Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition()) < 1000*1000 and Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition()) > 500*500  then
			bActionTaken = core.OrderAbility(botBrain, skills.leap)
		end
		if not bActionTaken and isjumpundertower() and core.unitSelf:GetHealthPercent() > unitTarget:GetHealthPercent() and targetstunned and skills.call:CanActivate() and angle < 0.3  and Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition()) < 1000*1000 and Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition()) > 500*500  then
			bActionTaken = core.OrderAbility(botBrain, skills.leap)
		end
	end
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride



--------------------------------------------------------------
-- Prism
--------------------------------------------------------------
function PrismUtility(botBrain)
  
	local ulti = skills.ulti
	if ulti:CanActivate() then
		local allies = HoN.GetHeroes(core.myTeam)
		for _, health in pairs(allies) do
			local low = health:GetHealthPercent()
			if low <= 0.245901 and low > 0 then
				local allyposition = health:GetPosition()
				local enemies = HoN.GetHeroes(core.enemyTeam)
				if EnemiesNear(allyposition, enemies, 700, 0) then
					return 100
				end
			end
		end
	end
	return 0
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
		if currentMana * 100 > 66.6 then
			if EnemiesNear(unitSelf:GetPosition(), creepsNearby, range, 2) then
				return 21
			end
		end
		if EnemiesNear(unitSelf:GetPosition(), heroesNearby, range, 1) then
			
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
-- Leeaaappeerr
--------------------------------------------------------------


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
  local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
	if not bActionTaken then
		local heroes = HoN.GetHeroes(core.enemyTeam)
		if angle < 0.5 and EnemiesNear(unitSelf:GetPosition(), heroes, 400, 0) and leap:CanActivate() then
			for index, enemy in pairs(heroes) do
				if leap:CanActivate() then
					bActionTaken = core.OrderAbility(botBrain, leap)
				end
			end
		elseif core.GetLastBehaviorName(botBrain) == "RetreatFromThreat" then
			if arrow and arrow:CanActivate() then
				local dangerdistance = 0
				heroes = HoN.GetHeroes(core.enemyTeam)
				if EnemiesNear(unitSelf:GetPosition(), heroes, 2000, 0) then
					for index, enemy in pairs(heroes) do
						if enemy:GetPosition() then
							dangerdistance = Vector3.Distance2DSq(unitSelf:GetPosition(), enemy:GetPosition())
							local units = core.CopyTable(core.localUnits["EnemyCreeps"])
							if NoObstructions(unitSelf:GetPosition(), enemy:GetPosition()) then
								bActionTaken = core.OrderAbilityPosition(botBrain, arrow, enemy:GetPosition())
							end
						end
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
