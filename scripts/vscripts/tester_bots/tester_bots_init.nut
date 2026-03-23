::ROOT_TB <- getroottable();
if (!("ConstantNamingConvention" in ROOT_TB))
{
	foreach(a, b in Constants)
		foreach(k, v in b)
			ROOT_TB[k] <- v != null ? v : 0;
}

::WHITESPACE_TB  <- {[9]=null, [10]=null, [11]=null, [12]=null, [13]=null, [32]=null},
::PUNCTUATION_TB <- {[33]=null, [44]=null, [46]=null, [63]=null}, // . , ? !

IncludeScript("tester_bots/upgrade_path.nut", getroottable())
IncludeScript("tester_bots/bomb_camper_heavy.nut", getroottable())
IncludeScript("tester_bots/grenade_demo.nut", getroottable())
IncludeScript("tester_bots/money_scout.nut", getroottable())
IncludeScript("tester_bots/banner_soldier.nut", getroottable())
IncludeScript("tester_bots/tank_buster_pyro.nut", getroottable())
IncludeScript("tester_bots/global_think.nut", getroottable())

::hGamerules_TB <- Entities.FindByClassname(null, "tf_gamerules")
::hPlayerManager_TB <- Entities.FindByClassname(null, "tf_player_manager")
::hObjRes_TB <- Entities.FindByClassname(null, "tf_objective_resource")
::hStats_TB <- Entities.FindByClassname(null, "tf_mann_vs_machine_stats")
::hHatch_TB <- Entities.FindByClassname(null, "func_capturezone")
::vHatchOrigin_TB <- hHatch_TB.GetOrigin()

::iVerbosity_TB <- 2
::bCurrentlyKickingBot_TB <- false

::iDroppedMoney_TB <- 0

::MaxPlayers_TB <- MaxClients().tointeger()
::MaxWeapons_TB <- 8

if (!("bCurrentWaveHasCrits_TB" in ROOT_TB)) {
	::botList_TB <- {}
	::bCurrentWaveHasCrits_TB <- false
	::iGlobalMoney_TB <- -1
}

const TB_HELP_STRING_1 = @"
========== DOCUMENTATION ==========
	-- COMMANDS -- 
		!tb_addbot <bot name>
			Adds a tester bot
			See the BOT TYPES section below to check the list of bot names

		!tb_kickbot <bot name>
			Removes a tester bot
			See the BOT TYPES section below to check the list of bot names
			'all' also works
		
		!tb_restart
			Restarts the wave in order to automatically calculate money for bots
		
		!tb_money <money amount>
			Overrides the amount of money for bots to upgrade with

		!tb_checkmoney
			Check the amount of money each bots have to upgrade with

		!tb_verbose <verbosity level 0-3>
		!tb_shutup
			Determine how much chat messages should be printed out
			Higher levels print out more details
			Level 0 silences most chat messages
			!tb_shutup = !tb_verbose 0

	-- BOT TYPES --
		Bomb Camper Heavy
		!tb_addbot bombCamperHeavy
		!tb_addbot bch
			
			Every 5 seconds, this bot will locate the closest enabled bomb to hatch and path towards it
			Prefers upgrading resistances over firing speed
			Will handle all your bomb babysitting needs

		Tank Buster Pyro
		!tb_addbot tankBusterPyro
		!tb_addbot tbp
			
			This bot will always path towards the oldest spawned tank
			Uses Phlogistinator and will always taunt when Mmmph is ready
			If no tanks are present, will go towards the closest bot to hatch instead
			Will handle all your tank busting needs

		Grenade Demoman
		!tb_addbot grenadeDemoman
		!tb_addbot gd
			
			Every 3 seconds, this bot will pick an ally to follow and stay close to
			Prioritizes certain classes and human players
			Uses the chargin' targe but never charges
"

const TB_HELP_STRING_2 = @"
		Money Scout
		!tb_addbot moneyScout
		!tb_addbot ms

			Every tick, search for the closest currency pack and run to it
			Mashes spacebar while shooting
			Uses milk whenever off recharge, prioritizes giants and certain classes
			Uses soda popper and always tries to activate hype
			Prioritizes milk slow, resistances, mobility

		Banner Soldier
		!tb_addbot buffSoldier
		!tb_addbot backupSoldier
		!tb_addbot conchSoldier
		!tb_addbot buS
		!tb_addbot baS
		!tb_addbot coS
			
			Every 3 seconds, this bot will pick an ally to follow and stay close to
			Prioritizes certain classes and human players
			Gets buff duration pretty early on
			Will activate banner whenever available
			Can be customized to have whichever banner you want
		
==================================="

