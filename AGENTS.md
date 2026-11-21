# AGENTS.md — Guide for agents and contributors

This repository collects **Lua scripts for Doobs**, a personal database app for iPad, iPhone and Mac:
ready-made databases (`.luaDoobs`), imports, rules and linked-library sources. There is no build: every file
is a standalone script that a user opens or pastes into Doobs.

## Read first

[`docs/lua4agent.md`](docs/lua4agent.md) is the **only source of truth** for the scripting API: entry points,
`ctx` contents, return shapes, field types and value formats, formulas, the `doobs` module and sandbox limits.
What it does not describe does not exist: never invent a function, key, type or operator. When in doubt, copy
a pattern from an existing script in this repository.

## Layout

| Folder | Entry point | Contents |
|---|---|---|
| `databases/<category>/` | `parameters(ctx)` + `import(ctx)` → `doobs.database()` | `.luaDoobs` files that create a database; categories `collections`, `home`, `personal`, `work` |
| `imports/` | `import(ctx)` → records | scripts pasted in **New library › From a Lua Script…** |
| `rules/` | `rule(ctx)` → fields to change | rule actions |
| `linked/` | `fetch(ctx)` → records | linked-library sources |
| (in a `.luaDoobs`) | `action(ctx)` → `doobs.changes()` | actions run on demand, added with `db:addAction` (lua4agent §5.7) |
| `docs/` | — | `lua4agent.md` |

Every folder has a `README.md` with a table listing its scripts. A new category folder under `databases/`
needs its own README and a row in `databases/README.md`.

## Adding a script

1. Pick the folder of its type (and category for a database). File name: lowercase English words with dashes
   (`wine-cellar.luaDoobs`, `isbn-google-books.lua`). Extension `.luaDoobs` for databases, `.lua` otherwise.
2. Start with a header comment: first line `-- Title` (60 characters at most, it names the script in Doobs),
   then what the script does, where to install it, and the fields or parameters it expects.
3. Write everything in English, comments included. Localize everything visible with
   `doobs.trInit("fr", { ["Title"] = "Titre", … })` (one call per language, at the top of the file) and
   `local T = doobs.tr` (`T("Title")`), and compute reused names once. Describe the database step by step with `doobs.database()` (one statement per library,
   field, record, collection), never as a hand-written `{ libraries = … }` table; build parameters forms with
   `doobs.parameters()`. Data refreshed from an API or a remote CSV belongs in a linked library
   (`db:addLinkedLibrary`), whose `fetch` script stays a literal long string in the file.
4. Rules: put the field names in a table at the top so users can adapt them; only work when the relevant field
   changed (`ctx.changed`); never overwrite a value the user typed unless that is the point of the rule.
5. Linked sources: a stable `id` per record, a single page when `ctx.sample` is true.
6. Add a row to the folder’s README table, and mention notable examples in `docs/lua4agent.md` (end of §12).
7. For each `.luaDoobs` file, add a sibling `.json` with the same base name (e.g. `books.json`): one object
   with `file` (the exact relative script file name), `title` and `description`
   (each an object `{"en": …, "fr": …}`). Rename/remove metadata together with its script.
   `databases/all.json` is generated from those metadata files by `scripts/build_database_catalog.py` and the
   database catalog workflow; regenerate it rather than editing it by hand.

## Rules

- Readable, commented code: users review a script before approving it on their device.
- `https://` only; check API values with `type(v)` (a JSON `null` becomes `nil`); `pcall` around network
  calls that may fail; `doobs.sleep` to respect rate limits.
- No secret in a script (`doobs.secret("name")`, declared in the assistant), no personal data, no test
  credentials.
- Public APIs only, used within their terms; never work around a site’s protection against automated access
  (use a file the user exports instead, as `imports/bdgest.lua` does).
- Sandbox: no `io`, `require`, `load`, `dofile`, no file access.
- READMEs and `docs/lua4agent.md` are in English. Field names inside scripts may be in French when the
  script is not localized; say so in the README.

## Official templates

`databases/**/{books,contacts,inventory,projects,recipes,trips,movies,retro}.luaDoobs` are copies of the
templates shipped with Doobs (`Doobs/Templates/` in the app’s source code), where tests check that each one
builds the expected database. Their file name is their identifier in the app: never rename them. Change them
in the app first, then copy them here; a change made here alone will be overwritten. They start with a
`--[[doobs-template … ]]` block (see `databases/README.md`).

## Testing

Doobs is the reference runtime: run the script in the editor (▶︎ trial run, with a sample file when it reads
`ctx.input`), then for real (open the `.luaDoobs` file, create the rule, add the linked library). For quick
checks without the app, run the script with a stock Lua 5.4 interpreter and a small stub of the `doobs` module
(load `BRDoobsDatabase.lua` from the Doobs app with `loadfile(path)(language, { language })` for `doobs.database`,
`doobs.parameters`, `doobs.tr` and `doobs.trInit`; stub `doobs.log` and `doobs.http.getJSON` returning a saved API response) — but only
Doobs validates field types, formulas and keys.

## Git

Do not commit or push without an explicit request from the repository owner.
