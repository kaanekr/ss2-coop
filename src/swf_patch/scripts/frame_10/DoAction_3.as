function refresh_character()
{
   _root.characterDNA = new Array();
   _root.characterDNA = _global.heroDNA;
}
function save_character(char_no)
{
   if(_global.coop != undefined && _global.coop.role == "client" && (_global.coop.inArena == true || _global.coop.needRestoreLocalHero == true))
   {
      return undefined;
   }
   char_no = Number(char_no);
   if(isNaN(char_no) || char_no < 1 || char_no > 10)
   {
      char_no = 1;
   }
   _root.skincharacter(_root.game.hero,this.hero);
   _root.battlevalues(_root.game.hero);
   if(_global.coopCleanDNA != undefined && _global.heroDNA != undefined)
   {
      _global.heroDNA = _global.coopCleanDNA(_global.heroDNA);
   }
   characterDNA = new Array();
   characterDNA = _global.heroDNA.split(",");
   so_local["character" + char_no] = characterDNA;
   var _loc4_ = SharedObject.getLocal("ss2_data");
   _loc4_.data.so_local = so_local;
   _loc4_.flush();
}
function refresh_gladiators()
{
   so_local = new Object();
   var _loc3_ = SharedObject.getLocal("ss2_data");
   so_local = _loc3_.data.so_local;
   so_local.max_gladiators = Number(so_local.max_gladiators);
   if(so_local.max_gladiators == undefined || so_local.max_gladiators == 0 || isNaN(so_local.max_gladiators))
   {
      _global.heroDNA = "Empty,0";
      characterDNA = new Array();
      characterDNA = _global.heroDNA.split(",");
      so_local = new Object();
      so_local.max_gladiators = 0;
      so_local.character1 = characterDNA;
      so_local.character2 = characterDNA;
      so_local.character3 = characterDNA;
      so_local.character4 = characterDNA;
      so_local.character5 = characterDNA;
      so_local.character6 = characterDNA;
      so_local.character7 = characterDNA;
      so_local.character8 = characterDNA;
      so_local.character9 = characterDNA;
      so_local.character10 = characterDNA;
      so_local.character11 = "Empty,0";
   }
   character_list = new String();
   i = 1;
   while(i <= 10)
   {
      var arr = so_local["character" + i];
      if(typeof(arr) == "object" && arr != null && arr[0] != undefined && String(arr[0]).substr(0,5) != "Empty")
      {
         var j = 1;
         while(j < arr.length)
         {
            if(arr[j] == undefined || arr[j] == null || String(arr[j]) == "undefined" || String(arr[j]) == "null" || String(arr[j]) == "NaN")
            {
               arr[j] = (j == 28) ? "Yet to fight" : "0";
            }
            j++;
         }
         var lvlVal = Number(arr[24]);
         if(isNaN(lvlVal) || lvlVal < 1 || lvlVal > 60)
         {
            arr[24] = "1";
         }
         var statIdx = 16;
         while(statIdx <= 23)
         {
            var stVal = Number(arr[statIdx]);
            if(isNaN(stVal) || stVal < 1)
            {
               arr[statIdx] = "5";
            }
            statIdx++;
         }
         if(isNaN(Number(arr[26])) || Number(arr[26]) <= 0)
         {
            arr[26] = "100";
         }
         if(isNaN(Number(arr[29])) || Number(arr[29]) < 0)
         {
            arr[29] = "0";
         }
         if(isNaN(Number(arr[30])) || Number(arr[30]) < 1 || Number(arr[30]) > 19)
         {
            arr[30] = "1";
         }
         character_list += arr[0];
         character_list += " , Level " + arr[24];
      }
      character_list += "\n";
      i++;
   }
   var _loc2_ = SharedObject.getLocal("ss2_data");
   _loc2_.data.so_local = so_local;
   _loc2_.flush();
}
System.security.allowDomain("*");
String.prototype.searchReplace = function(find, replace)
{
   return this.split(find).join(replace);
};
