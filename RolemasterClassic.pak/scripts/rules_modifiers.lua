-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function DifficultyList()
	local aDifficultyList = {};

	table.insert(aDifficultyList, {order = 1, fullname = "1. Routine +30", name = "Routine", modifier = 30});
	table.insert(aDifficultyList, {order = 2, fullname = "2. Easy +20", name = "Easy", modifier = 20});
	table.insert(aDifficultyList, {order = 3, fullname = "3. Light +10", name = "Light", modifier = 10});
	table.insert(aDifficultyList, {order = 4, fullname = "4. Medium +0", name = "Medium", modifier = 0});
	table.insert(aDifficultyList, {order = 5, fullname = "5. Hard -10", name = "Hard", modifier = -10});
	table.insert(aDifficultyList, {order = 6, fullname = "6. Very Hard -20", name = "Very Hard", modifier = -20});
	table.insert(aDifficultyList, {order = 7, fullname = "7. Extremely Hard -30", name = "Extremely Hard", modifier = -30});
	table.insert(aDifficultyList, {order = 8, fullname = "8. Sheer Folly -50", name = "Sheer Folly", modifier = -50});
	table.insert(aDifficultyList, {order = 9, fullname = "9. Absurd -70", name = "Absurd", modifier = -70});
	
	return aDifficultyList;
end

function DifficultyNameList()
	local aDifficultyList = Rules_Modifiers.DifficultyList();
	local aDifficultyNameList = {};
	
	for _, vDifficulty in pairs(aDifficultyList) do
		table.insert(aDifficultyNameList, vDifficulty.name);
	end
	
	return aDifficultyNameList;
end

function GetModFromDifficultyName(sDifficultyName)
	local nMod = 0;
	local aDifficultyList = Rules_Modifiers.DifficultyList();
	
	for _, vDifficulty in pairs(aDifficultyList) do
		if vDifficulty.name == sDifficultyName then
			nMod = vDifficulty.modifier;
		end
	end
	
	return nMod;
end

function Hits(aModifiers, nodeActor, sSkillName)
	if not nodeActor then
		return;
	end
	
	if DB.getChild(nodeActor, "damage") then
		nDamage = DB.getValue(nodeActor, "damage", 0);
	elseif DB.getChild(nodeActor, "hits.damage") then
		nDamage = DB.getValue(nodeActor, "hits.damage", 0);
	end
	
	if DB.getChild(nodeActor, "hits.max") then
		nHits = DB.getValue(nodeActor, "hits.max", 0);
	elseif DB.getChild(nodeActor, "hits") then
		nHits = DB.getValue(nodeActor, "hits", 0);
	end

	if nHits == null then 
		nHits = 0;
	end
	
	if nDamage == null then 
		nDamage = 0;
	end

	if nHits > 0 then
		nDamage = nDamage / nHits;
		if nDamage >= 1 then
			-- send a message to the chat box
			Comm.deliverChatMessage({font="systemfont",text="Maneuvering while unconcious"});
			-- but allow the maneuver to continue
		end

		-- Get Modifiers by Skill Name
		if sSkillName then
			if string.find(sSkillName, "Hide") then
				-- No Modifier
			elseif string.find(sSkillName, "Disarm Traps") or
						string.find(sSkillName, "Pick Locks") or 
						string.find(sSkillName, "Perception") then
				if nDamage > 0.75 then
				  table.insert(aModifiers, {description = "Wounded > 75%", number = -20});
				elseif nDamage > 0.5 then
				  table.insert(aModifiers, {description = "Wounded > 50%", number = -10});
				elseif nDamage > 0.25 then
				  table.insert(aModifiers, {description = "Wounded > 25%", number = -5});
				end
			else
				if nDamage > 0.75 then
				  table.insert(aModifiers, {description = "Wounded > 75%", number = -30});
				elseif nDamage > 0.5 then
				  table.insert(aModifiers, {description = "Wounded > 50%", number = -20});
				elseif nDamage > 0.25 then
				  table.insert(aModifiers, {description = "Wounded > 25%", number = -10});
				end
			end
		else
			if nDamage > 0.75 then
			  table.insert(aModifiers, {description = "Wounded > 75%", number = -30});
			elseif nDamage > 0.5 then
			  table.insert(aModifiers, {description = "Wounded > 50%", number = -20});
			elseif nDamage > 0.25 then
			  table.insert(aModifiers, {description = "Wounded > 25%", number = -10});
			end
		end
	end
