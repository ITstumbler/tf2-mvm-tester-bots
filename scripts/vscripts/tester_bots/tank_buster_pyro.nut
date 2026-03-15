//Tank Buster Pyro
//Paths towards the oldest tank 
//Prioritizes certain classes and human players
//Uses the chargin' targe but never charges

//BOTS MAY INHERIT MVM ROBOT TRAITS, MODELS ETC. REMOVE ALL OF THEM.

class tankBusterPyro {

	hTarget_tankBusterPyro = null
	hGenerator_tankBusterPyro = null
	iBotId_TB = null
	sBotType = null
	hPlayerEnt = null

	constructor(pBotId) {
		iBotId_TB = pBotId
		sBotType = "tankBusterPyro"
	}

	function initialize(player) {

		hPlayerEnt = player

		SetFakeClientConVarValue(player, "name", "Tank Buster (BOT)")
		setBotReady_TB(player.GetEntityIndex())

		cleanInheritances_TB(player)
		player.SetMaxHealth(175)

		//Lobotomy! We'll be controlling their hands from here 
		player.AddBotAttribute(IGNORE_ENEMIES|IGNORE_FLAG)
		player.SetMaxVisionRangeOverride(0.01)

		//First init = find out what starting currency is
		//Setting team to "auto" makes bots spawn with proper money, but only works on first spawn
		if(iGlobalMoney_TB == -1) {
			iGlobalMoney_TB = player.GetCurrency()
		}

		printChatMessage_TB("\x01Tank Buster (BOT) spawned with \x0722CC22" + iGlobalMoney_TB + " \x01credits", 2)

		//Bots may inherit icons from blue robots, make sure they don't
		NetProps.SetPropString(player, "m_PlayerClass.m_iszClassIcon", "tester_bot")

		//Bots don't go for ammo packs, just make them have infinite ammo
		player.AddCustomAttribute("ammo regen", 1, -1)

		local scope = player.GetScriptScope()

		scope.iBotId_TB <- iBotId_TB
		scope.botType_TB <- "tankBusterPyro"

		EntFire("tnGenerator_tankBusterPyro_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_tankBusterPyro_" + iBotId_TB, 0.0)

		////////////////////////
		//Think function below
		////////////////////////

		scope.flNextRefreshBombTime <- Time() + 0.03
		scope.hPreferredBomb <- Entities.FindByClassname(null, "item_teamflag")
		scope.hPreferredDestination <- player
		scope.hPreferredTarget <- null
		scope.vPreferredAllyOrigin <- Vector(0,0,0)
		scope.bShouldReloadToFull <- false
		scope.hPhlogistinator <- GivePlayerWeapon_TB(player, "tf_weapon_flamethrower", 594)
		scope.hPowerjack <- GivePlayerWeapon_TB(player, "tf_weapon_fireaxe", 214)
		scope.bHasPowerjackOut <- false

		scope.hBotActionPoint <- Entities.FindByName(null, "tnTarget_tankBusterPyro_" + iBotId_TB)

		upgradeBot_TB(player, tankBusterPyroUpgradeTable, iGlobalMoney_TB)

		killstreakify_TB(player)

		scope.losTrace <- {
			start = Vector(0,0,0), //Will be modified so that it starts at self's eye position
			end = Vector(0,0,0), //Will be modified so that it ends at the target
			ignore = player,
			mask = 1174421507
		}

		scope.findPreferredDestination <- function() {
			hPreferredDestination = null
			local hCurrentDestination = null
			local flLowestTankHealth = 9999999

			//Iterate through tanks first. We're Tank Buster Pyro after all
			//Go for the lowest health tank always
			while(hCurrentDestination = Entities.FindByClassname(hCurrentDestination, "tank_boss")) {

				local tankHealth = hCurrentDestination.GetHealth()

				if(tankHealth < flLowestTankHealth) {
					flLowestTankHealth = tankHealth
					hPreferredDestination = hCurrentDestination
				}
			}

			if(hPreferredDestination != null) return

			//No tank, search for players now
			local flClosestDestinationDistance = 100000000.0

			while(hCurrentDestination = Entities.FindByClassname(hCurrentDestination, "player")) {

				if(hCurrentDestination.GetTeam() != 3) continue
				if(NetProps.GetPropInt(hCurrentDestination, "m_lifeState") != 0) continue

				//Target is in spawn = don't bother
				if(hCurrentDestination.InCond(51)) continue

				//Ubered enemies = don't bother
				if(hCurrentDestination.InCond(5)) continue

				local vDestinationOriginDifference = hCurrentDestination.GetOrigin() - self.GetOrigin()
				local flDestinationDistance = vDestinationOriginDifference.Length()

				//Bomb carrier = priority unless too far away or healed by a medic (in which case the medic takes priority)
				if(hCurrentDestination.HasItem() && !(hCurrentDestination.InCond(TF_COND_HEALTH_BUFF))) {
					flDestinationDistance -= 1500
				}

				//Medics healing the bomb carrier = priority
				local hCurrentDestinationHealTarget = hCurrentDestination.GetHealTarget()
				if(hCurrentDestinationHealTarget != null && hCurrentDestinationHealTarget.HasItem()) {
					flDestinationDistance -= 1500
				}

				if(flDestinationDistance < flClosestDestinationDistance) {
					flClosestDestinationDistance = flDestinationDistance
					hPreferredDestination = hCurrentDestination
				}
			}

			//No active enemies? Go for the closest bomb to hatch
			if(hPreferredDestination == null) {
				hPreferredDestination = hClosestBomb_TB
			}
		}

		//When it comes to who to shoot though, shoot robots first
		scope.getNearestVisibleTarget <- function() {
			hPreferredTarget = null
			local hCurrentTarget = null
			local flClosestTargetDistance = 100000
			while(hCurrentTarget = Entities.FindByClassname(hCurrentTarget, "player")) {
				if(hCurrentTarget.GetTeam() != 3) continue
				if(NetProps.GetPropInt(hCurrentTarget, "m_lifeState") != 0) continue

				//Target is in spawn = don't bother
				if(hCurrentTarget.InCond(51)) continue

				//Ubered enemies = don't bother
				if(hCurrentTarget.InCond(5)) continue

				local vTargetOrigin = hCurrentTarget.GetOrigin()

				local vTargetOriginDifference = vTargetOrigin - self.GetOrigin()
				local flTargetDistance = vTargetOriginDifference.Length()

				//Target is outside of our flamethrower range, dont bother
				if(flTargetDistance > 350) continue

				//Bomb carrier = priority unless healed by a medic (in which case the medic takes priority)
				if(hCurrentTarget.HasItem() && !(hCurrentTarget.InCond(TF_COND_HEALTH_BUFF))) {
					flTargetDistance -= 1024
				}

				//Apparently this check can fail at random for some reasons. Penalize distance instead of skipping entirely
				losTrace.end = hCurrentTarget.EyePosition()

				TraceLineEx(losTrace)

				if(!losTrace.hit || losTrace.enthit != hCurrentTarget) {
					flTargetDistance += 128
				}

				local iCurrentTargetClass = hCurrentTarget.GetPlayerClass()

				//Spycheck
				if(hCurrentTarget.HasMission(4)) {
					//Disguised spy = not that important but still a little bit of priority
					if(hCurrentTarget.InCond(3)) {
						flTargetDistance *= 0.8
					}

					//Undisguised spy = panic
					else {
						flTargetDistance *= 0.05
					}
				}

				//Medicbots are also important
				if(iCurrentTargetClass == TF_CLASS_MEDIC) {
					flTargetDistance *= 0.4

					//If they are healing the bomb carrier, they are top priority
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

			//We also need to shoot at tanks, but they're not higher priority than players
			local hCurrentTank = null
			while(hCurrentTank = Entities.FindByClassname(hCurrentTank, "tank_boss")) {
				if(hCurrentTank.GetTeam() != 3) continue

				local vTankOrigin = hCurrentTank.GetOrigin()

				local vTankOriginDifference = vTankOrigin - self.GetOrigin()
				local flTankDistance = vTankOriginDifference.Length()

				if(flTankDistance > 350) continue

				losTrace.end = hCurrentTank.GetCenter()

				TraceLineEx(losTrace)

				if(!losTrace.hit || losTrace.enthit != hCurrentTarget) {
					flTankDistance += 256
				}

				//Tanks should be treated as lower priority than players
				flTankDistance += 300

				if(flTankDistance < flClosestTargetDistance) {
					flClosestTargetDistance = flTankDistance
					hPreferredTarget = hCurrentTank
				}
			}
		}

		scope.tankBusterPyroThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}

			//Is there cash near us? Collect it
			for ( local currencyPackEntity; currencyPackEntity = Entities.FindByClassnameWithin( currencyPackEntity, "item_currencypack_*", self.GetOrigin(), 50 ); ) {
				collectCash(currencyPackEntity, self)
			}

			losTrace.start = self.EyePosition()

			//POP THAT PHLOG
			//Unless we're already crit-boosted
			if(!(self.InCond(11)) && !(self.InCond(34))) {
				self.PressAltFireButton(1)
			}
			
			//Where should we go?
			//Find the lowest health tank, or the closest enemy to us
			
			findPreferredDestination()

			if(hBotActionPoint != null && hBotActionPoint.IsValid() && hPreferredDestination != null && hPreferredDestination.IsValid()) {
				hBotActionPoint.SetAbsOrigin(hPreferredDestination.GetOrigin())
			}
			
			//Who should we shoot at?
			//If we don't find anyone, switch to powerjack so we can move around faster

			getNearestVisibleTarget()
			
			if(hPreferredTarget == null) {
				if(!bHasPowerjackOut) {
					self.Weapon_Switch(hPowerjack)
					bHasPowerjackOut = true
				}
				return -1
			}

			if(bHasPowerjackOut) {
				self.Weapon_Switch(hPhlogistinator)
				bHasPowerjackOut = false
			}

			//Spinbot spinbot babyyyyy
			local selfEyePosition = self.EyePosition()
			local targetCenterPosition = hPreferredTarget.GetCenter()

			//Aim up against tanks, since we already prioritize tanks last when it comes to shooting
			if(hPreferredTarget.GetClassname() == "tank_boss") {
				targetCenterPosition.z += 250
			}

			local posDiff = targetCenterPosition - selfEyePosition
		
			self.SnapEyeAngles(VectorAngles_TB(posDiff))
			self.PressFireButton(1.5)

			return -1
		}

		AddThinkToEnt(player, "tankBusterPyroThink")
	}

