-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerDiceRolls();
	registerOptions();
	
	Module.onModuleLoad = onModuleLoad;
	Module.onModuleUnload = onModuleUnload;
	
end

function registerDiceRolls()
	
	-- Attack Tables
	DiceRollManager.setDiceSkinDefaults("armslaw", { { diceskin = 0, dicebodycolor="999999", dicetextcolor="000000" } } );
	DiceRollManager.setDiceSkinDefaults("clawlaw", { { diceskin = 0, dicebodycolor="4D2200", dicetextcolor="FFFFFF" } } );
	DiceRollManager.setDiceSkinDefaults("armoury", { { diceskin = 0, dicebodycolor="999999", dicetextcolor="000000" } } );
	DiceRollManager.setDiceSkinDefaults("fantasyweapons", { { diceskin = 0, dicebodycolor="999999", dicetextcolor="000000" } } );

	DiceRollManagerRMC.registerAttackKey();
	DiceRollManagerRMC.registerAttackTypeKey("armslaw", "armslaw");
	DiceRollManagerRMC.registerAttackTypeKey("clawlaw", "clawlaw");
	DiceRollManagerRMC.registerAttackTypeKey("armoury", "armoury");
	DiceRollManagerRMC.registerAttackTypeKey("fantasyweapons", "fantasyweapons");
	DiceRollManagerRMC.registerAttackTypeKey("coldball", "frost");
	DiceRollManagerRMC.registerAttackTypeKey("icebolt", "frost");
	DiceRollManagerRMC.registerAttackTypeKey("fireball", "fire");
	DiceRollManagerRMC.registerAttackTypeKey("firebolt", "fire");
	DiceRollManagerRMC.registerAttackTypeKey("lightningbolt", "lightning");
	DiceRollManagerRMC.registerAttackTypeKey("shockbolt", "lightning");
	DiceRollManagerRMC.registerAttackTypeKey("waterbolt", "water");

	-- Result Tables
	DiceRollManagerRMC.registerResultTableKey();
	DiceRollManagerRMC.registerResultTableTypeKey("grapple", "life");
	DiceRollManagerRMC.registerResultTableTypeKey("krush", "earth");
	DiceRollManagerRMC.registerResultTableTypeKey("mathrows", "water");
	DiceRollManagerRMC.registerResultTableTypeKey("mastrikes", "water");
	DiceRollManagerRMC.registerResultTableTypeKey("puncture", "earth");
	DiceRollManagerRMC.registerResultTableTypeKey("slash", "earth");
	DiceRollManagerRMC.registerResultTableTypeKey("tiny", "life");
	DiceRollManagerRMC.registerResultTableTypeKey("unbalancing", "life");
	DiceRollManagerRMC.registerResultTableTypeKey("largearms", "storm");
	DiceRollManagerRMC.registerResultTableTypeKey("superlargearms", "storm");
	DiceRollManagerRMC.registerResultTableTypeKey("weaponfumble", "shadow");
	DiceRollManagerRMC.registerResultTableTypeKey("nonweaponfumble", "shadow");
	DiceRollManagerRMC.registerResultTableTypeKey("cold", "frost");
	DiceRollManagerRMC.registerResultTableTypeKey("electricity", "lightning");
	DiceRollManagerRMC.registerResultTableTypeKey("heat", "fire");
	DiceRollManagerRMC.registerResultTableTypeKey("impact", "arcane");
	DiceRollManagerRMC.registerResultTableTypeKey("largespells", "light");
	DiceRollManagerRMC.registerResultTableTypeKey("superlargespells", "light");
	DiceRollManagerRMC.registerResultTableTypeKey("nonattackspellfailure", "shadow");
	DiceRollManagerRMC.registerResultTableTypeKey("attackspellfailure", "shadow");
	DiceRollManagerRMC.registerResultTableTypeKey("subdual", "light");
	
	-- Realms/RRs
	DiceRollManagerRMC.registerRealmRRKey();
	DiceRollManagerRMC.registerRealmRRTypeKey("channeling", "water");
	DiceRollManagerRMC.registerRealmRRTypeKey("essence", "fire");
	DiceRollManagerRMC.registerRealmRRTypeKey("mentalism", "life");
	DiceRollManagerRMC.registerRealmRRTypeKey("channelingessence", "storm");
	DiceRollManagerRMC.registerRealmRRTypeKey("channelingmentalism", "light");
	DiceRollManagerRMC.registerRealmRRTypeKey("essencementalism", "frost");
	DiceRollManagerRMC.registerRealmRRTypeKey("arcane", "arcane");
	DiceRollManagerRMC.registerRealmRRTypeKey("disease", "earth");
	DiceRollManagerRMC.registerRealmRRTypeKey("poison", "shadow");
	DiceRollManagerRMC.registerRealmRRTypeKey("terror", "lightning");
