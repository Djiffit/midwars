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

behaviorLib.StartingItems = {"4 Item_ManaPotion", "6 Item_HealthPotion", "Item_HomecomingStone", "Item_Bottle", "Item_EnhancedMarchers"}
behaviorLib.EarlyItems = {}
behaviorLib.MidItems = {"Item_Strength5", "Item_Shield2", "Item_Morph", "Item_Silence"}
behaviorLib.LateItems = {}

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

  if skills.ulti:CanLevelUp() and skills.ulti:GetLevel() == 0 then
    skills.ulti:LevelUp()
  elseif skills.heal:CanLevelUp() and skills.mana:GetLevel() > 0 and skills.stun:GetLevel() > 0 and skills.mana:GetLevel() >= skills.heal:GetLevel() then
    skills.heal:LevelUp()
  elseif skills.mana:CanLevelUp() and skills.stun:GetLevel() > 0 then
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

local function DetermineCloseEnemyTower(distance)
  local me = core.unitSelf
  local myPos = me:GetPosition()
  --local allies = core.CopyTable(core.localUnits["AllyUnits"])
  local towers = core.CopyTable(core.enemyTowers)
  for _, tower in pairs(towers) do
    local towerPos = tower:GetPosition()
    local towerDistance = Vector3.Distance2DSq(myPos, towerPos)
    if towerDistance < distance*distance then
      --[[local closeAllyCount = 0
      for _, ally in pairs(allies) do
        local allyPos = ally:GetPosition()
        local allyDistanceFromEnemy = Vector3.Distance2DSq(enemyPos, allyPos)
        if allyDistanceFromEnemy < 900*900 then
          closeAllyCount = closeAllyCount + 1
        end
        if closeAllyCount >= count then
          return enemy
          
        end
      end--]]
      return tower
    end
  end
  return nil
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

  local addBonus = 0
  local me = core.unitSelf
  if EventData.Type == "Attack" then
    local unitTarget = EventData.TargetUnit
    if unitTarget:IsHero() and unitTarget:IsStunned() and not DetermineCloseEnemyTower(1000)  and me:GetHealthPercent() < 0.4 then
      addBonus = addBonus + 50
    end
  end

  if addBonus > 0 then
    core.nHarassBonus = core.nHarassBonus + addBonus
  end

  -- custom code here
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

local function DontBreakChannelUtilityOverride(botbrain)
  return 200
end
behaviorLib.DontBreakChannelUtility = DontBreakChannelUtilityOverride

local function DetermineClosestSafePosition()
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local closestTower = nil
  local smallestDistance = -1
  local towers = core.CopyTable(core.allyTowers)
  for _, tower in pairs(towers) do
    local towerPos = tower:GetPosition()
    local towerDistance = Vector3.Distance2DSq(myPos, towerPos)
    if not closestTower or (towerDistance < smallestDistance or smallestDistance == -1) then
      closestTower = tower
      smallestDistance = towerDistance
    end
  end
  if closestTower then
    return closestTower:GetPosition()
  else
    return core.allyWell:GetPosition()
  end
end


--[[
local function HealAtWellUtilityOverride(botbrain)
  local me = core.unitSelf
  local myHealthPercent = me:GetHealthPercent()
  local myManaPercent = me:GetManaPercent()
  if myHealthPercent > 0.7 and myManaPercent > 0.4 and  then
    return 0
  end
  return object.HealAtWellUtilityOld(botbrain)
end
object.HealAtWellUtilityOld = behaviorLib.HealAtWellBehavior["Utility"]
behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride
--]]

local function DetermineEnemyWithOwnAlliesClose(me, count, distance)
  local myPos = me:GetPosition()
  --local allies = core.CopyTable(core.localUnits["AllyUnits"])
  local enemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  for _, enemy in pairs(enemies) do
    local enemyPos = enemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < distance*distance then
      --[[local closeAllyCount = 0
      for _, ally in pairs(allies) do
        local allyPos = ally:GetPosition()
        local allyDistanceFromEnemy = Vector3.Distance2DSq(enemyPos, allyPos)
        if allyDistanceFromEnemy < 900*900 then
          closeAllyCount = closeAllyCount + 1
        end
        if closeAllyCount >= count then
          return enemy
          
        end
      end--]]
      return enemy
    end
  end
  return nil
end

local function HealAtWellExecuteOverride(botBrain)
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local wellPos = core.allyWell:GetPosition()
  local actionTaken
  if Vector3.Distance2DSq(myPos, wellPos) < 3000*3000 then
    actionTaken = object.HealAtWellExecuteOld(botBrain)
  end
  local myHealthPercent = me:GetHealthPercent()
  local myManaPercent = me:GetManaPercent()
  local destination = DetermineClosestSafePosition()
  local closeEnemy = DetermineEnemyWithOwnAlliesClose(me, 1, 1300)
  local closeEnemyTower = DetermineCloseEnemyTower(1500)
  if not closeEnemy and not closeEnemyTower and myHealthPercent > 0.4 and myManaPercent > 0.2 and not actionTaken then
    actionTaken = core.OrderMoveToPosAndHoldClamp(botBrain, me, destination, false)
    if Vector3.Distance2DSq(myPos, destination) < 300*300 then
      local heal = skills.heal
      core.OrderAbilityPosition(botBrain, heal, me:GetPosition())
    end
  end
  if not actionTaken then
    object.HealAtWellExecuteOld(botBrain)
  end
