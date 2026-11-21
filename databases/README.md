# Databases (`.luaDoobs`)

A `.luaDoobs` file **creates a complete database**. When you open it with Doobs, the script is shown for
review and approval; a form then asks for the database name and the script’s parameters, then for the file
location. The database opens with its libraries, fields, records, forms and collections.

## Install

Open the file with Doobs: from Files, AirDrop or a message, from the Doobs browser, or with **File › Open…**
on Mac.

## Per-script JSON metadata

Each `.luaDoobs` script has a sibling `.json` with the same base name, for example
[`books.luaDoobs`](collections/books.luaDoobs) and [`books.json`](collections/books.json).
The metadata file contains a single object:

- `file`: the exact, case-sensitive script file name, relative to the metadata file's folder;
- `title`: an object with `en` and `fr` titles;
- `description`: an object with `en` and `fr` descriptions.

```json
{
  "file": "books.luaDoobs",
  "title": { "en": "Books", "fr": "Livres" },
  "description": {
    "en": "Catalog books with authors, genres, ISBNs, reading status, ratings and loans.",
    "fr": "Cataloguez les livres avec auteurs, genres, ISBN, état de lecture, notes et prêts."
  }
}
```

Clients can resolve `file` against the metadata URL and select a supported language, falling back to `en`.
Create, rename and remove a script's metadata together with the script, and update its description when
the script changes. Reading metadata does not execute the script. There are no per-folder `index.json` files.

### Combined catalog

[`all.json`](all.json) combines every per-script JSON object, including nested category folders. Entries
retain `file`, `title` and `description` and gain `directory`, relative to `databases/`, for example
`"directory": "collections"`. Resolve `directory + "/" + file` against the catalog URL to locate a script.
The array is sorted by directory and file name. The generator excludes `databases/all.json` itself and
rejects invalid metadata, missing scripts, mismatched base names and scripts without metadata.

The [database catalog workflow](../.github/workflows/database-catalog.yml) runs on each branch push and
can also be triggered manually. It regenerates the catalog and commits only `databases/all.json` back to
the same branch when its contents change. It uses `GITHUB_TOKEN`, so its own push does not trigger another
run. Branch rules must permit that bot to push; the workflow does not bypass branch protection.

To regenerate locally, run `python3 scripts/build_database_catalog.py` from the repository root. Python 3.9
or newer is sufficient; no external package is required. Edit per-script metadata rather than the generated file.

## Categories

| Folder | Databases |
|---|---|
| [`collections/`](collections/) | Books, Movies, Open Library books, Retro collection (demo), Wine cellar, Website directory |
| [`home/`](home/) | Inventory, Recipes, Household budget, Subscriptions and services, Parcel tracking |
| [`personal/`](personal/) | Contacts, Trips, Running training plan, Outdoor journal, ADEPS Points verts, Belgian localities, Medication tracker, Gift tracker |
| [`work/`](work/) | Projects, Project management (tasks, documents and contacts), Mini CRM, Job applications |

**Official** templates ship with Doobs and appear in **New database** and **New library**. They are copied
from the Doobs source code, where tests check their result; any change must be carried over there. Every
database here is localized in French and English.

## Writing a database

The script defines `parameters(ctx)` (optional form, suggested database name) and `import(ctx)`, which
describes the database **step by step** and returns it. Reference: [`docs/lua4agent.md`](../docs/lua4agent.md),
§5.4 to §5.6.

```lua
-- French translations (English is the source language).
doobs.trInit("fr", {
  ["Wine cellar"] = "Cave à vin", ["My cellar"] = "Ma cave", ["Samples"] = "Exemples",
  ["Name"] = "Nom", ["Vintage"] = "Millésime", ["Wines"] = "Vins", ["Rating"] = "Note", ["Recent"] = "Récents",
})
local T = doobs.tr

function parameters(ctx)
  local form = doobs.parameters(T("Wine cellar"), { database = T("My cellar") })
  form:addBoolean("samples", T("Samples"), { default = true })
  return form
end

function import(ctx)
  local NAME, VINTAGE = T("Name"), T("Vintage")

  local db = doobs.database()                                        -- the database

  local wines = db:addLibrary(T("Wines"), { icon = "wineglass", color = "red" })   -- a library
  wines:addField(NAME)                                               -- its fields
  wines:addField(VINTAGE, "integer")
  wines:addField(T("Rating"), "rating")
  if ctx.params.samples then
    wines:addRecord({ [NAME] = "Château Exemple", [VINTAGE] = 2018 })  -- a record
  end
  wines:addCollection(T("Recent"), { { VINTAGE, ">=", 2020 } })     -- a smart collection
  wines:setSort("-" .. VINTAGE)

  return db
end
```

A library can also be a **linked library**, refreshed from an API, a remote CSV or a Lua `fetch` script:
`db:addLinkedLibrary(name, { kind = "lua", script = …, key = "id" })` (see `personal/outdoor-journal`).

An **official** template also starts with a description block, read by Doobs without running the script:

```lua
--[[doobs-template
kind = library        -- library: database and library template; database: database only (demo)
order = 10            -- position in the list, then name
icon = books.vertical -- SF Symbol
color = brown
name = Livres | Books
summary = Titre, auteur, genre, lu, note | Title, author, genre, read, rating
]]
```

`name` and `summary` are written “français | english”.