end	

function Exhaustion(nodeActor)
	if not nodeActor then
		return "", 0;
	end

	local sDesc = "Not Exhausted";
	local nMod = 0;

	if string.lower(OptionsManager.getOption("CEEP")) ~= string.lower(Interface.getString("option_val_none")) then 
		local percent = DB.getValue(nodeActor, "exhaustion", 0) / DB.getValue(nodeActor, "exhaustion_total", 1) * 100;
		if string.lower(OptionsManager.getOption("CEEP")) == string.lower(Interface.getString("option_val_core")) then
			if percent >= 100 then
				sDesc = "Exhausted >= 100%";
				nMod = -100;
			end
		elseif string.lower(OptionsManager.getOption("CEEP")) == string.lower(Interface.getString("option_val_gradual")) then
			if percent >= 100 then
				sDesc = "Exhausted >= 100%";
				nMod = -100;
			elseif percent >= 90 then
				sDesc = "Exhausted >= 90%";
				nMod = -60;
			elseif percent >= 75 then
				sDesc = "Exhausted >= 75%";
				nMod = -30;
			elseif percent >= 50 then
				sDesc = "Exhausted >= 50%";
				nMod = -15;
			elseif percent >= 25 then
				sDesc = "Exhausted >= 25%";
				nMod = -5;
			end
		end
	end
	
	return sDesc, nMod;
end

function Effects(aModifiers, nodeActor, sSkillName)
	if nodeActor then
		local nStunMod = -50;
		local nSDMod = 0;
		local nBleedingAmount = 0;
		local nBleedingMod = 0;
		local nEffectsMod = 0;
		local sEffectsDesc;

		-- Get Effects Durations
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "Penalty", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "Penalty", number = vEffect.mod});
			end
		end
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "Bleeding", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				nBleedingAmount = vEffect.mod;
			end
		end
		
		-- Get Self Discipline Bonus
		nSDMod = DB.getValue(nodeActor, "abilities.selfdiscipline.total", 0);
		if nSDMod < 0 then
			nSDMod = 0;
		end
		
		-- Get Stun and Bleeding Modifiers by Skill Name
		if sSkillName then
			if string.find(sSkillName, "Speed") or string.find(sSkillName, "Strength") then
				nStunMod = -30;
				nBleedingMod = -10 * nBleedingAmount;
			elseif string.find(sSkillName, "Hide") then
				nStunMod = 0;
			elseif string.find(sSkillName, "Disarm Traps") then
				nBleedingMod = -5 * nBleedingAmount;
			elseif string.find(sSkillName, "Pick Locks") then
				nBleedingMod = -5 * nBleedingAmount;
			elseif string.find(sSkillName, "Perception") then
				nStunMod = -30;
				nBleedingMod = -5 * nBleedingAmount;
			else
				nBleedingMod = -10 * nBleedingAmount;
			end
		end
		
		-- Get Stun and Must Parry information
		if EffectManagerRMC.hasEffect(nodeActor, "NoParry") then
			nEffectsMod = -25 + nStunMod + nSDMod;
			sEffectsDesc = "Stun No Parry";
		elseif EffectManagerRMC.hasEffect(nodeActor, "Stun") then
			nEffectsMod = nStunMod + nSDMod;
			sEffectsDesc = "Stun";
		elseif EffectManagerRMC.hasEffect(nodeActor, "MustParry") then
			nEffectsMod = -25 + nSDMod;
			sEffectsDesc = "Must Parry";
		end
		
		if nEffectsMod > 0 then
			nEffectsMod = 0;
		end
		
		if EffectManagerRMC.hasEffect(nodeActor, "NoParry") or EffectManagerRMC.hasEffect(nodeActor, "Stun") or EffectManagerRMC.hasEffect(nodeActor, "MustParry") then
			table.insert(aModifiers, {description = sEffectsDesc, number = nEffectsMod});
		end
		
		if nBleedingAmount > 0 and nBleedingMod < 0 then
			table.insert(aModifiers, {description = "Bleeding", number = nBleedingMod});
		end
	end
end 

function Effects_OB(aModifiers, nodeActor)
	if nodeActor then
		-- Get OB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "OB", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "OB - Attacker Effects", number = vEffect.mod});
			end
		end
	end
end

function Effects_DB(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "DB", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "DB - Target Effects", number = -vEffect.mod, gmonly = true});
			end
		end
	end
end

