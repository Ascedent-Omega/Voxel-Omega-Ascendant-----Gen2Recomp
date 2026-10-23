-- Voxel Ascendant runtime dispatcher (Gen 1 release for Gen2Recomp).
--
-- Red, Blue and Yellow execute the reviewed VASC 3.0 Gen 1 runtime. This
-- release carries no Gold/Silver/Crystal runtime: on those cartridges, and on
-- any cartridge it cannot identify, the mod stays inactive and says so.

local mod = ...
assert(loadstring(assert(mod:read("lib/HumanDlc.lua"))))().install(mod)
-- Capture failures before the renderer starts; this receipt never changes recovery.
do
  local source=mod:read("lib/ErrorInbox.lua")
  if source then
    local ok,inbox=pcall(function() return assert((loadstring or load)(source,"@ErrorInbox"))().new() end)
    if ok then mod._vascErrorInbox=inbox end
  end
end

-- Cached once; Gen2 inherits this receipt through its mod facade. The engine's
-- AUTO detector is corrected for this hardware; explicit host tiers survive.
do
  local source = assert(mod:read("lib/DeviceHardware.lua"))
  local detector = assert((loadstring or load)(source, "@DeviceHardware"))()
  local hardware = detector.detect(love)
  local ok, performance = pcall(require, "src.core.Performance")
  if ok then hardware.hostAutoProfile = detector.installAutoProfile(performance, hardware) end
  mod._vascDeviceHardware = hardware
  mod.exports = mod.exports or {}
  mod.exports.deviceHardware = hardware
end

-- One engine overlay serves both generations, including its real hit areas.
do
  local ok, controls = pcall(require, "src.core.TouchControls")
  if ok then
    local source = assert(mod:read("lib/MobileTouchLayout.lua"))
    assert((loadstring or load)(source, "@MobileTouchLayout"))().install(controls)
  end
end

-- Both generations share the same bounded in-memory support evidence.
do
  local ok, recorder = pcall(function()
    local source = assert(mod:read("lib/RuntimePerformanceDiagnostics.lua"))
    return assert((loadstring or load)(source, "@RuntimePerformanceDiagnostics"))(mod)
  end)
  if ok then mod._vascRuntimeDiagnostics = recorder end
end

-- RC12 mobile trace bootstrap for the converged M10/M11 segment. It stores
-- renderer checkpoints in RAM until Diagnostics has booted and does not itself
-- install a render hook, query graphics state or write files directly.
local MobileDiagnostic = nil
do
  local okRead, source = pcall(function()
    return mod:read("lib/MobileVoxelDiagnostic.lua")
  end)
  if okRead and type(source) == "string" then
    local chunk = (loadstring or load)(source,
      "@" .. tostring(mod.path or "VOXEL_ASCENDANT")
        .. "/lib/MobileVoxelDiagnostic.lua")
    if chunk then
      local okLoad, value = pcall(chunk, mod)
      if okLoad and type(value) == "table" then
        MobileDiagnostic = value
        mod._vascMobileDiagnostic = value
        pcall(value.checkpoint, "mod-entry-loaded", {
          build="VASC-RC12-M10-M11-CONVERGED-20260903",
          physicalStatus="RC12_REQUIRES_PHYSICAL_SMARTPHONE_PASS",
          sourceZipSha256=
            "66021fb9a6512d3192692b14d3f8af965f8c52d8ed4b20163b1da8228be07618",
        })
      end
    end
  end
end
-- The loader obtains this value from manifest.json. Keep it authoritative for
-- every runtime/renderer export so a release cannot advertise one version to
-- the launcher and a different version to compatibility consumers such as
-- KASC. The fallback exists only for isolated legacy harnesses that construct
-- a minimal mod handle without loader metadata; the release contract asserts
-- that it matches manifest.json.
local PACKAGE_VERSION = type(mod.version) == "string" and mod.version
  or "3.0.2"
mod._vascPackageVersion = PACKAGE_VERSION

local function gameGeneration()
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  local resolve = assert((loadstring or load)(
    assert(mod:read("lib/Gen2RecompedGeneration.lua")),
    "@lib/Gen2RecompedGeneration.lua"))()
  return resolve(mod, ok and GameVersion or nil)
end

local function readOrError(owner, rel)
  local source, readErr = owner:read(rel)
  if not source then
    error(("VOXEL_ASCENDANT: missing %s: %s")
      :format(rel, tostring(readErr or "unavailable")), 0)
  end
  return source
end

