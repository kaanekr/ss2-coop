var ov = this;
var coopPhaseDone = false;
function randomBetween(a, b)
{
   if(_global.coop.enabled == true && _global.coopRandBetween != undefined)
   {
      return _global.coopRandBetween(a,b);
   }
   return a + Math.floor(Math.random() * (b - a + 1));
}
function coopFacePair(aClip, bClip)
{
   if(aClip._x < bClip._x)
   {
      aClip.gladiator_dir = "right";
      if(aClip._xscale < 0)
      {
         aClip._xscale = - aClip._xscale;
      }
      bClip.gladiator_dir = "left";
      if(bClip._xscale > 0)
      {
         bClip._xscale = - bClip._xscale;
      }
   }
   else
   {
      aClip.gladiator_dir = "left";
      if(aClip._xscale > 0)
      {
         aClip._xscale = - aClip._xscale;
      }
      bClip.gladiator_dir = "right";
      if(bClip._xscale < 0)
      {
         bClip._xscale = - bClip._xscale;
      }
   }
}
function coopClampPos(clip)
{
   if(clip != undefined)
   {
      if(clip._x < -2100)
      {
         clip._x = -2100;
      }
      if(clip._x > 2100)
      {
         clip._x = 2100;
      }
      clip._y = 200;
   }
}
function coopSnapClipTween(clip)
{
   if(clip != undefined && clip._coopKnockTween != undefined && clip._coopKnockTween != null)
   {
      clip._coopKnockTween.fforward();
      clip._coopKnockTween.stop();
      clip._coopKnockTween = null;
   }
}
function coopSnapTweens()
{
   coopSnapClipTween(_root.arena.gladiators.hero);
   coopSnapClipTween(_root.arena.gladiators.hero2);
   coopSnapClipTween(_root.arena.gladiators.villain);
   defender_smashed = false;
}
function coopResetClipPose(clip, gObj)
{
   if(clip != undefined && gObj != undefined)
   {
      coopClampPos(clip);
      if(gObj.hitpoints > 0 && clip.coopKO != true)
      {
         clip.gotoAndPlay("Standing");
         if(gObj.psyche_up == 2)
         {
            clip.gotoAndStop("psyche_charging");
         }
         if(gObj.psyche_up == 3)
         {
            clip.gotoAndStop("psyche_charging2");
         }
      }
   }
}
function coopResetPoses()
{
   coopResetClipPose(_root.arena.gladiators.hero,_root.game.hero);
   coopResetClipPose(_root.arena.gladiators.hero2,_root.game.hero2);
   coopResetClipPose(_root.arena.gladiators.villain,_root.game.villain);
   if(_root.arena.getfightdistance != undefined)
   {
      _root.arena.getfightdistance();
   }
}
function coopBuildSyncPayload()
{
   var h1c = _root.arena.gladiators.hero;
   var h2c = _root.arena.gladiators.hero2;
   var vc = _root.arena.gladiators.villain;
   var h1 = _root.game.hero;
   var h2 = _root.game.hero2;
   var v = _root.game.villain;
   return {seq:_global.coop.syncSeq,turn:_global.coop.activeTurn,seed:_global.coop.seed,h1x:Math.round(h1c._x),h2x:Math.round(h2c._x),vx:Math.round(vc._x),h1xs:Math.round(h1c._xscale),h2xs:Math.round(h2c._xscale),vxs:Math.round(vc._xscale),h1hp:Math.round(h1.hitpoints),h2hp:Math.round(h2.hitpoints),vhp:Math.round(v.hitpoints),h1stam:Math.round(h1.staminaleft),h2stam:Math.round(h2.staminaleft),vstam:Math.round(v.staminaleft),h1arm:Math.round(h1.armourclass),h2arm:Math.round(h2.armourclass),varm:Math.round(v.armourclass),dead1:h1.hitpoints <= 0 || h1c.coopKO == true ? 1 : 0,dead2:h2.hitpoints <= 0 || h2c.coopKO == true ? 1 : 0,vdead:v.hitpoints <= 0 ? 1 : 0};
}
function get_percentage(a, b)
{
   return a / b * 100;
}
function add_percentage(a, b)
{
   b /= 100;
   return Math.ceil(a * b);
}
function check_stats(whichcharacter)
{
   if(whichcharacter.staminaleft >= whichcharacter.staminamax)
   {
      whichcharacter.staminaleft = whichcharacter.staminamax;
   }
   if(whichcharacter.staminaleft <= 0)
   {
      whichcharacter.staminaleft = 0;
   }
   if(whichcharacter.hitpoints >= whichcharacter.hitpointsmax)
   {
      whichcharacter.hitpoints = whichcharacter.hitpointsmax;
   }
   if(whichcharacter.hitpoints <= 0)
   {
      whichcharacter.hitpoints = 0;
   }
   if(whichcharacter.armourclass >= whichcharacter.armourclass_max)
   {
      whichcharacter.armourclass = whichcharacter.armourclass_max;
   }
   if(whichcharacter.armourclass <= 0)
   {
      whichcharacter.armourclass = 0;
   }
}
function check_flipping(which_icon, whichcharacter, icon_above)
{
   if(whichcharacter._xscale < 0 || which_icon._xscale < 0)
   {
      which_icon._xscale = - which_icon._xscale;
   }
   which_icon._y = -240;
}
function magic_damage_character(defender, attacker, game_defender, game_attacker, damage_method, bonus_frame, damage)
{
   bonus_icon = defender.attachMovie("bonus_icon","bonus_icon",25005);
   if(game_defender.gladiator_dir == "left")
   {
      bonus_icon._x += 100;
   }
   else
   {
      bonus_icon._x -= 100;
   }
   bonus_icon.damage_splat.gotoAndStop(bonus_frame);
   bonus_icon.bonus = Math.ceil(damage);
   check_flipping(bonus_icon,defender);
   _global.crowd_action = 2;
   defender.gotoAndPlay(damage_method);
   if(game_defender.armourclass > 0)
   {
      game_defender.armourclass_temp = game_defender.armourclass;
      game_defender.armourclass -= damage;
      if(game_defender.armourclass < 0)
      {
         damage -= game_defender.armourclass_temp;
         game_defender.armourclass_temp = 0;
      }
   }
   if(game_defender.armourclass <= 0)
   {
      game_defender.hitpoints -= damage;
   }
   game_defender.psyche_up = 1;
   stamina_bonus = get_percentage(game_defender.breastplate,100);
   stamina_bonus = add_percentage(damage,stamina_bonus);
   game_defender.staminaleft += stamina_bonus;
   check_stats(game_defender);
   if(game_defender.hitpoints <= 0 || game_defender.hitpoints < game_defender.hitpointsmax && _global.fight_mode != "tournament")
   {
      _global.phasecomplete = true;
      if(_global.fight_mode != "duel")
      {
         death(defender,"slain");
      }
      else
      {
         death(defender,"yield");
      }
   }
}
function damagecharacter(defender, attacker, game_defender, game_attacker, damage_method, attack_direction)
{
   damage_icon = defender.attachMovie("damage_icon","damage_icon",25000);
   damage_icon.damage_splat.gotoAndStop(1);
   if(damage_method == "critical")
   {
      _global.crowd_action = 8;
      damage_icon.damage_splat.gotoAndStop(3);
   }
   if(damage_method == "taunt")
   {
      _global.crowd_action = 3;
      damage_method = "normal";
   }
   if(damage_method == "grievous")
   {
      _global.crowd_action = 20;
      damage_icon.damage_splat.gotoAndStop(5);
      game_defender.psyche_up = 1;
      game_attacker.psyche_up = 1;
   }
   damage_icon._xscale = damage_icon._yscale = 240 - _global.maxscale * 1.5;
   check_flipping(damage_icon,defender);
   damage = Math.ceil(damage);
   damage_icon.damage = this.damage;
   remove_armour_chance = randomBetween(1,100);
   if(damage_method == "grievous")
   {
      remove_armour(game_defender,defender,attack_direction);
   }
   if(remove_armour_chance > 66)
   {
      remove_armour(game_defender,defender,attack_direction);
   }
   if(damage_method == "normal" || damage_method == "grievous")
   {
      _global.crowd_action = 2;
      if(game_defender.armourclass > 0)
      {
         game_defender.armourclass_temp = game_defender.armourclass;
         game_defender.armourclass -= damage;
         if(game_defender.armourclass < 0)
         {
            damage_icon.damage_splat.gotoAndStop(2);
            damage -= game_defender.armourclass_temp;
            game_defender.armourclass_temp = 0;
         }
      }
   }
   if(game_defender.armourclass <= 0 || damage_method != "normal" && damage_method != "grievous")
   {
      if(damage_icon.damage_splat._currentframe == 1)
      {
         damage_icon.damage_splat.gotoAndStop(2);
      }
      game_defender.hitpoints -= damage;
   }
   stamina_bonus = get_percentage(game_defender.breastplate,100);
   stamina_bonus = add_percentage(damage,stamina_bonus);
   game_defender.staminaleft += stamina_bonus;
   check_stats(game_defender);
   if(game_defender.hitpoints <= 0 || game_defender.hitpoints < game_defender.hitpointsmax && _global.fight_mode != "tournament")
   {
      _global.phasecomplete = true;
      if(_global.fight_mode != "duel")
      {
         if(attack_direction <= 12)
         {
            death(defender,"slain");
         }
         else if(attack_direction == 20)
         {
            death(defender,"taunt");
         }
         else if(attack_direction >= 21 && attack_direction <= 23)
         {
            death(defender,"arrow");
         }
         else if(attack_direction == 30)
         {
            death(defender,"grievous");
         }
      }
      else
      {
         death(defender,"yield");
      }
   }
   if(attack_direction >= 5 && attack_direction <= 12 || attack_direction == 30)
   {
      randosmash = randomBetween(1,4);
      if(randosmash > 3 || attack_direction == 30)
      {
         if(defender.gladiator_dir == "left")
         {
            force = this.damage + game_attacker.strength * 6;
            if(force < 20)
            {
               force = 20;
            }
            if(force > 80)
            {
               defender.gotoAndPlay("knockback");
            }
         }
         else
         {
            force = - (this.damage + game_attacker.strength * 6);
            if(force > -20)
            {
               force = -20;
            }
            if(force < -80)
            {
               defender.gotoAndPlay("knockback");
            }
         }
         knockback(defender,force);
      }
   }
   game_defender.psyche_up = 1;
   magicweapon_percentage = randomBetween(1,100);
   if(magicweapon_percentage < game_attacker.weapon_enchantment_potency * 10)
   {
      if(game_attacker.equipped_weapon == 1 && game_attacker.weapon_enchantment_type == 2 || game_attacker.equipped_weapon == 2 && game_attacker.secondary_weapon_enchantment_type == 2)
      {
         game_defender.burning = true;
      }
      if(game_attacker.equipped_weapon == 1 && game_attacker.weapon_enchantment_type == 3 || game_attacker.equipped_weapon == 2 && game_attacker.secondary_weapon_enchantment_type == 3)
      {
         game_defender.frozen = true;
      }
      if(game_attacker.equipped_weapon == 1 && game_attacker.weapon_enchantment_type == 4 || game_attacker.equipped_weapon == 2 && game_attacker.secondary_weapon_enchantment_type == 4)
      {
         game_defender.poison = true;
      }
      if(game_attacker.equipped_weapon == 1 && game_attacker.weapon_enchantment_type == 5 || game_attacker.equipped_weapon == 2 && game_attacker.secondary_weapon_enchantment_type == 5)
      {
         game_defender.life_stolen = true;
      }
   }
}
function knockback(whichcharacter, force)
{
   _global.crowd_action = 1;
   _global.phasecomplete = true;
   defender_smashed = true;
   if(_global.coop.enabled == true)
   {
      coopSnapClipTween(whichcharacter);
      var kTw = new mx.transitions.Tween(whichcharacter,"_x",mx.transitions.easing.Regular.easeOut,whichcharacter._x,whichcharacter._x + force,18,false);
      whichcharacter._coopKnockTween = kTw;
      kTw.onMotionFinished = function()
      {
         if(whichcharacter._coopKnockTween == kTw)
         {
            whichcharacter._coopKnockTween = null;
         }
         defender_smashed = false;
      };
      return undefined;
   }
   var knock_defender = new mx.transitions.Tween(whichcharacter,"_x",mx.transitions.easing.Regular.easeOut,whichcharacter._x,whichcharacter._x + force,1,true);
   knock_defender.onMotionFinished = function()
   {
      knock_defender = null;
      defender_smashed = false;
   };
}
function death(whichcharacter, how_died)
{
   if(_global.coop.enabled == true)
   {
      if(whichcharacter == _root.arena.gladiators.villain)
      {
         coopSnapTweens();
         _root.game.hero.frozen = _root.game.hero.burning = _root.game.hero.poison = _root.game.hero.life_stolen = false;
         _root.game.hero2.frozen = _root.game.hero2.burning = _root.game.hero2.poison = _root.game.hero2.life_stolen = false;
         _root.game.villain.frozen = _root.game.villain.burning = _root.game.villain.poison = _root.game.villain.life_stolen = false;
         _root.game.hero.taunted1 = _root.game.hero.taunted2 = false;
         _root.game.hero2.taunted1 = _root.game.hero2.taunted2 = false;
         _root.game.villain.taunted1 = _root.game.villain.taunted2 = false;
         _global.deathsequence = how_died;
         if(_global.coopSend != undefined && _global.coop.role == "host")
         {
            _global.coop.lastOutcome = "won";
            _global.coop.syncSeq = Number(_global.coop.syncSeq) + 1;
            _global.coopSend("sync",coopBuildSyncPayload());
            _global.coopSend("end",{outcome:"won"});
         }
         delete ov.onEnterFrame;
         delete this.onEnterFrame;
         delete attacker.onEnterFrame;
         delete defender.onEnterFrame;
         delete nextphase;
         ov.gotoAndPlay("combatwon");
         return undefined;
      }
      if(whichcharacter == _root.arena.gladiators.hero || whichcharacter == _root.arena.gladiators.hero2)
      {
         var gChar = whichcharacter == _root.arena.gladiators.hero ? _root.game.hero : _root.game.hero2;
         var otherChar = whichcharacter == _root.arena.gladiators.hero ? _root.game.hero2 : _root.game.hero;
         gChar.hitpoints = 0;
         gChar.frozen = gChar.burning = gChar.poison = gChar.life_stolen = false;
         gChar.taunted1 = gChar.taunted2 = false;
         if(otherChar.hitpoints > 0)
         {
            if(whichcharacter.coopKO != true)
            {
               whichcharacter.coopKO = true;
               whichcharacter.gotoAndPlay(how_died == "yield" ? "Yield1" : "Death1");
               if(whichcharacter == defender && phase_decision == "cast_death_from_above")
               {
                  defender.struck = true;
               }
               if(whichcharacter == attacker && nextphase != undefined)
               {
                  attacker.struck = null;
                  nextphase();
               }
            }
            return undefined;
         }
         coopSnapTweens();
         _root.game.hero.frozen = _root.game.hero.burning = _root.game.hero.poison = _root.game.hero.life_stolen = false;
         _root.game.hero2.frozen = _root.game.hero2.burning = _root.game.hero2.poison = _root.game.hero2.life_stolen = false;
         _root.game.villain.frozen = _root.game.villain.burning = _root.game.villain.poison = _root.game.villain.life_stolen = false;
         _root.game.hero.taunted1 = _root.game.hero.taunted2 = false;
         _root.game.hero2.taunted1 = _root.game.hero2.taunted2 = false;
         _root.game.villain.taunted1 = _root.game.villain.taunted2 = false;
         _global.coop.lostClip = whichcharacter;
         _global.deathsequence = how_died;
         if(_global.coopSend != undefined && _global.coop.role == "host")
         {
            _global.coop.lastOutcome = "lost";
            _global.coop.syncSeq = Number(_global.coop.syncSeq) + 1;
            _global.coopSend("sync",coopBuildSyncPayload());
            _global.coopSend("end",{outcome:"lost"});
         }
         delete ov.onEnterFrame;
         delete this.onEnterFrame;
         delete attacker.onEnterFrame;
         delete defender.onEnterFrame;
         delete nextphase;
         ov.gotoAndPlay("combatlost");
         return undefined;
      }
   }
   _root.game.hero.frozen = false;
   _root.game.hero.burning = false;
   _root.game.hero.poison = false;
   _root.game.hero.life_stolen = false;
   _root.game.villain.frozen = false;
   _root.game.villain.burning = false;
   _root.game.villain.poison = false;
   _root.game.villain.life_stolen = false;
   _root.game.hero.taunted1 = false;
   _root.game.villain.taunted1 = false;
   _root.game.hero.taunted2 = false;
   _root.game.villain.taunted2 = false;
   _global.deathsequence = how_died;
   if(whichcharacter == _root.arena.gladiators.villain)
   {
      this.gotoAndPlay("combatwon");
   }
   if(whichcharacter == _root.arena.gladiators.hero)
   {
      this.gotoAndPlay("combatlost");
   }
   delete ov.onEnterFrame;
   delete attacker.onEnterFrame;
   delete defender.onEnterFrame;
   delete nextphase;
}
function defender_hurt(damage_method)
{
   criticalmiss = 0;
   animstate = String("hurt" + attack_direction);
   if(attack_direction >= 21 && attack_direction <= 23)
   {
      animstate = String("hurt" + (attack_direction - 20));
   }
   if(attack_direction == 30)
   {
      animstate = "knockback";
   }
   damagecharacter(defender,attacker,game_defender,game_attacker,damage_method,attack_direction);
   if(defender.coopKO != true)
   {
      defender.gotoAndPlay(animstate);
   }
}
function defender_blocked()
{
   _global.crowd_action = -2;
   animstate = String("defend" + attack_direction);
   if(attack_direction >= 21 && attack_direction <= 23)
   {
      animstate = String("defend" + (attack_direction - 20));
   }
   if(attack_direction == 30)
   {
      animstate = "defend12";
   }
   defend_icon = defender.attachMovie("defend_icon","defend_icon",25005);
   defend_icon._xscale = defend_icon._yscale = 240 - _global.maxscale * 1.5;
   check_flipping(defend_icon,defender);
   defender.gotoAndPlay(animstate);
}
function cast_spell_icon(which_avatar, spell_number)
{
   if(which_avatar == _root.arena.gladiators.hero || which_avatar == _root.arena.gladiators.hero2)
   {
      cast_spell = _root.arena.combat_panel.attachMovie("cast_spell_image","cast_spell_image",_root.arena.combat_panel.getNextHighestDepth(),{_x:60,_y:50});
   }
   else if(which_avatar == _root.arena.gladiators.villain)
   {
      cast_spell = _root.arena.combat_panel.attachMovie("cast_spell_image","cast_spell_image",_root.arena.combat_panel.getNextHighestDepth(),{_x:580,_y:50});
   }
   cast_spell.inventory_icons.gotoAndStop(spell_number);
   cast_spell.inventory_icons.battlebutton._visible = false;
   cast_spell.spellname = _root["inventory" + spell_number][1];
}
function add_stats_icon(which_character, which_avatar, stat, stat_number)
{
}
function check_spells(which_character, which_avatar)
{
   if(which_avatar.spell_colossus > 0)
   {
      which_avatar.spell_colossus -= 1;
   }
   if(which_avatar.spell_colossus == 0)
   {
      which_avatar._xscale = which_avatar._yscale = which_avatar.oldscale;
      which_character.strength = which_character.backup_strength;
      which_character.attack = which_character.backup_attack;
      which_avatar.spell_colossus = -1;
   }
   if(which_avatar.spell_little_fat_kid > 0)
   {
      which_avatar.spell_little_fat_kid -= 1;
   }
   if(which_avatar.spell_little_fat_kid == 0)
   {
      which_avatar._xscale = which_avatar._yscale = which_avatar.oldscale;
      which_character.strength = which_character.backup_strength;
      which_character.attack = which_character.backup_attack;
      which_avatar.spell_little_fat_kid = -1;
   }
   if(which_avatar.spell_swiftsandals > 0)
   {
      which_avatar.Rfoot.blendMode = "invert";
      which_avatar.Lfoot.blendMode = "invert";
      which_avatar.Rlowerleg.blendMode = "invert";
      which_avatar.Llowerleg.blendMode = "invert";
      which_avatar.spell_swiftsandals -= 1;
   }
   if(which_avatar.spell_swiftsandals == 0)
   {
      which_character.speed = which_character.backup_speed;
      which_avatar.Rfoot.blendMode = "normal";
      which_avatar.Lfoot.blendMode = "normal";
      which_avatar.Rlowerleg.blendMode = "normal";
      which_avatar.Llowerleg.blendMode = "normal";
      which_avatar.spell_swiftsandals = -1;
   }
   if(which_avatar.spell_bloodlust > 0)
   {
      which_avatar.Rlowerarm.blendMode = "difference";
      which_avatar.Llowerarm.blendMode = "difference";
      which_avatar.Rlowerarm.blendMode = "difference";
      which_avatar.Lupperarm.blendMode = "difference";
      which_avatar.spell_bloodlust -= 1;
   }
   if(which_avatar.spell_bloodlust == 0)
   {
      which_character.strength = which_character.backup_strength;
      which_character.defence = which_character.backup_defence;
      which_avatar.Rlowerarm.blendMode = "normal";
      which_avatar.Llowerarm.blendMode = "normal";
      which_avatar.Rlowerarm.blendMode = "normal";
      which_avatar.Lupperarm.blendMode = "normal";
      which_avatar.spell_bloodlust = -1;
   }
   if(which_avatar.spell_regenerate > 0)
   {
      which_avatar.spell_regenerate -= 1;
   }
   if(which_avatar.spell_boundless_energy > 0)
   {
      which_avatar.spell_boundless_energy -= 1;
   }
}
_root.delete_tooltips();
changeCombatants = function()
{
   _root.arena.gladiators.overlay_villain.gotoAndStop(1);
   if(_global.coop.enabled == true)
   {
      if(_global.coop.activeTurn == 1)
      {
         attacker = _root.arena.gladiators.hero;
         game_attacker = _root.game.hero;
         defender = _root.arena.gladiators.villain;
         game_defender = _root.game.villain;
      }
      else if(_global.coop.activeTurn == 2)
      {
         attacker = _root.arena.gladiators.hero2;
         game_attacker = _root.game.hero2;
         defender = _root.arena.gladiators.villain;
         game_defender = _root.game.villain;
      }
      else
      {
         if(villaindecisionA == null)
         {
            if(_root.game.hero.hitpoints <= 0)
            {
               _global.coop.targetHero = 2;
            }
            else if(_root.game.hero2.hitpoints <= 0)
            {
               _global.coop.targetHero = 1;
            }
            else
            {
               var d1 = Math.abs(_root.arena.gladiators.villain._x - _root.arena.gladiators.hero._x);
               var d2 = Math.abs(_root.arena.gladiators.villain._x - _root.arena.gladiators.hero2._x);
               _global.coop.targetHero = d2 < d1 ? 2 : 1;
            }
         }
         attacker = _root.arena.gladiators.villain;
         game_attacker = _root.game.villain;
         if(_global.coop.targetHero == 2 && _root.game.hero2.hitpoints > 0)
         {
            defender = _root.arena.gladiators.hero2;
            game_defender = _root.game.hero2;
         }
         else
         {
            defender = _root.arena.gladiators.hero;
            game_defender = _root.game.hero;
         }
         if(_root.arena.getfightdistance != undefined)
         {
            _root.arena.getfightdistance();
         }
      }
      coopFacePair(attacker,defender);
      if(game_attacker.hitpoints > 0)
      {
         attacker.gotoAndPlay("Standing");
         if(game_attacker.psyche_up == 2)
         {
            attacker.gotoAndStop("psyche_charging");
         }
         if(game_attacker.psyche_up == 3)
         {
            attacker.gotoAndStop("psyche_charging2");
         }
      }
      if(game_defender.hitpoints > 0)
      {
         defender.gotoAndPlay("Standing");
         if(game_defender.psyche_up == 2)
         {
            defender.gotoAndStop("psyche_charging");
         }
         if(game_defender.psyche_up == 3)
         {
            defender.gotoAndStop("psyche_charging2");
         }
      }
      if(attacker._y > 200)
      {
         attacker._y = 200;
      }
      if(defender._y < 200)
      {
         defender._y = 200;
      }
      if(_global.coop.activeTurn == 3 && villaindecisionA == null)
      {
         _root.game.villain.inventory_action = 0;
         villainChooseAction();
         if(_global.coopSend != undefined && _global.coop.role == "host")
         {
            var bInv = _root.game.villain.inventory_action != undefined ? Number(_root.game.villain.inventory_action) : 0;
            _global.coopSend("boss",{action:villaindecisionA,inv:bInv,target:_global.coop.targetHero,seed:_global.coop.seed});
         }
      }
      return undefined;
   }
   attacker.gotoAndPlay("Standing");
   defender.gotoAndPlay("Standing");
   if(game_attacker.psyche_up == 2)
   {
      attacker.gotoAndStop("psyche_charging");
   }
   if(game_attacker.psyche_up == 3)
   {
      attacker.gotoAndStop("psyche_charging2");
   }
   if(game_defender.psyche_up == 2)
   {
      defender.gotoAndStop("psyche_charging");
   }
   if(game_defender.psyche_up == 3)
   {
      defender.gotoAndStop("psyche_charging2");
   }
   if(_root.arena.gladiators.hero._x < _root.arena.gladiators.villain._x)
   {
      _root.arena.gladiators.hero.gladiator_dir = "right";
      if(_root.arena.gladiators.hero._xscale < 0)
      {
         _root.arena.gladiators.hero._xscale = - _root.arena.gladiators.hero._xscale;
         _root.arena.gladiators.villain._xscale = - _root.arena.gladiators.villain._xscale;
      }
      _root.arena.gladiators.villain.gladiator_dir = "left";
   }
   if(_root.arena.gladiators.hero._x > _root.arena.gladiators.villain._x)
   {
      _root.arena.gladiators.hero.gladiator_dir = "left";
      if(_root.arena.gladiators.hero._xscale > 0)
      {
         _root.arena.gladiators.hero._xscale = - _root.arena.gladiators.hero._xscale;
         _root.arena.gladiators.villain._xscale = - _root.arena.gladiators.villain._xscale;
      }
      _root.arena.gladiators.villain.gladiator_dir = "right";
   }
   if(attacker._y > 200)
   {
      attacker._y = 200;
   }
   if(defender._y < 200)
   {
      defender._y = 200;
   }
   if(attacker == _root.arena.gladiators.hero)
   {
      attacker = _root.arena.gladiators.villain;
      defender = _root.arena.gladiators.hero;
      game_attacker = _root.game.villain;
      game_defender = _root.game.hero;
      if(villaindecisionA == null)
      {
         villainChooseAction();
      }
   }
   else
   {
      attacker = _root.arena.gladiators.hero;
      defender = _root.arena.gladiators.villain;
      game_attacker = _root.game.hero;
      game_defender = _root.game.villain;
   }
};
checkattackroll = function()
{
   attack_chances(game_attacker,game_defender);
   diceroll = randomBetween(1,100);
   if(attack_direction >= 1 && attack_direction <= 4)
   {
      damage = game_attacker.min_damage;
      criticalhit = randomBetween(-20,20);
      rollneeded = 100 - game_attacker.quick_percentage;
   }
   else if(attack_direction >= 5 && attack_direction <= 8)
   {
      damage = randomBetween(game_attacker.min_damage,game_attacker.max_damage);
      criticalhit = randomBetween(1,20);
      rollneeded = 100 - game_attacker.normal_percentage;
   }
   else if(attack_direction >= 9 && attack_direction <= 12)
   {
      criticalhit = randomBetween(5,20);
      damage = game_attacker.max_damage;
      rollneeded = 100 - game_attacker.power_percentage;
   }
   else if(attack_direction == 20)
   {
      criticalhit = 21;
      damage = Math.round(game_attacker.charisma * 4) - game_defender.charisma;
      if(damage < 1)
      {
         damage = randomBetween(1,3);
      }
      rollneeded = 100 - game_attacker.taunt_percentage;
   }
   else if(attack_direction == 21)
   {
      criticalhit = randomBetween(-20,20);
      damage = randomBetween(game_attacker.min_damage,game_attacker.max_damage);
      rollneeded = 100 - game_attacker.bombard_percentage;
   }
   else if(attack_direction == 22)
   {
      criticalhit = 0;
      damage = game_attacker.min_damage;
      rollneeded = 100 - game_attacker.snipe_percentage;
   }
   else if(attack_direction == 23)
   {
      damage = Math.ceil(game_attacker.min_damage / 2);
      rollneeded = 100 - game_attacker.bash_percentage;
   }
   else if(attack_direction == 30)
   {
      criticalhit = 20;
      damage = Math.ceil(game_attacker.max_damage * 1.5);
      if(damage <= 1)
      {
         damage = game_attacker.character_level * 10;
      }
      rollneeded = 100 - Math.round(game_attacker.normal_percentage);
   }
   if(diceroll >= rollneeded)
   {
      deflect_critical = randomBetween(1,100);
      deflect_needed = get_percentage(100 - game_defender.helmet * 1.5 + game_defender.greaves,100);
      if(deflect_critical >= deflect_needed && attack_direction != 30)
      {
         criticalhit = 0;
      }
      if(attack_direction == 30)
      {
         defender_hurt("grievous");
      }
      else if(attack_direction == 20)
      {
         defender_hurt("taunt");
      }
      else if(criticalhit == 20 && attack_direction != 20)
      {
         defender_hurt("critical");
      }
      else
      {
         damage_method = "normal";
         defender_hurt("normal");
      }
   }
   else
   {
      defender_blocked();
   }
};
changeCombatants();
nextphase = function()
{
   if(_global.coop.enabled == true)
   {
      if(coopPhaseDone == true)
      {
         return undefined;
      }
      coopPhaseDone = true;
   }
   _root.arena.combatCamera();
   if(game_attacker._x < -2100)
   {
      game_attacker._x = -2100;
   }
   if(game_attacker._x > 2100)
   {
      game_attacker._x = 2100;
   }
   if(game_defender._x < -2100)
   {
      game_defender._x = -2100;
   }
   if(game_defender._x > 2100)
   {
      game_defender._x = 2100;
   }
   demand_move = 1;
   check_spells(game_attacker,attacker);
   check_spells(game_defender,defender);
   game_attacker.staminaleft -= game_attacker.staminacost;
   game_attacker.staminaleft += 1 + Math.round(game_attacker.stamina / 3);
   game_attacker.hitpoints += 1 + Math.ceil(game_attacker.stamina / 2);
   check_stats(game_attacker);
   bonus = 1 + Math.round(game_attacker.stamina / 3);
   add_stats_icon(game_attacker,attacker,bonus,2);
   check_stats(game_attacker);
   if(attacker.spell_regenerate > 0)
   {
      game_attacker.hitpoints += Math.round(game_attacker.hitpointsmax / 4);
      bonus = Math.round(game_attacker.hitpointsmax / 4);
      add_stats_icon(game_attacker,attacker,bonus,1);
      check_stats(game_attacker);
   }
   if(attacker.spell_boundless_energy > 0)
   {
      game_attacker.staminaleft += Math.round(game_attacker.staminamax / 4);
      bonus = Math.round(game_attacker.stamina / 4);
      add_stats_icon(game_attacker,attacker,bonus,2);
      check_stats(game_attacker);
      check_stats(game_attacker);
   }
   _global.crowd_interest += _global.crowd_action;
   if(_global.crowd_interest < 1)
   {
      _global.crowd_interest = 1;
   }
   else if(_global.crowd_interest > 100)
   {
      _global.crowd_interest = 100;
   }
   _global.crowd_action = 0;
   check_stats(game_attacker);
   if(phase_decision != "psyche_up")
   {
      game_attacker.psyche_up = 1;
   }
   _root.battlevalues(game_attacker);
   _root.battlevalues(game_defender);
   if(_global.coop.enabled == true)
   {
      coopSnapTweens();
      coopResetPoses();
      delete ov.onEnterFrame;
      delete attacker.onEnterFrame;
      delete defender.onEnterFrame;
      _global.battle_action = null;
      if(_root.game.villain.hitpoints <= 0)
      {
         if(_global.coopSend != undefined && _global.coop.role == "host")
         {
            _global.coop.lastOutcome = "won";
            _global.coop.syncSeq = Number(_global.coop.syncSeq) + 1;
            _global.coopSend("sync",coopBuildSyncPayload());
            _global.coopSend("end",{outcome:"won"});
         }
         ov.gotoAndPlay("combatwon");
         return undefined;
      }
      if(_root.game.hero.hitpoints <= 0 && _root.game.hero2.hitpoints <= 0)
      {
         if(_global.coopSend != undefined && _global.coop.role == "host")
         {
            _global.coop.lastOutcome = "lost";
            _global.coop.syncSeq = Number(_global.coop.syncSeq) + 1;
            _global.coopSend("sync",coopBuildSyncPayload());
            _global.coopSend("end",{outcome:"lost"});
         }
         ov.gotoAndPlay("combatlost");
         return undefined;
      }
      var nextT = _global.coop.activeTurn + 1;
      if(nextT > 3)
      {
         nextT = 1;
      }
      if(nextT == 1 && _root.game.hero.hitpoints <= 0)
      {
         nextT = 2;
      }
      if(nextT == 2 && _root.game.hero2.hitpoints <= 0)
      {
         nextT = 3;
      }
      _global.coop.activeTurn = nextT;
      if(_global.coopSend != undefined && _global.coop.role == "host")
      {
         _global.coop.syncSeq = Number(_global.coop.syncSeq) + 1;
         _global.coopSend("sync",coopBuildSyncPayload());
      }
      else if(_global.coop.role == "client")
      {
         _global.coop.awaitingSync = true;
      }
      ov.gotoAndPlay("initialise");
      return undefined;
   }
   if(_global.battle_action < 3)
   {
      _global.battle_action = _global.battle_action + 1;
      changeCombatants();
   }
   if(_global.battle_action == 3)
   {
      changeCombatants();
      _global.battle_action = null;
      delete ov.onEnterFrame;
      delete attacker.onEnterFrame;
      delete defender.onEnterFrame;
      this.gotoAndPlay("initialise");
   }
};
this.onEnterFrame = function()
{
   if(_root.arena.fightdistance < 100)
   {
      if(_global.coop.enabled == true)
      {
         if(attacker.gladiator_dir == "left")
         {
            attacker._x++;
            defender._x--;
         }
         else
         {
            attacker._x--;
            defender._x++;
         }
      }
      else
      {
         if(_root.arena.gladiators.hero.gladiator_dir == "left")
         {
            _root.arena.gladiators.hero._x++;
            _root.arena.gladiators.villain._x--;
         }
         else
         {
            _root.arena.gladiators.hero._x--;
            _root.arena.gladiators.villain._x++;
         }
      }
   }
   if(demand_move == null)
   {
      demand_move = 1;
   }
   demand_move++;
   if(demand_move >= 60 && attacker._y >= attacker.grounded && bullet_in_air != true || demand_move >= 200)
   {
      demand_move = 1;
      attacker.grounded = null;
      attacker.struck = null;
      defender.struck = null;
      defender.grounded = null;
      nextphase();
   }
   if(_global.coop.enabled == true)
   {
      if(attacker == _root.arena.gladiators.villain)
      {
         _global.phasecomplete = false;
      }
   }
   else if(attacker != _root.arena.gladiators.hero)
   {
      _global.phasecomplete = false;
   }
   if(knock_defender == null || knock_defender == undefined)
   {
      if(attacker._x < -2100)
      {
         attacker._x = -2100;
         if(attacker._y >= attacker.grounded)
         {
            attacker._y = attacker.grounded;
            attacker.grounded = null;
            attacker.destination = null;
            nextphase();
         }
      }
      if(attacker._x > 2100)
      {
         attacker._x = 2100;
         if(attacker._y >= attacker.grounded)
         {
            attacker._y = attacker.grounded;
            attacker.grounded = null;
            attacker.destination = null;
            nextphase();
         }
      }
      if(defender._x < -2100)
      {
         defender._x = -2100;
      }
      if(defender._x > 2100)
      {
         defender._x = 2100;
      }
   }
   _root.arena.gladiators.overlay_villain.gotoAndStop(2);
   if(_global.battle_action == 1)
   {
      phase_decision = decisionA;
   }
   else if(_global.battle_action == 2)
   {
      phase_decision = villaindecisionA;
   }
   else if(_global.battle_action == 3)
   {
      phase_decision = decisionB;
   }
   else if(_global.battle_action == 4)
   {
      phase_decision = villaindecisionB;
   }
   else
   {
      phase_decision = null;
   }
   if(phase_decision == "walkleft")
   {
      game_attacker.staminacost = Math.round(game_attacker.movement_speed / 2);
      if(attacker.destination == null)
      {
         attacker.gotoAndPlay("StepBack");
         attacker_x_walk = game_attacker.movement_speed * 16;
         walk_bonus = get_percentage(100 + game_attacker.boot * 2,100);
         attacker_x_walk = add_percentage(attacker_x_walk,walk_bonus);
         attacker.destination = attacker._x - attacker_x_walk;
         if(attacker.destination < defender._x + game_defender.physical_size && attacker.gladiator_dir == "left")
         {
            attacker.destination = defender._x + game_defender.physical_size;
         }
      }
      attacker._x -= Math.ceil((attacker._x - attacker.destination) / 8);
      if(attacker._x <= attacker.destination + 20)
      {
         attacker.destination = null;
         nextphase();
      }
   }
   if(phase_decision == "walkright")
   {
      game_attacker.staminacost = Math.round(game_attacker.movement_speed / 2);
      if(attacker.destination == null)
      {
         attacker.gotoAndPlay("StepForward");
         attacker_x_walk = game_attacker.movement_speed * 16;
         walk_bonus = get_percentage(100 + game_attacker.boot * 2,100);
         attacker_x_walk = add_percentage(attacker_x_walk,walk_bonus);
         attacker.destination = attacker._x + attacker_x_walk;
         if(attacker.destination > defender._x - game_defender.physical_size && attacker.gladiator_dir == "right")
         {
            attacker.destination = defender._x - game_defender.physical_size;
         }
      }
      attacker._x += Math.ceil((attacker.destination - attacker._x) / 8);
      if(attacker._x >= attacker.destination - 20)
      {
         attacker.destination = null;
         nextphase();
      }
   }
   if(phase_decision == "runleft")
   {
      game_attacker.staminacost = Math.round(game_attacker.movement_speed / 2);
      if(attacker.destination == null)
      {
         attacker.gotoAndPlay("RunBack");
         attacker.destination = attacker._x - game_attacker.movement_speed * 40;
      }
      attacker._x -= Math.ceil((attacker._x - attacker.destination) / 8);
      if(attacker.gladiator_dir == "left" && attacker._x < defender._x + attacker.physical_size)
      {
         attacker.destination = null;
         nextphase();
      }
      if(attacker._x <= attacker.destination + 10)
      {
         attacker.destination = null;
         nextphase();
      }
   }
   if(phase_decision == "runright")
   {
      game_attacker.staminacost = Math.round(game_attacker.movement_speed / 2);
      if(attacker.destination == null)
      {
         attacker.gotoAndPlay("RunForward");
         attacker.destination = attacker._x + game_attacker.movement_speed * 40;
      }
      attacker._x += Math.ceil((attacker.destination - attacker._x) / 8);
      if(attacker.gladiator_dir == "right" && attacker._x > defender._x - attacker.physical_size)
      {
         attacker.destination = null;
         nextphase();
      }
      if(attacker._x >= attacker.destination - 10)
      {
         attacker.destination = null;
         nextphase();
      }
   }
   if(phase_decision == "chargeright")
   {
      _global.crowd_action = 2;
      game_attacker.staminacost = Math.round(game_attacker.movement_speed * 2);
      if(attacker.destination == null)
      {
         attacker.gotoAndPlay("Charge");
         attacker.destination = attacker._x + game_attacker.movement_speed * 20;
      }
      if(attacker._x <= Math.round(defender._x - game_attacker.weapon_range))
      {
         attacker._x += Math.ceil((attacker.destination - attacker._x) / 8);
      }
      if(attacker._x > Math.round(defender._x - game_attacker.weapon_range))
      {
         if(attacker.struck != true)
         {
            attacker.struck = true;
            attacker.gotoAndPlay("Chargeattack");
            attacker.attack_direction = 9;
            checkattackroll();
         }
         else if(attacker.charging == false)
         {
            attacker.struck = null;
            attacker.charging = null;
            attacker.destination = null;
            nextphase();
         }
      }
      else if(attacker.charging == true)
      {
         attacker.charging = null;
         attacker.struck = null;
         attacker.destination = null;
         nextphase();
      }
   }
   if(phase_decision == "chargeleft")
   {
      _global.crowd_action = 2;
      game_attacker.staminacost = Math.round(game_attacker.movement_speed * 2);
      if(attacker.destination == null)
      {
         attacker.gotoAndPlay("Charge");
         attacker.destination = attacker._x - game_attacker.movement_speed * 20;
      }
      if(attacker._x >= Math.round(defender._x + game_attacker.weapon_range))
      {
         attacker._x -= Math.ceil((attacker._x - attacker.destination) / 8);
      }
      if(attacker._x < Math.round(defender._x + game_attacker.weapon_range))
      {
         if(attacker.struck != true)
         {
            attacker.struck = true;
            attacker.gotoAndPlay("Chargeattack");
            attacker.attack_direction = 9;
            checkattackroll();
         }
         else if(attacker.charging == false)
         {
            attacker.struck = null;
            attacker.charging = null;
            attacker.destination = null;
            nextphase();
         }
      }
      else if(attacker.charging == true)
      {
         attacker.charging = null;
         attacker.struck = null;
         attacker.destination = null;
         nextphase();
      }
   }
   if(phase_decision == "jumpright")
   {
      _global.crowd_action = -2;
      game_attacker.staminacost = Math.round(game_attacker.movement_speed);
      if(attacker.grounded == null)
      {
         attacker.grounded = attacker._y;
         attacker.gotoAndPlay("Jump");
         attacker.leap = - (3 + Math.ceil(game_attacker.movement_speed * 0.6));
         jump_bonus = get_percentage(100 + game_attacker.shinguard * 2,100);
         attacker.leap = add_percentage(attacker.leap,jump_bonus);
         if(attacker.leap > -8)
         {
            attacker.leap = -8;
         }
         if(attacker.leap < -36)
         {
            attacker.leap = -36;
            superjump = randomBetween(1,3);
            if(superjump == 3)
            {
               attacker.gotoAndPlay("Superjump");
            }
         }
      }
      jump_x_mov = Math.round(game_attacker.movement_speed * 0.6);
      jump_bonus = get_percentage(100 + game_attacker.shinguard * 2,100);
      jump_x_mov = add_percentage(jump_x_mov,jump_bonus);
      attacker._x += jump_x_mov;
      attacker._y += attacker.leap;
      attacker.leap += 1;
      if(attacker._y >= attacker.grounded)
      {
         attacker._y = attacker.grounded;
         attacker.grounded = null;
         nextphase();
      }
   }
   if(phase_decision == "jumpleft")
   {
      _global.crowd_action = -2;
      game_attacker.staminacost = Math.round(game_attacker.movement_speed);
      if(attacker.grounded == null)
      {
         attacker.grounded = attacker._y;
         attacker.gotoAndPlay("Jump");
         attacker.leap = 3 + Math.ceil(game_attacker.movement_speed * 0.6);
         jump_bonus = get_percentage(100 + game_attacker.shinguard * 2,100);
         attacker.leap = add_percentage(attacker.leap,jump_bonus);
         attacker.leap = - attacker.leap;
         if(attacker.leap > -8)
         {
            attacker.leap = -8;
         }
         if(attacker.leap < -36)
         {
            attacker.leap = -36;
            superjump = randomBetween(1,3);
            if(superjump == 3)
            {
               attacker.gotoAndPlay("Superjump");
            }
         }
      }
      jump_x_mov = Math.round(game_attacker.movement_speed * 0.6);
      jump_bonus = get_percentage(100 + game_attacker.shinguard * 2,100);
      jump_x_mov = add_percentage(jump_x_mov,jump_bonus);
      attacker._x -= jump_x_mov;
      attacker._y += attacker.leap;
      attacker.leap += 1;
      if(attacker._y >= attacker.grounded)
      {
         attacker._y = attacker.grounded;
         attacker.grounded = null;
         nextphase();
      }
   }
   if(phase_decision == "block")
   {
      game_attacker.staminacost = 7;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("Block");
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "swap_weapons")
   {
      game_attacker.staminacost = 1;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("Block");
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         if(game_attacker.using_bow != true)
         {
            game_attacker.equipped_weapon = 2;
            game_attacker.using_bow = true;
            attacker.weapon.realweapon.attachMovie("weapon" + game_attacker.secondary_weapon,"weapon",0,{_x:0,_y:0});
            attacker.Rlowerarm.attachMovie("shield1","shield",3,{_x:0,_y:50});
            _root.itemglow(attacker.weapon,game_attacker.secondary_weapon_enchantment_type,game_attacker.secondary_weapon_enchantment_potency);
            _root.battlevalues(game_attacker);
         }
         else
         {
            game_attacker.equipped_weapon = 1;
            game_attacker.using_bow = false;
            attacker.weapon.realweapon.attachMovie("weapon" + game_attacker.weapon,"weapon",0,{_x:0,_y:0});
            attacker.Rlowerarm.attachMovie("shield" + game_attacker.shield,"shield",3,{_x:0,_y:50});
            _root.itemglow(attacker.weapon,game_attacker.weapon_enchantment_type,game_attacker.weapon_enchantment_potency);
            _root.battlevalues(game_attacker);
         }
         nextphase();
      }
   }
   if(phase_decision == "wincrowd")
   {
      _global.crowd_action = Math.round((_global.coop.enabled == true ? game_attacker.charisma : _root.game.hero.charisma) / 2);
      game_attacker.staminacost = 3;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         if(attacker.wincrowd_move <= 0 || attacker.wincrowd_move == undefined)
         {
            attacker.wincrowd_move = _global.coop.enabled == true ? randomBetween(1,6) : 1 + random(6);
         }
         attacker.wincrowd_move += 1;
         if(attacker.wincrowd_move > 6)
         {
            attacker.wincrowd_move = 1;
         }
         animstate = String("wincrowd" + attacker.wincrowd_move);
         attacker.gotoAndPlay(animstate);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "rest")
   {
      _global.crowd_action = -2;
      game_attacker.staminacost = - Math.round(game_attacker.stamina * 15);
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("rest");
         game_attacker.hitpoints += 3 + Math.ceil(game_attacker.stamina);
         bonus = game_attacker.stamina;
         game_attacker.staminaleft += bonus;
         add_stats_icon(game_attacker,attacker,bonus,1);
         check_stats(game_attacker);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "frozen")
   {
      _global.crowd_action = 0;
      game_attacker.staminacost = 0;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("frozen");
         if(game_attacker.equipped_weapon == 1)
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"frozen",5,game_defender.weapon_enchantment_damage);
         }
         else
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"frozen",5,game_defender.secondary_weapon_enchantment_damage);
         }
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "life_stolen")
   {
      _global.crowd_action = 0;
      game_attacker.staminacost = 0;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("lifesteal");
         if(game_attacker.equipped_weapon == 1)
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"lifesteal",6,game_defender.weapon_enchantment_damage);
         }
         else
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"lifesteal",6,game_defender.secondary_weapon_enchantment_damage);
         }
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "poisoned")
   {
      _global.crowd_action = 0;
      game_attacker.staminacost = 0;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("poisoned");
         if(game_attacker.equipped_weapon == 1)
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"poisoned",7,game_defender.weapon_enchantment_damage);
         }
         else
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"poisoned",7,game_defender.secondary_weapon_enchantment_damage);
         }
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "burning")
   {
      _global.crowd_action = 0;
      game_attacker.staminacost = 0;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("burning");
         if(game_attacker.equipped_weapon == 1)
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"burning",4,game_defender.weapon_enchantment_damage);
         }
         else
         {
            magic_damage_character(attacker,defender,game_attacker,game_defender,"burning",4,game_defender.secondary_weapon_enchantment_damage);
         }
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "drink_potion")
   {
      _global.crowd_action = -3;
      game_attacker.staminacost = 0;
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attacker.gotoAndPlay("drink_potion");
         attacker.potions.gotoAndPlay(game_attacker.inventory_action - 1);
         if(game_attacker.inventory_action == 2)
         {
            bonus = Math.round(game_attacker.hitpointsmax * 0.25);
            game_attacker.hitpoints += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(1);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 3)
         {
            bonus = Math.round(game_attacker.hitpointsmax * 0.5);
            game_attacker.hitpoints += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(1);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 4)
         {
            bonus = Math.round(game_attacker.hitpointsmax * 0.75);
            game_attacker.hitpoints += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(1);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 5)
         {
            bonus = game_attacker.hitpointsmax;
            game_attacker.hitpoints += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(1);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 6)
         {
            bonus = Math.round(game_attacker.staminamax * 0.5);
            game_attacker.staminaleft += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(2);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 7)
         {
            bonus = Math.round(game_attacker.staminamax);
            game_attacker.staminaleft += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(2);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 8)
         {
            bonus = Math.round(game_attacker.armourclass * 0.5);
            game_attacker.armourclass += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(3);
            bonus_icon.bonus = "+ " + bonus;
         }
         if(game_attacker.inventory_action == 9)
         {
            bonus = Math.round(game_attacker.armourclass_max);
            game_attacker.armourclass += bonus;
            bonus_icon = attacker.attachMovie("bonus_icon","bonus_icon",25001);
            bonus_icon.damage_splat.gotoAndStop(3);
            bonus_icon.bonus = "+ " + bonus;
         }
         check_flipping(bonus_icon,attacker);
         check_stats(game_attacker);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "shove")
   {
      _global.crowd_action = 2;
      game_attacker.staminacost = Math.round(game_attacker.strength * 1.5);
      if(attacker.shove != true)
      {
         attacker.shove = true;
         attacker.gotoAndPlay("shove");
         if(attacker.gladiator_dir == "right")
         {
            force = game_attacker.strength * 12;
            force_bonus = get_percentage(100 + game_attacker.gauntlet * 2,100);
            force = add_percentage(force,force_bonus);
            if(force < 20)
            {
               force = 20;
            }
            if(force > 100)
            {
               defender.gotoAndPlay("knockback");
            }
         }
         else
         {
            force = game_attacker.strength * 12;
            force_bonus = get_percentage(100 + game_attacker.gauntlet * 2,100);
            force = add_percentage(force,force_bonus);
            force = - force;
            if(force > -20)
            {
               force = -20;
            }
            if(force < -100)
            {
               defender.gotoAndPlay("knockback");
            }
         }
         knockback(defender,force);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         attacker.shove = null;
         nextphase();
      }
   }
   if(phase_decision == "power_attack")
   {
      _global.crowd_action = 2;
      game_attacker.staminacost = Math.round(game_attacker.strength * 3);
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attack_direction = randomBetween(9,12);
         if(attack_direction == 9)
         {
            attacker.gotoAndPlay("Attack9");
         }
         if(attack_direction == 10)
         {
            attacker.gotoAndPlay("Attack10");
         }
         if(attack_direction == 11)
         {
            attacker.gotoAndPlay("Attack11");
         }
         if(attack_direction == 12)
         {
            attacker.gotoAndPlay("Attack12");
         }
         checkattackroll();
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "normal_attack")
   {
      game_attacker.staminacost = Math.round(game_attacker.strength * 2);
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attack_direction = randomBetween(5,8);
         if(attack_direction == 5)
         {
            attacker.gotoAndPlay("Attack5");
         }
         if(attack_direction == 6)
         {
            attacker.gotoAndPlay("Attack6");
         }
         if(attack_direction == 7)
         {
            attacker.gotoAndPlay("Attack7");
         }
         if(attack_direction == 8)
         {
            attacker.gotoAndPlay("Attack8");
         }
         checkattackroll();
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "quick_attack")
   {
      _global.crowd_action = -1;
      game_attacker.staminacost = Math.round(game_attacker.strength);
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attack_direction = randomBetween(1,4);
         if(attack_direction == 1)
         {
            attacker.gotoAndPlay("Attack1");
         }
         if(attack_direction == 2)
         {
            attacker.gotoAndPlay("Attack2");
         }
         if(attack_direction == 3)
         {
            attacker.gotoAndPlay("Attack3");
         }
         if(attack_direction == 4)
         {
            attacker.gotoAndPlay("Attack4");
         }
         checkattackroll();
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "bash_attack")
   {
      game_attacker.staminacost = Math.round(game_attacker.strength * 2);
      if(attacker.struck == null)
      {
         attacker.struck = false;
         attack_direction = 23;
         attacker.gotoAndPlay("Attack2");
         checkattackroll();
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "psyche_up")
   {
      game_attacker.staminacost = Math.round(game_attacker.strength);
      if(attacker.struck == null)
      {
         attacker.struck = false;
         if(game_attacker.psyche_up == 1)
         {
            attacker.gotoAndPlay("psyche_up");
         }
         if(game_attacker.psyche_up == 2)
         {
            t;
            attacker.gotoAndPlay("psyche_up2");
         }
         if(game_attacker.psyche_up == 3)
         {
            _global.crowd_action = 3;
            attacker.gotoAndPlay("psyche_up3");
            if(game_attacker.psyche_up == 3)
            {
               if(attacker.gladiator_dir == "right")
               {
                  if(attacker._x > Math.round(defender._x - (game_attacker.weapon_range + 50)))
                  {
                     attack_direction = 30;
                     checkattackroll();
                  }
               }
               if(attacker.gladiator_dir == "left")
               {
                  if(attacker._x < Math.round(defender._x + (game_attacker.weapon_range + 50)))
                  {
                     attack_direction = 30;
                     checkattackroll();
                  }
               }
            }
            game_attacker.psyche_up = 1;
         }
      }
      if(attacker.struck == true)
      {
         game_attacker.psyche_up += 1;
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "taunt")
   {
      _global.crowd_action = -2;
      game_attacker.staminacost = Math.round(game_attacker.charisma * 2);
      taunttimer++;
      if(taunttimer > 60)
      {
         taunttimer = 0;
         attacker.struck = null;
         nextphase();
      }
      if(attacker.struck == null)
      {
         game_attacker.hitpoints += 3 + Math.ceil(game_attacker.stamina);
         bonus = game_attacker.stamina;
         game_attacker.staminaleft += bonus;
         add_stats_icon(game_attacker,attacker,bonus,1);
         check_stats(game_attacker);
         taunttimer = 1;
         attacker.struck = false;
         attacker.gotoAndPlay("taunt");
         defender.gotoAndPlay("taunted");
         if(_global.coop.enabled == true)
         {
            // Remote turns skip the attack menu that normally prepares this chance.
            attack_chances(game_attacker,game_defender);
            attack_direction = 20;
         }
         diceroll = randomBetween(1,100);
         if(diceroll < game_attacker.taunt_percentage)
         {
            taunt_effect = randomBetween(1,2);
            if(taunt_effect == 1)
            {
               attack_direction = 20;
               checkattackroll();
            }
            else if(game_defender.equipped_weapon == 1)
            {
               if(attacker.gladiator_dir == "right")
               {
                  force = game_attacker.charisma * 25;
                  if(force < 20)
                  {
                     force = 20;
                  }
                  if(force > 100)
                  {
                     defender.gotoAndPlay("knockback");
                  }
               }
               else
               {
                  force = - game_attacker.charisma * 25;
                  if(force > -20)
                  {
                     force = -20;
                  }
                  if(force < -100)
                  {
                     defender.gotoAndPlay("knockback");
                  }
               }
               knockback(defender,force);
            }
            else
            {
               game_defender.psyche_up = 1;
               game_defender.taunted1 = true;
               if(game_defender == _root.game.hero.villain)
               {
                  villainChooseAction;
               }
            }
         }
         else
         {
            defender_blocked();
         }
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "bombardright" || phase_decision == "bombardleft" || phase_decision == "sniperight" || phase_decision == "snipeleft")
   {
      _global.crowd_action = -1;
      game_attacker.staminacost = Math.round(game_attacker.strength * 3);
      if(attacker.struck == null)
      {
         game_attacker.ammo_left -= 1;
         attacker.struck = false;
         bullet_in_air = true;
         if(phase_decision == "bombardright" || phase_decision == "bombardleft")
         {
            attacker.gotoAndPlay("bombard");
            attack_direction = 21;
         }
         else
         {
            attacker.gotoAndPlay("snipe");
            attack_direction = 22;
         }
      }
      if(bullet._y > 160 || bullet._x > defender._x && attacker.gladiator_dir == "right" || bullet._x < defender._x && attacker.gladiator_dir == "left")
      {
         checkattackroll();
         bullet_in_air = false;
         bullet.removeMovieClip();
      }
      if(attacker.fired == true)
      {
         attacker.fired = false;
         bulletdepth = 45000;
         bullet = _root.arena.gladiators.attachMovie("bullet","bullet" + bulletdepth,bulletdepth);
         bullet.gotoAndStop(game_attacker.secondary_weapon - 60);
         if(attacker.gladiator_dir == "right")
         {
            bullet._x = attacker._x + 30;
         }
         else
         {
            bullet._x = attacker._x - 30;
         }
         bullet._y = attacker._y - (attacker._yscale * 2 + 30);
         if(phase_decision == "sniperight" || phase_decision == "snipeleft")
         {
            bullet._y = attacker._y - (attacker._yscale * 1.5 + 5);
         }
         bullet.bulletlife = 1;
         bullet.bulletcounter = 1;
         bullet.gravity = 2;
         if(attacker.gladiator_dir == "right")
         {
            bullet.distance_to_enemy = Math.abs(attacker._x - defender._x);
         }
         else
         {
            bullet.distance_to_enemy = Math.abs(defender._x - attacker._x);
         }
         if(phase_decision == "bombardright" || phase_decision == "bombardleft")
         {
            if(_global.maxscale == 80)
            {
               bullet.Xvelocity = randomBetween(8,18);
            }
            if(_global.maxscale < 80)
            {
               bullet._xscale = bullet._yscale = 100;
               bullet.Xvelocity = randomBetween(16,24);
            }
            if(_global.maxscale <= 60)
            {
               bullet._xscale = bullet._yscale = 130;
               bullet.Xvelocity = randomBetween(20,30);
            }
            if(_global.maxscale <= 40)
            {
               bullet._xscale = bullet._yscale = 160;
               bullet.Xvelocity = randomBetween(30,36);
            }
         }
         else
         {
            bullet.Xvelocity = randomBetween(60,60);
         }
         bullet.Yvelocity = Math.ceil(bullet.distance_to_enemy / bullet.Xvelocity);
         bullet.onEnterFrame = function()
         {
            bullet.bulletcounter++;
            if(bullet.bulletcounter >= 3)
            {
               bullet.bulletcounter = 1;
               bullettrail_depth = _root.arena.gladiators.getNextHighestDepth();
               bullet_trail = _root.arena.gladiators.attachMovie("bullet_trail","bullet_trail" + bullettrail_depth,bullettrail_depth,{_x:this._x,_y:this._y,_rotation:this._rotation});
               bullet_trail.bullet.gotoAndStop(game_attacker.secondary_weapon - 60);
            }
            bullet.Yvelocity -= bullet.gravity;
            if(phase_decision == "bombardright" || phase_decision == "bombardleft")
            {
               bullet._y -= bullet.Yvelocity;
            }
            if(phase_decision == "bombardright" || phase_decision == "sniperight")
            {
               bullet._x += bullet.Xvelocity;
               if(phase_decsion == "sniperight")
               {
                  bullet._x += bullet.Xvelocity;
               }
            }
            else
            {
               bullet._x -= bullet.Xvelocity;
               if(phase_decsion == "snipeleft")
               {
                  bullet._x -= bullet.Xvelocity;
               }
            }
            bullet.bulletlife += bullet.Xvelocity;
            if(phase_decision == "bombardright" || phase_decision == "bombardleft")
            {
               bullet.bulletrotus = Math.round(bullet.bulletlife / (bullet.Xvelocity / (bullet.gravity * 2)));
            }
            else if(phase_decision == "sniperight")
            {
               bullet._rotation = 90;
            }
            else
            {
               bullet._rotation = -90;
            }
            if(bullet.bulletrotus > 170)
            {
               bullet.bulletrotus = 170;
            }
            bullet._rotation = bullet.bulletrotus;
            if(attacker.gladiator_dir == "left")
            {
               bullet._rotation = - bullet.bulletrotus;
            }
         };
      }
   }
   if(phase_decision == "cast_teleport")
   {
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,48);
         _root.arena.gladiators.attachMovie("circlets","circlets",_root.arena.gladiators.getNextHighestDepth(),{_x:attacker._x,_y:200});
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
      }
      combatscale();
      if(attacker.struck == true)
      {
         attacker._x = randomBetween(-2000,2000);
         attacker.gotoAndPlay("Cast2");
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_adulation")
   {
      _global.crowd_action = 50;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,47);
         attacker.struck = false;
         attacker.gotoAndPlay("wincrowd1");
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_weaken_armour")
   {
      _global.crowd_action = 4;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,44);
         attacker.struck = false;
         attacker.gotoAndPlay("Cast1");
         attack_direction = _global.coop.enabled == true ? randomBetween(1,9) : 1 + random(9);
         remove_armour(game_defender,defender,attack_direction);
         attack_direction = _global.coop.enabled == true ? randomBetween(1,9) : 1 + random(9);
         remove_armour(game_defender,defender,attack_direction);
         attack_direction = _global.coop.enabled == true ? randomBetween(1,9) : 1 + random(9);
         remove_armour(game_defender,defender,attack_direction);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_whirlwind")
   {
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,37);
         attacker.gotoAndPlay("psyche_up3");
         attacker.struck = false;
         if(attacker.gladiator_dir == "right")
         {
            if(attacker._x > Math.round(defender._x - (game_attacker.weapon_range + 50)))
            {
               attack_direction = 30;
               checkattackroll();
            }
         }
         if(attacker.gladiator_dir == "left")
         {
            if(attacker._x < Math.round(defender._x + (game_attacker.weapon_range + 50)))
            {
               attack_direction = 30;
               checkattackroll();
            }
         }
         game_attacker.psyche_up = 1;
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_gale")
   {
      _global.crowd_action = 2;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.shove != true)
      {
         cast_spell_icon(attacker,38);
         attacker.shove = true;
         attacker.gotoAndPlay("Cast1");
         if(attacker.gladiator_dir == "right")
         {
            force = 1000;
         }
         else
         {
            force = -1000;
         }
         defender.gotoAndPlay("knockback");
         knockback(defender,force);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         attacker.shove = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_command")
   {
      _global.crowd_action = 2;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.shove != true)
      {
         cast_spell_icon(attacker,39);
         defender.gotoAndPlay("knockback_mov");
         attacker.shove = true;
         attacker.gotoAndPlay("Cast2");
      }
      if(attacker.gladiator_dir == "right")
      {
         defender._x -= 40;
         if(defender._x <= attacker._x + game_defender.physical_size)
         {
            attacker.struck = null;
            attacker.shove = false;
            nextphase();
         }
      }
      else if(attacker.gladiator_dir == "left")
      {
         defender._x += 40;
         if(defender._x >= attacker._x - game_defender.physical_size)
         {
            attacker.struck = null;
            attacker.shove = false;
            nextphase();
         }
      }
   }
   if(phase_decision == "cast_ghost_strike")
   {
      _global.crowd_action = 5;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,36);
         attacker.blendMode = "add";
         attacker_old_x = attacker._x;
         if(attacker.gladiator_dir == "left")
         {
            attacker._x = defender._x + game_attacker.physical_size;
         }
         else
         {
            attacker._x = defender._x - game_attacker.physical_size;
         }
         attacker.struck = false;
         attack_direction = randomBetween(9,12);
         if(attack_direction == 9)
         {
            attacker.gotoAndPlay("Attack9");
         }
         if(attack_direction == 10)
         {
            attacker.gotoAndPlay("Attack10");
         }
         if(attack_direction == 11)
         {
            attacker.gotoAndPlay("Attack11");
         }
         if(attack_direction == 12)
         {
            attacker.gotoAndPlay("Attack12");
         }
         checkattackroll();
      }
      if(attacker.struck == true)
      {
         attacker._x = attacker_old_x;
         attacker.blendMode = "normal";
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_colossus")
   {
      attacker.spell_colossus = 16;
      _global.crowd_action = 15;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,42);
         attacker.struck = false;
         attacker.gotoAndPlay("Colossus");
         attacker.oldscale = attacker._yscale;
         attacker.newscale = 450;
         game_attacker.strength = game_attacker.backup_strength * 3;
         game_attacker.attack = game_attacker.backup_attack * 2;
      }
      attacker._yscale = Math.ceil((attacker.newscale - attacker._yscale) / 2);
      attacker._xscale = attacker._yscale;
      if(attacker.gladiator_dir == "left")
      {
         attacker._x -= 2;
      }
      else
      {
         attacker._x += 2;
      }
      if(attacker._yscale >= attacker.newscale)
      {
         attacker._yscale = attacker._xscale = attacker.newscale;
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_little_fat_kid")
   {
      defender.spell_little_fat_kid = 16;
      _global.crowd_action = 10;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(defender.struck == null)
      {
         attacker.gotoAndPlay("Cast2");
         cast_spell_icon(attacker,33);
         defender.struck = false;
         defender.gotoAndPlay("little_fat_kid");
         defender.oldscale = Number(defender._yscale);
         defender.newscale = 50;
         game_defender.strength = Math.round(game_defender.backup_strength / 2);
         game_defender.attack = Math.round(game_defender.backup_attack / 2);
      }
      defender._yscale = Math.ceil((defender.newscale - defender._yscale) / 2);
      defender._xscale = defender._yscale;
      if(defender._yscale <= defender.newscale)
      {
         defender._yscale = defender._xscale = defender.newscale;
         defender.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_lightning_bolt" || phase_decision == "cast_frightning_bolt")
   {
      _global.crowd_action = 5;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         if(phase_decision == "cast_lightning_bolt")
         {
            cast_spell_icon(attacker,34);
            lightning_damage = randomBetween(100,200);
            lightning_frame = 1;
         }
         if(phase_decision == "cast_frightning_bolt")
         {
            cast_spell_icon(attacker,35);
            lightning_damage = randomBetween(200,400);
            lightning_frame = 2;
         }
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
         bolt = _root.arena.gladiators.attachMovie("lightning_bolt_combat","lightning_bolt_combat",_root.arena.gladiators.getNextHighestDepth(),{_x:defender._x,_y:50});
         magic_damage_character(defender,attacker,game_defender,game_attacker,"lightning",8,lightning_damage);
         bolt.gotoAndStop(lightning_frame);
      }
      if(defender.struck == true)
      {
         bolt.removeMovieClip();
         attacker.struck = null;
         defender.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_death_from_above")
   {
      _global.crowd_action = 20;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,49);
         boulder_stones = randomBetween(10,20);
         lightning_frame = 1;
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
         i = 1;
         while(i <= boulder_stones)
         {
            boulder = _root.arena.gladiators.attachMovie("boulder_combat","boulder_combat" + i,_root.arena.gladiators.getNextHighestDepth(),{_x:defender._x,_y:-600});
            boulder._x += randomBetween(-300,300);
            boulder._y = randomBetween(-600,-800);
            boulder.yspeed = randomBetween(50,150);
            boulder._xscale = boulder._yscale = randomBetween(50,100);
            boulder.cacheAsBitmap = true;
            boulder.onEnterFrame = function()
            {
               if(this._y <= 150)
               {
                  this._y += this.yspeed;
               }
               if(this._y > 150 && this.bounced != true)
               {
                  this.bounced = true;
                  this.cacheAsBitmap = false;
                  this.gotoAndStop(4);
                  magic_damage_character(defender,attacker,game_defender,game_attacker,"burning",4,40);
               }
            };
            i++;
         }
      }
      if(defender.struck == true)
      {
         bolt.removeMovieClip();
         attacker.struck = null;
         defender.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_swiftsandals")
   {
      attacker.spell_swiftsandals = 20;
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,40);
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
         game_attacker.speed = 10 + game_attacker.backup_speed * 2;
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_bloodlust")
   {
      attacker.spell_bloodlust = 20;
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,41);
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
         game_attacker.strength = 10 + Math.round(game_attacker.backup_strength * 1.5);
         game_attacker.defence = Math.round(game_attacker.backup_defence * 0.5);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_regenerate")
   {
      attacker.spell_regenerate = 20;
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,46);
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_boundless_energy")
   {
      attacker.spell_boundless_energy = 20;
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,45);
         attacker.struck = false;
         attacker.gotoAndPlay("Cast2");
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_rejuvinate")
   {
      _global.crowd_action = 3;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         cast_spell_icon(attacker,43);
         attacker.struck = false;
         attacker.gotoAndPlay("Rejuvinate");
         game_attacker.hitpoints = game_attacker.hitpointsmax;
         game_attacker.staminaleft = game_attacker.staminamax;
         game_attacker.armourclass = game_attacker.armourclass_max;
         game_attacker.shoulderguard = game_attacker.backup_shoulderguard;
         game_attacker.gauntlet = game_attacker.backup_gauntlet;
         game_attacker.breastplate = game_attacker.backup_breastplate;
         game_attacker.helmet = game_attacker.backup_helmet;
         game_attacker.greaves = game_attacker.backup_greaves;
         game_attacker.shinguard = game_attacker.backup_shinguard;
         game_attacker.boot = game_attacker.backup_boot;
         game_attacker.weapon = game_attacker.backup_weapon;
         game_attacker.shield = game_attacker.backup_shield;
         _root.updatecharacter(game_attacker,attacker);
      }
      if(attacker.struck == true)
      {
         attacker.struck = null;
         nextphase();
      }
   }
   if(phase_decision == "cast_fireball" || phase_decision == "cast_hell_fireball" || phase_decision == "cast_dire_fireball")
   {
      _global.crowd_action = 5;
      game_attacker.staminacost = Math.round(game_attacker.magicka);
      if(attacker.struck == null)
      {
         bullet_in_air = true;
         if(phase_decision == "cast_fireball")
         {
            cast_spell_icon(attacker,30);
            fireball_damage = randomBetween(80,160);
            fireball_frame = 1;
         }
         if(phase_decision == "cast_hell_fireball")
         {
            cast_spell_icon(attacker,31);
            fireball_damage = randomBetween(150,450);
            fireball_frame = 2;
         }
         if(phase_decision == "cast_dire_fireball")
         {
            cast_spell_icon(attacker,32);
            fireball_damage = randomBetween(300,600);
            fireball_frame = 3;
         }
         attacker.struck = false;
         attacker.fired = true;
         attacker.gotoAndPlay("Cast1");
      }
      if(bullet._x > defender._x && attacker.gladiator_dir == "right" || bullet._x < defender._x && attacker.gladiator_dir == "left")
      {
         if(bullet._currentframe != 4)
         {
            magic_damage_character(defender,attacker,game_defender,game_attacker,"burning",4,fireball_damage);
            bullet.gotoAndStop(4);
            bullet.flying = false;
            bullet_in_air = false;
         }
      }
      if(attacker.fired == true)
      {
         attacker.fired = false;
         bulletdepth = 45000;
         bullet = _root.arena.gladiators.attachMovie("fireball_combat","fireball_combat" + bulletdepth,bulletdepth);
         bullet.gotondStop(fireball_frame);
         if(attacker.gladiator_dir == "right")
         {
            bullet._x = attacker._x + 30;
         }
         else
         {
            bullet._x = attacker._x - 30;
            bullet._xscale = - bullet._xscale;
         }
         bullet._y = attacker._y - (attacker._yscale * 1.5 + 5);
         bullet.bulletlife = 1;
         bullet.bulletcounter = 1;
         bullet.gravity = 2;
         if(attacker.gladiator_dir == "right")
         {
            bullet.distance_to_enemy = Math.abs(attacker._x - defender._x);
         }
         else
         {
            bullet.distance_to_enemy = Math.abs(defender._x - attacker._x);
         }
         if(phase_decision == "cast_fireball")
         {
            bullet.Xvelocity = 50;
         }
         if(phase_decision == "cast_hell_fireball")
         {
            bullet.Xvelocity = 70;
         }
         if(phase_decision == "cast_dire_fireball")
         {
            bullet.Xvelocity = 90;
         }
         bullet.onEnterFrame = function()
         {
            if(bullet.flying != false)
            {
               if(attacker.gladiator_dir == "right")
               {
                  bullet._x += bullet.Xvelocity;
               }
               else
               {
                  bullet._x -= bullet.Xvelocity;
               }
            }
         };
      }
   }
};
