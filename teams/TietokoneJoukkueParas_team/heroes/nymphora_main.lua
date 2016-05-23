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
runfile "bots/teams/TietokoneJoukkueParas_team/generics.lua"

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

behaviorLib.StartingItems = {"3 Item_MinorTotem", "Item_PretendersCrown", "Item_ManaBattery"}
behaviorLib.EarlyItems = {}
behaviorLib.MidItems = {"Item_PowerSupply", "Item_Bottle", "Item_Strength5", "Item_Shield2", "Item_Morph", "Item_Silence"}
behaviorLib.LateItems = {}

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 0, ShortSolo = 0, LongSolo = 0, ShortSupport = 5, LongSupport = 5, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
object.tSkills = {
  2, 0, 1, 0, 0,
  3, 0, 1, 1, 1,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
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

  local nPoints = unitSelf:GetAbilityPointsAvailable()
  if nPoints <= 0 then
    return
  end

  local nLevel = unitSelf:GetLevel()
  for i = nLevel, (nLevel + nPoints) do
    unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
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

  -- custom code here
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

local function GetDistanceToSelf(unit)
  local me = core.unitSelf
  local myPos = me:GetPosition()
  return Vector3.Distance2DSq(myPos, unit:GetPosition())
end

local function GetClosestAllyHero()
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local actionTaken = false
  local allyHeroes = core.CopyTable(core.localUnits["AllyHeroes"])
  local closestAllyHero
  local closestAllyHeroDistance = -1
  for _, allyHero in pairs(allyHeroes) do
    allyHeroDistanceFromSelf = Vector3.Distance2DSq(myPos, allyHero:GetPosition())
    if not closestAllyHero or (closestAllyHeroDistance == -1 or allyHeroDistanceFromSelf < closestAllyHeroDistance) then
      closestAllyHero = allyHero
      closestAllyHeroDistance = allyHeroDistanceFromSelf
    end
  end
  return closestAllyHero
end

local function GetClosestEnemyHero()
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local actionTaken = false
  local enemyHeroes = core.CopyTable(core.localUnits["EnemyHeroes"])
  if not enemyHeroes then
    return nil
  end
  local closestEnemyHero
  local closestEnemyHeroDistance = -1
  for _, enemyHero in pairs(enemyHeroes) do
    enemyHeroDistanceFromSelf = Vector3.Distance2DSq(myPos, enemyHero:GetPosition())
    if not closestEnemyHero or (closestEnemyHeroDistance == -1 or enemyHeroDistanceFromSelf < closestEnemyHeroDistance) then
      closestEnemyHero = enemyHero
      closestEnemyHeroDistance = enemyHeroDistanceFromSelf
    end
  end
  return closestEnemyHero
end

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

local function NextItemShouldBeBought(botbrain)
  local gold = botbrain:GetGold()
  local time = GetTime()
  if gold > 800 and time/6000000 < 10 then
    return true
  elseif gold > 2000 and time/6000000 > 10 then
    return true
  end
  return false
end

local function DetermineIfAllyNeedsToBeSaved()
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local allyHeroes = core.allyHeroes
  local enemyHeroes = core.CopyTable(core.localUnits["EnemyHeroes"])
end

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

local function HealAtWellExecuteOverride(botbrain)
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local wellPos = core.allyWell:GetPosition()
  local actionTaken = false
  if not actionTaken and Vector3.Distance2DSq(myPos, wellPos) < 1000*1000 then
    object.HealAtWellExecuteOld(botbrain)
    actionTaken = true
  end
  if not actionTaken and NextItemShouldBeBought(botbrain) then
    object.HealAtWellExecuteOld(botbrain)
    actionTaken = true
  end
  local myHealthPercent = me:GetHealthPercent()
  local myManaPercent = me:GetManaPercent()
  local destination = DetermineClosestSafePosition()
  local closestEnemyHero = GetClosestEnemyHero()
  local closeEnemyTower = DetermineCloseEnemyTower(1500)
  if not actionTaken and closestEnemyHero and GetDistanceToSelf(closestEnemyHero) < 1500*1500 then
    object.HealAtWellExecuteOld(botbrain)
    actionTaken = true
  end
  if not actionTaken and not closeEnemyTower and myHealthPercent > 0.4 and myManaPercent > 0.2 and not actionTaken then
    core.OrderMoveToPosAndHoldClamp(botbrain, me, destination, false)
    if Vector3.Distance2DSq(myPos, destination) < 300*300 then
      local heal = skills.heal
      core.OrderAbilityPosition(botbrain, heal, me:GetPosition())
    end
    actionTaken = true
  end
  if not actionTaken then
    object.HealAtWellExecuteOld(botbrain)
  end
end
object.HealAtWellExecuteOld = behaviorLib.HealAtWellBehavior["Execute"]
behaviorLib.HealAtWellBehavior["Execute"] = HealAtWellExecuteOverride

local stayCloseToAllies = false
local function PositionSelfUtilityOverride(botbrain)
  local closestAllyHero = GetClosestAllyHero()
  local closestEnemyHero = GetClosestEnemyHero()
  if closestAllyHero and GetDistanceToSelf(closestAllyHero) > 100*100 and closestEnemyHero and GetDistanceToSelf(closestEnemyHero) < 1500*1500 then
    stayCloseToAllies = true
    Echo("staying close to allies")
    return 60
  end
  return object.PositionSelfUtilityOld(botbrain)
end
object.PositionSelfUtilityOld = behaviorLib.PositionSelfBehavior["Utility"]
behaviorLib.PositionSelfBehavior["Utility"] = PositionSelfUtilityOverride

local function PositionSelfExecuteOverride(botbrain)
  local me = core.unitSelf
  local closestAllyHero = GetClosestAllyHero()
  local actionTaken = false
  if stayCloseToAllies and closestAllyHero then
    core.OrderMoveToPosAndHoldClamp(botbrain, me, closestAllyHero:GetPosition(), false)
    actionTaken = true
  end
  if not actionTaken then
    object.PositionSelfExecuteOld(botbrain)
  end

  
end
object.PositionSelfExecuteOld = behaviorLib.PositionSelfBehavior["Execute"]
behaviorLib.PositionSelfBehavior["Execute"] = PositionSelfExecuteOverride



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
local function HealUtility(botbrain)
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

local function HealExecute(botbrain)
  local me = core.unitSelf
  local heal = skills.heal
  local selfPos = me:GetPosition()
  if heal and heal:CanActivate() and healTargetPos then
    if me:GetHealthPercent() > 0.3 and me:GetHealthPercent() < 0.9 then
      core.OrderMoveToPosClamp(botbrain, me, healTargetPos, false)
    end
    return core.OrderAbilityPosition(botbrain, heal, healTargetPos)
  end
  return false
end
local HealBehavior = {}
HealBehavior["Utility"] = HealUtility
HealBehavior["Execute"] = HealExecute
HealBehavior["Name"] = "Healing"
tinsert(behaviorLib.tBehaviors, HealBehavior)
-- Tähtää vihollisiin, mene itse alueelle

local function ManaUtility(botbrain)
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

local function ManaExecute(botbrain)
  local mana = skills.mana
  local me = core.unitSelf
  if mana and mana:CanActivate() then
    return core.OrderAbilityEntity(botbrain, mana, me)
  end
  return false
end
local ManaBehavior = {}
ManaBehavior["Utility"] = ManaUtility
ManaBehavior["Execute"] = ManaExecute
ManaBehavior["Name"] = "Mana"
tinsert(behaviorLib.tBehaviors, ManaBehavior)

local stunTarget = nil
local function StunUtility(botbrain)
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

local function StunExecute(botbrain)
  local stun = skills.stun
  local selfPos = core.unitSelf:GetPosition()
  if stun and stun:CanActivate() and stunTarget then
    return core.OrderAbilityPosition(botbrain, stun, stunTarget:GetPosition())
  end
  return false
end
local StunBehavior = {}
StunBehavior["Utility"] = StunUtility
StunBehavior["Execute"] = StunExecute
StunBehavior["Name"] = "Stun"
tinsert(behaviorLib.tBehaviors, StunBehavior)

local teleportTarget = nil
local function TeleportUtility(botbrain)
  local teleport = skills.ulti
  local me = core.unitSelf
  local myPos = me:GetPosition()
  local distanceToWell = Vector3.Distance2DSq(myPos, core.allyWell:GetPosition())
  if teleport and teleport:CanActivate() and distanceToWell < 10000 and me:GetHealthPercent() > 0.7 and me:GetManaPercent() > 0.7 then
    local target = DetermineTeleportPosition()
    if target then
      teleportTarget = target
      return 110
    end
    return 0
  end
  return 0
end

local function TeleportExecute(botbrain)
  local teleport = skills.ulti
  if teleport and teleport:CanActivate() and teleportTarget then
    return core.OrderAbilityPosition(botbrain, teleport, teleportTarget)
  end
  return false
end
local TeleportBehavior = {}
TeleportBehavior["Utility"] = TeleportUtility
TeleportBehavior["Execute"] = TeleportExecute
TeleportBehavior["Name"] = "Teleport"
tinsert(behaviorLib.tBehaviors, TeleportBehavior)

BotEcho('finished loading nymphora_main')
