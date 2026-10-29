-- luajit tests/panorama_admission_test.lua [repository-root-with-trailing-slash]
local root=(arg and arg[1])or''
local M=assert(loadfile(root..'lib/Gen1InteriorPanoramas.lua'))()
local checked=0
local function check(value,message)assert(value,message);checked=checked+1 end
local function definition(p)
 return{tileset=p.tileset,width=p.width,height=p.height,kaOwner=p.owner,connections={},
  warps={{x=1,y=0},{x=1,y=0},{x=3,y=0},{x=-1,y=0},{x=p.width*2,y=0},{x=2,y=1}}}
end
for id,p in pairs(M.profiles)do
 local map={id=id,def=definition(p)}
 check(M.matches(map),'valid room rejected: '..id)
 local profile=M.profileFor(map)
 check(profile~=nil,'valid doorway profile missing: '..id)
 if #profile.doors>0 then
  local height=profile.doors[1].height
  profile.doors[1].height=-999
  check(M.profileFor(map).doors[1].height==height,'public doorway mutation leaked: '..id)
 end
 for _,key in ipairs{'width','height','tileset','kaOwner','connections'}do
  map.def=definition(p)
  if key=='width'or key=='height'then map.def[key]=map.def[key]+1
  elseif key=='connections'then map.def.connections={north='OTHER'}
  else map.def[key]='unrelated'end
  local expected=key=='kaOwner'and not p.owner
  check(M.matches(map)==not not expected,'changed admission field: '..id..'/'..key)
  check((M.profileFor(map)~=nil)==not not expected,'profile/admission disagree: '..id..'/'..key)
 end
 for _,variant in ipairs{'nil','false','empty'}do
  map.def=definition(p)
  if variant=='nil'then map.def.connections=nil elseif variant=='false'then map.def.connections=false end
  check(M.matches(map),'empty topology rejected: '..id..'/'..variant)
 end
 map.def=definition(p);map.def.warps={{x=2,y=0}}
 local before=M.profileFor(map)
 map.def.warps={{x=4,y=0}}
 local after=M.profileFor(map)
 check(M.matches(map),'live doorway edit changed classification: '..id)
 check(before~=after,'live doorway profile reused: '..id)
end
check(not M.matches(nil),'nil room accepted')
check(not M.matches({}),'missing definition accepted')
check(not M.matches({id='not-a-native-room',def={}}),'unknown room accepted')
print('PASS '..checked..' native room admission and live/public doorway checks')
