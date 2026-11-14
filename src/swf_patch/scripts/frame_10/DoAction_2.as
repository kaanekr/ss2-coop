function soundeffects()
{
   _root.createEmptyMovieClip("crowdsounds",-50001);
   crowd_noise = new Sound(crowdsounds);
   crowd_noise.attachSound("crowd-ambient.wav");
   rockyou = new Sound(crowdsounds);
   rockyou.attachSound("rockyou.wav");
   crowd_boo = new Sound(crowdsounds);
   crowd_boo.attachSound("boo-crowd.wav");
   _root.createEmptyMovieClip("townsounds",-50003);
   town_day = new Sound(townsounds);
   town_day.attachSound("townsquare_day.wav");
   town_night = new Sound(townsounds);
   town_night.attachSound("townsquare_night.wav");
   _root.createEmptyMovieClip("sounds",-50003);
   rooster = new Sound(sounds);
   rooster.attachSound("rooster.wav");
   victory1 = new Sound(sounds);
   victory1.attachSound("victory1.wav");
   victory2 = new Sound(sounds);
   victory2.attachSound("victory2.wav");
   victory3 = new Sound(sounds);
   victory3.attachSound("victory3.wav");
   coins = new Sound(sounds);
   coins.attachSound("coins.wav");
   levelupsong = new Sound(sounds);
   levelupsong.attachSound("gladiator-chant.wav");
   clicksound = new Sound(sounds);
   clicksound.attachSound("click.wav");
   clicksound2 = new Sound(sounds);
   clicksound2.attachSound("click2.wav");
}
var tempSound = new Sound();
_global.gamephase = 0;
_global.fight_mode = null;
_global.tournament_in_progress = false;
_global.special_for_day = false;
_global.heroDNA = null;
delete game;
_global.max_characters = 0;
if(_level0.citizen_kane != undefined && _level0.citizen_kane != "default")
{
   _global.user_id = _level0.citizen_kane;
}
if(_global.user_id == undefined || _global.user_id == null)
{
   _global.user_id = 123;
}
_root.removeMovieClip("charsheet");
_root.charsheet.removeMovieClip();
_root.gameover_screen.removeMovieClip(this);
removeMovieClip(_root.gameover_screen);
_root.tooltips("Welcome to Swords & Sandals. This gold box is a tooltip. It will appear throughout the game to help explain facets of the game to you, and to offer advice. You can turn off these tooltips at any time by clicking the option on the bottom panel.",1000,400,340);
_root.soundeffects();
var fadeFromBlack = new mx.transitions.Tween(_root.blackscreen,"_alpha",mx.transitions.easing.Regular.easeOut,100,0,1,true);

// ============================================================================
// SS2 2v1 Co-op Manager (_global.coop), Deterministic PRNG, XMLSocket & Lobby
// ============================================================================

if(_global.coop == undefined)
{
   _global.coop = {
      enabled:false,
      role:null,
      localActor:1,
      connected:false,
      peerConnected:false,
      sock:null,
      port:19801,
      p1DNA:null,
      p2DNA:null,
      p1Ready:false,
      p2Ready:false,
      seed:1337,
      activeTurn:1,
      turnSlot:1,
      targetHero:1,
      pendingRemoteAct:null,
      pendingRemoteBoss:null,
      matchCfg:null,
      localHeroBackup:null,
      localHeroBackupDNA:null,
      needRestoreLocalHero:false,
      inArena:false,
      statusText:"Offline",
      autoMode:null,
      testMode:false,
      lastOutcome:null,
      lastSync:null,
      pendingSync:null,
      syncSeq:0,
      lastAppliedSyncSeq:0,
      awaitingSync:false,
      autoChecked:false,
      pendingQuickChar:null,
      qaAutoTimer:0,
      townEntered:false,
      bugsHit:false
   };
}
else
{
   _global.coop.enabled = false;
   _global.coop.inArena = false;
   _global.coop.townEntered = false;
   _global.coop.localHeroBackup = null;
   _global.coop.localHeroBackupDNA = null;
   _global.coop.needRestoreLocalHero = false;
   _global.coop.pendingSync = null;
   _global.coop.awaitingSync = false;
   _global.coop.syncSeq = 0;
   _global.coop.lastAppliedSyncSeq = 0;
}

_global.coopSrand = function(s)
{
   var n = Math.floor(Number(s));
   if(isNaN(n))
   {
      n = 1337;
   }
   n = n % 2147483647;
   if(n <= 0)
   {
      n += 2147483646;
   }
   if(_global.coop != undefined)
   {
      _global.coop.seed = n;
   }
   return n;
};

_global.coopNextInt = function()
{
   var s = 1337;
   if(_global.coop != undefined)
   {
      s = Number(_global.coop.seed);
   }
   if(isNaN(s) || s <= 0)
   {
      s = 1337;
   }
   s = (s * 16807) % 2147483647;
   if(s <= 0)
   {
      s += 2147483646;
   }
   if(_global.coop != undefined)
   {
      _global.coop.seed = s;
   }
   return s;
};

_global.coopRand = function(n)
{
   var maxN = Math.floor(Number(n));
   if(isNaN(maxN) || maxN <= 0)
   {
      return 0;
   }
   var v = _global.coopNextInt();
   var r = Math.floor(((v - 1) / 2147483646) * maxN);
   if(r >= maxN)
   {
      r = maxN - 1;
   }
   if(r < 0)
   {
      r = 0;
   }
   return r;
};

_global.coopRandBetween = function(a, b)
{
   var lo = Math.floor(Number(a));
   var hi = Math.floor(Number(b));
   if(isNaN(lo))
   {
      lo = 0;
   }
   if(isNaN(hi))
   {
      hi = lo;
   }
   if(hi < lo)
   {
      var tmp = lo;
      lo = hi;
      hi = tmp;
   }
   return lo + _global.coopRand((hi - lo) + 1);
};

_global.coopCleanStr = function(val)
{
   if(val == undefined || val == null)
   {
      return "";
   }
   var str = String(val);
   if(str == "undefined" || str == "null")
   {
      return "";
   }
   str = str.split("|").join("_");
   str = str.split("\r").join("");
   str = str.split("\n").join("");
   str = str.split(String.fromCharCode(0)).join("");
   return str;
};

_global.coopCleanDNA = function(dna)
{
   var str = _global.coopCleanStr(dna);
   if(str == "")
   {
      return "";
   }
   var parts = str.split(",");
   if(parts.length > 0)
   {
      if(parts[0] == "" || parts[0] == "undefined" || parts[0] == "null")
      {
         parts[0] = "Gladiator";
      }
      var i = 1;
      while(i < parts.length)
      {
         if(parts[i] == "undefined" || parts[i] == "null" || parts[i] == "NaN")
         {
            parts[i] = (i == 28) ? "None" : "0";
         }
         i++;
      }
   }
   return parts.join(",");
};

_global.coopGetLocalDNA = function()
{
   if(_root.game != undefined && _root.game.hero != undefined)
   {
      if(typeof(_root.constructDNA) == "function")
      {
         _root.constructDNA();
      }
      if(_root.game.hero.charDNA != undefined && _root.game.hero.charDNA != "")
      {
         var cleaned = _global.coopCleanDNA(_root.game.hero.charDNA);
         if(_global.coop.role == "host")
         {
            _global.coop.p1DNA = cleaned;
         }
         else if(_global.coop.role == "client")
         {
            _global.coop.p2DNA = cleaned;
         }
         return cleaned;
      }
   }
   return "";
};

