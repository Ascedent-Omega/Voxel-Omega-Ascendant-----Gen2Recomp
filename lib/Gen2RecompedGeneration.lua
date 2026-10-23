-- Gen2Recomped port: resolve once per loader instance; never guess Gen 1.
local cartridges = { red=1, blue=1, yellow=1, gold=2, silver=2, crystal=2 }
return function(mod, GameVersion)
  local host = type(mod.host) == "table" and mod.host or {}
  local id = mod.gameVersion or host.version
  if type(id) == "string" and not cartridges[id:lower()] then return nil end
  local generation = mod.generation
  if generation == nil then generation = host.generation end
  if generation ~= nil then
    if type(generation) ~= "number" then return nil end
    if generation == 1 or generation == 2 then return generation end
    return nil
  end
  if type(GameVersion) ~= "table" then return nil end
  if id == nil and type(GameVersion.get) == "function" then
    local ok, value = pcall(GameVersion.get)
    if ok then id = value end
  end
  if id == nil then id = GameVersion.current end
  if type(id) == "string" then
    id = id:lower()
    if not cartridges[id] then return nil end
    if type(GameVersion.generation) == "function" then
      local ok, value = pcall(GameVersion.generation, id)
      if not ok or value ~= cartridges[id] then return nil end
    end
    return cartridges[id]
  end
  -- Without a cartridge id, the target API's documented no-argument call
  -- is safe; passing the GameVersion table would silently return Gen 1.
  if type(GameVersion.generation) == "function" then
    local ok, value = pcall(GameVersion.generation)
    if ok and (value == 1 or value == 2) then return value end
  end
  return nil
end
