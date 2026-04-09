-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _nParry = 0;

function onInit()
	self.onIDChanged();
	self.onAttackTableIDChanged();
	self.onOBChanged();
end

function registerDeleteMenu()
	if not Session.IsHost then
		return;
	end
	registerMenuItem("Delete attack", "delete_attack",8);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete_attack", 8, 8);
end
function onMenuSelection(selection, subselection)
	if not Session.IsHost then
		return;
	end
	if selection == 8 and subselection == 8 then
		WindowManager.safeDelete(self);
	end
end

function onIDChanged()
	local bID = true;
	if CombatManager2.isPC(windowlist.window.getDatabaseNode()) then
		bID = (isidentified.getValue() == 1);
	end
	name.setVisible(bID);
	nonid_name.setVisible(not bID);
end
local _bAttackTableUpdating = false
function onAttackTableIDChanged()
	if _bAttackTableUpdating then
		return;
	end
	_bAttackTableUpdating = true;
	attacktable.setValue(attacktableid.getValue(), attacktablename.getValue());
	self.updateNotes();
	_bAttackTableUpdating = false;
end
function onChanceChanged()
	self.updateNotes();
end

function onOBChanged()
	self.updateAttack();
end
function onParryChanged(nParry)
	if _nParry == nParry then
		return;
	end
	_nParry = nParry;
	self.updateAttack();
end
function updateAttack()
	local nOB = ob.getValue();
	local vAttType = DB.getValue(getDatabaseNode(), "type", "");
	if (vAttType ~= "Elemental Attack") and (vAttType ~= "Special") and (vAttType ~= 9) and (vAttType ~= 10) then  -- only update attacks that aren't Elemental Attacks or Special Attacks
		attack.setValue(nOB - _nParry);
	else
		attack.setValue(nOB);
	end
end

function onAttackAction(draginfo)
	local nodeCT = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeCT);
	if draginfo then
		draginfo.setCustomData(rActor);
	end

	local nodeAttack = getDatabaseNode();

	local rAction = {};
	rAction.nodeAttack = DB.getPath(nodeAttack);
	rAction.label = ItemManager.getDisplayName(nodeAttack, true);
	rAction.tableID = attacktable.getValue();
	rAction.OB = attack.getValue();
	if hitsmultiplier.getValue() ~= 0 then
		rAction.hitsMultiplier = hitsmultiplier.getValue();
	else
		rAction.hitsMultiplier = 1;
	end

	ActionAttack.performRoll(draginfo, rActor, rAction);
	return true;
end

function onTableIconDragStart(...)
	local id = attacktable.getValue();
	if id == "" then
		return false;
	end

	return attacktable.onDragStart(...);
end
function onTableIconDrop(x, y, draginfo)
	local customData = draginfo.getCustomData();
	if not customData or ((customData.type or "") ~="RMCTable") then
		return false;
	end

	-- NOTE: Settings attacktableid must occur last, so that onAttackTableIDChanged called with right data
	attacktablename.setValue(customData.tableName);
	attacktableid.setValue(customData.tableID);
	self.updateNotes();
	return true;
end

local _bUpdating = false;
function updateNotes()
	if not _bUpdating then
		local node = getDatabaseNode();
		if not node then
			return;
		end
		_bUpdating = true;

		-- Update table icon
		local tableid = DB.getValue(node, "attacktable.tableid", "");
		local tablename = DB.getValue(node, "attacktable.name", "");
		if tableid == "" then
			tableicon.setIcon("icon_notable");
			tableicon.setTooltipText("No attack table.");
			tableicon.setHoverCursor("arrow");
		else
			tableicon.setIcon("icon_table");
			tableicon.setTooltipText(tablename);
			tableicon.setHoverCursor("hand");
		end

		-- Update notes area
		sameround.setVisible(false);
		nextround.setVisible(false);
		chance.setVisible(false);
		spacer_notes.setVisible(true);

		local nodeCT = DB.getChild(getDatabaseNode(), "...");
		local sValue = chance.getValue();
		if sValue == "SameRnd" then
			sameround.setVisible(true);
			spacer_notes.setVisible(false);
		elseif sValue == "NextRnd" then
			nextround.setVisible(true);
			spacer_notes.setVisible(false);
		elseif sValue ~= "" then
			chance.setVisible(true);
			spacer_notes.setVisible(false);
		end
		
		_bUpdating = false;
	end
end