::printChatMessage_TB <- function(sMsg, iVerbosity) {
	if(iVerbosity.tointeger() > iVerbosity_TB.tointeger()) return

	ClientPrint(null, 3, sMsg)
}

//Ensures every player has a scope so that squirrel doesn't get upset
for (local i = 1; i <= MaxPlayers_TB ; i++)
{
	local player = PlayerInstanceFromIndex(i)
	if (player == null) continue
	player.ValidateScriptScope()
}

//Very important, it's to be able to tell when bots are doing better than you
::killstreakify_TB <- function(player) {
	for (local i = 0; i < MaxWeapons_TB; i++)
	{
		local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (weapon == null)
			continue
		local randomSheen = RandomInt(1,7) 
		local randomEffect = RandomInt(2002,2008) 

		weapon.AddAttribute("killstreak tier", 3, -1)
		weapon.AddAttribute("killstreak idleeffect", randomSheen, -1)
		weapon.AddAttribute("killstreak effect", randomEffect, -1)
	}
}

//Looked through valve bot templates
::commonCharacterAttributes_TB <- {
	[1] = "move speed bonus",
	[2] = "damage force reduction",
	[3] = "airblast vulnerability multiplier",
	[4] = "override footstep sound set",
	[5] = "heal rate bonus",
	[6] = "attack projectiles",
	[7] = "airblast vertical vulnerability multiplier",
	[8] = "rage giving scale",
	[9] = "head scale",
	[10] = "effect bar recharge rate increased",
	[11] = "Projectile speed increased",
	[12] = "increase buff duration",
	[13] = "health regen",
	[14] = "cannot be backstabbed",
	[15] = "damage bonus",
	[16] = "increased jump height",
	[17] = "medigun bullet resist passive", //Vaccinator medics being 6 of these was not something I expected
	[18] = "medigun bullet resist deployed",
	[19] = "medigun blast resist passive",
	[20] = "medigun blast resist deployed",
	[21] = "medigun fire resist passive",
	[22] = "medigun fire resist deployed",
	[23] = "bot custom jump particle", //And samurai demos for the next 3...
	[24] = "charge time increased",
	[25] = "charge recharge rate increased"
}

//Bots might inherit several traits from blue enemy robots, let's ensure that doesn't happen
//Max health is reset on the class file
::cleanInheritances_TB <- function(player) {
	player.RemoveWeaponRestriction(7)
	player.ClearAllBotAttributes()
	player.SetCustomModelWithClassAnimations(null)
	player.SetDifficulty(3)
	player.SetMaxVisionRangeOverride(9999)

	//We have to guess common character attributes to clean
	foreach(k, attr in commonCharacterAttributes_TB) {
		player.RemoveCustomAttribute(attr)
	}
}

//Red spawn doors can block navs under them. They must not be blocked.

::navAreaList <- {}

NavMesh.GetAllAreas(navAreaList)

foreach(_, navArea in navAreaList) {
	//Iterate through every nav
	//If we find a nav that's in a red spawn room, make it unblockable
	if(navArea.HasAttributeTF(2)) {
		navArea.SetAttributeTF(1342177280)
	}
}

::collectCash <- function(packEntity, cashCollector=null) {
	//Ty popext

	//Round state 10 = Pre-round
	//Round state 4 = Wave active
	//Anything else = do not collect

	if(GetRoundState() != 4 && GetRoundState() != 10) {
		return
	}

	local packEntityOrigin = packEntity.GetOrigin()
	//Send it deep underground before making it vanish
	packEntityOrigin.z -= 400

	packEntity.SetAbsOrigin(packEntityOrigin)

	local moneyBefore = NetProps.GetPropInt( hObjRes_TB, "m_nMvMWorldMoney" )
	packEntity.Kill()
	local moneyAfter = NetProps.GetPropInt( hObjRes_TB, "m_nMvMWorldMoney" )

	//Red money = make it poof but don't add cash
	if ( NetProps.GetPropBool( packEntity, "m_bDistributed" ) ) return

	local packPrice = moneyBefore - moneyAfter

	// local playerIndex = cashCollector.GetEntityIndex()

	// local previousCashScore = NetProps.GetPropIntArray(hPlayerManager_TB, "m_iCurrencyCollected", playerIndex)
	// NetProps.SetPropIntArray(hPlayerManager_TB, "m_iCurrencyCollected", previousCashScore + packPrice, playerIndex)

	if(GetRoundState() == 4) {
		NetProps.SetPropInt( hStats_TB, "m_currentWaveStats.nCreditsAcquired", NetProps.GetPropInt( hStats_TB, "m_currentWaveStats.nCreditsAcquired" ) + packPrice )
	}
	
	else if(GetRoundState() == 10) {
		NetProps.SetPropInt( hStats_TB, "m_previousWaveStats.nCreditsAcquired", NetProps.GetPropInt( hStats_TB, "m_previousWaveStats.nCreditsAcquired" ) + packPrice )
	}

	for ( local i = 1, player; i <= MaxPlayers_TB; i++ )
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		if (IsPlayerABot(player)) continue
		
		player.AddCurrency( packPrice )
	}	

	//Second not-null param = heal the scout collecting the cash

	if(cashCollector == null) {
		return
	}

	local currHealth = cashCollector.GetHealth()

	//Under 125 HP, scout gets 50 hp per cash
	//At 125-499 HP, scout gets 25 hp per cash
	//At 500 HP, scout gets 20 hp per cash
	//At 750 hp, scout gets 5 hp per cash
	//Scale inbetween 500-750
	//This is actually scaled by max hp but i dont care im not giving it sandman for my 0.01 ms perf increase

	local healthToHeal = 50

	if(currHealth >= 750) {
		healthToHeal = 5
	}
	else if(currHealth >= 500) {
		healthToHeal = (currHealth - 500) * 0.06 + 5
	}
	else if(currHealth >= 125) {
		healthToHeal = 25
	}

	cashCollector.SetHealth(currHealth + healthToHeal)
}

