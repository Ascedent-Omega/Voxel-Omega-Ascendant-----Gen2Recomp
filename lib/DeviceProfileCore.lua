-- One device-profile model for every VASC edition (Gen 1 Kanto, Gen 2 Johto).
--
-- Tiers, legacy aliases, the fallback chain and the binding lookup live here
-- and nowhere else. lib/DeviceProfile.lua (Gen 1) and gen2/lib/DeviceProfile.lua
-- (Gen 2) only supply what differs per edition: the selectable ladder, how
-- AUTO resolves and the UNCAP advanced value. Binding tables written against
-- the historical names (eco/handheld/max, light/balanced/high) keep working
-- unchanged; new tables may use potato/low/medium/high/ultra.
--
-- Stage 1 (2026-10-22): POTATO exists in the data model but is hidden from the
-- menus (POTATO_VISIBLE) until it has binding values of its own.

local V = ...
local ModSetting = V.require("ModSetting")

local Core = {}

-- Stage 3: the lowest tier has real values now and is selectable.
Core.POTATO_VISIBLE = true

-- Effective tiers, weakest first. CUSTOM and AUTO are selections, not tiers.
-- UNCAP is an edition-specific advanced value above ULTRA (Gen 2 only).
Core.TIERS = { "potato", "low", "medium", "high", "ultra" }
Core.TIER_SET = { potato = true, low = true, medium = true, high = true, ultra = true, uncap = true }

-- Player-facing names. The internal key of the lowest tier stays "potato"
-- for API stability; players only ever see the label below.
Core.LABELS = {
  auto = "AUTO", potato = "MINIMUM", low = "LOW", medium = "MEDIUM",
  high = "HIGH", ultra = "ULTRA", uncap = "UNCAPED", custom = "CUSTOM",
}
-- One plain line per tier: who it is for (menu help, Your Look).
Core.DESCRIPTIONS = {
  auto = "Picks a profile for this device",
  potato = "Very old phones and weak laptop graphics: smooth first, plain look",
  low = "Older phones and basic laptops",
  medium = "Most phones, laptops and Steam Deck",
  high = "Gaming PCs and top phones",
  ultra = "Powerful gaming PCs: everything on",
  uncap = "Beyond ULTRA: unlimited map loading (advanced)",
  custom = "Your own mix (set automatically when you change a detail)",
}

-- Stored/legacy spellings -> canonical value.
Core.ALIAS = {
  light = "low", eco = "low",
  balanced = "medium", handheld = "medium",
  max = "high",
}

-- Keys a binding table may use for each canonical tier (newest first).
Core.BINDING_KEYS = {
  potato = { "potato" },
  low = { "low", "light", "eco" },
  medium = { "medium", "balanced", "handheld" },
  high = { "high", "max" },
  ultra = { "ultra" },
  uncap = { "uncap" },
}

-- When a binding has no value for a tier, the next tier that does decides.
Core.FALLBACK = {
  potato = { "low", "medium", "high" },
  low = { "medium", "high" },
  medium = { "high" },
  high = {},
  ultra = { "high" },
  uncap = { "ultra", "high" },
}

function Core.canonical(value)
  if value == nil then return nil end
  return Core.ALIAS[value] or value
end

function Core.isTier(value)
  return Core.TIER_SET[Core.canonical(value)] == true
end

local function direct(binding, tier)
  for _, key in ipairs(Core.BINDING_KEYS[tier] or { tier }) do
    local value = binding[key]
    if value ~= nil then return value end
  end
  return nil
end

function Core.bindingValue(binding, tier)
  tier = Core.canonical(tier)
  local value = direct(binding, tier)
  if value ~= nil then return value end
  for _, next_ in ipairs(Core.FALLBACK[tier] or {}) do
    value = direct(binding, next_)
    if value ~= nil then return value end
  end
  return nil
end