local function runEntry(owner, rel)
  local source = readOrError(owner, rel)
  local chunk, compileErr = (loadstring or load)(source,
    "@" .. tostring(mod.path or "VOXEL_ASCENDANT") .. "/" .. rel)
  if not chunk then
    error(("VOXEL_ASCENDANT: %s did not compile: %s")
      :format(rel, tostring(compileErr)), 0)
  end
  return chunk(owner)
end

local AnimationMigration = runEntry(mod, "lib/HumanAnimationMigration.lua")
AnimationMigration.install(mod)

local generation = gameGeneration()
-- Both generation runtimes consume the same support-session owner. Bind the
-- resolved value on the root handle before either entry boots Diagnostics so
-- filenames and the first game-start receipt never fall back to Gx.
mod._vascHostGeneration = generation
-- The crash-loop marker uses generation as one of its closed decision fields.
-- Older RC12 bootstraps left it at "unknown"; supply the already resolved
-- dispatcher value before either generation attaches the recovery owner.
if MobileDiagnostic and type(MobileDiagnostic.setGeneration) == "function" then
  pcall(MobileDiagnostic.setGeneration, generation, {
    caller="main.lua", context="dispatcher", reason="generation-resolved",
  })
end
mod.exports = mod.exports or {}
mod.exports.wardrobeSourceRoot=mod.path..'/integrated/ascendant_pokemon_overworld/assets/characters/'
mod.exports.packageVersion = PACKAGE_VERSION
mod.exports.generation = generation
mod.exports.dispatcher = true
mod._vascTermuxDiagnostics = generation == 2
mod._vascR61AutoProfiler = generation == 2
if generation ~= 1 then
  mod.exports.active = false
  mod.exports.runtime = "inactive"
  mod.exports.rendererInstalled = false
  mod.exports.rendererError = generation == 2
    and "This Voxel Ascendant release is for Red, Blue and Yellow only"
    or "Unable to identify a supported Pokemon generation"
  if mod.log and type(mod.log.warn) == "function" then
    if generation == 2 then
      mod.log:warn("Voxel Ascendant stays inactive: this release is for Red, Blue and Yellow. Gold, Silver and Crystal support will ship as a separate release.")
    else
      mod.log:warn("Voxel Ascendant stays inactive: active game generation is unknown or unsupported")
    end
  end
  return
end

-- Shared entry cover, installed before generation-specific game.ready hooks.
-- The game-scoped owner prevents duplicate intros when KASC is present.
do
  local prefix="integrated/ascendant_startup/"
  local card=runEntry(mod,prefix.."StartupCard.lua").attach(mod,prefix)
  runEntry(mod,prefix.."VascPreload.lua").attach(card,function()return mod.exports end)
  mod.exports.startupCard={apiVersion=1,status=function()return card:status()end}
end

-- One frozen, internal Overworld Card for the Gen 1 runtime.
-- Prepare metadata before option schemas; boot after the generation exports
-- and declared provider dependencies, but before content registration closes.
-- The external host stays closed.
local nativeContentInfo=mod.info
local contentSession = runEntry(mod, "lib/AscendantContentSession.lua").new(mod)
runEntry(mod, "lib/SpriteBundledSession.lua").attach(contentSession,mod,nativeContentInfo,"vasc")
runEntry(mod, "lib/SpriteStartupOffer.lua").attach(contentSession,mod)
mod.hooks:wrap("core.update",function(nextFn,game,dt)
  local result={nextFn(game,dt)}
  contentSession:update(game,dt)
  return (unpack or table.unpack)(result)
end)
-- Authored character catalogue.
runEntry(mod, "lib/EmbeddedCobbleCharacters.lua").install(mod)
local OverworldCard = runEntry(mod, "lib/OverworldPokemonCard.lua")
local overworldCard = OverworldCard.new(mod)
mod._vascOverworldCard = overworldCard
mod.exports.overworldPokemonCard = {
  health=function() return overworldCard:health() end,
}
local function startOverworldCard()
  local ok, err = overworldCard:start()
  if not ok and mod.log then mod.log:warn("Overworld Card: %s", tostring(err)) end
end

if generation == 1 then
  mod.exports.runtime = "gen1"
  local result = runEntry(mod, "main_gen1.lua")
  -- Reassert the package version after the Gen-1 runtime populated exports.
  -- This prevents an optional compatibility provider from mistaking the 3.0
  -- package for a historical 2.x renderer.
  mod.exports.packageVersion = PACKAGE_VERSION
  mod.exports.version = PACKAGE_VERSION
  mod.exports.generation = 1
  mod.exports.runtime = "gen1"
  if type(mod.exports.renderer) == "table" then
    mod.exports.renderer.version = PACKAGE_VERSION
  end
  startOverworldCard()
  return result
end