//Ty popext
::VectorAngles_TB <- function(forward) {
	local yaw, pitch;
	if ( forward.y == 0.0 && forward.x == 0.0 ) {
		yaw = 0.0;
		if (forward.z > 0.0)
			pitch = -90.0;
		else
			pitch = 90.0;
	}
	else {
		yaw = (atan2(forward.y, forward.x) * 180.0 / Pi);
		pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / Pi);
	}

	return QAngle(pitch, yaw, 0.0);
}

::GivePlayerWeapon_TB <- function(player, classname, item_id)
{
	local weapon = Entities.CreateByClassname(classname)
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
	weapon.SetTeam(player.GetTeam())
	weapon.DispatchSpawn()

	// remove existing weapon in same slot
	for (local i = 0; i < MaxWeapons_TB; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetSlot() != weapon.GetSlot())
			continue
		held_weapon.Destroy()
		NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
		break
	}

	player.Weapon_Equip(weapon)
	player.Weapon_Switch(weapon)

	return weapon
}

::getWeaponInSlot_TB <- function(player, targetSlot) {
	for (local i = 0; i < MaxWeapons_TB; i++)
	{
		local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (weapon == null)
			continue
		if(weapon.GetSlot() == targetSlot) {
			// ClientPrint(null, 3, weapon.GetClassname())
			return weapon
		}
	}
}

::spawnPointPivot <- null
::botGeneratorPivot <- Vector(0, 0, 0)

while(spawnPointPivot = Entities.FindByClassname(spawnPointPivot, "info_player_teamspawn")) {

	local bIsSpawnPointDisabled = NetProps.GetPropBool(spawnPointPivot, "m_bDisabled")
	
	if(spawnPointPivot.GetTeam() == 2 && !bIsSpawnPointDisabled) {
		local nearestNavArea = NavMesh.GetNearestNavArea(spawnPointPivot.GetOrigin(), 2048, false, true)
		botGeneratorPivot = nearestNavArea.GetCenter()
		botGeneratorPivot.z = botGeneratorPivot.z + 32
		break
	}
}

::removeAllTesterBotsStepOne <- function() {
	for (local i = 1; i <= MaxPlayers_TB ; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		if (!IsPlayerABot(player)) continue
		if (player.GetTeam() != 2) continue

		player.AddBotAttribute(REMOVE_ON_DEATH)
	}
}

::removeAllTesterBotsStepTwo <- function() {
	for (local i = 1; i <= MaxPlayers_TB ; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		if (!IsPlayerABot(player)) continue
		if (player.GetTeam() != 2) continue

		player.TakeDamage(99999, 0, null)
	}
}

::reAddBots_TB <- function() {
	local i;
	foreach(i, bot in botList_TB) {
		if(botList_TB[i] == null) continue

		botList_TB[i].add()
	}
}

::removeBot_TB <- function(botType) {
	local i;
	foreach(i, bot in botList_TB) {
		if(botList_TB[i] == null) continue
		if(botList_TB[i].sBotType != botType && botType != "all") continue
		botList_TB[i].hPlayerEnt.AddBotAttribute(REMOVE_ON_DEATH)
		botList_TB[i].hPlayerEnt.TakeDamage(99999, 0, null)
		botList_TB[i].hTarget.Destroy()
		botList_TB[i].hGenerator.Destroy()

		printChatMessage_TB("\x07CC2222Kicking bot...", 1)

		botList_TB.rawdelete(i)

		bCurrentlyKickingBot_TB = true
		EntFire("bignet", "RunScriptCode", "bCurrentlyKickingBot_TB = false", 5)

		if(botType != "all") {
			break
		}
	}
}