_global.coopInitHeroFromDNA = function(targetObj, dnaStr)
{
   if(targetObj == undefined || targetObj == null)
   {
      return;
   }
   var clean = _global.coopCleanDNA(dnaStr);
   if(clean == "")
   {
      return;
   }
   targetObj.charDNA = clean;
   var parts = clean.split(",");
   var savedGlobalDNA = _root.characterDNA;
   _root.characterDNA = parts;
   characterDNA = parts;
   var savedDay = _global.day;
   var dummy = _root.createEmptyMovieClip("__coop_dummy_avatar",99902);
   if(typeof(_root.initcharacter) == "function")
   {
      _root.initcharacter(targetObj,dummy,clean);
   }
   if(parts.length > 0 && parts[0] != "")
   {
      targetObj.character_name = parts[0];
      targetObj.hero_name = parts[0];
   }
   if(savedDay != undefined)
   {
      _global.day = savedDay;
   }
   _root.characterDNA = savedGlobalDNA;
   if(targetObj.statpoints == undefined || targetObj.statpoints == null || isNaN(Number(targetObj.statpoints)) || Number(targetObj.statpoints) < 0)
   {
      targetObj.statpoints = 0;
   }
   else
   {
      targetObj.statpoints = Number(targetObj.statpoints);
   }
   if(isNaN(Number(targetObj.herolevel)) || Number(targetObj.herolevel) < 1)
   {
      targetObj.herolevel = 1;
   }
   else if(Number(targetObj.herolevel) > 60)
   {
      targetObj.herolevel = 60;
   }
   if(isNaN(Number(targetObj.goldpieces)) || Number(targetObj.goldpieces) < 0)
   {
      targetObj.goldpieces = 0;
   }
   if(typeof(_root.battlevalues) == "function")
   {
      _root.battlevalues(targetObj);
   }
   if(typeof(_root.backup_char) == "function")
   {
      _root.backup_char(targetObj);
   }
   if(dummy != undefined)
   {
      dummy.removeMovieClip();
   }
};

_global.coopRestoreLocalHero = function()
{
   var c = _global.coop;
   if(c == undefined)
   {
      return;
   }
   if(c.role == "client" && (c.needRestoreLocalHero == true || c.localHeroBackup != null || (c.localHeroBackupDNA != null && c.localHeroBackupDNA != "")))
   {
      if(_root.game == undefined)
      {
         _root.game = new Object();
      }
      var keepGold = -1;
      var keepXp = -1;
      var keepLvl = -1;
      var keepWins = -1;
      var hadHero2 = (_root.game.hero2 != undefined && !isNaN(Number(_root.game.hero2.herolevel)));
      if(hadHero2)
      {
         if(!isNaN(Number(_root.game.hero2.goldpieces)))
         {
            keepGold = Number(_root.game.hero2.goldpieces);
         }
         if(!isNaN(Number(_root.game.hero2.experience)))
         {
            keepXp = Number(_root.game.hero2.experience);
         }
         if(!isNaN(Number(_root.game.hero2.herolevel)))
         {
            keepLvl = Number(_root.game.hero2.herolevel);
         }
         if(!isNaN(Number(_root.game.hero2.battleswon)))
         {
            keepWins = Number(_root.game.hero2.battleswon);
         }
      }
      if(typeof(c.localHeroBackup) == "object" && c.localHeroBackup != null && !isNaN(Number(c.localHeroBackup.herolevel)) && Number(c.localHeroBackup.herolevel) >= 1)
      {
         _root.game.hero = c.localHeroBackup;
         if(typeof(_root.backup_char) == "function")
         {
            _root.backup_char(_root.game.hero);
         }
      }
      else if(c.localHeroBackupDNA != null && c.localHeroBackupDNA != "")
      {
         _root.game.hero = new Object();
         _global.coopInitHeroFromDNA(_root.game.hero,c.localHeroBackupDNA);
      }
      else if(typeof(c.localHeroBackup) == "string" && c.localHeroBackup != "")
      {
         _root.game.hero = new Object();
         _global.coopInitHeroFromDNA(_root.game.hero,c.localHeroBackup);
      }
      else
      {
         c.needRestoreLocalHero = false;
         return;
      }
      if(_root.game.hero.statpoints == undefined || isNaN(Number(_root.game.hero.statpoints)) || Number(_root.game.hero.statpoints) < 0)
      {
         _root.game.hero.statpoints = 0;
      }
      if(isNaN(Number(_root.game.hero.goldpieces)) || Number(_root.game.hero.goldpieces) < 0)
      {
         _root.game.hero.goldpieces = 0;
      }
      if(keepGold >= 0 && keepGold > Number(_root.game.hero.goldpieces))
      {
         _root.game.hero.goldpieces = keepGold;
      }
      if(keepXp >= 0 && keepXp > Number(_root.game.hero.experience))
      {
         _root.game.hero.experience = keepXp;
      }
      if(keepLvl > Number(_root.game.hero.herolevel) && keepLvl <= 60)
      {
         _root.game.hero.herolevel = keepLvl;
      }
      if(keepWins >= 0 && keepWins > Number(_root.game.hero.battleswon))
      {
         _root.game.hero.battleswon = keepWins;
      }
      if(typeof(_root.backup_char) == "function")
      {
         _root.backup_char(_root.game.hero);
      }
      if(typeof(_root.battlevalues) == "function")
      {
         _root.battlevalues(_root.game.hero);
      }
      var wasTourney = (c.matchCfg != null && (c.matchCfg.mode == "tournament" || c.matchCfg.mode == "tourn"));
      if(wasTourney)
      {
         var syncedTourney = Number(c.matchCfg.tourney);
         if(!isNaN(syncedTourney) && syncedTourney >= 1)
         {
            _root.game.hero.current_tournament = syncedTourney;
         }
         var syncedRank = Number(c.matchCfg.ranking);
         if(!isNaN(syncedRank) && syncedRank >= 1)
         {
            _root.game.hero.tournament_ranking = syncedRank;
         }
         _global.tournament_in_progress = true;
         if(typeof(_root.unleash_hell) == "function" && _root.game.hero.current_tournament >= 1 && _root.game.hero.current_tournament <= 18)
         {
            _root.unleash_hell(_root.game.hero.current_tournament);
            if(_root.game.champion != undefined && _root.game.champion.charDNA != undefined)
            {
               var cName = _root.game.champion.character_name;
               var cQuote = _root.game.champion.character_quote;
               var cHat = _root.game.champion.hat_name;
               _global.coopInitHeroFromDNA(_root.game.champion,_root.game.champion.charDNA);
               if(cName != undefined && cName != "")
               {
                  _root.game.champion.character_name = cName;
               }
               _root.game.champion.character_quote = cQuote;
               _root.game.champion.hat_name = cHat;
            }
         }
      }
      else
      {
         _global.tournament_in_progress = c.localTournamentInProgress;
         _root.game.champion = c.localTournamentChampion;
      }
      if(typeof(_root.constructDNA) == "function")
      {
         var prevEn = c.enabled;
         var prevAr = c.inArena;
         c.enabled = false;
         c.inArena = false;
         _root.constructDNA();
         c.enabled = prevEn;
         c.inArena = prevAr;
      }
      c.needRestoreLocalHero = false;
      c.localHeroBackup = null;
      c.localHeroBackupDNA = null;
      c.localTournamentChampion = null;
      if(_root.game.hero.charDNA != undefined && _root.game.hero.charDNA != "")
      {
         c.p2DNA = _global.coopCleanDNA(_root.game.hero.charDNA);
      }
   }
};

_global.coopSaveLocalHero = function()
{
   var c = _global.coop;
   if(_root.game == undefined || _root.game.hero == undefined)
   {
      return;
   }
   var prevInArena = (c != undefined) ? c.inArena : false;
   if(c != undefined)
   {
      c.inArena = false;
   }
   if(typeof(_root.constructDNA) == "function")
   {
      _root.constructDNA();
   }
   var charIdx = (_global.current_character != undefined && !isNaN(Number(_global.current_character)) && Number(_global.current_character) >= 1) ? Number(_global.current_character) : 1;
   if(typeof(_root.save_character) == "function")
   {
      _root.save_character(charIdx);
   }
   if(c != undefined)
   {
      c.inArena = prevInArena;
      var clean = _global.coopCleanDNA(_root.game.hero.charDNA);
      if(clean != "")
      {
         if(c.role == "host")
         {
            c.p1DNA = clean;
         }
         else if(c.role == "client")
         {
            c.p2DNA = clean;
         }
         if(c.connected == true)
         {
            _global.coopSend("hello",{role:c.role, dna:clean});
         }
      }
   }
};

