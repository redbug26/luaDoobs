-- Rule: fill in a book from its ISBN (Open Library, public API, no account)
--
-- Setup: Library properties › Rules › new “After saving” rule, “Lua Script” action, then paste
-- this script.
-- Expected fields: ISBN (text), Title (text), Pages (integer), Year (integer), Completed on (date).
-- Field names follow the app language (translations below); adapt them to your library.

doobs.trInit("fr", {
  ["Title"] = "Titre", ["Year"] = "Année", ["Completed on"] = "Complété le",
  ["ISBN not found: %s"] = "ISBN introuvable : %s",
})
local T = doobs.tr

local F = { isbn = T("ISBN"), title = T("Title"), pages = T("Pages"), year = T("Year"), done = T("Completed on") }

function rule(ctx)
  local isbn = ctx.record[F.isbn]
  if type(isbn) ~= "string" or isbn == "" then return nil end

  -- Only on creation, or when the ISBN has just changed.
  local changed = ctx.trigger == "create"
  for _, name in ipairs(ctx.changed) do if name == F.isbn then changed = true end end
  if not changed then return nil end

  isbn = isbn:gsub("[^%dXx]", ""):upper()
  local ok, data = pcall(doobs.http.getJSON, "https://openlibrary.org/isbn/" .. isbn .. ".json")
  if not ok or type(data) ~= "table" then
    doobs.log(string.format(T("ISBN not found: %s"), isbn))
    return nil
  end

  local out = { [F.done] = "@today" }
  -- Never overwrite a title already entered.
  if type(data.title) == "string" and not ctx.record[F.title] then out[F.title] = data.title end
  if type(data.number_of_pages) == "number" then out[F.pages] = data.number_of_pages end
  local year = type(data.publish_date) == "string" and data.publish_date:match("(%d%d%d%d)")
  if year then out[F.year] = tonumber(year) end
  return out
end
