function coopResetPoses()
{
   if(_root.arena.gladiators.overlay_villain != undefined)
   {
      _root.arena.gladiators.overlay_villain.gotoAndStop(1);
   }
   var pairs = [[_root.arena.gladiators.hero,_root.game.hero],[_root.arena.gladiators.hero2,_root.game.hero2],[_root.arena.gladiators.villain,_root.game.villain]];
   var pi = 0;
   while(pi < pairs.length)
   {
      var cl = pairs[pi][0];
      var gc = pairs[pi][1];
      if(cl != undefined && gc != undefined)
      {
         if(gc.hitpoints > 0)
         {
            cl.coopKO = false;
            if(cl._y > 200)
            {
               cl._y = 200;
            }
            if(gc.psyche_up == 2)
            {
               cl.gotoAndStop("psyche_charging");
            }
            else if(gc.psyche_up >= 3)
            {
               cl.gotoAndStop("psyche_charging2");
            }
            else
            {
               cl.gotoAndPlay("Standing");
            }
         }
      }
      pi++;
   }
}
function coopActiveHero()
{
   if(_global.coop.enabled == true && _global.coop.activeTurn == 2)
   {
      return _root.game.hero2;
   }
   return _root.game.hero;
}
function coopActiveClip()
{
   if(_global.coop.enabled == true && _global.coop.activeTurn == 2)
   {
      return _root.arena.gladiators.hero2;
   }
   return _root.arena.gladiators.hero;
}
function coopIsLocalOwner()
{
   if(_global.coop.enabled != true)
   {
      return true;
   }
   if(_global.coop.activeTurn == 1 && _global.coop.role == "host")
   {
      return true;
   }
   if(_global.coop.activeTurn == 2 && _global.coop.role == "client")
   {
      return true;
   }
   return false;
}
function coopClearWaitUI()
{
   if(this.coop_wait_clip != undefined)
   {
      this.coop_wait_clip.removeMovieClip();
      this.coop_wait_clip = null;
   }
   if(this.coop_auto_clip != undefined)
   {
      this.coop_auto_clip.removeMovieClip();
      this.coop_auto_clip = null;
   }
   delete this.onEnterFrame;
}
function coopShowWaitUI(msg)
{
   if(this.coop_wait_clip != undefined)
   {
      this.coop_wait_clip.removeMovieClip();
   }
   var wc = this.createEmptyMovieClip("coop_wait_clip",199990);
   wc._x = -95;
   wc._y = -75;
   wc.beginFill(1315860,85);
   wc.lineStyle(1,16766720,90);
   wc.moveTo(0,0);
   wc.lineTo(190,0);
   wc.lineTo(190,26);
   wc.lineTo(0,26);
   wc.lineTo(0,0);
   wc.endFill();
   wc.createTextField("txt",1,4,3,182,20);
   wc.txt.selectable = false;
   wc.txt.text = msg;
   var wFmt = new TextFormat("_sans",12,16766720,true,null,null,null,null,"center");
   wc.txt.setTextFormat(wFmt);
}
function coopSetMenuVisible(vis)
{
   optionA._visible = vis;
   optionB._visible = vis;
   optionC._visible = vis;
   optionD._visible = vis;
   optionE._visible = vis;
   optionF._visible = vis;
   optionG._visible = vis;
   optionH._visible = vis;
   swap_inventory._visible = vis;
   this.hero._visible = vis;
}
function getphase(whatsdoing)
{
   if(turnphase == 1)
   {
      if(_global.coop.enabled == true)
      {
         if(coopIsLocalOwner() && _global.coopSend != undefined)
         {
            var invId = coopLastInv != undefined && coopLastInv != null ? Number(coopLastInv) : 0;
            if(whatsdoing != "drink_potion" && whatsdoing.indexOf("cast_") != 0)
            {
               invId = 0;
            }
            _global.coopSend("act",{actor:_global.coop.activeTurn,action:whatsdoing,inv:invId,seed:_global.coop.seed});
            coopLastInv = 0;
         }
         coopClearWaitUI();
         decisionA = whatsdoing;
         turnphase = 2;
         _global.battle_action = 1;
         inventory_overlay.removeMovieClip();
         inv_struck = false;
         gotoAndStop("heroactions");
         play();
         return undefined;
      }
      decisionA = whatsdoing;
      turnphase = 2;
      _global.battle_action = 1;
      inventory_overlay.removeMovieClip();
      inv_struck = false;
      gotoAndStop("heroactions");
      play();
   }
}
function attack_chances(game_attacker, game_defender)
{
   game_attacker.power_percentage = Math.round((game_attacker.attack + 9) / (game_defender.defence + 9) * 100 * 0.33);
   game_attacker.normal_percentage = Math.round((game_attacker.attack + 9) / (game_defender.defence + 9) * 100 * 0.5);
   game_attacker.quick_percentage = Math.round((game_attacker.attack + 9) / (game_defender.defence + 9) * 100 * 0.66);
   game_attacker.bash_percentage = Math.round((game_attacker.attack + 9) / (game_defender.defence + 9) * 100 * 0.2);
   game_attacker.taunt_percentage = Math.round((game_attacker.charisma + 9) / (game_defender.charisma + 9) * 100 * 0.4);
   game_attacker.bombard_percentage = Math.round((game_attacker.attack + 9) / (game_defender.defence + 9) * 100 * 0.6);
   game_attacker.bombard_percentage_bonus = get_percentage(100 + game_attacker.shield * 1.5,100);
   game_attacker.bombard_percentage = add_percentage(game_attacker.bombard_percentage,game_attacker.bombard_percentage_bonus);
   game_attacker.snipe_percentage = Math.round((game_attacker.attack + 9) / (game_defender.defence + 9) * 100 * 0.9);
   game_attacker.snipe_percentage_bonus = get_percentage(100 + game_attacker.shield * 1.5,100);
   game_attacker.snipe_percentage = add_percentage(game_attacker.snipe_percentage,game_attacker.snipe_percentage_bonus);
   game_attacker.magicka_percentage = Math.round((game_attacker.magicka + 9) / (game_defender.magicka + 9) * 100 * 0.5);
   if(game_attacker.power_percentage < 1)
   {
      game_attacker.power_percentage = 1;
   }
   if(game_attacker.normal_percentage < 1)
   {
      game_attacker.normal_percentage = 1;
   }
   if(game_attacker.quick_percentage < 1)
   {
      game_attacker.quick_percentage = 1;
   }
   if(game_attacker.power_percentage > 99)
   {
      game_attacker.power_percentage = 99;
   }
   if(game_attacker.normal_percentage > 99)
   {
      game_attacker.normal_percentage = 99;
   }
   if(game_attacker.quick_percentage > 99)
   {
      game_attacker.quick_percentage = 99;
   }
   if(game_attacker.bash_percentage < 1)
   {
      game_attacker.bash_percentage = 1;
   }
   if(game_attacker.bash_percentage > 99)
   {
      game_attacker.bash_percentage = 99;
   }
   if(game_attacker.taunt_percentage > 99)
   {
      game_attacker.taunt_percentage = 99;
   }
   if(game_attacker.taunt_percentage < 1)
   {
      game_attacker.taunt_percentage = 1;
   }
   if(game_attacker.bombard_percentage < 1)
   {
      game_attacker.bombard_percentage = 1;
   }
   if(game_attacker.bombard_percentage > 99)
   {
      game_attacker.bombard_percentage = 99;
   }
   if(game_attacker.snipe_percentage < 1)
   {
      game_attacker.snipe_percentage = 1;
   }
   if(game_attacker.snipe_percentage > 99)
   {
      game_attacker.snipe_percentage = 99;
   }
}
var coop_ah = coopActiveHero();
var coop_ac = coopActiveClip();
if(coop_ah.using_bow)
{
   coop_ah.equipped_weapon = 2;
}
else
{
   coop_ah.equipped_weapon = 1;
}
_global.phasecomplete = true;
villaindecisionA = null;
_root.arena.gladiators.overlay.optiontext = "";
if(battlerounds <= 0)
{
   battlerounds = 0;
}
battlerounds += 1;
if(_global.coop.enabled != true || _global.coop.role == "host")
{
   if(battlerounds >= _root.game.hero.longestbattle)
   {
      _root.game.hero.longestbattle = battlerounds;
   }
   _root.game.hero.longestbattle = 0;
}
_root.skincharacter(coop_ah,this.hero);
this.hero.gotoAndStop("overlay");
this.swapDepths(4000);
turnphase = 1;
coopClearWaitUI();
coopSetMenuVisible(true);
_root.arena.gladiators.overlay.optiontext = "";
optionA.onRollOver = optionB.onRollOver = optionC.onRollOver = optionD.onRollOver = optionE.onRollOver = optionF.onRollOver = optionG.onRollOver = optionH.onRollOver = function()
{
   this.battlebutton.gotoAndStop(2);
   _root.arena.gladiators.overlay.optiontext = this.optiontext;
   if(this.tooltip == undefined)
   {
      _root.arena.gladiators.overlay.optiontext = "";
   }
   if(this.tooltip != undefined)
   {
      _root.tooltips(this.tooltip);
   }
};
optionA.onRollOut = optionB.onRollOut = optionC.onRollOut = optionD.onRollOut = optionE.onRollOut = optionF.onRollOut = optionG.onRollOut = optionH.onRollOut = function()
{
   this.battlebutton.gotoAndStop(1);
   _root.arena.gladiators.overlay.optiontext = "";
   _root.delete_tooltips();
};
if(_global.coop.enabled == true)
{
   decisionA = null;
   villaindecisionA = null;
   coopPhaseDone = false;
   coopResetPoses();
   var needSyncWait = false;
   if(_global.coop.role == "client" && _global.coop.awaitingSync == true)
   {
      if(_global.coop.pendingSync != null)
      {
         var preSync = _global.coop.pendingSync;
         _global.coop.pendingSync = null;
         _global.coop.awaitingSync = false;
         if(_global.coopApplySync != undefined)
         {
            _global.coopApplySync(preSync);
         }
      }
      else
      {
         needSyncWait = true;
         coopSetMenuVisible(false);
         coopShowWaitUI("Syncing with Host...");
         stop();
         var ovSync = this;
         this.onEnterFrame = function()
         {
            if(_global.coop.pendingSync != null)
            {
               var ps = _global.coop.pendingSync;
               _global.coop.pendingSync = null;
               _global.coop.awaitingSync = false;
               if(_global.coopApplySync != undefined)
               {
                  _global.coopApplySync(ps);
               }
               ovSync.coopClearWaitUI();
               ovSync.gotoAndStop(2);
               ovSync.gotoAndPlay("initialise");
            }
            else if(_global.coop.lastOutcome == "won")
            {
               _global.coop.awaitingSync = false;
               ovSync.coopClearWaitUI();
               ovSync.gotoAndPlay("combatwon");
            }
            else if(_global.coop.lastOutcome == "lost")
            {
               _global.coop.awaitingSync = false;
               ovSync.coopClearWaitUI();
               ovSync.gotoAndPlay("combatlost");
            }
         };
      }
   }
   if(needSyncWait)
   {
   }
   else if(_root.game.villain.hitpoints <= 0 || _global.coop.lastOutcome == "won")
   {
      gotoAndPlay("combatwon");
   }
   else if((_root.game.hero.hitpoints <= 0 && _root.game.hero2.hitpoints <= 0) || _global.coop.lastOutcome == "lost")
   {
      gotoAndPlay("combatlost");
   }
   else
   {
      if(_global.coop.activeTurn == 1 && _root.game.hero.hitpoints <= 0)
      {
         _global.coop.activeTurn = 2;
      }
      if(_global.coop.activeTurn == 2 && _root.game.hero2.hitpoints <= 0)
      {
         _global.coop.activeTurn = 3;
      }
      coop_ah = coopActiveHero();
      coop_ac = coopActiveClip();
      if(coop_ah.using_bow)
      {
         coop_ah.equipped_weapon = 2;
      }
      else
      {
         coop_ah.equipped_weapon = 1;
      }
      _root.skincharacter(coop_ah,this.hero);
      this.hero.gotoAndStop("overlay");
      if(_global.coop.activeTurn == 3)
      {
         coopSetMenuVisible(false);
         turnphase = 2;
         _global.battle_action = 2;
         decisionA = null;
         villaindecisionA = null;
         if(_global.coop.role == "host")
         {
            gotoAndStop("heroactions");
            play();
         }
         else
         {
            coopShowWaitUI("Boss is acting...");
            stop();
            var ov = this;
            this.onEnterFrame = function()
            {
               if(_global.coop.pendingRemoteBoss != null)
               {
                  var b = _global.coop.pendingRemoteBoss;
                  _global.coop.pendingRemoteBoss = null;
                  _global.coop.targetHero = Number(b.target);
                  if(_global.coopSrand != undefined && !isNaN(b.seed))
                  {
                     _global.coopSrand(Number(b.seed));
                  }
                  if(b.inv != undefined && b.inv > 1)
                  {
                     _root.game.villain.inventory_action = Number(b.inv);
                     var vi = 1;
                     while(vi <= 6)
                     {
                        if(_root.game.villain["inventory" + vi] == b.inv)
                        {
                           _root.game.villain["inventory" + vi] = 1;
                           break;
                        }
                        vi++;
                     }
                  }
                  _root.game.villain.taunted1 = false;
                  _root.game.villain.taunted2 = false;
                  _root.game.villain.frozen = false;
                  _root.game.villain.burning = false;
                  _root.game.villain.poison = false;
                  _root.game.villain.life_stolen = false;
                  ov.villaindecisionA = b.action;
                  ov.coopClearWaitUI();
                  ov.gotoAndStop("heroactions");
                  ov.play();
               }
               else if(_global.coop.lastOutcome == "won")
               {
                  ov.coopClearWaitUI();
                  ov.gotoAndPlay("combatwon");
               }
               else if(_global.coop.lastOutcome == "lost")
               {
                  ov.coopClearWaitUI();
                  ov.gotoAndPlay("combatlost");
               }
            };
         }
      }
      else if(coopIsLocalOwner())
      {
         if(coop_ah.ammo_left <= 0 && coop_ah.using_bow == true)
         {
            getphase("swap_weapons");
         }
         if(coop_ah.staminaleft <= 0)
         {
            getphase("rest");
         }
         if(coop_ah.taunted1 == true || coop_ah.taunted2 == true)
         {
            if(coop_ac.gladiator_dir == "right")
            {
               coop_ah.taunted1 = false;
               coop_ah.taunted2 = false;
               getphase("runleft");
            }
            if(coop_ac.gladiator_dir == "left")
            {
               coop_ah.taunted1 = false;
               coop_ah.taunted2 = false;
               getphase("runright");
            }
         }
         if(coop_ah.frozen == true)
         {
            coop_ah.frozen = false;
            getphase("frozen");
         }
         if(coop_ah.burning == true)
         {
            coop_ah.burning = false;
            getphase("burning");
         }
         if(coop_ah.poison == true)
         {
            coop_ah.poison = false;
            getphase("poisoned");
         }
         if(coop_ah.life_stolen == true)
         {
            coop_ah.life_stolen = false;
            getphase("life_stolen");
         }
         if(turnphase == 1 && (_global.coop.autoMode == "auto_duel" || _global.coop.autoMode == "auto_combat"))
         {
            var ovAuto = this;
            var acAuto = this.createEmptyMovieClip("coop_auto_clip",199991);
            acAuto.ticks = 0;
            acAuto.onEnterFrame = function()
            {
               this.ticks++;
               if(this.ticks >= 6)
               {
                  delete this.onEnterFrame;
                  if(ovAuto.turnphase == 1 && ovAuto.coopIsLocalOwner())
                  {
                     var aHero = ovAuto.coopActiveHero();
                     var aClip = ovAuto.coopActiveClip();
                     var autoAct = "normal_attack";
                     if(aHero.staminaleft < 20)
                     {
                        autoAct = "rest";
                     }
                     else if(_root.arena.fightdistance >= aHero.weapon_range)
                     {
                        autoAct = aClip.gladiator_dir == "left" ? "jumpleft" : "jumpright";
                     }
                     ovAuto.getphase(autoAct);
                  }
               }
            };
         }
      }
      else
      {
         coopSetMenuVisible(false);
         coopShowWaitUI("Waiting for P" + _global.coop.activeTurn + "...");
         stop();
         var ov2 = this;
         this.onEnterFrame = function()
         {
            if(_global.coop.pendingRemoteAct != null && Number(_global.coop.pendingRemoteAct.actor) == Number(_global.coop.activeTurn))
            {
               var act = _global.coop.pendingRemoteAct;
               _global.coop.pendingRemoteAct = null;
               if(_global.coopSrand != undefined && !isNaN(act.seed))
               {
                  _global.coopSrand(Number(act.seed));
               }
               var rah = ov2.coopActiveHero();
               if(act.inv != undefined && act.inv > 1)
               {
                  rah.inventory_action = Number(act.inv);
                  var si = 1;
                  while(si <= 6)
                  {
                     if(rah["inventory" + si] == act.inv)
                     {
                        rah["inventory" + si] = 1;
                        break;
                     }
                     si++;
                  }
               }
               rah.taunted1 = false;
               rah.taunted2 = false;
               rah.frozen = false;
               rah.burning = false;
               rah.poison = false;
               rah.life_stolen = false;
               ov2.coopClearWaitUI();
               ov2.getphase(act.action);
            }
            else if(_global.coop.lastOutcome == "won")
            {
               ov2.coopClearWaitUI();
               ov2.gotoAndPlay("combatwon");
            }
            else if(_global.coop.lastOutcome == "lost")
            {
               ov2.coopClearWaitUI();
               ov2.gotoAndPlay("combatlost");
            }
         };
      }
   }
}
else
{
   if(_root.game.hero.ammo_left <= 0 && _root.game.hero.using_bow == true)
   {
      getphase("swap_weapons");
   }
   if(_root.game.hero.staminaleft <= 0)
   {
      getphase("rest");
   }
   if(_root.game.hero.taunted1 == true || _root.game.hero.taunted2 == true)
   {
      if(_root.arena.gladiators.hero.gladiator_dir == "right")
      {
         _root.game.hero.taunted1 = false;
         getphase("runleft");
      }
      if(_root.arena.gladiators.hero.gladiator_dir == "left")
      {
         _root.game.hero.taunted1 = false;
         getphase("runright");
      }
   }
   if(_root.game.hero.frozen == true)
   {
      _root.game.hero.frozen = false;
      getphase("frozen");
   }
   if(_root.game.hero.burning == true)
   {
      _root.game.hero.burning = false;
      getphase("burning");
   }
   if(_root.game.hero.poison == true)
   {
      _root.game.hero.poison = false;
      getphase("poisoned");
   }
   if(_root.game.hero.life_stolen == true)
   {
      _root.game.hero.life_stolen = false;
      getphase("life_stolen");
   }
}
