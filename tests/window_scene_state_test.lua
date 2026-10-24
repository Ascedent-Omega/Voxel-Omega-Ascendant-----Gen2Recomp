-- Run from the repository: luajit tests/window_scene_state_test.lua lib/VoxelScene.lua
local f=assert(io.open(arg[1]or'lib/VoxelScene.lua','rb'));local source=f:read('*a');f:close()
local first=assert(source:find('  local drawingWindowExterior = false',1,true))
local last=assert(source:find('  for _, rim in ipairs(horizon) do',first,true))
local seam=source:sub(first,last-1)
local build=assert(loadstring('return function(Voxel3D,DayNight,state,HorizonWall,roomView)\n'..seam..'\nreturn windowExterior end'))()
local function exercise(sequence,expectedEntries)
 local map,room={},{};local state={room=room,tint='interior',portal=nil};local entries,leaves=0,0
 local G={roomVisibility=function(value,enclosure)state.room=value;state.enclosure=enclosure end,
  drawTint=function(value)state.tint=value or'interior'end,
  silphWindow=function(value,height)
   state.portal=value;state.height=height
   if value then assert(value==map and height==48);entries=entries+1 else leaves=leaves+1 end
  end}
 local set=build(G,{tint=function(outdoor)assert(outdoor);return'exterior'end},{map=map},{interiorProfileFor=function(value)assert(value==map);return{shellHeight=48}end},room)
 for _,outside in ipairs(sequence)do
  set(outside)
  if outside then assert(state.portal==map and state.room==nil and state.tint=='exterior','exterior lost its portal/room/tint')
  else assert(state.portal==nil and state.room==room and state.tint=='interior','interior inherited exterior state')end
 end
 set(false)
 assert(state.portal==nil and state.room==room and state.tint=='interior','following actors/grass inherited exterior state')
 assert(entries==expectedEntries,'redundant setup cycles retained')
 assert(leaves==entries,'unbalanced window-state restoration')
end
exercise({},0)
exercise({false,false},0)
exercise({true,true,true},1)
exercise({true,false,true,true,false,false,true},3)
exercise({false,true,false,true,false},2)
local all={};for i=1,76 do all[i]=true end;exercise(all,1)
assert(source:find("windowExterior(rim.class == 'silph_exterior')",1,true),'real draw loop missing boundary transition')
assert(source:find('  windowExterior(false)\n  Voxel3D.towerBackdrop(false)',1,true),'real draw loop missing final restoration')
print('PASS real window-state helper: original per-draw portal/room/tint contract, alternating groups, empty/interior-only frames and final restoration; 76 exterior meshes need one balanced setup cycle')
