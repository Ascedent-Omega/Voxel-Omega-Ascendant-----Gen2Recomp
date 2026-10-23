-- AUTO device profile: which tier a machine gets when DEVICE is AUTO.
--
-- Three steps, all from real data only:
--   1. gather(): what LÖVE exposes (OS, cores, renderer/vendor/device string,
--      texture limit, desktop size, DPI, Steam Deck receipt) plus a short
--      single-thread Lua micro-benchmark (cpuBenchmark, once per process).
--   2. startTier(): the tier the session STARTS at. It is the lowest of the
--      GPU tier (rule table on the renderer string), the CPU tier (core count
--      and benchmark score), the edition's historical AUTO rule (the cap) and
--      START_CEILING: nothing starts at HIGH/ULTRA without a measurement.
--   3. step(): the measured loop. While DEVICE is AUTO, overworld frames are
--      collected in windows (menus, battles, map changes and mesh building are
--      skipped). A window whose 95th percentile misses the 60 FPS budget moves
--      the tier one step DOWN, as many windows as it takes, floor MINIMUM. Two
--      consecutive quiet windows move it one step UP, never above the lower of
--      the GPU and CPU tiers (phones never above HIGH) and never back onto a tier this session already dropped from.
--      One settle window follows every change. The chosen tier is persisted as
--      the AUTO receipt (DeviceProfileCore) and resumed next launch.
--
-- Every threshold is a named constant below. Player-facing names come from
-- DeviceProfileCore.LABELS; this file only deals in internal keys (potato =
-- the lowest tier, shown as MINIMUM). There are no GPU timings in LÖVE; none
-- are faked: the loop judges CPU frame time, which is also what a vsync-off
-- or UNCAP session exposes.

local V = ...
local M = { REVISION = 2 }

M.ORDER = { "potato", "low", "medium", "high", "ultra" }
local RANK = { potato = 1, low = 2, medium = 3, high = 4, ultra = 5 }
M.RANK = RANK

local function lower(s) return tostring(s or ""):lower() end
local function minTier(a, b)
  if not a then return b end
  if not b then return a end
  return RANK[a] <= RANK[b] and a or b
end
M.minTier = minTier

-- ------------------------------------------------------------------ GPU table
-- Rules are tried in order; the first whose patterns match the lowercase
-- device string wins. `cores` is an optional minimum processor count for the
-- rule (below it the rule falls through to the next one).
M.DESKTOP_RULES = {
  -- Apple silicon
  { tier = "ultra",  cores = 6, match = { "apple m[3-9]" } },
  { tier = "high",   match = { "apple m[12]", "apple m[3-9]" } },
  -- NVIDIA
  { tier = "ultra",  cores = 6, match = { "rtx 3%d%d%d", "rtx 4%d%d%d", "rtx 5%d%d%d", "rtx a%d%d%d%d" } },
  { tier = "high",   match = { "rtx %d%d%d%d", "gtx 16%d%d", "gtx 10%d%d", "gtx 9%d%d", "gtx titan", "titan" } },
  { tier = "medium", match = { "gtx [5-8]%d%d", "geforce mx%d%d%d", "geforce gt %d%d%d", "quadro" } },
  { tier = "low",    match = { "geforce" } },
  -- AMD
  { tier = "ultra",  cores = 6, match = { "rx 6[7-9]%d%d", "rx 7%d%d%d", "rx 9%d%d%d", "rx 6950" } },
  { tier = "high",   match = { "rx 6[4-6]%d%d", "rx 5[5-7]%d%d", "rx 5%d%d%d", "rx 4[7-9]%d", "rx 5[7-9]%d", "rx vega 56", "rx vega 64", "radeon vii", "radeon pro w" } },
  { tier = "medium", match = { "rx 4[5-6]%d", "rx 5[5-6]%d", "radeon 7%d%dm", "radeon 8%d%dm", "radeon 6%d%dm", "vega", "radeon graphics", "radeon%(tm%) graphics", "radeon pro" } },
  { tier = "low",    match = { "radeon r[2-7]", "radeon hd", "radeon" } },
  -- Intel
  -- "Intel(R) Arc(TM) A770 Graphics": allow anything between "arc" and the model.
  { tier = "high",   match = { "arc.-a[5-7]%d%d", "arc.-b%d%d%d", "arc.-pro" } },
  { tier = "medium", match = { "arc.-a3%d%d", "iris xe", "iris plus", "iris", "uhd graphics 7%d%d", "intel%(r%) graphics" } },
  { tier = "low",    match = { "uhd graphics", "hd graphics", "intel" } },
  -- Software / virtual renderers
  { tier = "potato", match = { "llvmpipe", "softpipe", "swiftshader", "microsoft basic render", "vmware", "virtualbox", "mesa offscreen" } },
}