::insertNewBot_TB <- function(sBotType) {

	if(bCurrentlyKickingBot_TB) {
		printChatMessage_TB("\x07CC2222ERROR: \x01cannot add bots while a bot kick is in progress!", 0)
		return
	}

	if(GetRoundState() == 4) {
		printChatMessage_TB("\x07CC2222ERROR: \x01cannot add bots during the wave!", 0)
		return
	}

	//Which slots are free?
	local slotToInsertTo = -1;
	for(local i = 0; i < 6; i++) {
		if(!(botList_TB.rawin(i))) slotToInsertTo = i;
	}

	if(slotToInsertTo == -1) {
		printChatMessage_TB("\x07CC2222ERROR: \x01Can't have more than 6 tester bots!", 0)
		return
	}

	switch(sBotType) {
		case "bombCamperHeavy":
			botList_TB[slotToInsertTo] <- bombCamperHeavy(slotToInsertTo)
			botList_TB[slotToInsertTo].add()
			break
		case "grenadeDemo":
			botList_TB[slotToInsertTo] <- grenadeDemo(slotToInsertTo)
			botList_TB[slotToInsertTo].add()
			break
		case "moneyScout":
			botList_TB[slotToInsertTo] <- moneyScout(slotToInsertTo)
			botList_TB[slotToInsertTo].add()
			break
		case "bannerSoldier_buff":
			botList_TB[slotToInsertTo] <- bannerSoldier(slotToInsertTo, "The Buff Banner")
			botList_TB[slotToInsertTo].add()
			break
		case "bannerSoldier_backup":
			botList_TB[slotToInsertTo] <- bannerSoldier(slotToInsertTo, "The Battalion's Backup")
			botList_TB[slotToInsertTo].add()
			break
		case "bannerSoldier_conch":
			botList_TB[slotToInsertTo] <- bannerSoldier(slotToInsertTo, "The Concheror")
			botList_TB[slotToInsertTo].add()
			break
		case "tankBusterPyro":
			botList_TB[slotToInsertTo] <- tankBusterPyro(slotToInsertTo)
			botList_TB[slotToInsertTo].add()
			break
		default:
			break
	}
}

::setBotReady_TB <- function(playerIndex) {
	NetProps.SetPropBoolArray(hGamerules_TB, "m_bPlayerReady", true, playerIndex)
}

//List of upgrade paths in upgrade_path.nut

::upgradeBot_TB <- function(hRecipient, tUpgradePath, iCurrencyCount) {
	foreach(_, upgrade in tUpgradePath) {
		if(upgrade["cost"] > iCurrencyCount) {
			break
		}

		//Only buy crit res if there are alwayscrit bots in the wavebar
		if(upgrade["name"] == "dmg taken from crit reduced" && !bCurrentWaveHasCrits_TB) {
			continue
		}

		iCurrencyCount -= upgrade["cost"]

		if(upgrade["slot"] == SLOT_BODY) {
			hRecipient.AddCustomAttribute(upgrade["name"], upgrade["value"], -1)
			printChatMessage_TB("\x01Upgraded bot with \x03" + upgrade["name"] + " \x01with the value \x03" + upgrade["value"], 3)
		}
		
		else {
			for (local i = 0; i < MaxWeapons_TB; i++)
			{
				local weapon = NetProps.GetPropEntityArray(hRecipient, "m_hMyWeapons", i)
				if (weapon == null)
					continue
				if(weapon.GetSlot() != upgrade["slot"]) continue
				printChatMessage_TB("\x01Upgraded weapon " + weapon.GetClassname() +" with \x03" + upgrade["name"] + " \x01with the value \x03" + upgrade["value"], 3)
				weapon.AddAttribute(upgrade["name"], upgrade["value"], -1)
			}
		}
	}
}

