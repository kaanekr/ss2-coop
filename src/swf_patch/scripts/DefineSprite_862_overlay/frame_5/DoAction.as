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
      var wantLbl5 = ah.using_bow != true ? (_root.arena.fightdistance < ah.weapon_range ? "closerange_warrior" : "longrange_warrior") : (_root.arena.fightdistance < 100 + ah.physical_size ? "closerange_archer" : "longrange_archer");
      if(wantLbl5 != "longrange_warrior")
      {
         gotoAndStop(wantLbl5);
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
   optionD.gotoAndStop(8);
   optionE.gotoAndStop(9);
   optionF.gotoAndStop(12);
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
   optionD.optiontext = "Jump forward";
   optionE.optiontext = "Walk forward";
   optionF.optiontext = "Charge (" + ah.power_percentage + " %)";
   optionG.optiontext = "Win the Crowd";
   optionH.optiontext = "Psyche Up " + ah.psyche_up + " /3";
   optionA.tooltip = "Jump backward. Press this to leap out of danger. Jumping saps your energy quickly. The height and distance of your jump is determined by your agility.";
   optionB.tooltip = "Walk backward. Press this to step away from your enemy. Useful when your health is low, but be aware that jumping saps your energy quickly. The distance you can walk is determined by your agility.";
   optionD.tooltip = "Jump forward. Press this to leap towards your enemy. Jumping uses a lot of energy but is faster than walking. The height and distance of your jump is determined by your agility.";
   optionE.tooltip = "Walk forward. Press this to advance towards your enemy. Your combat options will change if you are close to your foe.";
   optionF.tooltip = "Charge enemy. Press this to perform an acrobatic leaping attack at your enemy. This uses a lot of energy but can knock your enemy backwards if successful.";
   optionG.tooltip = "Win the Crowd. Press this to entertain the crowd with your showmanship. The more you do this, the more gold they will give you for a victory. Be careful as it lowers your defence dramatically.";
   optionH.tooltip = "Psyche Up. Press this to enter a trance-like state. If you press this three times, you will launch a devastating, grievous attack.";
   if(ah.staminaleft / ah.staminamax * 100 >= 50)
   {
      optionC.optiontext = "Taunt (" + ah.taunt_percentage + " %)";
      optionC.gotoAndStop(18);
      optionC.tooltip = "Taunt enemy. Press this to yell taunts at your enemy (only appears if your enegy is high enough). If you have a high charisma, your taunts will have a variety of affects , such as forcing your enemy to charge at you,knocking them backwards or forwards, or even doing noise damage.";
      optionC.onRelease = function()
      {
         getphase("taunt");
      };
   }
   else
   {
      optionC.optiontext = "Rest and heal";
      optionC.gotoAndStop(11);
      optionC.tooltip = "Rest and heal. Press this to take a moment to replentish your energy and health. You will recover faster if you have a high stamina. Sometimes your energy reaches zero, and resting will be forced upon you ( in this case you skip a turn ) ";
      optionC.onRelease = function()
      {
         getphase("rest");
      };
   }
   optionA.onRelease = function()
   {
      getphase("jumpleft");
   };
   optionB.onRelease = function()
   {
      getphase("walkleft");
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
      getphase("chargeright");
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
   optionA.gotoAndStop(7);
   optionB.gotoAndStop(6);
   optionC.gotoAndStop(17);
   optionD.gotoAndStop(8);
   optionE.gotoAndStop(9);
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
   optionA.optiontext = "Jump forward";
   optionB.optiontext = "Walk forward";
   optionC.optiontext = "Charge (" + ah.power_percentage + " %)";
   optionD.optiontext = "Jump backward";
   optionE.optiontext = "Walk backward";
   optionG.optiontext = "Psyche Up " + ah.psyche_up + " /3";
   optionH.optiontext = "Win the Crowd";
   optionA.tooltip = "Jump forward. Press this to leap towards your enemy. Jumping uses a lot of energy but is faster than walking. The height and distance of your jump is determined by your agility.";
   optionB.tooltip = "Walk forward. Press this to advance towards your enemy. Your combat options will change if you are close to your foe.";
   optionC.tooltip = "Charge enemy. Press this to perform an acrobatic leaping attack at your enemy. This uses a lot of energy but can knock your enemy backwards if successful.";
   optionD.tooltip = "Jump backward. Press this to leap out of danger. Jumping saps your energy quickly. The height and distance of your jump is determined by your agility.";
   optionE.tooltip = "Walk backward. Press this to step away from your enemy. Useful when your health is low, but be aware that jumping saps your energy quickly. The distance you can walk is determined by your agility.";
   if(ah.staminaleft / ah.staminamax * 100 >= 50)
   {
      optionF.optiontext = "Taunt (" + ah.taunt_percentage + " %)";
      optionF.gotoAndStop(19);
      optionF.tooltip = "Taunt enemy. Press this to yell taunts at your enemy (only appears if your enegy is high enough). If you have a high charisma, your taunts will have a variety of affects , such as forcing your enemy to charge at you,knocking them backwards or forwards, or even doing noise damage.";
      optionF.onRelease = function()
      {
         getphase("taunt");
      };
   }
   else
   {
      optionF.optiontext = "Rest and heal";
      optionF.gotoAndStop(11);
      optionF.tooltip = "Rest and heal. Press this to take a moment to replentish your energy and health. You will recover faster if you have a high stamina. Sometimes your energy reaches zero, and resting will be forced upon you ( in this case you skip a turn ) ";
      optionF.onRelease = function()
      {
         getphase("rest");
      };
   }
   optionG.tooltip = "Psyche Up. Press this to enter a trance-like state. If you can psyche up three times without being hurt, you will launch a devastating, grievous attack.";
   optionH.tooltip = "Win the Crowd. Press this to entertain the crowd with your showmanship. The more you do this, the more gold they will give you for a victory. Be careful as it lowers your defence dramatically.";
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
      getphase("chargeleft");
   };
   optionD.onRelease = function()
   {
      getphase("jumpright");
   };
   optionE.onRelease = function()
   {
      getphase("walkright");
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
