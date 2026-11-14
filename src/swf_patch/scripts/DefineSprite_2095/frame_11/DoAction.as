init_bubbletext = "I am Arglax, Overlord of the Arena. What sort of fight are you after, gladiator?";
bubbletext = init_bubbletext;
if(_global.tournament_in_progress == true)
{
   bubbletext = "You are currently fighting in the " + tournament_name + ".";
   duel_icon._visible = duel_button._visible = false;
   init_bubbletext = bubbletext;
}
if(_root.game.hero.herolevel >= tournament_level_required)
{
   if(_global.game_mode == "demo" && tournament_number <= 3 || _global.game_mode == "full")
   {
      bubbletext = "You have reached a gladiator level " + _root.game.hero.herolevel + ". You cannot duel again until you win the " + tournament_name + ".";
      init_bubbletext = bubbletext;
      duel_icon._visible = duel_button._visible = false;
   }
}
tournaments_icons.gotoAndStop(tournament_number);
gp_text.text = _root.game.hero.goldpieces;
