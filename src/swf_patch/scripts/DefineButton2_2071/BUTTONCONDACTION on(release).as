on(release){
   if(!_global.coopStartStoryFight("tournament",_global.current_arena))
   {
      _global.fight_mode = "tournament";
      _root.gotoAndPlay("arena_intro");
   }
}
