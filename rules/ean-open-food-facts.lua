-- Rule: fill in a product from its EAN-13 barcode (Open Food Facts, public API)
--
-- Setup: Library properties › Rules › “After saving” › Lua Script.
-- Expected fields: EAN (EAN-13 barcode), Name (text), Brand (text), Quantity (text),
-- Nutri-Score (choice list A to E), Image (Media URL). Only empty fields are filled.
-- Field names follow the app language (translations below); adapt them to your library.

doobs.trInit("fr", {
  ["Name"] = "Nom", ["Brand"] = "Marque", ["Quantity"] = "Quantité",
  ["Product unknown to Open Food Facts: %s"] = "Produit inconnu d’Open Food Facts : %s",
})
local T = doobs.tr

local F = { ean = T("EAN"), name = T("Name"), brand = T("Brand"), quantity = T("Quantity"), score = T("Nutri-Score"), image = T("Image") }

local function empty(v) return v == nil or v == "" end

function rule(ctx)
  local ean = ctx.record[F.ean]
  if type(ean) ~= "string" or #ean ~= 13 then return nil end
  local changed = ctx.trigger == "create"
  for _, name in ipairs(ctx.changed) do if name == F.ean then changed = true end end
  if not changed then return nil end

  local ok, data = pcall(doobs.http.getJSON, "https://world.openfoodfacts.org/api/v2/product/" .. ean .. ".json",
    { query = { fields = "product_name,brands,quantity,nutriscore_grade,image_front_url" }, timeout = 20 })
  if not ok or type(data) ~= "table" or data.status ~= 1 or type(data.product) ~= "table" then
    doobs.log(string.format(T("Product unknown to Open Food Facts: %s"), ean))
    return nil
  end

  local p, out = data.product, {}
  local function fill(field, value)
    if type(value) == "string" and value ~= "" and empty(ctx.record[field]) then out[field] = value end
  end
  fill(F.name, p.product_name)
  fill(F.brand, p.brands)
  fill(F.quantity, p.quantity)
  fill(F.image, p.image_front_url)
  if type(p.nutriscore_grade) == "string" and p.nutriscore_grade:match("^[a-e]$") then
    fill(F.score, p.nutriscore_grade:upper())
  end
  return next(out) and out or nil
end