function Core.values(withUncap)
  local out = { "auto", "potato", "low", "medium", "high", "ultra" }
  if withUncap then out[#out + 1] = "uncap" end
  out[#out + 1] = "custom"
  return out
end

function Core.labels(values)
  local out = {}
  for i, v in ipairs(values) do out[i] = Core.LABELS[v] or string.upper(v) end
  return out
end

-- Menu/manager choice list in {label, value} pairs, honouring POTATO_VISIBLE.
function Core.choices(withUncap)
  local out = {}
  for _, v in ipairs(Core.values(withUncap)) do
    if v ~= "potato" or Core.POTATO_VISIBLE then out[#out + 1] = { Core.LABELS[v], v } end
  end
  return out
end

local function cleanPart(value)
  value = tostring(value or "unknown"):lower()
  return value:gsub("[^%w%._%-]+", "_"):sub(1, 96)
end

-- Same string as both historical copies produced for the same machine, so an
-- existing CUSTOM tuning survives this unification.
function Core.hardwareSignature()
  local ok, Performance = pcall(require, "src.core.Performance")
  if ok and type(Performance) == "table"
      and type(Performance.deviceSignature) == "function" then
    local got, value = pcall(Performance.deviceSignature)
    if got and value ~= nil then return cleanPart(value) end
  end
  local osName, cores, renderer, vendor, device = "unknown", 0,
    "unknown", "unknown", "unknown"
  local okSystem, system = pcall(function()
    local loveApi = rawget(_G, "love")
    return loveApi and loveApi.system or nil
  end)
  if okSystem and system then
    local got, value = pcall(system.getOS)
    if got and value then osName = value end
    got, value = pcall(system.getProcessorCount)
    if got and value then cores = value end
  end
  if osName == "unknown" then
    local okPlatform, Platform = pcall(require, "src.core.Platform")
    if okPlatform and type(Platform) == "table"
        and type(Platform.detect) == "function" then
      local got, info = pcall(Platform.detect)
      if got and type(info) == "table" and info.os then osName = info.os end
    end
  end
  if love and love.graphics and love.graphics.getRendererInfo then
    local got, a, _, c, d = pcall(love.graphics.getRendererInfo)
    if got then renderer, vendor, device = a or renderer, c or vendor, d or device end
  end
  local arch = jit and jit.arch or "unknown"
  return table.concat({ cleanPart(osName), cleanPart(arch), cleanPart(cores),
    cleanPart(renderer), cleanPart(vendor), cleanPart(device) }, ":")
end

-- The engine's coarse hardware tier (low / balanced / high), if available.
function Core.engineTier()
  local ok, Performance = pcall(require, "src.core.Performance")
  if ok and type(Performance) == "table"
     and type(Performance.detect) == "function" then
    local detected, got = pcall(Performance.detect)
    if detected then return got end
  end
  return nil
end

-- The shared AUTO classifier (lib/DeviceAutoProfile.lua). Optional: an
-- edition may still pass config.resolveAuto as the fallback rule.
local function autoProfileModule()
  local ok, module = pcall(V.require, "DeviceAutoProfile")
  if ok and type(module) == "table" and type(module.classify) == "function" then return module end
  return nil
end
Core.autoProfileModule = autoProfileModule

-- Skip a value when the player cycles the simple DEVICE row. UNCAP stays a
-- legal stored value (advanced row writes it) but is not in the simple ladder.
function Core.skipInSimpleCycle(setting, skipped)
  local skip = {}
  for _, v in ipairs(skipped or { "uncap" }) do skip[v] = true end
  setting.cycle = function(self, game, dir)
    dir = dir or 1
    local n = #self.values
    local i = self:read()
    for _ = 1, n do
      i = ((i + dir - 1) % n + n) % n + 1
      if self:allows(i) and not skip[self.values[i]] then break end
    end
    return self:setIndex(i, game)
  end
  return setting
end

-- config = {
--   modIdDefault = "VOXEL_ASCENDANT",
--   withUncap = false,
--   resolveAuto = function(engineTier, hardware) -> canonical tier (fallback only),
-- }
function Core.new(config)
  config = config or {}
  local DeviceProfile = {}
  local values = Core.values(config.withUncap == true)

  DeviceProfile.KEY = "deviceProfile"
  DeviceProfile.HARDWARE_KEY = "_deviceProfileHardwareV1"
  -- PERF AUTO FIX (2026-10-23): receipts are versioned. V1 receipts were
  -- written by the one-shot rule that started every PC at its GPU-table tier;
  -- they are deleted on restore and never trusted.
  DeviceProfile.AUTO_KEY = "_deviceProfileAutoV2"
  DeviceProfile.LEGACY_AUTO_KEYS = { "_deviceProfileAutoV1" }
  DeviceProfile.AUTO_RECEIPT_VERSION = 2
  DeviceProfile.LABEL = "DEVICE"
  DeviceProfile.core = Core
  DeviceProfile.setting = ModSetting.new(
    DeviceProfile.KEY, DeviceProfile.LABEL, values, Core.labels(values), "auto")
  if type(DeviceProfile.setting.aliasLegacy) == "function" then
    for old, live in pairs(Core.ALIAS) do DeviceProfile.setting:aliasLegacy(old, live) end
  end
  DeviceProfile.setting:setGate(function(value)
    if value == "potato" then return Core.POTATO_VISIBLE end
    return true
  end)
  Core.skipInSimpleCycle(DeviceProfile.setting)

  local bindings = {}
  local applying = false
  -- AUTO receipt for this hardware: { version, signature, start, ceiling,
  -- measured, reason, p50, p95, frames, fpsTarget, windows, budgetLevel,
  -- loadMs (rolling map build times, ms) }
  local autoReceipt = nil
  local autoCache = nil     -- { info, gpu, gpuReason, cpu, cpuReason, start, startReason, ceiling }
  local autoLoop = nil      -- DeviceAutoProfile loop state for this process
  local autoAnnounced = false
  local loadSamples = nil   -- rolling build times (receipt's list + this session)

  local function diagnostic(event, fields)
    local ok, D = pcall(V.require, "Diagnostics")
    if ok and type(D) == "table" and type(D.write) == "function" then pcall(D.write, event, fields) end
  end

  -- Gen 2 view budget (Gen2SpatialResidency). Absent on Gen 1.
  local function residency()
    local ok, R = pcall(V.require, "Gen2SpatialResidency")
    if ok and type(R) == "table" and type(R.setBudget) == "function" then return R end
    return nil
  end
  -- ADVANCED view rows set by hand own the view: AUTO never budgets them.
  local function viewOverridden(R)
    if type(R.overrides) ~= "function" then return false end
    local ok, o = pcall(R.overrides)
    return ok and type(o) == "table" and (o.range ~= nil or o.detail ~= nil or o.maps ~= nil) or false
  end
  -- Push the loop's budget rung for `tier`, or clear the budget when DEVICE
  -- is not AUTO, the rung is 0, or the view rows are overridden.
  local function syncBudget(tier)
    local R = residency()
    if not R then return nil end
    local level = autoLoop and autoLoop.budgetLevel or 0
    if DeviceProfile.setting:get() ~= "auto" or level <= 0 or viewOverridden(R) then
      pcall(R.setBudget, nil)
      return nil
    end
    local Auto = autoProfileModule()
    local base = type(R.profile) == "function" and R.profile(tier) or nil
    local b = Auto and Auto.budgetFor(level, base and base.drawn) or nil
    pcall(R.setBudget, b)
    return b
  end
  DeviceProfile.syncBudget = syncBudget

  -- Load score: real BODY builds of the current map (Gen2MapWarmup writes
  -- "gen2-map-warmup" result=ready with milliseconds; frames > 0 = it was
  -- built, not a cache hit). Recorded in the receipt only; never picks a tier.
  local function noteLoad(event, fields)
    if event ~= "gen2-map-warmup" or type(fields) ~= "table" or fields.result ~= "ready" then return end
    if not ((tonumber(fields.frames) or 0) > 0 and tonumber(fields.milliseconds)) then return end
    local Auto = autoProfileModule()
    if not Auto then return end
    loadSamples = Auto.addLoadSample(loadSamples, fields.milliseconds)
    if autoReceipt then autoReceipt.loadMs = loadSamples end
    local med = Auto.loadMedian(loadSamples)
    if med then
      print(string.format("[VASC] AUTO load-score (record only): map build median %.0f ms over %d builds",
        med, #loadSamples))
    end
  end
  DeviceProfile.noteLoad = noteLoad

  local function modId()
    return (V.mod and V.mod.id) or config.modIdDefault or "VOXEL_ASCENDANT"
  end

  local function bucket(game)
    local id = modId()
    local opts = game and game.save and game.save.options
    if opts then
      opts.modOptions = opts.modOptions or {}
      opts.modOptions[id] = opts.modOptions[id] or {}
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[id] = loader.modOptions[id] or {}
      if loader.loader then
        loader.loader.modOptions = loader.loader.modOptions or {}
        loader.loader.modOptions[id] = loader.loader.modOptions[id] or {}
      end
    end
    return opts and opts.modOptions[id], loader and loader.modOptions[id],
           loader and loader.loader and loader.loader.modOptions[id]
  end

  local function rawStore(game, setting, value)
    setting:sync(value)
    local save, loader, nestedLoader = bucket(game)
    if save then save[setting.key] = value end
    if loader then loader[setting.key] = value end
    if nestedLoader then nestedLoader[setting.key] = value end
  end

  -- A measured window updates the AUTO receipt in the option buckets but
  -- does not write: an options write is a storage append (tens of ms on
  -- some hosts), and windows end every few seconds of walking. The next
  -- options write carries the receipt; flushReceipt writes it at a covered
  -- moment (menu, battle, warp fade) when nothing else did.
  local receiptDirty = false

  local function persistOptions(game)
    receiptDirty = false
    if game and type(game.writeOptions) == "function" then
      pcall(game.writeOptions, game)
    elseif game and type(game.persistOptions) == "function" then
      pcall(game.persistOptions, game)
    end
  end

  DeviceProfile.hardwareSignature = Core.hardwareSignature
  DeviceProfile.canonical = Core.canonical

  -- The edition's historical AUTO answer: the cap the start tier never exceeds.
  local function editionCap()
    local hardware = V.mod and V.mod._vascDeviceHardware or {}
    local fallback = config.resolveAuto and config.resolveAuto(Core.engineTier(), hardware) or "high"
    return Core.canonical(fallback) or "high"
  end

  -- Hardware detection for this machine (cached per process): GPU tier from
  -- the renderer table, CPU tier from cores + benchmark, the start tier
  -- (lowest of GPU, CPU and the edition cap) and the ceiling the measured
  -- loop may climb to (the GPU tier; phones never above HIGH).
  local function autoDetect()
    if autoCache then return autoCache end
    local hardware = V.mod and V.mod._vascDeviceHardware or {}
    local Auto = autoProfileModule()
    local cap = editionCap()
    local detected
    if Auto then
      local ok, got = pcall(function()
        local info = Auto.gather(rawget(_G, "love"), hardware)
        local gpu, gpuReason = Auto.classify(info)
        local cpu, cpuReason = Auto.cpuTier(info)
        local start, startReason = Auto.startTier(info, cap)
        return { info = info, gpu = gpu, gpuReason = gpuReason, cpu = cpu, cpuReason = cpuReason,
          start = start, startReason = startReason, ceiling = Auto.ceiling(info), cap = cap }
      end)
      if ok and type(got) == "table" and Core.TIER_SET[got.start] then detected = got end
    end
    if not detected then
      detected = { info = {}, gpu = nil, cpu = nil, start = cap, startReason = "edition fallback rule",
        ceiling = cap, cap = cap }
    end
    autoCache = detected
    return detected
  end

  -- Kept for callers/tests: the GPU-table tier (also the climb ceiling).
  local function autoFromTable()
    local d = autoDetect()
    return d.ceiling, d.gpuReason or d.startReason
  end
  DeviceProfile.autoFromTable = autoFromTable
  -- The tier AUTO starts at on this machine before any measurement.
  local function autoStart()
    local d = autoDetect()
    return d.start, d.startReason
  end
  DeviceProfile.autoStart = autoStart
  DeviceProfile.autoDetect = autoDetect

  local function announce()
    if autoAnnounced then return end
    autoAnnounced = true
    local d = autoDetect()
    local info = d.info or {}
    print(string.format("[VASC] AUTO profile: gpu %s (%s), cpu %s (%s), cap %s -> start %s, ceiling %s",
      tostring(d.gpu), tostring(d.gpuReason), tostring(d.cpu), tostring(d.cpuReason),
      tostring(d.cap), tostring(d.start), tostring(d.ceiling)))
    diagnostic("device-auto-start", { gpu = info.device, renderer = info.renderer, cores = info.cores,
      cpuScore = info.cpuScore, gpuTier = d.gpu, cpuTier = d.cpu, startTier = d.start,
      tier = DeviceProfile.resolve("auto"), os = info.os, reason = d.startReason })
  end

  -- A selection -> the effective tier (never "auto"). AUTO = the measured
  -- receipt for this hardware when one exists, else the start tier.
  function DeviceProfile.resolve(value)
    value = Core.canonical(value)
    if value ~= "auto" then return value end
    if autoReceipt and autoReceipt.signature == DeviceProfile.hardwareSignature()
        and Core.TIER_SET[autoReceipt.measured] then
      return autoReceipt.measured
    end
    return (autoStart())
  end

  -- The measured loop runs for as long as DEVICE is AUTO (every window can
  -- move the tier); it only needs the classifier module to exist.
  function DeviceProfile.wantsMeasurement()
    if DeviceProfile.setting:get() ~= "auto" then return false end
    return autoProfileModule() ~= nil
  end

  function DeviceProfile.autoReceipt() return autoReceipt end

  function DeviceProfile.configure(list)
    bindings = list or {}
    for _, binding in ipairs(bindings) do
      local setting = binding.setting
      local defaultIndex = setting and setting.defaultIndex or 1
      binding.profileDefault = binding.default
      if binding.profileDefault == nil then
        binding.profileDefault = setting and setting.values
          and setting.values[defaultIndex] or nil
      end
      binding.setting:onChange(function(game)
        DeviceProfile.markCustom(game, "setting:" .. tostring(binding.setting.key))
      end)
    end
    DeviceProfile.setting:onChange(function(game, value)
      DeviceProfile.apply(game, value)
    end)
    local Auto = autoProfileModule()
    if Auto and type(Auto.install) == "function" and V.mod then
      pcall(Auto.install, V.mod, DeviceProfile)
    end
    local okD, D = pcall(V.require, "Diagnostics")
    if okD and type(D) == "table" and type(D.observe) == "function" then pcall(D.observe, noteLoad) end
  end

  -- One measured window (called by DeviceAutoProfile's runtime after every
  -- overworld window). Steps the current AUTO tier through Auto.step, records
  -- the receipt for this hardware and re-applies when the tier changed.
  -- Returns ok, tier, reason, changed.
  function DeviceProfile.applyMeasured(game, sample)
    local Auto = autoProfileModule()
    if not Auto then return false end
    local d = autoDetect()
    autoLoop = autoLoop or Auto.newLoop(d.ceiling)
    local R = residency()
    autoLoop.budget = R ~= nil and not viewOverridden(R)
    if not autoLoop.budget then autoLoop.budgetLevel = 0 end
    local current = DeviceProfile.resolve("auto")
    local levelBefore = autoLoop.budgetLevel or 0
    local measured, reason = Auto.step(current, sample, d.info, autoLoop)
    local changed = measured ~= current
    local windows = (autoReceipt and autoReceipt.signature == DeviceProfile.hardwareSignature()
      and tonumber(autoReceipt.windows) or 0) + 1
    autoReceipt = { version = DeviceProfile.AUTO_RECEIPT_VERSION, signature = DeviceProfile.hardwareSignature(),
      start = d.start, ceiling = d.ceiling, measured = measured, reason = reason,
      p50 = sample and sample.p50, p95 = sample and sample.p95, frames = sample and sample.n,
      fpsTarget = autoLoop.fpsTarget, windows = windows, budgetLevel = autoLoop.budgetLevel,
      loadMs = loadSamples }
    local save, loader, nestedLoader = bucket(game)
    for _, store in ipairs({ save, loader, nestedLoader }) do
      if store then store[DeviceProfile.AUTO_KEY] = autoReceipt end
    end
    local budgetMoved = (autoLoop.budgetLevel or 0) ~= levelBefore
    if changed or budgetMoved or (reason or ""):find("FPS target", 1, true) then
      print(string.format("[VASC] AUTO profile measured: %s -> %s (%s)", tostring(current), tostring(measured), tostring(reason)))
      diagnostic("device-auto-step", { previousTier = current, tier = measured, reason = reason,
        p50Ms = sample and sample.p50, p95Ms = sample and sample.p95, frames = sample and sample.n,
        fpsTarget = autoLoop.fpsTarget, windows = windows, budgetLevel = autoLoop.budgetLevel })
    end
    if changed and DeviceProfile.setting:get() == "auto" then
      DeviceProfile.apply(game, "auto") -- also syncs the budget and writes the options
    else
      syncBudget(measured)
      receiptDirty = true -- written at the next covered moment, not mid-walk
    end
    return true, measured, reason, changed
  end

  -- Write a receipt that only measured windows changed. Called by the AUTO
  -- runtime on frames where a short write cannot be seen.
  function DeviceProfile.flushReceipt(game)
    if not receiptDirty then return false end
    persistOptions(game)
    return true
  end
  function DeviceProfile.receiptDirty() return receiptDirty end
  function DeviceProfile.autoLoop() return autoLoop end

  function DeviceProfile.bindings() return bindings end

  -- Every managed row's value for a selection. CUSTOM owns nothing.
  function DeviceProfile.valuesFor(selected)
    local effective = DeviceProfile.resolve(selected or DeviceProfile.setting:get())
    local out = {}
    if effective == "custom" then return out, effective end
    for _, binding in ipairs(bindings) do
      local value = Core.bindingValue(binding, effective)
      if value ~= nil then out[binding.setting.key] = value end
    end
    return out, effective
  end

  function DeviceProfile.managedKeys()
    local out = {}
    for _, binding in ipairs(bindings) do out[#out + 1] = binding.setting.key end
    return out
  end

  function DeviceProfile.apply(game, selected)
    selected = Core.canonical(selected or DeviceProfile.setting:get())
    local effective = DeviceProfile.resolve(selected)
    if effective == "custom" then syncBudget(effective); return true, effective end
    applying = true
    for _, binding in ipairs(bindings) do
      local value = Core.bindingValue(binding, effective)
      if value ~= nil then rawStore(game, binding.setting, value) end
    end
    applying = false
    syncBudget(effective)
    persistOptions(game)
    return true, effective
  end

  function DeviceProfile.markCustom(game, reason)
    if applying or DeviceProfile.setting:get() == "custom" then return false end
    DeviceProfile.lastCustomReason = tostring(reason or "manual")
    print("[VASC] device profile -> CUSTOM (" .. DeviceProfile.lastCustomReason .. ")")
    rawStore(game, DeviceProfile.setting, "custom")
    persistOptions(game)
    return true
  end

  -- CUSTOM is explicit state. During boot the host can already have populated
  -- child rows with AUTO's resolved values, so their presence cannot classify
  -- a fresh install as CUSTOM. CUSTOM is the player's exact tuning on this
  -- machine: preserve it on the same hardware, including legacy installs with
  -- no signature yet; when the save moves to a different device, re-run AUTO.
  function DeviceProfile.restore(game, created)
    local save, loader, nestedLoader = bucket(game)
    local stores = { save, loader, nestedLoader }
    local stored, storedHardware
    for _, store in ipairs(stores) do
      if store and store[DeviceProfile.KEY] ~= nil then
        stored = store[DeviceProfile.KEY]
        break
      end
    end
    for _, store in ipairs(stores) do
      if store and store[DeviceProfile.HARDWARE_KEY] ~= nil then
        storedHardware = store[DeviceProfile.HARDWARE_KEY]
        break
      end
    end
    local hardware = DeviceProfile.hardwareSignature()
    if stored == "custom" and storedHardware ~= nil
        and storedHardware ~= hardware then
      stored = "auto"
    end
    -- AUTO receipt (measured loop) only counts on the same hardware and in
    -- the current receipt version. Older receipts are removed for good.
    autoReceipt = nil
    for _, store in ipairs(stores) do
      if store then
        for _, legacyKey in ipairs(DeviceProfile.LEGACY_AUTO_KEYS) do store[legacyKey] = nil end
      end
      local receipt = store and store[DeviceProfile.AUTO_KEY]
      if not autoReceipt and type(receipt) == "table" and receipt.signature == hardware
          and receipt.version == DeviceProfile.AUTO_RECEIPT_VERSION
          and Core.TIER_SET[receipt.measured] then
        autoReceipt = receipt
      end
    end
    -- Load score from earlier sessions: RECORD ONLY. Wall-clock build time
    -- depends on the tier's own slices, map size and pauses, so it must not
    -- pick a tier; it is kept to compare with a later build CPU ping.
    loadSamples = nil
    if autoReceipt and type(autoReceipt.loadMs) == "table" then
      local Auto = autoProfileModule()
      loadSamples = {}
      for _, v in ipairs(autoReceipt.loadMs) do
        if Auto then loadSamples = Auto.addLoadSample(loadSamples, v) end
      end
      autoReceipt.loadMs = loadSamples
    end
    stored = Core.canonical(stored) or "auto"
    if stored == "auto" then announce() end
    -- Persist AUTO explicitly, in the canonical spelling. Schema-populated
    -- child defaults are not proof of a hand-tuned legacy installation.
    rawStore(game, DeviceProfile.setting, stored)
    for _, store in ipairs(stores) do
      if store then store[DeviceProfile.HARDWARE_KEY] = hardware end
    end
    return DeviceProfile.apply(game, DeviceProfile.setting:get())
  end

  function DeviceProfile.externalChanged(game, key, value)
    if key == DeviceProfile.KEY then
      value = Core.canonical(value)
      DeviceProfile.setting:sync(value)
      return DeviceProfile.apply(game, DeviceProfile.setting:get())
    end
    for _, binding in ipairs(bindings) do
      if key == binding.setting.key then
        binding.setting:sync(value)
        local selected = DeviceProfile.setting:get()
        local expected = Core.bindingValue(binding, DeviceProfile.resolve(selected))
        -- The host can echo preset writes through mod.options_changed after
        -- apply() has returned. Matching echoes are still the active preset,
        -- not a user customization. A genuinely different value is CUSTOM.
        if selected ~= "custom" and value == expected then return true end
        DeviceProfile.markCustom(game, "external:" .. tostring(key)
          .. "=" .. tostring(value) .. "/expected=" .. tostring(expected))
        return true
      end
    end
    return false
  end

  function DeviceProfile.effective()
    return DeviceProfile.resolve(DeviceProfile.setting:get())
  end

  function DeviceProfile.row()
    local row = DeviceProfile.setting:row()
    local base = row.value
    row.value = function()
      local value = base()
      if DeviceProfile.setting:get() == "auto" then
        return value .. "/" .. (Core.LABELS[DeviceProfile.effective()] or string.upper(DeviceProfile.effective()))
      end
      return value
    end
    return row
  end

  -- One short help text for the DEVICE row: a line per tier.
  function DeviceProfile.helpText()
    local lines = {}
    for _, v in ipairs(values) do
      if v ~= "uncap" and (v ~= "potato" or Core.POTATO_VISIBLE) then
        lines[#lines + 1] = Core.LABELS[v] .. ": " .. (Core.DESCRIPTIONS[v] or "")
      end
    end
    return table.concat(lines, ". ") .. ". Changing a detail by hand keeps your values as CUSTOM."
  end

  return DeviceProfile
end

return Core
