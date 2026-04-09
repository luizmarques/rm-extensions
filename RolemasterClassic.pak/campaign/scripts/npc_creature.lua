-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function updateRollField(sControl, bReadOnly)
	self[sControl].setReadOnly(bReadOnly);
	if bReadOnly then
		self[sControl].setTooltipText("");
	else
		self[sControl].setTooltipText("Double click to roll");
	end
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	iq.setEnabled(not bReadOnly);
	outlook_d.setReadOnly(bReadOnly);
	outlook.setEnabled(not bReadOnly);

	levelcode.setReadOnly(bReadOnly);
	updateRollField("levelcode_roll", bReadOnly);

	hitscode.setReadOnly(bReadOnly);
	updateRollField("hitscode_roll", bReadOnly);

	num.setReadOnly(bReadOnly);
	freq.setEnabled(not bReadOnly);

	climate.setReadOnly(bReadOnly);
	locale.setReadOnly(bReadOnly);
	treasure.setReadOnly(bReadOnly);
	bonusep.setReadOnly(bReadOnly);
	bonusep_lvl.setReadOnly(bReadOnly);

end

-- Calculates NPC's variable level and hits using Level/Constitution codes and random rolls.
function Variability()
	local roll, row, code, levelmod;
	roll = levelcode_roll.getValue();
	if roll == nil then levelmod = 0;
	else
		if roll <= 1 then row = 1;
		elseif roll<=10 then row=2; 
		elseif roll<=15 then row=3; 
		elseif roll<=20 then row=4;
		elseif roll<=25 then row=5;
		elseif roll<=35 then row=6;
		elseif roll<=45 then row=7;
		elseif roll<=55 then row=8;
		elseif roll<=65 then row=9;
		elseif roll<=75 then row=10;
		elseif roll<=80 then row=11;
		elseif roll<=85 then row=12;
		elseif roll<=90 then row=13;
		elseif roll<=100 then row=14;
		elseif roll<=140 then row=15;
		elseif roll<=170 then row=16;
		elseif roll<=190 then row=17;
		elseif roll<=200 then row=18;
		elseif roll<=250 then row=19;
		elseif roll<=300 then row=20;
		else row=21;
		end
		local A = {-99,-1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,3,4};
		local B = {-99,-2,-1,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,6};
		local C = {-99,-3,-2,-1,0,0,0,0,0,0,0,1,1,2,2,3,4,5,6,7,8};
		local D = {-99,-4,-3,-2,-1,0,0,0,0,0,1,2,3,4,5,6,7,8,9,10,11};
		local E = {-99,-5,-4,-3,-2,-1,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12};
		local F = {-99,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13};
		local G = {-99,-10,-8,-6,-4,-2,-1,0,1,2,4,6,8,10,11,12,13,14,15,16,17};
		local H = {-3,-2,-2,-1,-1,-1,0,0,0,1,1,1,2,2,3,3,3,3,3,4,4};
		code = levelcode.getValue();
		if code == "A" then levelmod = A[row]; 
		elseif code == "B" then levelmod = B[row];
		elseif code == "C" then levelmod = C[row];
		elseif code == "D" then levelmod = D[row];
		elseif code == "E" then levelmod = E[row];
		elseif code == "F" then levelmod = F[row];
		elseif code == "G" then levelmod = G[row];
		elseif code == "H" then levelmod = H[row];
		else levelmod=0;
		end
	end

	local con = hitscode_roll.getValue();
	local hitsperlvl, EP, conbon = 0,0,0;
	if con ~= nil then 
		if con < 01 then con=01 elseif con>100 then con=100; end
			EP = con;
			code = hitscode.getValue();
			if code == "A" then
				hitsperlvl = 1;
				if con==1 then conbon=-15 elseif con<=9 then conbon=-10 elseif con<=25 then conbon=-5 
				elseif con<=74 then conbon=0 elseif con<=91 then conbon=5 elseif con<=00 then conbon=10 else conbon=15; end
				elseif code == "B" then
					hitsperlvl = 2;
				if con==1 then conbon=-20 elseif con<=4 then conbon=-15 elseif con<=11 then conbon=-10 elseif con<=31 then conbon=-5
				elseif con<=69 then conbon=0 elseif con<=89 then conbon=5 elseif con<=96 then conbon=10 elseif con<=99 then conbon=15 else conbon=20; end
				elseif code == "C" then
					hitsperlvl = 3;
				if con==1 then conbon=-25 elseif con<=3 then conbon=-20 elseif con<=8 then conbon=-15 elseif con<=23 then conbon=-10
				elseif con<=74 then conbon=-5 elseif con<=89 then conbon=0 elseif con<=94 then conbon=5
				elseif con<=97 then conbon=10 elseif con<=99 then conbon=15 else conbon=20; end
				elseif code == "D" then
					hitsperlvl = 5;
				if con==1 then conbon=-25 elseif con==2 then conbon=-20 elseif con<=4 then conbon=-15 elseif con<=9 then conbon=-10
				elseif con<=24 then connbon=-5 elseif con<=74 then conbon=0 elseif con<=89 then conbon=5
				elseif con<=94 then conbon=10 elseif con<=97 then conbon=15 elseif con<=99 then conbon=20 else conbon=25; end
				elseif code == "E" then
					hitsperlvl = 8;
					EP = EP+50;
				if con==1 then conbon=-25 elseif con==2 then conbon=-20 elseif con<=4 then conbon=-15 elseif con<=9 then conbon=-10
				elseif con<=24 then conbon=-5 elseif con<=72 then conbon=0 elseif con<=87 then conbon=55 elseif con<=92 then conbon=10
				elseif con<=95 then conbon=15 elseif con<=97 then conbon=20 elseif con==98 then conbon=25 elseif con==99 then conbon=30 else conbon=35; end
				elseif code == "F" then
					hitsperlvl = 10;
					EP = EP+100;
				if con==1 then conbon=-25 elseif con==2 then conbon=-20 elseif con==3 then conbon=-15 elseif con<=5 then conbon=-10
				elseif con<=10 then conbon=-5 elseif con<=25 then conbon=0 elseif con<=72 then conbon=5 elseif con<=87 then conbon=10
				elseif con<=92 then conbon=10 elseif con<=95 then conbon=20 elseif con<=97 then conbon=25
				elseif con==98 then conbon=30 elseif con==99 then conbon=35 else conbon=45; end
				elseif code == "G" then
					hitsperlvl = 12;
					EP = EP+150;
				if con==1 then conbon=-25 elseif con==2 then conbon=-20 elseif con==3 then conbon=-15 elseif con==4 then conbon=-10
				elseif con<=6 then conbon=-5 elseif con<=11 then conbon=0 elseif con<=26 then conbon=5 elseif con<=71 then conbon=10
				elseif con<=86 then conbon=15 elseif con<=91 then conbon=20 elseif con<=94 then conbon=25 elseif con<=96 then conbon=30
				elseif con<=98 then conbon=35 elseif con==99 then conbon=45 else conbon=60; end
				elseif code == "H" then
				hitsperlvl=15;
				EP = EP+200;
				if con==1 then conbon=-25 elseif con==2 then conbon=-20 elseif con==3 then conbon=-15 elseif con==4 then conbon=-10
				elseif con==5 then conbon=-5 elseif con<=7 then conbon=0 elseif con<=12 then conbon=5 elseif con<=27 then conbon=10
				elseif con<=72 then conbon=15 elseif con<=88 then conbon=20 elseif con<=93 then conbon=25 elseif con<=96 then conbon=30
				elseif con<=98 then conbon=35 elseif con==99 then conbon=45 else conbon=60; end
				else 
				conbon, EP, hitsperlvl = 0, 0, 0;
			end
		end

	local hitsbonus = conbon/100 * DB.getValue(getDatabaseNode(), "hits", 0) + hitsperlvl * levelmod;
	EP = EP+conbon;

	local str;
	if levelmod == -99 then str = "young/baby";
	elseif levelmod == 0 then str = "";
	elseif levelmod > 0 then str = "+"..levelmod.." levels";
	else str = levelmod.." levels"; end
		levelcode_result.setValue(str);
		if levelmod ~= -99 then 
		if hitsbonus == 0 then str=""; elseif hitsbonus > 0 then str = "+"..math.floor(hitsbonus+0.5).." hits"; 
		else str = math.floor(hitsbonus+0.5).." hits"; end
			hitscode_result.setValue(str);
		if EP ~= 0 then ExP.setValue(EP.." ExhP"); end
		else
			hitscode_result.setValue("n/a");
			ExP.setValue("n/a");
	end
