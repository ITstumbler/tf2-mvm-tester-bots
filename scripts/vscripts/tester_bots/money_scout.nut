//Money Scout
//Every tick, search for the closest currency pack and run to it
//Mashes spacebar while shooting
//Uses milk whenever off recharge, prioritizes giants and certain classes
//Uses soda popper and always tries to activate hype
//Prioritizes milk slow, resistances, mobility

//BOTS MAY INHERIT MVM ROBOT TRAITS, MODELS ETC. REMOVE ALL OF THEM.

class moneyScout {

	hTarget = null
	hGenerator = null
	iBotId_TB = null
	sBotType = null
	hPlayerEnt = null

	constructor(pBotId) {
		iBotId_TB = pBotId
		sBotType = "moneyScout"
	}

	function initialize(player) {

		hPlayerEnt = player

		//How did we activate on a non-red bot? Don't initialize.
		if(hPlayerEnt.GetTeam() != 2) return

		SetFakeClientConVarValue(player, "name", "Money Scout (BOT)")
		setBotReady_TB(player.GetEntityIndex())

		cleanInheritances_TB(player)
		player.SetMaxHealth(125)

		player.AddWeaponRestriction(2) //Primary only. Switch to mad milk through weapon_switch

		//First init = find out what starting currency is
		//Setting team to "auto" makes bots spawn with proper money, but only works on first spawn
		if(iGlobalMoney_TB == -1) {
			iGlobalMoney_TB = player.GetCurrency()
		}

		printChatMessage_TB("\x01Money Scout (BOT) spawned with \x0722CC22" + iGlobalMoney_TB + " \x01credits", 2)

		//Bots may inherit icons from blue robots, make sure they don't
		NetProps.SetPropString(player, "m_PlayerClass.m_iszClassIcon", "tester_bot")

		//Bots don't go for ammo packs, just make them have infinite ammo
		player.AddCustomAttribute("ammo regen", 1, -1)

		local scope = player.GetScriptScope()

		scope.iBotId_TB <- iBotId_TB
		scope.botType_TB <- "moneyScout"

		EntFire("tnGenerator_moneyScout_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_moneyScout_" + iBotId_TB, 0.0)

		////////////////////////
		//Think function below
		////////////////////////

		scope.flNextJumpTime <- Time() + 0.03
		scope.hPreferredMoney <- null //hPreferredCurrencyPack is a mouthful ok
		scope.hPreferredMilkTarget <- null
		scope.hSodaPopper <- GivePlayerWeapon_TB(player, "tf_weapon_soda_popper", 448) //GenerateAndWearItem don't work for both of these items for some reasons. FaN works just fine??
		scope.hMadMilk <- GivePlayerWeapon_TB(player, "tf_weapon_jar_milk", 222)
		scope.iMilkPhase <- 0 //Dumb ass mad milk m1 holding forces this to be split to phases. 0 = Milk ready, not out
		scope.flResetMilkPhaseTime <- 0 //The time to set iMilkPhase back to 0

		scope.hBotActionPoint <- Entities.FindByName(null, "tnTarget_moneyScout_" + iBotId_TB)

		upgradeBot_TB(player, moneyScoutUpgradeTable, iGlobalMoney_TB)

		killstreakify_TB(player)

		// EntFireByHandle(player, "RunScriptCode", "self.GetScriptScope().hMadMilk = getWeaponInSlot(self, 1)", 1, player, player)

		scope.losTrace <- {
			start = Vector(0,0,0), //Will be modified so that it starts at self's eye position
			end = Vector(0,0,0), //Will be modified so that it ends at the target
			ignore = player,
			mask = 1174421507
		}

		scope.getNearestMoney <- function() {
			hPreferredMoney = null
			local hCurrentMoney = null
			local flClosestMoneyDistance = 100000
			while(hCurrentMoney = Entities.FindByClassname(hCurrentMoney, "item_currencypack_*")) {
				if ( NetProps.GetPropBool( hCurrentMoney, "m_bDistributed" ) ) return

				local vMoneyOrigin = hCurrentMoney.GetOrigin()

				local vMoneyOriginDifference = vMoneyOrigin - self.GetOrigin()
				local flMoneyDistance = vMoneyOriginDifference.Length()

				//Red money = treat them as a lot further than green ones
				if(NetProps.GetPropBool( hCurrentMoney, "m_bDistributed" )) {
					flMoneyDistance += 32
					flMoneyDistance *= 8
				}

				if(flMoneyDistance < flClosestMoneyDistance) {
					flClosestMoneyDistance = flMoneyDistance
					hPreferredMoney = hCurrentMoney
				}
			}

			//No money on the ground? Go for the closest bomb to hatch
			if(hPreferredMoney == null) {
				hPreferredMoney = hClosestBomb_TB
			}
		}

		scope.getPreferredMilkTarget <- function() {
			hPreferredMilkTarget = null
			local hCurrentMilkTarget = null
			local flClosestDistanceToMilkTarget = 100000
			while(hCurrentMilkTarget = Entities.FindByClassname(hCurrentMilkTarget, "player")) {
				if(hCurrentMilkTarget.GetTeam() != 3) continue
				if(NetProps.GetPropInt(hCurrentMilkTarget, "m_lifeState") != 0) continue

				//Don't try to milk ubered or bonked targets
				if(hCurrentMilkTarget.InCond(5)) continue
				if(hCurrentMilkTarget.InCond(51)) continue
				if(hCurrentMilkTarget.InCond(14)) continue
				
				//Honestly just don't milk anything that's not at least minigiant
				if(hCurrentMilkTarget.GetMaxHealth() < 550) continue

				losTrace.end = hCurrentMilkTarget.EyePosition()

				TraceLineEx(losTrace)

				if(losTrace.hit == false) continue
				if(losTrace.enthit != hCurrentMilkTarget) continue

				local vMilkTargetOrigin = hCurrentMilkTarget.GetOrigin()

				local vMilkTargetOriginDifference = vMilkTargetOrigin - self.GetOrigin()
				local flMilkTargetDistance = vMilkTargetOriginDifference.Length()

				//Target is TOO FAR AWAY
				if(flMilkTargetDistance > 1024) continue

				local iCurrentMilkTargetClass = hCurrentMilkTarget.GetPlayerClass()

				//Giant scouts are top priority, we upgrade milk slow first for a reason
				if(iCurrentMilkTargetClass == TF_CLASS_SCOUT) {
					flMilkTargetDistance *= 0.1
				}

				//Giant heavies are second top priority
				//Third is equally split between other giant types, give or take
				//Don't try to convince me giant pyros are lower prio than giant soldiers
				if(iCurrentMilkTargetClass == TF_CLASS_HEAVYWEAPONS) {
					flMilkTargetDistance *= 0.35
				}

				//Not giant = less important, but milk if we're not seeing much else
				if(!(hCurrentMilkTarget.IsMiniBoss())) {
					flMilkTargetDistance += 1024
				}

				if(flMilkTargetDistance < flClosestDistanceToMilkTarget) {
					flClosestDistanceToMilkTarget = flMilkTargetDistance
					hPreferredMilkTarget = hCurrentMilkTarget
				}
			}
		}


		scope.moneyScoutThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			}

