-- Run from the repository: luajit tests/android_hot_path_test.lua [repo-root-with-trailing-slash]
local root=(arg and arg[1])or''
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
for _,platform in ipairs{'Android','iOS','Linux','OS X'}do
 local store,writes,fail={},0,nil
 local function write(path,payload)
  writes=writes+1;store[path]=payload
  if fail=='throw'then fail=nil;error('partial write')end
  if fail=='false'then fail=nil;return false end
  return true
 end
 local fs={write=write,read=function(p)return store[p]end,remove=function(p)store[p]=nil;return true end}
 love={system={getOS=function()return platform end},filesystem=fs}
 local D=assert(loadfile(root..'lib/Diagnostics.lua'))({mod={},require=function()error('no module')end})
 local mobile=platform=='Android'or platform=='iOS'
 local f={kind=D.MOBILE_RECOVERY_KIND,schema='v1',build='rc4',mode='LIVE_TEST',phase='draw',status='PASS',generation=1,checkpoint='scene-ready'}
 check(D.writeMobileRecoveryMarker(f),'initial write')
 check(writes==(mobile and 1 or 0),'platform writes')
 if mobile then
  local bytes=store[D.MOBILE_RECOVERY_MARKER]
  for _=1,10000 do check(D.writeMobileRecoveryMarker(f),'repeat result')end
  check(writes==1 and store[D.MOBILE_RECOVERY_MARKER]==bytes,'identical durable payload rewritten')
  for _,key in ipairs{'schema','build','mode','phase','status','generation','checkpoint'}do
   local old=f[key];f[key]=tostring(old)..'-changed'
   local before=writes;check(D.writeMobileRecoveryMarker(f)and writes==before+1,'changed '..key..' not committed')
   check(D.writeMobileRecoveryMarker(f)and writes==before+1,'same '..key..' repeated')
   f[key]=old;check(D.writeMobileRecoveryMarker(f)and writes==before+2,'restored '..key..' lost')
  end
  for _,kind in ipairs{'false','throw'}do
   fail=kind;f.checkpoint='start-'..kind;local before=writes
   check(not D.writeMobileRecoveryMarker(f)and writes==before+1,'failed write accepted')
   f.checkpoint='scene-ready'
   check(D.writeMobileRecoveryMarker(f)and writes==before+2,'failed changed write retained old receipt')
   fail=kind;f.checkpoint='retry-'..kind;before=writes
   check(not D.writeMobileRecoveryMarker(f),'failure expected')
   check(D.writeMobileRecoveryMarker(f)and writes==before+2,'failed same state not retried')
  end
  local before=writes;check(D.clearMobileRecoveryMarker(),'clear');check(not store[D.MOBILE_RECOVERY_MARKER],'clear bytes')
  check(D.writeMobileRecoveryMarker(f)and writes==before+1,'same state after clear not restored')
  store[D.MOBILE_RECOVERY_MARKER]=nil;before=writes
  check(D.readMobileRecoveryMarker()==nil,'external missing read');check(D.writeMobileRecoveryMarker(f)and writes==before+1,'read did not invalidate')
  fs.write=function(...)return write(...)end;before=writes
  check(D.writeMobileRecoveryMarker(f)and writes==before+1,'writer replacement stale')
  love.filesystem={write=write,read=fs.read,remove=fs.remove};before=writes
  check(D.writeMobileRecoveryMarker(f)and writes==before+1,'backend replacement stale')
  check(D.readMobileRecoveryMarker().checkpoint==f.checkpoint,'serialized receipt parse')
 end
end
do
 local originalRequire=require
 local current={save={}}
 _G.require=function(name)if name=='src.core.Game'then return current end;return originalRequire(name)end
 local owner='save1';local count=0;local store={};local badContext=false
 local storage={
  context=function()if badContext then return nil,'unavailable'end;return{modId='VASC',root='private',gameVersion='red',playthroughId=owner}end,
  writeBytes=function(_,game,key,bytes)count=count+1;store[owner..':'..key]=bytes;return true end,
  readBytes=function(_,game,key)return store[owner..':'..key]end,
  list=function()return{}end,delete=function()return true end,
 }
 love={system={getOS=function()return'Android'end}}
 local D=assert(loadfile(root..'lib/Diagnostics.lua'))({mod={storage=storage},require=function()error('unused')end})
 local f={kind=D.MOBILE_RECOVERY_KIND,schema='v1',build='rc4',mode='LIVE_TEST',phase='draw',status='PASS',generation=1,checkpoint='scene-ready'}
 check(D.writeMobileRecoveryMarker(f)and count==1,'scoped first receipt')
 check(D.writeMobileRecoveryMarker(f)and count==1,'scoped same receipt')
 owner='save2';check(D.writeMobileRecoveryMarker(f)and count==2,'same facade different playthrough skipped')
 owner='save1';check(D.writeMobileRecoveryMarker(f)and count==3,'returning owner stale')
 badContext=true;check(D.writeMobileRecoveryMarker(f)and count==4,'unknown context suppressed')
 check(D.writeMobileRecoveryMarker(f)and count==5,'unknown context cached')
 badContext=false;check(D.writeMobileRecoveryMarker(f)and count==6,'context restored stale')
 check(D.writeMobileRecoveryMarker(f)and count==6,'restored context duplicate')
 _G.require=originalRequire
end
local C=assert(loadfile(root..'lib/UniformMemo.lua'))().new()
local probes,sends=0,0
local sh={hasUniform=function(_,n)probes=probes+1;return n~='missing'end,send=function(_,n,...)sends=sends+1;return n,... end}
for _=1,10000 do check(not C.optional(sh,'missing',1),'missing send')end
check(probes==1 and sends==0,'missing availability not cached')
local vector={1,2,3};check(C.optional(sh,'present',vector),'supported uniform');vector[1]=9;check(C.optional(sh,'present',vector),'mutated vector');check(sends==2 and probes==2,'values incorrectly memoized')
C.clear();check(C.optional(sh,'present','row',vector),'matrix args');check(probes==2 and sends==3,'clear lost availability or skipped value')
local seen
local other={hasUniform=function()return true end,send=function(_,n,...)seen={...}end}
check(C.optional(other,'missing','row',vector),'new program stale');check(seen[1]=='row'and seen[2]==vector,'matrix layout/identity')
local retry=0;local throwing={hasUniform=function()retry=retry+1;error('temporary')end,send=function()sends=sends+1 end}
check(C.optional(throwing,'x',1)and C.optional(throwing,'x',2)and retry==2,'probe error swallowed/reused')
local noProbe={send=function()sends=sends+1 end};check(C.optional(noProbe,'x',1),'legacy shader')
local bad={hasUniform=function()return true end,send=function()error('bad value')end};check(not C.optional(bad,'x',1),'send error unprotected')
for _,name in ipairs{'lib/Diagnostics.lua','lib/UniformMemo.lua','lib/Voxel3D.lua'}do check(loadfile(root..name),'syntax '..name)end
print('PASS '..checks..' recovery receipt and optional-uniform contracts; Android/iOS/mobile writes, desktop no I/O, changed/failed state retries, clear/read/backend invalidation, supported uniform values/layout preserved')
