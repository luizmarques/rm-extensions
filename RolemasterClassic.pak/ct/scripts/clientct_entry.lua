-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
	self.updateOwnerControls();
end

function onOwnerChanged()
	self.updateHealthDisplay();
end
function updateOwnerControls()
	local bOwner = CombatManager2.isCTEntryOwner(getDatabaseNode());

	button_section_move.setVisible(bOwner);
	spacer_button_section_move.setVisible(not bOwner);
	button_section_active.setVisible(bOwner);
	spacer_button_section_active.setVisible(not bOwner);
	button_section_defense.setVisible(bOwner);
	spacer_button_section_defense.setVisible(not bOwner);

	button_section_move.setValue(0);
	button_section_active.setValue(0);
	button_section_defense.setValue(0);

	self.onSectionChanged("move");
	self.onSectionChanged("active");
	self.onSectionChanged("defense");
end

function onFactionChanged()
	super.onFactionChanged();
	self.updateHealthDisplay();
end
function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local sColor = ActorHealthManager.getHealthColor(rActor);
	
	damage.setColor(sColor);
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	if CombatManager2.isCTEntryOwner(getDatabaseNode()) then
		activitypercent.setVisible(true);
		ppmax.setVisible(true);
		ppcurrent.setVisible(true);
		spelladdermax.setVisible(false);
		spelladderused.setVisible(false);
		hits.setVisible(true);
		damage.setVisible(true);

		status.setVisible(false);
	elseif sOption == "detailed" then
		activitypercent.setVisible(true);
		ppmax.setVisible(true);
		ppcurrent.setVisible(true);
		spelladdermax.setVisible(false);
		spelladderused.setVisible(false);
		hits.setVisible(true);
		damage.setVisible(true);

		status.setVisible(false);
	elseif sOption == "status" then
		activitypercent.setVisible(false);
		ppmax.setVisible(false);
		ppcurrent.setVisible(false);
		spelladdermax.setVisible(false);
		spelladderused.setVisible(false);
		hits.setVisible(false);
		damage.setVisible(false);

		status.setVisible(true);
	else
		activitypercent.setVisible(false);
		ppmax.setVisible(false);
		ppcurrent.setVisible(false);
		spelladdermax.setVisible(false);
		spelladderused.setVisible(false);
		hits.setVisible(false);
		damage.setVisible(false);

		status.setVisible(false);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("attack") then
		local customData = draginfo.getCustomData();
		if customData then
			TargetingManager.notifyAddTarget(ActorManager.getCTNode(customData), getDatabaseNode());
		end
	end
end
