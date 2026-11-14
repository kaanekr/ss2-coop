if(_global.coop.enabled == true)
{
   _global.coop.inArena = false;
   if(_global.coop.role == "client")
   {
      if(_global.coopRestoreLocalHero != undefined && _global.coop.needRestoreLocalHero == true)
      {
         _global.coopRestoreLocalHero();
      }
      else if(_global.coop.localHeroBackup != null)
      {
         if(typeof(_global.coop.localHeroBackup) == "string")
         {
            var restHero2 = new Object();
            if(_global.coopInitHeroFromDNA != undefined)
            {
               _global.coopInitHeroFromDNA(restHero2,_global.coop.localHeroBackup);
            }
            else
            {
               _root.initcharacter(restHero2,null,_global.coop.localHeroBackup);
            }
            _root.game.hero = restHero2;
         }
         else
         {
            _root.game.hero = _global.coop.localHeroBackup;
         }
         _global.coop.localHeroBackup = null;
         _global.coop.needRestoreLocalHero = false;
      }
      if(_root.game.hero.statpoints == undefined || isNaN(Number(_root.game.hero.statpoints)))
      {
         _root.game.hero.statpoints = 0;
      }
   }
}
_root.restore_char(_root.game.hero);
_root.backup_char(_root.game.hero);
if(_global.coop.enabled == true)
{
   _root.battlevalues(_root.game.hero);
}
_root.game.hero.experience += _root.game.villain.character_xp;
_root.game.hero.score += _root.game.villain.character_xp;
_root.game.hero.gladiatorscore += Number(_root.game.hero.experience);
_root.constructDNA();
if(_global.coop.enabled == true)
{
   if(_global.coopSaveLocalHero != undefined)
   {
      _global.coopSaveLocalHero();
   }
   else if(_global.coop.role == "host")
   {
      _global.coop.p1DNA = _root.game.hero.charDNA;
   }
   else if(_global.coop.role == "client")
   {
      _global.coop.p2DNA = _root.game.hero.charDNA;
   }
}
nextleveltext_exp = Math.round((_root.game.hero.experience - _root.game.hero.experiencelast) / (_root.game.hero.experienceneeded - _root.game.hero.experiencelast) * 100);
if(_root.game.hero.herolevel < 50 && _root.game.hero.current_tournament <= 18 && _root.fizMode == "fizzle" || _root.game.hero.herolevel < 12 && _root.game.hero.current_tournament <= 3 && _root.fizMode != "fizzle")
{
   if(nextleveltext_exp > 100)
   {
      nextleveltext_exp = 100;
   }
   if(_root.game.hero.experience > _root.game.hero.experienceneeded)
   {
      _root.game.hero.experience = _root.game.hero.experienceneeded;
   }
   fight_win_stuff.nextleveltext = nextleveltext_exp + " % TO NEXT LEVEL";
   fight_win_stuff.experiencetext = _root.game.hero.experience + " xp / " + _root.game.hero.experienceneeded + " xp ";
   exp_percent = Math.round((_root.game.hero.experience - _root.game.hero.experiencelast) / (_root.game.hero.experienceneeded - _root.game.hero.experiencelast) * 150);
   if(exp_percent > 150)
   {
      exp_percent = 150;
   }
   experiencetext = _root.game.hero.experience + " xp / " + _root.game.hero.experienceneeded + " xp ";
   var slideExpbar = new mx.transitions.Tween(fight_win_stuff.exp_bar,"_xscale",mx.transitions.easing.Strong.easeOut,original_exp,exp_percent,2,true);
   slideExpbar.onMotionFinished = function()
   {
      if(fight_win_stuff.exp_bar._xscale > 150)
      {
         fight_win_stuff.exp_bar._xscale = 150;
      }
      fight_win_stuff.button_yes._visible = true;
      if(exp_percent >= 150)
      {
         fight_win_stuff.nextleveltext = "YOU HAVE LEVELLED UP!";
      }
   };
}
else if(_root.game.hero.current_tournament == 18 && _root.game.hero.tournament_ranking == 1 && _root.fizMode == "fizzle" || _root.game.hero.current_tournament >= 4 && _root.game.hero.tournament_ranking == 1 && _root.fizMode != "fizzle")
{
   _root.game.hero.current_tournament = 19;
   fight_win_stuff.button_yes._visible = true;
   exp_percent = 150;
   fight_win_stuff.exp_bar._xscale = exp_percent;
   _root.game.hero.experience = _root.game.hero.experienceneeded;
   if(_root.fizMode == "fizzle")
   {
      fight_win_stuff.nextleveltext = "MAXIMUM LEVEL ATTAINED!";
   }
   else if(_root.fizMode != "fizzle")
   {
      fight_win_stuff.nextleveltext = "MAXIMUM DEMO LEVEL ATTAINED!";
   }
}
else
{
   fight_win_stuff.button_yes._visible = true;
   exp_percent = 0;
   fight_win_stuff.exp_bar._xscale = exp_percent;
   _root.game.hero.experience = _root.game.hero.experienceneeded - 1;
   if(_root.fizMode == "fizzle")
   {
      fight_win_stuff.nextleveltext = "MAXIMUM LEVEL ATTAINED!";
   }
   else if(_root.fizMode != "fizzle")
   {
      fight_win_stuff.nextleveltext = "MAXIMUM DEMO LEVEL ATTAINED!";
   }
}