	function add() {
		hTarget_tankBusterPyro = SpawnEntityFromTable("bot_action_point",
		{
			stay_time = 99999
			targetname = "tnTarget_tankBusterPyro_" + iBotId_TB
			command = "next_action_point"
			desired_distance = 1
			next_action_point = "tnTarget_tankBusterPyro_" + iBotId_TB
			origin = Vector(0,0,0)
		})

		hGenerator_tankBusterPyro = SpawnEntityFromTable("bot_generator",
		{
			team = "auto"
			origin = botGeneratorPivot
			maxActive = 1
			difficulty = 3
			disableDodge = 0
			interval = 1 // Irrelevant due to spawnOnlyWhenTriggered
			count = 1
			initial_command = "goto action point"
			action_point = "tnTarget_tankBusterPyro_" + iBotId_TB
			spawnOnlyWhenTriggered = 1
			targetname = "tnGenerator_tankBusterPyro_" + iBotId_TB
		})

		//Silly workaround to make our entities preserved through wave fails and mission switches
		hTarget_tankBusterPyro.KeyValueFromString("classname", "entity_saucer")
		hGenerator_tankBusterPyro.KeyValueFromString("classname", "entity_saucer")

		NetProps.SetPropString(hGenerator_tankBusterPyro, "m_className", "pyro")

		EntityOutputs.AddOutput(hGenerator_tankBusterPyro, "OnSpawned", "!activator", "RunScriptCode", "botList_TB[" + iBotId_TB + "].initialize(self)", 0.0, -1)

		hGenerator_tankBusterPyro.AcceptInput("SpawnBot", null, null, null)
	}
}