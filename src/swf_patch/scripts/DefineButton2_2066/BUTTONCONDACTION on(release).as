on(release){
   var maxArena = 2;
   var level = _root.game.hero.herolevel;
   if(level >= 48)
   {
      maxArena = 6;
   }
   else if(level >= 36)
   {
      maxArena = 5;
   }
   else if(level >= 27)
   {
      maxArena = 4;
   }
   else if(level >= 15)
   {
      maxArena = 3;
   }
   var arenaId = 1 + random(maxArena);
   _root.clicksound2.start();
   if(_global.coopStartStoryFight("duel",arenaId))
   {
      return;
   }
   _global.fight_mode = "duel";
   _global.current_arena = arenaId;
   _root.gotoAndPlay("arena_intro");
}