end

function registerOptions()
	OptionsManager.registerOption2("INIT", false, "option_header_combat", "option_label_INIT", "option_entry_cycler", 
			{ labels = "option_val_on|option_val_group", values = "on|group", baselabel = "option_val_off", baseval = "off", default = "group" });
	OptionsManager.registerOption2("INTD", false, "option_header_combat", "option_label_INTD", "option_entry_cycler", 
			{ labels = "option_val_d100|option_val_open_ended|option_val_high_open_ended|option_val_low_open_ended", values = "d100|Open-Ended|High Open-Ended|Low Open-Ended", baselabel = "option_val_2d10", baseval = "Core: 2d10", default = "Core: 2d10" });
	OptionsManager.registerOption2("INTA", false, "option_header_combat", "option_label_INTA", "option_entry_cycler", 
			{ labels = "option_val_npcs|option_val_pcs|option_val_both", values = "NPCs Only|PCs Only|PCs and NPCs", baselabel = "option_val_none", baseval = "None", default = "None" });
	OptionsManager.registerOption2("INTC", false, "option_header_combat", "option_label_INTC", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SETC", false, "option_header_combat", "option_label_SETC", "option_entry_cycler", 
			{ labels = "option_val_off|option_val_on", values = "off|on", baselabel = "option_val_gmonly", baseval = "gm only", default = "gm only" });
	OptionsManager.registerOption2("SEPC", false, "option_header_combat", "option_label_SEPC", "option_entry_cycler", 
			{ labels = "option_val_gmonly", values = "gm only", baselabel = "option_val_all", baseval = "all", default = "all" });
	OptionsManager.registerOption2("SENPC", false, "option_header_combat", "option_label_SENPC", "option_entry_cycler", 
			{ labels = "option_val_all", values = "all", baselabel = "option_val_gmonly", baseval = "gm only", default = "gm only" });
	OptionsManager.registerOption2("TSDU", false, "option_header_combat", "option_label_TSDU", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TRCS", false, "option_header_combat", "option_label_TRCS", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TRRR", false, "option_header_combat", "option_label_TRRR", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TRAR", false, "option_header_combat", "option_label_TRAR", "option_entry_cycler", 
			{ labels = "option_val_first_critical|option_val_all_criticals|option_val_fumbles|option_val_first_critical_fumbles|option_val_all_criticals_fumbles", values = "First Critical|All Criticals|Fumbles|1st Crit/Fumbles|All Crits/Fumbles", baselabel = "option_val_none", baseval = "None", default = "None" });
	OptionsManager.registerOption2("TRSO", false, "option_header_combat", "option_label_TRSO", "option_entry_cycler", 
			{ labels = "option_val_ascending|option_val_descending", values = "Ascending|Descending", baselabel = "option_val_standard", baseval = "Standard", default = "Standard" });
	OptionsManager.registerOption2("SHPC", false, "option_header_combat", "option_label_SHPC", "option_entry_cycler", 
			{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "detailed" });
	OptionsManager.registerOption2("SHNPC", false, "option_header_combat", "option_label_SHNPC", "option_entry_cycler", 
			{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "status" });
	OptionsManager.registerOption2("MISP", false, "option_header_combat", "option_label_MISP", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TSEC", false, "option_header_combat", "option_label_TSEC", "option_entry_cycler", 
			{ labels = "option_val_attack_defense|option_val_attack_move|option_val_attack_defense_move|option_val_none", values = "Attack/Defense|Attack/Move|All Three|None", baselabel = "option_val_attack", baseval = "Attack", default = "Attack" });
	OptionsManager.registerOption2("NCON", false, "option_header_combat", "option_label_NCON", "option_entry_cycler", 
			{ labels = "option_val_co_50|option_val_co_npc", values = "50 constitution|npc hits", baselabel = "option_val_co_1", baseval = "1 constitution", default = "1 constitution" });
	OptionsManager.registerOption2("DDTA", false, "option_header_combat", "option_label_DDTA", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("NRLH", false, "option_header_combat", "option_label_NRLH", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("CCAD", false, "option_header_character", "option_label_CCAD", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("CCHP", false, "option_header_character", "option_label_CCHP", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("CCPP", false, "option_header_character", "option_label_CCPP", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("CGEN", false, "option_header_character", "option_label_CGEN", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CMSG", false, "option_header_character", "option_label_CMSG", "option_entry_cycler", 
			{ labels = "option_val_30|option_val_40|option_val_50|option_val_60|option_val_70|option_val_80|option_val_90|option_val_10", values = "30|40|50|60|70|80|90|10", baselabel = "option_val_20", baseval = "20", default = "20" });
	OptionsManager.registerOption2("CEEP", false, "option_header_character", "option_label_CEEP", "option_entry_cycler", 
			{ labels = "option_val_core|option_val_gradual", values = "Core|Gradual", baselabel = "option_val_none", baseval = "None", default = "Core" });
	OptionsManager.registerOption2("CEAT", false, "option_header_character", "option_label_CEAT", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CEMD", false, "option_header_character", "option_label_CEMD", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CEMV", false, "option_header_character", "option_label_CEMV", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("RRRM", false, "option_header_character", "option_label_RRRM", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("AL14", false, "option_header_optionalrules", "option_label_AL14", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CL01", false, "option_header_optionalrules", "option_label_CL01", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CL07", false, "option_header_optionalrules", "option_label_CL07", "option_entry_cycler", 
			{ labels = "option_val_randomfixed|option_val_threecolumn", values = "7.1: Random Fixed|7.2: Three Column", baselabel = "option_val_random", baseval = "Core: Random", default = "Core: Random" });
	OptionsManager.registerOption2("CL111", false, "option_header_optionalrules", "option_label_CL111", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CL112", false, "option_header_optionalrules", "option_label_CL112", "option_entry_cycler", 
			{ labels = "option_val_25|option_val_30|option_val_40|option_val_50|option_val_60|option_val_70|option_val_80|option_val_90|option_val_100", values = "25|30|40|50|60|70|80|90|100", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CL113", false, "option_header_optionalrules", "option_label_CL113", "option_entry_cycler", 
			{ labels = "option_val_30|option_val_40|option_val_50|option_val_60|option_val_70|option_val_75|option_val_80|option_val_90|option_val_100|option_val_150|option_val_200|option_val_0|option_val_10|option_val_20", values = "30|40|50|60|70|75|80|90|100|150|200|0|10|20", baselabel = "option_val_25", baseval = "25", default = "25" });
	OptionsManager.registerOption2("CL16", false, "option_header_optionalrules", "option_label_CL16", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CL23G", false, "option_header_optionalrules", "option_label_CL23G", "option_entry_cycler", 
			{ labels = "option_val_opt23_1|option_val_opt23_2|option_val_rmc2|option_val_none", values = "RM2 (Opt23.1)|RMFRP (Opt23.2)|RM Companion II|None", baselabel = "option_val_core", baseval = "Core", default = "Core" });
	OptionsManager.registerOption2("CL23T", false, "option_header_optionalrules", "option_label_CL23T", "option_entry_cycler", 
			{ labels = "option_val_opt23_3|option_val_opt23_4", values = "Stepped (Opt23.3)|Static (Opt23.4)", baselabel = "option_val_core", baseval = "Core", default = "Core" });
	OptionsManager.registerOption2("CL24", false, "option_header_optionalrules", "option_label_CL24", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SL04", false, "option_header_optionalrules", "option_label_SL04", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("OOMM", false, "option_header_optionalrules", "option_label_OOMM", "option_entry_cycler", 
			{ labels = "option_val_ag|option_val_qu|option_val_ag_qu", values = "AG|QU|AG/QU", baselabel = "option_val_none", baseval = "None", default = "AG" });
	OptionsManager.registerOption2("OOMV", false, "option_header_optionalrules", "option_label_OOMV", "option_entry_cycler", 
			{ labels = "option_val_ag|option_val_qu|option_val_ag_qu", values = "AG|QU|AG/QU", baselabel = "option_val_none", baseval = "None", default = "AG/QU" });
	OptionsManager.registerOption2("OMOV", false, "option_header_optionalrules", "option_label_OMOV", "option_entry_cycler", 
			{ labels = "option_val_rmc4|option_val_rmc6|option_val_rmfrp", values = "RM Companion IV|RM Companion VI|RMFRP/RMSS", baselabel = "option_val_armslaw", baseval = "Core: Arms Law", default = "Core: Arms Law" });
	OptionsManager.registerOption2("RC552", false, "option_header_optionalrules", "option_label_RC552", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	-- Check for Module related Options
	for k, sModule in pairs(Module.getModules()) do
		if Module.getModuleInfo(sModule).loaded then
			onModuleLoad(sModule);
		end
	end
	
end

function onModuleLoad(sModule)
	if (sModule == "Rolemaster Companion 1" and Module.getModuleInfo(sModule).author == "Aurigas Aldeberon LLC, 2020" and Module.getModuleInfo(sModule).loaded) or not Session.IsHost then
		OptionsManager.registerOption2("RC422", false, "option_header_companion1", "option_label_RC422", "option_entry_cycler", 
				{ labels = "option_val_elves|option_val_halflings|option_val_elves_halflings", values = "elves|halflings|elves/halflings", baselabel = "option_val_none", baseval = "none", default = "none" });
		OptionsManager.registerOption2("RC422A", false, "option_header_companion1", "option_label_RC422A", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422B", false, "option_header_companion1", "option_label_RC422B", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422C", false, "option_header_companion1", "option_label_RC422C", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422D", false, "option_header_companion1", "option_label_RC422D", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422E", false, "option_header_companion1", "option_label_RC422E", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422F", false, "option_header_companion1", "option_label_RC422F", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422G", false, "option_header_companion1", "option_label_RC422G", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC422H", false, "option_header_companion1", "option_label_RC422H", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
		OptionsManager.registerOption2("RC44B", false, "option_header_companion1", "option_label_RC44B", "option_entry_cycler", 
				{ labels = "option_val_linear|option_val_smooth", values = "linear|smooth", baselabel = "option_val_core", baseval = "core", default = "core" });
		OptionsManager.registerOption2("RC44D", false, "option_header_companion1", "option_label_RC44D", "option_entry_cycler", 
				{ labels = "option_val_linear|option_val_smooth", values = "linear|smooth", baselabel = "option_val_core", baseval = "core", default = "core" });
		OptionsManager.registerOption2("RC44P", false, "option_header_companion1", "option_label_RC44P", "option_entry_cycler", 
				{ labels = "option_val_linear|option_val_smooth", values = "linear|smooth", baselabel = "option_val_core", baseval = "core", default = "core" });
		OptionsManager.registerOption2("RC48B", false, "option_header_companion1", "option_label_RC48B", "option_entry_cycler", 
				{ labels = "option_val_option1|option_val_option2", values = "Option 1|Option 2", baselabel = "option_val_core", baseval = "core", default = "core" });
		OptionsManager.registerOption2("RC48D", false, "option_header_companion1", "option_label_RC48D", "option_entry_cycler", 
				{ labels = "option_val_option1|option_val_option2", values = "Option 1|Option 2", baselabel = "option_val_core", baseval = "core", default = "core" });
		OptionsManager.registerOption2("RC48P", false, "option_header_companion1", "option_label_RC48P", "option_entry_cycler", 
				{ labels = "option_val_option1|option_val_option2", values = "Option 1|Option 2", baselabel = "option_val_core", baseval = "core", default = "core" });
	end
end

function onModuleUnload(sModule)
	if sModule == "Rolemaster Companion 1" and Module.getModuleInfo(sModule).author == "Aurigas Aldeberon LLC, 2020" then
		OptionsManager.deleteOption("RC422");
		OptionsManager.deleteOption("RC422A");
		OptionsManager.deleteOption("RC422B");
		OptionsManager.deleteOption("RC422C");
		OptionsManager.deleteOption("RC422D");
		OptionsManager.deleteOption("RC422E");
		OptionsManager.deleteOption("RC422F");
		OptionsManager.deleteOption("RC422G");
		OptionsManager.deleteOption("RC422H");
		OptionsManager.deleteOption("RC44B");
		OptionsManager.deleteOption("RC44D");
		OptionsManager.deleteOption("RC44P");
		OptionsManager.deleteOption("RC48B");
		OptionsManager.deleteOption("RC48D");
		OptionsManager.deleteOption("RC48P");
	end
end