_global.coopParseMessage = function(src)
{
   if(src == undefined || src == null)
   {
      return null;
   }
   var s = String(src);
   while(s.length > 0)
   {
      var code = s.charCodeAt(s.length - 1);
      if(code == 0 || code == 10 || code == 13)
      {
         s = s.substr(0,s.length - 1);
      }
      else
      {
         break;
      }
   }
   if(s.indexOf("COOP|") != 0)
   {
      return null;
   }
   var parts = s.split("|");
   var out = new Object();
   var i = 1;
   while(i < parts.length)
   {
      var seg = parts[i];
      var eq = seg.indexOf("=");
      if(eq > 0)
      {
         var k = seg.substr(0,eq);
         var v = seg.substr(eq + 1);
         out[k] = v;
      }
      i++;
   }
   return out;
};

_global.coopSend = function(msgType, kvObj)
{
   var c = _global.coop;
   if(c == undefined || c.sock == null || c.connected != true)
   {
      return false;
   }
   var msg = "COOP|t=" + _global.coopCleanStr(msgType);
   if(kvObj != undefined && kvObj != null)
   {
      for(var k in kvObj)
      {
         var ck = _global.coopCleanStr(k);
         if(ck != "" && ck != "t")
         {
            msg += "|" + ck + "=" + _global.coopCleanStr(kvObj[k]);
         }
      }
   }
   return c.sock.send(msg);
};

_global.coopQuickChar = function(customName, lvl)
{
   var c = _global.coop;
   var targetLvl = Number(lvl);
   if(isNaN(targetLvl) || targetLvl < 1)
   {
      targetLvl = 3;
   }
   var charName = _global.coopCleanStr(customName);
   if(charName == "")
   {
      if(c.role == "client")
      {
         charName = "CoopP2";
      }
      else
      {
         charName = "CoopP1";
      }
   }
   c.pendingQuickChar = {name:charName, lvl:targetLvl};
   if(typeof(_root.initsystem) == "function" && typeof(_root.constructDNA) == "function")
   {
      _global.coopExecuteQuickChar();
   }
   else
   {
      _root.gotoAndPlay("new_or_continue");
   }
};

_global.coopExecuteQuickChar = function()
{
   var c = _global.coop;
   if(c.pendingQuickChar == null)
   {
      return;
   }
   if(typeof(_root.initsystem) != "function" || typeof(_root.constructDNA) != "function")
   {
      return;
   }
   var cfg = c.pendingQuickChar;
   c.pendingQuickChar = null;
   _root.initsystem();
   if(_root.game == undefined)
   {
      _root.game = new Object();
   }
   if(_root.game.hero == undefined)
   {
      _root.game.hero = new Object();
   }
   var h = _root.game.hero;
   h.character_name = cfg.name;
   h.hero_name = cfg.name;
   h.herolevel = cfg.lvl;
   h.strength = 6 + cfg.lvl;
   h.speed = 6 + cfg.lvl;
   h.attack = 7 + cfg.lvl;
   h.defence = 6 + cfg.lvl;
   h.vitality = 8 + cfg.lvl;
   h.charisma = 5;
   h.stamina = 7 + cfg.lvl;
   h.magicka = 5;
   h.weapon = 4;
   h.shield = 2;
   h.breastplate = 3;
   h.helmet = 2;
   h.greaves = 2;
   h.goldpieces = 1000;
   h.inventory1 = 3;
   h.inventory2 = 30;
   h.inventory_maxslots = 2;
   h.equipped_weapon = 1;
   h.statpoints = 0;
   h.experience = 0;
   h.battlesfought = 0;
   h.battleswon = 0;
   h.battleslost = 0;
   h.days_in_arena = 1;
   _root.constructDNA();
   if(typeof(_root.backup_char) == "function")
   {
      _root.backup_char(h);
   }
   if(typeof(_root.save_character) == "function")
   {
      _global.current_character = 1;
      _root.save_character(1);
   }
   _global.gamephase = 2;
   _global.time_of_day = 24;
   _global.coopGetLocalDNA();
   _root.hero.removeMovieClip();
   c.townEntered = false;
   _root.gotoAndPlay("townsquare");
};

_global.coopEnsureQAWatchdog = function()
{
   if(_root.__coop_watchdog != undefined)
   {
      return;
   }
   var wd = _root.createEmptyMovieClip("__coop_watchdog",99901);
   wd.onEnterFrame = function()
   {
      var c = _global.coop;
      if(c == undefined)
      {
         return;
      }
      if(_root.bug == true || (_root._currentframe >= 242 && _root._currentframe <= 261))
      {
         c.bugsHit = true;
      }
      if(c.pendingQuickChar != null && typeof(_root.initsystem) == "function" && typeof(_root.constructDNA) == "function")
      {
         _global.coopExecuteQuickChar();
      }
      if(c.autoMode == "auto_duel" && c.autoStarted != true && c.connected == true)
      {
         if(_root._currentframe < 35 && c.pendingQuickChar == null && (_root.game == undefined || _root.game.hero == undefined))
         {
            _global.coopQuickChar(null,3);
         }
         else if(_root._currentframe > 150 && _root._currentframe < 214 && c.townEntered == true && c.inArena != true)
         {
            var myReady = (c.role == "host") ? c.p1Ready : c.p2Ready;
            if(!myReady)
            {
               _global.coopSetReady(true);
            }
            if(c.role == "host" && c.p1Ready == true && c.p2Ready == true && c.p1DNA != null && c.p1DNA != "" && c.p2DNA != null && c.p2DNA != "")
            {
               c.autoStarted = true;
               _global.coopHostStartDuel(1);
            }
         }
      }
      if((c.autoMode == "auto_duel" || c.autoMode == "auto_combat") && c.inArena == true && c._autoArenaJumped != true && _root._currentframe == 220)
      {
         c._autoArenaJumped = true;
         _root.gotoAndPlay("arena");
      }
      else if(c.enterPending == true && _root._currentframe == 220)
      {
         c.enterPending = false;
         _root.gotoAndPlay("arena");
      }
   };
};