::setTesterBotsMoney <- function(sMoneyCount="0") {
	local iMoneyCount = sMoneyCount.tointeger()
	iGlobalMoney_TB = iMoneyCount
	
	for (local i = 1; i <= MaxPlayers_TB ; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		if (!IsPlayerABot(player)) continue
		if (player.GetTeam() != 2) continue

		local upgradeTable = null
		switch(player.GetScriptScope().botType_TB) {
			case "bombCamperHeavy":
				upgradeTable = bombCamperHeavyUpgradeTable
				break
			case "grenadeDemo":
				upgradeTable = grenadeDemoUpgradeTable
				break
			case "moneyScout":
				upgradeTable = moneyScoutUpgradeTable
				break
			case "bannerSoldier_buff":
				upgradeTable = bannerSoldierUpgradeTable
				break
			case "bannerSoldier_backup":
				upgradeTable = bannerSoldierUpgradeTable
				break
			case "bannerSoldier_conch":
				upgradeTable = bannerSoldierUpgradeTable
				break
			case "tankBusterPyro":
				upgradeTable = tankBusterPyroUpgradeTable
				break
			default:
				upgradeTable = bombCamperHeavyUpgradeTable
				break
		}
		upgradeBot_TB(player, upgradeTable, iMoneyCount)
	}

	printChatMessage_TB("\x01Tester bots have \x0722CC22" + iGlobalMoney_TB + "\x01 credits to upgrade with", 1)
}

//Bots will only buy crit resistance if wavebar shows alwayscrit robots
//Let's be real here you're not gonna buy crit res just for regular demoknights/flare pyros or something

::checkIfCritsArePresentInCurrentWave <- function() {
	local i
	for(i = 0; i < 12; i++) {
		local iconFlags = NetProps.GetPropIntArray(hObjRes_TB, "m_nMannVsMachineWaveClassFlags", i)
		local iconFlags2 = NetProps.GetPropIntArray(hObjRes_TB, "m_nMannVsMachineWaveClassFlags2", i)
		if(iconFlags & 16) {
			bCurrentWaveHasCrits_TB = true
			break
		}
		if(iconFlags2 & 16) {
			bCurrentWaveHasCrits_TB = true
			break
		}
	}
}

//For god knows why wave resets in rafmod servers force us to respawn all tester bots
::checkIfRafmodResetHappened <- function() {
	local i;
	foreach(i, bot in botList_TB) {
		if(botList_TB[i] == null) continue
		// ClientPrint(null, 3, botList_TB[i].sBotType + " is being spawned...")
		botList_TB[i].hGenerator.AcceptInput("SpawnBot", null, null, null)
	}
}

::checkMoney <- function() {
	for (local i = 1; i <= MaxPlayers_TB ; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		if (!IsPlayerABot(player)) continue
		if (player.GetTeam() != 2) continue
		printChatMessage_TB("\x07FF3F3F" + Convars.GetClientConvarValue("name", player.GetEntityIndex()) + " \x01has \x0700AA00" + player.GetCurrency() + " \x01credits to upgrade with", 2)
	}
	printChatMessage_TB("\x01Tester bots have \x0722CC22" + iGlobalMoney_TB + "\x01 credits to upgrade with", 1)
	printChatMessage_TB("\x0700DD22Manually override the money tester bots have \x07DDDD22!tb_money <amount>", 1)
}

::startAndLoseWave <- function(reversed=false) {
	NetProps.SetPropFloat(hGamerules_TB, "m_flRestartRoundTime", Time())

	local blueWin_TB = SpawnEntityFromTable("game_round_win",
	{
		TeamNum = reversed ? 2 : 3
	})

	EntFireByHandle(blueWin_TB, "RoundWin", null, 1, null, null)
	EntFireByHandle(blueWin_TB, "Kill", null, 2, null, null)
}

//Ty mince
::ParseCommand <- function(string, cmdstart='!', strchar='`')
{
	local cmd = {
		start = null,
		name  = null,
		args  = [],
		error = null			
	}

	if (string == "!") return cmd;
	
	// Make sure our string actually starts with cmdstart
	if (string[0] != cmdstart)
		return cmd;
	else if (typeof(cmdstart) == "array")
	{
		local found = false;
		foreach (s in cmdstart)
		{
			if (startswith(string, s))
			{
				found    = true;
				cmdstart = s;
				break;
			}
		}
		if (!found) return cmd;
	}
	
	cmd.start = cmdstart;
	
	// Get rid of cmdstart from string
	if (cmdstart)
		string = string.slice(1);
	
	// Parse tokens
	local tokens = [];
	local in_str = false;
	local start  = null
	local strlen = string.len();
	for (local i = 0; i < strlen; ++i)
	{
		local ch = string[i];
		
		if (ch in WHITESPACE_TB)
		{
			if (start != null)
			{
				if (in_str) continue;
				
				// End of token
				tokens.append(string.slice(start, i));
				start = null;
			}
		}
		else
		{
			if (start == null)
			{
				start = i;
				
				if (ch == strchar)
					in_str = true;
			}
			else
			{
				if (ch == strchar)
				{
					in_str = false;
					
					tokens.append(string.slice(start+1, i));
					start = null;
				}
			}
		}
		
		// Ensure we detect the last token
		if (i == string.len() - 1 && start != null)
		{
			if (in_str)
			{
				cmd.error <- "[CMD] Invalid arguments: String token was not closed before EOL.";
				return cmd;
			}

			tokens.append(string.slice(start));
			break;
		}
	}
	
	cmd.name <- tokens[0];
	
	if (tokens.len() > 1)
		cmd.args <- tokens.slice(1);
	
	return cmd;
}

