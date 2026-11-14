delete this.onEnterFrame;
if(_global.coop.enabled == true)
{
   _global.coop.lastOutcome = "lost";
   _global.coop.inArena = false;
}
_root.arena.gotoAndPlay("combat_lost");
var loseTarget = _global.coop.enabled == true && _global.coop.lostClip != undefined ? _global.coop.lostClip : _root.arena.gladiators.hero;
if(_global.deathsequence == "slain")
{
   deathanim = _global.coop.enabled == true && _global.coopRandBetween != undefined ? _global.coopRandBetween(1,7) : 1 + random(7);
   if(deathanim == 1)
   {
      loseTarget.gotoAndPlay("Death1");
   }
   if(deathanim == 2)
   {
      loseTarget.gotoAndPlay("Death2");
   }
   if(deathanim == 3)
   {
      loseTarget.gotoAndPlay("Death3");
   }
   if(deathanim == 4)
   {
      loseTarget.gotoAndPlay("Death4");
   }
   if(deathanim == 5)
   {
      loseTarget.gotoAndPlay("Death5");
   }
   if(deathanim == 6)
   {
      loseTarget.gotoAndPlay("Death6");
   }
   if(deathanim == 7)
   {
      loseTarget.gotoAndPlay("Death7");
   }
}
else if(_global.deathsequence == "taunt")
{
   loseTarget.gotoAndPlay("DeathTaunt");
}
else if(_global.deathsequence == "pit")
{
   loseTarget.gotoAndPlay("DeathSpike");
}
else if(_global.deathsequence == "arrow")
{
   deathanim = _global.coop.enabled == true && _global.coopRandBetween != undefined ? _global.coopRandBetween(1,3) : 1 + random(3);
   if(deathanim == 1)
   {
      loseTarget.gotoAndPlay("Death21");
   }
   if(deathanim == 2)
   {
      loseTarget.gotoAndPlay("Death22");
   }
   if(deathanim == 3)
   {
      loseTarget.gotoAndPlay("Death23");
   }
}
if(_global.deathsequence == "poisoned")
{
   loseTarget.gotoAndPlay("death_poisoned");
}
if(_global.deathsequence == "yield")
{
   deathanim = _global.coop.enabled == true && _global.coopRandBetween != undefined ? _global.coopRandBetween(1,2) : randomBetween(1,2);
   if(deathanim == 1)
   {
      loseTarget.gotoAndPlay("Yield1");
   }
   if(deathanim == 2)
   {
      loseTarget.gotoAndPlay("Yield2");
   }
}
