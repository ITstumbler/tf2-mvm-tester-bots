# How to use
## Initializing
### Local server
Drop the tester_bots folder in tf/scripts/vscripts/
Load up an MvM map and type the following command in console:
```
script_execute tester_bots/tester_bots_init
```

### Potato testing server:
This script has been uploaded to potato testing servers
Load up an MvM map and type the following command in console:
```
sm_ent_fire bignet runscriptfile tester_bots/tester_bots_init.nut
```

## In-game chat commands

Use chat commands to add bots
```
!tb_addbot bombCamperHeavy
!tb_addbot bch
!tb_addbot grenadeDemo
!tb_addbot gd
!tb_addbot moneyScout
!tb_addbot ms
!tb_addbot tankBusterPyro
!tb_addbot tbp
!tb_addbot buffSoldier
!tb_addbot buS
!tb_addbot backupSoldier
!tb_addbot baS
!tb_addbot conchSoldier
!tb_addbot coS
```

Kick bots because someone joined
```
!tb_kickbot bombCamperHeavy
!tb_kickbot bch
```

Manually set tester bot money
```
!tb_money <amount>
!tb_money 6900
```