function Effects_MM(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "MM", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "MM - Effects", number = vEffect.mod});
			end
		end
	end
end

function Effects_SM(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "SM", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "SM - Effects", number = vEffect.mod});
			end
		end
	end
end

function Effects_Skill(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "Skill", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "Skill - Effects", number = vEffect.mod});
			end
		end
	end
end

function Effects_RR(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "RR", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "RR - Effects", number = vEffect.mod});
			end
		end
	end
end

function Effects_Stat(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "Stat", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "Stat - Effects", number = vEffect.mod});
			end
		end
	end
end

function Effects_StatBonus(aModifiers, nodeActor)
	if nodeActor then
		-- Get DB Effects
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeActor, "StatBonus", true);
		if nEffectCount > 0 then
			for _, vEffect in pairs(aEffects) do
				table.insert(aModifiers, {description = "Stat Bonus - Effects", number = vEffect.mod});
			end
		end
	end
end

function TargetDefense(aModifiers, nodeAttacker, nodeTarget, bIsMissile)
	if not nodeTarget then
		return 0;
	end

	local nResult;
	local sNodeAttackerName = DB.getPath(nodeAttacker);

	-- general defence bonus
	nResult = -1 * DB.getValue(nodeTarget, "db", 0);
	table.insert(aModifiers, {description = "DB - Defense bonus", number = nResult, gmonly = true});
	
	-- Non-ID DB
	nResult = -1 * DB.getValue(nodeTarget, "db_nonid", 0);
	if nResult ~= 0 then
		table.insert(aModifiers, {description = "DB - Non-ID Items", number = nResult, gmonly = true});
	end

	-- DB from Effects
	Rules_Modifiers.Effects_DB(aModifiers, nodeTarget);
	
	-- Process CT defense entries
	for _,vDefense in pairs(DB.getChildren(nodeTarget, "defences")) do
		ProcessTargetDefense(aModifiers, sNodeAttackerName, nodeTarget, bIsMissile, vDefense);
	end

	-- Process PC defense entries
	if ActorManager.isPC(nodeTarget) then
		local nodePC = ActorManager.getCreatureNode(nodeTarget);
		for _,vAttackDefense in pairs(DB.getChildren(nodePC, "weapons")) do
			if DB.getValue(vAttackDefense, "type", "") == "Shield" then
				local sClass, sRecordName = DB.getValue(vAttackDefense, "open", nil);
				if sRecordName and sRecordName ~= "" then
					local nodeItem = DB.findNode(sRecordName);
					if nodeItem then
						ProcessTargetDefense(aModifiers, sNodeAttackerName, nodeTarget, bIsMissile, nodeItem);
					else
						ProcessTargetDefense(aModifiers, sNodeAttackerName, nodeTarget, bIsMissile, vAttackDefense);
					end
				end
			end
		end
	end
end

function ProcessTargetDefense(aModifiers, sNodeAttackerName, nodeTarget, bIsMissile, vDefense)
	local bApplyDefense = false;
	if DB.getValue(vDefense, "targetall", 0) == 1 then
		bApplyDefense = true;
	else
		for _, vTarget in pairs(DB.getChildren(nodeTarget, "targets")) do
			local sTargetNodeName = ActorManager.getCreatureNodeName(DB.getValue(vTarget, "noderef", ""));
			if vTarget and sTargetNodeName == sNodeAttackerName then
				bApplyDefense = true;
			end
		end
	end

	if bApplyDefense then
		local sDefenseName = DB.getValue(vDefense, "name", "");
		nResult = 0;
		if EffectManagerRMC.hasEffect(nodeTarget, "NoParry") and sDefenseName == "Parry" then -- Ignore Parry when NoParry effect is on target
			-- this is a weapon, but the defender is unable to parry, so don't include it in the DB
		elseif sDefenseName == "Parry" then
			-- adjust for any parry penalty
			local nParry = 0;
			local nParryPenalty = 0;
			local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(nodeTarget, "ParryPenalty", true);

			if nEffectCount > 0 then
				for _, vEffect in pairs(aEffects) do
					nParryPenalty = vEffect.mod;
				end
			end

			if bIsMissile then
				nParry = DB.getValue(vDefense, "missilebonus", 0) + nParryPenalty;
			else
				nParry = DB.getValue(vDefense, "meleebonus", 0) + nParryPenalty;
			end
			if nParry > 0 then
				nResult = nResult + nParry;
			end
		else
			if bIsMissile then
				nResult = nResult + DB.getValue(vDefense, "missilebonus", 0);
			else
				nResult = nResult + DB.getValue(vDefense, "meleebonus", 0);
			end
		end
		if nResult > 0 then
			nResult = nResult * -1;
			table.insert(aModifiers, {description = "DB - " .. sDefenseName, number = nResult, gmonly=true});
		end
	end
