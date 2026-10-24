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
 -- Private instrumentation of the real application loop. No offscreen synthetic
 -- render, forced GPU synchronization, screenshots or writes inside a sample.
 local clock=love.timer.getTime
 local active,previous,frameUpdate,frameDraw=false,nil,0,0
 local rows,segments,scopes={},{},{}
 local profiling=qa and qa:read('profile.txt')=='1'
 local selection=qa and qa:read('scenario.txt')
 local requestedShadows=qa and qa:read('shadows.txt')=='1'
 local originalUpdate,originalDraw,originalPresent=love.update,love.draw,love.graphics.present
 love.update=function(...)
  local t=clock();local r=originalUpdate(...);frameUpdate=clock()-t;return r
 end
 love.draw=function(...)
  local t=clock();local r=originalDraw(...);frameDraw=clock()-t;return r
 end
 love.graphics.present=function(...)
  local stats=active and love.graphics.getStats()
  local t=clock();local r=originalPresent(...);local now=clock()
  if active then
   if previous then
    rows[#rows+1]={now-previous,frameUpdate,frameDraw,now-t,stats.drawcalls or 0,
     stats.canvasswitches or 0,collectgarbage('count'),
     game.stack:top()==game.overworld and 1 or 0}
   end
   previous=now
  end
  return r
 end
 local function saveRows(name)
  local csv={'frame_ms,update_ms,draw_ms,present_ms,draw_calls,canvas_switches,lua_kib,world_visible'}
  for _,r in ipairs(rows)do
   csv[#csv+1]=string.format('%.6f,%.6f,%.6f,%.6f,%d,%d,%.3f,%d',r[1]*1000,r[2]*1000,r[3]*1000,r[4]*1000,r[5],r[6],r[7],r[8])
  end
  write(name..'_csv',table.concat(csv,'\n')..'\n')
 end
 local function sample(name,seconds,action)
  game.input:reset();wait(15)
  local status=scene.sceneryStatus(game.overworld)
  assert(voxel.ready and (not status.enabled or status.horizon and status.horizon.ready),'sample without finished scenery')
  assert(V.lib.require('AntiAlias').resolution:get()=='native','resolution changed')
  assert(V.lib.require('AntiAlias').factor()==1,'native scene scale changed')
  local pixelW,pixelH=love.graphics.getPixelDimensions()
  local sceneW,sceneH=G.size()
  local player=game.overworld.player
  local sx,sy=player.px,player.py
  rows={};scopes={};previous=nil
  active=true
  local epochStart=os.time()
  local start=clock()
  while clock()-start<seconds do
   assert(select(1,love.graphics.getPixelDimensions())==pixelW and select(2,love.graphics.getPixelDimensions())==pixelH,'display resized during measured segment')
   if action then action(clock()-start)end
   wait(1)
  end
  active=false
  game.input:reset();game:gamepadaxis(nil,'rightx',0)
  saveRows(name)
  if profiling then write(name..'_profile_json',require('src.link.Json').encode(scopes))end
  local n,total=0,0;for _,r in ipairs(rows)do n=n+1;total=total+r[1]end
  local desc={name=name,epochStart=epochStart,epochEnd=os.time(),frames=n,seconds=total,fps=n/math.max(total,.00001),map=game.overworld.map.id,
   camera=voxel.level,shadowsRequested=requestedShadows,shadowsActive=G.shadowsActive()and true or false,pixelWidth=pixelW,pixelHeight=pixelH,sceneWidth=sceneW,sceneHeight=sceneH,movedPixels=math.sqrt((player.px-sx)^2+(player.py-sy)^2),sceneScale=V.lib.require('AntiAlias').factor()}
  segments[#segments+1]=desc
  log(string.format('SAMPLE %s n=%d seconds=%.3f fps=%.2f camera=%s',name,n,total,desc.fps,tostring(voxel.level)))
  assert(n>=30,'too few rendered frames')
  wait(30)
 end
 local ok,err=xpcall(function()
  love.audio.setVolume(0)
  V=assert(game.mods.exports.VOXEL_ASCENDANT);assert(game.mods.exports.kanto_ascendant)
  for _,id in ipairs({'VOXEL_ASCENDANT','kanto_ascendant'})do assert(not game.mods.mods[id].failed,id..' failed')end
  voxel=assert(V.lib.require('VoxelState'));scene=assert(V.lib.require('VoxelScene'));G=assert(V.Voxel3D)
  if profiling then
   local phase,phaseTime
   G._qaPerformanceProbe=function(name)
    if not active then phase=nil;return end
    local now=clock()
    if name~='start'and phase then
     local label='beginScene.'..phase;local dt=now-phaseTime
     local r=scopes[label]or{calls=0,seconds=0,max=0};scopes[label]=r
     r.calls=r.calls+1;r.seconds=r.seconds+dt;r.max=math.max(r.max,dt)
    end
    phase,phaseTime=name,now
   end
   local function instrument(tab,name,label)
    local fn=tab[name];if type(fn)~='function'then return end
    tab[name]=function(...)
     if not active then return fn(...)end
     local function pack(...)return {n=select('#',...),...}end
     local t=clock();local result=pack(fn(...));local dt=clock()-t
     local r=scopes[label]or{calls=0,seconds=0,max=0};scopes[label]=r
     r.calls=r.calls+1;r.seconds=r.seconds+dt;r.max=math.max(r.max,dt)
     return unpack(result,1,result.n)
    end
   end
   for _,name in ipairs({'draw','beginScene','endScene','beginWater','endWater','glass','flatten','weatherGround','seasonFoliage','modelGrass','roomVisibility','beginWorldLayer','endWorldLayer','viewProjection','skyBody'})do instrument(G,name,'Voxel3D.'..name)end
   for _,name in ipairs({'render','prefetch','drawWater'})do instrument(scene,name,'VoxelScene.'..name)end
   for _,name in ipairs({'draw','drawInstanced','setCanvas','clear','setShader','rectangle','polygon','newImage','newMesh','newCanvas'})do instrument(love.graphics,name,'graphics.'..name)end
  end
  if V.ascendantContent then V.ascendantContent.onboardingShown=true;V.ascendantContent.promptDisabled=true end
  if V.setupCard then V.setupCard.suspended=true end
  local saved=assert(require('src.core.SaveData').load('red'));game:restoreSave(saved);wait(90);settle()
  local osname=love.system.getOS()
  if osname~='Android'and osname~='iOS'then
   love.window.setMode(1280,720,{resizable=false,vsync=1,highdpi=false})
   love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
   love.keypressed=function()end;love.keyreleased=function()end;love.keyboard.isDown=function()return false end
   love.mousepressed=function()end;love.mousereleased=function()end;love.mousemoved=function()end
  end
  option('deviceProfile','custom');option('sceneResolution','native');option('shadows',requestedShadows);option('aa',0)
  option('scenery','full');option('realWindows',true);option('palletBuildings',true)
  level(1)
  local renderer={love.graphics.getRendererInfo()}
  local w,h=love.graphics.getDimensions()
  local pixelW,pixelH=love.graphics.getPixelDimensions()
  local metadata={host=host,os=osname,renderer=renderer,width=w,height=h,pixelWidth=pixelW,pixelHeight=pixelH,
   settings={scenery='full',realWindows=true,sceneResolution='native',aa=0,shadows=requestedShadows,tiltshift=0,deviceProfile='custom',weather='clear',daytime='day'},
   versions={vasc=game.mods.mods.VOXEL_ASCENDANT.manifest.version,kasc=game.mods.mods.kanto_ascendant.manifest.version},
   method='consecutive love.graphics.present completion timestamps; wall-time update/draw/present; normal host loop and frame cap; real final scene'}
  write('metadata_json',require('src.link.Json').encode(metadata))
  log('SETTINGS '..w..'x'..h..' '..osname..' '..table.concat(renderer,' / '))
  local duration=tonumber(qa and qa:read('duration.txt')or'')or 15
  local maps={{'REDS_HOUSE_2F',2,3,'bedroom'},{'PALLET_TOWN',7,7,'pallet'},{'VIRIDIAN_MART',3,5,'mart'},{'SILPH_CO_2F',8,11,'silph'}}
  if selection=='mart'then maps={maps[3],maps[3]}elseif selection=='pallet'then maps={maps[2]}elseif selection=='bedroom'then maps={maps[1]}elseif selection=='silph'then maps={maps[4]}elseif selection=='fp'or selection=='fp-look'then maps={}elseif profiling then maps={maps[2]}end
  for pass,c in ipairs(maps)do
   if selection=='mart'then c={c[1],c[2],c[3],'mart-pass'..pass}end
   local started=clock();rows={};previous=nil;active=true
   enter(c[1],c[2],c[3]);awaitScene();active=false
   saveRows(c[4]..'-transition')
   log(string.format('LOAD %s %.3f seconds',c[4],clock()-started))
   shot(c[4]..'-full');wait(90)
   sample(c[4]..'-full-idle',duration)
   if c[4]=='pallet'then
    local held
    local function walk(t)
     local key=math.floor(t/.7)%2==0 and'right'or'left'
     if held~=key then if held then game.input:overlayReleased(held)end;game.input:overlayPressed(key);held=key end
    end
    sample('pallet-full-walk',duration,walk)
   end
  end
  if not profiling and (not selection or selection==''or selection=='fp'or selection=='fp-look')then
  enter('SILPH_CO_2F',1,9);level(6);awaitScene()
  local untilTime=clock()+20
  while clock()<untilTime do
   local eye,focus=G.eye,G.focus;local a=math.atan2(focus[1]-eye[1],-(focus[3]-eye[3]))
   local diff=(-math.pi/2-a+math.pi)%(math.pi*2)-math.pi
   if math.abs(diff)<.025 then break end
   game:gamepadaxis(nil,'rightx',(diff>=0 and 1 or -1)*math.min(.6,.18+math.abs(diff)*.5));wait(1)
  end
  game:gamepadaxis(nil,'rightx',0);wait(60);shot('silph-window-fp');wait(60)
  if selection~='fp-look'then sample('silph-window-fp-idle',duration)end
  sample('silph-window-fp-look',duration,function(t)game:gamepadaxis(nil,'rightx',math.floor(t/2)%2==0 and .32 or -.32)end)
  end
  write('summary_json',require('src.link.Json').encode({metadata=metadata,segments=segments}))
  log('PASS')
 end,(debug and debug.traceback)or tostring)
 active=false;love.update=originalUpdate;love.draw=originalDraw;love.graphics.present=originalPresent
 write('result_txt',ok and'PASS\n'or('FAIL\n'..tostring(err)))
 if not ok then print('PERFORMANCE_FAIL '..tostring(err))end
 love.event.quit(ok and 0 or 1)
end
