local root=assert(arg[1])
local payload='PK\003\004\r\n\026compressed\000bytes'
local files,states,requests={}, {}, {}
local portable=false
files['mod_cache/test/sprite-fetch-tmp/old.part']='old'
files['mod_cache/test/sprite-fetch-tmp/keep.txt']='keep'
local fs={read=function(p)return files[p]end,getInfo=function(p)return files[p]and{size=#files[p]}end,
 getDirectoryItems=function()return {'old.part','keep.txt','../outside.part'}end,
 remove=function(p)files[p]=nil;return true end}
local Fetch={available=function()return true end,download=function(url,path,opts)
 local id=#requests+1;requests[id]={url=url,path=path,opts=opts};states[id]={status='pending'};return id end,
 poll=function(id)return states[id]end,release=function(id)states[id]=nil end}
package.loaded['src.net.Fetch']=Fetch
package.loaded['src.core.SaveData']={persistenceFs=function()return fs end,portableBaseDir=function()return portable and '/portable'or nil end}
love={timer={getTime=function()return 1.2345 end},system={getOS=function()return 'Windows'end}}
setmetatable(love,{__index=function(_,key)if key=='thread'then error('compute permission absent')end end})
local function read(rel)local f=assert(io.open(root..'/'..rel,'rb'));local s=f:read('*a');f:close();return s end
local mod={id='test',read=function(_,rel)return read(rel)end,fetch={available=function()return true end,
 get=function()error('Windows binary payload must not use native text GET')end}}
local Factory=assert(loadfile(root..'/lib/HdBinaryFetch.lua'))()
local f=Factory.new(mod);assert(f:available())
assert(not files['mod_cache/test/sprite-fetch-tmp/old.part']and files['mod_cache/test/sprite-fetch-tmp/keep.txt']=='keep','only owned abandoned staging files may be removed')
local job=assert(f:get('https://example.com/binary',{maxSeconds=90,maxBytes=100}))
assert(requests[1].opts.maxSeconds==30 and requests[1].path:match('^mod_cache/test/'))
assert(f:poll(job).status=='pending')
files[requests[1].path]=payload;states[1]={status='ok'}
assert(f:poll(job).body==payload,'CRLF, Ctrl-Z and NUL must survive file staging')
assert(not files[requests[1].path]and not states[1],'finished staging cleaned')
f:release(job);assert(f:poll(job).status=='error')
local oversize=assert(f:get('https://example.com/binary',{maxBytes=2}));local id=#requests
files[requests[id].path]=payload;states[id]={status='ok'}
assert(f:poll(oversize).status=='error'and not files[requests[id].path])
local cancelled=assert(f:get('https://example.com/binary'));id=#requests
assert(f:cancel(cancelled));files[requests[id].path]=payload;states[id]={status='ok'}
assert(f:poll(cancelled).status=='cancelled'and not files[requests[id].path])
local held={}
for i=1,4 do held[i]=assert(f:get('https://example.com/binary'));f:cancel(held[i]);f:release(held[i])end
assert(not f:get('https://example.com/binary'),'cancelled running jobs still consume the four-job limit')
for i=#requests-3,#requests do files[requests[i].path]=payload;states[i]={status='ok'}end
assert(f:get('https://example.com/binary'),'finished cancelled workers are reclaimed')
f:close();assert(not f:available()and not f:get('https://example.com/binary'))
portable=true
local offline=Factory.new(mod);assert(not offline:available(),'portable native-root mismatch must remain unavailable')
print('PASS Windows binary downloads without compute; byte preservation; timeout and size limits; cancelled-worker cap; staging cleanup; portable-root isolation')
