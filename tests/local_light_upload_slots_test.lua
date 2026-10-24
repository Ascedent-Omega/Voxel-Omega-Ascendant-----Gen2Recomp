-- CPU contract for live light uploads: exact current data, bounded retention,
-- no overwrite of either of the two most recent images, and clean rebuilds.
local root=assert(arg[1],'mod root required')
local created,barriers={},{}
local function clone(t)
 if type(t)~='table'then return t end
 local c={};for k,v in pairs(t)do c[k]=clone(v)end;return c
end
love={graphics={},image={},timer={getTime=os.clock}}
function love.image.newImageData(w,h)
 local d={w=w,h=h,pixels={}}
 function d:setPixel(x,y,...)self.pixels[y*self.w+x]={...}end
 function d:getString()return 'mock-index-fingerprint-'..self.w..'-'..self.h end
 function d:release()assert(not self.released);self.released=true end
 return d
end
function love.graphics.getSystemLimits()return{texturesize=8192}end
function love.graphics.newImage(data)
 local image={w=data.w,h=data.h,pixels=clone(data.pixels),updates=0}
 function image:setFilter()end;function image:setWrap()end
 function image:replacePixels(d)
  assert(not self.released and barriers[self],'upload missing resource barrier')
  barriers[self]=nil;assert(self.w==d.w and self.h==d.h,'resized upload slot')
  self.pixels=clone(d.pixels);self.updates=self.updates+1
 end
 function image:release()assert(not self.released,'double release');self.released=true end
 created[#created+1]=image;return image
end
local modules={StaticLightField={GLSL='',invalidate=function()end},RasterResources={
 seal=function(x)return x end,changing=function(x)barriers[x]=true end,
}}
local V={require=function(n)return assert(modules[n],n)end,mod={read=function(_,name)
 assert(name=='lib/LightVisibility.lua')
 return 'return {prepare=function(_,_,blank)return blank end,invalidate=function()end}'
end}}
local grid=assert(loadfile(root..'/lib/LocalLightGrid.lua'))(V)
local mobile=arg[2]=='mobile'
local slotCount=mobile and 1 or 3
local policy={MAX_LIGHTS=4,MAX_BLOCKERS=4,mobile=mobile}
local map={def={width=10,height=10}}
local pool={{x=16,y=16,z=16,radius=32,power=1,normal={0,0,0},color={1,.5,.2},owner={},kind='torch'}}
local function frame()return{map=map,allLights=pool,allBlockers={},lights={},blockers={}}end
local history,indices={},nil
for i=1,15 do
 pool[1].power=i/16
 local result=assert(grid.prepare(frame(),policy,nil))
 local image=result.data
 if not mobile then assert(image~=history[#history]and image~=history[#history-1],'in-flight light image overwritten')end
 assert(math.abs(image.pixels[2][4]-pool[1].power*.72/8)<1e-12,'light colour/power is stale')
 if indices then assert(result.indices==indices,'flicker rebuilt geometry indices')end
 indices=result.indices;history[#history+1]=image
 if i>slotCount then assert(image==history[i-slotCount],'upload pool exceeded its platform bound')end
end
local live=0;for _,im in ipairs(created)do if not im.released then live=live+1 end end
assert(live==slotCount+1,'unexpected live upload resource count')
local unchanged=assert(grid.prepare(frame(),policy,nil))
assert(unchanged.data==history[#history],'unchanged light data rotated/uploaded')
local old={};for _,im in ipairs(created)do old[#old+1]=im end
pool[2]={x=160,y=16,z=16,radius=32,power=.7,normal={0,0,0},color={.2,.5,1},owner={},kind='torch'}
local expanded=assert(grid.prepare(frame(),policy,nil))
assert(expanded.data.h==2 and expanded.indices~=indices,'new layout retained old texture dimensions')
for _,im in ipairs(old)do assert(im.released,'layout change leaked an upload resource')end
grid.invalidate();grid.invalidate()
for _,im in ipairs(created)do assert(im.released,'reset leaked an upload resource')end
local fresh=assert(grid.prepare(frame(),policy,nil))
assert(not fresh.data.released and fresh.data.h==2,'reset failed to rebuild current light data')
grid.invalidate()
print('PASS '..(mobile and 'mobile single upload' or 'desktop three uploads')..': live colour/power, bounded retention, stable indices, unchanged data, layout replacement, idempotent reset')
