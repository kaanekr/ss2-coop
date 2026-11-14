_root.arena.combat_panel.removeMovieClip();
_root.arena.coop_hud.removeMovieClip();
_root.crowd_noise.stop();
_root.delete_tooltips();
_global.battle_started = false;
var coopFightBanner = null;
if(_global.coop.enabled == true)
{
   _global.coop.inArena = false;
   coopFightBanner = _root.game.hero.character_name + " & " + _root.game.hero2.character_name + " defeat " + _root.game.villain.character_name + "!";
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
            var restHero = new Object();
            if(_global.coopInitHeroFromDNA != undefined)
            {
               _global.coopInitHeroFromDNA(restHero,_global.coop.localHeroBackup);
            }
            else
            {
               _root.initcharacter(restHero,null,_global.coop.localHeroBackup);
            }
            _root.game.hero = restHero;
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
      _root.backup_char(_root.game.hero);
      _root.battlevalues(_root.game.hero);
   }
}
if(_global.gamephase == 4)
{
   _global.gamephase = 5;
   _root.tooltips("Congratulations! You have won your first combat. Whenever you win battles, you receive experience points and gold. The stronger your opponent, the more experience you get. The more the crowd enjoyed your fight, the more gold you receive.",300,400,100);
}
this.attachMovie("fight_win_stuff","fight_win_stuff",100000,{_x:-193,_y:164});
fight_win_stuff._visible = false;
fight_win_stuff.button_yes._visible = false;
fight_win_stuff.exp_bar._xscale = 0;
if(fight_win_stuff.exp_bar._xscale > 150)
{
   fight_win_stuff.exp_bar._xscale = 150;
}
if(coopFightBanner != null)
{
   fighttext = coopFightBanner;
}
else if(_global.fight_mode == "duel")
{
   fighttext = "First blood to " + _root.game.hero.character_name + "! " + _root.game.villain.character_name + " yields.";
}
else
{
   fighttext = _root.game.hero.character_name + " defeats " + _root.game.villain.character_name;
}
_root.game.villain.character_xp = Number(_root.game.villain.character_xp);
_global.crowd_interest = Number(_global.crowd_interest);
fight_win_stuff.xpwon = _root.game.villain.character_xp + " xp won for this fight.";
fight_win_stuff.experiencetext = _root.game.hero.experience + " xp / " + _root.game.hero.experienceneeded + " xp ";
nextleveltext_exp = Math.round((_root.game.hero.experience - _root.game.hero.experiencelast) / (_root.game.hero.experienceneeded - _root.game.hero.experiencelast) * 100);
if(nextleveltext_exp > 100)
{
   nextleveltext_exp = 100;
}
original_exp = nextleveltext_exp;
fight_win_stuff.exp_bar._xscale = original_exp;
if(fight_win_stuff.exp_bar._xscale < 0)
{
   fight_win_stuff.exp_bar._xscale = 0;
}
fighttext.swapDepths(110003);
fight_win_stuff.nextleveltext = nextleveltext_exp + " % TO NEXT LEVEL";
_root.game.hero.goldpieces += Number(Math.round(_root.game.villain.character_xp * (100 + _global.crowd_interest) / 100));
fight_win_stuff.goldwon = Math.round(_root.game.villain.character_xp * (100 + _global.crowd_interest) / 100) + " gold won. (" + _global.crowd_interest + " % crowd appreciation )";
if(_root.game.hero.herolevel == 1)
{
   fight_win_stuff.goldwon = "\'A gift from the emperor to start you on your way.\'  You receive 2500 gold pieces.";
   _root.game.hero.goldpieces = 2500;
}
_root.game.hero.battlesfought += 1;
_root.game.hero.battleswon += 1;
if(_global.tournament_in_progress == true)
{
   _root.game.hero.tournament_ranking -= 1;
   if(_global.coop.enabled == true && _global.coopSaveLocalHero != undefined)
   {
      _global.coopSaveLocalHero();
   }
   if(_root.game.hero.tournament_ranking == 1)
   {
      gotoAndStop("combat_wonitem");
      play();
   }
   else
   {
      gotoAndStop("combat_delay");
      play();
   }
}
else
{
   if(_global.coop.enabled == true && _global.coopSaveLocalHero != undefined)
   {
      _global.coopSaveLocalHero();
   }
   gotoAndStop("combat_delay");
   play();
}