end

function TargetStunned(aModifiers, rTarget, sTableID)
	if EffectManagerRMC.hasEffect(rTarget, "Stun") or EffectManagerRMC.hasEffect(rTarget, "NoParry") then
		if sTableID == Rules_Constants.BaseSpellAttackTableID then
			table.insert(aModifiers, {description = "Static Target", number = 10, gmonly = true});
		else
			table.insert(aModifiers, {description = "Defender Stunned", number = 20, gmonly = true});
		end
	end
end

function AttackRange(aModifiers, nodeAttack, nRange, nReach)
	local sDistanceSuffix = GameSystem.getDistanceSuffix();
	if nRange >= 0 then
		local sType = DB.getValue(nodeAttack, "type", "");
		if (nRange and nReach and nRange > nReach) or Rules_Weapons.IsRanged(sType)  then
			local sRangeDesc = "Range " .. nRange .. sDistanceSuffix;
			local nRangeMod = 0;
			
			if nRange <= DB.getValue(nodeAttack, "rng1", 0) then
				nRangeMod = DB.getValue(nodeAttack, "mod1", 0);
				sRangeDesc = sRangeDesc .. " <= " .. DB.getValue(nodeAttack, "rng1", 0) .. sDistanceSuffix;
			elseif nRange <= DB.getValue(nodeAttack, "rng2", 0) then
				nRangeMod = DB.getValue(nodeAttack, "mod2", 0);
				sRangeDesc = sRangeDesc .. " <= " .. DB.getValue(nodeAttack, "rng2", 0) .. sDistanceSuffix;
			elseif nRange <= DB.getValue(nodeAttack, "rng3", 0) then
				nRangeMod = DB.getValue(nodeAttack, "mod3", 0);
				sRangeDesc = sRangeDesc .. " <= " .. DB.getValue(nodeAttack, "rng3", 0) .. sDistanceSuffix;
			elseif nRange <= DB.getValue(nodeAttack, "rng4", 0) then
				nRangeMod = DB.getValue(nodeAttack, "mod4", 0);
				sRangeDesc = sRangeDesc .. " <= " .. DB.getValue(nodeAttack, "rng4", 0) .. sDistanceSuffix;
			elseif nRange <= DB.getValue(nodeAttack, "rng5", 0) then
				nRangeMod = DB.getValue(nodeAttack, "mod5", 0);
				sRangeDesc = sRangeDesc .. " <= " .. DB.getValue(nodeAttack, "rng5", 0) .. sDistanceSuffix;
			elseif nRange <= DB.getValue(nodeAttack, "rng6", 0) then
				nRangeMod = DB.getValue(nodeAttack, "mod6", 0);
				sRangeDesc = sRangeDesc .. " <= " .. DB.getValue(nodeAttack, "rng6", 0) .. sDistanceSuffix;
			else
				sRangeDesc = sRangeDesc .. " > MAX";
			end

			table.insert(aModifiers, {description = sRangeDesc, number = nRangeMod});
		end
	end
end

function BonusVsAT(aModifiers, nodeItem, nAT)
	local nATBonus = 0;
	
	-- bonus vs armor type
	if nAT < 5 then
		nATBonus = DB.getValue(nodeItem, "at1_4", 0);
	elseif nAT < 9 then
		nATBonus = DB.getValue(nodeItem, "at5_8", 0);
	elseif nAT < 13 then
		nATBonus = DB.getValue(nodeItem, "at9_12", 0);
	elseif nAT < 17 then
		nATBonus = DB.getValue(nodeItem, "at13_16", 0);
	else
		nATBonus = DB.getValue(nodeItem, "at17_20", 0);
	end

	if nATBonus ~= 0 then
		table.insert(aModifiers, {description = "Bonus vs AT" .. nAT, number = nATBonus, gmonly=true});
	end
end

function ArmorMissilePenalty(aModifiers, nodeAttacker)
	local nMissilePenalty = DB.getValue(nodeAttacker, "atmiss", 0);

	if nMissilePenalty < 0 then
		table.insert(aModifiers, {description = "Armor missile penalty", number = nMissilePenalty});
	end
