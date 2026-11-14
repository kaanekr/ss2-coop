if(_global.coop.enabled == true && (_global.coop.awaitingSync == true || !coopIsLocalOwner()))
{
   inventory_overlay.removeMovieClip();
   swap_inventory._visible = false;
}
else
{
   var coopOv = this;
   var coopAh = _global.coop.enabled == true && _global.coop.activeTurn == 2 ? _root.game.hero2 : _root.game.hero;
   this.attachMovie("inventory_overlay","inventory_overlay",199999,{_x:0,_y:-80});
   inventory = this.inventory_overlay;
   inventory._xscale = inventory._yscale = 60;
   inventory.inventory_button1.onRollOver = inventory.inventory_button2.onRollOver = inventory.inventory_button3.onRollOver = inventory.inventory_button4.onRollOver = inventory.inventory_button5.onRollOver = inventory.inventory_button6.onRollOver = function()
   {
      this.battlebutton.gotoAndStop(2);
      _root.arena.gladiators.overlay.optiontext = this.optiontext;
      if(this.tooltip == undefined)
      {
         _root.arena.gladiators.overlay.optiontext = "";
      }
      if(this.tooltip != undefined)
      {
         _root.tooltips(this.tooltip);
      }
   };
   inventory.inventory_button1.onRollOut = inventory.inventory_button2.onRollOut = inventory.inventory_button3.onRollOut = inventory.inventory_button4.onRollOut = inventory.inventory_button5.onRollOut = inventory.inventory_button6.onRollOut = function()
   {
      this.battlebutton.gotoAndStop(1);
      _root.arena.gladiators.overlay.optiontext = "";
      _root.delete_tooltips();
   };
   inventory.inventory_button1.onRelease = inventory.inventory_button2.onRelease = inventory.inventory_button3.onRelease = inventory.inventory_button4.onRelease = inventory.inventory_button5.onRelease = inventory.inventory_button6.onRelease = function()
   {
      if(this._name == "inventory_button1" && inv_struck != true)
      {
         coopAh.inventory_action = coopAh.inventory1;
         coopAh.inventory1 = 1;
         inv_struck = true;
      }
      if(this._name == "inventory_button2" && inv_struck != true)
      {
         coopAh.inventory_action = coopAh.inventory2;
         coopAh.inventory2 = 1;
         inv_struck = true;
      }
      if(this._name == "inventory_button3" && inv_struck != true)
      {
         coopAh.inventory_action = coopAh.inventory3;
         coopAh.inventory3 = 1;
         inv_struck = true;
      }
      if(this._name == "inventory_button4" && inv_struck != true)
      {
         coopAh.inventory_action = coopAh.inventory4;
         coopAh.inventory4 = 1;
         inv_struck = true;
      }
      if(this._name == "inventory_button5" && inv_struck != true)
      {
         coopAh.inventory_action = coopAh.inventory5;
         coopAh.inventory5 = 1;
         inv_struck = true;
      }
      if(this._name == "inventory_button6" && inv_struck != true)
      {
         coopAh.inventory_action = coopAh.inventory6;
         coopAh.inventory6 = 1;
         inv_struck = true;
      }
      this.battlebutton.gotoAndStop(1);
      _root.arena.gladiators.overlay.optiontext = "";
      _root.delete_tooltips();
      if(this.whichphase != undefined && this.whichphase != null & this.whichphase != "")
      {
         coopOv.coopLastInv = coopAh.inventory_action;
         getphase(this.whichphase);
         _root["game.hero.inventory" + this.whichbutton] = 1;
         _root.constructDNA();
      }
   };
   inventory.inventory_button1.optiontext = _root["inventory" + coopAh.inventory1][1];
   inventory.inventory_button2.optiontext = _root["inventory" + coopAh.inventory2][1];
   inventory.inventory_button3.optiontext = _root["inventory" + coopAh.inventory3][1];
   inventory.inventory_button4.optiontext = _root["inventory" + coopAh.inventory4][1];
   inventory.inventory_button5.optiontext = _root["inventory" + coopAh.inventory5][1];
   inventory.inventory_button6.optiontext = _root["inventory" + coopAh.inventory6][1];
   inventory.inventory_button1.tooltip = _root["inventory" + coopAh.inventory1][1];
   inventory.inventory_button2.tooltip = _root["inventory" + coopAh.inventory2][1];
   inventory.inventory_button3.tooltip = _root["inventory" + coopAh.inventory3][1];
   inventory.inventory_button4.tooltip = _root["inventory" + coopAh.inventory4][1];
   inventory.inventory_button5.tooltip = _root["inventory" + coopAh.inventory5][1];
   inventory.inventory_button6.tooltip = _root["inventory" + coopAh.inventory6][1];
   inventory.inventory_button1.whichphase = _root["inventory" + coopAh.inventory1][0];
   inventory.inventory_button2.whichphase = _root["inventory" + coopAh.inventory2][0];
   inventory.inventory_button3.whichphase = _root["inventory" + coopAh.inventory3][0];
   inventory.inventory_button4.whichphase = _root["inventory" + coopAh.inventory4][0];
   inventory.inventory_button5.whichphase = _root["inventory" + coopAh.inventory5][0];
   inventory.inventory_button6.whichphase = _root["inventory" + coopAh.inventory6][0];
   inventory.inventory_button1.whichbutton = 1;
   inventory.inventory_button2.whichbutton = 2;
   inventory.inventory_button3.whichbutton = 3;
   inventory.inventory_button4.whichbutton = 4;
   inventory.inventory_button5.whichbutton = 5;
   inventory.inventory_button6.whichbutton = 6;
   if(coopAh.ammo_left <= 0 && coopAh.secondary_weapon != 0 || coopAh.secondary_weapon == 0)
   {
      swap_inventory._visible = false;
   }
   else if(coopAh.using_bow != true)
   {
      swap_inventory._visible = true;
      swap_inventory.gotoAndStop(10);
   }
   else
   {
      swap_inventory._visible = true;
      swap_inventory.gotoAndStop(11);
   }
   swap_inventory.onRollOver = function()
   {
      this.battlebutton.gotoAndStop(2);
      if(coopAh.using_bow == true)
      {
         _root.arena.gladiators.overlay.optiontext = "Switch to melee weapon";
      }
      else
      {
         _root.arena.gladiators.overlay.optiontext = "Switch to ranged weapon";
      }
      if(this.tooltip != undefined)
      {
         _root.tooltips("If you have more than one weapon, you can now switch between your melee and ranged weapon by clicking this button. Only work if you have any ammunition left.");
      }
   };
   swap_inventory.onRollOut = function()
   {
      this.battlebutton.gotoAndStop(1);
      _root.arena.gladiators.overlay.optiontext = "";
      _root.delete_tooltips();
   };
   swap_inventory.onRelease = function()
   {
      this.battlebutton.gotoAndStop(1);
      _root.arena.gladiators.overlay.optiontext = "";
      _root.delete_tooltips();
      getphase("swap_weapons");
      _root.constructDNA();
   };
}
