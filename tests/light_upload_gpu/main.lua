function love.load()
 local ok,err=xpcall(function()
  local root=assert(os.getenv('QA_VASC_ROOT'))
  local modules={RasterResources={seal=function(x)return x end,changing=function()end},StaticLightField={GLSL='',invalidate=function()end}}
  local V={require=function(n)return assert(modules[n],n)end,mod={read=function(_,p)
   assert(p=='lib/LightVisibility.lua')
   return 'return{prepare=function(_,_,blank)return blank end,invalidate=function()end}'
  end}}
  local grid=assert(loadfile(root..'/lib/LocalLightGrid.lua'))(V)
  local g=love.graphics
  local sh=g.newShader([[uniform float row;uniform float rows;
   vec4 effect(vec4 c,Image image,vec2 uv,vec2 sc){return Texel(image,vec2(.625,(row+.5)/rows));}]])
  local target=g.newCanvas(1,1,{dpiscale=1})
  local pool={};for i=1,3 do pool[i]={x=i*16,y=16,z=16,radius=32,power=.1,normal={0,0,0},color={.1*i,.2*i,.25*i},owner={},kind='torch'}end
  local map={def={width=10,height=10}};local history={}
  for cycle=1,18 do
   pool[1].power=cycle/20
   local frame={map=map,allLights=pool,allBlockers={},lights={},blockers={}}
   local result=assert(grid.prepare(frame,{MAX_LIGHTS=4,MAX_BLOCKERS=4},nil))
   assert(result.data~=history[#history]and result.data~=history[#history-1],'in-flight texture reused')
   history[#history+1]=result.data
   for row=0,2 do
    g.push('all');g.setCanvas(target);g.origin();g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.setShader(sh)
    sh:send('row',row);sh:send('rows',3);g.draw(result.data);g.pop()
    local d=target:newImageData();local r,gg,b,a=d:getPixel(0,0);d:release()
    local l=pool[row+1]
    assert(math.abs(r-l.color[1])<1/255+.0001 and math.abs(gg-l.color[2])<1/255+.0001 and math.abs(b-l.color[3])<1/255+.0001,'GPU read stale colour')
    assert(math.abs(a-l.power*.72/8)<1/255+.0001,'GPU read stale live power')
   end
  end
  grid.invalidate();grid.invalidate()
  target:release();sh:release()
  print('PASS GPU: 54 actual texture readbacks; exact current colours/powers within RGBA8 precision; upload retention and reset')
 end,debug.traceback)
 if not ok then print('FAIL GPU '..tostring(err))end
 love.event.quit(ok and 0 or 1)
end
