::hGlobalThinker_TB <- SpawnEntityFromTable("logic_relay",
{
	targetname = "global_thinker_tb"
})

::hClosestBomb_TB <- Entities.FindByClassname(null, "item_teamflag")

//Silly workaround to make our entities preserved through wave fails and mission switches
hGlobalThinker_TB.KeyValueFromString("classname", "entity_saucer")

hGlobalThinker_TB.ValidateScriptScope()
local globalThinkerScope = hGlobalThinker_TB.GetScriptScope()

globalThinkerScope.flNextRefreshBombTime <- Time() + 0.03

globalThinkerScope.globalThinkFunction <- function() {
	if(Time() >= flNextRefreshBombTime) {
		flNextRefreshBombTime += 5

		// EntFire("tnGenerator_bombCamperHeavy_" + iBotId_TB, "CommandGoToActionPoint", "tnTarget_bombCamperHeavy_" + iBotId_TB, 0.0)

		hClosestBomb_TB = null
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
				hClosestBomb_TB = hCurrentBomb
			}
		}

		//Emergency fallback
		if(hClosestBomb_TB == null) {
			hClosestBomb_TB = self
		}
	}

	return -1
}

AddThinkToEnt(hGlobalThinker_TB, "globalThinkFunction")