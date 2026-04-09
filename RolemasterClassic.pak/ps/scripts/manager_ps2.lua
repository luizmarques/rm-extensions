-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	PartyXPManager.setActorTypeInfo("charsheet", { sField = "xp" });
	WindowTabManager.registerTab("partysheet_host", { sName = "xp", sTabRes = "tab_xp", sClass = "ps_xp" });
end

function linkPCFields(nodePS)
	local nodeChar = PartyManager.mapPStoChar(nodePS);
	
	PartyManager.linkRecordField(nodeChar, nodePS, "name", "string");
	PartyManager.linkRecordField(nodeChar, nodePS, "token", "token", "token");

	PartyManager.linkRecordField(nodeChar, nodePS, "race", "string");
	PartyManager.linkRecordField(nodeChar, nodePS, "profession", "string");
	PartyManager.linkRecordField(nodeChar, nodePS, "level", "number");
	PartyManager.linkRecordField(nodeChar, nodePS, "xp", "number");
	PartyManager.linkRecordField(nodeChar, nodePS, "nextlevelxp", "number");

	PartyManager.linkRecordField(nodeChar, nodePS, "hits.max", "number", "hitsmax");
	PartyManager.linkRecordField(nodeChar, nodePS, "hits.damage", "number", "hitsdamage");
	PartyManager.linkRecordField(nodeChar, nodePS, "pp.max", "number", "ppmax");
	PartyManager.linkRecordField(nodeChar, nodePS, "pp.used", "number", "ppused");
	PartyManager.linkRecordField(nodeChar, nodePS, "pp.spelladdermax", "number", "spelladdermax");
	PartyManager.linkRecordField(nodeChar, nodePS, "pp.spelladderused", "number", "spelladderused");
	PartyManager.linkRecordField(nodeChar, nodePS, "exhaustion_total", "number", "exhaustionmax");
	PartyManager.linkRecordField(nodeChar, nodePS, "exhaustion", "number", "exhaustionused");
	
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.constitution.total", "number", "constitution");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.agility.total", "number", "agility");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.selfdiscipline.total", "number", "selfdiscipline");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.memory.total", "number", "memory");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.reasoning.total", "number", "reasoning");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.strength.total", "number", "strength");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.quickness.total", "number", "quickness");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.presence.total", "number", "presence");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.intuition.total", "number", "intuition");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.empathy.total", "number", "empathy");

	PartyManager.linkRecordField(nodeChar, nodePS, "rr.base.channeling.total", "number", "channeling");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.base.essence.total", "number", "essence");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.base.mentalism.total", "number", "mentalism");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.base.poison.total", "number", "poison");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.base.disease.total", "number", "disease");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.base.terror.total", "number", "terror");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.hybrid.chan_ment.total", "number", "chan_ment");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.hybrid.ess_chan.total", "number", "ess_chan");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.hybrid.ment_ess.total", "number", "ment_ess");
	PartyManager.linkRecordField(nodeChar, nodePS, "rr.hybrid.arcane.total", "number", "arcane");

	PartyManager.linkRecordField(nodeChar, nodePS, "bmr.total", "number", "move");
	PartyManager.linkRecordField(nodeChar, nodePS, "mmpenalty", "number", "movementmaneuver");

	linkSkillRecordField(nodeChar, nodePS, "links.skill_perception_total", "number", "Perception", "Perception");
end
function linkSkillRecordField(nodeChar, nodePS, sCharSkillLink, sType, sPSLink, sSkillName)
	PartyManager.linkRecordField(nodeChar, nodePS, sCharSkillLink, sType, sPSLink);

	if DB.getValue(nodePS, sPSLink, 0) == 0 then
		local nodeSkill = Rules_PC.SkillNode(nodeChar, sSkillName);
		local nSkillTotal = DB.getValue(nodeSkill, "total", 0);
		if nSkillTotal == 0 then
			nSkillTotal = Rules_PC.SkillUntrainedTotal(nodeChar, sSkillName);
		end
		DB.setValue(nodePS, sPSLink, "number", nSkillTotal);
	end
end
