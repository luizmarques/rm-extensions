-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Stack manager module
local scriptName = "ManagementScript_StackManager.lua";

local queuelist = {};
local stacknode = nil;

-- Public routines

function isActive()
    return true;
end

function addEntry(rRoll)
	local node;
	local target;
	
	if Session.IsHost then
		target = stacknode;
	else
		target = getMyQueue(User.getUsername());
	end
	if not target then
		-- nothing to do, can't find the target
		ErrorHandler.showWarning("Unable to send die roll to GM: message stack missing","addEntry",scriptName,true);
		return;
	end
	if not Session.IsHost and not isActive() then
		-- stack is disabled, don't add the node
		ErrorHandler.showWarning("The GM has disabled this function","addEntry",scriptName,true);
		return;
	end
	node = DB.createChild(target);
	if node then
		encode(node, rRoll);
	else
		ErrorHandler.showWarning("Unable to send die roll to GM: could not create the database node","addEntry",scriptName,true);
	end
	if Session.IsHost then
		-- open the table resolver
		if not Interface.findWindow("tableresolver","") then
			Interface.openWindow("tableresolver","");
		end
	else
		-- let the host know
		if node and ChatManager and ChatManager.sendCommand then
			-- send a stack command to the host, with the child node path as a parameter
			ChatManager.sendCommand("stack", DB.getPath(node));
		end
	end
end

function handleStackCommand(name,text,sender)
	if text~="" then
		local node = DB.findNode(text);
		if node and stacknode then
			-- copy the queued item to the stack
			copyNode(stacknode,node,true);
			-- delete the item from the queue
			DB.deleteNode(node);
			-- open the table resolver
			if not Interface.findWindow("tableresolver","") then
				Interface.openWindow("tableresolver","");
			end
		end
	end
end

function copyNode(parent,source,rename)
	local nodeName = DB.getName(source);
	local nodeType = DB.getType(source);
	if nodeType == "string" or nodeType == "number" then
		DB.setValue(parent, nodeName, nodeType, DB.getValue(source, "."));
	elseif nodeType == "node" then
		local newNode;
		if rename then
			newNode = DB.createChild(parent);
		else
			newNode = DB.createChild(parent, nodeName);
		end
		for _,child in ipairs(DB.getChildList(source)) do
			copyNode(newNode, child);
		end
	end
end

function decode(stackEntryNode)
	local customData = {};
	local customDataNode = DB.createChild(stackEntryNode, "customData");
	local modifiers = nil;
	local modifiersNode = nil;
	-- error check, return an empty table
	if not customDataNode then
		return customData;
	end
	-- common fields
	getField(customDataNode,customData,"tableType","");
	getField(customDataNode,customData,"name","");
	getField(customDataNode,customData,"dieResult",0);
	getField(customDataNode,customData,"unmodifiedRoll",0);
	getField(customDataNode,customData,"dieType","");
	getField(customDataNode,customData,"type","");
	getField(customDataNode,customData,"tableID","");
	getField(customDataNode,customData,"actorNodeName","");
	getField(customDataNode,customData,"actorName","");
	getField(customDataNode,customData,"columnTitle","");
	getField(customDataNode,customData,"hitsMultiplier",1);
	getField(customDataNode,customData,"attackerName","");
	getField(customDataNode,customData,"attackerNodeName","");
	getField(customDataNode,customData,"defenderNodeName","");
	getField(customDataNode,customData,"defenderName","");

	-- type-specific fields
	if customData.tableType == Rules_Constants.TableType.Attack or customData.tableType == Rules_Constants.TableType.Result then
		getField(customDataNode,customData,"tableColumn",1);
		getField(customDataNode,customData,"attackerNode","");
		getField(customDataNode,customData,"attackDBNodeName","");
		getField(customDataNode,customData,"attackDBNodeClass","");
		getField(customDataNode,customData,"critTableID","");
		getField(customDataNode,customData,"critTableName","");
		getField(customDataNode,customData,"largeColumnName", "Normal");
		getField(customDataNode,customData,"fumbleValue",0);
		getField(customDataNode,customData,"maxResultLevel",0);
	end

	-- modifiers
	modifiers = {};
	for k,node in pairs(DB.getChildren(customDataNode, "modifiers")) do
		local desc = DB.getValue(node, "description", "");
		local val = DB.getValue(node, "number", 0);
		table.insert(modifiers, { description = desc, number = val });
	end
	customData.modifiers = modifiers;
	-- done
	return customData;
end

