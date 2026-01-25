//Bomb Camper Heavy
//Every 5 seconds, this bot will pick the closest enabled bomb to hatch
//He will then walk towards the bomb and stand there until it dies or the bomb moves
//Always revs up on top of the bomb
//Never switches to other weapons

//BOTS MAY INHERIT MVM ROBOT TRAITS, MODELS ETC. REMOVE ALL OF THEM.

class bombCamperHeavy {

	hTarget_bombCamperHeavy = null
	hGenerator_bombCamperHeavy = null
	iBotId_TB = null
	sBotType = null
	hPlayerEnt = null

	constructor(pBotId) {
		iBotId_TB = pBotId
		sBotType = "bombCamperHeavy"
	}

	function initialize(player) {

		hPlayerEnt = player

		SetFakeClientConVarValue(player, "name", "Bomb Camper (BOT)")
		setBotReady_TB(player.GetEntityIndex())

		cleanInheritances_TB(player)
		player.SetMaxHealth(300)

		player.AddWeaponRestriction(2) //Primary only

		//First init = find out what starting currency is
		//Setting team to "auto" makes bots spawn with proper money, but only works on first spawn
		if(iGlobalMoney_TB == -1) {
			iGlobalMoney_TB = player.GetCurrency()
		}

		ClientPrint(null, 3, "\x01Bomb Camper (BOT) spawned with \x0722CC22" + iGlobalMoney_TB + " \x01credits")

		//Bots may inherit icons from blue robots, make sure they don't
		NetProps.SetPropString(player, "m_PlayerClass.m_iszClassIcon", "tester_bot")

		//Bots don't go for ammo packs, just make them have infinite ammo
		player.AddCustomAttribute("ammo regen", 1, -1)

		local scope = player.GetScriptScope()

		scope.iBotId_TB <- iBotId_TB
		scope.botType_TB <- "bombCamperHeavy"

		EntFire("tnGenerator_bombCamperHeavy_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_bombCamperHeavy_" + iBotId_TB, 0.0)

		////////////////////////
		//Think function below
		////////////////////////

		scope.flNextRefreshBombTime <- Time() + 0.03
		scope.hPreferredBomb <- Entities.FindByClassname(null, "item_teamflag")
		scope.vPreferredBombOrigin <- Vector(0,0,0)
		scope.hBombCarrierToAimbotAt <- null

		upgradeBot_TB(player, bombCamperHeavyUpgradeTable, iGlobalMoney_TB)

		killstreakify_TB(player)

		scope.hBotActionPoint <- Entities.FindByName(null, "tnTarget_bombCamperHeavy_" + iBotId_TB)

		scope.losTrace <- {
			start = Vector(0,0,0), //Will be modified so that it starts at self's eye position
			end = Vector(0,0,0), //Will be modified so that it ends at the target
			ignore = player,
			mask = 1174421507
		}

		//My proudest function name
		scope.findhBombCarrierToAimbotAtIfWeShould <- function() {
			hBombCarrierToAimbotAt = null
			local hCurrentTarget = null
			local flClosestTargetDistanceToHatch = 1000000
			while(hCurrentTarget = Entities.FindByClassname(hCurrentTarget, "player")) {
				if(!(hCurrentTarget.HasItem())) continue

				//Target is ubercharged = don't bother
				if(hCurrentTarget.InCond(5)) continue
				if(hCurrentTarget.InCond(51)) continue

				//No los to bomb carrier = don't bother
				losTrace.end = hCurrentTarget.EyePosition()

				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentTarget) continue

				local vTargetToHatchOriginDifference = hCurrentTarget.GetOrigin() - vHatchOrigin_TB
				local flTargetDistanceToHatch = vTargetToHatchOriginDifference.Length()

				//Target is DANGEROUSLY CLOSE to hatch, abandon everything and just shoot it
				if(flTargetDistanceToHatch < 300 && flTargetDistanceToHatch < flClosestTargetDistanceToHatch) {
					hBombCarrierToAimbotAt = hCurrentTarget
					flClosestTargetDistanceToHatch = flTargetDistanceToHatch
				}

				local vTargetToSelfOriginDifference = hCurrentTarget.GetOrigin() - self.GetOrigin()
				local flTargetDistanceToSelf = vTargetToSelfOriginDifference.Length()

				//Only lock on if the bomb carrier is somewhat close to us
				if(flTargetDistanceToSelf < 800 && flTargetDistanceToHatch < flClosestTargetDistanceToHatch) {
					hBombCarrierToAimbotAt = hCurrentTarget
					flClosestTargetDistanceToHatch = flTargetDistanceToHatch
				}
			}
		}