M.MOBILE_RULES = {
  -- Apple
  { tier = "high",   match = { "apple a1[5-9]", "apple a[2-9]%d", "apple m%d" } },
  { tier = "medium", match = { "apple a1[2-4]" } },
  { tier = "low",    match = { "apple a1[01]", "apple a9" } },
  { tier = "potato", match = { "apple a[1-8]%f[%D]" } },
  -- Qualcomm Adreno
  { tier = "high",   match = { "adreno %(tm%) [78]%d%d", "adreno [78]%d%d" } },
  { tier = "medium", match = { "adreno %(tm%) 6[5-9]%d", "adreno 6[5-9]%d" } },
  { tier = "low",    match = { "adreno %(tm%) 6%d%d", "adreno 6%d%d" } },
  { tier = "potato", match = { "adreno" } },
  -- ARM Mali / Immortalis / Samsung Xclipse
  { tier = "high",   match = { "immortalis", "mali%-g7%d%d", "mali%-g8%d%d", "mali%-g9%d%d", "xclipse" } },
  { tier = "medium", match = { "mali%-g6%d%d", "mali%-g7[78]%f[%D]" } },
  { tier = "low",    match = { "mali%-g7[0-6]%f[%D]", "mali%-g68", "mali%-g57", "mali%-g5[0-9]%d" } },
  { tier = "potato", match = { "mali" } },
  -- Imagination PowerVR
  { tier = "medium", match = { "img b", "img c", "powervr b" } },
  { tier = "potato", match = { "ge8%d%d%d", "ge9%d%d%d", "gm9%d%d%d", "sgx" } },  -- entry-level Rogue (GE8320 etc.)
  { tier = "low",    match = { "powervr gt7", "powervr gx6", "powervr rogue" } },
  { tier = "potato", match = { "powervr" } },
  -- Software / emulators
  { tier = "potato", match = { "swiftshader", "llvmpipe", "android emulator", "virtual" } },
}

-- Below these the table result is capped, whatever the GPU name says.
M.DESKTOP_MIN_CORES_FOR_HIGH = 4
M.SMALL_TEXTURE_LIMIT = 4096

local function firstRule(rules, device, cores)
  for _, rule in ipairs(rules) do
    if not rule.cores or (cores or 0) >= rule.cores then
      for _, pattern in ipairs(rule.match) do
        if device:find(pattern) then return rule.tier, pattern end
      end
    end
  end
  return nil
end

local function isMobileOS(osName)
  local o = lower(osName)
  return o == "android" or o == "ios"
end
M.isMobileOS = isMobileOS

-- --------------------------------------------------------------- CPU benchmark
-- The kind of work the renderer's draw-submission loop does every frame:
-- table reads/writes, small arithmetic, a few string keys. Each run works in
-- chunks until it has done BENCH_UNITS_MAX units or BENCH_RUN_CAP_MS of wall
-- time has passed, whichever comes first, so a slow phone spends at most
-- BENCH_RUNS x BENCH_RUN_CAP_MS (about 45 ms) and still gets a score (work
-- done per millisecond). The best of the runs counts: the maximum rejects a
-- run that was interrupted by loading or the OS. Cached per process.
M.BENCH_UNITS_MAX = 2000000 -- inner iterations per run, upper bound
M.BENCH_CHUNK = 20000       -- iterations between clock checks
M.BENCH_RUN_CAP_MS = 15     -- wall-time cap per run
M.BENCH_RUNS = 3
-- Score thresholds (units/ms). Reference: a 2020-class 16-thread desktop
-- under LÖVE 11.5 (LuaJIT) measures about 45000-50000 units/ms; the
-- thresholds are fractions of that reference (roughly 2/3, 1/3, 1/8, 1/25),
-- not tuned to any one machine. Phones with the JIT are several times
-- slower; iOS (interpreter only) is slower again. The measured loop is the
-- real arbiter; these only pick where it starts.
M.CPU_SCORE_ULTRA = 30000
M.CPU_SCORE_HIGH = 15000
M.CPU_SCORE_MEDIUM = 6000
M.CPU_SCORE_LOW = 2000
-- Core-count tiers (hardware threads as LÖVE reports them; 0 = unknown).
M.CORES_ULTRA = 8
M.CORES_HIGH = 6
M.CORES_MEDIUM = 4
M.CORES_LOW = 2

