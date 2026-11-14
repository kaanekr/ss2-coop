delete this.onEnterFrame;
if(_global.coop.enabled == true)
{
   _global.coop.lastOutcome = "won";
   _global.coop.inArena = false;
   _root.game.hero.hitpoints = _root.game.hero.hitpointsmax;
   _root.game.hero.staminaleft = _root.game.hero.staminamax;
   _root.game.hero2.hitpoints = _root.game.hero2.hitpointsmax;
   _root.game.hero2.staminaleft = _root.game.hero2.staminamax;
}
_root.arena.gotoAndPlay("combat_won");
_root.game.hero.hitpoints = _root.game.hero.hitpointsmax;
_root.game.hero.staminaleft = _root.game.hero.staminamax;
if(_global.deathsequence == "slain")
{
   deathanim = randomBetween(1,7);
   if(deathanim == 1)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death1");
   }
   if(deathanim == 2)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death2");
   }
   if(deathanim == 3)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death3");
   }
   if(deathanim == 4)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death4");
   }
   if(deathanim == 5)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death5");
   }
   if(deathanim == 6)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death6");
   }
   if(deathanim == 7)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death7");
   }
}
else if(_global.deathsequence == "taunt")
{
   _root.arena.gladiators.villain.gotoAndPlay("DeathTaunt");
}
else if(_global.deathsequence == "pit")
{
   _root.arena.gladiators.villain.gotoAndPlay("DeathSpike");
}
else if(_global.deathsequence == "arrow")
{
   deathanim = randomBetween(1,2);
   if(deathanim == 1)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death21");
   }
   if(deathanim == 2)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Death22");
   }
}
if(_global.deathsequence == "grievous")
{
   _root.arena.gladiators.villain.gotoAndPlay("Death23");
}
if(_global.deathsequence == "poisoned")
{
   _root.arena.gladiators.villain.gotoAndPlay("death_poisoned");
}
if(_global.deathsequence == "yield")
{
   deathanim = randomBetween(1,2);
   if(deathanim == 1)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Yield1");
   }
   if(deathanim == 2)
   {
      _root.arena.gladiators.villain.gotoAndPlay("Yield2");
   }
}
