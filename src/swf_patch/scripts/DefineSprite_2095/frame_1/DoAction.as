if(_global.coop != undefined && _global.coop.inArena != true)
{
   _global.coop.enabled = false;
   _global.coop.inArena = false;
   if(_global.coop.needRestoreLocalHero == true)
   {
      _global.coopRestoreLocalHero();
   }
}
_root.delete_tooltips();
if(_global.gamephase < 5)
{
   _root.tooltips("This is the Arena\'s registration booth. You can select to fight in a tournament to the death, if your level is high enough, or fight a duel in a random arena for gold.",1000,400,90);
}
shopkeeper.gotoAndPlay("normal");
tournament_number = Number(_root.game.hero.current_tournament);
tournament_level_required = _root["tournament" + tournament_number][0];
tournament_max_gladiators = _root["tournament" + tournament_number][1];
tournament_arena = _root["tournament" + tournament_number][2];
tournament_name = _root["tournament" + tournament_number][3];
tournament_desc = _root["tournament" + tournament_number][4];
tournament_arena_name = _root.arena_names[tournament_arena];
if(_global.tournament_in_progress != true)
{
   _root.game.hero.tournament_ranking = tournament_max_gladiators;
}

if(_global.coop != undefined)
{
   var localDna = _global.coopGetLocalDNA();
   if(_global.coop.connected == true && localDna != "")
   {
      _global.coopSend("hello",{role:_global.coop.role, dna:localDna});
      _global.coopRefreshLobbyUI();
   }
   if(typeof(_global.coopDrawButton) == "function")
   {
      if(_root.__coop_foyer_btn != undefined)
      {
         _root.__coop_foyer_btn.removeMovieClip();
      }
      var fLabel = (_global.coop.connected == true) ? "2v1 CO-OP (ONLINE)" : "2v1 CO-OP LOBBY";
      var fBg = (_global.coop.connected == true) ? 0x2E5D34 : 0x4A2E16;
      var foyerBtn = _global.coopDrawButton(_root,"__coop_foyer_btn",99921,247,14,150,28,fLabel,fBg,0xFFD470,0xFFFFFF,function()
      {
         _global.coopToggleLobby();
      });
      foyerBtn.onEnterFrame = function()
      {
         if(_root.foyer == undefined || (_global.coop != undefined && _global.coop.inArena == true))
         {
            this.removeMovieClip();
         }
         else if(_global.coop != undefined && this.lbl != undefined)
         {
            var wantLbl = (_global.coop.connected == true) ? "2v1 CO-OP (ONLINE)" : "2v1 CO-OP LOBBY";
            if(this.lbl.text != wantLbl)
            {
               this.lbl.text = wantLbl;
               this.lbl.setTextFormat(this._fmt);
            }
         }
      };
   }
}

if(_global.tournament_in_progress == true)
{
   gotoAndStop("tournament");
   play();
}
else
{
   gotoAndStop("browse");
   play();
}
