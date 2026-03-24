//Bomb Camper Heavy
//Every 5 seconds, this bot will pick the closest enabled bomb to hatch
//He will then walk towards the bomb and stand there until it dies or the bomb moves
//Always revs up on top of the bomb
//Never switches to other weapons

//BOTS MAY INHERIT MVM ROBOT TRAITS, MODELS ETC. REMOVE ALL OF THEM.

class bombCamperHeavy {

	hTarget = null
	hGenerator = null
	iBotId_TB = null
	sBotType = null
	hPlayerEnt = null

	constructor(pBotId) {
		iBotId_TB = pBotId
		sBotType = "bombCamperHeavy"
	}

	function initialize(player) {

		hPlayerEnt = player

		local scope = player.GetScriptScope()

		//How did we activate on a non-red bot? Don't initialize.
		if(hPlayerEnt.GetTeam() != 2) return

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

		printChatMessage_TB("\x01Bomb Camper (BOT) spawned with \x0722CC22" + iGlobalMoney_TB + " \x01credits", 2)

		//Bots may inherit icons from blue robots, make sure they don't
		NetProps.SetPropString(player, "m_PlayerClass.m_iszClassIcon", "tester_bot")

		//Bots don't go for ammo packs, just make them have infinite ammo
		player.AddCustomAttribute("ammo regen", 1, -1)

		scope.iBotId_TB <- iBotId_TB
		scope.botType_TB <- "bombCamperHeavy"

		EntFire("tnGenerator_bombCamperHeavy_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_bombCamperHeavy_" + iBotId_TB, 0.0)

		////////////////////////
		//Think function below
		////////////////////////

		scope.vPreferredBombOrigin <- Vector(0,0,0)
		scope.hBombCarrierToAimbotAt <- null
		scope.hMinigun <- getWeaponInSlot_TB(player, 0)
		scope.hSandvich <- GivePlayerWeapon_TB(player, "tf_weapon_lunchbox", 42)
		scope.flPreviousSandvichEatTime <- 0
		scope.bShouldEatSandvich <- false

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

				//Something something clean code
				//Evaluating sandvich safety also requires us to iterate through every blu player, so might as well do it here
				evaluateSandvichSafety(hCurrentTarget)

				local iCurrentTargetClass = hCurrentTarget.GetPlayerClass()
				if(!(hCurrentTarget.HasItem()) && iCurrentTargetClass != TF_CLASS_MEDIC) continue

				//Target is a bomb carrier being healed by a medic. Ignore, shoot the medic.
				if(hCurrentTarget.HasItem() && hCurrentTarget.InCond(TF_COND_HEALTH_BUFF)) continue

				//Target is ubercharged or bonked = don't bother
				if(hCurrentTarget.InCond(5)) continue
				if(hCurrentTarget.InCond(51)) continue
				if(hCurrentTarget.InCond(52)) continue
				if(hCurrentTarget.InCond(14)) continue

				//Target isn't a medicbot healing the bomb carrier, don't bother
				if(!hCurrentTarget.HasItem() && iCurrentTargetClass == TF_CLASS_MEDIC) {
					local hCurrentTargetHealTarget = hCurrentTarget.GetHealTarget()
					if(hCurrentTargetHealTarget == null || !(hCurrentTargetHealTarget.HasItem())) continue
				}
				
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

		//If there are no nearby threats, rest and eat a sandvich
		scope.evaluateSandvichSafety <- function(hEnemy) {
			//Not alive, not blue, don't consider
			if(hEnemy.GetTeam() != 3) return
			if(NetProps.GetPropInt(hEnemy, "m_lifeState") != 0) return

			local vTargetToSelfOriginDifference = hEnemy.GetOrigin() - self.GetOrigin()
			local flTargetDistanceToSelf = vTargetToSelfOriginDifference.Length()

			if(flTargetDistanceToSelf < 900) bShouldEatSandvich = false
		}

		scope.eatSandvich <- function() {
			self.Weapon_Switch(hSandvich)
			self.AddCustomAttribute("disable weapon switch", 1.0, 2.5)
			self.PressFireButton(2)
			self.AddBotAttribute(SUPPRESS_FIRE) //The bot will hold m1 if we dont slap this
			EntFireByHandle(self, "RunScriptCode", "self.RemoveBotAttribute(SUPPRESS_FIRE)", 2.5, self, self)
			flPreviousSandvichEatTime = Time()
			ClientPrint(null, 3, "Trying to eat...")
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

			//This is handled by the function below
			bShouldEatSandvich = true
			
			//Who should we shoot at?
			//Figure out if we should aimbot a bomb carrier
			//If not, let the default expert ai decide what to shoot

			findhBombCarrierToAimbotAtIfWeShould()

			//Ok actually i cba implement this for now later though
			//Don't upgrade sandvich. So the recharge is fixed at 30s
			// if(bShouldEatSandvich && self.GetHealth() <= 200 && Time() - flPreviousSandvichEatTime > 32) {
				//We need 1.6s to spin down and eat sandvich
				
				// EntFireByHandle(self, "RunScriptCode", "self.GetScriptScope().eatSandvich()", 2, self, self)
			// }

			//Where should we go?
			//Refer to global_think.nut on how we find the closest bomb
			
			if(hClosestBomb_TB != null && hClosestBomb_TB.IsValid() && hBotActionPoint != null && hBotActionPoint.IsValid()) {

				local vDistanceFromSelfToBomb = selfOrigin - hClosestBomb_TB.GetOrigin()
				if(vDistanceFromSelfToBomb.Length() <= 128 && !bShouldEatSandvich) {
					self.PressFireButton(0.15)
				}

				vPreferredBombOrigin = hClosestBomb_TB.GetOrigin()
				hBotActionPoint.SetAbsOrigin(vPreferredBombOrigin)
			}

			if(hBombCarrierToAimbotAt == null) return -1

			local posDiff = hBombCarrierToAimbotAt.GetCenter() - self.EyePosition()
			self.SnapEyeAngles(VectorAngles_TB(posDiff))
			self.PressFireButton(0.1)
			
			return -1
		}

		AddThinkToEnt(player, "bombCamperHeavyThink")
	}

	function add() {
		hTarget = SpawnEntityFromTable("bot_action_point",
		{
			stay_time = 99999
			targetname = "tnTarget_bombCamperHeavy_" + iBotId_TB
			command = "next_action_point"
			desired_distance = 64
			next_action_point = "tnTarget_bombCamperHeavy_" + iBotId_TB
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
			action_point = "tnTarget_bombCamperHeavy_" + iBotId_TB
			spawnOnlyWhenTriggered = 1
			targetname = "tnGenerator_bombCamperHeavy_" + iBotId_TB
		})

		//Silly workaround to make our entities preserved through wave fails and mission switches
		hTarget.KeyValueFromString("classname", "entity_saucer")
		hGenerator.KeyValueFromString("classname", "entity_saucer")

		NetProps.SetPropString(hGenerator, "m_className", "heavyweapons")

		EntityOutputs.AddOutput(hGenerator, "OnSpawned", "!activator", "RunScriptCode", "botList_TB[" + iBotId_TB + "].initialize(self)", 0.0, -1)

		hGenerator.AcceptInput("SpawnBot", null, null, null)
	}
}