end
object.HealAtWellExecuteOld = behaviorLib.HealAtWellBehavior["Execute"]
behaviorLib.HealAtWellBehavior["Execute"] = HealAtWellExecuteOverride



local function DetermineTeleportPosition()
  local me = core.unitSelf
  local towers = core.CopyTable(core.allyTowers)
  local smallestHealthTower
  local smallestHealth = -1
  for _, tower in pairs(towers) do
    local towerHealth = tower:GetHealthPercent()
    if towerHealth < 1 and (towerHealth < smallestHealth or smallestHealth == -1) then
      smallestHealthTower = tower
      smallestHealth = towerHealth
    end
  end
  if smallestHealthTower then
    return smallestHealthTower:GetPosition()
  end
  return nil
end

local function DetermineEnemiesCloseTogetherPosition(distanceToSelf, count)
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local enemies = core.CopyTable(core.localUnits["Enemies"])
  for _, enemy in pairs(enemies) do
    local enemyPos = enemy:GetPosition()
    local enemiesCloseCount = 0
    for _, enemy2 in pairs(enemies) do
      local enemy2Pos = enemy2:GetPosition()
      local enemiesDistance = Vector3.Distance2DSq(enemyPos, enemy2Pos)
      if enemiesDistance < distanceToSelf*distanceToSelf then
          enemiesCloseCount = enemiesCloseCount + 1
          if enemiesCloseCount >= count then
            return enemy:GetPosition()
          end
        end
      end
    end
  return nil
end

local healTargetPos = nil
local function HealUtility(botBrain)
  local heal = skills.heal
  local me = core.unitSelf
  if heal and heal:CanActivate() then
    if me:GetHealthPercent() < 0.5 and me:GetHealthRegen() < 50 then
      healTargetPos = me:GetPosition()
      return 110
    end
    local target = DetermineEnemiesCloseTogetherPosition(450, 3)
    if me:GetManaPercent() > 0.5 and target then
      healTargetPos = target
      return 100
    end
  end
  return 0
end

local function HealExecute(botBrain)
  local me = core.unitSelf
  local heal = skills.heal
  local selfPos = me:GetPosition()
  if heal and heal:CanActivate() and healTargetPos then
    if me:GetHealthPercent() > 0.3 and me:GetHealthPercent() < 0.9 then
      core.OrderMoveToPosClamp(botBrain, me, healTargetPos, false)
    end
    return core.OrderAbilityPosition(botBrain, heal, healTargetPos)
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
    for _, enemy in pairs(enemies) do
      local enemyPos = enemy:GetPosition()
      local enemyRange = enemy:GetAttackRange()
      local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
      if distanceEnemy < 1.2 * enemyRange * enemyRange then
        return 0
      end
    end
    if me:GetManaRegen() > 50 then
      return 0
    end
    return 60
  end
  return 0
end

local function ManaExecute(botBrain)
  local mana = skills.mana
  local me = core.unitSelf
  if mana and mana:CanActivate() then
    return core.OrderAbilityEntity(botBrain, mana, me)
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
  if stun and stun:CanActivate() then
    local target = DetermineEnemyWithOwnAlliesClose(me, 1, 900)
    if target then
      stunTarget = target
      return 60
    end
    return 0
  end
  return 0
end

local function StunExecute(botBrain)
  local stun = skills.stun
  local selfPos = core.unitSelf:GetPosition()
  if stun and stun:CanActivate() and stunTarget then
    return core.OrderAbilityPosition(botBrain, stun, stunTarget:GetPosition())
  end
  return false
end
local StunBehavior = {}
StunBehavior["Utility"] = StunUtility
StunBehavior["Execute"] = StunExecute
StunBehavior["Name"] = "Stun"
tinsert(behaviorLib.tBehaviors, StunBehavior)

local teleportTarget = nil
local function TeleportUtility(botBrain)
  local teleport = skills.ulti
  local me = core.unitSelf
  if teleport and teleport:CanActivate() then
    local target = DetermineTeleportPosition()
    if target then
      teleportTarget = target
      return 110
    end
    return 0
  end
  return 0
end

local function TeleportExecute(botBrain)
  local me = core.unitSelf
  local teleport = skills.ulti
  local myPos = me:GetPosition()
  if teleport and teleport:CanActivate() and teleportTarget then
    local distanceToWell = Vector3.Distance2DSq(myPos, core.allyWell:GetPosition())
    if distanceToWell < 10000 and me:GetHealthPercent() > 0.7 and me:GetManaPercent() > 0.7 then
      return core.OrderAbilityPosition(botBrain, teleport, teleportTarget)
    end
  end
  return false
end
local TeleportBehavior = {}
TeleportBehavior["Utility"] = TeleportUtility
TeleportBehavior["Execute"] = TeleportExecute
TeleportBehavior["Name"] = "Teleport"
tinsert(behaviorLib.tBehaviors, TeleportBehavior)

BotEcho('finished loading nymphora_main')
