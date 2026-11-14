_root.delete_tooltips();
if(_global.coop.enabled == true)
{
   _root.charsheet.removeMovieClip();
}
crowd.gotoAndStop(_global.current_arena);
if(_global.gamephase == 2)
{
   _global.gamephase = 3;
   _root.tooltips("Your first opponent! Study your enemy for a while, then when ready, click the button in the bottom right corner to enter the arena.",300,400,110);
}
_root.game.hero.hitpoints = _root.game.hero.hitpointsmax;
_root.arena_intro.createEmptyMovieClip("gladiators",5);
if(_global.coop.enabled == true)
{
   var heroPair = _root.arena_intro.gladiators.createEmptyMovieClip("heropair",301);
   portrait_hero = heroPair.attachMovie("hero","hero",1);
   portrait_hero2 = heroPair.attachMovie("hero","hero2",2);
   portrait_villain = _root.arena_intro.gladiators.attachMovie("hero","villain",300);
   heroPair.setMask(_root.arena_intro.heromask);
   portrait_villain.setMask(_root.arena_intro.villainmask);
}
else
{
   portrait_hero = _root.arena_intro.gladiators.attachMovie("hero","hero",301);
   portrait_villain = _root.arena_intro.gladiators.attachMovie("hero","villain",300);
   portrait_hero.setMask(_root.arena_intro.heromask);
   portrait_villain.setMask(_root.arena_intro.villainmask);
}
if(_global.coop.enabled == true)
{
   _global.coop.inArena = true;
   _global.coop.activeTurn = 1;
   _global.coop.targetHero = 1;
   _global.coop.pendingRemoteAct = null;
   _global.coop.pendingRemoteBoss = null;
   _global.coop.pendingSync = null;
   _global.coop.awaitingSync = false;
   _global.coop.syncSeq = 0;
   _global.coop.lastAppliedSyncSeq = 0;
   if(_global.coopSrand != undefined && _global.coop.seed != undefined)
   {
      _global.coopSrand(_global.coop.seed);
   }
   if(_global.coop.role == "client")
   {
      if(_global.coop.localHeroBackup == null && _root.game.hero != undefined)
      {
         _global.coop.localHeroBackup = _root.game.hero;
      }
      if(_global.coop.p1DNA != undefined && _global.coop.p1DNA != null)
      {
         _root.game.hero = new Object();
         _root.initcharacter(_root.game.hero,null,_global.coop.p1DNA);
         _root.backup_char(_root.game.hero);
         _root.battlevalues(_root.game.hero);
      }
   }
   else if(_global.coop.p1DNA != undefined && _global.coop.p1DNA != null)
   {
      _root.initcharacter(_root.game.hero,null,_global.coop.p1DNA);
      _root.backup_char(_root.game.hero);
      _root.battlevalues(_root.game.hero);
   }
   _root.game.hero2 = new Object();
   if(_global.coop.p2DNA != undefined && _global.coop.p2DNA != null)
   {
      _root.initcharacter(_root.game.hero2,null,_global.coop.p2DNA);
      _root.backup_char(_root.game.hero2);
      _root.battlevalues(_root.game.hero2);
   }
   if(_global.coop.matchCfg != undefined && _global.coop.matchCfg.vdna != undefined && _global.coop.matchCfg.vdna != "")
   {
      if(_root.game.villain == undefined)
      {
         _root.game.villain = new Object();
      }
      var keepVQuote = _root.game.villain.character_quote;
      _root.initcharacter(_root.game.villain,null,_global.coop.matchCfg.vdna);
      if(_global.coop.matchCfg.vname != undefined && _global.coop.matchCfg.vname != "")
      {
         _root.game.villain.character_name = _global.coop.matchCfg.vname;
         _root.game.villain.hero_name = _global.coop.matchCfg.vname;
         _root.game.villain.hat_name = _global.coop.matchCfg.hat != undefined && _global.coop.matchCfg.hat != "" ? _global.coop.matchCfg.hat : _global.coop.matchCfg.vname;
      }
      if(keepVQuote != undefined && keepVQuote != "")
      {
         _root.game.villain.character_quote = keepVQuote;
      }
      _root.battlevalues(_root.game.villain);
      if(_global.coop.matchCfg.boss >= 1 && _global.coop.matchCfg.boss <= 18)
      {
         _root.game.champion = _root.game.villain;
      }
   }
   _root.game.hero.charDNA = _root.game.hero.charDNA != undefined ? _root.game.hero.charDNA : _global.coop.p1DNA;
   if(_global.coop.matchCfg != undefined && !isNaN(Number(_global.coop.matchCfg.tourney)) && Number(_global.coop.matchCfg.tourney) >= 1)
   {
      _root.game.hero.current_tournament = Number(_global.coop.matchCfg.tourney);
   }
   _root.game.hero.tournament_ranking = _global.coop.matchCfg.ranking;
   _root.game.hero2.charDNA = _root.game.hero2.charDNA != undefined ? _root.game.hero2.charDNA : _global.coop.p2DNA;
   _root.game.villain.charDNA = _root.game.villain.charDNA != undefined ? _root.game.villain.charDNA : _global.coop.matchCfg.vdna;
   _root.skincharacter(_root.game.hero,portrait_hero);
   _root.skincharacter(_root.game.hero2,portrait_hero2);
   _root.skincharacter(_root.game.villain,_root.arena_intro.gladiators.villain);
   portrait_hero.gotoAndStop("portrait");
   portrait_hero2.gotoAndStop("portrait");
   portrait_villain.gotoAndStop("portrait");
   portrait_hero._xscale = 240;
   portrait_hero._yscale = 240;
   portrait_hero._x = -115;
   portrait_hero._y = 575;
   portrait_hero2._xscale = 220;
   portrait_hero2._yscale = 220;
   portrait_hero2._x = -230;
   portrait_hero2._y = 590;
   portrait_villain._xscale = 300;
   portrait_villain._yscale = 300;
   portrait_villain._x = 160;
   portrait_villain._y = 600;
   _root.arena_intro.createTextField("coop_intro_txt",990,-300,-225,600,32);
   var introFmt = new TextFormat("_sans",16,16766720,true,null,null,null,null,"center");
   _root.arena_intro.coop_intro_txt.selectable = false;
   _root.arena_intro.coop_intro_txt.text = "2v1 CO-OP: " + _root.game.hero.character_name + " & " + _root.game.hero2.character_name + "  VS  " + _root.game.villain.character_name;
   _root.arena_intro.coop_intro_txt.setTextFormat(introFmt);
}
else
{
   _root.skincharacter(_root.game.hero,_root.arena_intro.gladiators.hero);
   if(_global.fight_mode == "duel" && _global.fightstarted != true)
   {
      randomise_gladiator(_root.game.villain,_root.arena_intro.gladiators.villain,_root.game.hero.herolevel);
      constructvillainDNA(_root.game.villain);
   }
   if(_root.game.hero.tournament_ranking == 2)
   {
      _root.unleash_hell(_root.game.hero.current_tournament);
   }
   if(_root.game.hero.herolevel == 1)
   {
      _root.unleash_hell(0);
   }
   _root.skincharacter(_root.game.villain,_root.arena_intro.gladiators.villain);
   portrait_hero.gotoAndStop("portrait");
   portrait_villain.gotoAndStop("portrait");
   portrait_hero._xscale = 300;
   portrait_hero._yscale = 300;
   portrait_hero._x = -160;
   portrait_hero._y = 570;
   portrait_villain._xscale = 300;
   portrait_villain._yscale = 300;
   portrait_villain._x = 160;
   portrait_villain._y = 600;
}
