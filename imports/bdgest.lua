-- BDGest: imports your comic book collection (online.bdgest.com).
--
-- 1. On online.bdgest.com: Outils › Sauvegarde et Restauration › Télécharger le fichier.
-- 2. Tap ▶︎ (or run the script) and choose the downloaded CSV file.
--
-- The site is protected against automated access: a script cannot read it directly, hence the
-- exported file. The export contains the albums, followed by the Revues and Para-BD tables: only
-- the albums are imported. An unknown column is imported as is (if it holds at least one value).
--
-- The library created is set up (`library` table of the result): calculated title
-- “Series – T3 – Title”, form in sections, list grouped by series (list View button ›
-- Group by: Publisher, Collection…), “À lire”, “Liste de souhaits”… collections.
-- BDGest is a French service: field names stay in French, like its export; messages follow the
-- app language (translations below).

doobs.trInit("fr", {
  ["Choose the CSV file exported from BDGest (Outils › Sauvegarde et Restauration)."] =
    "Choisissez le fichier CSV exporté depuis BDGest (Outils › Sauvegarde et Restauration).",
  ["The file contains no album."] = "Le fichier ne contient aucun album.",
  ["“Série” and “Titre” columns not found: is this really the BDGest CSV export?"] =
    "Colonnes « Série » et « Titre » introuvables : est-ce bien l’export CSV de BDGest ?",
  ["%d row(s) of the Revues / Para-BD tables ignored."] = "%d ligne(s) des tables Revues / Para-BD ignorée(s).",
  ["%d column(s) imported as is: %s"] = "%d colonne(s) importée(s) telles quelles : %s",
  ["Comics"] = "Bandes dessinées",
})
local T = doobs.tr

-- BDGest export columns (lowercase, without accents or punctuation) -> Doobs field,
-- conversion, and `optional`: field left out if no album has a value.
local COLUMNS = {
  { "Série", "text", { "serie", "series", "nomserie" } },
  { "Tome", "tome", { "num", "tome", "numero", "numalbum" } },
  { "Variante", "text", { "numa", "variante", "suffixe" }, optional = true },
  { "Titre", "text", { "titre", "titrealbum" } },
  { "Scénario", "text", { "scenariste", "scenario", "scenaristes" } },
  { "Dessin", "text", { "dessinateur", "dessin", "dessinateurs" } },
  { "Couleurs", "text", { "coloriste", "couleurs", "couleur" }, optional = true },
  { "Éditeur", "text", { "editeur" } },
  { "Collection", "text", { "collection" }, optional = true },
  { "Dépôt légal", "date", { "dl", "depotlegal", "parution" } },
  { "Achevé d’imprimer", "date", { "ai", "acheveimprimer", "achevedimprimer" }, optional = true },
  { "ISBN", "text", { "isbn", "ean" } },
  { "Format", "code", { "format" }, optional = true },
  { "Édition originale", "bool", { "eo", "editionoriginale" } },
  { "Lu", "bool", { "lu" } },
  { "Date de lecture", "date", { "datelu", "datelecture" }, optional = true },
  { "Dédicace", "bool", { "dedicace" } },
  { "Date de dédicace", "date", { "datededicace" }, optional = true },
  { "État", "code", { "etat" }, optional = true },
  { "Note", "number", { "note" }, optional = true },
  { "Cote", "currency", { "cote" }, optional = true },
  { "Prix d’achat", "currency", { "prixachat", "prixdachat" }, optional = true },
  { "Date d’achat", "date", { "dateachat", "datedachat" }, optional = true },
  { "Liste de souhaits", "bool", { "wishlist", "souhait" } },
  { "Série suivie", "bool", { "suivi" }, optional = true },
  { "À vendre", "bool", { "avendre" }, optional = true },
  { "Emplacement", "text", { "localisation", "emplacement" }, optional = true },
  { "Commentaire", "longtext", { "commentaire", "commentaires", "remarque" }, optional = true },
  { "Identifiant BDGest", "text", { "idalbum", "idbdgest" } },
}
-- Technical columns of the export, never imported.
local SKIP = { table = true }

