-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
	self.calcInitialParry();

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "initresult"), "onUpdate", self.onInitUpdate);
	DB.addHandler(DB.getPath(node, "effects.*.label"), "onUpdate", self.onEffectLabelUpdate);
	DB.addHandler(DB.getPath(node, "effects.*"), "onDelete", self.onEffectPreDelete);
	DB.addHandler(DB.getPath(node, "effects"), "onChildDeleted", self.onEffectChildDelete);
end
function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "initresult"), "onUpdate", self.onInitUpdate);
	DB.removeHandler(DB.getPath(node, "effects.*.label"), "onUpdate", self.onEffectLabelUpdate);
	DB.removeHandler(DB.getPath(node, "effects.*"), "onDelete", self.onEffectPreDelete);
	DB.removeHandler(DB.getPath(node, "effects"), "onChildDeleted", self.onEffectChildDelete);
end

function calcInitialParry()
	local node = getDatabaseNode();
	for _,v in pairs(DB.getChildren(node, "defences")) do
		if DB.getValue(v, "name", "") == "Parry" then
			DB.setValue(node, "parry.meleebonus", "number", DB.getValue(v, "meleebonus", 0));
			DB.setValue(node, "parry.missilebonus", "number", DB.getValue(v, "missilebonus", 0));
			break;
		end
	end
end

function onInitUpdate(nodeUpdated)
	CombatManager2.UpdateEffectInit(getDatabaseNode(), initresult.getValue());
end
function onEffectLabelUpdate(nodeEffect)
	local sEffName = DB.getValue(nodeEffect, "", "");
	if sEffName == "Dead" then
		local rActor = ActorManager.resolveActor(getDatabaseNode());
		EffectManager.removeCondition(rActor, "Unconscious");
	end

	self.updateDeleteVisibility();
end
function onEffectPreDelete(nodeEffect)
	local sEffName = DB.getValue(nodeEffect, "label", "");
	if sEffName == "Dying" then
		local iEffDuration = DB.getValue(nodeEffect, "duration");
		if iEffDuration <= 1 then
			EffectManager.addCondition(ActorManager.resolveActor(getDatabaseNode()), "Dead");
		end
	end
end
function onEffectChildDelete(nodeEffects)
	self.updateDeleteVisibility();
end
function updateDeleteVisibility()
	if self.isPC() then
		return;
	end

	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local nPercentWounded = ActorHealthManager.getHealthInfo(rActor);
	local bShowDelete = false;
	if nPercentWounded >= 1 then
		bShowDelete = true;
	else
		local rActor = ActorManager.resolveActor(nodeEntry);
		if EffectManager.hasCondition(rActor, "Dying") or 
				EffectManager.hasCondition(rActor, "Dead") or 
				EffectManager.hasCondition(rActor, "Unconscious") then
			bShowDelete = true;
		end
	end
	idelete.setVisible(bShowDelete);
end

function onMovementChanged()
	local node = getDatabaseNode();

	local nBaseRate = DB.getValue(node, "baserate", 0);
	local sPace = DB.getValue(node, "pace", "");

	local nPotential = nBaseRate * Rules_Move.PaceMultiplier(sPace);
	DB.setValue(node, "potentialdistance", "number", nPotential);

	local nManueverResult = DB.getValue(node, "manueverresult", 100);
	local nMaxMove = math.floor(nPotential * (nManueverResult / 100));
	DB.setValue(node, "maxdistance", "number", nMaxMove);

	local nActualMove = DB.getValue(node, "actualdistance", 0);
	local nMovePercent = 0;
	if nMaxMove > 0 then
		nMovePercent = math.floor((nActualMove / nMaxMove) * 100);
	end
	DB.setValue(node, "movepercent", "number", nMovePercent);
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local nPercentWounded,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor);
	
	damage.setColor(sColor);
	status.setValue(sStatus);
	
	local nConstitution;
	local nDamage = damage.getValue();
	local nHits = hits.getValue();
	if self.isPC() then
		local nodeChar = link.getTargetDatabaseNode();
		if nodeChar then
			nConstitution = DB.getValue(nodeChar, "abilities.constitution.temp_current", 1);
		else
			nConstitution = 1;
		end
	else
		local sOptionNCON = OptionsManager.getOption("NCON");
		if sOptionNCON == "npc hits" then
			nConstitution = nHits;
		elseif sOptionNCON == "50 constitution" then
			nConstitution = 50;
		else
			nConstitution = 1;
		end
	end

	if nPercentWounded < 1 then
		EffectManager.removeCondition(rActor, "Unconscious");
	else
		local nBelowZero = nDamage - nHits;
		local nEffectInit = DB.getValue(getDatabaseNode(), "initresult", 1) - 1;
		if nConstitution and nBelowZero >= nConstitution then
			nDamage = nConstitution + nHits;
			EffectManager.addCondition(rActor, "Dead");
			EffectManager.removeCondition(rActor, "Unconscious");
		else
			if not EffectManager.hasCondition(rActor, "Dead") then
				EffectManager.addCondition(rActor, "Unconscious");
			end
		end
	end
		
	self.updateDeleteVisibility();
end

