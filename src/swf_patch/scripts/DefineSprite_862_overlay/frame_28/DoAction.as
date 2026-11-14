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
      var wantLbl28 = ah.using_bow != true ? (_root.arena.fightdistance < ah.weapon_range ? "closerange_warrior" : "longrange_warrior") : (_root.arena.fightdistance < 100 + ah.physical_size ? "closerange_archer" : "longrange_archer");
      if(wantLbl28 != "closerange_archer")
      {
         gotoAndStop(wantLbl28);
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
   optionH._visible = false;
   optionA.gotoAndStop(7);
   optionB.gotoAndStop(6);
   optionC.gotoAndStop(16);
   optionD.gotoAndStop(8);
   optionE.gotoAndStop(24);
   optionF.gotoAndStop(18);
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
      optionH.gotoAndStop(28);
   }
   optionA.optiontext = "Jump backward";
   optionB.optiontext = "Walk backward";
   optionC.optiontext = "Shove enemy";
   optionD.optiontext = "Jump forward";
   optionE.optiontext = "Bash (" + ah.bash_percentage + " % chance)";
   optionF.optiontext = "Taunt (" + ah.taunt_percentage + " %)";
   optionG.optiontext = "Win the Crowd";
   optionH.optiontext = "Psyche Up " + ah.psyche_up + " /3";
   optionA.tooltip = "Jump backward. Press this to leap out of danger. Jumping saps your energy quickly. The height and distance of your jump is determined by your agility.";
   optionB.tooltip = "Walk backward. Press this to step away from your enemy. Useful when your health is low, but be aware that jumping saps your energy quickly. The distance you can walk is determined by your agility.";
   optionC.tooltip = "Shove enemy. Press this to push your opponent backwards and give yourself some breathing space. The stronger you are , the further you push your foe.) ";
   optionD.tooltip = "Jump forward. Press this to leap towards your enemy. Jumping uses a lot of energy but is faster than walking. The height and distance of your jump is determined by your agility.";
   optionE.tooltip = "Bash attack. A weak and clumsy attack only used when you are too close to use your ranged weapon. Unlikely to hit, and if it does, unlikely to do much damage.";
   optionF.tooltip = "Taunt enemy. Press this to yell taunts at your enemy (only appears if your enegy is high enough). If you have a high charisma, your taunts will have a variety of affects , such as forcing your enemy to charge at you,knocking them backwards or forwards, or even doing noise damage.";
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
      getphase("jumpright");
   };
   optionE.onRelease = function()
   {
      getphase("bash_attack");
   };
   optionF.onRelease = function()
   {
      getphase("taunt");
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
   optionG._visible = false;
   optionA.gotoAndStop(7);
   optionB.gotoAndStop(21);
   optionC.gotoAndStop(19);
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
   optionA.optiontext = "Jump Forward";
   optionB.optiontext = "Bash (" + ah.bash_percentage + " % chance)";
   optionC.optiontext = "Taunt (" + ah.taunt_percentage + " %)";
   optionD.optiontext = "Jump backward";
   optionE.optiontext = "Walk backward";
   optionF.optiontext = "Shove enemy";
   optionG.optiontext = "Psyche Up " + ah.psyche_up + " /3";
   optionH.optiontext = "Win the Crowd";
   optionA.tooltip = "Jump forward. Press this to leap towards your enemy. Jumping uses a lot of energy but is faster than walking. The height and distance of your jump is determined by your agility.";
   optionB.tooltip = "Normal attack. A standard hack, thrust or bash. Their chance of hitting is based on several factors, including your attack vs your opponent\'s defence, and random chance.";
   optionC.tooltip = "Quick attack. These attacks don\'t use much energy and have the highest chance of doing damage. However most quick attacks will only do minimal grazing damage to your opponent.";
   optionD.tooltip = "Jump backward. Press this to leap out of danger. Jumping saps your energy quickly. The height and distance of your jump is determined by your agility.";
   optionE.tooltip = "Bash attack. A weak and clumsy attack only used when you are too close to use your ranged weapon. Unlikely to hit, and if it does, unlikely to do much damage.";
   optionF.tooltip = "Taunt enemy. Press this to yell taunts at your enemy (only appears if your enegy is high enough). If you have a high charisma, your taunts will have a variety of affects , such as forcing your enemy to charge at you,knocking them backwards or forwards, or even doing noise damage.";
   optionG.tooltip = "Psyche Up. Press this to enter a trance-like state. If you can psyche up three times without being hurt, you will launch a devastating, grievous attack.";
   optionH.tooltip = "Win the Crowd. Press this to entertain the crowd with your showmanship. The more you do this, the more gold they will give you for a victory. Be careful as it lowers your defence dramatically.";
   optionA.onRelease = function()
   {
      getphase("jumpleft");
   };
   optionB.onRelease = function()
   {
      getphase("bash_attack");
   };
   optionC.onRelease = function()
   {
      getphase("taunt");
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
