function getfightdistance()
{
   if(_global.coop.enabled == true)
   {
      var activeClip = gladiators.hero;
      if(_global.coop.activeTurn == 2)
      {
         activeClip = gladiators.hero2;
      }
      else if(_global.coop.activeTurn == 3)
      {
         if(_global.coop.targetHero == 2 && _root.game.hero2.hitpoints > 0)
         {
            activeClip = gladiators.hero2;
         }
         else if(_root.game.hero.hitpoints <= 0 && _root.game.hero2.hitpoints > 0)
         {
            activeClip = gladiators.hero2;
         }
      }
      if(activeClip._x < gladiators.villain._x)
      {
         xdist = Math.round(gladiators.villain._x - activeClip._x);
         ydist = Math.round(gladiators.villain._y - activeClip._y);
         gladiators.overlay._xscale = -100;
      }
      else
      {
         xdist = Math.round(activeClip._x - gladiators.villain._x);
         ydist = Math.round(activeClip._y - gladiators.villain._y);
      }
      fightdistance = Math.round(Math.sqrt(xdist * xdist + ydist * ydist));
      midwaypoint = Math.round(fightdistance / 2);
      return undefined;
   }
   if(_root.arena.gladiators.hero._x < _root.arena.gladiators.villain._x)
   {
      xdist = Math.round(gladiators.villain._x - gladiators.hero._x);
      ydist = Math.round(gladiators.villain._y - gladiators.hero._y);
      _root.arena.gladiators.overlay._xscale = -100;
   }
   else
   {
      xdist = Math.round(_root.arena.gladiators.hero._x - _root.arena.gladiators.villain._x);
      ydist = Math.round(_root.arena.gladiators.hero._y - _root.arena.gladiators.villain._y);
   }
   fightdistance = Math.round(Math.sqrt(xdist * xdist + ydist * ydist));
   midwaypoint = Math.round(fightdistance / 2);
}
function combatCamera()
{
   return undefined;
}
function combatscale()
{
   if(_global.coop.enabled == true)
   {
      var minX = undefined;
      var maxX = undefined;
      if(_root.game.hero.hitpoints > 0 && gladiators.hero != undefined)
      {
         minX = gladiators.hero._x;
         maxX = gladiators.hero._x;
      }
      if(_root.game.hero2.hitpoints > 0 && gladiators.hero2 != undefined)
      {
         if(minX == undefined || gladiators.hero2._x < minX)
         {
            minX = gladiators.hero2._x;
         }
         if(maxX == undefined || gladiators.hero2._x > maxX)
         {
            maxX = gladiators.hero2._x;
         }
      }
      if(_root.game.villain.hitpoints > 0 && gladiators.villain != undefined)
      {
         if(minX == undefined || gladiators.villain._x < minX)
         {
            minX = gladiators.villain._x;
         }
         if(maxX == undefined || gladiators.villain._x > maxX)
         {
            maxX = gladiators.villain._x;
         }
      }
      if(minX == undefined)
      {
         minX = gladiators.hero._x;
         maxX = gladiators.villain._x;
      }
      var camMid = Math.round((maxX - minX) / 2);
      gladiators.midway_focus._x = minX + camMid;
      midwaypoint = camMid;
   }
   else if(_root.arena.gladiators.hero._x < _root.arena.gladiators.villain._x)
   {
      gladiators.midway_focus._x = gladiators.hero._x + midwaypoint;
   }
   else
   {
      gladiators.midway_focus._x = gladiators.villain._x + midwaypoint;
   }
   var _loc5_ = 5;
   var _loc4_ = 16;
   var _loc3_ = {x:Math.round(gladiators.midway_focus._x),y:Math.round(gladiators.midway_focus._y)};
   gladiators.localToGlobal(_loc3_);
   if(_loc3_.x < 300)
   {
      gladiators._x += (300 - _loc3_.x) / _loc4_;
   }
   if(_loc3_.x > 340)
   {
      gladiators._x -= (_loc3_.x - 340) / _loc4_;
   }
   if(midwaypoint < 240)
   {
      _global.maxscale = 80;
   }
   if(midwaypoint > 240 && midwaypoint <= 300)
   {
      _global.maxscale = 70;
   }
   if(midwaypoint > 300 && midwaypoint <= 400)
   {
      _global.maxscale = 60;
   }
   if(midwaypoint > 200 && midwaypoint <= 400)
   {
      _global.maxscale = 50;
   }
   if(midwaypoint > 400 && midwaypoint <= 700)
   {
      _global.maxscale = 30;
   }
   if(midwaypoint > 700 && midwaypoint <= 1500)
   {
      _global.maxscale = 20;
   }
   if(midwaypoint > 1500)
   {
      _global.maxscale = 15;
   }
   if(_global.zoomscale < _global.maxscale)
   {
      _global.zoomscale -= Math.round((_global.zoomscale - _global.maxscale) / _loc5_);
   }
   if(_global.zoomscale > _global.maxscale)
   {
      _global.zoomscale += Math.round((_global.maxscale - _global.zoomscale) / _loc5_);
   }
   if(_global.zoomscale > _global.maxscale - 4 && _global.zoomscale < _global.maxscale + 4)
   {
      _global.zoomscale = _global.maxscale;
   }
   gladiators._xscale = gladiators._yscale = Math.ceil(_global.zoomscale);
   crowd._y = -200 + Math.ceil(_global.zoomscale);
}
if(_global.coop.enabled != true || _global.coop.role == "host")
{
   if(_root.game.villain.character_xp >= _root.game.hero.villain_xp)
   {
      _root.game.hero.villain_xp = _root.game.villain.character_xp;
      _root.game.hero.mostpowerfulfoe = _root.game.villain.character_name + "  Level " + _root.game.villain.herolevel;
   }
}
_root.game.villain.staminaleft = _root.game.villain.staminamax;
_root.game.hero.psyche_up = _root.game.villain.psyche_up = 1;
_root.arena.attachMovie("combat_panel","combat_panel",200000,{_x:-320,_y:122});
combat_panel.herotext = _root.game.hero.character_name;
combat_panel.villaintext = _root.game.villain.character_name;
function coopDrawHudBox(clip, width, height, color)
{
   clip.beginFill(color,100);
   clip.moveTo(0,0);
   clip.lineTo(width,0);
   clip.lineTo(width,height);
   clip.lineTo(0,height);
   clip.lineTo(0,0);
   clip.endFill();
}
function coopHudText(clip, name, depth, x, y, width, size, color, bold)
{
   clip.createTextField(name,depth,x,y,width,17);
   var field = clip[name];
   field.selectable = false;
   field.setNewTextFormat(new TextFormat("_sans",size,color,bold));
   return field;
}
function coopCreateStatRow(card, depth, y, label, color)
{
   var row = card.createEmptyMovieClip("stat" + depth,depth);
   row._y = y;
   coopHudText(row,"label",1,7,-3,48,10,0xF5E6C8,true).text = label;
   var track = row.createEmptyMovieClip("track",2);
   track._x = 53;
   track._y = 1;
   coopDrawHudBox(track,80,8,0x514137);
   row.fill = row.createEmptyMovieClip("fill",3);
   row.fill._x = track._x;
   row.fill._y = track._y;
   coopDrawHudBox(row.fill,80,8,color);
   coopHudText(row,"value",4,138,-3,62,10,0xFFFFFF,false);
}
function coopUpdateStatRow(row, current, maximum)
{
   var ratio = maximum > 0 ? current / maximum : 0;
   row.fill._xscale = Math.max(0,Math.min(100,ratio * 100));
   row.value.text = Math.round(current) + " / " + Math.round(maximum);
}
if(_global.coop.enabled == true)
{
   _root.game.hero2.psyche_up = 1;
   combat_panel.herotext = _root.game.hero.character_name + " [P1]";
   // The native combat panel masks children outside its potion and name area.
   var hud = this.createEmptyMovieClip("coop_hud",200001);
   var cardPosition = {x:218,y:322};
   this.globalToLocal(cardPosition);
   hud._x = cardPosition.x;
   hud._y = cardPosition.y;
   coopDrawHudBox(hud,200,66,0x2B1F17);
   coopHudText(hud,"playerName",1,7,2,186,12,0xFBD991,true);
   coopCreateStatRow(hud,2,21,"Health",0xD75C55);
   coopCreateStatRow(hud,3,35,"Energy",0x6B9DE0);
   coopCreateStatRow(hud,4,49,"Armor",0xC7AD72);
   hud.onEnterFrame = function()
   {
      if(_global.coop.inArena != true)
      {
         this.removeMovieClip();
      }
   };
}
_global.zoomscale = 5;
crowd.gotoAndStop(_global.current_arena);
if(_global.current_arena == 6 && _root.game.hero.tournament_ranking == 2)
{
   crowd.emperor._visible = false;
}
sand.gotoAndStop(_global.current_arena);
_root.sky.gotoAndStop(_global.time_of_day);
_root.sky.cacheAsBitmap = true;
crowd.onEnterFrame = function()
{
   if(_root.arena.gladiators.camPoint.x < 300)
   {
      this._x += (300 - camPoint.x) / 16;
   }
   if(_root.arena.gladiators.camPoint.x > 340)
   {
      this._x -= (_root.arena.gladiators.camPoint.x - 340) / 16;
   }
   if(this._x < -600)
   {
      this._x = 600;
   }
   if(this._x > 200)
   {
      this._x = 200;
   }
};
gladiators.onEnterFrame = function()
{
   getfightdistance();
   if(_global.phasecomplete != false)
   {
      combatscale();
   }
   offsetX = 0;
   closeUpOverlay = false;
   var activeHeroClip = gladiators.hero;
   if(_global.coop.enabled == true && _global.coop.activeTurn == 2)
   {
      activeHeroClip = gladiators.hero2;
   }
   gDistance = Math.abs(activeHeroClip._x - gladiators.villain._x);
   if(gDistance < 1600)
   {
      gladiators.overlay._x = activeHeroClip._x;
   }
   else
   {
      closeUpOverlay = true;
      if(activeHeroClip._x < gladiators.villain._x)
      {
         gx = activeHeroClip._x + gDistance * 0.5;
      }
      else
      {
         gx = activeHeroClip._x - gDistance * 0.5;
      }
      gladiators.overlay._x = gx;
   }
   gladiators.overlay.hero._visible = closeUpOverlay;
   if(gladiators.overlay._currentFrame > 52)
   {
      gladiators.overlay.hero._visible = false;
   }
   gladiators.overlay._y = activeHeroClip._y - 180;
   gladiators.overlay_villain._x = gladiators.villain._x;
   gladiators.overlay_villain._y = gladiators.villain._y - 180;
   if(_global.coop.enabled == true && _root.arena.coop_hud != undefined)
   {
      var h1 = _root.game.hero;
      var h2 = _root.game.hero2;
      combat_panel.herotext = h1.character_name + (h1.hitpoints <= 0 ? " [P1 KO]" : " [P1]");
      coop_hud.playerName.text = h2.character_name + (h2.hitpoints <= 0 ? " [P2 KO]" : " [P2]");
      coopUpdateStatRow(coop_hud.stat2,h2.hitpoints,h2.hitpointsmax);
      coopUpdateStatRow(coop_hud.stat3,h2.staminaleft,h2.staminamax);
      coopUpdateStatRow(coop_hud.stat4,h2.armourclass,h2.armourclass_max);
   }
   if(_global.maxscale < 20)
   {
      flipoverlay = 600;
   }
   if(_global.maxscale == 20)
   {
      flipoverlay = 500;
   }
   if(_global.maxscale == 30)
   {
      flipoverlay = 320;
   }
   if(_global.maxscale == 50)
   {
      flipoverlay = 240;
   }
   if(_global.maxscale == 60)
   {
      flipoverlay = 220;
   }
   if(_global.maxscale == 70)
   {
      flipoverlay = 200;
   }
   if(_global.maxscale == 80)
   {
      flipoverlay = 160;
   }
   if(closeUpOverlay)
   {
      flipoverlay = 600;
   }
   if(_root.arena.gladiators.hero.gladiator_dir == "right")
   {
      gladiators.overlay._xscale = flipoverlay;
      gladiators.overlay._yscale = flipoverlay;
      gladiators.overlay_villain._xscale = gladiators.overlay_villain._yscale = flipoverlay;
   }
   else
   {
      gladiators.overlay._xscale = gladiators.overlay._yscale = flipoverlay;
      gladiators.overlay_villain._xscale = gladiators.overlay_villain._yscale = flipoverlay;
   }
};
