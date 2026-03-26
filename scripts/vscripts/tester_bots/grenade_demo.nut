//Grenade Demo
//Every 3 seconds, this bot will pick an ally to follow and stay close to
//Prioritizes certain classes and human players
//Uses the chargin' targe but never charges

//BOTS MAY INHERIT MVM ROBOT TRAITS, MODELS ETC. REMOVE ALL OF THEM.

class grenadeDemo {

	hTarget = null
	hGenerator = null
	iBotId_TB = null
	sBotType = null
	hPlayerEnt = null

	constructor(pBotId) {
		iBotId_TB = pBotId
		sBotType = "grenadeDemo"
	}

	function initialize(player) {

		hPlayerEnt = player

		//How did we activate on a non-red bot? Don't initialize.
		if(hPlayerEnt.GetTeam() != 2) return

		SetFakeClientConVarValue(player, "name", "Grenade Demo (BOT)")
		setBotReady_TB(player.GetEntityIndex())

		cleanInheritances_TB(player)
		player.SetMaxHealth(175)

		player.AddWeaponRestriction(2) //Primary only

		//Lobotomy! We'll be controlling their hands from here 
		player.AddBotAttribute(IGNORE_ENEMIES|IGNORE_FLAG)
		player.SetMaxVisionRangeOverride(0.01)

		player.GenerateAndWearItem("The Chargin' Targe")

		//First init = find out what starting currency is
		//Setting team to "auto" makes bots spawn with proper money, but only works on first spawn
		if(iGlobalMoney_TB == -1) {
			iGlobalMoney_TB = player.GetCurrency()
		}

		printChatMessage_TB("\x01Grenade Demo (BOT) spawned with \x0722CC22" + iGlobalMoney_TB + " \x01credits", 2)

		//Bots may inherit icons from blue robots, make sure they don't
		NetProps.SetPropString(player, "m_PlayerClass.m_iszClassIcon", "tester_bot")

		//Bots don't go for ammo packs, just make them have infinite ammo
		player.AddCustomAttribute("ammo regen", 1, -1)

		//Stop charging!
		player.AddCustomAttribute("charge recharge rate increased", -999, -1)
		player.AddCustomAttribute("charge time decreased", -1.45, -1)

		//They wont stop killing themselves here's a little something
		player.AddCustomAttribute("blast dmg to self increased", 0.0001, -1)

		local scope = player.GetScriptScope()

		scope.iBotId_TB <- iBotId_TB
		scope.botType_TB <- "grenadeDemo"

		EntFire("tnGenerator_grenadeDemo_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_grenadeDemo_" + iBotId_TB, 0.0)

		////////////////////////
		//Think function below
		////////////////////////

		scope.flNextTargetRefreshTime <- Time() + 0.03
		scope.flNextJumpTime <- Time() + 0.03
		scope.hPreferredAlly <- player
		scope.hPreferredTarget <- null
		scope.bShouldReloadToFull <- false
		scope.hGrenadeLauncher <- getWeaponInSlot_TB(player, 0)

		scope.hBotActionPoint <- Entities.FindByName(null, "tnTarget_grenadeDemo_" + iBotId_TB)

		upgradeBot_TB(player, grenadeDemoUpgradeTable, iGlobalMoney_TB)

		killstreakify_TB(player)

		scope.losTrace <- {
			start = Vector(0,0,0), //Will be modified so that it starts at self's eye position
			end = Vector(0,0,0), //Will be modified so that it ends at the target
			ignore = player,
			mask = 1174421507
		}

		scope.getNearestVisibleTarget <- function() {
			hPreferredTarget = null
			local hCurrentTarget = null
			local flClosestTargetDistance = 100000
			while(hCurrentTarget = Entities.FindByClassname(hCurrentTarget, "player")) {
				if(hCurrentTarget.GetTeam() != 3) continue
				if(NetProps.GetPropInt(hCurrentTarget, "m_lifeState") != 0) continue

				//Target is in spawn = don't bother
				if(hCurrentTarget.InCond(51)) continue

				//Ubered giants = dont bother
				if(hCurrentTarget.InCond(5) && hCurrentTarget.IsMiniBoss()) continue

				//No los to target = don't bother
				losTrace.end = hCurrentTarget.EyePosition()
				
				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentTarget) continue

				local vTargetOrigin = hCurrentTarget.GetOrigin()

				local vTargetOriginDifference = vTargetOrigin - self.GetOrigin()
				local flTargetDistance = vTargetOriginDifference.Length()

				//Target is TOO FAR AWAY
				if(flTargetDistance > 1500) continue

				local targetIsBehindSelf = vTargetOrigin.Dot(self.EyeAngles().Forward()) > self.GetOrigin().Length()

				//Reduce the importance of targets behind us since we don't want our bot to be spinbotting around, but still able to react to threats behind
				if(targetIsBehindSelf) {
					flTargetDistance += 512
				}

				//Ubered by medicbots or bonked: try to launch it anyways, but put them on lower priority
				if(hCurrentTarget.InCond(5) || hCurrentTarget.InCond(14)) {
					flTargetDistance += 512
				}

				//Prioritize bomb carriers if they are within a reasonable distance, and aren't being healed
				if(hCurrentTarget.HasItem() && !(hCurrentTarget.InCond(TF_COND_HEALTH_BUFF))) {
					flTargetDistance -= 1024
				}

				local iCurrentTargetClass = hCurrentTarget.GetPlayerClass()

				//Spycheck
				if(hCurrentTarget.HasMission(4)) {
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
					flTargetDistance *= 0.4

					//Unless they are healing the bomb carrier
					local hCurrentTargetHealTarget = hCurrentTarget.GetHealTarget()
					if(hCurrentTargetHealTarget != null && hCurrentTargetHealTarget.HasItem()) {
						flTargetDistance -= 1024
					}
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
				if(hCurrentTank.GetMaxHealth() <= 0) continue

				losTrace.end = hCurrentTank.GetCenter()

				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentTank) continue

				local vTankOrigin = hCurrentTank.GetOrigin()

				local vTankOriginDifference = vTankOrigin - self.GetOrigin()
				local flTankDistance = vTankOriginDifference.Length()

				//Tank is TOO FAR AWAY
				if(flTankDistance > 1800) continue

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

			//And lastly we need to shoot at buildings
			local hCurrentBuilding = null
			while(hCurrentBuilding = Entities.FindByClassname(hCurrentBuilding, "obj_*")) {
				if(hCurrentBuilding.GetClassname() == "obj_attachment_sapper") continue
				if(hCurrentBuilding.GetTeam() != 3) continue
				if(hCurrentBuilding.GetMaxHealth() <= 0) continue

				losTrace.end = hCurrentBuilding.GetCenter()

				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentBuilding) continue

				local vBuildingOrigin = hCurrentBuilding.GetOrigin()

				local vBuildingOriginDifference = vBuildingOrigin - self.GetOrigin()
				local flBuildingDistance = vBuildingOriginDifference.Length()

				//Sentry Gun is TOO FAR AWAY
				if(flBuildingDistance > 1800) continue

				if(flBuildingDistance < flClosestTargetDistance) {
					flClosestTargetDistance = flBuildingDistance
					hPreferredTarget = hCurrentBuilding
				}
			}
		}

