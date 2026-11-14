on(release){
   _root.clicksound2.start();
   if(_global.coop.inArena == true)
   {
      if(_global.coop.role == "host")
      {
         _global.coopCancelIntro();
      }
      else
      {
         _global.coopSend("cancel",{});
      }
      return;
   }
   _root.gotoAndPlay("townsquare");
}
