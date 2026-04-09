-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActorHealthManager.getWoundPercent = getWoundPercent;
	ActorHealthManager.isDyingOrDeadStatus = isDyingOrDeadStatus;
end

function isDyingOrDeadStatus(sStatus)
	return ((sStatus == ActorHealthManager.STATUS_UNCONSCIOUS) or 
			(sStatus == ActorHealthManager.STATUS_DYING) or 
			(sStatus == ActorHealthManager.STATUS_DEAD) or 
			(sStatus == ActorHealthManager.STATUS_DESTROYED));
end

function getWoundPercent(rActor)
	local nHits, nDamage;
	local node = ActorManager.getCreatureNode(rActor);
	if ActorManager.isPC(rActor) then
		nHits = math.max(DB.getValue(node, "hits.max", 0), 0);
		nDamage = math.max(DB.getValue(node, "hits.damage", 0), 0);
	else
		nHits = math.max(DB.getValue(node, "hits", 0), 0);
		nDamage = math.max(DB.getValue(node, "damage", 0), 0);
	end

	local nPercentWounded = 0;
	if nHits > 0 then
		nPercentWounded = nDamage / nHits;
	end

	local sStatus;
	if EffectManagerRMC.hasEffect(node, ActorHealthManager.STATUS_UNCONSCIOUS) then
		sStatus = ActorHealthManager.STATUS_UNCONSCIOUS;
	elseif EffectManagerRMC.hasEffect(node, ActorHealthManager.STATUS_DYING) then
		sStatus = ActorHealthManager.STATUS_DYING;
	elseif EffectManagerRMC.hasEffect(node, ActorHealthManager.STATUS_DEAD) then
		sStatus = ActorHealthManager.STATUS_DEAD;
	elseif nPercentWounded >= 1 then
		sStatus = ActorHealthManager.STATUS_DEAD;
	else
		sStatus = ActorHealthManager.getDefaultStatusFromWoundPercent(nPercentWounded);
	end

	return nPercentWounded, sStatus;
end