		scope.grenadeDemoThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}

			//Is there cash near us? Collect it
			for ( local currencyPackEntity; currencyPackEntity = Entities.FindByClassnameWithin( currencyPackEntity, "item_currencypack_*", self.GetOrigin(), 50 ); ) {
				collectCash(currencyPackEntity, self)
			}

			//Is our clip empty?
			//If so, stop firing until we fully reload
			//Grenade launchers are massively punished for not fully reloading before firing, this is important
			//For our purposes, reloading to 4 clip = reloading to full
			//Even though clip size can be upgraded, this is good enough

			if(hGrenadeLauncher != null && hGrenadeLauncher.IsValid()) {
				local iCurrentClip = hGrenadeLauncher.Clip1()
				if(iCurrentClip == 0) {
					bShouldReloadToFull = true
				}
				else if(iCurrentClip >= 4) {
					bShouldReloadToFull = false
				}
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

				//No active teammates? Go for the closest bomb to hatch
				if(hPreferredAlly == null) {
					hPreferredAlly = hClosestBomb_TB
				}
			}

			if(hBotActionPoint != null && hBotActionPoint.IsValid()) {
				hBotActionPoint.SetAbsOrigin(hPreferredAlly.GetOrigin())
			}

			//Randomly jump and hope we dodge or reduce a random attack's damage
			//I could try to detect for rockets/pipes/stickies nearby but I don't want to
			if(Time() >= flNextJumpTime) {
				flNextJumpTime = Time() + 3.2
				self.GetLocomotionInterface().Jump()
			}
			
			//Who should we look at?
			//getNearestVisibleTarget(), of course!
			//If null, let the bot do its own thing
			//Try to lead its aim because grenade demos dont naturally do that
			//Not aimbot accuracy but you know what good enough
			//Demos shouldnt be crazy aimbots anyways

			//We're reloading! Don't bother
			if(bShouldReloadToFull == true) return -1

			losTrace.start = self.EyePosition()

			getNearestVisibleTarget()
			
			if(hPreferredTarget == null) return -1

			local selfEyePosition = self.EyePosition()
			local targetFeetPosition = hPreferredTarget.GetOrigin()

			// DebugDrawLine(selfEyePosition, hPreferredTarget.EyePosition(), 255, 10, 10, false, 3)

			//Predict where the target will be
			//Ty kiwi's vscript aimbot for help
			local posDiff = targetFeetPosition - selfEyePosition
			local grenadeTravelTimeToTargetCurrentPos = posDiff.Length() / 1100 //Pipes are affected by drag, this is give or take
			local targetAbsVelocity = hPreferredTarget.GetAbsVelocity()

			for(local i = 0; i < 5; i++) {
				local predictedTargetPos = targetFeetPosition + (targetAbsVelocity * grenadeTravelTimeToTargetCurrentPos)
				
				local predictedPosDiff = predictedTargetPos - selfEyePosition
				//Pipes arc down, let's aim up a bit
				predictedPosDiff.z += 300 * grenadeTravelTimeToTargetCurrentPos * grenadeTravelTimeToTargetCurrentPos
				grenadeTravelTimeToTargetCurrentPos = predictedPosDiff.Length() / 1100
			}

			local finalPredictedTargetPos = targetFeetPosition + (targetAbsVelocity * grenadeTravelTimeToTargetCurrentPos)
			local finalPredictedPosDiff = finalPredictedTargetPos - selfEyePosition
			finalPredictedPosDiff.z += 300 * grenadeTravelTimeToTargetCurrentPos * grenadeTravelTimeToTargetCurrentPos

			// DebugDrawLine(losTrace.startpos, losTrace.endpos, 255, 10, 10, false, 3)
			// DebugDrawLine(targetFeetPosition, Vector(targetFeetPosition.x, targetFeetPosition.y, targetFeetPosition.z + 128), 255, 10, 10, false, 0.5)

			self.SnapEyeAngles(VectorAngles_TB(finalPredictedPosDiff))
			self.PressFireButton(0.1)

			return -1
		}

		AddThinkToEnt(player, "grenadeDemoThink")
	}
	
	function add() {
		hTarget = SpawnEntityFromTable("bot_action_point",
		{
			stay_time = 99999
			targetname = "tnTarget_grenadeDemo_" + iBotId_TB
			command = "next_action_point"
			desired_distance = 128
			next_action_point = "tnTarget_grenadeDemo_" + iBotId_TB
			origin = Vector(0,0,0)
		})
		
		hGenerator = SpawnEntityFromTable("bot_generator",
		{
			team = "auto"
			origin = botGeneratorPivot
			maxActive = 3
			difficulty = 3
			disableDodge = 0
			interval = 1 // Irrelevant due to spawnOnlyWhenTriggered
			count = -1
			initial_command = "goto action point"
			action_point = "tnTarget_grenadeDemo_" + iBotId_TB
			spawnOnlyWhenTriggered = 1
			targetname = "tnGenerator_grenadeDemo_" + iBotId_TB
		})

		//Silly workaround to make our entities preserved through wave fails and mission switches
		hTarget.KeyValueFromString("classname", "entity_saucer")
		hGenerator.KeyValueFromString("classname", "entity_saucer")

		NetProps.SetPropString(hGenerator, "m_className", "demoman")

		EntityOutputs.AddOutput(hGenerator, "OnSpawned", "!activator", "RunScriptCode", "botList_TB[" + iBotId_TB + "].initialize(self)", 0.0, -1)

		hGenerator.AcceptInput("SpawnBot", null, null, null)
	}
}