_global.coopApplyStartMatch = function(m)
{
   var c = _global.coop;
   var mode = "duel";
   if(m.mode != undefined && m.mode != "")
   {
      mode = String(m.mode);
   }
   var bossId = Number(m.boss);
   if(isNaN(bossId))
   {
      bossId = 0;
   }
   var arenaId = Math.floor(Number(m.arena));
   if(isNaN(arenaId) || arenaId < 1 || arenaId > 6)
   {
      arenaId = 1;
   }
   var tod = Number(m.tod);
   if(isNaN(tod))
   {
      tod = 24;
   }
   var seed = Number(m.seed);
   if(isNaN(seed))
   {
      seed = 1337;
   }
   var p1dna = _global.coopCleanDNA(m.p1dna);
   var p2dna = _global.coopCleanDNA(m.p2dna);
   var vdna = _global.coopCleanDNA(m.vdna);
   var vname = "Challenger";
   if(m.vname != undefined && m.vname != "")
   {
      vname = _global.coopCleanStr(m.vname);
   }
   var ranking = Number(m.ranking);
   if(isNaN(ranking) || ranking < 1)
   {
      ranking = 2;
   }
   var tourney = Number(m.tourney);
   if(isNaN(tourney) || tourney < 1)
   {
      if(bossId >= 1 && bossId <= 18)
      {
         tourney = bossId;
      }
      else
      {
         var p1Arr = p1dna.split(",");
         if(p1Arr.length > 30 && !isNaN(Number(p1Arr[30])) && Number(p1Arr[30]) >= 1)
         {
            tourney = Number(p1Arr[30]);
         }
         else if(_root.game != undefined && _root.game.hero != undefined && !isNaN(Number(_root.game.hero.current_tournament)) && Number(_root.game.hero.current_tournament) >= 1)
         {
            tourney = Number(_root.game.hero.current_tournament);
         }
         else
         {
            tourney = 1;
         }
      }
   }
   var isTourney = (mode == "tournament" || mode == "tourn");
   if(c.role == "client" && c.needRestoreLocalHero != true)
   {
      c.localTournamentInProgress = isTourney ? true : _global.tournament_in_progress;
      c.localTournamentChampion = _root.game.champion;
   }

   if(_root.game != undefined && _root.game.hero != undefined && typeof(_root.game.hero) == "object")
   {
      if(c.role == "host" || c.needRestoreLocalHero != true)
      {
         if(typeof(_root.constructDNA) == "function")
         {
            _root.constructDNA();
         }
         if(typeof(_root.backup_char) == "function")
         {
            _root.backup_char(_root.game.hero);
         }
         if(_root.game.hero.charDNA != undefined && _root.game.hero.charDNA != "")
         {
            c.localHeroBackup = _root.game.hero;
            c.localHeroBackupDNA = String(_root.game.hero.charDNA);
            if(c.role == "client")
            {
               c.needRestoreLocalHero = true;
               if(isTourney)
               {
                  c.localHeroBackup.current_tournament = tourney;
                  c.localHeroBackup.tournament_ranking = ranking;
               }
            }
         }
      }
   }

   c.p1DNA = p1dna;
   c.p2DNA = p2dna;
   c.matchCfg = {
      mode:mode,
      boss:bossId,
      arena:arenaId,
      tod:tod,
      seed:seed,
      vdna:vdna,
      vname:vname,
      hat:m.hat,
      tourney:tourney,
      ranking:ranking,
      p1dna:p1dna,
      p2dna:p2dna
   };
   c.enabled = true;
   c.playerCount = 1 + (p2dna != "" ? 1 : 0);
   c.activeTurn = 1;
   c.turnSlot = 1;
   c.targetHero = 1;
   c.pendingRemoteAct = null;
   c.pendingRemoteBoss = null;
   c.pendingSync = null;
   c.lastSync = null;
   c.syncSeq = 0;
   c.lastAppliedSyncSeq = 0;
   c.awaitingSync = false;
   c.lastOutcome = null;
   c._autoArenaJumped = false;
   c.enterPending = false;
   c.townEntered = false;
   c.inArena = true;
   c.statusText = "Starting 2v1 Arena...";
   _global.coopSrand(seed);
   _global.battle_started = false;

   if(_root.game == undefined)
   {
      _root.game = new Object();
   }
   var hostStatPts = 0;
   if(c.role == "host" && _root.game.hero != undefined && !isNaN(Number(_root.game.hero.statpoints)) && Number(_root.game.hero.statpoints) >= 0)
   {
      hostStatPts = Number(_root.game.hero.statpoints);
   }
   _root.game.hero = new Object();
   _global.coopInitHeroFromDNA(_root.game.hero,p1dna);
   _root.game.hero.current_tournament = tourney;
   _root.game.hero.tournament_ranking = ranking;
   if(c.role == "host")
   {
      _root.game.hero.statpoints = hostStatPts;
   }
   _global.heroDNA = p1dna;

   _root.game.hero2 = new Object();
   _global.coopInitHeroFromDNA(_root.game.hero2,p2dna);

   var bossQuote = m.quote;
   var bossHat = m.hat;
   if(bossId >= 1 && bossId <= 18 && typeof(_root.unleash_hell) == "function")
   {
      var savedChamp = _root.game.champion;
      var savedVil = _root.game.villain;
      _root.unleash_hell(bossId);
      if(bossQuote == undefined || bossQuote == "")
      {
         bossQuote = _root.game.champion.character_quote;
      }
      if(bossHat == undefined || bossHat == "")
      {
         bossHat = _root.game.champion.hat_name;
      }
      _root.game.champion = savedChamp;
      _root.game.villain = savedVil;
   }
   _root.game.villain = new Object();
   _global.coopInitHeroFromDNA(_root.game.villain,vdna);
   _root.game.villain.character_name = vname;
   _root.game.villain.hero_name = vname;
   _root.game.villain.hat_name = (bossHat != undefined && bossHat != "") ? String(bossHat) : vname;
   _root.game.villain.character_quote = bossQuote;
   if(isNaN(Number(_root.game.villain.character_xp)) || Number(_root.game.villain.character_xp) <= 0)
   {
      _root.game.villain.character_xp = Math.max(150,Number(_root.game.villain.herolevel) * 200);
   }
   if(bossId >= 1 && bossId <= 18)
   {
      _root.game.champion = _root.game.villain;
   }

   _global.fight_mode = mode;
   _global.current_arena = arenaId;
   _global.time_of_day = tod;
   _global.tournament_in_progress = isTourney;
   _global.fightstarted = true;
   _global.battle_started = false;

   _global.coopHideLobby();
   _root.gotoAndPlay("arena_intro");
};

_global.coopHandleQA = function(m)
{
   var c = _global.coop;
   var cmd = String(m.cmd);
   if(cmd == "ping")
   {
      _global.coopSend("qa",{cmd:"pong", role:c.role, frame:_root._currentframe, inArena:c.inArena});
   }
   else if(cmd == "status")
   {
      var gm = _root.game;
      var h1hp = (gm != undefined && gm.hero != undefined) ? Number(gm.hero.hitpoints) : -1;
      var h2hp = (gm != undefined && gm.hero2 != undefined) ? Number(gm.hero2.hitpoints) : -1;
      var vhp = (gm != undefined && gm.villain != undefined) ? Number(gm.villain.hitpoints) : -1;
      var h1arm = (gm != undefined && gm.hero != undefined) ? Number(gm.hero.armourclass) : -1;
      var h2arm = (gm != undefined && gm.hero2 != undefined) ? Number(gm.hero2.armourclass) : -1;
      var varm = (gm != undefined && gm.villain != undefined) ? Number(gm.villain.armourclass) : -1;
      var gl = (_root.arena != undefined) ? _root.arena.gladiators : undefined;
      var h1x = (gl != undefined && gl.hero != undefined) ? Math.round(gl.hero._x) : -1;
      var h2x = (gl != undefined && gl.hero2 != undefined) ? Math.round(gl.hero2._x) : -1;
      var vx = (gl != undefined && gl.villain != undefined) ? Math.round(gl.villain._x) : -1;
      var h1f = (gl != undefined && gl.hero != undefined) ? Number(gl.hero._currentframe) : -1;
      var h2f = (gl != undefined && gl.hero2 != undefined) ? Number(gl.hero2._currentframe) : -1;
      var vf = (gl != undefined && gl.villain != undefined) ? Number(gl.villain._currentframe) : -1;
      var outStr = (c.lastOutcome != null) ? String(c.lastOutcome) : "";
      var isBugs = (c.bugsHit == true || _root.bug == true || (_root._currentframe >= 242 && _root._currentframe <= 261)) ? 1 : 0;
      _global.coopSend("qa",{
         cmd:"status_ack",
         role:c.role,
         enabled:c.enabled,
         connected:c.connected,
         p1Ready:c.p1Ready,
         p2Ready:c.p2Ready,
         inArena:c.inArena,
         turn:c.activeTurn,
         frame:_root._currentframe,
         foyer:_root.foyer._currentframe,
         mode:_global.fight_mode,
         tourney:gm.hero.current_tournament,
         ranking:gm.hero.tournament_ranking,
         inProgress:_global.tournament_in_progress,
         gold:gm.hero.goldpieces,
         xp:gm.hero.experience,
         vxp:gm.villain.character_xp,
         opponent:gm.villain.character_name,
         vmax:gm.villain.hitpointsmax,
         vsmax:gm.villain.staminamax,
         vamax:gm.villain.armourclass_max,
         h2max:gm.hero2.hitpointsmax,
         h2energy:gm.hero2.staminaleft,
         h2energymax:gm.hero2.staminamax,
         h2armormax:gm.hero2.armourclass_max,
         p1healthHud:_root.arena.combat_panel.hero_potion.hitpoints,
         p2healthHud:_root.arena.coop_hud.stat2.value.text,
         p2energyHud:_root.arena.coop_hud.stat3.value.text,
         p2armorHud:_root.arena.coop_hud.stat4.value.text,
         arena:_global.current_arena,
         introCrowd:_root.crowd._currentframe,
         arenaCrowd:_root.arena.crowd._currentframe,
         arenaSand:_root.arena.sand._currentframe,
         shadow1:(_global.coop.testMode == true && gl.hero_shadow != undefined) ? [Math.round(gl.hero_shadow._x),gl.hero_shadow._y,gl.hero_shadow._currentframe].join(",") : "",
         shadow2:(_global.coop.testMode == true && gl.hero2_shadow != undefined) ? [Math.round(gl.hero2_shadow._x),gl.hero2_shadow._y,gl.hero2_shadow._currentframe].join(",") : "",
         shadowV:(_global.coop.testMode == true && gl.villain_shadow != undefined) ? [Math.round(gl.villain_shadow._x),gl.villain_shadow._y,gl.villain_shadow._currentframe].join(",") : "",
         h1hp:h1hp,
         h2hp:h2hp,
         vhp:vhp,
         h1arm:h1arm,
         h2arm:h2arm,
         varm:varm,
         h1x:h1x,
         h2x:h2x,
         vx:vx,
         h1f:h1f,
         h2f:h2f,
         vf:vf,
         outcome:outStr,
         bugs:isBugs
      });
   }
   else if(cmd == "quick_char")
   {
      _global.coopQuickChar(m.name,m.lvl);
   }
   else if(cmd == "ready")
   {
      _global.coopSetReady(true);
   }
   else if(cmd == "host_duel")
   {
      if(c.role == "host")
      {
         _global.coopHostStartDuel(m.arena);
      }
   }
   else if(cmd == "host_boss")
   {
      if(c.role == "host")
      {
         var bId = Number(m.boss);
         if(isNaN(bId) || bId < 1)
         {
            bId = 1;
         }
         _global.coopHostStartMatch("duel",bId,m.arena);
      }
   }
   else if(cmd == "foyer" && c.testMode == true && c.inArena != true)
   {
      _root.gotoAndPlay("foyer");
   }
   else if(cmd == "story_register" && c.testMode == true && _root.foyer != undefined)
   {
      _global.fight_mode = "tournament";
      _root.foyer.gotoAndPlay("tournament");
   }
   else if(cmd == "set_ranking" && c.testMode == true && _root.game != undefined && _root.game.hero != undefined)
   {
      var rVal = Number(m.ranking);
      if(!isNaN(rVal) && rVal >= 1)
      {
         _root.game.hero.tournament_ranking = rVal;
      }
      var tVal = Number(m.tourney);
      if(!isNaN(tVal) && tVal >= 1)
      {
         _root.game.hero.current_tournament = tVal;
      }
   }
   else if(cmd == "story_fight" && c.testMode == true && _root.foyer != undefined)
   {
      _global.coopStartStoryFight(String(m.mode),m.mode == "tournament" ? _global.current_arena : 1);
   }
   else if(cmd == "story_enter" && c.testMode == true && _root._currentframe == 220)
   {
      _global.coopConfirmIntro();
   }
   else if(cmd == "enter_arena")
   {
      if(_root._currentframe >= 214 && _root._currentframe <= 220)
      {
         c._autoArenaJumped = true;
         _root.gotoAndPlay("arena");
      }
   }
   else if(cmd == "act")
   {
      if(_root.arena != undefined && _root.arena.gladiators != undefined && _root.arena.gladiators.overlay != undefined && typeof(_root.arena.gladiators.overlay.getphase) == "function")
      {
         _root.arena.gladiators.overlay.getphase(String(m.action));
      }
   }
};

