local root=assert(arg[1], 'mod root required')
local Fetch=assert(loadfile(root..'/lib/HdBinaryFetch.lua'))()
local Mirror=assert(loadfile(root..'/lib/SpriteMirrorFetch.lua'))()
local reads=0
local mirrors={{enabled=true,provider='test',baseUrl='https://example.com'}}
for _,platform in ipairs({'Android','iOS','OS X','Linux','Windows'})do
  love={system={getOS=function()return platform end}}
  local transport=Fetch.new({read=function()reads=reads+1;error('offline transport must not start workers')end})
  assert(type(transport)=='table',platform..': missing transport must stay loadable')
  assert(not transport:available(),platform..': offline availability')
  assert(not transport:capabilities().boundedHttpsGet)
  local fetch=Mirror.new{transport=transport,mirrors=mirrors,now=function()return 0 end,sha256=function()return ''end}
  local ok,err=fetch:start('/test',1,string.rep('a',64))
  assert(ok==false and err=='transport_unavailable',platform..': download must fail clearly without retries')
  assert(fetch.state=='idle')
  transport:cancel({});transport:release({});transport:close()
end
assert(reads==0)
local native={get=function()end,poll=function()end,cancel=function()end,release=function()end}
for _,platform in ipairs({'Android','iOS','OS X','Linux'})do
  love={system={getOS=function()return platform end}}
  assert(Fetch.new({fetch=native})==native,'native transport must be preserved')
end
love=setmetatable({},{__index=function()error('sandbox blocked love module')end})
assert(Fetch.new({fetch=native})==native,'blocked platform API must preserve native transport')
print('PASS offline Gen2 transport on five platforms; immediate download error; native Gen1 delegation; sandbox platform access')