end

function OB_NonID(aModifiers, nodeAttack)
	local nOBNonID = DB.getValue(nodeAttack, "ob_nonid", 0);
	if nOBNonID ~= 0 then
		table.insert(aModifiers, {description = "OB - Non-ID Items", number = nOBNonID, gmonly = true});
	end

end

function MovementManueverModifier(aModifiers, nodeActor, sSkillName, nArmorFactor)
	local nFactor = 1;
	-- get Armor Factor if available, if not use the default multiplier of 1
	if nArmorFactor then
		nFactor = nArmorFactor;
	end

	if sSkillName == ActionSkill.GenericMM then
		local sOptOOMM = string.lower(OptionsManager.getOption("OOMM"));
		local nStatMod = 0;
		if sOptOOMM == string.lower(Interface.getString("option_val_ag")) then
			nStatMod = DB.getValue(nodeActor, "abilities.agility.total", 0);
			table.insert(aModifiers, {description = "Ag bonus", number = nStatMod});	
		elseif sOptOOMM == string.lower(Interface.getString("option_val_qu")) then
			nStatMod = DB.getValue(nodeActor, "abilities.quickness.total", 0);
			table.insert(aModifiers, {description = "Qu bonus", number = nStatMod});	
		elseif sOptOOMM == string.lower(Interface.getString("option_val_ag_qu")) then
			nStatMod = math.floor((DB.getValue(nodeActor, "abilities.agility.total", 0) + DB.getValue(nodeActor, "abilities.quickness.total", 0)) / 2);
			table.insert(aModifiers, {description = "Ag/Qu bonus", number = nStatMod});	
		end
	elseif sSkillName == ActionSkill.MovementMM then
		local sOptOOMV = string.lower(OptionsManager.getOption("OOMV"));
		local nStatMod = 0;
		if sOptOOMV == string.lower(Interface.getString("option_val_ag")) then
			nStatMod = DB.getValue(nodeActor, "abilities.agility.total", 0);
			table.insert(aModifiers, {description = "Ag bonus", number = nStatMod});	
		elseif sOptOOMV == string.lower(Interface.getString("option_val_qu")) then
			nStatMod = DB.getValue(nodeActor, "abilities.quickness.total", 0);
			table.insert(aModifiers, {description = "Qu bonus", number = nStatMod});	
		elseif sOptOOMV == string.lower(Interface.getString("option_val_ag_qu")) then
			nStatMod = math.floor((DB.getValue(nodeActor, "abilities.agility.total", 0) + DB.getValue(nodeActor, "abilities.quickness.total", 0)) / 2);
			table.insert(aModifiers, {description = "Ag/Qu bonus", number = nStatMod});	
		end
	end

	-- adjust MM rolls for armor penalties and the Moving in <Armor Type> skill
	local nMMPenalty = 0;
	if DB.getChild(nodeActor, "mmpenalty") then
		nMMPenalty = DB.getValue(nodeActor, "mmpenalty", 0);
	else
		nMMPenalty = Rules_PC.MMPenalty(nodeActor);
	end
	if nMMPenalty < 0 and nFactor > 0 then
		if nFactor == 1 then
			table.insert(aModifiers, {description = "Armor penalty", number = nMMPenalty});
		else
			table.insert(aModifiers, {description = "Armor penalty (x" .. nFactor .. ")", number = nMMPenalty * nFactor});
		end
	end
	
	-- check NPC MN Bonus
	if DB.getChild(nodeActor, "mnbonus") then
		table.insert(aModifiers, {description = "MN bonus", number = DB.getValue(nodeActor, "mnbonus", 0)});
	end

	-- Modifiers from Effects
	Rules_Modifiers.Effects_MM(aModifiers, nodeActor);
end

function EncumbrancePenalty(nEncAllowance, nEncLoad)
	local nEncPenalty = 0;
	
	if nEncAllowance ~=0 then
		local nFrac = nEncLoad / nEncAllowance;
		nEncPenalty = -10 * math.ceil(nFrac) + 10;
		if nFrac > 14 then
			nEncPenalty = -120;
		elseif nFrac > 6 then
			nEncPenalty = nEncPenalty + 20;
		elseif nFrac > 3 then
			nEncPenalty = (math.ceil(nFrac) + 1) * -5;
		elseif nFrac <=1 then
			nEncPenalty = 0;
		end
	end

	return nEncPenalty;
end
