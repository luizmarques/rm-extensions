-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function showError(message, functionName, scriptName, fatalError) 
	local message, functionName, scriptName = getNames(message, functionName, scriptName);

	errorMessage = "ERROR: " .. message;

	if fatalError then
		errorMessage = errorMessage ..  "  [" .. functionName .. "]";
		error(errorMessage); -- TODO: rethink this? - the error function HALTS script processing!
	else
		errorMessage = errorMessage ..  " [" .. scriptName .. "][" .. functionName .. "]";

		-- deliver message to the chatwindow
		msg = {};
		msg.text = errorMessage;
		msg.sender = "";
		Comm.deliverChatMessage(msg)
	end
end

function showWarning(message, functionName, scriptName, displayToUser) 
	local message, functionName, scriptName = getNames(message, functionName, scriptName);

	warningMessage = "Warning: " .. message;

	if displayToUser then
		warningMessage = warningMessage ..  "  [" .. functionName .. "]";

		-- deliver message to the chatwindow
		msg = {};
		msg.text = warningMessage;
		msg.sender = "";
		msg.font = "warningmsgfont";
		Comm.deliverChatMessage(msg);

	--return false;
	else
		warningMessage = warningMessage ..  " [" .. scriptName .. "][" .. functionName .. "]";
		ChatManager.SystemMessage(warningMessage);
	end
end

function getNames(message, functionName, scriptName)
	if message == nil or string.gsub(message, "%s", "") == "" then
		message = "<no message supplied!>"
	end
	if functionName == nil or string.gsub(functionName, "%s", "") == "" then
		functionName = "<unknown function!>";
	end
	if scriptName == nil or string.gsub(scriptName, "%s", "") == "" then
		scriptName = "<unknown lua script!>";
	end

	return message, functionName, scriptName;
end