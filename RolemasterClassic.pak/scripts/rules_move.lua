-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Move Constants
PaceNone = "x0 None";
PaceCrawl = "x0.5 Crawl/Stalk";
PaceWalk = "x1 Walk";
PaceJog = "x1.5 Jog";
PaceRun = "x2 Run";
PaceSprint = "x3 Sprint";
PaceFastSprint = "x4 Fast Sprint";
PaceDash = "x5 Dash";

-- Move Constants
Paces = { 	
			{ 
				name = PaceNone,
				multiplier = 0,
				exhaustion = 0,
				difficultyRMC = "None",
				difficultyRM4 = "None",
				difficultyRM6 = "None",
				difficultyRMFRP = "None"
			}, 
			{ 
				name = PaceCrawl,
				multiplier = 0.5,
				exhaustion = 1/30,
				difficultyRMC = "None",
				difficultyRM4 = "None",
				difficultyRM6 = "None",
				difficultyRMFRP = "None"
			}, 
			{ 
				name = PaceWalk,
				multiplier = 1,
				exhaustion = 1/30,
				difficultyRMC = "None",
				difficultyRM4 = "None",
				difficultyRM6 = "None",
				difficultyRMFRP = "None"
			}, 
			{ 
				name = PaceJog,
				multiplier = 1.5,
				exhaustion = 1/6,
				difficultyRMC = "Routine",
				difficultyRM4 = "Routine",
				difficultyRM6 = "None",
				difficultyRMFRP = "None"
			}, 
			{ 
				name = PaceRun,
				multiplier = 2,
				exhaustion = 1/2,
				difficultyRMC = "Easy",
				difficultyRM4 = "Routine",
				difficultyRM6 = "None",
				difficultyRMFRP = "None"
			}, 
			{ 
				name = PaceSprint,
				multiplier = 3,
				exhaustion = 5,
				difficultyRMC = "Light",
				difficultyRM4 = "Easy",
				difficultyRM6 = "None",
				difficultyRMFRP = "Easy"
			}, 
			{ 
				name = PaceFastSprint,
				multiplier = 4,
				exhaustion = 25,
				difficultyRMC = "Medium",
				difficultyRM4 = "Easy",
				difficultyRM6 = "None",
				difficultyRMFRP = "Light"
			}, 
			{ 
				name = PaceDash,
				multiplier = 5,
				exhaustion = 40,
				difficultyRMC = "Hard",
				difficultyRM4 = "Light",
				difficultyRM6 = "None",
				difficultyRMFRP = "Medium"
			} 
		}
				
-- Get Base Movement Rate
function BaseMovementRate(sHeight)
	local sFeet, sInches = HeightFeetInches(sHeight);
	local nFeet = tonumber(sFeet);
	local nInches = tonumber(sInches);
	local nTotalHeight;
	
	if not nFeet then
		nFeet = 0;
	end
	if not nInches then
		nInches = 0;
	end

	nTotalHeight = nFeet + (nInches/12);
	if nTotalHeight >= 10.83 then
		return 100;
	elseif nTotalHeight >= 10.33 then
		return 95;
	elseif nTotalHeight >= 9.83 then
		return 90;
	elseif nTotalHeight >= 9.33 then
		return 85;
	elseif nTotalHeight >= 8.83 then
		return 80;
	elseif nTotalHeight >= 8.33 then
		return 75;
	elseif nTotalHeight >= 7.83 then
		return 70;
	elseif nTotalHeight >= 7.33 then
		return 65;
	elseif nTotalHeight >= 6.83 then
		return 60;
	elseif nTotalHeight >= 6.33 then
		return 55;
	elseif nTotalHeight >= 5.83 then
		return 50;
	elseif nTotalHeight >= 5.33 then
		return 45;
	elseif nTotalHeight >= 4.83 then
		return 40;
	elseif nTotalHeight >= 4.33 then
		return 35;
	elseif nTotalHeight >= 3.83 then
		return 30;
	elseif nTotalHeight >= 3.33 then
		return 25;
	elseif nTotalHeight >= 2.83 then
		return 20;
	elseif nTotalHeight >= 2.33 then
		return 15;
	elseif nTotalHeight >= 1.83 then
		return 10;
	elseif nTotalHeight >= 1.33 then
		return 5;
	elseif nTotalHeight == 0 then
		return 50;
	else		
		return 0;
	end
