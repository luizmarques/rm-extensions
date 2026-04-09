-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local refreshing = false;

function onInit()
	OptionsManager.registerCallback("CL111", refresh);
	OptionsManager.registerCallback("CL112", refresh);
	OptionsManager.registerCallback("RC44B", refresh);
	OptionsManager.registerCallback("RC44D", refresh);
	OptionsManager.registerCallback("RC48B", refresh);
	OptionsManager.registerCallback("RC48D", refresh);
	refresh();
end

function onClose()
	OptionsManager.unregisterCallback("CL111", refresh);
	OptionsManager.unregisterCallback("CL112", refresh);
	OptionsManager.unregisterCallback("RC44B", refresh);
	OptionsManager.unregisterCallback("RC44D", refresh);
	OptionsManager.unregisterCallback("RC48B", refresh);
	OptionsManager.unregisterCallback("RC48D", refresh);
end

function getRefreshing()
	return refreshing;
end

function setRefreshing(newValue)
	refreshing = newValue;
end

function refresh()
	if not refreshing then
		refreshing = true;
		primestat.setValue(Rules_Professions.IsPrimeRequisite(windowlist.window.profession.getValue(), label.getValue()));
		if primestat.getValue() == 1 and temproll.getValue() < 90 then
			temp.setValue(90);
		else
			temp.setValue(temproll.getValue());
		end
		pot.setValue(Rules_Stats.StatPotential(temp.getValue(),potroll.getValue()));
		bonus.setValue(Rules_Stats.Bonus(temp.getValue()));
		local nTemp = temp.getValue();
		local nTotalBonus = bonus.getValue() + DB.getValue(getDatabaseNode(), "race", 0) + DB.getValue(getDatabaseNode(), "special", 0);
		dp.setValue(Rules_Stats.DPs(nTemp, nTotalBonus));
		if string.lower(OptionsManager.getOption("CL112")) == string.lower(Interface.getString("option_val_off")) then 
			dp.setVisible(getDev());
		else
			dp.setVisible(false);
		end
        windowlist.setDPs();
		refreshing = false;
	end
end

function setDev(status)
	if status then
		dev.setValue(1);
	else
		dev.setValue(0);
	end
	refresh();
end

function getDev()
	return (dev.getValue()~=0);
end

