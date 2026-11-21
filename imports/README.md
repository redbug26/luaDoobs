# Imports (`import(ctx)`)

An import script **fills a library** from a file or an API. Its records go through the Doobs import
assistant: column mapping, simulation, then a single atomic import, into a new library or an existing one.
The script is saved in the database and can be run again.

## Install

In the database: **New library › From a Lua Script…**, create a script and paste the file’s contents. If the
script reads `ctx.input`, Doobs first asks for the file to import.

## Scripts

| File | Source | What it does |
|---|---|---|
| [`bdgest.lua`](bdgest.lua) | CSV export from [BDGest](https://online.bdgest.com) | Recognizes columns by name (series, volume, authors, publisher, ISBN, price, first edition…), converts dates and prices, skips the Magazines and Merchandise tables; title formulas, form with sections, grouping by series, collections. |

To read your BDGest Online account directly (series and albums linked, covers, wishlist), without exporting
a file, create a database from [`databases/collections/bdgest.luaDoobs`](../databases/collections/bdgest.luaDoobs).

To get the BDGest file: on the website, **Outils › Sauvegarde et Restauration › Télécharger le fichier**
(Tools › Backup and Restore › Download the file).

## Writing an import

```lua
function import(ctx)
  -- ctx.input = { name = "…", text = "…" } when a file was chosen; ctx.params = parameters
  local rows = doobs.csv.parse(ctx.input.text, { header = true })
  local records = {}
  for _, r in ipairs(rows) do records[#records + 1] = { Title = r.title, Price = tonumber(r.price) } end
  return { name = "Catalog", records = records,
           fields = { "Title", "Price" }, types = { Price = "currency" },
           library = { icon = "cart", sort = { "Title" } } }
end
```

An import can declare a parameters form (`parameters(ctx)`) and a full library setup (`library`: formulas,
title, form, sort, grouping, collections). To create several linked libraries, return a complete database
instead: see [`databases/`](../databases/). Reference: [`docs/lua4agent.md`](../docs/lua4agent.md), §5.1, §6
and §7.
