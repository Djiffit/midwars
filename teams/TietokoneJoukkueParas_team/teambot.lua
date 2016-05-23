local _G = getfenv(0)
local object = _G.object

runfile 'bots/teambot/teambotbrain.lua'

object.myName = 'TietokoneJoukkueParas'

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


teamHeroTarget = nil


function object:GetTeamTarget()
	if teamHeroTarget and teamHeroTarget:IsValid() then
		if self:CanSeeUnit(teamHeroTarget) then
			return seft:GetMemoryUnit(teamHeroTarget)
		end

		teamHeroTarget = nil
	end

	return nil

end


function object:SetTeamTarget(target)

	local oldTarget = self:GetTeamTarget()

	if not oldTarget then
		teamHeroTarget = target
		return
	end

	
	teamHeroTarget = BetterTarget(oldTarget, target)

end



local function BetterTarget(first, second) 


	local firstUtil = targetUtility(first)
	local secondUtil = targetUtility(second)

	if firstUtil < secondUtil then

		return second

	end

	return first


end


local function TargetUtility(targetHero)

	local util = 0

	local basePos = core.allyMainBaseStructure:GetPosition()

	local dist = Vector3.Distance2D(basePos, targetHero:GetPosition()) 

	local health = targetHero:GetHealthPercent()

	

	util = util - dist / 500 + (1 - health) * 1.5

	return util

end