-- NOTE: See individual sub-section windows for additional linking
function linkPCFields(nodeChar)
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(DB.createChild(nodeChar, "name", "string"), true);
		token.setLink(DB.createChild(nodeChar, "token", "token"));
		token3Dflat.setLink(DB.createChild(nodeChar, "token3Dflat", "token"));
		senses.setLink(DB.createChild(nodeChar, "senses", "string"), true);
		initresult.setLink(DB.createChild(nodeChar, "initiative.initresult", "number"), false);

		quicknessBonus.setLink(DB.createChild(nodeChar, "abilities.quickness.total", "number"), true);
		quicknessStat.setLink(DB.createChild(nodeChar, "abilities.quickness.temp", "number"), true);

		hits.setLink(DB.createChild(nodeChar, "hits.max", "number"), true);
		damage.setLink(DB.createChild(nodeChar, "hits.damage", "number"), false);

		ppcurrent.setLink(DB.createChild(nodeChar, "pp.used", "number"), false);
		ppmax.setLink(DB.createChild(nodeChar, "pp.max", "number"), true);
		spelladdermax.setLink(DB.createChild(nodeChar, "pp.spelladdermax", "number"), true);
		spelladderused.setLink(DB.createChild(nodeChar, "pp.spelladderused", "number"), false);

		at.setLink(DB.createChild(nodeChar, "at", "number"), true);
		atmiss.setLink(DB.createChild(nodeChar, "atmiss", "number"), true);
		db.setLink(DB.createChild(nodeChar, "db", "number"), true);
		db_nonid.setLink(DB.createChild(nodeChar, "db_nonid", "number"), true);
		movemaneuver.setLink(DB.createChild(nodeChar, "mmpenalty", "number"), true);
		move.setLink(DB.createChild(nodeChar, "bmr.total", "number"), true);
		exhaustionmax.setLink(DB.createChild(nodeChar, "exhaustion_total", "number"), true);
		exhaustioncurrent.setLink(DB.createChild(nodeChar, "exhaustion", "number"), false);
	end
end

function onDrop(x, y, draginfo)
	-- locate and process the custom data
	local customData = draginfo.getCustomData();

	-- only recognise dropped strings, numbers or Attack Effects
	if draginfo and (draginfo.isType("number") or draginfo.isType("rmdice"))then
		if not customData then
			local iHits = draginfo.getNumberData();
			if iHits then
				customData = { Hits = iHits };
				draginfo.setDescription(tostring(iHits));
			end
		end
	elseif draginfo and draginfo.isType("effect") then
		local rEffect = EffectManager.decodeEffectFromDrag(draginfo);
		local sFriendFoe = DB.getValue(getDatabaseNode(), "friendfoe", "");
		local sImmunity = DB.getValue(getDatabaseNode(),"immunity", "");
		local bShowEffect = true;
		local nEffectGMOnly = 1;

		if sFriendFoe == "friend" then -- Ally
			if OptionsManager.isOption("SEPC", "all") then
				bShowEffect = true;
				nEffectGMOnly = 0;
			end	
		else -- Non-ally
			if OptionsManager.isOption("SENPC", "all") and not CombatManager.isCTHidden(nodeTarget) then
				bShowEffect = true;
				nEffectGMOnly = 0;
			end	
		end

		rEffect.nGMOnly = nEffectGMOnly;
		rEffect.nInit = DB.getValue(getDatabaseNode(),"initresult", 1) - 1;
		if rEffect.sName == "Stun" or rEffect.sName == "NoParry" then	
			if sImmunity:lower():find("stun") then
				EffectManagerRMC.notifyImmunity("", "", getDatabaseNode(), rEffect, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", getDatabaseNode(), rEffect, bShowEffect, nEffectGMOnly);
			end
		elseif rEffect.sName == "MustParry" then
			if sImmunity:lower():find("stun") and OptionsManager.isOption("AL14", "on") then
				EffectManagerRMC.notifyImmunity("", "", getDatabaseNode(), rEffect, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", getDatabaseNode(), rEffect, bShowEffect, nEffectGMOnly);
			end
		else
			if rEffect.sName:lower():find("bleeding") and sImmunity:lower():find("hits/rd") then
				EffectManagerRMC.notifyImmunity("", "", getDatabaseNode(), rEffect, bShowEffect, nEffectGMOnly);
			else
				EffectManager.addEffect("", "", getDatabaseNode(), rEffect, bShowEffect, nEffectGMOnly);
			end
		end
		return true;
	elseif draginfo and draginfo.isType("attack") then
		if customData then
			TargetingManager.notifyAddTarget(ActorManager.getCTNode(customData), getDatabaseNode());
			return;
		end
	elseif (not draginfo) or (not draginfo.isType(Rules_Constants.DataType.AttackEffects)) then
		return;
	end

	if customData then
		if draginfo.getDescription() and draginfo.getDescription()~="" then
			if (customData.AttackerNodeName or "") ~= "" then
				nodeAttacker = DB.findNode(customData.AttackerNodeName);
			end
			CombatManager2.addWoundEffects(getDatabaseNode(), customData, draginfo.getDescription(), nodeAttacker);
		end
		return true;
	end
end

function onActiveChanged()
	self.onSectionChanged("move");
	self.onSectionChanged("active");
	self.onSectionChanged("defense");
end
function getSectionToggle(sKey)
	local bResult = false;

	local sButtonName = "button_section_" .. sKey;
	local cButton = self[sButtonName];
	if cButton then
		bResult = (cButton.getValue() == 1);

		if not bResult then
			local bActive = self.isActive();
			if bActive then
				if (sKey == "move") and (OptionsManager.isOption("TSEC", "Attack/Move") or OptionsManager.isOption("TSEC", "All Three")) then
					bResult = true;
				end
				if (sKey == "active") and not OptionsManager.isOption("TSEC", "None") then
					bResult = true;
				end
				if (sKey == "defense") and (OptionsManager.isOption("TSEC", "Attack/Defense") or OptionsManager.isOption("TSEC", "All Three")) then
					bResult = true;
				end
			end
		end
	end

	return bResult;
end
