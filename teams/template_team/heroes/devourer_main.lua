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

BotEcho('loading devourer_main...')

object.heroName = 'Hero_Devourer'

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
    skills.hook = unitSelf:GetAbility(0)
    skills.rot = unitSelf:GetAbility(1)
    skills.skin = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.hook and skills.rot and skills.skin and skills.ulti and skills.attributeBoost then
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
  elseif skills.hook:CanLevelUp() then
    skills.hook:LevelUp()
  elseif skills.rot:CanLevelUp() then
    skills.rot:LevelUp()
  elseif skills.skin:CanLevelUp() then
    skills.skin:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end

behaviorLib.StartingItems = {"Item_ManaBattery", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_EnhancedMarchers", "Item_PowerSupply"}
behaviorLib.MidItems = {"Item_PortalKey", "Item_MagicArmor2"}
behaviorLib.LateItems = {"Item_BehemothsHeart"}

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
local function CustomHarassUtilityOverride(hero)
  local nUtility = 0

  if skills.hook:CanActivate() then
    nUtility = nUtility + 10
  end

  if skills.ulti:CanActivate() then
    nUtility = nUtility + 40
  end

  return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride
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
local function IsFreeLine(pos1, pos2)
  core.DrawDebugLine(pos1, pos2, "yellow")
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 50 * 50
  for _, ally in pairs(tAllies) do
    local posAlly = ally:GetPosition()
    local x3, y3 = posAlly.x, posAlly.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      core.DrawXPosition(posAlly, "red", 25)
      return false
    end
  end
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

local function DetermineHookTarget(hook)
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = hook:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 999999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    core.DrawXPosition(enemyPos, "yellow", 50)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and IsFreeLine(myPos, enemyPos) then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local hookTarget = nil
local function HookUtility(botBrain)
  local hook = skills.hook
  if hook and hook:CanActivate() then
    local unitTarget = DetermineHookTarget(hook)
    if unitTarget then
      hookTarget = unitTarget:GetPosition()
      core.DrawXPosition(hookTarget, "green", 50)
      return 60
    end
  end
  hookTarget = nil
  return 0
end
local function HookExecute(botBrain)
  local hook = skills.hook
  if hook and hook:CanActivate() and hookTarget then
    return core.OrderAbilityPosition(botBrain, hook, hookTarget)
  end
  return false
end
local HookBehavior = {}
HookBehavior["Utility"] = HookUtility
HookBehavior["Execute"] = HookExecute
HookBehavior["Name"] = "Hooking"
tinsert(behaviorLib.tBehaviors, HookBehavior)


local RotEnableBehavior = {}
RotEnableBehavior["Utility"] = RotEnableUtility
RotEnableBehavior["Execute"] = RotEnableExecute
RotEnableBehavior["Name"] = "Rot enable"
tinsert(behaviorLib.tBehaviors, RotEnableBehavior)

local function RotEnableUtility(botBrain)
	local rot = skills.rot
  local myPos = unit:GetPosition()
	local range = rot:GetTargetRadius()
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
	local rangeSq = range * range
	local hasEffect = core.unitSelf:HasState("State_Devourer_Ability2_Self")

	 for _, unitEnemy in pairs(tLocalEnemies) do

    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)

    if Vector3.Distance2DSq(enemy:GetPosition(), myPos) < rangeSq then
      return 50
    end

  end

	return 0
end 

local function RotEnableExecute()
	local rot = skills.rot
	if rot and rot:CanActivate() then
		return core.OrderAbility(botBrain, rot)	
	end
	return false
end

local function HasEnemiesInRange(unit, range)
  local enemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local rangeSq = range * range
  local myPos = unit:GetPosition()
  for _, enemy in pairs(enemies) do
    if Vector3.Distance2DSq(enemy:GetPosition(), myPos) < rangeSq then
      return true
    end
  end
  return false
end


local RotDisableBehavior = {}
local function RotDisableUtility(botBrain)
  local rot = skills.rot
  local rotRange = rot:GetTargetRadius()
  local hasEffect = core.unitSelf:HasState("State_Devourer_Ability2_Self")
  local hasEnemiesClose = HasEnemiesInRange(core.unitSelf, rotRange)
  if rot:CanActivate() and hasEffect and not hasEnemiesClose then
    return 1000
  end
  return 0
end
local function RotDisableExecute(botBrain)
  local rot = skills.rot
  if rot and rot:CanActivate() then
    return core.OrderAbility(botBrain, rot)
  end
  return false
end



RotDisableBehavior["Utility"] = RotDisableUtility
RotDisableBehavior["Execute"] = RotDisableExecute
RotDisableBehavior["Name"] = "Rot disable"
tinsert(behaviorLib.tBehaviors, RotDisableBehavior)





BotEcho('finished loading devourer_main')
