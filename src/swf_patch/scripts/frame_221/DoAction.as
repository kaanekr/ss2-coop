_root.delete_tooltips();
function coopAttachGroundShadow(gladiators, fighter, name, depth)
{
   var shadow = gladiators.createEmptyMovieClip(name,depth);
   shadow.fighter = fighter;
   shadow._y = 200;
   shadow.beginFill(0x160E08,70);
   shadow.moveTo(-30,0);
   shadow.curveTo(-30,-8,0,-8);
   shadow.curveTo(30,-8,30,0);
   shadow.curveTo(30,8,0,8);
   shadow.curveTo(-30,8,-30,0);
   shadow.endFill();
   shadow.onEnterFrame = function()
   {
      this._x = this.fighter._x;
      this._visible = this.fighter._visible;
      this._xscale = Math.abs(this.fighter._xscale);
      this._yscale = Math.abs(this.fighter._yscale);
      this._alpha = Math.max(15,65 - Math.max(0,200 - this.fighter._y) / 2);
   };
   shadow.onEnterFrame();
}
if(_global.gamephase == 3)
{
   _global.gamephase = 4;
   _root.tooltips("Combat is turned based and lasts until only one gladiator remains standing. Rollover the icons surrounding your gladiator to find out what they do.",300,400,50);
}
_root.town_day.stop();
_root.town_night.stop();
_root.arena.createEmptyMovieClip("gladiators",5);
_root.arena.gladiators.attachMovie("midway_focus","midway_focus",6);
rockLeft = _root.arena.gladiators.attachMovie("rockMC","rockLeft",200);
rockRight = _root.arena.gladiators.attachMovie("rockMC","rockRight",201);
rockLeft._y = rockRight._y = 210;
rockLeft._x = -2160;
rockRight._x = 2160;
_root.arena.gladiators._x = 0;
_root.arena.gladiators._y = 0;
_root.arena.gladiators.attachMovie("overlay","overlay",40000);
_root.arena.gladiators.attachMovie("overlay_villain","overlay_villain",40001);
arena_hero = _root.arena.gladiators.attachMovie("hero_battle","hero",301);
arena_villain = _root.arena.gladiators.attachMovie("hero_battle","villain",300);
_root.game.hero.equipped_weapon = 1;
_root.game.hero.using_bow = false;
_root.skincharacter(_root.game.hero,_root.arena.gladiators.hero);
_root.skincharacter(game.villain,_root.arena.gladiators.villain);
arena_hero._xscale = 80 + Math.round(_root.game.hero.strength / 1.5);
arena_hero._yscale = 80 + Math.round(_root.game.hero.strength / 1.5);
arena_hero._x = -250;
arena_hero._y = 200;
arena_hero.gladiator_dir = "right";
arena_villain._xscale = 80 + Math.round(_root.game.villain.strength / 1.5);
arena_villain._xscale = - arena_villain._xscale;
arena_villain._yscale = 80 + Math.round(_root.game.villain.strength / 1.5);
arena_villain._x = 250;
arena_villain._y = 200;
arena_villain.gladiator_dir = "left";
if(_global.coop.enabled != true)
{
   arena_hero_shadow = _root.arena.gladiators.attachMovie("hero_battle","hero_shadow",298);
   arena_villain_shadow = _root.arena.gladiators.attachMovie("hero_battle","villain_shadow",299);
   _root.skincharacter(_root.game.hero,_root.arena.gladiators.hero_shadow);
   _root.skincharacter(_root.game.villain,_root.arena.gladiators.villain_shadow);
   arena_hero_shadow._y = arena_hero._y;
   arena_villain_shadow._y = arena_villain._y;
   arena_hero_shadow._xscale = arena_hero._xscale;
   arena_hero_shadow._yscale = - arena_hero._yscale / 5;
   arena_villain_shadow._xscale = arena_villain._xscale;
   arena_villain_shadow._yscale = - arena_villain._yscale / 5;
   if(_global.current_arena >= 1 && _global.current_arena < 6)
   {
   }
   if(_global.current_arena < 6)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"0",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      hero_shadowColor = new Color(arena_hero_shadow);
      hero_shadowColor.setTransform(charColorTransform);
      villain_shadowColor = new Color(arena_villain_shadow);
      villain_shadowColor.setTransform(charColorTransform);
   }
   if(_global.current_arena == 6)
   {
      arena_hero_shadow._alpha = 30;
      arena_villain_shadow._alpha = 30;
   }
   arena_hero_shadow.onEnterFrame = function()
   {
      hero_frame = arena_hero._currentframe;
      this.gotoAndStop(hero_frame);
      this.weapon.gotoAndStop(1);
      this._x = arena_hero._x;
      this._xscale = _root.arena.gladiators.hero._xscale;
      this._yscale = - Math.round(_root.arena.gladiators.hero._yscale / 4);
   };
   arena_villain_shadow.onEnterFrame = function()
   {
      villain_frame = arena_villain._currentframe;
      this.gotoAndStop(villain_frame);
      this.weapon.gotoAndStop(1);
      this._x = arena_villain._x;
      this._xscale = _root.arena.gladiators.villain._xscale;
      this._yscale = - Math.round(_root.arena.gladiators.villain._yscale / 4);
   };
}
if(_global.coop.enabled == true)
{
   _global.battle_action = null;
   _global.phasecomplete = true;
   _global.coop.inArena = true;
   _global.coop.activeTurn = 1;
   _global.coop.targetHero = 1;
   _global.coop.pendingRemoteAct = null;
   _global.coop.pendingRemoteBoss = null;
   _global.coop.pendingSync = null;
   _global.coop.awaitingSync = false;
   _global.coop.syncSeq = 0;
   _global.coop.lastAppliedSyncSeq = 0;
   arena_hero2 = _root.arena.gladiators.attachMovie("hero_battle","hero2",302);
   _root.game.hero2.equipped_weapon = 1;
   _root.game.hero2.using_bow = false;
   _root.game.hero2.psyche_up = 1;
   _root.skincharacter(_root.game.hero2,_root.arena.gladiators.hero2);
   arena_hero2._xscale = 80 + Math.round(_root.game.hero2.strength / 1.5);
   arena_hero2._yscale = 80 + Math.round(_root.game.hero2.strength / 1.5);
   arena_hero2._x = -380;
   arena_hero2._y = 200;
   arena_hero2.gladiator_dir = "right";
   var fighters = _root.arena.gladiators;
   coopAttachGroundShadow(fighters,arena_hero,"hero_shadow",298);
   coopAttachGroundShadow(fighters,arena_hero2,"hero2_shadow",297);
   coopAttachGroundShadow(fighters,arena_villain,"villain_shadow",299);
}
_global.battle_started = true;
