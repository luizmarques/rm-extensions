-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hits", "damage"});
	
	TokenManager.addEffectTagIconConditional("IF", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManagerRMC.parseEffectComp);
	
	Token.onDrop = onDrop;
end

function getHealthInfo(nodeCT)
	return ActorHealthManager.getTokenHealthInfo(ActorManager.resolveActor(nodeCT));
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManagerRMC.checkConditional(rActor, nodeEffect, vComp.remainder);
end

function onDrop(tokenCT, draginfo)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);
	if nodeCT then
		local sType = draginfo.getType();
		if sType == "tableresult" then
			local woundEffects = draginfo.getCustomData();
			local sDescription = draginfo.getDescription();
			CombatManager2.addWoundEffects(nodeCT, woundEffects, sDescription);
		elseif sType == "attack" then
			local customData = draginfo.getCustomData();
			if customData then
				TargetingManager.notifyAddTarget(ActorManager.getCTNode(customData), nodeCT);
			end
		end
	end
end
