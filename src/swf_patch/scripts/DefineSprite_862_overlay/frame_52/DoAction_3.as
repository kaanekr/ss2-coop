function check_inventory(which_item)
{
   if(spell_selected == true)
   {
      return false;
   }
   if(spell_selected != true)
   {
      i = 1;
      while(i <= 6)
      {
         if(inventory_array[i] == which_item && which_item != 1)
         {
            item_used = Number(which_item);
            return true;
         }
         i++;
      }
   }
}
function use_item(which_item)
{
   spell_selected = true;
   i = 1;
   while(i <= 6)
   {
      if(inventory_array[i] == which_item && which_item != 1)
      {
         _root.game.villain.inventory_action = which_item;
         item_used = null;
         _root.game.villain["inventory" + i] = 1;
         inventory_array = new Array(0,_root.game.villain.inventory1,_root.game.villain.inventory2,_root.game.villain.inventory3,_root.game.villain.inventory4,_root.game.villain.inventory5,_root.game.villain.inventory6);
         spell_selected = false;
         break;
      }
      i++;
   }
}
function villain_cast_spells()
{
   inventory_array = new Array(1,_root.game.villain.inventory1,_root.game.villain.inventory2,_root.game.villain.inventory3,_root.game.villain.inventory4,_root.game.villain.inventory5,_root.game.villain.inventory6);
   if(randomBetween(1,100) > 10)
   {
      if(check_inventory(43) == true && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 1.5)
      {
         villaindecisionA = "cast_rejuvinate";
         use_item(item_used);
      }
      else if(check_inventory(5) == true && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(46) == true && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 2)
      {
         villaindecisionA = "cast_regenerate";
         use_item(item_used);
      }
      else if(check_inventory(4) == true && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(3) == true && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(2) == true && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(49) == true)
      {
         villaindecisionA = "cast_death_from_above";
         use_item(item_used);
      }
      else if(check_inventory(42) == true && _root.arena.fightdistance < 300)
      {
         villaindecisionA = "cast_colossus";
         use_item(item_used);
      }
      else if(check_inventory(33) == true && _root.arena.fightdistance < 500)
      {
         villaindecisionA = "cast_little_fat_kid";
         use_item(item_used);
      }
      else if(check_inventory(9) == true && _root.game.villain.armourclass < _root.game.villain.armourclass_max / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(8) == true && _root.game.villain.armourclass < _root.game.villain.armourclass_max / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(7) == true && _root.game.villain.staminaleft < _root.game.villain.staminamax / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(6) == true && _root.game.villain.staminaleft < _root.game.villain.staminamax / 2)
      {
         villaindecisionA = "drink_potion";
         use_item(item_used);
      }
      else if(check_inventory(32) == true)
      {
         villaindecisionA = "cast_dire_fireball";
         use_item(item_used);
      }
      else if(check_inventory(35) == true)
      {
         villaindecisionA = "cast_frightning_bolt";
         use_item(item_used);
      }
      else if(check_inventory(31) == true)
      {
         villaindecisionA = "cast_hell_fireball";
         use_item(item_used);
      }
      else if(check_inventory(34) == true)
      {
         villaindecisionA = "cast_lightning_bolt";
         use_item(item_used);
      }
      else if(check_inventory(30) == true)
      {
         villaindecisionA = "cast_fireball";
         use_item(item_used);
      }
      else if(check_inventory(44) == true && _root.arena.fightdistance < 300)
      {
         villaindecisionA = "cast_weaken_armour";
         use_item(item_used);
      }
      else if(check_inventory(37) == true && _root.arena.fightdistance < 200 && _root.game.villain.equipped_weapon != 2)
      {
         villaindecisionA = "cast_whirlwind";
         use_item(item_used);
      }
      else if(check_inventory(36) == true && _root.arena.fightdistance > 500 && _root.game.villain.equipped_weapon != 2)
      {
         villaindecisionA = "cast_ghost_strike";
         use_item(item_used);
      }
      else if(check_inventory(41) == true && _root.arena.fightdistance < 400)
      {
         villaindecisionA = "cast_bloodlust";
         use_item(item_used);
      }
      else if(check_inventory(45) == true)
      {
         villaindecisionA = "cast_boundless_energy";
         use_item(item_used);
      }
      else if(check_inventory(38) == true && _root.arena.fightdistance < 400 && _root.game.villain.armourclass < _root.game.villain.armourclass_max / 2)
      {
         villaindecisionA = "cast_gale";
         use_item(item_used);
      }
      else if(check_inventory(39) == true && _root.arena.fightdistance > 300)
      {
         villaindecisionA = "cast_command";
         use_item(item_used);
      }
      else if(check_inventory(48) == true && _root.arena.fightdistance < 250 && _root.game.villain.hitpoints < _root.game.villain.hitpointsmax / 2)
      {
         villaindecisionA = "cast_teleport";
         use_item(item_used);
      }
      else if(check_inventory(40) == true && _root.arena.fightdistance > 300)
      {
         villaindecisionA = "cast_swiftsandals";
         use_item(item_used);
      }
      else if(check_inventory(47) == true && _root.arena.fightdistance > 300)
      {
         villaindecisionA = "cast_adulation";
         use_item(item_used);
      }
   }
}
