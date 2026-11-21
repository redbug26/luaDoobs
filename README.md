# luaDoobs

**Lua templates** for [Doobs](#about-doobs), the personal database for iPad, iPhone and Mac: ready-made
databases, imports, rules and linked libraries, organized by script type, with their documentation.

## Script types

| Folder | Type | Entry point | In Doobs |
|---|---|---|---|
| [`databases/`](databases/) | **Database** (`.luaDoobs` file) | `import(ctx)` → `doobs.database()` | Open the file: review, parameters, location, then the database is created |
| [`imports/`](imports/) | **Import** | `import(ctx)` → records | **New library › From a Lua Script…** |
| [`rules/`](rules/) | **Rule** | `rule(ctx)` → fields to change | **Properties › Automatic Rules › New Rule › Lua Action** |
| [`linked/`](linked/) | **Linked library** | `fetch(ctx)` → records | **New library › Linked library › Lua Script** |
| — | **Action** | `action(ctx)` → `doobs.changes()` | **Scripts › New action…**, or created with a database (`db:addAction`), such as “Refresh from BDGest” |
| [`docs/`](docs/) | Documentation | — | Complete reference, for humans and AI agents |

Every folder has its own README: how to install, list of scripts, and a starting point to write your own.

## Contents

```
luaDoobs/
├── databases/
│   ├── collections/   books, movies, Open Library books, BDGest, Discogs, retro collection (demo), wine cellar, websites
│   ├── home/          inventory, recipes, household budget, subscriptions, parcel tracking
│   ├── personal/      contacts, trips, running plan, outdoor journal, ADEPS, localities, medication, gifts
│   └── work/          projects, project management, mini CRM, job applications, Freshservice
├── imports/           BDGest CSV export
├── rules/             ISBN → Open Library, EAN → Open Food Facts, completion date, recurring task
├── linked/            Open-Meteo weather forecast
└── docs/              lua4agent.md — scripting reference
```

Agents and contributors: see [`AGENTS.md`](AGENTS.md).

Scripts are written in English (comments included) and translated with `doobs.trInit` / `doobs.tr`: they
follow the user’s preferred languages. The scripts here ship French translations; add any other language
with one more `doobs.trInit` call.

## Security

A script received from someone else never runs before it has been reviewed and approved on the device. It
runs in a sandbox: no files, no code loading, no system access; only HTTPS networking, JSON, CSV and the
secrets you give it, which are stored in the Keychain.

## Writing a script

The reference is [`docs/lua4agent.md`](docs/lua4agent.md). It is written so that an **AI agent**
can produce a correct script on its own: give it to the agent together with your request (“create a
.luaDoobs file to manage my wine cellar, with…”).

- A database is described step by step: `local db = doobs.database()`, then `db:addLibrary(…)`,
  `lib:addField(…)`, `lib:addRecord(…)`, `lib:addCollection(…)`… — several libraries, links, every field type,
  even linked libraries refreshed from an API. The official templates in [`databases/`](databases/) are the
  reference.
- Write in English, register translations with `doobs.trInit("fr", { ["Title"] = "Titre" })`, then use
  `local T = doobs.tr` and `T("Title")`.
- No `io`, `require` or `load`; `https://` only; a JSON `null` becomes `nil`.

## Contributing

Submit one script per pull request, in the folder of its type (and, for a database, of its category):

1. one file per script, lowercase with dashes (`wine-cellar.luaDoobs`, `isbn-google-books.lua`);
2. a header comment: what the script does, where to install it, the expected fields or parameters;
3. a new row in the table of the folder’s README;
4. readable, commented code: users must be able to review it before approving it;
5. no secret in the script (use `doobs.secret("name")`), no personal data;
6. tested in Doobs (try it in the editor, then run it for real).

The official templates are copied from the Doobs source code, where tests check their result: a change must
be carried over there.

## About Doobs

Doobs is a personal, local, document-based database that requires no code, in the spirit of Bento:
libraries, forms, links between records, calculations, smart collections.
# luaDoobs
# luaDoobs
