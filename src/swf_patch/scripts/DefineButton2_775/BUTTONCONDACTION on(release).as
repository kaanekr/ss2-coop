on(release){
   _root.clicksound2.start();
   if(_root.game.hero.current_tournament >= 19 && _root.game.hero.tournament_ranking <= 2)
   {
      fight_over_win._visible = false;
      _root.attachMovie("gameover_screen","gameover_screen",50000,{x:-40,y:-40});
      _root.gameover_screen._alpha = 0;
      fighttext = _root.game.hero.character_name + " defeats the Emperor!";
      var fadeGameover = new mx.transitions.Tween(_root.gameover_screen,"_alpha",mx.transitions.easing.Regular.easeOut,0,100,3,true);
      _root.tooltips("Congratulations, you have completed Swords and Sandals II. Your final score is based on the amount of experience you won as a gladiator in this session.",300,400,320);
      this._visible = false;
   }
   else if(nextleveltext == "YOU HAVE LEVELLED UP!" && (_global.game_mode == "demo" && _root.game.hero.herolevel < 12 || _global.game_mode == "full" && _root.game.hero.herolevel < 50))
   {
      _root.game.hero.experience = _root.game.hero.experienceneeded + 1;
      _root.game.hero.herolevel++;
      _root.battlevalues(_root.game.hero);
      _root.constructDNA();
      if(_global.coop != undefined && _global.coop.enabled == true && _global.coopSaveLocalHero != undefined)
      {
         _global.coopSaveLocalHero();
      }
      _root.gotoAndPlay("levelup");
   }
   else if(_global.tournament_in_progress == true)
   {
      _root.gotoAndPlay("foyer");
   }
   else if(_global.tournament_complete == true)
   {
      _global.tournament_complete = null;
      _global.time_of_day = 1 + random(23);
      _global.day++;
      chance_of_rain = 1 + random(100);
      if(chance_of_rain > 80)
      {
         _global.rain_chance = true;
      }
      else
      {
         _global.rain_chance = false;
      }
      _global.special_for_day = false;
      _root.game.hero.days_in_arena = _global.day;
      _global.cloudframe = 1 + random(16);
      _global.special_event = 0;
      _global.special_event_happening = false;
      _root.gotoAndPlay("daybreak");
   }
   else
   {
      _root.gotoAndPlay("townsquare");
   }
}