_global.coopApplySync = function(s)
{
   if(s == undefined || s == null)
   {
      return false;
   }
   var c = _global.coop;
   if(s.seq != undefined && !isNaN(Number(s.seq)))
   {
      c.lastAppliedSyncSeq = Number(s.seq);
   }
   if(s.turn != undefined && !isNaN(Number(s.turn)))
   {
      c.activeTurn = Number(s.turn);
      c.turnSlot = Number(s.turn);
   }
   if(s.seed != undefined && !isNaN(Number(s.seed)))
   {
      _global.coopSrand(Number(s.seed));
   }
   var gm = _root.game;
   if(gm != undefined)
   {
      if(gm.hero != undefined)
      {
         if(s.h1hp != undefined && !isNaN(Number(s.h1hp)))
         {
            gm.hero.hitpoints = Math.max(0,Number(s.h1hp));
         }
         if(s.h1stam != undefined && !isNaN(Number(s.h1stam)))
         {
            gm.hero.staminaleft = Math.max(0,Number(s.h1stam));
         }
         if(s.h1arm != undefined && !isNaN(Number(s.h1arm)))
         {
            gm.hero.armourclass = Math.max(0,Number(s.h1arm));
         }
         if(s.dead1 == 1)
         {
            gm.hero.hitpoints = 0;
         }
      }
      if(gm.hero2 != undefined)
      {
         if(s.h2hp != undefined && !isNaN(Number(s.h2hp)))
         {
            gm.hero2.hitpoints = Math.max(0,Number(s.h2hp));
         }
         if(s.h2stam != undefined && !isNaN(Number(s.h2stam)))
         {
            gm.hero2.staminaleft = Math.max(0,Number(s.h2stam));
         }
         if(s.h2arm != undefined && !isNaN(Number(s.h2arm)))
         {
            gm.hero2.armourclass = Math.max(0,Number(s.h2arm));
         }
         if(s.dead2 == 1)
         {
            gm.hero2.hitpoints = 0;
         }
      }
      if(gm.villain != undefined)
      {
         if(s.vhp != undefined && !isNaN(Number(s.vhp)))
         {
            gm.villain.hitpoints = Math.max(0,Number(s.vhp));
         }
         if(s.vstam != undefined && !isNaN(Number(s.vstam)))
         {
            gm.villain.staminaleft = Math.max(0,Number(s.vstam));
         }
         if(s.varm != undefined && !isNaN(Number(s.varm)))
         {
            gm.villain.armourclass = Math.max(0,Number(s.varm));
         }
         if(s.vdead == 1)
         {
            gm.villain.hitpoints = 0;
         }
      }
   }
   var g = (_root.arena != undefined) ? _root.arena.gladiators : undefined;
   if(g != undefined)
   {
      if(g.hero != undefined)
      {
         if(s.h1x != undefined && !isNaN(Number(s.h1x)))
         {
            g.hero._x = Number(s.h1x);
            if(g.hero_shadow != undefined)
            {
               g.hero_shadow._x = g.hero._x;
            }
         }
         if(s.h1xs != undefined && !isNaN(Number(s.h1xs)) && Number(s.h1xs) != 0)
         {
            g.hero._xscale = Number(s.h1xs);
            g.hero.gladiator_dir = (Number(s.h1xs) >= 0) ? "right" : "left";
         }
         if(s.dead1 == 1 && g.hero.coopKO != true)
         {
            g.hero.coopKO = true;
            g.hero.gotoAndPlay("Death1");
         }
      }
      if(g.hero2 != undefined)
      {
         if(s.h2x != undefined && !isNaN(Number(s.h2x)))
         {
            g.hero2._x = Number(s.h2x);
            if(g.hero2_shadow != undefined)
            {
               g.hero2_shadow._x = g.hero2._x;
            }
         }
         if(s.h2xs != undefined && !isNaN(Number(s.h2xs)) && Number(s.h2xs) != 0)
         {
            g.hero2._xscale = Number(s.h2xs);
            g.hero2.gladiator_dir = (Number(s.h2xs) >= 0) ? "right" : "left";
         }
         if(s.dead2 == 1 && g.hero2.coopKO != true)
         {
            g.hero2.coopKO = true;
            g.hero2.gotoAndPlay("Death1");
         }
      }
      if(g.villain != undefined)
      {
         if(s.vx != undefined && !isNaN(Number(s.vx)))
         {
            g.villain._x = Number(s.vx);
            if(g.villain_shadow != undefined)
            {
               g.villain_shadow._x = g.villain._x;
            }
         }
         if(s.vxs != undefined && !isNaN(Number(s.vxs)) && Number(s.vxs) != 0)
         {
            g.villain._xscale = Number(s.vxs);
            g.villain.gladiator_dir = (Number(s.vxs) >= 0) ? "right" : "left";
         }
      }
   }
   c.awaitingSync = false;
   return true;
};

_global.coopConsumePendingSync = function()
{
   var c = _global.coop;
   if(c == undefined || c.pendingSync == null)
   {
      return false;
   }
   var s = c.pendingSync;
   c.pendingSync = null;
   return _global.coopApplySync(s);
};