		scope.bombCamperHeavyThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}

			local selfOrigin = self.GetOrigin()

			//These don't need to change on every iteration
			losTrace.start = self.EyePosition()

			//Is there cash near us? Collect it
			for ( local currencyPackEntity; currencyPackEntity = Entities.FindByClassnameWithin( currencyPackEntity, "item_currencypack_*", selfOrigin, 50 ); ) {
				collectCash(currencyPackEntity, self)
			}

			//Where should we go?
			//Every 5 seconds, find the closest bomb to hatch, and sit there
			//On single bomb maps this doesn't do anything, but some maps have multiple bombs active at once
			
			if(Time() >= flNextRefreshBombTime) {
				flNextRefreshBombTime += 5

				// EntFire("tnGenerator_bombCamperHeavy_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_bombCamperHeavy_" + iBotId_TB, 0.0)

				hPreferredBomb = null
				local flClosestDistanceToHatch = 90000000.0
				local hCurrentBomb = null
				while(hCurrentBomb = Entities.FindByClassname(hCurrentBomb, "item_teamflag")) {
					
					local vDistanceToHatch = hCurrentBomb.GetOrigin() - vHatchOrigin_TB
					local flDistanceToHatch = vDistanceToHatch.Length()

					//Bomb is dormant in spawn = ignore unless all bombs are dormant
					//By treating them as impossibly far
					if(NetProps.GetPropInt(hCurrentBomb, "m_nFlagStatus") == 0) {
						flDistanceToHatch += 1024
						flDistanceToHatch *= 100
					}

					if(flDistanceToHatch < flClosestDistanceToHatch) {
						flClosestDistanceToHatch = flDistanceToHatch
						hPreferredBomb = hCurrentBomb
					}
				}

				//Emergency fallback
				if(hPreferredBomb == null) {
					hPreferredBomb = self
				}

				local vDistanceFromSelfToBomb = selfOrigin - hPreferredBomb.GetOrigin()
				if(vDistanceFromSelfToBomb.Length() <= 128) {
					self.PressFireButton(6)
				}
			}

			if(hPreferredBomb != null && hPreferredBomb.IsValid() && hBotActionPoint != null && hBotActionPoint.IsValid()) {
				vPreferredBombOrigin = hPreferredBomb.GetOrigin()
				hBotActionPoint.SetAbsOrigin(vPreferredBombOrigin)
			}
			
			//Who should we shoot at?
			//Figure out if we should aimbot a bomb carrier
			//If not, let the default expert ai decide what to shoot

			findhBombCarrierToAimbotAtIfWeShould()

			if(hBombCarrierToAimbotAt == null) return -1

			local posDiff = hBombCarrierToAimbotAt.GetCenter() - self.EyePosition()
			self.SnapEyeAngles(VectorAngles_TB(posDiff))
			self.PressFireButton(0.1)
			
			return -1
		}

		AddThinkToEnt(player, "bombCamperHeavyThink")
	}

	function add() {
		hTarget_bombCamperHeavy = SpawnEntityFromTable("bot_action_point"
		{
			stay_time = 99999
			targetname = "tnTarget_bombCamperHeavy_" + iBotId_TB
			command = "next_action_point"
			desired_distance = 64
			next_action_point = "tnTarget_bombCamperHeavy_" + iBotId_TB
			origin = Vector(0,0,0)
		})

		hGenerator_bombCamperHeavy = SpawnEntityFromTable("bot_generator"
		{
			team = "auto"
			origin = botGeneratorPivot
			maxActive = 1
			difficulty = 3
			disableDodge = 0
			interval = 1 // Irrelevant due to spawnOnlyWhenTriggered
			count = 1
			initial_command = "goto action point"
			action_point = "tnTarget_bombCamperHeavy_" + iBotId_TB
			spawnOnlyWhenTriggered = 1
			targetname = "tnGenerator_bombCamperHeavy_" + iBotId_TB
		})

		//Silly workaround to make our entities preserved through wave fails and mission switches
		hTarget_bombCamperHeavy.KeyValueFromString("classname", "entity_saucer")
		hGenerator_bombCamperHeavy.KeyValueFromString("classname", "entity_saucer")

		NetProps.SetPropString(hGenerator_bombCamperHeavy, "m_className", "heavyweapons")

		EntityOutputs.AddOutput(hGenerator_bombCamperHeavy, "OnSpawned", "!activator", "RunScriptCode", "botList_TB[" + iBotId_TB + "].initialize(self)", 0.0, -1)

		hGenerator_bombCamperHeavy.AcceptInput("SpawnBot", null, null, null)
	}
}


