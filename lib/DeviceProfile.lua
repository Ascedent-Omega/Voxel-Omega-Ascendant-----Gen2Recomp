-- Persistent device profiles for the expensive, non-compositional parts of
-- the renderer. Gen 1 (Kanto) edition of the shared DeviceProfileCore:
-- AUTO is resolved by the shared hardware table (lib/DeviceAutoProfile.lua)
-- plus a one-time measured step; CUSTOM never rewrites child rows.

local V = ...
local Core = V.require("DeviceProfileCore")

return Core.new({
  modIdDefault = "VOXEL_ASCENDANT",
  withUncap = false,
  -- Fallback only (when DeviceAutoProfile is unavailable): the historical
  -- Gen 1 rule. Steam Deck -> MEDIUM; engine tier decides, default HIGH.
  resolveAuto = function(engineTier, hardware)
    if hardware and hardware.steamDeck then return "medium" end
    if engineTier == "low" then return "low" end
    if engineTier == "balanced" then return "medium" end
    return "high"
  end,
})
