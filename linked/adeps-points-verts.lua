-- ADEPS “Points verts” (Belgian walking events)
-- Every event of the public ODWB export, including archives and cancellations.
-- Setup: create an empty database, then New library › Linked library › Lua Script; paste this
-- script. No parameter or secret needed. Choose “id” as the unique identifier and enable refresh
-- in Doobs. Field keys are in French, like the source (date, place, coordinates, organizer,
-- contact, services and GPX); they are stable identifiers, rename the fields in the assistant.
-- Check the types in the assistant: Date = date, Position = location, Téléphone = phone,
-- distances and services = checkboxes, Traces GPX = long text.
-- A .luaDoobs file can also create this library with db:addLinkedLibrary (see the guide, §5.6).

doobs.trInit("fr", {
  ["Cannot read the ADEPS walking events. Try again later. %s"] = "Impossible de lire les points verts ADEPS. Réessayez plus tard. %s",
  ["ADEPS: the JSON export must be a list."] = "ADEPS : l’export JSON doit être une liste.",
  ["ADEPS: unexpected export format; refresh stopped."] = "ADEPS : format d’export inattendu ; actualisation interrompue.",
  ["ADEPS: missing row in the export; refresh stopped."] = "ADEPS : ligne manquante dans l’export ; actualisation interrompue.",
  ["ADEPS: event without identifier or walk code."] = "ADEPS : rendez-vous sans identifiant ou code de point vert.",
  ["ADEPS: duplicate identifier in the export: %s"] = "ADEPS : identifiant en double dans l’export : %s",
})
local T = doobs.tr

local SOURCE = "https://www.odwb.be/api/explore/v2.1/catalog/datasets/points-verts-de-ladeps/exports/json"

local function text(value)
  if type(value) ~= "string" then return nil end
  local clean = value:match("^%s*(.-)%s*$")
  if clean ~= "" then return clean end
end

local function number(value)
  if type(value) ~= "number" and type(value) ~= "string" then return nil end
  local n = tonumber(value)
  if n and n == n and n ~= math.huge and n ~= -math.huge then return n end
end

local function yesno(value)
  if type(value) ~= "string" then return nil end
  value = value:match("^%s*(.-)%s*$"):lower()
  if value == "oui" then return true end
  if value == "non" then return false end
  -- A missing or unknown value stays absent rather than becoming “No”.
end

local function position(row)
  local point = type(row.geopoint) == "table" and row.geopoint or {}
  local lat = number(point.lat) or number(row.latitude)
  local lon = number(point.lon) or number(row.longitude)
  if lat and lon and lat >= -90 and lat <= 90 and lon >= -180 and lon <= 180 then
    return tostring(lat) .. ", " .. tostring(lon), lat, lon
  end
end

local function traces(value)
  local raw = text(value)
  if not raw or raw == "[]" then return nil end
  local ok, items = pcall(doobs.json.decode, raw)
  if not ok or type(items) ~= "table" then return raw end
  local lines = {}
  for _, item in ipairs(items) do
    if type(item) == "table" then
      local url = text(item.fichier)
      if url and url:match("^https://") then
        lines[#lines + 1] = (text(item.titre) or "GPX") .. "\n" .. url
      end
    end
  end
  if #lines > 0 then return table.concat(lines, "\n\n") end
  -- Keep the metadata if the trace format changes.
  if next(items) then return raw end
end

function fetch(ctx)
  local query = { lang = "fr", timezone = "Europe/Brussels" }
  local limit
  if ctx.sample then
    limit = number(ctx.limit)
    limit = limit and limit > 0 and math.max(1, math.floor(limit)) or 20
    -- The export accepts limit: a trial run only downloads a sample, in one request.
    query.limit = limit
  end

  -- One request for the whole export in normal mode: no limit and no date filter.
  local ok, rows = pcall(doobs.http.getJSON, SOURCE, { query = query, timeout = 120 })
  if not ok then
    error(string.format(T("Cannot read the ADEPS walking events. Try again later. %s"), tostring(rows)))
  end
  if type(rows) ~= "table" then error(T("ADEPS: the JSON export must be a list.")) end
  local count = 0
  for key, row in pairs(rows) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or type(row) ~= "table" then
      error(T("ADEPS: unexpected export format; refresh stopped."))
    end
    count = count + 1
  end
  for i = 1, count do
    if type(rows[i]) ~= "table" then
      error(T("ADEPS: missing row in the export; refresh stopped."))
    end
  end

  local records, seen = {}, {}
  for _, row in ipairs(rows) do
    local sourceID = type(row.id) == "string" and text(row.id)
      or (type(row.id) == "number" and tostring(row.id))
    local code = text(row.ndeg_pv)
    if not sourceID or not code then
      error(T("ADEPS: event without identifier or walk code."))
    end
    -- The export reuses some ids for several walks: the code tells them apart.
    -- Neither the date nor the place is part of the key: a correction keeps them linked.
    local id = sourceID .. ":" .. code
    if seen[id] then error(string.format(T("ADEPS: duplicate identifier in the export: %s"), id)) end
    seen[id] = true

    local location, lat, lon = position(row)
    records[#records + 1] = {
      id = id,
      ["Identifiant ADEPS"] = sourceID,
      ["Point vert"] = code,
      ["Date"] = text(row.date),
      ["Activité"] = text(row.activite),
      ["Statut"] = text(row.statut),
      ["Localité"] = text(row.localite),
      ["Commune"] = text(row.entite),
      ["Province"] = text(row.province),
      ["Rendez-vous"] = text(row.lieu_de_rendez_vous),
      ["Informations rendez-vous"] = text(row.infos_rendez_vous),
      ["Position"] = location,
      ["Latitude"] = lat,
      ["Longitude"] = lon,
      ["Carte IGN"] = text(row.ign),
      ["Gare"] = text(row.gare),
      ["Organisateur"] = text(row.groupement),
      ["Nom du contact"] = text(row.nom),
      ["Prénom du contact"] = text(row.prenom),
      ["Téléphone"] = text(row.gsm),
      ["10 km"] = yesno(row["10km"]),
      ["15 km"] = yesno(row["15km"]),
      ["Accessible PMR"] = yesno(row.pmr),
      ["Poussettes"] = yesno(row.poussettes),
      ["Orientation"] = yesno(row.orientation),
      ["Balade guidée"] = yesno(row.balade_guidee),
      ["Vélo"] = yesno(row.velo),
      ["VTT"] = yesno(row.vtt),
      ["Ravitaillement"] = yesno(row.ravitaillement),
      ["Be WaPP"] = yesno(row.bewapp),
      ["Adep Santé"] = yesno(row.adep_sante),
      ["Traces GPX"] = traces(row.traces_gpx),
    }
    if limit and #records >= limit then break end
  end
  -- Any error goes back to Doobs, which then keeps the last valid cache.
  return records
end
