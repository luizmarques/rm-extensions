-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- The sourceless value is used if the multitext is used in a window not bound to the database
-- or if the <sourceless /> flag is specifically set

local sourcelessvalue = 1;
local enabled = true;

function setState(state)
	if self.beforeStateChanged then
		state = self.beforeStateChanged(state);
	end
	if state == nil or state == false then
		state = 1;
	end
	if source then
		source.setValue(state);
	else
		sourcelessvalue = state;
		update();
	end
end

function update()
	local stateval = sourcelessvalue;
	local statename = "";
	if source then
		stateval = source.getValue();
	end
	statename = statelabels[1].state[stateval];
	if type(statename)=="string" then
		setValue(statename);
	end
	if self.onStateChanged then
		self.onStateChanged();
	end
end

function getState()
	if source then
		return source.getValue();
	else
		return sourcelessvalue;
	end
end

function onClickDown(button, x, y)
	if enabled then
		local newstate = getState() + 1;
		if newstate > table.getn(statelabels[1].state) then
			newstate = 1;
		end
		setState(newstate);
	end
end

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	setValue(statelabels[1].state[1]);

	if not sourceless and window.getDatabaseNode() then
		-- Get value from source node
		if sourcename then
			source = DB.createChild(window.getDatabaseNode(), sourcename[1], "number");
		else
			source = DB.createChild(window.getDatabaseNode(), getName(), "number");
		end
		if source then
			DB.addHandler(DB.getPath(source), "onUpdate", self.update);
			update();
		end
		-- Get static flag from database node
		if DB.isStatic(window.getDatabaseNode()) then
			enabled = false;
		end
	else
		-- Use internal value, initialize to state if <state /> is specified
		if state then
			sourcelessvalue = state[1];
			update();
		end
	end
	-- allow <readonly/> to override the database node setting
	if readonly then
		enabled = false;
	end
end

function setEnabled(state)
	if not sourceless and window.getDatabaseNode() then
		-- Get static flag from database node
		if DB.isStatic(window.getDatabaseNode()) then
			state = false;
		end
	end
	enabled = state;
end