-- Doobs types of the fields (unknown columns are typed by the assistant).
local TYPES = { tome = "integer", number = "decimal", currency = "currency", date = "date",
                bool = "boolean", longtext = "longtext", code = "integer", text = "text" }

local ACCENTS = { ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
                  ["î"] = "i", ["ï"] = "i", ["ô"] = "o", ["ö"] = "o", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
                  ["ç"] = "c", ["œ"] = "oe", ["°"] = "" }

local function key(s)
  s = (s or ""):lower()
  for from, to in pairs(ACCENTS) do s = s:gsub(from, to) end
  return (s:gsub("[^%w]", ""))
end

local function trim(s) return ((s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function number(s)
  s = trim(s):gsub("%s", ""):gsub("€", ""):gsub(",", ".")
  return tonumber(s:match("^-?[%d%.]+$") or "")
end

local function date(s)
  s = trim(s)
  local d, m, y = s:match("^(%d%d?)/(%d%d?)/(%d%d%d%d)")
  if d then return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d)) end
  m, y = s:match("^(%d%d?)/(%d%d%d%d)$")
  if m then return string.format("%04d-%02d-01", tonumber(y), tonumber(m)) end
  y, m, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)")
  if y then return string.format("%s-%s-%s", y, m, d) end
  y = s:match("^(%d%d%d%d)$")
  if y then return y .. "-01-01" end
  return nil
end

local YES = { oui = true, o = true, x = true, ["1"] = true, yes = true, y = true, vrai = true, ["true"] = true }

-- Converted value; nil = empty.
local function convert(kind, raw)
  raw = trim(raw)
  if raw == "" then return nil end
  if kind == "number" or kind == "currency" then return number(raw) end
  if kind == "date" then return date(raw) end
  if kind == "bool" then return YES[key(raw)] == true end
  if kind == "tome" then return tonumber(raw) end            -- “HS”, “INT”: see Variante
  if kind == "code" then                                     -- BDGest codes: 0 = not set
    local n = tonumber(raw)
    if n == 0 then return nil end
    return n
  end
  return raw
end

local function separator(text)
  local first = text:match("^[^\r\n]*") or ""
  local best, count = ";", -1
  for _, sep in ipairs({ ";", ",", "\t", "|" }) do
    local _, n = first:gsub(sep == "|" and "%|" or sep, "")
    if n > count then best, count = sep, n end
  end
  return best
end

