on(release){
   _root.clicksound2.start();
   _root.AS3connection.send("AS2to3","doAchievement","SS2_BOSS_" + _root.game.hero.current_tournament);
   if(_root.game.hero.current_tournament < 19)
   {
      _root.game.hero.current_tournament++;
   }
   _root.constructDNA();
   if(_global.coop != undefined && _global.coop.enabled == true && _global.coopSaveLocalHero != undefined)
   {
      _global.coopSaveLocalHero();
   }
   _global.tournament_complete = true;
   _global.tournament_in_progress = false;
   _root.arena.gotoAndPlay("combat_exp");
}
