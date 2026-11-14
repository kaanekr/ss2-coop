function initcharacter(whichcharacter, whichavatar, DNA)
{
   if(DNA == undefined || DNA == null || DNA == "")
   {
      if(whichcharacter.charDNA != undefined && whichcharacter.charDNA != "")
      {
         DNA = whichcharacter.charDNA;
      }
      else
      {
         return undefined;
      }
   }
   if(_global.coopCleanDNA != undefined)
   {
      DNA = _global.coopCleanDNA(DNA);
   }
   whichcharacter.charDNA = DNA;
   whichcharacter.characterDNA = new Array();
   whichcharacter.characterDNA = DNA.split(",");
   whichcharacter.character_name = String(whichcharacter.characterDNA[0]);
   whichcharacter.hero_name = whichcharacter.character_name;
   whichcharacter.skincolor = Number(whichcharacter.characterDNA[1]);
   whichcharacter.haircolor = Number(whichcharacter.characterDNA[2]);
   whichcharacter.features = Number(whichcharacter.characterDNA[3]);
   whichcharacter.hairstyle = Number(whichcharacter.characterDNA[4]);
   whichcharacter.facehairstyle = Number(whichcharacter.characterDNA[5]);
   whichcharacter.shoulderguard = Number(whichcharacter.characterDNA[6]);
   whichcharacter.gauntlet = Number(whichcharacter.characterDNA[7]);
   whichcharacter.breastplate = Number(whichcharacter.characterDNA[8]);
   whichcharacter.helmet = Number(whichcharacter.characterDNA[9]);
   whichcharacter.greaves = Number(whichcharacter.characterDNA[10]);
   whichcharacter.shinguard = Number(whichcharacter.characterDNA[11]);
   whichcharacter.boot = Number(whichcharacter.characterDNA[12]);
   whichcharacter.weapon = Number(whichcharacter.characterDNA[13]);
   whichcharacter.shield = Number(whichcharacter.characterDNA[14]);
   whichcharacter.battlesfought = Number(whichcharacter.characterDNA[15]);
   whichcharacter.strength = Number(whichcharacter.characterDNA[16]);
   whichcharacter.speed = Number(whichcharacter.characterDNA[17]);
   whichcharacter.attack = Number(whichcharacter.characterDNA[18]);
   whichcharacter.defence = Number(whichcharacter.characterDNA[19]);
   whichcharacter.vitality = Number(whichcharacter.characterDNA[20]);
   whichcharacter.charisma = Number(whichcharacter.characterDNA[21]);
   whichcharacter.stamina = Number(whichcharacter.characterDNA[22]);
   whichcharacter.magicka = Number(whichcharacter.characterDNA[23]);
   whichcharacter.herolevel = Number(whichcharacter.characterDNA[24]);
   whichcharacter.experience = Number(whichcharacter.characterDNA[25]);
   whichcharacter.experienceneeded = Number(whichcharacter.characterDNA[26]);
   whichcharacter.villain_xp = Number(whichcharacter.characterDNA[27]);
   whichcharacter.mostpowerfulfoe = String(whichcharacter.characterDNA[28]);
   whichcharacter.goldpieces = Number(whichcharacter.characterDNA[29]);
   whichcharacter.current_tournament = Number(whichcharacter.characterDNA[30]);
   whichcharacter.gladiatorscore = Number(whichcharacter.characterDNA[31]);
   whichcharacter.weapon_enchantment_potency = Number(whichcharacter.characterDNA[32]);
   whichcharacter.weapon_enchantment_type = Number(whichcharacter.characterDNA[33]);
   whichcharacter.inventory1 = Number(whichcharacter.characterDNA[34]);
   whichcharacter.inventory2 = Number(whichcharacter.characterDNA[35]);
   whichcharacter.inventory3 = Number(whichcharacter.characterDNA[36]);
   whichcharacter.inventory4 = Number(whichcharacter.characterDNA[37]);
   whichcharacter.inventory5 = Number(whichcharacter.characterDNA[38]);
   whichcharacter.inventory6 = Number(whichcharacter.characterDNA[39]);
   whichcharacter.inventory_maxslots = Number(whichcharacter.characterDNA[40]);
   whichcharacter.battleswon = Number(whichcharacter.characterDNA[41]);
   whichcharacter.days_in_arena = Number(whichcharacter.characterDNA[42]);
   whichcharacter.battlesfought = Number(whichcharacter.characterDNA[43]);
   whichcharacter.battleslost = Number(whichcharacter.characterDNA[44]);
   whichcharacter.secondary_weapon = Number(whichcharacter.characterDNA[45]);
   whichcharacter.secondary_weapon_enchantment_potency = Number(whichcharacter.characterDNA[46]);
   whichcharacter.secondary_weapon_enchantment_type = Number(whichcharacter.characterDNA[47]);
   whichcharacter.maximum_ammo = Number(whichcharacter.characterDNA[48]);
   whichcharacter.equipped_weapon = Number(whichcharacter.characterDNA[49]);
   if(whichcharacter.character_name == undefined || whichcharacter.character_name == null || whichcharacter.character_name == "" || whichcharacter.character_name == "undefined" || whichcharacter.character_name == "null")
   {
      whichcharacter.character_name = "Gladiator";
      whichcharacter.hero_name = "Gladiator";
   }
   if(isNaN(whichcharacter.skincolor) || whichcharacter.skincolor < 1)
   {
      whichcharacter.skincolor = 1;
   }
   if(isNaN(whichcharacter.haircolor) || whichcharacter.haircolor < 1)
   {
      whichcharacter.haircolor = 1;
   }
   if(isNaN(whichcharacter.features) || whichcharacter.features < 1)
   {
      whichcharacter.features = 1;
   }
   if(isNaN(whichcharacter.hairstyle) || whichcharacter.hairstyle < 1)
   {
      whichcharacter.hairstyle = 1;
   }
   if(isNaN(whichcharacter.facehairstyle) || whichcharacter.facehairstyle < 0)
   {
      whichcharacter.facehairstyle = 0;
   }
   if(isNaN(whichcharacter.shoulderguard) || whichcharacter.shoulderguard < 0)
   {
      whichcharacter.shoulderguard = 0;
   }
   if(isNaN(whichcharacter.gauntlet) || whichcharacter.gauntlet < 0)
   {
      whichcharacter.gauntlet = 0;
   }
   if(isNaN(whichcharacter.breastplate) || whichcharacter.breastplate < 0)
   {
      whichcharacter.breastplate = 0;
   }
   if(isNaN(whichcharacter.helmet) || whichcharacter.helmet < 0)
   {
      whichcharacter.helmet = 0;
   }
   if(isNaN(whichcharacter.greaves) || whichcharacter.greaves < 0)
   {
      whichcharacter.greaves = 0;
   }
   if(isNaN(whichcharacter.shinguard) || whichcharacter.shinguard < 0)
   {
      whichcharacter.shinguard = 0;
   }
   if(isNaN(whichcharacter.boot) || whichcharacter.boot < 0)
   {
      whichcharacter.boot = 0;
   }
   if(isNaN(whichcharacter.weapon) || whichcharacter.weapon < 0)
   {
      whichcharacter.weapon = 1;
   }
   if(isNaN(whichcharacter.shield) || whichcharacter.shield < 0)
   {
      whichcharacter.shield = 0;
   }
   if(isNaN(whichcharacter.strength) || whichcharacter.strength < 1)
   {
      whichcharacter.strength = 5;
   }
   if(isNaN(whichcharacter.speed) || whichcharacter.speed < 1)
   {
      whichcharacter.speed = 5;
   }
   if(isNaN(whichcharacter.attack) || whichcharacter.attack < 1)
   {
      whichcharacter.attack = 5;
   }
   if(isNaN(whichcharacter.defence) || whichcharacter.defence < 1)
   {
      whichcharacter.defence = 5;
   }
   if(isNaN(whichcharacter.vitality) || whichcharacter.vitality < 1)
   {
      whichcharacter.vitality = 5;
   }
   if(isNaN(whichcharacter.charisma) || whichcharacter.charisma < 1)
   {
      whichcharacter.charisma = 5;
   }
   if(isNaN(whichcharacter.stamina) || whichcharacter.stamina < 1)
   {
      whichcharacter.stamina = 5;
   }
   if(isNaN(whichcharacter.magicka) || whichcharacter.magicka < 1)
   {
      whichcharacter.magicka = 5;
   }
   if(isNaN(whichcharacter.herolevel) || whichcharacter.herolevel < 1)
   {
      whichcharacter.herolevel = 1;
   }
   else if(whichcharacter.herolevel > 60)
   {
      whichcharacter.herolevel = 60;
   }
   if(isNaN(whichcharacter.experience) || whichcharacter.experience < 0)
   {
      whichcharacter.experience = 0;
   }
   if(isNaN(whichcharacter.experienceneeded) || whichcharacter.experienceneeded <= 0)
   {
      whichcharacter.experienceneeded = 100;
   }
   if(isNaN(whichcharacter.villain_xp) || whichcharacter.villain_xp < 0)
   {
      whichcharacter.villain_xp = 50;
   }
   if(whichcharacter.mostpowerfulfoe == undefined || whichcharacter.mostpowerfulfoe == "undefined" || whichcharacter.mostpowerfulfoe == "null" || whichcharacter.mostpowerfulfoe == "")
   {
      whichcharacter.mostpowerfulfoe = "Yet to fight";
   }
   if(isNaN(whichcharacter.goldpieces) || whichcharacter.goldpieces < 0)
   {
      whichcharacter.goldpieces = 0;
   }
   if(isNaN(whichcharacter.current_tournament) || whichcharacter.current_tournament < 1 || whichcharacter.current_tournament > 19)
   {
      whichcharacter.current_tournament = 1;
   }
   if(isNaN(whichcharacter.gladiatorscore) || whichcharacter.gladiatorscore < 0)
   {
      whichcharacter.gladiatorscore = 0;
   }
   if(isNaN(whichcharacter.weapon_enchantment_potency) || whichcharacter.weapon_enchantment_potency < 0)
   {
      whichcharacter.weapon_enchantment_potency = 0;
   }
   if(isNaN(whichcharacter.weapon_enchantment_type) || whichcharacter.weapon_enchantment_type < 0)
   {
      whichcharacter.weapon_enchantment_type = 0;
   }
   if(isNaN(whichcharacter.inventory1) || whichcharacter.inventory1 < 0)
   {
      whichcharacter.inventory1 = 0;
   }
   if(isNaN(whichcharacter.inventory2) || whichcharacter.inventory2 < 0)
   {
      whichcharacter.inventory2 = 0;
   }
   if(isNaN(whichcharacter.inventory3) || whichcharacter.inventory3 < 0)
   {
      whichcharacter.inventory3 = 0;
   }
   if(isNaN(whichcharacter.inventory4) || whichcharacter.inventory4 < 0)
   {
      whichcharacter.inventory4 = 0;
   }
   if(isNaN(whichcharacter.inventory5) || whichcharacter.inventory5 < 0)
   {
      whichcharacter.inventory5 = 0;
   }
   if(isNaN(whichcharacter.inventory6) || whichcharacter.inventory6 < 0)
   {
      whichcharacter.inventory6 = 0;
   }
   if(isNaN(whichcharacter.inventory_maxslots) || whichcharacter.inventory_maxslots < 1)
   {
      whichcharacter.inventory_maxslots = 1;
   }
   if(isNaN(whichcharacter.battleswon) || whichcharacter.battleswon < 0)
   {
      whichcharacter.battleswon = 0;
   }
   if(isNaN(whichcharacter.days_in_arena) || whichcharacter.days_in_arena < 1)
   {
      whichcharacter.days_in_arena = 1;
   }
   if(isNaN(whichcharacter.battlesfought) || whichcharacter.battlesfought < 0)
   {
      whichcharacter.battlesfought = 0;
   }
   if(isNaN(whichcharacter.battleslost) || whichcharacter.battleslost < 0)
   {
      whichcharacter.battleslost = 0;
   }
   if(isNaN(whichcharacter.secondary_weapon) || whichcharacter.secondary_weapon < 0)
   {
      whichcharacter.secondary_weapon = 0;
   }
   if(isNaN(whichcharacter.secondary_weapon_enchantment_potency) || whichcharacter.secondary_weapon_enchantment_potency < 0)
   {
      whichcharacter.secondary_weapon_enchantment_potency = 0;
   }
   if(isNaN(whichcharacter.secondary_weapon_enchantment_type) || whichcharacter.secondary_weapon_enchantment_type < 0)
   {
      whichcharacter.secondary_weapon_enchantment_type = 0;
   }
   if(isNaN(whichcharacter.maximum_ammo) || whichcharacter.maximum_ammo < 0)
   {
      whichcharacter.maximum_ammo = 5;
   }
   if(isNaN(whichcharacter.equipped_weapon) || whichcharacter.equipped_weapon < 1 || whichcharacter.equipped_weapon > 2)
   {
      whichcharacter.equipped_weapon = 1;
   }
   if(whichcharacter == _root.game.hero && !isNaN(Number(_root.game.hero.days_in_arena)))
   {
      _global.day = _root.game.hero.days_in_arena;
   }
   if(whichcharacter.statpoints == undefined || isNaN(Number(whichcharacter.statpoints)))
   {
      whichcharacter.statpoints = 0;
   }
   if(whichcharacter.score == undefined || isNaN(Number(whichcharacter.score)))
   {
      whichcharacter.score = 0;
   }
   if(whichcharacter.tournament_ranking == undefined || isNaN(Number(whichcharacter.tournament_ranking)))
   {
      whichcharacter.tournament_ranking = 2;
   }
   if(whichcharacter.herolevel >= 6)
   {
      whichcharacter.inventory_maxslots = 2;
   }
   if(whichcharacter.herolevel >= 15)
   {
      whichcharacter.inventory_maxslots = 3;
   }
   if(whichcharacter.herolevel >= 20)
   {
      whichcharacter.inventory_maxslots = 4;
   }
   if(whichcharacter.herolevel >= 30)
   {
      whichcharacter.inventory_maxslots = 5;
   }
   if(whichcharacter.herolevel >= 40)
   {
      whichcharacter.inventory_maxslots = 6;
   }
   initcolour(whichcharacter,whichavatar);
   updatecharacter(whichcharacter,whichavatar);
   colorhero(whichcharacter,whichavatar);
   if(typeof(_root.backup_char) == "function")
   {
      _root.backup_char(whichcharacter);
   }
}
function initcolour(whichcharacter, whichavatar)
{
   begincolouring(whichavatar,whichcharacter.skincolor,"head.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Lupperarm.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Rupperarm.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Llowerarm.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Rlowerarm.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Lupperleg.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Rupperleg.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Llowerleg.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"Rlowerleg.bareskin",whichcharacter);
   begincolouring(whichavatar,whichcharacter.skincolor,"torso.bareskin",whichcharacter);
}
function updatecharacter(whichcharacter, whichavatar)
{
   whichavatar.head.attachMovie("eyes1","eyes",1);
   whichavatar.head.attachMovie("mouth1","mouth",2);
   whichavatar.head.eyes._y = -14;
   whichavatar.head.eyes._x = -3;
   whichavatar.head.attachMovie("features" + whichcharacter.features,"features",4);
   whichavatar.head.attachMovie("hair" + whichcharacter.hairstyle,"hair",5);
   if(whichcharacter.helmet != 0)
   {
      whichavatar.head.attachMovie("helmet" + whichcharacter.helmet,"helmet",5);
   }
   whichavatar.head.attachMovie("facehair" + whichcharacter.facehairstyle,"facehair",3);
   whichavatar.torso.attachMovie("breastplate" + whichcharacter.breastplate,"breastplate",1);
   whichavatar.Lupperarm.attachMovie("shoulderguard" + whichcharacter.shoulderguard,"shoulderguard",1);
   whichavatar.Rupperarm.attachMovie("shoulderguard" + whichcharacter.shoulderguard,"shoulderguard",1);
   whichavatar.Llowerarm.attachMovie("gauntlet" + whichcharacter.gauntlet,"gauntlet",1);
   whichavatar.Rlowerarm.attachMovie("gauntlet" + whichcharacter.gauntlet,"gauntlet",2);
   whichavatar.Lupperleg.attachMovie("greaves" + whichcharacter.greaves,"greaves",1);
   whichavatar.Rupperleg.attachMovie("greaves" + whichcharacter.greaves,"greaves",1);
   whichavatar.Llowerleg.attachMovie("shinguard" + whichcharacter.shinguard,"shinguard",1);
   whichavatar.Rlowerleg.attachMovie("shinguard" + whichcharacter.shinguard,"shinguard",1);
   whichavatar.Rfoot.attachMovie("boot" + whichcharacter.boot,"boot",1);
   whichavatar.Lfoot.attachMovie("boot" + whichcharacter.boot,"boot",1);
   if(whichcharacter.equipped_weapon == 1)
   {
      whichavatar.weapon.realweapon.attachMovie("weapon" + whichcharacter.weapon,"weapon",0,{_x:0,_y:0});
      whichavatar.Rlowerarm.attachMovie("shield" + whichcharacter.shield,"shield",3,{_x:0,_y:50});
   }
   else if(whichcharacter.equipped_weapon == 2)
   {
      whichavatar.weapon.realweapon.attachMovie("weapon" + whichcharacter.secondary_weapon,"weapon",0,{_x:0,_y:0});
   }
}
function begincolouring(whichavatar, whichcolor, whichobject, whichcharacter)
{
   whichavatar.head.eyes._visible = true;
   if(whichcolor == 1)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"255",rb:"0",ga:"90",gb:"0",ba:"75",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 1;
   }
   if(whichcolor == 2)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"255",rb:"0",ga:"105",gb:"0",ba:"75",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 1;
   }
   if(whichcolor == 3)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"58",rb:"0",ga:"34",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 1;
   }
   if(whichcolor == 4)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"155",gb:"0",ba:"155",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 6;
   }
   if(whichcolor == 5)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"85",gb:"0",ba:"105",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 7;
   }
   if(whichcolor == 6)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"0",gb:"0",ba:"100",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 9;
   }
   if(whichcolor == 7)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"60",rb:"00",ga:"70",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 8;
   }
   if(whichcolor == 8)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"100",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 10;
   }
   if(whichcolor == 9)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"65",gb:"0",ba:"15",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 10;
      whichcharacter.features = 11;
   }
   if(whichcolor == 10)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"155",rb:"0",ga:"105",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 12;
   }
   if(whichcolor == 11)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"110",rb:"0",ga:"75",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 13;
   }
   if(whichcolor == 12)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"128",rb:"0",ga:"64",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 14;
   }
   if(whichcolor == 13)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"160",rb:"00",ga:"00",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 15;
   }
   if(whichcolor == 14)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"100",rb:"0",ga:"0",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 16;
   }
   if(whichcolor == 15)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"100",rb:"0",ga:"0",gb:"0",ba:"85",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 17;
   }
   if(whichcolor == 16)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"55",rb:"0",ga:"0",gb:"0",ba:"35",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 18;
   }
   if(whichcolor == 17)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"55",rb:"0",ga:"0",gb:"0",ba:"55",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 19;
   }
   if(whichcolor == 18)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"255",rb:"0",ga:"255",gb:"0",ba:"255",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 20;
   }
   if(whichcolor == 19)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"100",rb:"0",ga:"100",gb:"0",ba:"100",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 20;
   }
   if(whichcolor == 20)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"80",rb:"0",ga:"80",gb:"0",ba:"80",bb:"00",aa:"100",ab:"0"};
      whichcharacter.features = 20;
   }
   if(whichcolor == 21)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"0",rb:"0",ga:"0",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 25;
   }
   if(whichcolor == 22)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"58",rb:"0",ga:"34",gb:"0",ba:"0",bb:"0",aa:"100",ab:"0"};
      whichcharacter.features = 22;
   }
   if(whichcolor == 24)
   {
      charColorTransform = new Object();
      charColorTransform = {ra:"255",rb:"0",ga:"105",gb:"0",ba:"78",bb:"0",aa:"122",ab:"0"};
      whichcharacter.features = 24;
   }
   charColor = new Color(whichavatar + "." + whichobject);
   charColor.setTransform(charColorTransform);
}
function updatecast()
{
   constructDNA();
   initcharacter(game.hero,_root.hero,_global.heroDNA);
   updatecharacter(game.hero,_root.hero);
   colorhero(game.hero,_root.hero);
   constructDNA();
   game.hero.charDNA = _global.heroDNA;
   _root.charDNA = game.hero.charDNA;
}
function skincharacter(whichcharacter, whichavatar)
{
   initcharacter(whichcharacter,whichavatar,whichcharacter.charDNA);
   updatecharacter(whichcharacter,whichavatar);
   colorhero(whichcharacter,whichavatar);
   battlevalues(whichcharacter);
   if(whichcharacter.equipped_weapon == 1)
   {
      _root.itemglow(whichavatar.weapon,whichcharacter.weapon_enchantment_type,whichcharacter.weapon_enchantment_potency);
   }
   else if(whichcharacter.equipped_weapon == 2)
   {
      _root.itemglow(whichavatar.weapon,whichcharacter.secondary_weapon_enchantment_type,whichcharacter.secondary_weapon_enchantment_potency);
   }
}
function constructDNA()
{
   if(_global.coop != undefined && _global.coop.role == "client" && (_global.coop.inArena == true || _global.coop.needRestoreLocalHero == true))
   {
      return undefined;
   }
   if(_root.fizMode != "fizzle")
   {
      is_that_virtuous();
   }
   if(_root.game.hero.statpoints == undefined || isNaN(Number(_root.game.hero.statpoints)))
   {
      _root.game.hero.statpoints = 0;
   }
   _root.game.hero.statpoints = Number(_root.game.hero.statpoints);
   if(_root.game.hero.character_name == undefined)
   {
      _root.game.hero.character_name = _root.game.hero.hero_name;
   }
   check_for_nan(_root.game.hero);
   _global.heroDNA = _root.game.hero.character_name + "," + _root.game.hero.skincolor + "," + _root.game.hero.haircolor + "," + _root.game.hero.features + "," + _root.game.hero.hairstyle + "," + _root.game.hero.facehairstyle + "," + game.hero.shoulderguard + "," + _root.game.hero.gauntlet + "," + _root.game.hero.breastplate + "," + _root.game.hero.helmet + "," + _root.game.hero.greaves + "," + _root.game.hero.shinguard + "," + _root.game.hero.boot + "," + _root.game.hero.weapon + "," + _root.game.hero.shield + "," + _root.game.hero.battlesfought + "," + _root.game.hero.strength + "," + _root.game.hero.speed + "," + _root.game.hero.attack + "," + _root.game.hero.defence + "," + _root.game.hero.vitality + "," + _root.game.hero.charisma + "," + _root.game.hero.stamina + "," + _root.game.hero.magicka + "," + _root.game.hero.herolevel + "," + _root.game.hero.experience + "," + _root.game.hero.experienceneeded + "," + _root.game.hero.villain_xp + "," + _root.game.hero.mostpowerfulfoe + "," + _root
   .game.hero.goldpieces + "," + _root.game.hero.current_tournament + "," + _root.game.hero.gladiatorscore + "," + _root.game.hero.weapon_enchantment_potency + "," + _root.game.hero.weapon_enchantment_type + "," + _root.game.hero.inventory1 + "," + _root.game.hero.inventory2 + "," + _root.game.hero.inventory3 + "," + _root.game.hero.inventory4 + "," + _root.game.hero.inventory5 + "," + _root.game.hero.inventory6 + "," + _root.game.hero.inventory_maxslots + "," + _root.game.hero.battleswon + "," + _root.game.hero.days_in_arena + "," + _root.game.hero.battlesfought + "," + _root.game.hero.battleslost + "," + _root.game.hero.secondary_weapon + "," + _root.game.hero.secondary_weapon_enchantment_potency + "," + _root.game.hero.secondary_weapon_enchantment_type + "," + _root.game.hero.maximum_ammo + "," + _root.game.hero.equipped_weapon;
   _root.game.hero.charDNA = _global.heroDNA;
}
function is_that_virtuous()
{
   if(_root.game.hero.gauntlet > 8)
   {
      _root.game.hero.gauntlet = 8;
   }
   if(_root.game.hero.breastplate > 8)
   {
      _root.game.hero.breastplate = 8;
   }
   if(_root.game.hero.breastplate > 8)
   {
      _root.game.hero.breastplate = 8;
   }
   if(_root.game.hero.helmet > 8)
   {
      _root.game.hero.helmet = 8;
   }
   if(_root.game.hero.greaves > 8)
   {
      _root.game.hero.greaves = 8;
   }
   if(_root.game.hero.shinguard > 8)
   {
      _root.game.hero.shinguard = 8;
   }
   if(_root.game.hero.boot > 8)
   {
      _root.game.hero.boot = 8;
   }
   if(_root.game.hero.shield > 8)
   {
      _root.game.hero.shield = 8;
   }
   if(_root.game.hero.strength > 50)
   {
      _root.game.hero.strength = 50;
   }
   if(_root.game.hero.speed > 50)
   {
      _root.game.hero.speed = 50;
   }
   if(_root.game.hero.attack > 50)
   {
      _root.game.hero.attack = 50;
   }
   if(_root.game.hero.defence > 50)
   {
      _root.game.hero.defence = 50;
   }
   if(_root.game.hero.vitality > 50)
   {
      _root.game.hero.vitality = 50;
   }
   if(_root.game.hero.charisma > 50)
   {
      _root.game.hero.charisma = 50;
   }
   if(_root.game.hero.magicka > 50)
   {
      _root.game.hero.magicka = 50;
   }
   if(_root.game.hero.herolevel > 12)
   {
      _root.game.hero.herolevel = 12;
   }
   if(_root.game.hero.inventory_maxslots > 2)
   {
      _root.game.hero.inventory_maxslots = 2;
   }
   if(_root.game.hero.inventory3 > 0 || _root.game.hero.inventory4 > 0 || _root.game.hero.inventory5 > 0 || _root.game.hero.inventory6 > 0)
   {
      _root.game.hero.inventory_maxslots = 2;
   }
   if(_root.game.hero.maximum_ammo > 10)
   {
      _root.game.hero.maximum_ammo = 10;
   }
}
function constructvillainDNA(whichcharacter)
{
   whichcharacter.charDNA = whichcharacter.character_name + "," + whichcharacter.skincolor + "," + whichcharacter.haircolor + "," + whichcharacter.features + "," + whichcharacter.hairstyle + "," + whichcharacter.facehairstyle + "," + whichcharacter.shoulderguard + "," + whichcharacter.gauntlet + "," + whichcharacter.breastplate + "," + whichcharacter.helmet + "," + whichcharacter.greaves + "," + whichcharacter.shinguard + "," + whichcharacter.boot + "," + whichcharacter.weapon + "," + whichcharacter.shield + "," + whichcharacter.battlesfought + "," + whichcharacter.strength + "," + whichcharacter.speed + "," + whichcharacter.attack + "," + whichcharacter.defence + "," + whichcharacter.vitality + "," + whichcharacter.charisma + "," + whichcharacter.stamina + "," + whichcharacter.magicka + "," + whichcharacter.herolevel + "," + whichcharacter.experience + "," + whichcharacter.experienceneeded + "," + whichcharacter.villain_xp + "," + whichcharacter.mostpowerfulfoe + "," + 0 + "," + whichcharacter
   .current_tournament + "," + whichcharacter.gladiatorscore + "," + whichcharacter.weapon_enchantment_potency + "," + whichcharacter.weapon_enchantment_type + "," + whichcharacter.inventory1 + "," + whichcharacter.inventory2 + "," + whichcharacter.inventory3 + "," + whichcharacter.inventory4 + "," + whichcharacter.inventory5 + "," + whichcharacter.inventory6 + "," + whichcharacter.inventory_maxslots + "," + whichcharacter.battleswon + "," + whichcharacter.days_in_arena + "," + whichcharacter.battlesfought + "," + whichcharacter.battleslost + "," + whichcharacter.secondary_weapon + "," + whichcharacter.secondary_weapon_enchantment_potency + "," + whichcharacter.secondary_weapon_enchantment_type + "," + whichcharacter.maximum_ammo + "," + whichcharacter.equipped_weapon;
   whichcharacter.charDNA = whichcharacter.charDNA;
}
function colorhero(whichcharacter, whichavatar, whichcolor)
{
   begincolouring(whichavatar,whichcharacter.haircolor,"head.hair");
   begincolouring(whichavatar,whichcharacter.haircolor,"head.facehair");
}
function check_for_nan(whichcharacter)
{
   if(whichcharacter == undefined || whichcharacter == null)
   {
      return undefined;
   }
   whichcharacter.goldpieces = Number(whichcharacter.goldpieces);
   whichcharacter.herolevel = Number(whichcharacter.herolevel);
   if(whichcharacter.herolevel < 1 || whichcharacter.herolevel > 60 || whichcharacter.herolevel == undefined || whichcharacter.herolevel == null || isNaN(whichcharacter.herolevel) == true)
   {
      whichcharacter.herolevel = 1;
   }
   if(whichcharacter.goldpieces < 0 || whichcharacter.goldpieces == undefined || whichcharacter.goldpieces == null || isNaN(whichcharacter.goldpieces) == true)
   {
      whichcharacter.goldpieces = 0;
   }
   if(whichcharacter.statpoints < 0 || whichcharacter.statpoints == undefined || whichcharacter.statpoints == null || isNaN(whichcharacter.statpoints) == true)
   {
      whichcharacter.statpoints = 0;
   }
}