::HandleArgs <- function(player, cmd, argformat)
{
	// Collect amount of required args
	local required_args = 0;
	foreach (arg in argformat)
		if ("required" in arg && arg.required)
			++required_args;
	
	local arglen    = cmd.args.len();
	local formatlen = null;
	
	// We don't care about going over length if our last arg is a vararg
	local last = argformat.top();
	if (!("vararg" in last) || !last.vararg)
		formatlen = argformat.len();

	// Check number of args in cmd
	if (arglen < required_args || (formatlen && (arglen > formatlen)))
	{
		local output = format("[CMD] Usage: !%s", cmd.name);
		foreach (arg in argformat)
		{
			if ("required" in arg && arg.required)
				output += format(" (%s)", arg.name);
			else
				output += format(" [%s]", arg.name);
		}
		return output; // Caller handles error msg display
	}
	
	foreach (index, arg in argformat)
	{
		local cmparg = null;
		if (index < arglen)
			cmparg = cmd.args[index];
		
		if (cmparg != null)
		{
			// Check type
			if (!("type" in arg))
				arg.type <- "string";

			try
			{
				switch (arg.type)
				{
				case "integer":
					cmd.args[index] = cmparg.tointeger();
					break;
				case "float":
					cmd.args[index] = cmparg.tofloat();
					break;
				}
			}
			catch (err)
			{
				return format("[CMD] Invalid type for argument <%s>, expected <%s>", arg.name, arg.type);
			}
			
			// Target type is a special case
			if (arg.type == "target")
			{
				local targets = ResolveTargetString(cmparg, player);
				if (!targets || !targets.len())
					return "[CMD] Could not find a valid target";
				else
				{
					if ("flags" in arg)
					{
						if ((arg.flags & TARGETFLAGS_NOSELF) && targets.find(player) != null)
							return "[CMD] Command does not support targeting yourself";
						else if ((arg.flags & TARGETFLAGS_NOMULTIPLE) && targets.len() > 1)
							return "[CMD] Command does not support multiple targets";
						else if ((arg.flags & TARGETFLAGS_NOBOTS))
						{
							foreach (t in targets)
								if (t.IsBotOfType(1337))
									return "[CMD] Command does not support targeting bots";
						}
					}
					cmd.args[index] = targets;
				}
			}
			
			// Update this with the new typed value
			cmparg = cmd.args[index];
			
			// Check bounds
			if (arg.type == "integer" || arg.type == "float")
			{
				local f = (arg.type == "integer") ? "%d" : "%.2f"
				if ("min_value" in arg && cmparg < arg.min_value)
					return format("[CMD] Argument <%s> below minimum value <" + f + ">", arg.name, arg.min_value);
				if ("max_value" in arg && cmparg > arg.max_value)
					return format("[CMD] Argument <%s> above maximum value <" + f + ">", arg.name, arg.max_value);
			}
		}
		else
		{
			cmd.args.append(null);
		}
	}
}