end

--[[
  This function calculates the Bonus Experience Points given the creatures BonusEP letter code
  and the level of the character getting experience.
--]]
function BonusEP()
	  local code, lvl, xp = bonusep.getValue(), bonusep_lvl.getValue(), 0;
	  if code ~= nil and lvl ~=nil and lvl ~=0 then
		local row = math.floor((lvl-1)/2);
		if row < 0 then row = 0; elseif row > 10 then row=10; end
			bonusep_xp.setValue("test");
		if code == "A" then 
			if row > 4 then xp=10 else xp=50-(row*10); end
		elseif code == "B" then 
			if  row > 6 then xp=10; elseif row==1 then xp=75; else xp=70-(row*10); end
		elseif code == "C" then xp = 100-(row*5);
		elseif code == "D" then xp = 200-(row*10);
		elseif code == "E" then if row==10 then xp=210; else xp=400-(row*20); end
		elseif code == "F" then xp = 800-(row*40);
		elseif code == "G" then xp = 1200-(row*60);
		elseif code == "H" then xp = 1600-(row*80);
		elseif code == "I" then xp = 2000-(row*100);
		elseif code == "J" then xp = 3000-(row*150);
		elseif code == "K" then xp = 4000-(row*200);
		elseif code == "L" then xp = 5000-(row*250);
		else xp = "";
		end
	  else xp = "";
	  end
	  bonusep_xp.setValue(xp);
end