function import(ctx)
  if not ctx.input then
    error(T("Choose the CSV file exported from BDGest (Outils › Sauvegarde et Restauration)."))
  end
  local text = ctx.input.text:gsub("^\239\187\191", "")   -- UTF-8 BOM
  local rows = doobs.csv.parse(text, { separator = separator(text), header = true })
  if #rows == 0 then error(T("The file contains no album.")) end

  -- File columns -> Doobs fields.
  local byAlias = {}
  for _, column in ipairs(COLUMNS) do
    for _, alias in ipairs(column[3]) do byAlias[alias] = column end
  end
  local mapping, unknown, seen, tableColumn = {}, {}, {}, nil
  for header in pairs(rows[1]) do
    local k = key(header)
    local column = byAlias[k]
    if k == "table" then tableColumn = header end
    if SKIP[k] or k == "" then
      -- technical or unnamed column
    elseif column and not seen[column[1]] then
      mapping[header] = column
      seen[column[1]] = true
    else
      unknown[#unknown + 1] = header
    end
  end
  table.sort(unknown)
  if not seen["Série"] and not seen["Titre"] then
    error(T("“Série” and “Titre” columns not found: is this really the BDGest CSV export?"))
  end

  local records, filled, skipped = {}, {}, 0
  for _, row in ipairs(rows) do
    -- The Revues and Para-BD tables (other columns) come after the albums: ignored.
    local kind = tableColumn and trim(row[tableColumn]):upper() or ""
    if kind ~= "" and kind ~= "ALBUM" then
      skipped = skipped + 1
    else
      local r = {}
      for header, column in pairs(mapping) do
        local raw = row[header]
        local v = convert(column[2], raw)
        -- Non-numeric volume (“HS”, “INT”): kept in Variante.
        if column[2] == "tome" and v == nil and trim(raw) ~= "" and not r["Variante"] then r["Variante"] = trim(raw) end
        if v ~= nil then r[column[1]] = v end
      end
      for _, header in ipairs(unknown) do
        local v = trim(row[header])
        if v ~= "" then r[trim(header)] = v end
      end
      for name, v in pairs(r) do
        if v ~= false then filled[name] = true end
      end
      records[#records + 1] = r
    end
  end

  -- Fields in order; optional fields never filled are left out.
  local fields, types = {}, {}
  for _, column in ipairs(COLUMNS) do
    local name = column[1]
    if (seen[name] or (name == "Variante" and filled[name])) and (not column.optional or filled[name]) then
      fields[#fields + 1] = name
      types[name] = TYPES[column[2]]
    end
  end
  local kept = {}
  for _, header in ipairs(unknown) do
    if filled[trim(header)] then
      fields[#fields + 1] = trim(header)
      kept[#kept + 1] = trim(header)
    end
  end
  local keep = {}
  for _, f in ipairs(fields) do keep[f] = true end
  for _, r in ipairs(records) do
    for name in pairs(r) do if not keep[name] then r[name] = nil end end
  end

  -- Record title: “Série – T3a – Titre”, recalculated when the series, volume or title changes.
  local tome = '" – T" & [Tome]'
  local noTome = '""'
  if keep["Variante"] then
    tome = '" – T" & [Tome] & [Variante]'
    noTome = 'IF(ISBLANK([Variante]); ""; " – " & [Variante])'
  end
  local album = '[Série] & IF(ISBLANK([Tome]); ' .. noTome .. '; ' .. tome .. ')'
             .. ' & IF(OR(ISBLANK([Titre]); [Titre] = [Série]); ""; " – " & [Titre])'

  local warnings = {}
  if skipped > 0 then
    warnings[#warnings + 1] = string.format(T("%d row(s) of the Revues / Para-BD tables ignored."), skipped)
  end
  if #kept > 0 then
    warnings[#warnings + 1] = string.format(T("%d column(s) imported as is: %s"), #kept, table.concat(kept, ", "))
  end

  return {
    name = T("Comics"),
    records = records,
    fields = fields,
    types = types,
    warnings = warnings,
    library = {
      icon = "books.vertical",
      color = "orange",
      formulas = {
        { name = "Album", type = "text", hidden = true, formula = album },
        -- List subtitle: “Scénario / Dessin” (a single name when they are the same).
        { name = "Auteurs", type = "text", hidden = true,
          formula = 'IF(OR(ISBLANK([Dessin]); [Dessin] = [Scénario]); [Scénario]; IF(ISBLANK([Scénario]); [Dessin]; [Scénario] & " / " & [Dessin]))' },
      },
      title = "Album",
      subtitle = "Auteurs",
      sort = { "Série", "Tome", "Variante" },
      group = "Série",
      form = {
        columns = 2,
        sections = {
          { title = "Album", fields = { { "Série", 2 }, "Tome", "Variante", { "Titre", 2 } } },
          { title = "Auteurs", fields = { "Scénario", "Dessin", "Couleurs" } },
          { title = "Édition", fields = { "Éditeur", "Collection", "Dépôt légal", "Achevé d’imprimer", "ISBN", "Format", "Édition originale" } },
          { title = "Ma collection", fields = { "Lu", "Date de lecture", "Liste de souhaits", "Série suivie", "Dédicace", "Date de dédicace",
                                                "État", "Note", "Emplacement", "À vendre" } },
          { title = "Achat et cote", fields = { "Prix d’achat", "Date d’achat", "Cote" } },
          { title = "Notes", fields = { "Commentaire", "Identifiant BDGest" } },
        },
      },
      collections = {
        { name = "À lire", rules = { { "Lu", "=", false }, { "Liste de souhaits", "=", false } } },
        { name = "Liste de souhaits", rules = { { "Liste de souhaits", "=", true } } },
        { name = "Éditions originales", rules = { { "Édition originale", "=", true } } },
        { name = "Dédicacés", rules = { { "Dédicace", "=", true } } },
      },
    },
  }
end
