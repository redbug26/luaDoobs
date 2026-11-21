# Linked libraries (`fetch(ctx)`)

A linked library shows data **read from an external source**, read-only, and refreshes it. Links,
collections and forms created in Doobs stay in the database; they survive refreshes thanks to the stable
identifier of each record.

## Install

**New library › Linked library › Lua Script**, paste the script, declare the parameters listed at the top of
the file (and any secrets, which are stored in the Keychain), test, then choose the unique identifier and the
field types.

## Scripts

| File | Source | Parameters | Identifier | What it shows |
|---|---|---|---|---|
| [`meteo-open-meteo.lua`](meteo-open-meteo.lua) | [Open-Meteo](https://open-meteo.com) (no key) | `latitude`, `longitude` | `id` (date) | 16-day forecast: weather, minimum and maximum temperature, rain |
| [`adeps-points-verts.lua`](adeps-points-verts.lua) | [ODWB / ADEPS JSON export](https://www.odwb.be/api/explore/v2.1/catalog/datasets/points-verts-de-ladeps/exports/json?lang=fr&timezone=Europe%2FBrussels) (no key) | None | `id` (ADEPS ID + point-vert code) | All walking events, including archives and cancellations: date, location, organizer, contact, accessibility, services and GPX links. French field names. |

### ADEPS Points verts

Create an empty database, then add a **Linked library › Lua Script** with
[`adeps-points-verts.lua`](adeps-points-verts.lua). Name it **Points verts ADEPS**, choose `id` as the
unique identifier, and enable automatic refresh in Doobs. To create the database directly with typed,
localized fields and automatic refresh already configured, open
[`databases/personal/adeps-points-verts.luaDoobs`](../databases/personal/adeps-points-verts.luaDoobs).
It uses `db:addLinkedLibrary` (§5.6 of the guide) with an embedded source script and defaults to a six-hour
refresh interval, refresh on opening and a 100,000-record cap.

Check inferred types: `Date` as date, `Position` as location, `Téléphone` as phone, `Latitude` and
`Longitude` as decimals, distance/service flags as booleans, and `Traces GPX` and meeting information as
long text. Keep identifiers and `Carte IGN` as text. Sort by `Date` and use `Localité` as the title if desired.
Cancelled events keep their source status in `Statut`; no event is filtered out.

The full export is downloaded once per refresh; the trial requests at most `ctx.limit` rows (20 when
unspecified). Some ADEPS IDs are reused for different point-vert codes, so the stable key combines both.
Network or identity errors stop the refresh, preserving the previous cache. Doobs defaults to a 10,000-record
cap; raise it in the assistant if the dataset grows beyond that size. No API key or parameter is needed.

## Writing a source

```lua
function fetch(ctx)
  -- ctx.sample = true while testing in the assistant: one page only, at most ctx.limit records
  local data = doobs.http.getJSON("https://api.example.com/items", {
    query = { city = ctx.params.city },
    headers = { Authorization = "Bearer " .. doobs.secret("token") },   -- secret declared in the assistant
  })
  local records = {}
  for _, item in ipairs(data.items or {}) do
    records[#records + 1] = { id = tostring(item.id), Name = item.name, Price = item.price }
    if ctx.sample and #records >= ctx.limit then break end
  end
  return records
end
```

- Every record carries a **stable identifier** (`id`, `uuid`, `code`…).
- Field types are inferred from the values; `fields`, `types`, `library` and `libraries` are ignored.
- Never hard-code a secret: use `doobs.secret("name")`.

Reference: [`docs/lua4agent.md`](../docs/lua4agent.md), §5.2 and §11.3.
