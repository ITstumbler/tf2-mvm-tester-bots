::SLOT_BODY <- -2
::SLOT_PRIMARY <- 0
::SLOT_SECONDARY <- 1
::SLOT_MELEE <- 2

//Bomb camper heavy

//Upgrade priorities =
//3 crit resistance, if alwayscrit bots are present
//2 ticks of health-on-kill
//3 blast resistance, regardless of presence
//3 bullet resistance, regardless of presence
//4 firing speed
//2 ticks of health-on-kill
//3 fire resistance
//3 movement speed
//1 tick of projectile penetration
//2 destroy projectiles
//5 health regen
//2 ticks of projectile penetration

::bombCamperHeavyUpgradeTable <- {
	[1] = {
		name = "dmg taken from crit reduced",
		value = 0.7,
		cost = 150,
		slot = SLOT_BODY
	},
	[2] = {
		name = "dmg taken from crit reduced",
		value = 0.4,
		cost = 150,
		slot = SLOT_BODY
	},
	[3] = {
		name = "dmg taken from crit reduced",
		value = 0.1,
		cost = 150,
		slot = SLOT_BODY
	},
	[4] = {
		name = "heal on kill",
		value = 25,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[5] = {
		name = "heal on kill",
		value = 50,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[6] = {
		name = "dmg taken from blast reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[7] = {
		name = "dmg taken from blast reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[8] = {
		name = "dmg taken from blast reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[9] = {
		name = "dmg taken from bullets reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[10] = {
		name = "dmg taken from bullets reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[11] = {
		name = "dmg taken from bullets reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[12] = {
		name = "fire rate bonus",
		value = 0.9,
		cost = 350,
		slot = SLOT_PRIMARY
	},
	[13] = {
		name = "fire rate bonus",
		value = 0.8,
		cost = 350,
		slot = SLOT_PRIMARY
	},
	[14] = {
		name = "fire rate bonus",
		value = 0.7,
		cost = 350,
		slot = SLOT_PRIMARY
	},
	[15] = {
		name = "fire rate bonus",
		value = 0.6,
		cost = 350,
		slot = SLOT_PRIMARY
	},
	[16] = {
		name = "heal on kill",
		value = 25,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[17] = {
		name = "heal on kill",
		value = 50,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[18] = {
		name = "dmg taken from fire reduced",
		value = 0.75,
		cost = 150,
		slot = SLOT_BODY
	},
	[19] = {
		name = "dmg taken from fire reduced",
		value = 0.5,
		cost = 150,
		slot = SLOT_BODY
	},
	[20] = {
		name = "dmg taken from fire reduced",
		value = 0.25,
		cost = 150,
		slot = SLOT_BODY
	},
	[21] = {
		name = "move speed bonus",
		value = 1.1,
		cost = 200,
		slot = SLOT_BODY
	},
	[22] = {
		name = "move speed bonus",
		value = 1.2,
		cost = 200,
		slot = SLOT_BODY
	},
	[23] = {
		name = "move speed bonus",
		value = 1.3,
		cost = 200,
		slot = SLOT_BODY
	},
	[24] = {
		name = "projectile penetration heavy",
		value = 1,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[25] = {
		name = "attack projectiles",
		value = 1,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[26] = {
		name = "attack projectiles",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[27] = {
		name = "health regen",
		value = 2,
		cost = 200,
		slot = SLOT_BODY
	},
	[28] = {
		name = "health regen",
		value = 4,
		cost = 200,
		slot = SLOT_BODY
	},
	[29] = {
		name = "health regen",
		value = 6,
		cost = 200,
		slot = SLOT_BODY
	},
	[30] = {
		name = "health regen",
		value = 8,
		cost = 200,
		slot = SLOT_BODY
	},
	[31] = {
		name = "health regen",
		value = 10,
		cost = 200,
		slot = SLOT_BODY
	},
	[32] = {
		name = "projectile penetration heavy",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[33] = {
		name = "projectile penetration heavy",
		value = 3,
		cost = 400,
		slot = SLOT_PRIMARY
	}
}

//Grenade Demo

//Upgrade priorities =
//3 Reload speed
//1 Damage
//4 Firing speed
//3 Damage
//3 crit resistance, if alwayscrit bots are present
//4 Clip size
//2 HoK
//3 blast resistance, regardless of presence
//3 bullet resistance, regardless of presence
//3 move speed
//3 fire resistance, regardless of presence
//2 HoK
//3 push force
//5 health regen
//3 jump height

::grenadeDemoUpgradeTable <- {
	[1] = {
		name = "faster reload rate",
		value = 0.8,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[2] = {
		name = "faster reload rate",
		value = 0.6,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[3] = {
		name = "faster reload rate",
		value = 0.4,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[4] = {
		name = "damage bonus",
		value = 1.2,
		cost = 500,
		slot = SLOT_PRIMARY
	},
	[5] = {
		name = "fire rate bonus",
		value = 0.9,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[6] = {
		name = "fire rate bonus",
		value = 0.8,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[7] = {
		name = "fire rate bonus",
		value = 0.7,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[8] = {
		name = "fire rate bonus",
		value = 0.6,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[9] = {
		name = "damage bonus",
		value = 1.4,
		cost = 500,
		slot = SLOT_PRIMARY
	},
	[10] = {
		name = "damage bonus",
		value = 1.6,
		cost = 500,
		slot = SLOT_PRIMARY
	},
	[11] = {
		name = "damage bonus",
		value = 1.8,
		cost = 500,
		slot = SLOT_PRIMARY
	},
	[12] = {
		name = "dmg taken from crit reduced",
		value = 0.7,
		cost = 150,
		slot = SLOT_BODY
	},
	[13] = {
		name = "dmg taken from crit reduced",
		value = 0.4,
		cost = 150,
		slot = SLOT_BODY
	},
	[14] = {
		name = "dmg taken from crit reduced",
		value = 0.1,
		cost = 150,
		slot = SLOT_BODY
	},
	[15] = {
		name = "clip size upgrade atomic",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[16] = {
		name = "clip size upgrade atomic",
		value = 4,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[17] = {
		name = "clip size upgrade atomic",
		value = 6,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[18] = {
		name = "clip size upgrade atomic",
		value = 8,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[19] = {
		name = "health on kill",
		value = 25,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[20] = {
		name = "health on kill",
		value = 50,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[21] = {
		name = "dmg taken from blast reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[22] = {
		name = "dmg taken from blast reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[23] = {
		name = "dmg taken from blast reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[24] = {
		name = "dmg taken from bullets reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[25] = {
		name = "dmg taken from bullets reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[26] = {
		name = "dmg taken from bullets reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[27] = {
		name = "move speed bonus",
		value = 1.1,
		cost = 200,
		slot = SLOT_BODY
	},
	[28] = {
		name = "move speed bonus",
		value = 1.2,
		cost = 200,
		slot = SLOT_BODY
	},
	[29] = {
		name = "move speed bonus",
		value = 1.3,
		cost = 200,
		slot = SLOT_BODY
	},
	[30] = {
		name = "dmg taken from fire reduced",
		value = 0.75,
		cost = 150,
		slot = SLOT_BODY
	},
	[31] = {
		name = "dmg taken from fire reduced",
		value = 0.5,
		cost = 150,
		slot = SLOT_BODY
	},
	[32] = {
		name = "dmg taken from fire reduced",
		value = 0.25,
		cost = 150,
		slot = SLOT_BODY
	},
	[33] = {
		name = "health on kill",
		value = 75,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[34] = {
		name = "health on kill",
		value = 100,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[35] = { //Shield or body, same thing
		name = "damage force reduction",
		value = 0.7,
		cost = 100,
		slot = SLOT_BODY
	},
	[36] = {
		name = "damage force reduction",
		value = 0.4,
		cost = 100,
		slot = SLOT_BODY
	},
	[37] = {
		name = "damage force reduction",
		value = 0.1,
		cost = 100,
		slot = SLOT_BODY
	},
	[38] = {
		name = "health regen",
		value = 2,
		cost = 200,
		slot = SLOT_BODY
	},
	[39] = {
		name = "health regen",
		value = 4,
		cost = 200,
		slot = SLOT_BODY
	},
	[40] = {
		name = "health regen",
		value = 6,
		cost = 200,
		slot = SLOT_BODY
	},
	[41] = {
		name = "health regen",
		value = 8,
		cost = 200,
		slot = SLOT_BODY
	},
	[42] = {
		name = "health regen",
		value = 10,
		cost = 200,
		slot = SLOT_BODY
	},
	[43] = {
		name = "increased jump height",
		value = 1.2,
		cost = 100,
		slot = SLOT_BODY
	},
	[44] = {
		name = "increased jump height",
		value = 1.4,
		cost = 100,
		slot = SLOT_BODY
	},
	[45] = {
		name = "increased jump height",
		value = 1.6,
		cost = 100,
		slot = SLOT_BODY
	}
}

//Money Scout

//Upgrade priorities =
//Mad milk slow
//3 crit resist, if alwayscrit bots are present
//Alternate between jump height and movement speed until maxed
//3 bullet resist, regardless of presence
//3 fire resist, regardless of presence
//3 blast resist, regardless of presence
//4 Mad milk recharge
//1 Clip size
//4 Damage
//3 Clip size
//1 Projectile penetration
//4 Health-on-kill
//5 Health regen

::moneyScoutUpgradeTable <- {
	[1] = {
		name = "applies snare effect",
		value = 0.65,
		cost = 200,
		slot = SLOT_SECONDARY
	},
	[2] = {
		name = "dmg taken from crit reduced",
		value = 0.7,
		cost = 150,
		slot = SLOT_BODY
	},
	[3] = {
		name = "dmg taken from crit reduced",
		value = 0.4,
		cost = 150,
		slot = SLOT_BODY
	},
	[4] = {
		name = "dmg taken from crit reduced",
		value = 0.1,
		cost = 150,
		slot = SLOT_BODY
	},
	[5] = {
		name = "increased jump height",
		value = 1.2,
		cost = 100,
		slot = SLOT_BODY
	},
	[6] = {
		name = "move speed bonus",
		value = 1.1,
		cost = 200,
		slot = SLOT_BODY
	},
	[7] = {
		name = "increased jump height",
		value = 1.4,
		cost = 100,
		slot = SLOT_BODY
	},
	[8] = {
		name = "move speed bonus",
		value = 1.2,
		cost = 200,
		slot = SLOT_BODY
	},
	[9] = {
		name = "increased jump height",
		value = 1.6,
		cost = 100,
		slot = SLOT_BODY
	},
	[10] = {
		name = "move speed bonus",
		value = 1.3,
		cost = 200,
		slot = SLOT_BODY
	},
	[11] = {
		name = "dmg taken from bullets reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[12] = {
		name = "dmg taken from bullets reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[13] = {
		name = "dmg taken from bullets reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[14] = {
		name = "dmg taken from fire reduced",
		value = 0.75,
		cost = 150,
		slot = SLOT_BODY
	},
	[15] = {
		name = "dmg taken from fire reduced",
		value = 0.5,
		cost = 150,
		slot = SLOT_BODY
	},
	[16] = {
		name = "dmg taken from fire reduced",
		value = 0.25,
		cost = 150,
		slot = SLOT_BODY
	},
	[17] = {
		name = "dmg taken from blast reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[18] = {
		name = "dmg taken from blast reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[19] = {
		name = "dmg taken from blast reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[20] = { //Bot mad milk doesn't go on recharge so we have to figure it out ourselves anyways kek?
		name = "effect bar recharge rate increased",
		value = 0.85,
		cost = 250,
		slot = SLOT_SECONDARY
	},
	[21] = {
		name = "effect bar recharge rate increased",
		value = 0.7,
		cost = 250,
		slot = SLOT_SECONDARY
	},
	[22] = {
		name = "effect bar recharge rate increased",
		value = 0.55,
		cost = 250,
		slot = SLOT_SECONDARY
	},
	[23] = {
		name = "effect bar recharge rate increased",
		value = 0.4,
		cost = 250,
		slot = SLOT_SECONDARY
	},
	[24] = {
		name = "clip size bonus upgrade",
		value = 1.5,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[25] = {
		name = "damage bonus",
		value = 1.25,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[26] = {
		name = "damage bonus",
		value = 1.5,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[27] = {
		name = "damage bonus",
		value = 1.75,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[28] = {
		name = "damage bonus",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[29] = {
		name = "clip size bonus upgrade",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[30] = {
		name = "clip size bonus upgrade",
		value = 2.5,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[31] = {
		name = "clip size bonus upgrade",
		value = 3,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[32] = {
		name = "projectile penetration",
		value = 1,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[33] = {
		name = "heal on kill",
		value = 25,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[34] = {
		name = "heal on kill",
		value = 50,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[35] = {
		name = "heal on kill",
		value = 75,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[36] = {
		name = "heal on kill",
		value = 100,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[37] = {
		name = "health regen",
		value = 2,
		cost = 200,
		slot = SLOT_BODY
	},
	[38] = {
		name = "health regen",
		value = 4,
		cost = 200,
		slot = SLOT_BODY
	},
	[39] = {
		name = "health regen",
		value = 6,
		cost = 200,
		slot = SLOT_BODY
	},
	[40] = {
		name = "health regen",
		value = 8,
		cost = 200,
		slot = SLOT_BODY
	},
	[41] = {
		name = "health regen",
		value = 10,
		cost = 200,
		slot = SLOT_BODY
	}
}

//Banner Soldier

//Upgrade priorities =
//1 Rocket Specialist
//3 Reload
//1 Health-on-kill
//2 Damage
//2 Buff Duration
//3 Crit resistance, if alwayscrit bots are present
//4 Firing speed
//2 Damage
//2 Clip size
//3 Blast resistance, regardless of presence
//3 Bullet resistance, regardless of presence
//3 Move speed
//3 Rocket specialist
//2 Clip size
//3 Fire resistance, regardless of presence
//3 Health-on-kill
//5 Health regen

::bannerSoldierUpgradeTable <- {
	[1] = {
		name = "rocket specialist",
		value = 1,
		cost = 300,
		slot = SLOT_PRIMARY
	},
	[2] = {
		name = "faster reload rate",
		value = 0.8,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[3] = {
		name = "faster reload rate",
		value = 0.6,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[4] = {
		name = "faster reload rate",
		value = 0.4,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[5] = {
		name = "heal on kill",
		value = 25,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[6] = {
		name = "damage bonus",
		value = 1.25,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[7] = {
		name = "damage bonus",
		value = 1.5,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[8] = {
		name = "increase buff duration",
		value = 1.25,
		cost = 250,
		slot = SLOT_SECONDARY
	},
	[9] = {
		name = "increase buff duration",
		value = 1.5,
		cost = 250,
		slot = SLOT_SECONDARY
	},
	[10] = {
		name = "dmg taken from crit reduced",
		value = 0.7,
		cost = 150,
		slot = SLOT_BODY
	},
	[11] = {
		name = "dmg taken from crit reduced",
		value = 0.4,
		cost = 150,
		slot = SLOT_BODY
	},
	[12] = {
		name = "dmg taken from crit reduced",
		value = 0.1,
		cost = 150,
		slot = SLOT_BODY
	},
	[13] = {
		name = "fire rate bonus",
		value = 0.9,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[14] = {
		name = "fire rate bonus",
		value = 0.8,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[15] = {
		name = "fire rate bonus",
		value = 0.7,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[16] = {
		name = "fire rate bonus",
		value = 0.6,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[17] = {
		name = "damage bonus",
		value = 1.75,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[18] = {
		name = "damage bonus",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[19] = {
		name = "clip size upgrade atomic",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[20] = {
		name = "clip size upgrade atomic",
		value = 4,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[21] = {
		name = "dmg taken from blast reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[22] = {
		name = "dmg taken from blast reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[23] = {
		name = "dmg taken from blast reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[24] = {
		name = "dmg taken from bullets reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[25] = {
		name = "dmg taken from bullets reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[26] = {
		name = "dmg taken from bullets reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[27] = {
		name = "move speed bonus",
		value = 1.1,
		cost = 200,
		slot = SLOT_BODY
	},
	[28] = {
		name = "move speed bonus",
		value = 1.2,
		cost = 200,
		slot = SLOT_BODY
	},
	[29] = {
		name = "move speed bonus",
		value = 1.3,
		cost = 200,
		slot = SLOT_BODY
	},
	[30] = {
		name = "rocket specialist",
		value = 2,
		cost = 300,
		slot = SLOT_PRIMARY
	},
	[31] = {
		name = "rocket specialist",
		value = 3,
		cost = 300,
		slot = SLOT_PRIMARY
	},
	[32] = {
		name = "rocket specialist",
		value = 4,
		cost = 300,
		slot = SLOT_PRIMARY
	},
	[33] = {
		name = "clip size upgrade atomic",
		value = 6,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[34] = {
		name = "clip size upgrade atomic",
		value = 8,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[35] = {
		name = "dmg taken from fire reduced",
		value = 0.75,
		cost = 150,
		slot = SLOT_BODY
	},
	[36] = {
		name = "dmg taken from fire reduced",
		value = 0.5,
		cost = 150,
		slot = SLOT_BODY
	},
	[37] = {
		name = "dmg taken from fire reduced",
		value = 0.25,
		cost = 150,
		slot = SLOT_BODY
	},
	[38] = {
		name = "heal on kill",
		value = 50,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[39] = {
		name = "heal on kill",
		value = 75,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[40] = {
		name = "heal on kill",
		value = 100,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[41] = {
		name = "health regen",
		value = 2,
		cost = 200,
		slot = SLOT_BODY
	},
	[42] = {
		name = "health regen",
		value = 4,
		cost = 200,
		slot = SLOT_BODY
	},
	[43] = {
		name = "health regen",
		value = 6,
		cost = 200,
		slot = SLOT_BODY
	},
	[44] = {
		name = "health regen",
		value = 8,
		cost = 200,
		slot = SLOT_BODY
	},
	[45] = {
		name = "health regen",
		value = 10,
		cost = 200,
		slot = SLOT_BODY
	}
}

//Tank buster pyro

//Upgrade priorities =
//3 crit resistance, if alwayscrit bots are present
//1 damage
//2 health-on-kill
//3 damage
//3 fire resistance, regardless of presence
//3 blast resistance, regardless of presence
//3 bullet resistance, regardless of presence
//2 ticks of health-on-kill
//3 movement speed
//5 health regen
//3 jump height
//4 burn damage
//4 burn time

//If you come tell me that pyro shouldn't buy fire res before blast res I will beat you up

::tankBusterPyroUpgradeTable <- {
	[1] = {
		name = "dmg taken from crit reduced",
		value = 0.7,
		cost = 150,
		slot = SLOT_BODY
	},
	[2] = {
		name = "dmg taken from crit reduced",
		value = 0.4,
		cost = 150,
		slot = SLOT_BODY
	},
	[3] = {
		name = "dmg taken from crit reduced",
		value = 0.1,
		cost = 150,
		slot = SLOT_BODY
	},
	[4] = {
		name = "damage bonus",
		value = 1.25,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[5] = {
		name = "heal on kill",
		value = 25,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[6] = {
		name = "heal on kill",
		value = 50,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[7] = {
		name = "damage bonus",
		value = 1.5,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[8] = {
		name = "damage bonus",
		value = 1.75,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[9] = {
		name = "damage bonus",
		value = 2,
		cost = 400,
		slot = SLOT_PRIMARY
	},
	[10] = {
		name = "dmg taken from fire reduced",
		value = 0.75,
		cost = 150,
		slot = SLOT_BODY
	},
	[11] = {
		name = "dmg taken from fire reduced",
		value = 0.5,
		cost = 150,
		slot = SLOT_BODY
	},
	[12] = {
		name = "dmg taken from fire reduced",
		value = 0.25,
		cost = 150,
		slot = SLOT_BODY
	},
	[13] = {
		name = "dmg taken from blast reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[14] = {
		name = "dmg taken from blast reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[15] = {
		name = "dmg taken from blast reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[16] = {
		name = "dmg taken from bullets reduced",
		value = 0.75,
		cost = 300,
		slot = SLOT_BODY
	},
	[17] = {
		name = "dmg taken from bullets reduced",
		value = 0.5,
		cost = 300,
		slot = SLOT_BODY
	},
	[18] = {
		name = "dmg taken from bullets reduced",
		value = 0.25,
		cost = 300,
		slot = SLOT_BODY
	},
	[19] = {
		name = "heal on kill",
		value = 75,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[20] = {
		name = "heal on kill",
		value = 100,
		cost = 200,
		slot = SLOT_PRIMARY
	},
	[21] = {
		name = "move speed bonus",
		value = 1.1,
		cost = 200,
		slot = SLOT_BODY
	},
	[22] = {
		name = "move speed bonus",
		value = 1.2,
		cost = 200,
		slot = SLOT_BODY
	},
	[23] = {
		name = "move speed bonus",
		value = 1.3,
		cost = 200,
		slot = SLOT_BODY
	},
	[24] = {
		name = "health regen",
		value = 2,
		cost = 200,
		slot = SLOT_BODY
	},
	[25] = {
		name = "health regen",
		value = 4,
		cost = 200,
		slot = SLOT_BODY
	},
	[26] = {
		name = "health regen",
		value = 6,
		cost = 200,
		slot = SLOT_BODY
	},
	[27] = {
		name = "health regen",
		value = 8,
		cost = 200,
		slot = SLOT_BODY
	},
	[28] = {
		name = "health regen",
		value = 10,
		cost = 200,
		slot = SLOT_BODY
	},
	[29] = {
		name = "increased jump height",
		value = 1.2,
		cost = 100,
		slot = SLOT_BODY
	},
	[30] = {
		name = "increased jump height",
		value = 1.4,
		cost = 100,
		slot = SLOT_BODY
	},
	[31] = {
		name = "increased jump height",
		value = 1.6,
		cost = 100,
		slot = SLOT_BODY
	},
	[32] = {
		name = "weapon burn dmg increased",
		value = 1.25,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[33] = {
		name = "weapon burn dmg increased",
		value = 1.5,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[34] = {
		name = "weapon burn dmg increased",
		value = 1.75,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[35] = {
		name = "weapon burn dmg increased",
		value = 2,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[36] = { //Does this uh even do anything?
		name = "weapon burn time increased",
		value = 1.25,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[37] = {
		name = "weapon burn time increased",
		value = 1.5,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[38] = {
		name = "weapon burn time increased",
		value = 1.75,
		cost = 250,
		slot = SLOT_PRIMARY
	},
	[39] = {
		name = "weapon burn time increased",
		value = 2,
		cost = 250,
		slot = SLOT_PRIMARY
	}
}