local function clock()
  local t = rawget(_G, "love")
  t = t and t.timer
  if t and type(t.getTime) == "function" then return t.getTime() end
  return os.clock()
end

local BENCH_KEYS = { "x", "y", "z", "lod", "tier", "dist", "ox", "oy" }
local function benchChunk(rows, from, count)
  local sum = 0
  for i = from, from + count - 1 do
    local r = rows[(i % 64) + 1]
    local k = BENCH_KEYS[(i % 8) + 1]
    r.z = (r.x * 3 + r.y) % 977
    r.dist = math.sqrt(r.x * r.x + r.y * r.y + r.z)
    if r.dist > 50 then r.lod = 2 else r.lod = 1 end
    local v = r[k]
    if type(v) == "number" then sum = sum + v * 0.5 else sum = sum + #v end
    r.ox, r.oy = r.oy, (r.ox + 1) % 13
  end
  return sum
end

-- One capped run: returns units done, milliseconds spent.
local function benchRun()
  local rows = {}
  for i = 1, 64 do rows[i] = { x = i, y = i * 2, z = 0, lod = 1, tier = "present", dist = i * 7, ox = 0, oy = 0 } end
  local t0, units, ms = clock(), 0, 0
  repeat
    benchChunk(rows, units, M.BENCH_CHUNK)
    units = units + M.BENCH_CHUNK
    ms = (clock() - t0) * 1000
  until units >= M.BENCH_UNITS_MAX or ms >= M.BENCH_RUN_CAP_MS
  return units, ms
end

local benchCache = nil
function M.cpuBenchmark(force)
  if benchCache and not force then return benchCache.score, benchCache.ms, benchCache.units end
  local best, bestMs, bestUnits = 0, 0, 0
  for _ = 1, M.BENCH_RUNS do
    local units, ms = benchRun()
    local score = ms > 0 and (units / ms) or 0
    if score > best then best, bestMs, bestUnits = score, ms, units end
  end
  benchCache = { score = math.floor(best + 0.5), ms = bestMs, units = bestUnits }
  return benchCache.score, benchCache.ms, benchCache.units
end

function M.cpuTierFromScore(score)
  score = tonumber(score)
  if not score or score <= 0 then return nil, "no benchmark" end
  if score >= M.CPU_SCORE_ULTRA then return "ultra", "cpu score " .. score end
  if score >= M.CPU_SCORE_HIGH then return "high", "cpu score " .. score end
  if score >= M.CPU_SCORE_MEDIUM then return "medium", "cpu score " .. score end
  if score >= M.CPU_SCORE_LOW then return "low", "cpu score " .. score end
  return "potato", "cpu score " .. score
end

function M.cpuTierFromCores(cores)
  cores = tonumber(cores) or 0
  if cores <= 0 then return nil, "cores unknown" end
  if cores >= M.CORES_ULTRA then return "ultra", cores .. " cores" end
  if cores >= M.CORES_HIGH then return "high", cores .. " cores" end
  if cores >= M.CORES_MEDIUM then return "medium", cores .. " cores" end
  if cores > M.CORES_LOW then return "low", cores .. " cores" end
  return "low", cores .. " cores"
end

