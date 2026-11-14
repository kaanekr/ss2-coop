if(_global.coop != undefined && _global.coop.inArena != true)
{
   _global.coop.enabled = false;
   _global.coop.inArena = false;
   if(_global.coop.needRestoreLocalHero == true)
   {
      _global.coopRestoreLocalHero();
   }
}
_root.sky.cacheAsBitmap = false;
day_night_cycle();
_root.sky._visible = true;
_root.sky.cacheAsBitmap = true;
_root.delete_tooltips();
_global.battle_started = false;
if(_global.gamephase == 1)
{
   _global.gamephase = 2;
   _root.tooltips("Your adventure starts here in the town square. Before you enter the arena, you should visit the armoury and the weaponsmith and stock up on a weapon or some armour. Click on one of the buildings nearby to enter, or click the collesseum to jump straight into battle.",1000,400,90);
}
if(_global.gamephase == 5)
{
   _root.tooltips("So you\'ve survived your first fight? Well done. You\'ve earnt some gold to spend. Don\'t forget to visit the armoury or weaponsmith when you\'ve enough gold.",1000,400,90);
}
townhero = _root.townsquare.attachMovie("hero","hero",300);
_root.constructDNA();
_root.skincharacter(_root.game.hero,this.townhero);
_root.save_character(_global.current_character);
townhero._xscale = townhero._yscale = 40 + Math.round(_root.game.hero.strength / 3);
townhero._x = 0;
townhero._y = 180;
_root.attachMovie("charsheet","charsheet",99888);
charsheet._x = 484;
charsheet._y = 168;
charsheet.tab_stats.onRollOver = function()
{
   _root.delete_tooltips();
   _root.charsheet.gotoAndPlay("stats");
};
charsheet.tab_armour.onRollOver = function()
{
   _root.delete_tooltips();
   _root.charsheet.gotoAndPlay("armour");
};
charsheet.tab_info.onRollOver = function()
{
   _root.delete_tooltips();
   _root.charsheet.gotoAndPlay("info");
};
charsheet.tab_items.onRollOver = function()
{
   _root.delete_tooltips();
   _root.charsheet.gotoAndPlay("items");
};
charsheet.tab_stats.onRollOut = charsheet.tab_items.onRollOut = charsheet.tab_info.onRollOut = charsheet.tab_armour.onRollOut = function()
{
   _root.charsheet.gotoAndPlay(1);
};
special_event_chance = 1 + random(100);
if(special_event_chance <= 2 && _global.special_event_happening != true && _global.special_for_day != true && (_global.coop == undefined || (_global.coop.connected != true && _global.coop.testMode != true)))
{
   _root.gotoAndPlay("special_event");
}
else if(_global.coop == undefined || _global.coop.inArena != true)
{
   play();
}
button_exit.onRollOver = function()
{
   _root.tooltips("Click here to restart your game. Any unsaved progress will be lost!");
};
button_exit.onRollOut = function()
{
   _root.delete_tooltips();
};
button_exit.onRelease = function()
{
   if(_global.coop != undefined)
   {
      _global.coopHideLobby();
   }
   gotoAndStop("splash");
   play();
};
if(_root.game.hero.goldpieces >= 100000)
{
   AS3connection.send("AS2to3","doAchievement","SS2_100000_GOLD");
}
else
{
   _root.AS3connection.send("AS2to3","doAchievement","SS2_BOSS_0");
}

if(_global.coop != undefined && _global.coop.inArena != true)
{
   _global.coop.townEntered = true;
   var localDna = _global.coopGetLocalDNA();
   if(_global.coop.connected == true && localDna != "")
   {
      _global.coopSend("hello",{role:_global.coop.role, dna:localDna});
      _global.coopRefreshLobbyUI();
   }
   if(typeof(_global.coopDrawButton) == "function")
   {
      if(_root.__coop_town_btn != undefined)
      {
         _root.__coop_town_btn.removeMovieClip();
      }
      var townCoopLabel = (_global.coop.connected == true) ? "2v1 CO-OP (ONLINE)" : "2v1 CO-OP LOBBY";
      var btnBg = (_global.coop.connected == true) ? 0x2E5D34 : 0x4A2E16;
      var townBtn = _global.coopDrawButton(_root,"__coop_town_btn",99920,14,14,154,28,townCoopLabel,btnBg,0xFFD470,0xFFFFFF,function()
      {
         _global.coopToggleLobby();
      });
      townBtn.onEnterFrame = function()
      {
         if(_root._currentframe < 150 || _root._currentframe > 159)
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
