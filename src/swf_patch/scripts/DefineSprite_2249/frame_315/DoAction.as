if(_global.coop.enabled == true)
{
   _global.coop.inArena = false;
   if(_global.coop.role == "client" && _global.coopRestoreLocalHero != undefined && _global.coop.needRestoreLocalHero == true)
   {
      _global.coopRestoreLocalHero();
   }
}
_root.game.hero.battlesfought += 1;
_root.game.hero.battleslost += 1;
_root.restore_char(_root.game.hero);
_global.battle_started = false;
_root.constructDNA();
if(_global.coop.enabled == true && _global.coopSaveLocalHero != undefined)
{
   _global.coopSaveLocalHero();
}
fighttext.swapDepths(110003);
if(_global.tournament_in_progress != true)
{
   fight_over_lost._visible = true;
   fight_over_lost.swapDepths(222222);
   fighttext = "First blood to " + _root.game.villain.character_name + "! " + _root.game.hero.character_name + " yields.";
   goldlost = Math.ceil(_root.game.hero.herolevel * _root.game.hero.herolevel * 50);
   _root.game.hero.goldpieces -= Number(goldlost);
   if(_root.game.hero.goldpieces < 0)
   {
      _root.game.hero.goldpieces = Number(0);
   }
   fight_over_lost.goldlost = "You are forced to hand over " + goldlost + " gold pieces.";
   if(_root.game.hero.goldpieces <= Number(0))
   {
      fight_over_lost.goldlost += " You have no gold left!";
   }
   _root.tooltips("You have lost this combat. Whenever you lose a fight, you will lose gold. The higher your gladiator level, the more gold you will lose.",300,400,320);
}
else
{
   fight_over_lost._visible = false;
   _root.attachMovie("gameover_screen","gameover_screen",50000,{x:-40,y:-40});
   _root.gameover_screen._alpha = 0;
   fighttext = _root.game.villain.character_name + " defeats " + _root.game.hero.character_name;
   var fadeGameover = new mx.transitions.Tween(_root.gameover_screen,"_alpha",mx.transitions.easing.Regular.easeOut,0,100,3,true);
   _root.tooltips("Alas, you were slain in combat and the game is over. Your final score is based on the amount of experience you won as a gladiator in this session.",300,400,320);
}
