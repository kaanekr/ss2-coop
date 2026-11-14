tournament_arena_live = "This tournament is being held in the " + tournament_arena_name + ".";
tournaments_icons.gotoAndStop(tournament_number);
tournament_desc_text.text = tournament_desc;
i = 0;
while(i <= 20)
{
   if(i <= tournament_max_gladiators)
   {
      if(i == 1)
      {
         _root.unleash_hell(tournament_number);
         if(typeof(_global.coopInitHeroFromDNA) == "function" && _root.game.champion != undefined && _root.game.champion.charDNA != undefined)
         {
            var champName = _root.game.champion.character_name;
            var champQuote = _root.game.champion.character_quote;
            var champHat = _root.game.champion.hat_name;
            _global.coopInitHeroFromDNA(_root.game.champion,_root.game.champion.charDNA);
            if(champName != undefined && champName != "")
            {
               _root.game.champion.character_name = champName;
               _root.game.champion.hero_name = champName;
            }
            _root.game.champion.character_quote = champQuote;
            _root.game.champion.hat_name = champHat;
         }
         else
         {
            _root.constructvillainDNA(_root.game.champion);
         }
         tourney_gladiator1 = _root.game.champion.character_name;
         tourney_gladiator_text_1.textColor = 16776960;
      }
      else
      {
         var needGen = (_global.tournament_in_progress != true || _root.game["villain" + i] == undefined || _root.game["villain" + i].character_name == undefined);
         if(needGen)
         {
            _root.game["villain" + i] = new Object();
            _root.randomise_gladiator(_root.game["villain" + i],_root.arena_intro.gladiators.villain,_root.game.hero.herolevel);
         }
         _root.constructvillainDNA(_root.game["villain" + i]);
         this["tourney_gladiator" + i] = _root.game["villain" + i].character_name;
         if(i == _root.game.hero.tournament_ranking)
         {
            _root.foyer["tourney_gladiator" + i] = _root.game.hero.character_name + " (you)";
            _root.foyer["tourney_gladiator_text" + i].textColor = 13311;
         }
         if(i > _root.game.hero.tournament_ranking)
         {
            _root.foyer["tourney_gladiator" + i] = _root.game["villain" + (i - 1)].character_name + "(dead)";
         }
      }
   }
   else
   {
      this["tourney_gladiator" + i] = "";
   }
   i++;
}
_global.tournament_in_progress = true;
_global.current_arena = tournament_arena;
if(_root.game.hero.tournament_ranking > 2)
{
   _root.game.villain = _root.game["villain" + (_root.game.hero.tournament_ranking - 1)];
}
else
{
   _root.game.villain = _root.game.champion;
}
