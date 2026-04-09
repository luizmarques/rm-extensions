-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Options allow specific elements of the Rolemaster Classic code to be over-ridden using extensions or other
-- similar methods. A typical example would be replacement of the bonuses attaching to various ability values.
-- 
-- Only pre-defined functions can be replaced, a list of which appears below, but there is no restriction on
-- how the replacement function operates.
-- 
-- Options are registered using OptionManager.register(option_name, option_function) and when they are invoked
-- they receive two parameters, the option_name and a vararg expression representing the option parameters (the
-- contents of which depend on the function being over-ridden).
--
-- The ruleset is distributed with default behaviours, determined by the core RM canon, which is defined in the
-- options.lua script file.
--
-- The list of supported options includes:
--
-- "abilitybonus",abilitywindow     -  returns the bonus calculated for a given ability score.
-- "mmskillname",armortype          -  returns the name of the moving maneuver skill relevant to the armor type
-- "skillcost",skillname,profession - returns the (string) cost of the named skill for a given character profession

local optionlist = {};

-- ##################### External Functions - can be called by other code #########################################

function register(optname, func)
	if not optname or not func then
		return false;
	end
	if type(optname)~="string" or type(func)~="function" then
		return false;
	end
	optionlist[optname] = func;
	return true;  
end

function invoke(optname, ...)
	local func;
	if not optname or type(optname)~="string" then
		return nil;
	end
	func = optionlist[optname];
	if not func then
		return nil;
	end
	return func(optname, ...);
end