function encode(stackEntryNode, rRoll)
	local customDataNode = DB.createChild(stackEntryNode, "customData");
	local modifiersNode = nil;
	local modifiers = {};
	local unmodifiedRoll = rRoll.unmodified;

	-- common fields
	DB.setValue(customDataNode, "tableType", "string", rRoll.tableType);
	DB.setValue(customDataNode, "name", "string", rRoll.name);
	DB.setValue(customDataNode, "dieResult", "number", rRoll.dieResult);
	DB.setValue(customDataNode, "unmodifiedRoll", "number", unmodifiedRoll);
	DB.setValue(customDataNode, "dieType", "string", rRoll.dieType);
	DB.setValue(customDataNode, "type", "string", rRoll.tableType);
	DB.setValue(customDataNode, "tableID", "string", rRoll.tableID);
	DB.setValue(customDataNode, "actorNodeName", "string", rRoll.nodeActorName);
	DB.setValue(customDataNode, "actorName", "string", rRoll.actorName);
	DB.setValue(customDataNode, "columnTitle", "string", rRoll.columnTitle);
	DB.setValue(customDataNode, "hitsMultiplier", "number", rRoll.hitsMultiplier);
	DB.setValue(customDataNode, "attackerNodeName", "string", rRoll.nodeAttackerName);
	DB.setValue(customDataNode, "attackerName", "string", rRoll.attackerName);
	DB.setValue(customDataNode, "defenderNodeName", "string", rRoll.targetNodeName);
	DB.setValue(customDataNode, "defenderName", "string", rRoll.targetName);

	-- type-specific fields
	if rRoll.tableType == Rules_Constants.TableType.Attack or rRoll.tableType == Rules_Constants.TableType.Result then
		DB.setValue(customDataNode, "tableColumn", "number", rRoll.tableColumn);
		DB.setValue(customDataNode, "attackerNode", "string", rRoll.nodeAttackerName);
		DB.setValue(customDataNode, "attackDBNodeName", "string", rRoll.attackDBNodeName);
		DB.setValue(customDataNode, "attackDBNodeClass", "string", rRoll.attackDBNodeClass);
		DB.setValue(customDataNode, "critTableID", "string", rRoll.critTableID);
		DB.setValue(customDataNode, "critTableName", "string", rRoll.critTableName);
		DB.setValue(customDataNode, "largeColumnName", "string", rRoll.largeColumnName);
		DB.setValue(customDataNode, "fumbleValue", "number", rRoll.fumbleValue);
		DB.setValue(customDataNode, "maxResultLevel", "number", rRoll.maxResultLevel);
	end

	-- modifiers
	modifiers = Utilities.modifiersStringToTable(rRoll.modifiers);
	modifiersNode = DB.createChild(customDataNode, "modifiers");
	if modifiersNode and modifiers then
		for i = 1, #modifiers do
			node = DB.createChild(modifiersNode);
			if node then
				DB.setValue(node, "description", "string", modifiers[i].description);
				DB.setValue(node, "number", "number", modifiers[i].number);
			end
		end
	end
end

-- Initialization

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	if Session.IsHost then
		stacknode = DB.createNode("stack");
		-- clear any remaining queues
		DB.deleteNode("queues");
		-- register the stack command handler
		if ChatManager and ChatManager.registerCommandHandler then
			ChatManager.registerCommandHandler("stack",handleStackCommand);
		end
		-- capture user login
		User.onLogin = onLogin;
	end
end

-- User login and logout

function onLogin(username, activated)
	if activated then
		local myqueue;
		-- grant access to the list of queues
		DB.addHolder(DB.createNode("queues"), username, false);
		-- reset node owners (to fix FG bug)
		resetOwners();
		-- find/create a queue for this user
		myqueue = getMyQueue(username);
		-- found the queue?
		if myqueue then
			-- save a reference to it
			queuelist[username] = myqueue;
		end
	else
		-- look for an existing queue
		local myqueue = queuelist[username];
		-- found the queue?
		if myqueue then
			-- remove the reference
			queuelist[username] = nil;
			-- delete the queue
			DB.deleteNode(myqueue);
		end
		-- revoke access to the list
		DB.removeHolder(DB.createNode("queues"), username);
	end
end

-- Internal support routines

function resetOwners()
	if not Session.IsHost then
		return;
	end
	DB.addHolder(DB.createNode("queues"), User.getUsername(), true);
	for username, node in pairs(queuelist) do
		DB.addHolder(node, username, true);
	end
end

function getMyQueue(username)
	local queues = DB.findNode("queues");
	if not queues then
		return nil;
	end

	if Session.IsHost then
		for _,queue in ipairs(DB.getChildList(queues)) do
			if DB.getOwner(queue) == username then
				return queue;
			end
		end
	else
		if username ~= User.getUsername() then
			-- a client cannot get the queue of another client
			return nil;
		end
		for _,queue in ipairs(DB.getChildList(queues)) do
			if DB.isOwner(queue) then
				return queue;
			end
		end
		-- client cannot create a queue if it doesn't exist
		return nil;
	end
	-- create a new queue for this user
	local newqueue = DB.createChild(queues);
	DB.addHolder(newqueue, username, true);
	return newqueue;
end

function getField(node, customData, fieldname, defaultvalue)
	if not node then
		customData[fieldname] = defaultvalue;
	else
		customData[fieldname] = DB.getValue(node, fieldname, defaultvalue);
	end
end

function setField(node, rRoll, fieldname, datatype)
	if not node then
		return;
	end
	DB.setValue(node, fieldname, datatype, rRoll[fieldname]);
end
