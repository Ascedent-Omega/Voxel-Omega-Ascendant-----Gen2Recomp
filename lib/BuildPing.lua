-- Build CPU ping (PERF F1, 2026-10-23).
--
-- How fast this device turns Lua mesh work into meshes: CPU milliseconds per
-- 1000 BuildBudget ticks, measured by ChunkMesher.pump around the build
-- coroutine's resumes (so pauses, covers and the tier's slice sizes do not
-- enter it, unlike wall-clock load time). Disk-cache hits never report.
-- Kept as a rolling median of the last SAMPLES builds, separately for BODY,
-- FULL and aux (grass/flowers/figures) builds.
--
-- RECORD ONLY: nothing reads it to choose a tier yet. Builds are kept in
-- memory; P.summary() writes one Diagnostics line ("build-ping",
-- phase=summary) on a covered frame at most every SUMMARY_SECONDS.
local V = ...

local P = { SAMPLES = 15, MIN_TICKS = 2000 }
local KINDS = { body = true, full = true, aux = true }
local lists = { body = {}, full = {}, aux = {} }
local counts = { body = 0, full = 0, aux = 0 }
local ignored = { body = 0, full = 0, aux = 0 }
local last = {}
local pendingBuilds, lastSummaryAt = 0, nil

local function median(list)
  local n = #list
  if n == 0 then return nil end
  local copy = {}
  for i = 1, n do copy[i] = list[i] end
  table.sort(copy)
  if n % 2 == 1 then return copy[(n + 1) / 2] end
  return (copy[n / 2] + copy[n / 2 + 1]) / 2
end
P.median = function(kind) return median(lists[kind] or {}) end

local function diagnostic(event, fields)
  local ok, D = pcall(V.require, "Diagnostics")
  if ok and type(D) == "table" and type(D.write) == "function" then pcall(D.write, event, fields) end
end

-- Per-part rolling lists ("body:analysis", "body:mesh", ...): which part of
-- a build is the steadier device measure is still open.
local partLists = {}
-- ms per 1000 `units` (ticks, or emitted quads) into the rolling list `key`
local function addPart(key, ms, units, minUnits)
  ms, units = tonumber(ms), tonumber(units)
  if not (ms and units and ms > 0 and units >= minUnits) then return end
  local list = partLists[key] or {}
  partLists[key] = list
  list[#list + 1] = ms * 1000 / units
  while #list > P.SAMPLES do table.remove(list, 1) end
end

-- One finished real build. Returns the ms per 1000 ticks, or nil when the
-- build is ignored (unknown kind, bad numbers, fewer than MIN_TICKS ticks).
-- `parts` (optional) = { analysis = { ms, ticks }, mesh = { ms, ticks } }.
function P.add(kind, cpuMs, ticks, uploadMs, mapId, parts)
  cpuMs, ticks = tonumber(cpuMs), tonumber(ticks)
  if not KINDS[kind] then return nil end
  if not (cpuMs and ticks and cpuMs > 0 and cpuMs == cpuMs and ticks >= P.MIN_TICKS) then
    ignored[kind] = ignored[kind] + 1
    return nil
  end
  local per = cpuMs * 1000 / ticks
  local list = lists[kind]
  list[#list + 1] = per
  while #list > P.SAMPLES do table.remove(list, 1) end
  counts[kind] = counts[kind] + 1
  last[kind] = { msPer1k = per, cpuMs = cpuMs, ticks = ticks, uploadMs = tonumber(uploadMs), mapId = mapId,
    parts = type(parts) == "table" and parts or nil }
  if type(parts) == "table" then
    for name, v in pairs(parts) do
      if type(v) == "table" then
        addPart(kind .. ":" .. tostring(name), v.ms, v.ticks, P.MIN_TICKS / 4)
        -- alternative normaliser under test: ms per 1000 emitted quads
        addPart(kind .. ":" .. tostring(name) .. "/quads", v.ms, v.quads, 500)
      end
    end
  end
  pendingBuilds = pendingBuilds + 1
  return per
end

-- One summary line for the builds since the last one. Never per build: a
-- support-log flush is a storage append (tens of ms on some hosts), so the
-- mesher calls this only on covered frames (warp fade, loading cover), at
-- most once per SUMMARY_SECONDS. Returns true when a line was written.
P.SUMMARY_SECONDS = 300
function P.summary(now, force)
  if pendingBuilds == 0 then return false end
  now = tonumber(now) or 0
  if not force and lastSummaryAt and now - lastSummaryAt < P.SUMMARY_SECONDS then return false end
  lastSummaryAt = now
  local out = {}
  for _, kind in ipairs({ "body", "full", "aux" }) do
    local med = median(lists[kind])
    if med then out[#out + 1] = string.format("%s %.3f/%d", kind, med, #lists[kind]) end
  end
  local mesh = partLists["full:mesh"] or partLists["body:mesh"]
  local fields = { phase = "summary", total = pendingBuilds,
    p50Ms = median(lists.full) or median(lists.body),
    detail = "ms/1k ticks median/builds: " .. table.concat(out, ", ")
      .. (mesh and string.format("; mesh %.3f", median(mesh)) or "") }
  pendingBuilds = 0
  print("[VASC] build ping (record only): " .. fields.detail)
  diagnostic("build-ping", fields)
  return true
end

function P.stats()
  local out = {}
  for kind in pairs(KINDS) do
    local l = last[kind]
    out[kind] = { median = median(lists[kind]), samples = #lists[kind], builds = counts[kind],
      ignored = ignored[kind], last = l and l.msPer1k or nil, lastMap = l and l.mapId or nil,
      lastUploadMs = l and l.uploadMs or nil, lastParts = l and l.parts or nil }
  end
  out.parts = {}
  for key, list in pairs(partLists) do out.parts[key] = { median = median(list), samples = #list } end
  return out
end

function P.reset()
  for kind in pairs(KINDS) do lists[kind], counts[kind], ignored[kind], last[kind] = {}, 0, 0, nil end
  partLists = {}
  pendingBuilds, lastSummaryAt = 0, nil
end
function P.pending() return pendingBuilds end

return P