			losTrace.start = self.EyePosition()

			//Is there cash near us? Collect it
			//And because it's scout, the collection radius is 144
			//Also be sure to heal
			for ( local currencyPackEntity; currencyPackEntity = Entities.FindByClassnameWithin( currencyPackEntity, "item_currencypack_*", self.GetOrigin(), 288 ); ) {
				//Second param = heal player mentioned in param
				collectCash(currencyPackEntity, self)
			}

			//Just try to pop soda popper hype
			self.PressAltFireButton(0.1)

			getNearestMoney()

			if(hPreferredMoney != null && hPreferredMoney.IsValid() && hBotActionPoint != null && hBotActionPoint.IsValid()) {
				local vPreferredMoneyOrigin = hPreferredMoney.GetOrigin()
				hBotActionPoint.SetAbsOrigin(vPreferredMoneyOrigin)
			}

			//Mash spacebar, it gets results
			//Check if our clip is less than max to see if we are in danger or not
			if(Time() >= flNextJumpTime && hSodaPopper.IsValid()) {

				local iCurrentClip = hSodaPopper.Clip1()
				local iMaxClip = hSodaPopper.GetAttribute("clip size bonus upgrade", 1) * 2

				if(iCurrentClip < iMaxClip) {
					//Bots don't auto-reload so we have to force it to reload
					local buttons = NetProps.GetPropInt(self, "m_nButtons")
					NetProps.SetPropInt(self, "m_nButtons", buttons | IN_RELOAD)
					self.GetLocomotionInterface().Jump()

					//Depending on the amount of world money, decide how often we should be spamming jump

					local iWorldMoneyScout = NetProps.GetPropInt(hObjRes_TB, "m_nMvMWorldMoney")
					if(iWorldMoneyScout < 10) {
						flNextJumpTime = Time() + 0.75
					}
					else if(iWorldMoneyScout < 50) {
						flNextJumpTime = Time() + 1.5
					}
					else if(iWorldMoneyScout < 115) {
						flNextJumpTime = Time() + 2.5
					}
					else {
						flNextJumpTime = Time() + 3.5
					}
				}
			}

