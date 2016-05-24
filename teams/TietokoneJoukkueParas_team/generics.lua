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


onCombatEventOld = object.oncombatevent

local function onCombatEventCustom(botBrain, EventData)

	onCombatEventOld(botBrain, EventData)

end

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

local HarassHeroUtilityOld = behaviorLib.HarassHeroBehavior["Utility"]
local function TeamHarassHeroUtility(botBrain)
  local me = core.unitSelf
  local teamBotBrain = core.teamBotBrain
  local enemyHeroCloseToAllyTower = enemyHeroClosestToAllyTower(botBrain, 600)
  if enemyHeroCloseToAllyTower and me:GetHealthPercent() > 0.3 then
    Echo("begin ally tower harass")
    return 80
  end
  if GetDistanceToClosestEnemyTower() < 700*700 then
    Echo("don't harass close to enemy tower")
    return 0
  end
  if teamBotBrain.GetTeamTarget then
    local target = teamBotBrain:GetTeamTarget()
    if target then
      Echo("found team target")
      local util = 40
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