_global.coopHandleMessage = function(m)
{
   if(m == null)
   {
      return;
   }
   var c = _global.coop;
   var t = String(m.t);
   if(t == "hello")
   {
      c.peerConnected = true;
      var peerDna = _global.coopCleanDNA(m.dna);
      if(c.role == "host")
      {
         if(peerDna != "")
         {
            c.p2DNA = peerDna;
         }
         c.statusText = (peerDna != "") ? "Client connected (P2 synced)" : "Client connected";
      }
      else
      {
         if(peerDna != "")
         {
            c.p1DNA = peerDna;
         }
         c.statusText = (peerDna != "") ? "Host connected (P1 synced)" : "Host connected";
      }
      if(m.reply != "1")
      {
         _global.coopSend("hello",{role:c.role, dna:_global.coopGetLocalDNA(), reply:"1"});
      }
      _global.coopRefreshLobbyUI();
   }
   else if(t == "ready")
   {
      c.peerConnected = true;
      var isR = (m.ready == "1" || m.ready == "true");
      var rDna = _global.coopCleanDNA(m.dna);
      if(m.role == "client")
      {
         c.p2Ready = isR;
         if(rDna != "")
         {
            c.p2DNA = rDna;
         }
      }
      else if(m.role == "host")
      {
         c.p1Ready = isR;
         if(rDna != "")
         {
            c.p1DNA = rDna;
         }
      }
      c.statusText = "P1:" + (c.p1Ready ? "READY" : "wait") + " | P2:" + (c.p2Ready ? "READY" : "wait");
      _global.coopRefreshLobbyUI();
   }
   else if(t == "start")
   {
      _global.coopApplyStartMatch(m);
   }
   else if(t == "enter" && c.role == "client" && c.inArena == true)
   {
      c.enterPending = true;
   }
   else if(t == "cancel" && c.inArena == true && _root._currentframe >= 214 && _root._currentframe <= 220)
   {
      _global.coopCancelIntro();
   }
   else if(t == "act")
   {
      c.pendingRemoteAct = {
         actor:Number(m.actor),
         action:String(m.action),
         inv:(m.inv != undefined && m.inv != "") ? Number(m.inv) : 0,
         seed:(m.seed != undefined && m.seed != "") ? Number(m.seed) : c.seed
      };
   }
   else if(t == "boss")
   {
      c.pendingRemoteBoss = {
         action:String(m.action),
         inv:(m.inv != undefined && m.inv != "") ? Number(m.inv) : 0,
         target:(m.target != undefined && m.target != "") ? Number(m.target) : 1,
         seed:(m.seed != undefined && m.seed != "") ? Number(m.seed) : c.seed
      };
   }
   else if(t == "sync")
   {
      var syncObj = {
         seq:(m.seq != undefined && m.seq != "") ? Number(m.seq) : (c.lastAppliedSyncSeq + 1),
         turn:Number(m.turn),
         seed:(m.seed != undefined && m.seed != "") ? Number(m.seed) : c.seed,
         h1x:Number(m.h1x),
         h2x:Number(m.h2x),
         vx:Number(m.vx),
         h1xs:(m.h1xs != undefined && m.h1xs != "") ? Number(m.h1xs) : undefined,
         h2xs:(m.h2xs != undefined && m.h2xs != "") ? Number(m.h2xs) : undefined,
         vxs:(m.vxs != undefined && m.vxs != "") ? Number(m.vxs) : undefined,
         h1hp:Number(m.h1hp),
         h2hp:Number(m.h2hp),
         vhp:Number(m.vhp),
         h1stam:(m.h1stam != undefined && m.h1stam != "") ? Number(m.h1stam) : undefined,
         h2stam:(m.h2stam != undefined && m.h2stam != "") ? Number(m.h2stam) : undefined,
         vstam:(m.vstam != undefined && m.vstam != "") ? Number(m.vstam) : undefined,
         h1arm:(m.h1arm != undefined && m.h1arm != "") ? Number(m.h1arm) : undefined,
         h2arm:(m.h2arm != undefined && m.h2arm != "") ? Number(m.h2arm) : undefined,
         varm:(m.varm != undefined && m.varm != "") ? Number(m.varm) : undefined,
         dead1:(m.dead1 == "1" || m.dead1 == "true") ? 1 : 0,
         dead2:(m.dead2 == "1" || m.dead2 == "true") ? 1 : 0,
         vdead:(m.vdead == "1" || m.vdead == "true") ? 1 : 0
      };
      c.lastSync = syncObj;
      c.pendingSync = syncObj;
   }
   else if(t == "end")
   {
      c.lastOutcome = String(m.outcome);
      c.inArena = false;
      if(c.peerConnected != true)
      {
         c.p1Ready = false;
         c.p2Ready = false;
      }
      c.statusText = "Match ended: " + c.lastOutcome;
      _global.coopRefreshLobbyUI();
   }
   else if(t == "qa")
   {
      _global.coopHandleQA(m);
   }
};

_global.coopDisconnect = function()
{
   var c = _global.coop;
   if(c == undefined)
   {
      return;
   }
   if(c.sock != null)
   {
      c.sock.onConnect = null;
      c.sock.onData = null;
      c.sock.onClose = null;
      c.sock.close();
      c.sock = null;
   }
   c.connected = false;
   c.peerConnected = false;
   c.p1Ready = false;
   c.p2Ready = false;
   c.enabled = false;
   c.inArena = false;
   c.statusText = "Disconnected";
   _global.coopRefreshLobbyUI();
};

_global.coopConnect = function(role, port)
{
   var c = _global.coop;
   _global.coopDisconnect();
   if(role != "host" && role != "client")
   {
      role = "host";
   }
   var usePort = Number(port);
   if(isNaN(usePort) || usePort <= 0)
   {
      usePort = (role == "host") ? 19801 : 19802;
   }
   c.role = role;
   c.localActor = (role == "host") ? 1 : 2;
   c.port = usePort;
   c.statusText = "Connecting as " + role.toUpperCase() + " on 127.0.0.1:" + usePort + "...";

   var s = new XMLSocket();
   s.onConnect = function(success)
   {
      var co = _global.coop;
      if(success)
      {
         co.connected = true;
         co.statusText = "Connected (" + co.role + ":" + co.port + ")";
         var myDNA = _global.coopGetLocalDNA();
         _global.coopSend("hello",{role:co.role, dna:myDNA});
      }
      else
      {
         co.connected = false;
         co.statusText = "Failed to connect on :" + co.port + " (is relay running?)";
      }
      _global.coopRefreshLobbyUI();
   };
   s.onData = function(src)
   {
      var parsed = _global.coopParseMessage(src);
      if(parsed != null)
      {
         _global.coopHandleMessage(parsed);
      }
   };
   s.onClose = function()
   {
      var co = _global.coop;
      co.connected = false;
      co.peerConnected = false;
      co.statusText = "Connection closed";
      _global.coopRefreshLobbyUI();
   };
   c.sock = s;
   s.connect("127.0.0.1",usePort);
   _global.coopRefreshLobbyUI();
};

_global.coopSetReady = function(flag)
{
   var c = _global.coop;
   if(c.connected != true)
   {
      c.statusText = "Connect to relay first";
      _global.coopRefreshLobbyUI();
      return;
   }
   if(typeof(_root.initcharacter) != "function" || typeof(_root.constructDNA) != "function")
   {
      c.statusText = "Enter game (create/load gladiator) first";
      _global.coopRefreshLobbyUI();
      return;
   }
   var myDNA = _global.coopGetLocalDNA();
   if(myDNA == "")
   {
      c.statusText = "Create or load a gladiator first";
      _global.coopRefreshLobbyUI();
      return;
   }
   var r = (flag == true);
   if(c.role == "host")
   {
      c.p1DNA = myDNA;
      c.p1Ready = r;
   }
   else
   {
      c.p2DNA = myDNA;
      c.p2Ready = r;
   }
   _global.coopSend("ready",{role:c.role, ready:(r ? "1" : "0"), dna:myDNA});
   c.statusText = "P1:" + (c.p1Ready ? "READY" : "wait") + " | P2:" + (c.p2Ready ? "READY" : "wait");
   _global.coopRefreshLobbyUI();
};