-- CPU tier = the lower of the core-count tier and the benchmark tier.
-- Unknown parts are ignored; both unknown -> nil (no CPU opinion).
function M.cpuTier(info)
  local byCores, whyCores = M.cpuTierFromCores(info and info.cores)
  local byScore, whyScore = M.cpuTierFromScore(info and info.cpuScore)
  local tier = minTier(byCores, byScore)
  if not tier then return nil, "cpu unknown" end
  local why = {}
  if byCores then why[#why + 1] = whyCores end
  if byScore then why[#why + 1] = whyScore end
  return tier, table.concat(why, ", ")
end

-- ----------------------------------------------------------------- gathering
-- Collect what the running engine exposes. Every field is optional; the
-- classifier tolerates "unknown" everywhere. love.system may be blocked by
-- the host sandbox: every probe is pcall-wrapped.
function M.gather(api, hardware, opts)
  api = api or rawget(_G, "love")
  local info = { os = "unknown", arch = (jit and jit.arch) or "unknown", cores = 0,
    renderer = "unknown", vendor = "unknown", device = "unknown",
    textureSize = nil, width = 0, height = 0, dpi = 1, steamDeck = false, cpuScore = nil }
  if api and api.system then
    local ok, v = pcall(api.system.getOS); if ok and v then info.os = v end
    ok, v = pcall(api.system.getProcessorCount); if ok and tonumber(v) then info.cores = tonumber(v) end
  end
  if info.os == "unknown" then
    local ok, CP = pcall(V.require, "CanvasPresentation")
    if ok and type(CP) == "table" and type(CP.OS) == "string" then info.os = CP.OS end
  end
  if api and api.graphics then
    if api.graphics.getRendererInfo then
      local ok, r, _, vendor, device = pcall(api.graphics.getRendererInfo)
      if ok then info.renderer, info.vendor, info.device = r or info.renderer, vendor or info.vendor, device or info.device end
    end
    if api.graphics.getSystemLimits then
      local ok, limits = pcall(api.graphics.getSystemLimits)
      if ok and type(limits) == "table" then info.textureSize = tonumber(limits.texturesize) end
    end
  end
  if api and api.window then
    if api.window.getDesktopDimensions then
      local ok, w, h = pcall(api.window.getDesktopDimensions)
      if ok and tonumber(w) then info.width, info.height = tonumber(w), tonumber(h) or 0 end
    end
    if api.window.getDPIScale then
      local ok, d = pcall(api.window.getDPIScale); if ok and tonumber(d) then info.dpi = tonumber(d) end
    end
  end
  hardware = hardware or (V and V.mod and V.mod._vascDeviceHardware) or nil
  if type(hardware) == "table" and hardware.steamDeck then info.steamDeck = true end
  info.mobile = isMobileOS(info.os)
  if not (opts and opts.skipBenchmark) then
    local ok, score = pcall(M.cpuBenchmark)
    if ok then info.cpuScore = score end
  end
  return info
end

-- GPU table step. Returns tier, reason (short text for logs/docs).
function M.classify(info)
  info = info or {}
  local device = lower(info.device) .. " " .. lower(info.renderer) .. " " .. lower(info.vendor)
  local cores = tonumber(info.cores) or 0
  local tex = tonumber(info.textureSize)
  if info.steamDeck then return "medium", "steam-deck" end
  if info.mobile or isMobileOS(info.os) then
    if tex and tex <= M.SMALL_TEXTURE_LIMIT then return "potato", "mobile texture limit " .. tex end
    if cores > 0 and cores <= 4 then return "potato", "mobile " .. cores .. " cores" end
    local tier, pattern = firstRule(M.MOBILE_RULES, device, cores)
    if tier then return tier, "mobile gpu rule '" .. pattern .. "'" end
    return "low", "mobile unknown gpu"
  end
  -- desktop (Windows, Linux, macOS, other)
  local arch = lower(info.arch)
  if (arch == "arm" or arch == "arm64") and not device:find("apple") then
    return "low", "arm handheld / sbc"
  end
  if tex and tex <= M.SMALL_TEXTURE_LIMIT then return "low", "desktop texture limit " .. tex end
  local tier, pattern = firstRule(M.DESKTOP_RULES, device, cores)
  if tier then
    if (tier == "high" or tier == "ultra") and cores > 0 and cores < M.DESKTOP_MIN_CORES_FOR_HIGH then
      return "medium", "gpu rule '" .. pattern .. "' capped by " .. cores .. " cores"
    end
    return tier, "desktop gpu rule '" .. pattern .. "'"
  end
  if cores > 0 and cores <= 2 then return "medium", "desktop unknown gpu, " .. cores .. " cores" end
  return "high", "desktop unknown gpu"
end
M.gpuTier = M.classify

-- Unknown GPU AND unknown CPU: start here and let the loop decide.
M.UNKNOWN_START = "medium"
-- Phones never start or climb above this.
M.MOBILE_CEILING = "high"
-- No device starts above this: HIGH and ULTRA are only reached by the
-- measured loop after quiet windows.
M.START_CEILING = "medium"

-- The starting tier. `cap` is the edition's historical AUTO answer (or nil).
-- Returns tier, reason, parts { gpu=, cpu=, cap= }.
function M.startTier(info, cap)
  info = info or {}
  local gpu, gpuWhy = M.classify(info)
  local cpu, cpuWhy = M.cpuTier(info)
  local mobile = info.mobile or isMobileOS(info.os)
  local gpuKnown = gpuWhy and not gpuWhy:find("unknown gpu", 1, true)
  local tier
  if not gpuKnown and not cpu then
    tier = M.UNKNOWN_START
  else
    -- An unknown GPU still has a table answer (HIGH on a desktop, LOW on a
    -- phone); the CPU side can only pull the start further down.
    tier = minTier(gpu, cpu)
  end
  if cap and RANK[cap] then tier = minTier(tier, cap) end
  tier = minTier(tier, M.START_CEILING)
  if mobile then tier = minTier(tier, M.MOBILE_CEILING) end
  if info.steamDeck then tier = minTier(tier, "medium") end
  local parts = { gpu = gpu, gpuReason = gpuWhy, cpu = cpu, cpuReason = cpuWhy, cap = cap }
  local reason = string.format("gpu %s (%s); cpu %s (%s); cap %s -> start %s",
    tostring(gpu), tostring(gpuWhy), tostring(cpu or "unknown"), tostring(cpuWhy or ""),
    tostring(cap or "none"), tier)
  return tier, reason, parts
end

-- The highest tier the loop may climb to on this device: the lower of the
-- GPU and CPU tiers (an unknown CPU side does not limit), phones never above
-- MOBILE_CEILING.
function M.ceiling(info)
  local tier = minTier(M.classify(info), (M.cpuTier(info)))
  if info and (info.mobile or isMobileOS(info.os)) then tier = minTier(tier, M.MOBILE_CEILING) end
  return tier
end

-- ------------------------------------------------------------ measured loop
-- Frame budget for 60 FPS is 16.7 ms. A window whose 95th percentile is above
-- DOWN_P95_MS is not holding 60; a window whose p95 and median are below the
-- UP thresholds has clear headroom for one more tier.
M.DOWN_P95_MS = 18.0
M.UP_P95_MS = 13.0
M.UP_P50_MS = 10.0
M.UP_WINDOWS = 2             -- consecutive quiet windows before a step up
M.SETTLE_WINDOWS = 1         -- windows ignored after any change
M.WINDOW_SECONDS = 8         -- overworld seconds per window
M.MIN_WINDOW_FRAMES = 120
M.WARMUP_SECONDS = 10        -- once per session, after the first overworld frame
M.MAP_ENTER_SKIP_SECONDS = 3 -- after every map change
-- Last resort: MINIMUM (already 50% render scale, no shadows/water/AA) still
-- misses 60. Instead of oscillating, the loop settles on a steady 30 FPS
-- target: it stays at MINIMUM, never climbs again this session, and only
-- reports whether 30 is held.
M.FALLBACK_FPS_TARGET = 30
M.DOWN_P95_30FPS_MS = 36.0

-- View budget ladder (Gen 2, Gen2SpatialResidency.setBudget). Within a tier
-- a bad window first trims the budget one rung (maps drawn, then the
-- full-detail radius, then the camera reach); the tier only drops once the
-- last rung is reached. Quiet windows restore one rung at a time before any
-- step up. `drawn` is a fraction of the tier's own drawn-map count.
M.BUDGET_LADDER = {
  { drawn = 0.75 },
  { drawn = 0.5 },
  { drawn = 0.5, detail = 0.75 },
  { drawn = 0.5, detail = 0.5 },
  { drawn = 0.5, detail = 0.5, range = 0.75 },
  { drawn = 0.5, detail = 0.5, range = 0.5 },
}

-- The budget table for a ladder level (nil at level 0). `baseDrawn` is the
-- tier's drawn-map count from the residency profile.
function M.budgetFor(level, baseDrawn)
  local rung = M.BUDGET_LADDER[tonumber(level) or 0]
  if not rung then return nil end
  local b = { range = rung.range, detail = rung.detail, source = "auto:" .. level }
  if rung.drawn and tonumber(baseDrawn) then
    b.drawn = math.max(2, math.floor(baseDrawn * rung.drawn + 0.5))
  end
  return b
end

-- opts.budget = true when a view budget can be applied (Gen 2 residency
-- present and no ADVANCED view overrides).
function M.newLoop(ceiling, opts)
  return { ceiling = ceiling or "ultra", dropped = {}, upStreak = 0, settle = 0, changes = 0, fpsTarget = 60,
    budget = opts and opts.budget == true or false, budgetLevel = 0 }
end

-- One window decision. sample = { p50, p95, n }. Returns tier, reason.
-- `loop` carries the session state (dropped tiers, up streak, settle).
function M.step(tier, sample, info, loop)
  loop = loop or M.newLoop()
  local rank = RANK[tier]
  if not rank then return tier, "unknown tier" end
  if type(sample) ~= "table" or (tonumber(sample.n) or 0) < M.MIN_WINDOW_FRAMES then return tier, "not enough frames" end
  local p50, p95 = tonumber(sample.p50), tonumber(sample.p95)
  if not (p50 and p95) then return tier, "no percentiles" end
  if loop.settle > 0 then
    loop.settle = loop.settle - 1
    return tier, string.format("p50 %.1f / p95 %.1f ms: settling", p50, p95)
  end
  local mobile = info and (info.mobile or isMobileOS(info.os))
  if loop.fpsTarget == M.FALLBACK_FPS_TARGET then
    -- Steady 30 FPS mode: MINIMUM, no climbing, no oscillation.
    if p95 > M.DOWN_P95_30FPS_MS then
      return tier, string.format("p95 %.1f ms > %.1f: below the 30 FPS target at MINIMUM", p95, M.DOWN_P95_30FPS_MS)
    end
    return tier, string.format("p50 %.1f / p95 %.1f ms: holding the 30 FPS target", p50, p95)
  end
  if p95 > M.DOWN_P95_MS then
    loop.upStreak = 0
    if loop.budget and (loop.budgetLevel or 0) < #M.BUDGET_LADDER then
      loop.budgetLevel = (loop.budgetLevel or 0) + 1
      loop.settle = M.SETTLE_WINDOWS
      loop.changes = loop.changes + 1
      return tier, string.format("p95 %.1f ms > %.1f: view budget trimmed to %d/%d", p95, M.DOWN_P95_MS, loop.budgetLevel, #M.BUDGET_LADDER)
    end
    if rank <= 1 then
      loop.fpsTarget = M.FALLBACK_FPS_TARGET
      loop.settle = M.SETTLE_WINDOWS
      loop.changes = loop.changes + 1
      return tier, string.format("p95 %.1f ms at MINIMUM: switching to a steady %d FPS target", p95, M.FALLBACK_FPS_TARGET)
    end
    loop.dropped[tier] = true
    loop.settle = M.SETTLE_WINDOWS
    loop.changes = loop.changes + 1
    loop.budgetLevel = 0 -- the lower tier starts with its full view
    return M.ORDER[rank - 1], string.format("p95 %.1f ms > %.1f: one step down", p95, M.DOWN_P95_MS)
  end
  if p95 < M.UP_P95_MS and p50 < M.UP_P50_MS then
    loop.upStreak = loop.upStreak + 1
    if loop.budget and (loop.budgetLevel or 0) > 0 then
      if loop.upStreak < M.UP_WINDOWS then
        return tier, string.format("p50 %.1f / p95 %.1f ms: quiet window %d/%d", p50, p95, loop.upStreak, M.UP_WINDOWS)
      end
      loop.upStreak = 0
      loop.budgetLevel = loop.budgetLevel - 1
      loop.settle = M.SETTLE_WINDOWS
      loop.changes = loop.changes + 1
      return tier, string.format("p50 %.1f / p95 %.1f ms for %d windows: view budget restored to %d/%d", p50, p95, M.UP_WINDOWS, loop.budgetLevel, #M.BUDGET_LADDER)
    end
    local target = M.ORDER[rank + 1]
    local ceilingRank = RANK[loop.ceiling] or 5
    if mobile then ceilingRank = math.min(ceilingRank, RANK[M.MOBILE_CEILING]) end
    if not target or rank >= ceilingRank then
      return tier, string.format("p50 %.1f / p95 %.1f ms: quiet, at ceiling %s", p50, p95, tostring(M.ORDER[ceilingRank]))
    end
    if loop.dropped[target] then
      return tier, string.format("p50 %.1f / p95 %.1f ms: quiet, but %s was dropped this session", p50, p95, target)
    end
    if loop.upStreak < M.UP_WINDOWS then
      return tier, string.format("p50 %.1f / p95 %.1f ms: quiet window %d/%d", p50, p95, loop.upStreak, M.UP_WINDOWS)
    end
    loop.upStreak = 0
    loop.settle = M.SETTLE_WINDOWS
    loop.changes = loop.changes + 1
    return target, string.format("p50 %.1f / p95 %.1f ms for %d windows: one step up", p50, p95, M.UP_WINDOWS)
  end
  loop.upStreak = 0
  return tier, string.format("p50 %.1f / p95 %.1f ms: keep", p50, p95)
end

-- Drive a whole simulated session: windows = list of { p50, p95, n } (n
-- defaults to 480). Returns the final tier and the list of tiers after each
-- window. Used by the tests; the runtime below feeds the same step().
function M.simulate(start, windows, info, ceiling, opts)
  local loop = M.newLoop(ceiling or M.ceiling(info), opts)
  local tier, trace = start, {}
  for _, w in ipairs(windows) do
    local s = { p50 = w.p50 or w[1], p95 = w.p95 or w[2], n = w.n or w[3] or 480 }
    tier = M.step(tier, s, info, loop)
    trace[#trace + 1] = loop.budget and (tier .. ":" .. loop.budgetLevel) or tier
  end
  return tier, trace, loop
end

-- ---------------------------------------------------------------- load score
-- How long the current map's BODY mesh takes to become drawable when it is
-- really built (Gen2MapWarmup "gen2-map-warmup" result=ready, frames > 0;
-- cache hits are instant and say nothing). RECORD ONLY: the rolling list of
-- the last LOAD_SAMPLES builds is kept in the AUTO receipt but never picks a
-- tier. Wall-clock build time depends on the tier's own slice sizes, map size
-- and pauses (a lower tier would measure itself as slower again); a build CPU
-- ping measured inside the mesher is meant to replace it.
M.LOAD_SAMPLES = 9
M.LOAD_MIN_SAMPLES = 3

function M.median(list)
  if type(list) ~= "table" or #list == 0 then return nil end
  local copy = {}
  for i, v in ipairs(list) do copy[i] = v end
  table.sort(copy)
  local n = #copy
  if n % 2 == 1 then return copy[(n + 1) / 2] end
  return (copy[n / 2] + copy[n / 2 + 1]) / 2
end

-- Append one build time to a rolling list (kept to LOAD_SAMPLES).
function M.addLoadSample(list, ms)
  list = type(list) == "table" and list or {}
  ms = tonumber(ms)
  if not ms or ms <= 0 then return list end
  list[#list + 1] = math.floor(ms + 0.5)
  while #list > M.LOAD_SAMPLES do table.remove(list, 1) end
  return list
end

-- Median of a list of build times; nil until LOAD_MIN_SAMPLES exist.
function M.loadMedian(list)
  if type(list) ~= "table" or #list < M.LOAD_MIN_SAMPLES then return nil end
  return M.median(list)
end

-- ------------------------------------------------------------------ runtime
local function inWorld(game)
  if not game then return false end
  local top = game.stack and game.stack.top and game.stack:top()
  if game.overworld then return top == game.overworld end           -- Gen 1
  return top == nil and type(game.world) == "table" and game.world.map ~= nil -- Gen 2 (Game2)
end

local function currentMapId(game)
  local w = game and (game.overworld or game.world)
  local map = w and w.map
  return map and (map.id or map.name) or nil
end

local function inBattle(game)
  local ok, OB = pcall(V.require, "OverworldBattle")
  if ok and type(OB) == "table" and type(OB.sceneActive) == "function" then
    local got, active = pcall(OB.sceneActive)
    if got and active then return true end
  end
  if game and game.battle then return true end
  return false
end

-- Mesh building or cache writing in flight: frames are not steady state.
local function pumping()
  local ok, Mesher = pcall(V.require, "ChunkMesher")
  if ok and type(Mesher) == "table" then
    if type(Mesher.liveQueued) == "function" then
      local got, n = pcall(Mesher.liveQueued); if got and (tonumber(n) or 0) > 0 then return true end
    end
  end
  local okC, Cache = pcall(V.require, "Gen2MeshCache")
  if okC and type(Cache) == "table" and type(Cache.queued) == "function" then
    local got, n = pcall(Cache.queued); if got and (tonumber(n) or 0) > 0 then return true end
  end
  local okP, Prebuild = pcall(V.require, "Gen2CachePrebuild")
  if okP and type(Prebuild) == "table" and type(Prebuild.status) == "function" then
    local got, st = pcall(Prebuild.status); if got and type(st) == "table" and st.running then return true end
  end
  return false
end
M.pumping = pumping

local function percentile(values, q)
  table.sort(values)
  return values[math.max(1, math.min(#values, math.ceil(#values * q)))]
end

function M.install(mod, DeviceProfile)
  if M.installed then return true end
  local hooks = mod and mod.hooks
  if not (hooks and type(hooks.wrap) == "function") then return false, "hooks unavailable" end
  local state = { warm = 0, samples = {}, windowTime = 0, mapId = nil, mapTimer = 0, windows = 0, skipped = 0 }
  M.state = state
  local function clearWindow() state.samples = {}; state.windowTime = 0 end
  -- A pending receipt is written only where a short write cannot be seen:
  -- a menu/battle/other screen on top, or a warp fade / map setup.
  local function flushReceipt(game)
    if type(DeviceProfile.flushReceipt) == "function" then
      local okF = pcall(DeviceProfile.flushReceipt, game)
      if okF then state.flushes = (state.flushes or 0) + 1 end
    end
  end
  local ok, err = pcall(function()
    hooks:wrap("render.hud", function(next_, game, viewport)
      local w = game and game.world
      if type(w) == "table" and (w.fade or w.mapSetup) then flushReceipt(game) end
      if type(DeviceProfile.wantsMeasurement) == "function" and DeviceProfile.wantsMeasurement() then
        local dt = love and love.timer and love.timer.getDelta and love.timer.getDelta() or 0
        if not inWorld(game) or inBattle(game) then
          clearWindow()
          flushReceipt(game)
        elseif dt > 0 and dt < 1 then
          local map = currentMapId(game)
          if map ~= state.mapId then state.mapId = map; state.mapTimer = 0; clearWindow() end
          state.mapTimer = state.mapTimer + dt
          state.warm = state.warm + dt
          if state.mapTimer < M.MAP_ENTER_SKIP_SECONDS or state.warm < M.WARMUP_SECONDS then
            -- not steady yet
          elseif pumping() then
            state.skipped = state.skipped + 1
            clearWindow()
          else
            state.samples[#state.samples + 1] = dt * 1000
            state.windowTime = state.windowTime + dt
            if state.windowTime >= M.WINDOW_SECONDS and #state.samples >= M.MIN_WINDOW_FRAMES then
              local copy = {}
              for i, v in ipairs(state.samples) do copy[i] = v end
              local sample = { n = #copy, p50 = percentile(copy, .50), p95 = percentile(copy, .95) }
              clearWindow()
              state.windows = state.windows + 1
              pcall(DeviceProfile.applyMeasured, game, sample)
            end
          end
        end
      else
        clearWindow()
      end
      return next_(game, viewport)
    end, -15170)
  end)
  if not ok then return false, tostring(err) end
  M.installed = true
  return true
end

return M
