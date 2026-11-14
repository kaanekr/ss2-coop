var ah = _root.game.hero;
var ac = _root.arena.gladiators.hero;
var coopAllowMenu = true;
if(_global.coop.enabled == true)
{
   ah = coopActiveHero();
   ac = coopActiveClip();
   if(_global.coop.awaitingSync == true || !coopIsLocalOwner())
   {
      coopSetMenuVisible(false);
      coopAllowMenu = false;
   }
   else
   {
      var wantLbl13 = ah.using_bow != true ? (_root.arena.fightdistance < ah.weapon_range ? "closerange_warrior" : "longrange_warrior") : (_root.arena.fightdistance < 100 + ah.physical_size ? "closerange_archer" : "longrange_archer");
      if(wantLbl13 != "closerange_warrior")
      {
         gotoAndStop(wantLbl13);
         coopAllowMenu = false;
      }
      else
      {
         coopSetMenuVisible(true);
      }
   }
}
if(coopAllowMenu)
{
attack_chances(ah,_root.game.villain);
hero._visible = true;
if(ac.gladiator_dir == "right")
{
   if(ah.herolevel < 3)
   {
      optionG._visible = false;
   }
   if(ah.herolevel < 7)
   {
      optionH._visible = false;
   }
   optionA.gotoAndStop(7);
   optionB.gotoAndStop(6);
   optionC.gotoAndStop(16);
   optionD.gotoAndStop(2);
   optionE.gotoAndStop(3);
   optionF.gotoAndStop(4);
   optionG.gotoAndStop(29);
   if(ah.psyche_up <= 1)
   {
      optionH.gotoAndStop(26);
   }
   if(ah.psyche_up == 2)
   {
      optionH.gotoAndStop(27);
   }
   if(ah.psyche_up >= 3)
   {
      optionHG.gotoAndStop(28);
   }
   optionA.optiontext = "Jump backward";
   optionB.optiontext = "Walk backward";
   optionC.optiontext = "Shove enemy";
   optionD.optiontext = "Power (" + ah.power_percentage + " % chance)";
   optionE.optiontext = "Normal(" + ah.normal_percentage + " % chance)";
   optionF.optiontext = "Quick (" + ah.quick_percentage + " % chance)";
   optionG.optiontext = "Win the Crowd";
   optionH.optiontext = "Psyche Up " + ah.psyche_up + " /3";
   optionA.tooltip = "Jump backward. Press this to leap out of danger. Jumping saps your energy quickly. The height and distance of your jump is determined by your agility.";
   optionB.tooltip = "Walk backward. Press this to step away from your enemy. Useful when your health is low, but be aware that jumping saps your energy quickly. The distance you can walk is determined by your agility.";
   optionC.tooltip = "Shove enemy. Press this to push your opponent backwards and give yourself some breathing space. The stronger you are , the further you push your foe.) ";
   optionD.tooltip = "Power attack. Power attacks sap a lot of energy and are the least likely to hit, but will inflict the most damage if successful.";
   optionE.tooltip = "Normal attack. A standard hack, thrust or bash. Their chance of hitting is based on several factors, including your attack vs your opponent\'s defence, and random chance.";
   optionF.tooltip = "Quick attack. These attacks don\'t use much energy and have the highest chance of doing damage. However most quick attacks will only do minimal grazing damage to your opponent.";
   optionG.tooltip = "Win the Crowd. Press this to entertain the crowd with your showmanship. The more you do this, the more gold they will give you for a victory. Be careful as it lowers your defence dramatically.";
   optionH.tooltip = "Psyche Up. Press this to enter a trance-like state. If you can psyche up three times without being hurt, you will launch a devastating, grievous attack.";
   optionA.onRelease = function()
   {
      getphase("jumpleft");
   };
   optionB.onRelease = function()
   {
      getphase("walkleft");
   };
   optionC.onRelease = function()
   {
      getphase("shove");
   };
   optionD.onRelease = function()
   {
      getphase("power_attack");
   };
   optionE.onRelease = function()
   {
      getphase("normal_attack");
   };
   optionF.onRelease = function()
   {
      getphase("quick_attack");
   };
   optionG.onRelease = function()
   {
      getphase("wincrowd");
   };
   optionH.onRelease = function()
   {
      getphase("psyche_up");
   };
}
else
{
   if(ah.herolevel < 3)
   {
      optionH._visible = false;
   }
   if(ah.herolevel < 7)
   {
      optionG._visible = false;
   }
   optionA.gotoAndStop(13);
   optionB.gotoAndStop(14);
   optionC.gotoAndStop(15);
   optionD.gotoAndStop(8);
   optionE.gotoAndStop(9);
   optionF.gotoAndStop(10);
   if(ah.psyche_up <= 1)
   {
      optionG.gotoAndStop(26);
   }
   if(ah.psyche_up == 2)
   {
      optionG.gotoAndStop(27);
   }
   if(ah.psyche_up >= 3)
   {
      optionG.gotoAndStop(28);
   }
   optionH.gotoAndStop(30);
   optionA.optiontext = "Power (" + ah.power_percentage + " % chance)";
   optionB.optiontext = "Normal(" + ah.normal_percentage + " % chance)";
   optionC.optiontext = "Quick (" + ah.quick_percentage + " % chance)";
   optionD.optiontext = "Jump backward";
   optionE.optiontext = "Walk backward";
   optionF.optiontext = "Shove enemy";
   optionG.optiontext = "Psyche Up " + ah.psyche_up + " /3";
   optionH.optiontext = "Win the Crowd";
   optionA.tooltip = "Power attack. Power attacks sap a lot of energy and are the least likely to hit, but will inflict the most damage if successful.";
   optionB.tooltip = "Normal attack. A standard hack, thrust or bash. Their chance of hitting is based on several factors, including your attack vs your opponent\'s defence, and random chance.";
   optionC.tooltip = "Quick attack. These attacks don\'t use much energy and have the highest chance of doing damage. However most quick attacks will only do minimal grazing damage to your opponent.";
   optionD.tooltip = "Jump backward. Press this to leap out of danger. Jumping saps your energy quickly. The height and distance of your jump is determined by your agility.";
   optionE.tooltip = "Walk backward. Press this to step away from your enemy. Useful when your health is low, but be aware that jumping saps your energy quickly. The distance you can walk is determined by your agility.";
   optionF.tooltip = "Shove enemy. Press this to push your opponent backwards and give yourself some breathing space. The stronger you are , the further you push your foe.) ";
   optionG.tooltip = "Psyche Up. Press this to enter a trance-like state. If you can psyche up three times without being hurt, you will launch a devastating, grievous attack.";
   optionH.tooltip = "Win the Crowd. Press this to entertain the crowd with your showmanship. The more you do this, the more gold they will give you for a victory. Be careful as it lowers your defence dramatically.";
   optionA.onRelease = function()
   {
      getphase("power_attack");
   };
   optionB.onRelease = function()
   {
      getphase("normal_attack");
   };
   optionC.onRelease = function()
   {
      getphase("quick_attack");
   };
   optionD.onRelease = function()
   {
      getphase("jumpright");
   };
   optionE.onRelease = function()
   {
      getphase("walkright");
   };
   optionF.onRelease = function()
   {
      getphase("shove");
   };
   optionG.onRelease = function()
   {
      getphase("psyche_up");
   };
   optionH.onRelease = function()
   {
      getphase("wincrowd");
   };
}
}
