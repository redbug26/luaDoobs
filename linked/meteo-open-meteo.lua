-- Linked library: 16-day weather forecast (Open-Meteo, public API, no key)
--
-- Setup: New library › Linked library › Lua Script, paste this script.
-- Parameters to declare in the assistant: latitude, longitude (e.g. 50.47 and 4.87 for Namur).
-- Unique identifier: “id” (the date). The library is read-only and refreshes itself.
-- Weather labels follow the app language (translations below).

doobs.trInit("fr", {
  ["Clear sky"] = "Ciel dégagé",
  ["Mainly clear"] = "Peu nuageux",
  ["Partly cloudy"] = "Partiellement nuageux",
  ["Overcast"] = "Couvert",
  ["Fog"] = "Brouillard",
  ["Rime fog"] = "Brouillard givrant",
  ["Light drizzle"] = "Bruine faible",
  ["Drizzle"] = "Bruine",
  ["Dense drizzle"] = "Bruine forte",
  ["Light rain"] = "Pluie faible",
  ["Rain"] = "Pluie",
  ["Heavy rain"] = "Pluie forte",
  ["Light snow"] = "Neige faible",
  ["Snow"] = "Neige",
  ["Heavy snow"] = "Neige forte",
  ["Light showers"] = "Averses faibles",
  ["Showers"] = "Averses",
  ["Violent showers"] = "Averses violentes",
  ["Thunderstorm"] = "Orage",
  ["Missing latitude and longitude parameters."] = "Paramètres latitude et longitude manquants.",
})
local T = doobs.tr
local WEATHER = {   -- main WMO codes
  [0] = T("Clear sky"), [1] = T("Mainly clear"), [2] = T("Partly cloudy"),
  [3] = T("Overcast"), [45] = T("Fog"), [48] = T("Rime fog"),
  [51] = T("Light drizzle"), [53] = T("Drizzle"), [55] = T("Dense drizzle"),
  [61] = T("Light rain"), [63] = T("Rain"), [65] = T("Heavy rain"),
  [71] = T("Light snow"), [73] = T("Snow"), [75] = T("Heavy snow"),
  [80] = T("Light showers"), [81] = T("Showers"), [82] = T("Violent showers"),
  [95] = T("Thunderstorm"),
}

function fetch(ctx)
  local lat, lon = tonumber(ctx.params.latitude), tonumber(ctx.params.longitude)
  if not lat or not lon then error(T("Missing latitude and longitude parameters.")) end
  local data = doobs.http.getJSON("https://api.open-meteo.com/v1/forecast", { query = {
    latitude = lat, longitude = lon, timezone = "auto",
    daily = "temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code",
    forecast_days = ctx.sample and 3 or 16,
  } })
  local d = type(data.daily) == "table" and data.daily or {}
  local records = {}
  for i, day in ipairs(type(d.time) == "table" and d.time or {}) do
    -- Stable English keys (they identify the fields; rename the fields in the assistant).
    records[#records + 1] = {
      id = day,
      Date = day,
      Weather = WEATHER[d.weather_code and d.weather_code[i]] or "—",
      ["Min (°C)"] = d.temperature_2m_min and d.temperature_2m_min[i],
      ["Max (°C)"] = d.temperature_2m_max and d.temperature_2m_max[i],
      ["Rain (mm)"] = d.precipitation_sum and d.precipitation_sum[i],
    }
    if ctx.sample and #records >= ctx.limit then break end
  end
  return records
end
