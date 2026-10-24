-- Preserve compressed content bytes on Windows without changing the engine's
-- global network provider. Other platforms retain the native mod.fetch path.
local M = {}
function M.new(mod)
  local native = mod.fetch
  -- Gen2Recomped does not expose mod.fetch. Optional downloads must never
  -- prevent the bundled game content from loading, on any platform.
  if native == nil then
    return {
      available=function()return false end,
      capabilities=function()return {} end,
      get=function()return nil,"transport_unavailable" end,
      poll=function()return {status="error",err="transport_unavailable"}end,
      cancel=function()return false end,
      release=function()end,
      close=function()end,
    }
  end
  local okPlatform, platform = pcall(function()return love.system.getOS()end)
  if not okPlatform or platform ~= "Windows" then return native end
  local okThreads,threadApi=pcall(function()return love.thread end)
  if not okThreads or not(threadApi and threadApi.newThread and threadApi.newChannel)then
    local source=assert(mod:read('lib/HdFileFetch.lua'))
    local files=assert((loadstring or load)(source,'@HdFileFetch'))().new(mod)
    if files then return files end
    -- A portable root cannot be mixed with the native pool's staging root.
    return {available=function()return false end,capabilities=function()return {}end,
      get=function()return nil,'transport_unavailable'end,poll=function()return {status='error',err='transport_unavailable'}end,
      cancel=function()return false end,release=function()end,close=function()end}
  end
  local source = assert(mod:read("lib/HdBinaryFetchWorker.lua"))
  local jobs, workers = {}, {}
  local closed = false
  local self = {}
  local function collect()
    local count = 0
    for job in pairs(workers) do
      local response = job.channel:pop()
      while response do
        if job.state.status == "pending" then job.state = response end
        response = job.channel:pop()
      end
      local running = job.thread:isRunning()
      if job.state.status == "pending" then
        if not running then
          job.state = {status="error", err=job.thread:getError() or "HD worker stopped"}
        end
      end
      if running then count = count + 1 else workers[job] = nil end
    end
    return count
  end
  function self:available() return not closed and native:available() end
  -- This worker caps the body after receiving it, so it must not advertise
  -- the engine's stronger bounded-receive capability.
  function self:capabilities() return {} end
  function self:get(url, opts)
    if closed then return nil, "HD transport closed" end
    if collect() >= 4 then return nil, "HD workers busy; retry shortly" end
    opts = type(opts) == "table" and opts or {}
    local channel = threadApi.newChannel()
    local job = {channel=channel, state={status="pending"}}
    local ok, err = pcall(function()
      job.thread = threadApi.newThread(source)
      job.thread:start(url, math.min(30, math.max(1, tonumber(opts.maxSeconds) or 30)), channel, math.min(4194304, tonumber(opts.maxBytes) or 4194304))
    end)
    if not ok then return nil, tostring(err) end
    jobs[job], workers[job] = true, true
    return job
  end
  function self:poll(job)
    if not jobs[job] then return {status="error",err="Unknown HD job"} end
    collect()
    return {status=job.state.status, body=job.state.body, err=job.state.err, receivedBytes=job.state.receivedBytes}
  end
  function self:cancel(job)
    if not jobs[job] then return false end
    job.state = {status="cancelled"}
    return true
  end
  function self:release(job) jobs[job] = nil; collect() end
  function self:close()
    closed = true
    for job in pairs(jobs) do self:cancel(job); jobs[job] = nil end
    collect()
  end
  return self
end
return M