end

-- Convert Height String to Feet and Inches
function HeightFeetInches(sHeight)
	local nLocFeet = string.find(sHeight, "'");
	local nLocInchesStart;
	local nLocInchesEnd;
	local nFeet = 0;
	local nInches = 0;
	if nLocFeet then
		nLocInchesStart = nLocFeet + 1;
	else
		nLocFeet = string.find(string.upper(sHeight), "F");
		if nLocFeet then
			if string.find(string.upper(sHeight), "FEET", nLocFeet) then
				nLocInchesStart = nLocFeet + 4;
			elseif string.find(string.upper(sHeight), "FT", nLocFeet) then
				nLocInchesStart = nLocFeet + 2;
			else
				nLocInchesStart = nLocFeet + 1;
			end
		else
			nLocInchesStart = 1;
		end
	end
	if nLocFeet then
		nFeet = string.sub(sHeight, 1, nLocFeet - 1);
	else
		nFeet = sHeight;
	end
	nLocInchesEnd = string.find(sHeight, "\"");
	if nLocInchesEnd then
		nInches = string.sub(sHeight, nLocInchesStart, string.len(sHeight) - 1);
	else
		nInches = string.sub(sHeight, nLocInchesStart);
	end
	if string.len(nInches) == 0 then
		nInches = 0;
	end
	
	return nFeet, nInches;
end

-- Get Pace List
function PaceList()
	local aPaceList = {};
	for _, vPace in pairs(Paces) do
		table.insert(aPaceList, vPace.name);
	end
	return aPaceList;
end

-- Get Pace MM Difficulty
function PaceDifficulty(sCurrentPace)
	local sOptOMOV = string.lower(OptionsManager.getOption("OMOV"));
	local sDifficulty = "None";

	for _, vPace in pairs(Paces) do
		if sCurrentPace == vPace.name then
			if sOptOMOV == string.lower(Interface.getString("option_val_armslaw")) then			
				sDifficulty = vPace.difficultyRMC;
			elseif sOptOMOV == string.lower(Interface.getString("option_val_rmc4")) then			
				sDifficulty = vPace.difficultyRM4;
			elseif sOptOMOV == string.lower(Interface.getString("option_val_rmc6")) then			
				sDifficulty = vPace.difficultyRM6;
			elseif sOptOMOV == string.lower(Interface.getString("option_val_rmfrp")) then			
				sDifficulty = vPace.difficultyRMFRP;
			else
				sDifficulty = vPace.difficultyRMC;
			end
		end
	end

	return sDifficulty;
end

-- Get Pace Movement Mulitplier
function PaceMultiplier(sCurrentPace)
	local nMultiplier = 0;
	for _, vPace in pairs(Paces) do
		if sCurrentPace == vPace.name then
			nMultiplier = vPace.multiplier;
		end
	end
	return nMultiplier;
end

-- Get Pace Exhaustion per Round
function PaceExhaustion(sPace)
	local nExhaustion = 0;
	
	if sPace == Rules_Move.PaceWalk then
		nExhaustion = 1/30;
	elseif sPace == Rules_Move.PaceJog then
		nExhaustion = 1/6;
	elseif sPace == Rules_Move.PaceRun then
		nExhaustion = 1/2;
	elseif sPace == Rules_Move.PaceSprint then
		nExhaustion = 5;
	elseif sPace == Rules_Move.PaceFastSprint then
		nExhaustion = 25;
	elseif sPace == Rules_Move.PaceDash then
		nExhaustion = 40;
	end

	return math.floor(nExhaustion * 100) / 100;
end

function PaceNone()
	return Paces[1].name;
end
