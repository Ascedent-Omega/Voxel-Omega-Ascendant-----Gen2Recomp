-- Gen1's engine-owned download pool keeps Windows payloads out of text
-- pipes. This adapter needs no mod-created thread or compute permission.
local M={}
function M.new(mod)
  local ok,Fetch=pcall(require,'src.net.Fetch')
  local okSave,SaveData=pcall(require,'src.core.SaveData')
  if not ok or not okSave or type(Fetch.download)~='function'
      or type(Fetch.poll)~='function' or type(Fetch.release)~='function'
      or type(SaveData.persistenceFs)~='function' then return nil end
  -- Fetch.download writes to the native save directory. Never read or
  -- remove a same-named file in a different portable persistence root.
  if type(SaveData.portableBaseDir)=='function' and SaveData.portableBaseDir() then return nil end
  local fs=SaveData.persistenceFs()
  if not(fs and fs.read and fs.getInfo and fs.remove) then return nil end
  local root='mod_cache/'..assert(mod.id)..'/sprite-fetch-tmp/'
  -- A previous process may have quit while the pool was finishing a
  -- cancelled request. These staging files never contain active content.
  if type(fs.getDirectoryItems)=='function'then
    local listed,names=pcall(fs.getDirectoryItems,root)
    if listed and type(names)=='table'then
      for _,name in ipairs(names)do
        if type(name)=='string'and name:match('^[%w%-]+%.part$')then pcall(fs.remove,root..name)end
      end
    end
  end
  local epoch=tostring(os.time())..'-'..tostring(love.timer.getTime()):gsub('[^%w]','')
  local serial,closed=0,false
  local jobs,workers={},{}
  local self={}
  local function collect()
    local count=0
    for job in pairs(workers)do
      local polled,state=pcall(Fetch.poll,job.id)
      if polled and type(state)=='table' and state.status=='pending' then
        count=count+1
        local info=fs.getInfo(job.path,'file')
        job.receivedBytes=math.min(job.limit,info and info.size or 0)
        if info and info.size>job.limit and job.state.status=='pending' then
          job.state={status='error',err='Response exceeds content limit'}
        end
      else
        if job.state.status=='pending' then
          local info=fs.getInfo(job.path,'file')
          if polled and type(state)=='table' and state.status=='ok'
              and info and info.size>0 and info.size<=job.limit then
            local read,body=pcall(fs.read,job.path)
            job.state=read and type(body)=='string' and #body<=job.limit
              and {status='ok',body=body} or {status='error',err='Unable to read content download'}
          else
            job.state={status='error',err=polled and type(state)=='table' and state.err or 'Content download failed'}
          end
        end
        pcall(fs.remove,job.path);pcall(Fetch.release,job.id);workers[job]=nil
      end
    end
    return count
  end
  function self:available()
    if closed then return false end
    local yes,value=pcall(Fetch.available)
    return yes and value==true
  end
  function self:capabilities()return {}end
  function self:get(url,opts)
    if closed then return nil,'HD transport closed'end
    if collect()>=4 then return nil,'HD downloads busy; retry shortly'end
    opts=type(opts)=='table'and opts or {}
    serial=serial+1
    local job={path=root..epoch..'-'..serial..'.part',state={status='pending'},
      limit=math.min(4194304,math.max(1,tonumber(opts.maxBytes)or 4194304))}
    local started,id=pcall(Fetch.download,url,job.path,{maxSeconds=math.min(30,math.max(1,tonumber(opts.maxSeconds)or 30)),
      userAgent='gen1recomp-mod/'..mod.id})
    if not started or not id then return nil,'Content download could not start'end
    job.id=id;jobs[job]=true;workers[job]=true;return job
  end
  function self:poll(job)
    if not jobs[job]then return {status='error',err='Unknown HD job'}end
    collect()
    return {status=job.state.status,body=job.state.body,err=job.state.err,receivedBytes=job.receivedBytes}
  end
  function self:cancel(job)
    if not jobs[job]then return false end
    job.state={status='cancelled'};return true
  end
  function self:release(job)
    if jobs[job]and job.state.status=='pending'then self:cancel(job)end
    jobs[job]=nil;collect()
  end
  function self:close()
    closed=true
    for job in pairs(jobs)do self:cancel(job);jobs[job]=nil end
    collect()
  end
  return self
end
return M