_global.coopHostStartMatch = function(mode, bossId, arenaId, opponent)
{
   var c = _global.coop;
   if(c.role != "host")
   {
      c.statusText = "Only Host can start match";
      _global.coopRefreshLobbyUI();
      return false;
   }
   if(c.connected != true)
   {
      c.statusText = "Not connected to relay";
      _global.coopRefreshLobbyUI();
      return false;
   }
   var p1dna = _global.coopGetLocalDNA();
   if(p1dna == "")
   {
      c.statusText = "Host needs a loaded gladiator";
      _global.coopRefreshLobbyUI();
      return false;
   }
   var p2dna = _global.coopCleanDNA(c.p2DNA);
   if(p2dna == "")
   {
      c.statusText = "Waiting for P2 gladiator DNA";
      _global.coopRefreshLobbyUI();
      return false;
   }
   if(typeof(_root.randomise_gladiator) != "function" || typeof(_root.unleash_hell) != "function")
   {
      c.statusText = "Enter game (Townsquare/Foyer) before starting";
      _global.coopRefreshLobbyUI();
      return false;
   }

   var useMode = (mode != undefined && mode != "") ? String(mode) : "duel";
   var bId = Math.floor(Number(bossId));
   if(isNaN(bId) || bId < 0 || bId > 18)
   {
      bId = 0;
   }
   var seed = 1000 + Math.floor(Math.random() * 900000);
   _global.coopSrand(seed);

   var aId = Math.floor(Number(arenaId));
   if(isNaN(aId) || aId < 1 || aId > 6)
   {
      aId = _global.coopRandBetween(1,6);
   }
   var tod = (_global.time_of_day != undefined && !isNaN(Number(_global.time_of_day))) ? Number(_global.time_of_day) : 24;

   if(_root.game == undefined)
   {
      _root.game = new Object();
   }
   var prevEnabled = c.enabled;
   var prevInArena = c.inArena;
   var prevBattle = _global.battle_started;
   _global.battle_started = false;
   if(opponent == undefined || (bId >= 1 && bId <= 18))
   {
      _root.game.villain = new Object();
   }
   var vname = "Challenger";
   if(bId >= 1 && bId <= 18)
   {
      _root.unleash_hell(bId);
      var bossName = _root.game.champion.character_name;
      var bossQuote = _root.game.champion.character_quote;
      var bossHat = _root.game.champion.hat_name;
      _global.coopInitHeroFromDNA(_root.game.champion,_root.game.champion.charDNA);
      if(bossName != undefined && bossName != "")
      {
         _root.game.champion.character_name = bossName;
         _root.game.champion.hero_name = bossName;
      }
      _root.game.champion.character_quote = bossQuote;
      _root.game.champion.hat_name = bossHat;
      _root.game.villain = _root.game.champion;
      if(_root.game.villain.character_name != undefined && _root.game.villain.character_name != "")
      {
         vname = String(_root.game.villain.character_name);
      }
      else if(_root.game.villain.hat_name != undefined && _root.game.villain.hat_name != "")
      {
         vname = String(_root.game.villain.hat_name);
      }
   }
   else if(opponent != undefined)
   {
      _root.game.villain = opponent;
      if(_root.game.villain.charDNA == undefined || _root.game.villain.charDNA == "" || _root.game.villain.charDNA.indexOf("undefined") >= 0)
      {
         _root.constructvillainDNA(_root.game.villain);
      }
      vname = String(_root.game.villain.character_name);
   }
   else
   {
      var p1Parts = p1dna.split(",");
      var p2Parts = p2dna.split(",");
      var p1Lvl = Number(p1Parts[24]);
      var p2Lvl = Number(p2Parts[24]);
      if(isNaN(p1Lvl) || p1Lvl < 1)
      {
         p1Lvl = 1;
      }
      if(isNaN(p2Lvl) || p2Lvl < 1)
      {
         p2Lvl = p1Lvl;
      }
      var duelLvl = Math.max(p1Lvl,p2Lvl);
      var tmpVil = _root.createEmptyMovieClip("__tmp_duel_vil",99903);
      _root.randomise_gladiator(_root.game.villain,tmpVil,duelLvl);
      if(typeof(_root.check_for_nan) == "function")
      {
         _root.check_for_nan(_root.game.villain);
      }
      _root.constructvillainDNA(_root.game.villain);
      if(tmpVil != undefined)
      {
         tmpVil.removeMovieClip();
      }
      if(_root.game.villain.character_name != undefined && _root.game.villain.character_name != "")
      {
         vname = String(_root.game.villain.character_name);
      }
   }
   c.enabled = prevEnabled;
   c.inArena = prevInArena;
   _global.battle_started = prevBattle;

   var vdna = _global.coopCleanDNA(_root.game.villain.charDNA);
   vname = _global.coopCleanStr(vname);
   var tourneyNum = (_root.game.hero != undefined && !isNaN(Number(_root.game.hero.current_tournament)) && Number(_root.game.hero.current_tournament) >= 1) ? Number(_root.game.hero.current_tournament) : 1;
   var payload = {
      mode:useMode,
      boss:bId,
      arena:aId,
      tod:tod,
      seed:seed,
      vdna:vdna,
      vname:vname,
      hat:_root.game.villain.hat_name,
      quote:_root.game.villain.character_quote,
      tourney:tourneyNum,
      ranking:_root.game.hero.tournament_ranking,
      p1dna:p1dna,
      p2dna:p2dna
   };
   _global.coopSend("start",payload);
   _global.coopApplyStartMatch(payload);
   return true;
};

_global.coopHostStartDuel = function(arenaId)
{
   return _global.coopHostStartMatch("duel",0,arenaId);
};

_global.coopStartStoryFight = function(mode, arenaId)
{
   var c = _global.coop;
   if(c == undefined || c.connected != true)
   {
      return false;
   }
   if(c.role != "host" || c.peerConnected != true || c.p1Ready != true || c.p2Ready != true)
   {
      var message = c.role != "host" ? "The host chooses the next fight." : "Both players must Ready Up in the Co-op lobby.";
      _root.tooltips(message,300,400,100);
      return true;
   }
   var boss = 0;
   var opponent = undefined;
   if(mode == "tournament")
   {
      if(_root.game.hero.tournament_ranking == 2)
      {
         boss = Number(_root.game.hero.current_tournament);
         if(isNaN(boss) || boss < 1 || boss > 18)
         {
            boss = 1;
         }
         opponent = undefined;
      }
      else
      {
         opponent = _root.game.villain;
      }
   }
   if(!_global.coopHostStartMatch(mode,boss,arenaId,opponent))
   {
      _root.tooltips(c.statusText,300,400,100);
   }
   return true;
};

_global.coopCancelIntro = function()
{
   var c = _global.coop;
   c.enterPending = false;
   c.inArena = false;
   c.enabled = false;
   _global.fightstarted = false;
   if(c.role == "host")
   {
      _global.coopSend("cancel",{});
      _root.gotoAndPlay("foyer");
   }
   else
   {
      _global.coopRestoreLocalHero();
      _root.gotoAndPlay("townsquare");
   }
};

_global.coopConfirmIntro = function()
{
   _global.fightselected = false;
   _root.clicksound2.start();
   if(_global.coop.inArena == true)
   {
      if(_global.coop.role != "host")
      {
         _root.tooltips("Waiting for the host to enter the arena.",300,400,100);
         return;
      }
      _global.coopSend("enter",{});
   }
   _root.gotoAndPlay("arena");
};

_global.coopSaveConfig = function(role, port, autoConnect)
{
   var so = SharedObject.getLocal("ss2_coop_cfg");
   if(so != undefined && so.data != undefined)
   {
      so.data.role = role;
      so.data.port = port;
      so.data.autoConnect = autoConnect;
      so.flush();
   }
};

_global.coopCheckAutoConfig = function()
{
   var c = _global.coop;
   if(c.autoChecked == true)
   {
      return;
   }
   c.autoChecked = true;
   var so = SharedObject.getLocal("ss2_coop_cfg");
   var role = _level0.coopRole;
   if(role == undefined || role == "")
   {
      role = _root.coopRole;
   }
   if((role == undefined || role == "") && so != undefined && so.data != undefined)
   {
      role = so.data.role;
   }

   var port = _level0.coopPort;
   if(port == undefined || port == "")
   {
      port = _root.coopPort;
   }
   if((port == undefined || port == "") && so != undefined && so.data != undefined)
   {
      port = so.data.port;
   }

   var autoConn = _level0.coopAuto;
   if(autoConn == undefined || autoConn == "")
   {
      autoConn = _root.coopAuto;
   }
   if((autoConn == undefined || autoConn == "") && so != undefined && so.data != undefined)
   {
      autoConn = so.data.autoConnect;
   }

   var testFlag = _level0.coopTest;
   if(testFlag == undefined || testFlag == "")
   {
      testFlag = _root.coopTest;
   }
   if(testFlag == "1" || testFlag == "true" || testFlag == true)
   {
      c.testMode = true;
   }

   var autoModeVal = _level0.coopAutoMode;
   if(autoModeVal == undefined || autoModeVal == "")
   {
      autoModeVal = _root.coopAutoMode;
   }
   if(autoModeVal != undefined && autoModeVal != "")
   {
      c.autoMode = String(autoModeVal);
   }
   else if(autoConn == "auto_duel" || autoConn == "auto_combat")
   {
      c.autoMode = String(autoConn);
   }

   if(role == "host" || role == "client")
   {
      c.role = String(role);
      c.localActor = (c.role == "host") ? 1 : 2;
   }
   if(port != undefined && !isNaN(Number(port)) && Number(port) > 0)
   {
      c.port = Number(port);
   }
   if((autoConn == "1" || autoConn == "true" || autoConn == true || autoConn == "auto_duel" || autoConn == "auto_combat") && c.role != null && c.connected != true)
   {
      _global.coopConnect(c.role,c.port);
   }
};

