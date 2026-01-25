//Banner Soldier
// Every 3 seconds, this bot will pick an ally to follow and stay close to
//Prioritizes certain classes and human players
//Gets buff duration pretty early on
//Will activate banner whenever available
//Can be customized to have whichever banner you want

//BOTS MAY INHERIT MVM ROBOT TRAITS, MODELS ETC. REMOVE ALL OF THEM.

class bannerSoldier {

	hTarget_bannerSoldier = null
	hGenerator_bannerSoldier = null
	iBotId_TB = null
	sBotType = null
	sBannerType = null
	hPlayerEnt = null

	constructor(pBotId, pBannerType) {
		iBotId_TB = pBotId
		sBannerType = pBannerType //The Buff Banner, The Battalion's Backup, The Concheror
		switch(pBannerType) {
			case "The Battalion's Backup":
				sBotType = "bannerSoldier_backup"
				break
			case "The Concheror":
				sBotType = "bannerSoldier_conch"
				break
			default:
				sBotType = "bannerSoldier_buff"
				break
		}
	}

	function initialize(player) {

		hPlayerEnt = player

		local sPlayerName = "Buff Soldier (BOT)"
		local iBannerIndex = 129
		player.SetMaxHealth(200)

		if(sBannerType == "The Battalion's Backup") {
			sPlayerName = "Backup Soldier (BOT)"
			iBannerIndex = 226
			player.SetMaxHealth(220)
			player.SetHealth(220)
		}
		else if(sBannerType == "The Concheror") {
			sPlayerName = "Conch Soldier (BOT)"
			iBannerIndex = 354
			player.SetMaxHealth(200)
		}

		cleanInheritances_TB(player)

		SetFakeClientConVarValue(player, "name", sPlayerName)
		setBotReady_TB(player.GetEntityIndex())

		player.AddWeaponRestriction(2) //Primary only. Switch to banner through weapon_switch

		//Lobotomy! We'll be controlling their hands from here 
		//For a moment I thought stock soldier ai works well but apparently it is just insanely bad
		//We'll borrow grenade demo logic for this
		player.AddBotAttribute(IGNORE_ENEMIES|IGNORE_FLAG)
		player.SetMaxVisionRangeOverride(0.01)

		//First init = find out what starting currency is
		//Setting team to "auto" makes bots spawn with proper money, but only works on first spawn
		if(iGlobalMoney_TB == -1) {
			iGlobalMoney_TB = player.GetCurrency()
		}

		ClientPrint(null, 3, "\x01" + sPlayerName + " spawned with \x0722CC22" + iGlobalMoney_TB + " \x01credits")

		//Bots may inherit icons from blue robots, make sure they don't
		NetProps.SetPropString(player, "m_PlayerClass.m_iszClassIcon", "tester_bot")

		//Bots don't go for ammo packs, just make them have infinite ammo
		player.AddCustomAttribute("ammo regen", 1, -1)

		//They wont stop killing themselves here's a little something
		player.AddCustomAttribute("blast dmg to self increased", 0.0001, -1)

		local scope = player.GetScriptScope()

		scope.iBotId_TB <- iBotId_TB
		scope.botType_TB <- sBotType

		EntFire("tnGenerator_" + sBotType + "_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_" + sBotType + "_" + iBotId_TB, 0.0)

		////////////////////////
		//Think function below
		////////////////////////

		scope.flNextTargetRefreshTime <- Time() + 0.03
		scope.flNextJumpTime <- Time() + 0.03
		scope.bShouldUseBanner <- true //If there are enemies near us that we can see, this becomes false
		scope.iBannerPhase <- 0 //0 = Can use banner, 1 = Deploying banner, 2 = Should not use banner
		scope.flResetCanUseBannerTime <- 0
		scope.hPreferredTarget <- null
		scope.hPreferredAlly <- player
		scope.hOriginal <- GivePlayerWeapon_TB(player, "tf_weapon_rocketlauncher", 513) //Aims better with The Original
		scope.hBanner <- GivePlayerWeapon_TB(player, "tf_weapon_buff_item", iBannerIndex)

		upgradeBot_TB(player, bannerSoldierUpgradeTable, iGlobalMoney_TB)

		killstreakify_TB(player)

		//Upgrade first! Then set our projectile speed based on our rocket specialist upgrades
		scope.flProjectileSpeed <- 1100 * (1 + (scope.hOriginal.GetAttribute("rocket specialist", 0) * 0.15)) 

		scope.losTrace <- {
			start = Vector(0,0,0), //Will be modified so that it starts at self's eye position
			end = Vector(0,0,0), //Will be modified so that it ends at the target
			ignore = player,
			mask = 1174421507
		}

		scope.hBotActionPoint <- Entities.FindByName(null, "tnTarget_" + sBotType + "_" + iBotId_TB)

		scope.getNearestVisibleTarget <- function() {
			hPreferredTarget = null
			local hCurrentTarget = null
			local flClosestTargetDistance = 100000
			bShouldUseBanner = true
			while(hCurrentTarget = Entities.FindByClassname(hCurrentTarget, "player")) {
				if(hCurrentTarget.GetTeam() != 3) continue
				if(NetProps.GetPropInt(hCurrentTarget, "m_lifeState") != 0) continue

				//Target is in spawn = don't bother
				if(hCurrentTarget.InCond(51)) continue

				//Ubered giants = dont bother
				if(hCurrentTarget.InCond(5) && hCurrentTarget.IsMiniBoss()) continue

				losTrace.end = hCurrentTarget.EyePosition()

				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentTarget) continue

				local vTargetOrigin = hCurrentTarget.GetOrigin()

				local vTargetOriginDifference = vTargetOrigin - self.GetOrigin()
				local flTargetDistance = vTargetOriginDifference.Length()

				//Target is TOO FAR AWAY
				if(flTargetDistance > 3000) continue

				//Side gig: remember that there's an enemy nearby that we can see, so don't use banner
				if(flTargetDistance < 1200) {
					bShouldUseBanner = false
				}

				local targetIsBehindSelf = vTargetOrigin.Dot(self.EyeAngles().Forward()) > self.GetOrigin().Length()

				//Reduce the importance of targets behind us since we don't want our bot to be spinbotting around, but still able to react to threats behind
				if(targetIsBehindSelf) {
					flTargetDistance += 512
				}

				//Ubered by medicbots: try to launch it anyways, but put them on lower priority
				if(hCurrentTarget.InCond(5)) {
					flTargetDistance += 512
				}

				//Prioritize bomb carriers if they are within a reasonable distance
				if(hCurrentTarget.HasItem()) {
					flTargetDistance -= 1024
				}

				local iCurrentTargetClass = hCurrentTarget.GetPlayerClass()

				//Spycheck
				if(iCurrentTargetClass == TF_CLASS_SPY) {
					//Disguised spy = not that important but still a little bit of priority
					if(hCurrentTarget.InCond(3)) {
						flTargetDistance *= 0.7
					}

					//Undisguised spy = panic
					else {
						flTargetDistance *= 0.05
					}
					
				}

				//Medicbots are also important but not by that much
				if(iCurrentTargetClass == TF_CLASS_MEDIC) {
					flTargetDistance *= 0.5
				}

				//Yellow eyed pyros = less important
				//But what about normal skill pyros you ask? Treat them as the same as other bots.
				//KEEP GAMBLING ON THE 50/50
				if(iCurrentTargetClass == TF_CLASS_PYRO && hCurrentTarget.GetDifficulty() > 1) {
					flTargetDistance += 700
				}

				if(flTargetDistance < flClosestTargetDistance) {
					flClosestTargetDistance = flTargetDistance
					hPreferredTarget = hCurrentTarget
				}
			}

			//We also need to shoot at tanks!
			local hCurrentTank = null
			while(hCurrentTank = Entities.FindByClassname(hCurrentTank, "tank_boss")) {
				if(hCurrentTank.GetTeam() != 3) continue

				losTrace.end = hCurrentTank.GetCenter()

				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentTank) continue

				local vTankOrigin = hCurrentTank.GetOrigin()

				local vTankOriginDifference = vTankOrigin - self.GetOrigin()
				local flTankDistance = vTankOriginDifference.Length()

				//Tank is TOO FAR AWAY
				if(flTankDistance > 3000) continue

				local tankIsBehindSelf = vTankOrigin.Dot(self.EyeAngles().Forward()) > self.GetOrigin().Length()

				//Tanks should be treated as lower priority than players.
				flTankDistance += 512
				
				if(tankIsBehindSelf) {
					flTankDistance += 512
				}

				if(flTankDistance < flClosestTargetDistance) {
					flClosestTargetDistance = flTankDistance
					hPreferredTarget = hCurrentTank
				}
			}
		}

		scope.bannerSoldierThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}

			losTrace.start = self.EyePosition()

			//Is there cash near us? Collect it
			for ( local currencyPackEntity; currencyPackEntity = Entities.FindByClassnameWithin( currencyPackEntity, "item_currencypack_*", self.GetOrigin(), 50 ); ) {
				collectCash(currencyPackEntity, self)
			}
			
			//Where should we go?
			//Find a teammate and stick near them
			//Details and priorities below
			
			if(Time() >= flNextTargetRefreshTime || (hPreferredAlly.IsPlayer() && NetProps.GetPropInt(player, "m_lifeState") != 0)) {
				flNextTargetRefreshTime += 3

				hPreferredAlly = null
				local flClosestAllyDistance = 100000000.0
				local hCurrentPlayer = null
				while(hCurrentPlayer = Entities.FindByClassname(hCurrentPlayer, "player")) {

					if(hCurrentPlayer.GetTeam() != 2) continue
					if(NetProps.GetPropInt(hCurrentPlayer, "m_lifeState") != 0) continue

					//Do not follow other bots. Fall back to the bomb
					if(IsPlayerABot(hCurrentPlayer)) {
						continue
					}

					local vAllyOriginDifference = hCurrentPlayer.GetOrigin() - self.GetOrigin()
					local flAllyDistance = vAllyOriginDifference.Length()

					local iCurrentPlayerClass = hCurrentPlayer.GetPlayerClass()

					//Strongly discourage this bot from following scouts, pyros, and spies
					if(iCurrentPlayerClass == TF_CLASS_SCOUT || iCurrentPlayerClass == TF_CLASS_PYRO || iCurrentPlayerClass == TF_CLASS_SPY) {
						flAllyDistance += 512
						flAllyDistance *= 2
					}

					//Lightly discourage this bot from following heavies, engineers and snipers
					if(iCurrentPlayerClass == TF_CLASS_HEAVYWEAPONS || iCurrentPlayerClass == TF_CLASS_ENGINEER || iCurrentPlayerClass == TF_CLASS_SNIPER) {
						flAllyDistance += 256
						flAllyDistance *= 1.5
					}

					if(flAllyDistance < flClosestAllyDistance) {
						flClosestAllyDistance = flAllyDistance
						hPreferredAlly = hCurrentPlayer
					}
				}

				//No active teammates? just grab the first bomb we can and go there
				if(hPreferredAlly == null) {
					hPreferredAlly = Entities.FindByClassname(null, "item_teamflag")
				}
			}

			if(hBotActionPoint != null && hBotActionPoint.IsValid()) {
				hBotActionPoint.SetAbsOrigin(hPreferredAlly.GetOrigin())
			}

			//Randomly jump and hope we dodge or reduce a random attack's damage
			//I could try to detect for rockets/pipes/stickies nearby but I don't want to
			if(Time() >= flNextJumpTime) {
				flNextJumpTime = Time() + 1.6
				self.GetLocomotionInterface().Jump()
			}

			//Who should we look at?
			//How should we aim?
			getNearestVisibleTarget()

			//Rip guard clause
			//Don't hold fire or even aim if we're deploying banner
			if(hPreferredTarget != null && iBannerPhase != 1) {
				local selfEyePosition = self.EyePosition()

				//First we try to aim for the target's feet...
				local targetPosition = hPreferredTarget.GetOrigin()

				losTrace.end = targetPosition

				TraceLineEx(losTrace)

				//We don't have direct los to target's feet. Try aiming for the center now
				if(losTrace.hit == false || losTrace.enthit != hPreferredTarget) {
					targetPosition = hPreferredTarget.GetCenter()

					losTrace.end = targetPosition

					TraceLineEx(losTrace)
					
					//No direct los to target's center. Fall back to eyes.
					//Target could also be tanks which don't have eyes, don't fall back if the target is a tank
					if(hPreferredTarget.IsPlayer() && (losTrace.hit == false || losTrace.enthit != hPreferredTarget)) {
						targetPosition = hPreferredTarget.EyePosition()
					}
				}

				//Predict where the target will be
				//Ty kiwi's vscript aimbot for help
				local posDiff = targetPosition - selfEyePosition
				local rocketTravelTimeToTargetCurrentPos = posDiff.Length() / flProjectileSpeed
				local targetAbsVelocity = hPreferredTarget.GetAbsVelocity()

				for(local i = 0; i < 5; i++) {
					local predictedTargetPos = targetPosition + (targetAbsVelocity * rocketTravelTimeToTargetCurrentPos)
					local predictedPosDiff = predictedTargetPos - selfEyePosition
					rocketTravelTimeToTargetCurrentPos = predictedPosDiff.Length() / flProjectileSpeed
				}

				local finalPredictedTargetPos = targetPosition + (targetAbsVelocity * rocketTravelTimeToTargetCurrentPos)
				local finalPredictedPosDiff = finalPredictedTargetPos - selfEyePosition

				self.SnapEyeAngles(VectorAngles_TB(finalPredictedPosDiff))
				self.PressFireButton(0.1)
			}

			//Should we pop banner? How?
			//Is our banner even charged?
			if(self.GetRageMeter() < 100) return -1

			//Are we currently ubered or crit-boosted? Hold it off for later
			//Screw vaccinator
			if(self.InCond(5)) return -1
			if(self.InCond(11)) return -1
			if(self.InCond(28)) return -1
			if(self.InCond(34)) return -1
			if(self.InCond(52)) return -1

			//Is there anyone near us that we can see? Don't pop banner, hold it off
			//Code for setting this in GetNearestVisibleTarget()
			if(!bShouldUseBanner) return -1

			//Allow for redeploying banner if we haven't used it for a while
			if(iBannerPhase == 2) {
				if(Time() >= flResetCanUseBannerTime) {
					iBannerPhase = 0
				}
				return -1
			}

			if(iBannerPhase == 0) {
				self.Weapon_Switch(hBanner)
				self.AddCustomAttribute("disable weapon switch", 1.0, 3)
				self.PressFireButton(1.8)
				self.AddBotAttribute(SUPPRESS_FIRE) //The bot will hold m1 if we dont slap this
				EntFireByHandle(self, "RunScriptCode", "self.RemoveBotAttribute(SUPPRESS_FIRE)", 4, self, self)
				EntFireByHandle(self, "RunScriptCode", "self.GetScriptScope().iBannerPhase = 2", 4, self, self)

				iBannerPhase = 1

				flResetCanUseBannerTime = Time() + 4 + (hBanner.GetAttribute("increase buff duration", 1) * 10)
			}

			return -1
		}

		AddThinkToEnt(player, "bannerSoldierThink")
	}

	function add() {
		hTarget_bannerSoldier = SpawnEntityFromTable("bot_action_point"
		{
			stay_time = 99999
			targetname = "tnTarget_" + sBotType + "_" + iBotId_TB
			command = "next_action_point"
			desired_distance = 128
			next_action_point = "tnTarget_" + sBotType + "_" + iBotId_TB
			origin = Vector(0,0,0)
		})

		hGenerator_bannerSoldier = SpawnEntityFromTable("bot_generator"
		{
			team = "auto"
			origin = botGeneratorPivot
			maxActive = 1
			difficulty = 3
			disableDodge = 0
			interval = 1 // Irrelevant due to spawnOnlyWhenTriggered
			count = 1
			initial_command = "goto action point"
			action_point = "tnTarget_" + sBotType + "_" + iBotId_TB
			spawnOnlyWhenTriggered = 1
			targetname = "tnGenerator_" + sBotType + "_" + iBotId_TB
		})

		//Silly workaround to make our entities preserved through wave fails and mission switches
		hTarget_bannerSoldier.KeyValueFromString("classname", "entity_saucer")
		hGenerator_bannerSoldier.KeyValueFromString("classname", "entity_saucer")


		NetProps.SetPropString(hGenerator_bannerSoldier, "m_className", "soldier")

		EntityOutputs.AddOutput(hGenerator_bannerSoldier, "OnSpawned", "!activator", "RunScriptCode", "botList_TB[" + iBotId_TB + "].initialize(self)", 0.0, -1)

		hGenerator_bannerSoldier.AcceptInput("SpawnBot", null, null, null)
	}
}