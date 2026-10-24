local function wait(n)for _=1,n do coroutine.yield()end end
return function(game,qa)
 if not (qa and type(qa.read)=='function')then qa=nil end
 if qa then assert(qa.id=='ASCENDANT_GAMEPLAY_QA','Private QA mod required')else assert((os.getenv('POKEPORT_IDENTITY')or''):match('^ascendant%-geometry%-'),'Dedicated ascendant-geometry- identity required')end
 local host=qa and qa:read('host.txt')or assert(os.getenv('GEO_HOST'))
 local out=not qa and assert(os.getenv('GEO_OUT'))or nil
 local function write(name,bytes)
  if qa then return assert(qa.storage:writeBytes(game,'geo_'..host..'_'..name,bytes))end
  local f=assert(io.open(out..'/'..host..'-'..name,'wb'));f:write(bytes);f:close();return true
 end
 local records={}
 local function log(s)records[#records+1]=s;print('GEOMETRY '..host..' '..s);write('progress_txt',table.concat(records,'\n'))end
 local function tap(key)game.input:overlayPressed(key);wait(2);game.input:overlayReleased(key);wait(5)end
 local function settle()
  local deadline=love.timer.getTime()+180
  while love.timer.getTime()<deadline do
   if game.stack:top()==game.overworld and not game.overworld.player.inputLocked then return end
   local top=game.stack:top()
   if top and (top.phase=='out'or top.phase=='in')then wait(3)
   elseif top~=game.overworld then tap('a')else wait(5)end
  end
  error('world busy for 180 seconds')
 end
 local V,scene,voxel,G
 local nextWaitDump=0
 local function pending(tag)
  local now=love.timer.getTime();if now<nextWaitDump then return end;nextWaitDump=now+10
  local st=scene.sceneryStatus(game.overworld);local g=st.gate or{};local h=st.horizon or{}
  log('WAIT '..tag..' voxel='..tostring(st.voxelReady)..' map='..tostring(st.mapReady)..' reveal='..tostring(st.ready)..' active='..tostring(g.active)..' core='..tostring(g.coreReady)..' safe='..tostring(g.hasSafeCanvas)..' horizon='..tostring(g.resources and g.resources.horizon)..' panorama='..tostring(g.resources and g.resources.panorama)..' failed='..tostring(g.failure)..' hready='..tostring(h.ready)..' hresumes='..tostring(h.resumes)..' pending='..tostring(st.pending))
 end
 local function awaitScene()
  local deadline=love.timer.getTime()+180
  while true do
   local st=scene.sceneryStatus and scene.sceneryStatus(game.overworld)or{}
   local gate=st.gate or{}
   assert(not gate.failed,'scenery transaction failed: '..tostring(gate.failure))
   local h=st.horizon or{}
   if voxel.ready and (not st.enabled or st.mobile and gate.active and h.ready or not st.mobile and h.ready)then return end
   pending('scene')
   assert(love.timer.getTime()<deadline,'scene not complete: '..game.overworld.map.id)
   wait(3)
  end
 end
 local function shot(name)
  awaitScene();wait(15);local done=false
  love.graphics.captureScreenshot(function(d)write(name..'.png',d:encode('png'):getString());done=true end)
  for _=1,180 do if done then break end;wait(1)end;assert(done,'capture timed out')
  local eye=G and G.eye or{};local focus=G and G.focus or{}
  log('SHOT '..name..' level='..tostring(voxel and voxel.level)..' eye='..table.concat(eye,',')..' focus='..table.concat(focus,','))
 end
 local function option(key,value)
  local id='VOXEL_ASCENDANT';local o=game.save.options;o.modOptions=o.modOptions or{};o.modOptions[id]=o.modOptions[id]or{};o.modOptions[id][key]=value
  game.mods.modOptions[id]=game.mods.modOptions[id]or{};game.mods.modOptions[id][key]=value
  game.mods.events:emit('mod.options_changed',{mod=id,key=key,value=value})
 end
 local function level(n)
  game.input:reset()
  game.save.options.pipelines=game.save.options.pipelines or{};game.save.options.pipelines.voxel=n
  require('src.render.Pipelines').applyOptions(game.save.options);wait(45)
  game.save.options.pipelines.tiltshift=0;require('src.render.Pipelines').applyOptions(game.save.options);wait(5)
  if n==1 then option('daytime','day');option('weather','clear')end
  assert(voxel.level==n,'camera level mismatch '..tostring(voxel.level)..' expected '..n)
 end
 local function enter(id,x,y)
  local started=love.timer.getTime()
  game.input:reset()
  -- Use the real fade/map/reveal lifecycle instead of publishing an uncovered
  -- half-built fixture. Actual wall input remains in the collision probes.
  game.overworld:startWarpTo(id,x,y,'up')
  local deadline=love.timer.getTime()+180
  while game.overworld.map.id~=id or game.stack:top()~=game.overworld do
   pending('warp')
   assert(love.timer.getTime()<deadline,'warp/reveal timed out: '..id)
   local top=game.stack:top()
   if top and (top.phase=='out'or top.phase=='in')then wait(3)
   elseif top~=game.overworld then tap('a')else wait(3)end
  end
  settle()
  while true do
   local st=scene.sceneryStatus and scene.sceneryStatus(game.overworld)or{}
   local g=st.gate or{}
   assert(not g.failed,'scenery transaction failed: '..tostring(g.failure))
   if scene.readyForReveal(game.overworld)and (not st.mobile or not st.enabled or g.active)then break end
   pending('scene')
   assert(love.timer.getTime()<deadline,'scene not complete: '..id)
   wait(3)
  end
  wait(30)
  if scene.sceneryStatus then local st=scene.sceneryStatus(game.overworld);local g=st.gate or{};local h=st.horizon or{};log('STATUS ready='..tostring(st.ready)..' enabled='..tostring(st.enabled)..' active='..tostring(g.active)..' failed='..tostring(g.failure)..' horizonReady='..tostring(h.ready)..' horizonResumes='..tostring(h.resumes)..' horizonFailed='..tostring(h.failed))end
  assert(game.overworld.map.id==id,'map changed during fixture')
  log('ENTER '..id..' dims='..game.overworld.map.def.width..','..game.overworld.map.def.height..' tileset='..game.overworld.map.def.tileset..' preparedSeconds='..string.format('%.2f',love.timer.getTime()-started))
 end
 local ok,err=xpcall(function()
  if not qa then io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end;love.window.setMode(1024,768,{resizable=true});love.keypressed=function()end;love.keyreleased=function()end;love.keyboard.isDown=function()return false end;love.mousepressed=function()end;love.mousereleased=function()end end
  love.audio.setVolume(0)
  V=assert(game.mods.exports.VOXEL_ASCENDANT);assert(game.mods.exports.kanto_ascendant)
  for _,id in ipairs({'VOXEL_ASCENDANT','kanto_ascendant'})do assert(not game.mods.mods[id].failed,id..' failed')end
  voxel=assert(V.lib.require('VoxelState'));scene=assert(V.lib.require('VoxelScene'));G=assert(V.Voxel3D)
  if V.ascendantContent then V.ascendantContent.onboardingShown=true;V.ascendantContent.promptDisabled=true end
  if V.setupCard then V.setupCard.suspended=true end
  local saved=assert(require('src.core.SaveData').load('red'));game:restoreSave(saved);wait(90);settle()
  local report=game.saveReport
  if report then assert(#report.lostMons==0 and #report.lostItems==0 and #report.remappedMaps==0,'Save content was quarantined');log('SAVE_CONTENT_RETAINED')end
  option('deviceProfile','custom');option('daytime','day');option('weather','clear');option('sceneResolution','native');option('shadows',false);option('aa',0)
  log('SETTINGS deviceProfile=custom sceneResolution='..tostring(V.lib.require('AntiAlias').resolution:get())..' shadows=false aa=0')
  option('scenery','full');option('realWindows',true);option('palletBuildings',true)
  level(1);enter('SILPH_CO_2F',8,11)
  local map=game.overworld.map;local pick,best
  for y=2,map.def.height*2-3 do for x=1,map.def.width*2-2 do
   if map:isWalkableCell(x,y)and not require('src.world.Collision').occupied(game.overworld.entities,x,y,game.overworld.player)and not map:warpAtCell(x,y)then
    local score=x*1000+math.abs(y-map.def.height)
    if not best or score<best then best=score;pick={x,y}end
   end
  end end
  assert(pick);enter('SILPH_CO_2F',pick[1],pick[2]);level(6)
  local untilTime=love.timer.getTime()+20
  while love.timer.getTime()<untilTime do
   local eye,focus=G.eye,G.focus;local a=math.atan2(focus[1]-eye[1],-(focus[3]-eye[3]))
   local diff=(-math.pi/2-a+math.pi)%(math.pi*2)-math.pi
   if math.abs(diff)<.025 then break end
   game:gamepadaxis(nil,'rightx',(diff>=0 and 1 or -1)*math.min(.6,.18+math.abs(diff)*.5));wait(1)
  end
  game:gamepadaxis(nil,'rightx',0);wait(15)
  shot('silph-window-open')
  local p=game.overworld.player;local x,y,px=p.cellX,p.cellY,p.px
  game.input:overlayPressed('up');wait(90);game.input:overlayReleased('up');wait(10)
  assert(p.cellX==x and p.cellY==y,'walked through exterior glass')
  assert(p.px<px-.5 and p.px>px-4,'glass approach did not stop at boundary')
  log('GLASS_COLLISION_PASS '..x..','..y..' movedPixels='..string.format('%.3f',px-p.px))
  shot('silph-glass-stop')
  option('realWindows',false);wait(5);shot('silph-window-closed')
  option('realWindows',true);wait(5);shot('silph-window-reopened')
  log('WINDOW_TOGGLE_PASS')
  log('PASS')
 end,(debug and debug.traceback)or tostring)
 write('result_txt',ok and 'PASS\n'or('FAIL\n'..tostring(err)))
 if not ok then print('GEOMETRY_FAIL '..tostring(err))end
 love.event.quit(ok and 0 or 1)
end