			getPreferredMilkTarget() //We need this function to decide whether or not we should be mashing spacebar xd

			if(hPreferredMilkTarget == null) return -1

			if(iMilkPhase == 2) {
				if(Time() >= flResetMilkPhaseTime) {
					printChatMessage_TB("Money scout milk recharged!", 3)
					iMilkPhase = 0
				}
				return -1
			}

			//Bot mad milk doesnt go on recharge after being thrown so we have to figure it out ourselves
			
			if(iMilkPhase == 0) {
				self.Weapon_Switch(hMadMilk)
				self.AddCustomAttribute("disable weapon switch", 1.0, 2.5)
				self.PressFireButton(2)
				self.AddBotAttribute(SUPPRESS_FIRE) //The bot will hold m1 if we dont slap this
				EntFireByHandle(self, "RunScriptCode", "self.RemoveBotAttribute(SUPPRESS_FIRE)", 2.5, self, self)
				EntFireByHandle(self, "RunScriptCode", "self.GetScriptScope().iMilkPhase = 2", 2.5, self, self)

				iMilkPhase = 1
			}
			
			//Lead the milk
			local selfEyePosition = self.EyePosition()
			local targetFeetPosition = hPreferredMilkTarget.GetOrigin()
			local posDiff = targetFeetPosition - selfEyePosition
			local finalPredictedPosDiff = posDiff

			//But only lead against gscouts!
			if(hPreferredMilkTarget.GetPlayerClass == TF_CLASS_SCOUT) {
				local milkTravelTimeToTargetCurrentPos = posDiff.Length() / 1019.9 
				local targetAbsVelocity = hPreferredMilkTarget.GetAbsVelocity()

				for(local i = 0; i < 5; i++) {
					local predictedTargetPos = targetFeetPosition + (targetAbsVelocity * milkTravelTimeToTargetCurrentPos)
					
					local predictedPosDiff = predictedTargetPos - selfEyePosition
					//Milk arcs down, let's aim up a bit
					predictedPosDiff.z += 300 * milkTravelTimeToTargetCurrentPos * milkTravelTimeToTargetCurrentPos

					milkTravelTimeToTargetCurrentPos = predictedPosDiff.Length() / 1019.9
				}

				local finalPredictedTargetPos = targetFeetPosition + (targetAbsVelocity * milkTravelTimeToTargetCurrentPos)
				finalPredictedPosDiff = finalPredictedTargetPos - selfEyePosition
				finalPredictedPosDiff.z += 300 * milkTravelTimeToTargetCurrentPos * milkTravelTimeToTargetCurrentPos
			}

			self.SnapEyeAngles(VectorAngles_TB(finalPredictedPosDiff))

			flResetMilkPhaseTime = Time() + (20 * hMadMilk.GetAttribute("effect bar recharge rate increased", 1)) - 2

			return -1
		}

		AddThinkToEnt(player, "moneyScoutThink")
	}

	function add() {
		hTarget = SpawnEntityFromTable("bot_action_point",
		{
			stay_time = 99999
			targetname = "tnTarget_moneyScout_" + iBotId_TB
			command = "next_action_point"
			desired_distance = 8
			next_action_point = "tnTarget_moneyScout_" + iBotId_TB
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
			action_point = "tnTarget_moneyScout_" + iBotId_TB
			spawnOnlyWhenTriggered = 1
			targetname = "tnGenerator_moneyScout_" + iBotId_TB
		})

		//Silly workaround to make our entities preserved through wave fails and mission switches
		hTarget.KeyValueFromString("classname", "entity_saucer")
		hGenerator.KeyValueFromString("classname", "entity_saucer")

		NetProps.SetPropString(hGenerator, "m_className", "scout")

		EntityOutputs.AddOutput(hGenerator, "OnSpawned", "!activator", "RunScriptCode", "botList_TB[" + iBotId_TB + "].initialize(self)", 0.0, -1)

		hGenerator.AcceptInput("SpawnBot", null, null, null)
	}
}


