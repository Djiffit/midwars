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

BotEcho('loading nymphora_main...')

object.heroName = 'Hero_Fairy'

--------------------------------
-- Items
--------------------------------

behaviorLib.StartingItems = {"Item_ManaPotion", "Item_HealthPotion", "Item_EnhancedMarchers", "Item_HomecomingStone"}
behaviorLib.EarlyItems = {"2 Item_Strength5", "Item_HomecomingStone"}
behaviorLib.MidItems = {"Item_Shield2", "Item_HomecomingStone"}
behaviorLib.LateItems = {"Item_Morph", "Item_Silence"}

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 0, ShortSolo = 0, LongSolo = 0, ShortSupport = 5, LongSupport = 5, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.heal = unitSelf:GetAbility(0)
    skills.mana = unitSelf:GetAbility(1)
    skills.stun = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.heal and skills.mana and skills.stun and skills.ulti and skills.attributeBoost then
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
  elseif skills.heal:CanLevelUp() and skills.mana.GetLevel() > 0 and skills.stun.GetLevel() > 0 then
    skills.heal:LevelUp()
  elseif skills.mana:CanLevelUp() and skills.stun.GetLevel() > 0 and skills.mana:GetLevel() < skills.heal.GetLevel() then
    skills.mana:LevelUp()
  elseif skills.heal:GetLevel() == 0 then
    skills.heal:LevelUp()
  elseif skills.mana:GetLevel() == 0 then
    skills.mana:LevelUp()
  elseif skills.stun:CanLevelUp() then
    skills.stun:LevelUp()
  elseif skills.heal:CanLevelUp() then
    skills.heal:LevelUp()
  elseif skills.mana:CanLevelUp() then
    skills.mana:LevelUp()
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

local function HealUtility(botBrain)
  local heal = skills.heal
  local me = core.unitSelf
  if heal and heal:CanActivate() then
    if me:GetHealthPercent() < 0.5 and me:GetManaPercent() > 0.5 then
      return 60
    end
  end
  return 0
end

local function HealExecute(botBrain)
  local heal = skills.heal
  local selfPos = core.unitSelf:GetPosition()
  if heal and heal:CanActivate() then
    return core.OrderAbilityPosition(botBrain, heal, selfPos)
  end
  return false
end
local HealBehavior = {}
HealBehavior["Utility"] = HealUtility
HealBehavior["Execute"] = HealExecute
HealBehavior["Name"] = "Healing"
tinsert(behaviorLib.tBehaviors, HealBehavior)
-- Tähtää vihollisiin, mene itse alueelle

local function ManaUtility(botBrain)
  local mana = skills.mana
  local me = core.unitSelf
  local myPos = me:GetPosition()
  if mana and mana:CanActivate() then
    local enemies = core.CopyTable(core.localUnits["EnemyHeroes"])
    for enemy in enemies do
      local enemyPos = enemy:GetPosition()
      local enemyRange = enemy:GetAttackRange()
      local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
      if distanceEnemy < 2 * enemyRange then
        Echo("Too close to enemy")
        return 0
      end
    end
    return 60
  end
  return 0
end

local function ManaExecute(botBrain)
  local mana = skills.mana
  local selfPos = core.unitSelf:GetPosition()
  if mana and mana:CanActivate() then
    return core.OrderAbilityPosition(botBrain, mana, selfPos)
  end
  return false
end
local ManaBehavior = {}
ManaBehavior["Utility"] = ManaUtility
ManaBehavior["Execute"] = ManaExecute
ManaBehavior["Name"] = "Mana"
tinsert(behaviorLib.tBehaviors, ManaBehavior)

local stunTarget = nil
local function StunUtility(botBrain)
  local stun = skills.stun
  local me = core.unitSelf
  local myPos = me:GetPosition()
  if stun and stun:CanActivate() then
    local allies = core.CopyTable(core.localUnits["AllyUnits"])
    local enemies = core.CopyTable(core.localUnits["EnemyHeroes"])
    for enemy in enemies do
      local enemyPos = enemy:GetPosition()
      local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
      if distanceEnemy < 450 then
        for ally in allies do
          local closeAllyCount = 0
          local allyPos = ally:GetPosition()
          local allyDistanceFromEnemy = Vector3.Distance2DSq(enemyPos, allyPos)
          if allyDistanceFromEnemy < 100 then
            closeAllyCount += 1
          end
          if closeAllyCount >= 5
            stunTarget = enemy
            return 60
          end
        end
        Echo("No close allies")
      end
    end
    return 0
  end
  return 0
end

local function StunExecute(botBrain)
  local stun = skills.stun
  local selfPos = core.unitSelf:GetPosition()
  if stun and stun:CanActivate() and stunTarget then
    return core.OrderAbilityPosition(botBrain, stun, stunTarget)
  end
  return false
end
local StunBehavior = {}
StunBehavior["Utility"] = StunUtility
StunBehavior["Execute"] = StunExecute
StunBehavior["Name"] = "Stun"
tinsert(behaviorLib.tBehaviors, StunBehavior)

BotEcho('finished loading nymphora_main')
