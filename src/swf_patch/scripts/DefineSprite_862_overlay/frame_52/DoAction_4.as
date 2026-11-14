function randomBetween(a, b)
{
   if(_global.coop.enabled == true && _global.coopRandBetween != undefined)
   {
      return _global.coopRandBetween(a,b);
   }
   return a + Math.floor(Math.random() * (b - a + 1));
}
villainChooseAction = function()
{
   var tgtGame = _global.coop.enabled == true && _global.coop.targetHero == 2 ? _root.game.hero2 : _root.game.hero;
   var tgtClip = _global.coop.enabled == true && _global.coop.targetHero == 2 ? _root.arena.gladiators.hero2 : _root.arena.gladiators.hero;
   attack_chances(_root.game.villain,tgtGame);
   if(_root.game.villain.character_name == "Fearful prisoner")
   {
      _root.game.villain.taunted1 = false;
      _root.game.villain.taunted2 = false;
   }
   if(_root.game.villain.equipped_weapon == 1 && _root.arena.fightdistance < _root.game.villain.weapon_range || _root.game.villain.equipped_weapon == 2 && _root.arena.fightdistance >= 200)
   {
      if(_root.game.villain.staminaleft > 10)
      {
         choices = randomBetween(1,100);
         if(choices < 25)
         {
            if(_root.game.villain.equipped_weapon == 1)
            {
               villaindecisionA = "quick_attack";
            }
            else
            {
               if(_root.arena.gladiators.villain._x < tgtClip._x)
               {
                  villaindecisionA = "sniperight";
               }
               if(_root.arena.gladiators.villain._x >= tgtClip._x)
               {
                  villaindecisionA = "snipeleft";
               }
            }
         }
         if(choices >= 25 && choices < 55)
         {
            if(_root.game.villain.equipped_weapon == 1)
            {
               villaindecisionA = "normal_attack";
            }
            else
            {
               if(_root.arena.gladiators.villain._x < tgtClip._x && _root.game.villain.ammo_left > 0)
               {
                  villaindecisionA = "bombardright";
               }
               if(_root.arena.gladiators.villain._x >= tgtClip._x && _root.game.villain.ammo_left > 0)
               {
                  villaindecisionA = "bombardleft";
               }
            }
         }
         if(choices >= 55 && choices < 80)
         {
            if(_root.game.villain.equipped_weapon == 1)
            {
               villaindecisionA = "power_attack";
            }
            else
            {
               if(_root.arena.gladiators.villain._x < tgtClip._x)
               {
                  villaindecisionA = "bombardright";
               }
               if(_root.arena.gladiators.villain._x >= tgtClip._x)
               {
                  villaindecisionA = "bombardleft";
               }
            }
         }
         if(choices >= 80 && choices < 90)
         {
            if(_root.game.villain.equipped_weapon == 1)
            {
               villaindecisionA = "shove";
            }
            else
            {
               villaindecisionA = "taunt";
            }
         }
         if(choices >= 90 && choices < 95)
         {
            if(_root.arena.gladiators.villain._x < tgtClip._x)
            {
               villaindecisionA = "walkleft";
            }
            if(_root.arena.gladiators.villain._x >= tgtClip._x)
            {
               villaindecisionA = "walkright";
            }
         }
         if(choices >= 95)
         {
            if(_root.arena.gladiators.villain._x < tgtClip._x)
            {
               villaindecisionA = "jumpleft";
            }
            if(_root.arena.gladiators.villain._x >= tgtClip._x)
            {
               villaindecisionA = "jumpright";
            }
         }
      }
      else
      {
         villaindecisionA = "rest";
      }
   }
   else if(_root.arena.gladiators.villain._x < tgtClip._x)
   {
      choices = randomBetween(1,100);
      if(choices < 50)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "walkright";
         }
         else
         {
            villaindecisionA = "walkleft";
         }
      }
      if(choices >= 50 && choices < 70)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "jumpright";
         }
         else
         {
            villaindecisionA = "jumpleft";
         }
      }
      if(choices >= 70 && choices < 75)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "chargeright";
         }
         else
         {
            villaindecisionA = "jumpleft";
         }
      }
      if(choices >= 75 && choices < 80)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "walkleft";
         }
         else
         {
            villaindecisionA = "walkright";
         }
      }
      if(choices >= 80 && choices < 85)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "jumpleft";
         }
         else
         {
            villaindecisionA = "jumpright";
         }
      }
      if(choices >= 85 && choices <= 95)
      {
         if(_root.game.villain.staminaleft / _root.game.villain.staminamax * 100 >= 40)
         {
            villaindecisionA = "taunt";
         }
         else
         {
            villaindecisionA = "rest";
         }
      }
      if(choices > 95)
      {
         if(_root.game.villain.staminaleft / _root.game.villain.staminamax * 100 >= 30)
         {
            villaindecisionA = "wincrowd";
         }
         else
         {
            villaindecisionA = "rest";
         }
      }
   }
   else
   {
      choices = randomBetween(1,100);
      if(choices < 50)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "walkleft";
         }
         else
         {
            villaindecisionA = "walkright";
         }
      }
      if(choices >= 50 && choices < 70)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "jumpleft";
         }
         else
         {
            villaindecisionA = "jumpright";
         }
      }
      if(choices >= 70 && choices < 75)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "chargeleft";
         }
         else
         {
            villaindecisionA = "jumpright";
         }
      }
      if(choices >= 75 && choices < 80)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "walkright";
         }
         else
         {
            villaindecisionA = "walkleft";
         }
      }
      if(choices >= 80 && choices < 85)
      {
         if(_root.game.villain.equipped_weapon == 1)
         {
            villaindecisionA = "jumpright";
         }
         else
         {
            villaindecisionA = "jumpleft";
         }
      }
      if(choices >= 85 && choices <= 95)
      {
         if(_root.game.villain.staminaleft / _root.game.villain.staminamax * 100 >= 40)
         {
            villaindecisionA = "taunt";
         }
         else
         {
            villaindecisionA = "rest";
         }
      }
      if(choices > 95)
      {
         if(_root.game.villain.staminaleft / _root.game.villain.staminamax * 100 >= 30)
         {
            villaindecisionA = "wincrowd";
         }
         else
         {
            villaindecisionA = "rest";
         }
      }
   }
   random_swap = randomBetween(1,100);
   if(random_swap > 80 && _root.game.villain.secondary_weapon != 0 && _root.game.villain.ammo_left > 0)
   {
      if(_root.game.villain.equipped_weapon == 2 && _root.arena.fightdistance < 200 || _root.game.villain.equipped_weapon == 1 && _root.arena.fightdistance >= 200)
      {
         villaindecisionA = "swap_weapons";
      }
   }
   psyche_up_chance = randomBetween(1,100);
   if(psyche_up_chance > 90)
   {
      if(_root.game.villain.herolevel >= 10 && _root.game.villain.equipped_weapon == 1)
      {
         villaindecisionA = "psyche_up";
      }
      else
      {
         villaindecisionA = "rest";
      }
   }
   if(_root.game.villain.psyche_up > 1)
   {
      psyche_up_chance = randomBetween(1,100);
      if(psyche_up_chance > 10)
      {
         villaindecisionA = "psyche_up";
      }
      else
      {
         _root.game.villain.psyche_up = 1;
      }
   }
   if(_global.coop.enabled != true && _root.game.hero.herolevel == 1)
   {
      if(_root.arena.gladiators.villain.gladiator_dir == "right")
      {
         villaindecisionA = "walkright";
      }
      if(_root.arena.gladiators.villain.gladiator_dir == "left")
      {
         villaindecisionA = "walkleft";
      }
   }
   if(_root.game.villain.staminaleft <= 0)
   {
      villaindecisionA = "rest";
   }
   if(_root.game.villain.ammo_left <= 0 && _root.game.villain.equipped_weapon == 2)
   {
      villaindecisionA = "swap_weapons";
   }
   if(_root.game.villain.taunted1 == true)
   {
      if(_root.arena.gladiators.villain.gladiator_dir == "right")
      {
         _root.game.villain.taunted1 = false;
         villaindecisionA = "runright";
      }
      if(_root.arena.gladiators.villain.gladiator_dir == "left")
      {
         _root.game.villain.taunted1 = false;
         villaindecisionA = "runleft";
      }
   }
   if(_root.game.villain.taunted2 == true)
   {
      if(_root.arena.gladiators.villain.gladiator_dir == "right")
      {
         _root.game.villain.taunted2 = false;
         villaindecisionA = "runright";
      }
      if(_root.arena.gladiators.villain.gladiator_dir == "left")
      {
         _root.game.villain.taunted2 = false;
         villaindecisionA = "runleft";
      }
   }
   if(_root.game.villain.frozen == true)
   {
      _root.game.villain.frozen = false;
      villaindecisionA = "frozen";
   }
   if(_root.game.villain.burning == true)
   {
      _root.game.villain.burning = false;
      villaindecisionA = "burning";
   }
   if(_root.game.villain.poison == true)
   {
      _root.game.villain.poison = false;
      villaindecisionA = "poisoned";
   }
   if(_root.game.villain.life_stolen == true)
   {
      _root.game.villain.life_stolen = false;
      villaindecisionA = "life_stolen";
   }
   villain_cast_spells();
};