::testerBotsCallbacks <- {

	OnGameEvent_recalculate_holidays = function(_) {

		bCurrentWaveHasCrits_TB = false
		EntFireByHandle(hGamerules_TB, "CallScriptFunction", "checkIfCritsArePresentInCurrentWave", 0.25, null, null)
		EntFireByHandle(hGamerules_TB, "CallScriptFunction", "checkIfRafmodResetHappened", 0.5, null, null)
		EntFireByHandle(hGamerules_TB, "RunScriptCode", "setTesterBotsMoney(iGlobalMoney_TB)", 1, null, null)
		// EntFireByHandle(hGamerules_TB, "CallScriptFunction", "removeAllTesterBotsStepOne", 0.75, null, null)
		// EntFireByHandle(hGamerules_TB, "CallScriptFunction", "removeAllTesterBotsStepTwo", 1, null, null)
		// EntFireByHandle(hGamerules_TB, "CallScriptFunction", "reAddBots_TB", 7, null, null)
	}

	OnGameEvent_mvm_begin_wave = function(_) {
		iDroppedMoney_TB = 0
	}

    OnGameEvent_mvm_wave_complete = function(_) {
		
		for (local i = 1; i <= MaxPlayers_TB ; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			if (player == null) continue
			if (!IsPlayerABot(player)) continue
			if (player.GetTeam() != 2) continue
			EntFireByHandle(hGamerules_TB, "RunScriptCode", "setBotReady_TB(" + player.GetEntityIndex() + ")", 1, null, null)
			player.AddCustomAttribute("health drain", 300, 3) //Recover hp on wave finish so that they don't start the next wave with 70 hp
		}

		bCurrentWaveHasCrits_TB = false
		EntFireByHandle(hGamerules_TB, "CallScriptFunction", "checkIfCritsArePresentInCurrentWave", 0.25, null, null)

		local droppedMoney = NetProps.GetPropInt(hStats_TB, "m_currentWaveStats.nCreditsDropped")

		// ClientPrint(null, 3, "Dropped: " + droppedMoney)

		setTesterBotsMoney(iGlobalMoney_TB + droppedMoney + 100)
	}

	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
        local scope = player.GetScriptScope()

		if (params.team == 0) {
			//This is a chore that has to be done to ensure the scope exists
			player.ValidateScriptScope()
		}

		if(!("iBotId_TB" in scope)) {
			return
		}

		EntFireByHandle(player, "RunScriptCode", "botList_TB[" + scope.iBotId_TB + "].initialize(self)", 0.5, player, player)
	}

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)

		if(!IsPlayerABot(player)) return

		//Since red bots can drop money, we need a pivot point to return to when undoing that
		//(We don't want red bots to drop money)
		if(player.GetTeam() == 3) {
			iDroppedMoney_TB = NetProps.GetPropInt(hStats_TB, "m_currentWaveStats.nCreditsDropped")
			
			// ClientPrint(null, 3, "\x01Updating dropped money to \x05" + iDroppedMoney_TB)
			return
		}
		if(player.GetTeam() != 2) {
			return
		}

		local playerOrigin = player.GetCenter()		
		local currencyPack = null
		
		while(currencyPack = Entities.FindByClassname(currencyPack, "item_currencypack_custom")) {
			local currencyPackOrigin = currencyPack.GetOrigin()

			if(currencyPackOrigin.ToKVString() != playerOrigin.ToKVString()) {
				continue
			}

			// ClientPrint(null, 3, "Dumb ass red bot is dropping money, nuking...")
			// ClientPrint(null, 3, "\x01Setting dropped money to \x05" + iDroppedMoney_TB)
			
			currencyPack.Kill()
			// NetProps.SetPropInt(hObjRes_TB, "m_nMvMWorldMoney", iWorldMoney_TB)
			NetProps.SetPropInt(hStats_TB, "m_currentWaveStats.nCreditsDropped", iDroppedMoney_TB)

			return
		}
		
		// iWorldMoney_TB = NetProps.GetPropInt(hObjRes_TB, "m_nMvMWorldMoney")
		
	}

	OnGameEvent_mvm_tank_destroyed_by_players = function(_) {
		iDroppedMoney_TB = NetProps.GetPropInt(hStats_TB, "m_currentWaveStats.nCreditsDropped")
	}

	OnGameEvent_player_say = function(params) {
		//Ty mince
		local player = GetPlayerFromUserID(params.userid);
		if (!player) return;
		
		player.ValidateScriptScope();
		local scope = player.GetScriptScope();
		
		local cmd = ParseCommand(params.text);
		
		if (cmd.error)
		{
			ClientPrint(player, 3, cmd.error);
			return;
		}
		
		if (!cmd || !cmd.name) return;

		switch (cmd.name)
		{
			case "tb_addbot":
				local err = HandleArgs(player, cmd, [{name="botname",type="botname",required=true}]);
				if (err)
				{
					ClientPrint(player, 3, err);
					break;
				}
				
				local botname = cmd.args[0];

				switch(botname) {
					case "bombCamperHeavy":
						insertNewBot_TB("bombCamperHeavy")
						break
					case "bch":
						insertNewBot_TB("bombCamperHeavy")
						break
					case "grenadeDemo":
						insertNewBot_TB("grenadeDemo")
						break
					case "gd":
						insertNewBot_TB("grenadeDemo")
						break
					case "moneyScout":
						insertNewBot_TB("moneyScout")
						break
					case "ms":
						insertNewBot_TB("moneyScout")
						break
					case "buffSoldier":
						insertNewBot_TB("bannerSoldier_buff")
						break
					case "buS":
						insertNewBot_TB("bannerSoldier_buff")
						break
					case "backupSoldier":
						insertNewBot_TB("bannerSoldier_backup")
						break
					case "baS":
						insertNewBot_TB("bannerSoldier_backup")
						break
					case "conchSoldier":
						insertNewBot_TB("bannerSoldier_conch")
						break
					case "coS":
						insertNewBot_TB("bannerSoldier_conch")
						break
					case "tankBusterPyro":
						insertNewBot_TB("tankBusterPyro")
						break
					case "tbp":
						insertNewBot_TB("tankBusterPyro")
						break
					default:
						ClientPrint(null, 3, "\x07CC3333ERROR: unknown bot type")
						ClientPrint(null, 3, "\x07DDFFDDMake sure your capitalization matches!")
						ClientPrint(null, 3, "\x07FFDDDDType \x07CCAA66!tb_help \x07FFDDDDfor help")
						break
				}
				break;
			case "tb_kickbot":
				local err = HandleArgs(player, cmd, [{name="botname",type="botname",required=true}]);
				if (err)
				{
					ClientPrint(player, 3, err);
					break;
				}
				
				local botname = cmd.args[0];

				switch(botname) {
					case "bombCamperHeavy":
						removeBot_TB("bombCamperHeavy")
						break
					case "bch":
						removeBot_TB("bombCamperHeavy")
						break
					case "grenadeDemo":
						removeBot_TB("grenadeDemo")
						break
					case "gd":
						removeBot_TB("grenadeDemo")
						break
					case "moneyScout":
						removeBot_TB("moneyScout")
						break
					case "ms":
						removeBot_TB("moneyScout")
						break
					case "buffSoldier":
						removeBot_TB("bannerSoldier_buff")
						break
					case "buS":
						removeBot_TB("bannerSoldier_buff")
						break
					case "backupSoldier":
						removeBot_TB("bannerSoldier_backup")
						break
					case "baS":
						removeBot_TB("bannerSoldier_backup")
						break
					case "conchSoldier":
						removeBot_TB("bannerSoldier_conch")
						break
					case "coS":
						removeBot_TB("bannerSoldier_conch")
						break
					case "tankBusterPyro":
						removeBot_TB("tankBusterPyro")
						break
					case "tbp":
						removeBot_TB("tankBusterPyro")
						break
					case "all":
						removeBot_TB("all")
						break
					default:
						ClientPrint(null, 3, "\x07CC3333ERROR: unknown bot type")
						ClientPrint(null, 3, "\x07DDFFDDMake sure your capitalization matches!")
						ClientPrint(null, 3, "\x07FFDDDDType \x07CCAA66!tb_help \x07FFDDDDfor help")
						break
				}
				break;
			case "tb_restart":
				startAndLoseWave()
				break
			case "tb_checkmoney":
				checkMoney()
				break
			case "tb_money":
				local err = HandleArgs(player, cmd, [{name="moneycount",type="moneycount",required=true}]);
				if (err)
				{
					ClientPrint(player, 3, err);
					break;
				}
				
				local moneycount = cmd.args[0];

				setTesterBotsMoney(moneycount);
				break;
			case "tb_verbose":
				local err = HandleArgs(player, cmd, [{name="verbosity",type="verbosity",required=true}]);
				if (err)
				{
					ClientPrint(player, 3, err);
					break;
				}
				
				local pVerbosity = cmd.args[0];
				pVerbosity = pVerbosity.tointeger()

				iVerbosity_TB = pVerbosity
				printChatMessage_TB("\x01Verbosity set to \x05" + pVerbosity, 0)
				break
			case "tb_shutup":
				iVerbosity_TB = 0
				printChatMessage_TB("\x01Verbosity set to \x050", 0)
				break
			case "tb_help":
				printl(TB_HELP_STRING_1)
				EntFire("gamerules", "RunScriptCode", "printl(TB_HELP_STRING_2)", 0.2)
				ClientPrint(null, 3, "\x0744FF22Check console for help")
				break
			default:
			break;
		}

		
	}
}

__CollectGameEventCallbacks(testerBotsCallbacks)

// script_execute tester_bots/tester_bots_init
// ent_fire !self RunScriptCode "addTestThink()"
// ent_fire !picker RunScriptCode "self.ForceRespawn()"
// ent_fire !self RunScriptCode "AddThinkToEnt(self, ``)"
// ent_fire player RunScriptCode "self.GetLocomotionInterface().Jump()"
// ent_fire !picker RunScriptCode "ClientPrint(null, 3, `MONEY: ` + self.GetCurrency())"
// ent_fire bot_generator RunScriptCode "NetProps.SetPropInt(self, `m_iTeamNum`, 5)"

// ::addTestThink <- function() {

// 	local scope = self.GetScriptScope()

//     scope.testThink <- function() {
//         ClientPrint(null, 3, "Juicy: " + self.GetRageMeter())
//         return -1
//     }
//     AddThinkToEnt(self, "testThink")
// }

ClientPrint(null, 3, "Tester bots script is running!")
ClientPrint(null, 3, "\x07DDAAAAType \x07FFFFCC!tb_help \x07DDAAAAfor a list of commands")