// ============================================================================
// Pure-AS2 Co-op Lobby UI Overlay
// ============================================================================

_global.coopDrawButton = function(parentMc, name, depth, x, y, w, h, label, bgColor, borderColor, textColor, onClickFn)
{
   var btn = parentMc.createEmptyMovieClip(name,depth);
   btn._x = x;
   btn._y = y;
   btn.beginFill(bgColor,100);
   btn.lineStyle(1,borderColor,100);
   btn.moveTo(0,0);
   btn.lineTo(w,0);
   btn.lineTo(w,h);
   btn.lineTo(0,h);
   btn.lineTo(0,0);
   btn.endFill();

   var tf = btn.createTextField("lbl",1,2,Math.max(1,Math.round((h - 18) / 2)),w - 4,h - 2);
   tf.selectable = false;
   tf.text = label;
   var fmt = new TextFormat();
   fmt.font = "_sans";
   fmt.size = 11;
   fmt.bold = true;
   fmt.align = "center";
   fmt.color = textColor;
   tf.setTextFormat(fmt);
   btn._fmt = fmt;

   btn.onRollOver = function()
   {
      this._alpha = 85;
   };
   btn.onRollOut = function()
   {
      this._alpha = 100;
   };
   btn.onRelease = onClickFn;
   return btn;
};

_global.coopDescribeDNA = function(dna, fallbackLabel)
{
   if(dna == undefined || dna == null || dna == "")
   {
      return fallbackLabel + ": <waiting>";
   }
   var parts = String(dna).split(",");
   var cname = (parts[0] != undefined && parts[0] != "") ? parts[0] : "Gladiator";
   var clvl = (parts[24] != undefined && parts[24] != "") ? parts[24] : "1";
   return fallbackLabel + ": " + cname + " (Lv." + clvl + ")";
};

_global.coopRefreshLobbyUI = function()
{
   var panel = _root.__coop_lobby;
   if(panel == undefined)
   {
      return;
   }
   var c = _global.coop;
   _global.coopGetLocalDNA();

   panel.txt_status.text = "Status: " + c.statusText + "   |   Role: " + (c.role != null ? c.role.toUpperCase() : "NONE") + " (:" + c.port + ")";
   panel.txt_p1.text = _global.coopDescribeDNA(c.p1DNA,"P1 (Host)") + (c.p1Ready ? "  [READY]" : "  [NOT READY]");
   panel.txt_p2.text = _global.coopDescribeDNA(c.p2DNA,"P2 (Client)") + (c.p2Ready ? "  [READY]" : "  [NOT READY]");
   panel.txt_opp.text = c.role == "client" ? "The host chooses the fight at the Arena." : "After Ready Up, choose a fight at the Arena.";

   var fmt = new TextFormat();
   fmt.font = "_sans";
   fmt.size = 12;
   fmt.color = 0xF5E6C8;
   panel.txt_status.setTextFormat(fmt);
   panel.txt_p1.setTextFormat(fmt);
   panel.txt_p2.setTextFormat(fmt);
   panel.txt_opp.setTextFormat(fmt);

   var myReady = (c.role == "host") ? c.p1Ready : c.p2Ready;
   if(panel.btn_ready != undefined && panel.btn_ready.lbl != undefined)
   {
      panel.btn_ready.lbl.text = myReady ? "Unready" : "Ready Up";
      panel.btn_ready.lbl.setTextFormat(panel.btn_ready._fmt);
   }
};

_global.coopHideLobby = function()
{
   if(_root.__coop_lobby != undefined)
   {
      _root.__coop_lobby.removeMovieClip();
   }
};

_global.coopShowLobby = function()
{
   if(_root.__coop_lobby != undefined)
   {
      _global.coopRefreshLobbyUI();
      return;
   }
   _global.coopGetLocalDNA();
   var panel = _root.createEmptyMovieClip("__coop_lobby",99930);
   panel._x = 170;
   panel._y = 85;
   var W = 460;
   var H = 264;

   // Backdrop shield
   panel.beginFill(0x000000,45);
   panel.moveTo(-170,-85);
   panel.lineTo(630,-85);
   panel.lineTo(630,515);
   panel.lineTo(-170,515);
   panel.lineTo(-170,-85);
   panel.endFill();

   // Panel box
   panel.beginFill(0x1E1610,96);
   panel.lineStyle(2,0xD4A843,100);
   panel.moveTo(0,0);
   panel.lineTo(W,0);
   panel.lineTo(W,H);
   panel.lineTo(0,H);
   panel.lineTo(0,0);
   panel.endFill();

   // Title bar
   panel.beginFill(0x3B2616,100);
   panel.lineStyle(1,0xD4A843,100);
   panel.moveTo(0,0);
   panel.lineTo(W,0);
   panel.lineTo(W,34);
   panel.lineTo(0,34);
   panel.lineTo(0,0);
   panel.endFill();

   var titleTf = panel.createTextField("txt_title",1,12,6,W - 50,24);
   titleTf.selectable = false;
   titleTf.text = "SWORDS & SANDALS 2 — 2v1 CO-OP LOBBY";
   var tFmt = new TextFormat();
   tFmt.font = "_sans";
   tFmt.size = 14;
   tFmt.bold = true;
   tFmt.color = 0xFFD470;
   titleTf.setTextFormat(tFmt);

   _global.coopDrawButton(panel,"btn_close",2,W - 34,5,26,24,"X",0x7A2018,0xD4A843,0xFFFFFF,function()
   {
      _global.coopHideLobby();
   });

   var makeLine = function(nm, dp, yy)
   {
      var fld = panel.createTextField(nm,dp,18,yy,W - 36,24);
      fld.selectable = false;
      fld.wordWrap = true;
      return fld;
   };
   makeLine("txt_status",3,44);
   makeLine("txt_p1",4,126);
   makeLine("txt_p2",5,154);
   makeLine("txt_opp",6,232);

   // Connection buttons
   _global.coopDrawButton(panel,"btn_host",10,18,78,140,30,"Host Co-op (19801)",0x2E5D34,0xD4A843,0xFFFFFF,function()
   {
      _global.coopConnect("host",19801);
   });
   _global.coopDrawButton(panel,"btn_join",11,168,78,140,30,"Join Co-op (19802)",0x2B4C7E,0xD4A843,0xFFFFFF,function()
   {
      _global.coopConnect("client",19802);
   });
   _global.coopDrawButton(panel,"btn_disc",12,318,78,124,30,"Disconnect",0x5A2A22,0xD4A843,0xFFFFFF,function()
   {
      _global.coopDisconnect();
   });

   // Ready button
   _global.coopDrawButton(panel,"btn_ready",13,18,186,424,32,"Ready Up",0x5E4A1E,0xFFD470,0xFFFFFF,function()
   {
      var c = _global.coop;
      var cur = (c.role == "host") ? c.p1Ready : c.p2Ready;
      _global.coopSetReady(!cur);
   });

   _global.coopRefreshLobbyUI();
};

_global.coopToggleLobby = function()
{
   if(_root.__coop_lobby != undefined)
   {
      _global.coopHideLobby();
   }
   else
   {
      _global.coopShowLobby();
   }
};

_global.coopCheckAutoConfig();
_global.coopEnsureQAWatchdog();
