local function wait(n)for _=1,n do coroutine.yield()end end
return function(game)
 local identity=os.getenv('POKEPORT_IDENTITY')or''
 assert(identity:match('^ascendant%-gameplay%-'),'Use a dedicated ascendant-gameplay- POKEPORT_IDENTITY; this fixture starts a new game')
 io.stdout:setvbuf('no')
 local out=assert(os.getenv('ASCENDANT_PLAY_OUT'));local host=assert(os.getenv('ASCENDANT_PLAY_HOST'))
 local phase=os.getenv('ASCENDANT_PLAY_PHASE')or'play'
 local function record(s)print('PLAY_QA '..host..' '..s)end
 local function describe()local s=game.stack:top();return require('src.core.StateStack').describe and require('src.core.StateStack').describe(s)or tostring(s)end
 local function shot(name)
  wait(8);local done=false
  love.graphics.captureScreenshot(function(frame)local f=assert(io.open(out..'/'..host..'-'..name..'.png','wb'));f:write(frame:encode('png'):getString());f:close();done=true end)
  for _=1,120 do if done then break end;wait(1)end
  assert(done,'screenshot not rendered: '..name);record('SHOT '..name)
 end
 local function tap(button)
  table.insert(game.input.pressQueue,button);wait(2);game.input.state[button]=false;wait(8)
 end
 local function closeToWorld()
  for _=1,16 do if game.stack:top()==game.overworld then return end;tap('b');wait(8)end
  error('cannot return to world: '..describe())
 end
 local function startItem(fragment)
  closeToWorld();tap('start');wait(10)
  local s=game.stack:top();assert(s.items,'no start items: '..describe())
  local target
  for i,row in ipairs(s.items)do record('START_ROW '..tostring(row.label));if tostring(row.label):upper():find(fragment,1,true)then target=i end end
  assert(target,'missing start item '..fragment)
  for _=1,#s.items do if s.index==target then break end;tap('down')end
  assert(s.index==target,'menu navigation failed');tap('a');wait(30)
 end
 local function settleWorld()
  for _=1,120 do
   if game.stack:top()==game.overworld and not game.overworld.player.inputLocked then wait(15);if game.stack:top()==game.overworld and not game.overworld.player.inputLocked then return end end
   if game.stack:top()~=game.overworld then tap('a')else wait(10)end
  end
  error('world remains busy: '..describe())
 end
 local dirs={{'up',0,-1},{'right',1,0},{'down',0,1},{'left',-1,0}}
 local function walkTo(tx,ty,warp)
  settleWorld();local old=game.overworld.map.id;local blocked={}
  for attempt=1,90 do
   local ow=game.overworld;local p=ow.player
   if ow.map.id~=old then assert(warp==ow.map.id,'unexpected map '..ow.map.id);record('WARP '..old..' -> '..ow.map.id);wait(90);return end
   if p.cellX==tx and p.cellY==ty and not p.moving then if not warp then return end;if warp=='PALLET_TOWN'then game.input.state.down=true;wait(45);game.input.state.down=false end;wait(120);assert(game.overworld.map.id==warp,'warp did not complete');record('WARP '..old..' -> '..game.overworld.map.id);return end
   local q={{p.cellX,p.cellY}};local seen={[p.cellX..','..p.cellY]=true};local head=1;local path
   while head<=#q do
    local v=q[head];head=head+1
    if v[1]==tx and v[2]==ty then path=v;break end
    for _,d in ipairs(dirs)do local x,y=v[1]+d[2],v[2]+d[3];local k=x..','..y
     if not seen[k]and not blocked[k]and x>=0 and y>=0 and x<40 and y<40 and ow.map:isWalkableCell(x,y)then seen[k]=true;q[#q+1]={x,y,prev=v,dir=d[1]}end
    end
   end
   assert(path,'no walkable path '..tx..','..ty)
   while path.prev and path.prev.prev do path=path.prev end
   local button=path.dir;assert(button,'warp did not fire at '..tx..','..ty)
   local x,y=p.cellX,p.cellY
   game.input.state[button]=true;table.insert(game.input.pressQueue,button)
   for _=1,45 do wait(1);if game.overworld.map.id~=old or p.cellX~=x or p.cellY~=y or p.moving then break end end
   game.input.state[button]=false
   for _=1,60 do wait(1);if not p.moving then break end end
   wait(12)
   if game.overworld.map.id==old and p.cellX==x and p.cellY==y then blocked[path[1]..','..path[2]]=true;record('REROUTE blocked '..path[1]..','..path[2])end
   record('WALK '..game.overworld.map.id..' '..p.cellX..','..p.cellY)
  end
  error('walk timed out '..old..' -> '..tx..','..ty..' top='..describe())
 end
 local ok,err=xpcall(function()
  love.audio.setVolume(0);love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
  assert(game.mods.exports.VOXEL_ASCENDANT and game.mods.exports.kanto_ascendant,'both mods required')
  record('FULL_GAME_LOAD phase='..phase)
  for _,id in ipairs({'VOXEL_ASCENDANT','kanto_ascendant'})do assert(not game.mods.mods[id].failed,id..' failed')end
  local V=game.mods.exports.VOXEL_ASCENDANT
  if V.ascendantContent then V.ascendantContent.onboardingShown=true;V.ascendantContent.promptDisabled=true end
  if V.setupCard then V.setupCard.suspended=true end
  local SaveData=require('src.core.SaveData')
  local archive=assert(game.mods.exports.kanto_ascendant.legacyJourney.archive)
  local function verifyArchive()local valid,reason=archive.lineageStatus(game.save);assert(valid,'Legacy archive rejected the save: '..tostring(reason));record('LEGACY_LINEAGE_PASS '..tostring(reason))end
  if phase=='reload'then
   local saved=assert(SaveData.load('red'),'no disk save');game:restoreSave(saved);wait(150)
   assert(game.overworld.map.id=='PALLET_TOWN','saved map not restored')
   local mon=game.save.party[1];assert(mon.species=='BULBASAUR'and mon.moves[1].pp<35,'saved party/PP not restored')
   assert(game.save.flags.ASCENDANT_GAMEPLAY_QA,'saved marker not restored')
   local archived=assert(archive.load());(function()local written,why=archive.write(archived);assert(written,'Legacy archive storage write/readback failed: '..tostring(why))end)();assert(game:writeSave()~=false);record('LEGACY_ARCHIVE_STORAGE_PASS');verifyArchive();shot('12-fresh-process-reload');startItem('ASCENDANT');shot('13-reloaded-ascendant');closeToWorld()
   record('FRESH_PROCESS_RELOAD_PASS');return
  end
  local oldSave=game.save
  if game.startNewGame then game:startNewGame({intro=false})else local title=game:makeTitleState();assert(title.onNewGame,'missing genuine New Game callback');title.onNewGame()end
  for _=1,600 do if game.save~=oldSave then break end;tap('start');wait(5)end
  assert(game.save~=oldSave,'New Game did not create a new save');record('GENUINE_NEW_GAME')
  wait(1);while game.stack:top()do game.stack:pop()end
  local Pokemon=require('src.pokemon.Pokemon');game.save.party={Pokemon.new(game.data,'BULBASAUR',30)}
  game.save.party[1].moves={{id='TACKLE',pp=35}};game.save.flags.EVENT_GOT_POKEDEX=true
  require('src.inventory.Bag').add(game.save,'POTION',3,game.data)
  game.stack:push(require('src.world.OverworldController'),'REDS_HOUSE_2F',3,6,'up')
  wait(120);assert(game.overworld.map.id=='REDS_HOUSE_2F');record('WORLD_ENTER');if phase=='archive-probe'then local a=assert(archive.load());local w,e=archive.write(a);record('ARCHIVE_PROBE '..tostring(w)..' '..tostring(e));assert(w,e);return end;shot('01-world')
  tap('start');wait(20);assert(game.stack:top()~=game.overworld,'start menu did not open');shot('02-start-menu');tap('b');wait(10)
  startItem('MON');shot('03-party');tap('a');wait(15);shot('04-party-actions');tap('a');wait(40);shot('05-summary');closeToWorld();record('PARTY_SUMMARY_PASS')
  startItem('ITEM');shot('06-bag');tap('down');tap('up');closeToWorld();record('BAG_PASS')
  startItem('ASCENDANT');shot('07-ascendant');tap('down');tap('up');closeToWorld();record('KASC_MENU_PASS')
  if V.setupCard then V.setupCard.suspended=false;V.setupCard.open(game);wait(40);shot('08-vasc-your-look');closeToWorld();V.setupCard.suspended=true;record('VASC_MENU_PASS')end
  walkTo(7,1,'REDS_HOUSE_1F');settleWorld();shot('09-downstairs')
  walkTo(2,7,'PALLET_TOWN');settleWorld();shot('10-outdoors')
  local mon=game.save.party[1];local exp=mon.exp
  local battle=require('src.battle.BattleState').newWild(game,'RATTATA',5)
  game.stack:push(battle)
  local gotMenu,gotMove=false,false
  for step=1,500 do
   if game.stack:top()==game.overworld then break end
   if battle.phase=='menu'and not gotMenu then shot('11-battle-menu');gotMenu=true end
   if battle.phase=='moveSelect'and not gotMove then shot('11b-move-selection');gotMove=true end
   tap('a');wait(10)
   if step%25==0 then record('BATTLE phase='..tostring(battle.phase)..' enemyHP='..tostring(battle.enemy and battle.enemy.mon.hp)..' top='..describe())end
  end
  assert(game.stack:top()==game.overworld,'battle did not finish: '..tostring(battle.phase))
  assert(gotMenu and gotMove,'battle menus not exercised');assert(battle.enemy.mon.hp<=0,'enemy not defeated')
  assert(mon.moves[1].pp<35,'PP not spent');assert(mon.exp>exp,'no battle experience');record('BATTLE_WIN hp='..mon.hp..' pp='..mon.moves[1].pp..' exp='..mon.exp)
  local archived=assert(archive.load());(function()local written,why=archive.write(archived);assert(written,'Legacy archive storage write/readback failed: '..tostring(why))end)();record('LEGACY_ARCHIVE_STORAGE_PASS')
  game.save.flags.ASCENDANT_GAMEPLAY_QA=true
  assert(game:writeSave()~=false,'save write failed');local saved=assert(SaveData.load('red'),'disk save missing')
  assert(saved.party[1].moves[1].pp==mon.moves[1].pp,'saved PP mismatch');game:restoreSave(saved);wait(150)
  assert(game.overworld.map.id=='PALLET_TOWN','same-process load map mismatch');shot('11c-saved-reloaded');verifyArchive();record('SAVE_LOAD_PASS')
 end,debug.traceback)
 local f=assert(io.open(out..'/'..host..'-'..phase..'-result.txt','w'));f:write(ok and 'PASS\n'or('FAIL\n'..tostring(err)));f:close()
 if not ok then print('PLAY_QA_FAIL '..tostring(err))end
 love.event.quit(ok and 0 or 1)
end
