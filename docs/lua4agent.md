# Doobs: writing Lua scripts (guide for an AI agent)

This document gives an agent everything it needs to write Lua scripts that **create and fill Doobs
libraries**, feed **linked libraries** or automate **rules**. Everything described here matches the actual
behavior of the app. What is not described does not exist: do not invent any function, key or type.

---

## 1. Doobs in brief

Doobs is a personal database for iPad, iPhone and Mac, with no code to write, in the spirit of Bento.

- A **database** is a document (`.doobs`) that contains **libraries** (the equivalent of tables).
- A library has typed **fields**, **records**, **forms** (record layout), **collections** (smart: a filter;
  manual: a list of records) and a **presentation** (sort, grouping, view type).
- A **linked library** shows, read-only, data coming from an external source (Contacts, HTTPS CSV, REST API
  or **Lua script**). That data lives in a cache on the device and is never modified by Doobs.

## 2. Kinds of scripts

| Function | Where it is used | What it does |
|---|---|---|
| `import(ctx)` | **New library › From a Lua Script…**, or **New database › From a Lua Script…** | Produces records that go through the import assistant: **one** new library, with its fields, formulas, form, sort, grouping and collections, or an existing library that gets new records. Or describes a **complete database** step by step with `doobs.database()` (several libraries, links, every field type, records, linked libraries), created directly without the assistant (§5.5). |
| `fetch(ctx)` | **New library › Linked library › Lua Script** | Returns the source’s records on every refresh. The library is **read-only**. |
| `rule(ctx)` | **Properties › Automatic Rules › Lua Action** | Runs after a record is saved and returns the fields to change. |
| `action(ctx)` | **Scripts** entry of the sidebar, menu of a library or of a record, database menu | Runs **on demand** for a record, a library or the whole database, and returns changes built with `doobs.changes()`: Doobs shows a summary, then applies them (§5.7). |
| `parameters(ctx)` | With `import(ctx)`, optional | Declares a form shown **before** the import; the values arrive in `ctx.params`. |

A **`.luaDoobs` file** is an import script (with `parameters` when needed) saved in a text file. Doobs opens it
to **create a database** directly: this is the format to deliver to the user (§5.4).

One file can define several functions, but each place only calls its own. A script is made of
**declarations**. Code run at the top level defines constants and local functions, never does the work.

## 3. What a script can create, and what it cannot

Read this before designing a database. `import(ctx)` has **two result shapes**:

| | List of records (`records`, `fields`, `types`, `library`) | Complete database (`doobs.database()`, §5.5) |
|---|---|---|
| Libraries | **one**, through the import assistant (new or existing) | **several**, created directly, including **linked libraries** (§5.6) |
| Field types | `text`, `longtext`, `integer`, `decimal`, `boolean`, `choice`, `date`, `time`, `datetime`, `duration`, `currency`, `rating`, `address`, `phone`, `email`, `url`, `im`, `location`, `media` (empty), `imageurl`, `qrcode`, `ean13` | all of them: plus `multichoice`, `serial`, `formula`, `relation` (link), `sublist` |
| Field options | choices inferred from the values | `choices`, `default` (`"@today"`), `max`, `currency`, `hidden`, sublist columns, link target and cardinality |
| Records | at least one | zero or more, links by key |
| Formulas | `library.formulas` | `formula` fields in place |
| Collections | smart | smart (`linked` rule on a link) and **manual** |
| Automatic rules | — | `lib:addRule`: values, formulas and Lua actions, with trigger, watched fields and condition |
| Forms | one (`library.form`) | the default form and others (`forms`, generated or with sections) |
| View | sort, grouping | sort, grouping, presentation, gallery image |
| Validation | invalid values reported in the assistant | invalid description: **nothing is created**; invalid value: reported |

**Choosing:** a single library filled from a file or an API, which the user may want to adjust → list of
records. A structure (several libraries, links, sublists, multiple choices, serial numbers, template without
records) → complete database. The **official templates** of Doobs are written this way
([`databases/`](../databases/)): they are the reference to imitate.

**No script can:**

- fill a `media` field: the field is created empty. To show a remote image, use `imageurl`;
- create buttons or folders (a complete database creates **automatic rules** with `lib:addRule`, §5.5);
- write records to a linked library (a complete database can *create* one, §5.6, but its records always
  come from its source).

**A linked library (`fetch`)**: field types are **inferred from the values** (boolean, integer, decimal, date,
email, URL…). The user adjusts them in the assistant, where they also choose the unique identifier and rename
fields. The keys `fields`, `types`, `library` and `libraries` returned by `fetch` are **ignored**.

**A rule (`rule`)** cannot write to a calculated field (formula), nor to a media, link or sublist field.

The **JSON template** (`doobs-template`, §10) is still possible for a structure without records imported
through Settings › Templates, but a complete Lua database does everything it does, with records and
localization.

---

## 4. Syntax rules and pitfalls

- **Lua 5.4.7.** Field names with accents, spaces or apostrophes are written `r["Quantité"]`,
  `r["Purchase price"]`. A field’s name is its visible label: choose clean labels, in the language of the
  database (or written in English and localized with `doobs.tr`, §4.1).
- Lua table keys have **no order**. To set the order of fields, return `fields = { … }`.
- `nil` means “no value”: the key does not exist. `""` is an empty string. Do not put `nil` in an array,
  because `#t` becomes unpredictable.
- A JSON `null` becomes `nil`: the key disappears from the object, and a `null` in a JSON array leaves a hole.
  Check the type (`type(v) == "string"`, `type(v) == "number"`) before using a value coming from an API, which
  may also change type.
- Nested tables in a record are **flattened**: `{ author = { name = "X" } }` gives the field `author.name`. An
  array of scalars becomes the text `"a, b, c"`. An array of objects becomes JSON text. Flatten yourself and
  give readable names.
- A single scalar value in the list (`{ "a", "b" }`) becomes the record `{ value = "a" }`.
- Errors: `error("readable message")` stops the script and shows the message to the user. `doobs.*` functions
  raise an error themselves when they fail. Use `pcall` to tolerate an occasional failure, for example an API
  page in error.

### 4.1 Localization

Write every visible text **in English** and register its translations at the top of the script, one
`doobs.trInit` call per language. `doobs.tr` then picks the user’s first preferred language (device settings,
in order) that has a translation, and falls back to the English text. Any number of languages can be added.

```lua
-- French translations (English is the source language).
doobs.trInit("fr", {
  ["Books"] = "Livres",
  ["To read"] = "À lire",
  ["%d books imported"] = "%d livres importés",
})
-- German translations.
doobs.trInit("de", { ["Books"] = "Bücher", ["To read"] = "Zu lesen" })
local T = doobs.tr

function import(ctx)
  local db = doobs.database()
  local books = db:addLibrary(T("Books"))
  doobs.log(string.format(T("%d books imported"), 12))
  …
end
```

- Translate labels, names of libraries, fields, choices and collections, messages and warnings. Compute reused
  names once (`local READ = T("Read")`).
- One English text has **one** translation per language: when two meanings share an English word (a field
  “Computer” and a choice “Computer”), make the English texts different (“Home computer”).
- `T` takes the English text only; format afterwards: `string.format(T("Line ignored: “%s”"), line)`.
- Never translate **keys** that identify data: `id`, properties returned by `fetch`, parameter ids, record keys.
  An embedded `fetch` script (§5.6) runs on its own and registers its own translations.
- Comments are written in English too.

---

## 5. Function contracts

### 5.1 `import(ctx)`

```lua
function import(ctx)
  -- ctx.input  : { name = "file.csv", text = "…contents…" }, present only if the script reads ctx.input
  -- ctx.params : values of the parameters(ctx) form (§5.4), otherwise an empty table
  return {
    name     = "Library name",                   -- optional; otherwise “Lua Import”
    records  = { { Field = value, … }, … },      -- required (may be empty)
    fields   = { "Field1", "Field2", … },        -- optional: field order
    types    = { Field1 = "text", Field2 = "date" }, -- optional: forced types (list in §3)
    warnings = { "message", … },                 -- optional: shown in the assistant
    library  = { … },                            -- optional: library setup (§7)
  }
end
```

- Short form allowed: `return { {…}, {…} }`, that is, the list of records directly.
- If the script **mentions `ctx.input`**, Doobs first asks the user for a file, read as text (encoding
  detected). Without `ctx.input`, the script runs directly, for example to read an API.
- A field listed in `fields` but missing from every record is still created. A field present in the records
  but missing from `fields` is added after.
- Without `types`, the type is **inferred** from the values, as for a CSV. A field with few distinct values (at
  least 10 values, at most 12 distinct ones) becomes a choice list. **Always force the types** for a stable
  result.
- A `choice` field gets the distinct values encountered as options, 50 at most, in order of appearance.
- The user then sees the assistant (preview, types, destination) and confirms. The import is **atomic**:
  everything is created or nothing is. Value errors are listed row by row.
- **New database › From a Lua Script…** creates an empty document, then runs the script as soon as the
  database opens. A `.luaDoobs` file does the same, with the parameters form in addition (§5.4).

### 5.2 `fetch(ctx)`: linked library

```lua
function fetch(ctx)
  -- ctx.sample : true while testing in the assistant
  -- ctx.limit  : number of records wanted during the test (0 otherwise)
  -- ctx.params : non-secret parameters entered in the assistant (also in doobs.params)
  return { { id = "42", Title = "…", Price = 12.5 }, … }
  -- or { records = { … }, warnings = { … } }
end
```

- **Unique identifier**: every record must carry a **stable** key. The assistant automatically suggests `id`,
  `uuid`, `_id`, `reference`, `ref`, `code` or `key`. Links the user creates to these records survive refreshes
  thanks to this key. Without an identifier, Doobs computes a fingerprint of the contents: links are then not
  guaranteed.
- During the test (`ctx.sample == true`), read **a single page** and stop at `ctx.limit` records. The test must
  stay fast.
- Cap: 10,000 records by default, adjustable in the assistant. Beyond that, the rest is truncated with a
  warning.
- Maximum duration of a refresh: at least 120 s.
- **Secrets** (API key, token, password) are declared **by name** in the assistant. Their value goes into the
  device Keychain. The script reads them with `doobs.secret("name")`. Never hard-code a secret in the script.
- On error (exception, invalid JSON), the last valid version of the cache stays displayed.

### 5.3 `rule(ctx)`: rule action

```lua
function rule(ctx)
  -- ctx.record  : record values AFTER the change, { ["Field name"] = value } (without media)
  -- ctx.id      : record identifier
  -- ctx.trigger : "create" or "update"
  -- ctx.changed : list of the names of the changed fields
  -- ctx.rule, ctx.library : names of the rule and of the library
  return { ["Field"] = value, … }   -- or nil: nothing changes
end
```

- Returned field names are compared **ignoring case and accents**.
- Special values: `"@today"` (today’s date), `"@now"` (current instant), `"@clear"` (empties the field),
  `"@toggle"` (flips a checkbox).
- Runs **in the background, after the save**, after the rule’s simple actions. Maximum duration: 60 s. The
  script does not trigger rules again, and **Undo** does not revert its changes. They appear in the record’s
  history under the rule’s name.
- Typical use: completing a record from the web, for example from its ISBN or EAN.
- Values received in `ctx.record`: text (string), numbers, booleans, date `"YYYY-MM-DD"`, date and time ISO
  8601 UTC, time and duration in seconds, amount as a number, link = array of identifiers, location =
  `{ lat =, lon = }`, multiple choice = array of strings, sublist = array of rows.

### 5.4 `parameters(ctx)` and `.luaDoobs` files

```lua
function parameters(ctx)
  -- ctx.database : true when the form comes before creating a database (.luaDoobs)
  local form = doobs.parameters("My collection", {   -- form title (optional)
    database = "Games",                              -- suggested name for the new database (optional)
    message  = "Introduction text.",                 -- optional
  })
  form:addText("name", "Name", { default = "Games", required = true })
  form:addChoice("currency", "Currency", { "EUR", "USD" }, { default = "EUR" })
  form:addInteger("max", "Maximum number", { default = 50, help = "Help shown under the field." })
  form:addDate("since", "Since", { default = os.date("%Y-%m-%d") })
  form:addLongText("list", "Categories", { default = "A\nB" })
  form:addBoolean("demo", "Add samples", { default = true })
  form:addPassword("key", "API key", { placeholder = "optional" })
  return form
end
```

- `doobs.parameters(title, { database, message })` creates the form; each method adds one field and returns the
  form: `addText`, `addLongText`, `addNumber`, `addInteger`, `addBoolean`, `addDate`, `addPassword`
  `(id, label, options)` and `addChoice(id, label, choices, options)`. A duplicate `id` stops the script at its
  line.
- Equivalent table form, still accepted: `return { title =, message =, database =, fields = { { id =, label =,
  type =, choices =, default =, … } } }`, or directly the list of fields.

- Types (table form): `text` (default), `longtext`, `number`, `integer`, `boolean`, `choice` (with a non-empty
  `choices`), `date`, `password`. Each `id` is unique; `label` defaults to `id`; `name` is accepted instead of `id`.
- Options: `default` (string, number or boolean), `required`, `placeholder`, `help`.
- Values received in `ctx.params` and `doobs.params`, **typed**: number for `number` and `integer` (a decimal
  comma is accepted when typing), boolean for `boolean`, `"YYYY-MM-DD"` for `date`, string otherwise. An
  optional field left empty is **absent**: plan a fallback value (`ctx.params.max or 50`). A required `choice`
  without `default` takes the first choice.
- Doobs refuses the input (message to the user) if a required field is empty, if a number, an integer or a
  date is invalid, or if a choice is unknown.
- `parameters` runs in the same sandbox, after approval, with a **30 s** limit. It must stay fast: no long
  network loop.
- Values are **never saved** in the document. The form comes back each time the script is run from the
  database. For a lasting secret, see `doobs.secret` (linked libraries).
- `parameters` must be a **global** function (`function parameters(ctx)`), not a `local function`.

**Opening a `.luaDoobs` file** (Files, Messages, the Doobs browser, File › Open… on Mac):

1. If the script is not already approved on the device, the user reviews and approves it.
2. Form: **database name** (pre-filled with `database`, otherwise with the file name), then the fields of
   `parameters`.
3. The user chooses where to save the database.
4. The database opens; `import(ctx)` runs with `ctx.params`; the library is imported directly (without the
   assistant, with the mappings it would suggest), then shown. The script stays saved in the database as an
   import script.

Rules for writing a `.luaDoobs` file:

- UTF-8 text, `.luaDoobs` extension, 4 MB at most.
- Starts with a `-- Title` comment (60 characters at most; anything after a “:” is ignored): it names the
  script in the database and in the list of approved scripts. Then explain in a comment what the script
  creates.
- Defines `import(ctx)` and, usually, `parameters(ctx)`. Only use `ctx.input` if a source file is really
  needed: the user will have to choose it when the database opens.
- List of records: must return **at least one record**, otherwise the import fails (“The script returned no
  records”). An empty database or one with several libraries: describe a complete database (§5.5).
- `parameters(ctx)` may declare no field at all: `return doobs.parameters(title, { database = … })` is enough to
  suggest a database name (otherwise it is the file name).

### 5.5 Complete database: `doobs.database()`

`import(ctx)` builds the database **step by step**, one statement per element, and returns it. Doobs then
creates everything **in order**, in a single transaction, without the import assistant.

```lua
doobs.trInit("fr", {
  ["Comics library"] = "Bibliothèque de BD", ["My comics"] = "Mes BD",
  ["Series"] = "Série", ["Title"] = "Titre", ["Read"] = "Lu", ["Name"] = "Nom",
  ["Adventure"] = "Aventure", ["Humor"] = "Humour", ["No."] = "N°", ["Loans"] = "Prêts",
  ["Who"] = "Qui", ["Return"] = "Retour", ["To read"] = "À lire",
})
local T = doobs.tr

function parameters(ctx)
  return doobs.parameters(T("Comics library"), { database = T("My comics") })
end

function import(ctx)
  local SERIES, TITLE, READ, NAME, GENRE = T("Series"), T("Title"), T("Read"), T("Name"), T("Genre")

  -- 1. The database.
  local db = doobs.database()

  -- 2. A library, its fields, its records.
  local series = db:addLibrary(SERIES, { icon = "books.vertical", color = "orange" })
  series:addField(NAME)
  series:addField(GENRE, "multichoice", { choices = { T("Adventure"), T("Humor") } })
  series:addRecord({ [NAME] = "Tintin", [GENRE] = { T("Adventure") } })

  -- 3. A second library, linked to the first one.
  local albums = db:addLibrary(T("Albums"), { icon = "book", color = "brown" })
  albums:addField(TITLE)
  albums:addField(T("No."), "serial")
  albums:addField(SERIES, "relation", { library = series })
  albums:addField(READ, "boolean", { default = false })
  albums:addField(T("Loans"), "sublist", { columns = {
    { id = "who", name = T("Who") }, { id = "back", name = T("Return"), type = "date" } } })
  albums:addRecord({ [TITLE] = "Tintin in Tibet", [SERIES] = "Tintin", [READ] = true })

  -- 4. Collections, forms, presentation.
  albums:addCollection(T("To read"), { { READ, "=", false } })
  albums:defaultForm({ columns = 2 })
    :addSection(T("Albums"), { { TITLE, 2 }, SERIES, READ })
    :addSection(T("Loans"), { T("Loans") })
  albums:setView("table")

  return db
end
```

See [`databases/collections/retro.luaDoobs`](../databases/collections/retro.luaDoobs) for a complete case with
four libraries.

**Database** (`local db = doobs.database()`)

| Method | Role |
|---|---|
| `db:addLibrary(name, { icon, color, key })` | adds a local library and returns it; `name` unique; `key` = field whose value is the records’ key (default: first input field) |
| `db:addLinkedLibrary(name, source, { icon, color })` | adds a read-only linked library (§5.6) and returns it |
| `db:library(name)` | library already added, or `nil` |
| `db:addWarning(text)` | message shown to the user after creation (skipped row, corrected value…) |
| `db:addAction(name, { scope, library, script, entry })` | action run on demand, created with the database (§5.7) |
| `db:addReport(name, { subtitle, palette, blocks })` | report created with the database (below) |

**Reports** (`db:addReport`). A report is computed each time it is shown (nothing is stored but its definition).
Each block is a table:

- `type`: `"chart"`, `"table"` (cross table), `"kpi"` (figures), `"records"` (list), `"text"`, `"pagebreak"`;
- `library`: a library added by the script (object or name), required except for `text` and `pagebreak`;
- `filter`: rules as for `addCollection` (§7), with `match = "any"` to combine them with “or”;
- `groupBy`, `splitBy` (a series per value), `sortField`: `"Field"`, `"Link>Field"` (field of the linked record)
  or `"@created"` / `"@modified"`; grouping on a link groups by the title of the linked record;
- `series`: `{ { label, measure, field, filter, match, color }, … }`; `measure` = `count` (default), `sum`, `avg`,
  `min`, `max`, `distinct` or `percent`; `sum`…`distinct` need `field`; shortcut: `measure` / `field` / `label` on
  the block for a single series;
- `columns` (`records`): field paths; `text` (`text`): simple Markdown, `{date}`, `{database}`, `{count}`;
- settings, as in the report editor: `title`, `note`, `width` (`full`, `half`, `third`), `chart` (`bar`, `hbar`,
  `stacked`, `stacked100`, `line`, `area`, `pie`, `donut`), `groupDate` (`day` … `year`, `weekday`), `sort`
  (`auto`, `label`, `value`, `value-asc`), `limit`, `others`, `showValues`, `showLegend`, `showTotal`,
  `hideEmpty`, `decimals`, `sortDescending`.

A block whose field is unknown is skipped with a warning; a report without a valid block is not created.

```lua
local open = { { "Status", "!=", T("Resolved") }, { "Status", "!=", T("Closed") } }
db:addReport(T("Open tickets"), { blocks = {
  { type = "kpi", library = tickets, filter = open, series = { { label = T("Open") },
      { label = T("Unassigned"), filter = { { "Assigned", "=", false } } } } },
  { type = "chart", chart = "hbar", library = tickets, filter = open, groupBy = "Requester", sort = "value", limit = 20 },
  { type = "table", library = tickets, filter = open, groupBy = "Requester", splitBy = "Group", showTotal = true },
} })
```

**Library** (returned by `addLibrary`; every method except `defaultForm`/`addForm` returns the library, so calls
can be chained)

| Method | Role |
|---|---|
| `lib:addField(name, type, options)` | adds a field; `type` defaults to `"text"` (§6, plus `multichoice`, `serial`, `formula`, `relation`, `sublist`); `options` below |
| `lib:addFields({ "Name", { "Year", "integer" }, { "Genre", "choice", { choices = … } } })` | several fields, in order |
| `lib:addRecord(values, key)` | adds a record `{ ["Field name"] = value }`; `key` = its key for links and manual collections |
| `lib:addRecords({ values, … })` | several records |
| `lib:addCollection(name, rules, match)` | smart collection; rules as in §7; `match` = `"all"` (default) or `"any"`; on a link: `{ "Computer", "linked", "key" }` |
| `lib:addManualCollection(name, { key, … })` | manual collection of records, by key |
| `lib:addRule(name, { on, when, condition, match, set, compute, script, enabled })` | automatic rule, applied each time a record is saved (below) |
| `lib:defaultForm({ columns, theme })` | default form; returns a **form** to fill with `:addSection` |
| `lib:addForm(name, { columns, theme })` | extra named form; returns a **form** |
| `lib:addGeneratedForm(name, columns)` | extra form showing every field |
| `lib:setTitle(field)`, `lib:setSubtitle(field)` | title and subtitle of the records |
| `lib:setSort(field, "-field", …)` | sort; `"-"` = descending |
| `lib:setGroup(field)` | grouping of the list |
| `lib:hideFields(field, …)` | fields hidden in forms |
| `lib:setView(type, { gallery = field })` | presentation: `split`, `table`, `gallery`, `form`, `calendar` |

**Form** (returned by `defaultForm` and `addForm`): `form:addSection(title, fields)` returns the form; each item
is `"Name"`, `{ "Name", width }` or `"-"` (separator). The default width is 1 column, except `longtext`, `media`,
`imageurl` and `address` (full width). Without `defaultForm`, a library that has `addForm`/`addGeneratedForm`
forms gets no generated default form.

**Automatic rules** (`addRule(name, options)`, local libraries only), created in the order of the calls and
applied in that order every time a record is saved **after** the database is created (records added by the
script trigger nothing):

| Option | Role |
|---|---|
| `on` | `"create"`, `"update"` or `"any"` (default) |
| `when` | list of watched fields: on an update, the rule only runs if one of them changed (default: any field) |
| `condition`, `match` | rules as for a collection (§7), evaluated on the saved record; `match = "any"` or `"all"` (default) |
| `set` | `{ ["Field"] = value }`: value in the format of §6, or `"@today"`, `"@now"`, `"@clear"`, `"@toggle"` |
| `compute` | `{ ["Field"] = "formula" }` in human form (§8), every field of the library available |
| `script` | Lua action defining `rule(ctx)` (§5.3), written as a long string `[==[ … ]==]` |
| `enabled` | `false` to create the rule disabled |

A rule needs `set`, `compute` or `script`; it cannot change a formula, media, link or sublist field. Within one
rule, `set` and `compute` see the record **as it was before the rule** (compute from `TODAY()`, not from a
date the same rule sets); the next rule sees the result. A rule that cites an unknown field or a rejected value
is not created and is reported. The `script` is approved with the file only if it appears there **verbatim**
(as for `fetch`, §5.6); it runs on its own, so it registers its own translations or reads field names in each
language the database can be created in (see `databases/home/parcel-tracking.luaDoobs`).

```lua
parcels:addRule(T("Delivery date"), { when = { STATUS },
  condition = { { STATUS, "=", DELIVERED }, { DELIVERED_ON, "empty" } },
  set = { [DELIVERED_ON] = "@today" } })
apps:addRule(T("Applied today"), { when = { STATUS }, condition = { { STATUS, "=", APPLIED } },
  set = { [APPLIED_ON] = "@today" }, compute = { [FOLLOW_UP] = 'DATEADD(TODAY(); 7; "day")' } })
```

**Field options** (`addField(name, type, options)`):

| Option | Types | Role |
|---|---|---|
| `choices` | `choice`, `multichoice` | list of labels, in order |
| `default` | input fields | value for new records; `"@today"` for a date |
| `max` | `rating` | maximum rating (default 5) |
| `currency` | `currency`, `sublist` | ISO code (`"EUR"`) |
| `columns` | `sublist` | `{ { id, name, type, choices… } }`; `id` defaults to `name`, `type` defaults to `text` |
| `library`, `many` | `relation` | target library (the object returned by `addLibrary`, or its name); `many = true` for several records |
| `formula`, `result` | `formula` | human form (§8); `result` = `text` (default), `number`, `currency`, `date`, `boolean` |
| `hidden` | all | hidden in forms |
| `source` | linked library | key of the value in the source’s records (default: the field name), §5.6 |
| `options` | all | extra raw options (§10), merged |

Field names are unique within a library (case-insensitive) and cannot contain `[ ] { }`. A formula can
reference fields of its library and, through a link, those of the target (`SUM([Games]; [Purchase price])`); a
formula that references a field added later is created after the other fields.

**Record values** follow §6, plus:

| Type | Value |
|---|---|
| `relation` | key of the target record, or list of keys (`many`) |
| `multichoice` | list of labels `{ "Vegan", "Gluten-free" }` |
| `sublist` | list of rows `{ { item = "Train", amount = 38.4 } }` (keys: `id` or column name) |
| `location` | `{ lat = 50.47, lon = 4.87 }` or `"50.47, 4.87"` |
| `formula`, `serial`, `media` | ignored (calculated, assigned or not importable) |

A record’s **key** is the one given to `addRecord`, otherwise the value of the library’s `key` field (by default
the first input field). Links and manual collections reference these keys; a linked record may belong to a
library added later.

**Errors.** Mistakes in the calls (unknown type, duplicate field or library, relation without `library`,
formula without `formula`, sublist without `columns`, `addRecord` on a linked library…) **stop the script at the
line of the call**, with a clear message. At creation, a link to a missing library or an invalid formula:
**nothing is created** and the message names the cause. Rejected value, key not found, unknown field in a
record: the database is created and the problem is reported.

**Underlying format.** `db` is a plain table `{ libraries = { … }, warnings = { … } }` (its methods live in
metatables), and `import(ctx)` may also return that table written by hand. Each library is
`{ name, icon, color, key, fields, records, title, subtitle, hidden, sort, group, form, forms, collections, view,
source, rules }` (and `db.actions`, from `db:addAction`, §5.7, and `db.reports`, from `db:addReport`); a rule is `{ name, on, when, condition, match, set, compute, script, enabled }`; a field is `"Name"` or `{ name, type, …options }`; a record carries its key in `_key`; a collection is
`{ name, rules, match }` or `{ name, records }`; a form is `{ name, columns, theme, sections = { { title, fields } } }`
or `{ name, generated = true, columns }`; `view` is `{ type, gallery }`. Prefer the methods: they check every
call.

### 5.6 Linked library in a complete database

`db:addLinkedLibrary(name, source, options)` adds a **linked library**: read-only, its records are read from the
source and refreshed, exactly as one created with **New library › Linked library**. The first refresh starts
right after the database is created.

```lua
local FORECAST = [==[
function fetch(ctx)
  local data = doobs.http.getJSON("https://api.open-meteo.com/v1/forecast", { query = {
    latitude = ctx.params.latitude, longitude = ctx.params.longitude, timezone = "auto",
    daily = "temperature_2m_max", forecast_days = ctx.sample and 3 or 16 } })
  local out = {}
  for i, day in ipairs(data.daily.time) do out[#out + 1] = { id = day, max = data.daily.temperature_2m_max[i] } end
  return out
end
]==]

function import(ctx)
  local db = doobs.database()
  local forecast = db:addLinkedLibrary("Forecast", {
    kind = "lua", script = FORECAST, key = "id",
    params = { latitude = 50.47, longitude = 4.87 },
    refresh = 180, refreshOnOpen = true,
  }, { icon = "cloud.sun" })
  forecast:addField("Date", "date", { source = "id" })
  forecast:addField("Max (°C)", "decimal", { source = "max" })
  forecast:setSort("Date")
  return db
end
```

**Source** (`source` table):

| Key | Kinds | Role |
|---|---|---|
| `kind` | all | **required**: `"lua"`, `"csv"` or `"rest"` |
| `key` | all | identifier of each record: property name (`lua`, `rest`), column or list of columns (`csv`) |
| `refresh`, `refreshOnOpen` | all | refresh interval in minutes (0 = manual), refresh when the database opens |
| `timeout`, `maxRecords` | all | seconds (1–300), record cap |
| `script` | `lua` | Lua source defining `fetch(ctx)` (§5.2), written as a long string `[==[ … ]==]` |
| `params` | `lua`, `rest` | `{ name = value }`, non-secret (`ctx.params` for `lua`, query parameters for `rest`) |
| `secrets` | `lua` | `{ "name" }` (value entered later in the source properties) or `{ name = value }` (e.g. from a `password` parameter); read with `doobs.secret("name")` |
| `url` | `csv`, `rest` | `https://` address |
| `separator`, `header`, `encoding` | `csv` | `"auto"`, `";"`, `","` or `"tab"`; first row is a header (default `true`); `"auto"` or IANA name |
| `headers`, `recordsPath` | `rest` | `{ name = value }`; path of the records in the JSON (`"data.items"`) |
| `pagination` | `rest` | `{ type = "page" \| "offset" \| "cursor", pageParam, sizeParam, pageSize, firstPage, offsetParam, limitParam, cursorParam, cursorPath }` |
| `auth` | `rest` | `{ type = "none" \| "apiKeyHeader" \| "apiKeyQuery" \| "basic" \| "bearer", name, username, key \| password \| token }` (OAuth is not available here) |

Rules:

- Each field maps a value of the source’s records: `source = "key"` (default: the field name). Allowed types:
  every simple type of §6 (no `formula`, `relation`, `sublist`, `serial`, `media`, `multichoice`).
- No `addRecord`: the records come from the source. Smart collections, forms, title, sort and view work as for a
  local library. A manual collection of a linked library, or a link from a local record to one of its records,
  cannot be filled at creation (reported); links can be made afterwards in the app.
- A local library can have a `relation` field targeting a linked library (`{ library = forecast }`).
- **Secret values** (`secrets = { token = value }`, `auth.token`, `auth.key`, `auth.password`) go to the device
  Keychain, never into the document. A missing value is reported: the user enters it in the source properties.
- **Approval**: the `fetch` script is approved together with the `.luaDoobs` file only if it appears in that
  file **verbatim** (keep it as a literal long string; never download or assemble it). Otherwise the user must
  approve it before the first refresh.

### 5.7 `action(ctx)`: action run on demand

An action is a script that the user runs when they want: refreshing a database from an online account,
completing a record, creating a weekly review… It has a **scope**:

| Scope | Where it is run | `ctx` |
|---|---|---|
| `"record"` | Menu of a record (of its library) | `ctx.record` (values, as for `rule`), `ctx.id`, `ctx.library` |
| `"library"` | Menu **⋯** of the library | `ctx.library` (name) |
| `"database"` | **Scripts** entry of the sidebar, database menu | — |

Every action also receives `ctx.scope`, `ctx.action` (its name) and `ctx.libraries`, the list
`{ { name =, fields = { names… }, linked = bool }, … }` of the database, to check what exists.

```lua
function action(ctx)
  local c = doobs.changes()
  c:update(ctx.id, { ["Titre"] = "New title" })                       -- a given record (ctx.id)
  c:create("Tâches", { ["Titre"] = "Weekly review" })                 -- a new record
  c:upsert("Séries", "Identifiant", { Identifiant = 806, Titre = "Blake et Mortimer" })
  c:upsert("Albums", { "Identifiant", "Collection" }, { Identifiant = 12, Collection = "mybase", ["Série"] = 806 })
  c:untouched("Albums", { ["Possédé"] = false }, { ["Possédé"] = true })
  c:key("Séries", "Identifiant")                                      -- key used by links to this library
  return c:message("12 albums read.")
end
```

- `upsert(library, key, values)`: the record whose **key** (one field name, or a list of names) has the same
  value is updated, otherwise a record is created. With several records sharing a key (two copies of a book),
  the n-th `upsert` of this key updates the n-th existing record (in creation order).
- **Only the given fields are written**, and only when the value changes: the user’s own fields and records
  are kept. `"@clear"` empties a field. Formula, serial, media and sublist fields are ignored.
- `untouched(library, values, where)`: writes `values` on the records of the library that no `update` or
  `upsert` of this run reached, among those that match `where` (equalities, optional). Typical use: marking
  what disappeared from the source. **Nothing is ever deleted.**
- A link receives the **key** of the target record: the key of the `upsert` calls on the target library (one
  field), or the one declared by `c:key(library, field)`. Linked libraries are read-only.
- Doobs first computes the changes without writing (“3 records created, 120 modified”) and asks for
  confirmation; an automatic backup precedes the writing; everything is written in one transaction, without
  triggering the automatic rules. A **record** action that only updates records is applied directly and can
  be undone (**Undo**). Unknown fields and invalid values are reported, never fatal.
- Limits: 2 minutes, extendable with `doobs.timeout` up to 30 minutes. Secrets: those of the import script
  with the same title (first comment), so an action in the `.luaDoobs` file that created the database reuses
  its sign-in (`doobs.oauth.token`).
- `nil` or an empty `doobs.changes()`: nothing changes (with `c:message(…)`, the message is shown).

**Created with the database.** `db:addAction(name, { scope = "database" | "library" | "record", library =
lib, script = text, entry = "action" })` adds an action to the database built by `import(ctx)`. Without
`script`, the action is **the `.luaDoobs` file itself**, approved with it: write `action(ctx)` in the same
file, next to `import(ctx)`, and share the reading code (see
[`databases/collections/bdgest.luaDoobs`](../databases/collections/bdgest.luaDoobs), action “Refresh from
BDGest”). A user can also add an action by hand: **Scripts › New action…**.

## 6. Values: expected format per type

For an import, each value is converted to text, then read according to the field type. Send values in these
formats.

| Type | Identifier | Value to return from Lua |
|---|---|---|
| Short text | `text` | string |
| Long text | `longtext` | string (`\n` line breaks allowed) |
| Integer | `integer` | number or string (`"1 234"` and `"1234,0"` accepted; rounded) |
| Decimal | `decimal` | number (`12.5`) or string (`"12,5"`) |
| Checkbox | `boolean` | `true`/`false`, or `"oui"`, `"non"`, `"yes"`, `"no"`, `"1"`, `"0"`, `"x"`, `"vrai"`, `"faux"` |
| Choice list | `choice` | string; the options are the values encountered |
| Date | `date` | `"YYYY-MM-DD"` (preferred). Also `dd/MM/yyyy`, `dd-MM-yyyy`, `dd.MM.yyyy`, `yyyy/MM/dd`, `yyyy` or ISO 8601 |
| Time | `time` | `"HH:MM"` or `"HH:MM:SS"` |
| Date and time | `datetime` | ISO 8601 (`"2026-03-14T09:30:00Z"`) or `"yyyy-MM-dd HH:mm"` (local time) |
| Duration | `duration` | `"1h30"`, `"2j"` (days), `"45"` (minutes by default), `"1:30"` (h:min), `"1:30:00"` (h:min:s) |
| Amount | `currency` | number in major units (`12.5` = 12.50) or string |
| Rating | `rating` | integer from 0 to 5 (or `"★★★"`) |
| Address | `address` | string, several lines separated by `\n` |
| Phone | `phone` | string |
| Email | `email` | string |
| Website | `url` | `https://…` string |
| Messaging | `im` | string (handle) |
| Location | `location` | `"50.85, 4.35"` (latitude, longitude) |
| Media | `media` | **not importable**: the field is created empty |
| Image (URL) | `imageurl` | `https://…` string pointing to an image, shown and cached, never copied |
| QR code | `qrcode` | string to encode |
| EAN-13 barcode | `ean13` | string of 13 digits, the last one being the check digit (verified) |

Only in a complete database (§5.5), a JSON template (§10) or in the app: `multichoice`, `serial`, `formula`
(except through `library.formulas`), `relation`, `sublist`. In a complete database, a value can also be a
real Lua type (number, boolean, list, table): see the table in §5.5.

Advice:

- An unknown date must be **absent**, not `""` nor `"0000-00-00"`.
- For an amount, return a number; never return `"12,50 €"`.
- A value invalid for the type is reported as a row error in the assistant; it is not imported.

## 7. Library setup (`library`, import only)

Every reference to a field uses its **name**. A name that cannot be found produces a warning and the entry is
ignored. Exception: a form field that cannot be found is ignored **without** a warning, which allows a form
shared by files with varying columns.

```lua
library = {
  icon     = "books.vertical",   -- SF Symbol name
  color    = "orange",           -- blue indigo purple pink red orange yellow green mint teal cyan brown gray
  formulas = {                   -- calculated fields, created after the imported fields
    { name = "Total", formula = "[Price] * [Quantity]", type = "currency" },
    { name = "Label", formula = '[Series] & " – V" & [Volume]', type = "text", hidden = true },
  },
  hidden   = { "Source identifier" },   -- hidden fields
  title    = "Label",                   -- records’ title field (lists, links)
  subtitle = "Author",                  -- subtitle field
  sort     = { "Series", "Volume", "-Year" },  -- "-" = descending order
  group    = "Series",                  -- list grouping
  form = {
    columns  = 2,                       -- 1 to 4 (default 2)
    theme    = "system",                -- system sand ocean forest night paper
    sections = {
      { title = "Album", fields = { { "Series", 2 }, "Volume", { field = "Title", span = 2 } } },
      { title = "Notes", fields = { "Comment" } },
    },
  },
  collections = {                       -- smart collections
    { name = "To read", rules = { { "Read", "=", false } } },
    { name = "Expensive or rare", match = "any", rules = {
        { field = "Price", op = ">", value = 50 },
        { field = "Rarity", op = "=", value = "Rare" },
    } },
  },
}
```

- **formulas.type**: `text`, `number`, `currency`, `date` or `boolean` (default `text`). Formulas may depend on
  each other; declare them in dependency order.
- **form.sections.fields**: each item is `"Name"`, `{ "Name", width }` or `{ field = "Name", span = width }`
  (`name` is the same as `field`). The default width is 1 column, except for `longtext`, `media`, `imageurl`
  and `address`, which take the full width. The form replaces the layout of the default form.
- **collections.rules**: `{ field, operator, value }` or `{ field =, op =, value = }`. `match = "all"`
  (default, every condition) or `"any"` (at least one).
  - Operators: `=` (or `==`), `<>` (or `~=`, `!=`), `>`, `>=`, `<`, `<=`, `contains`, `notcontains`, `begins`,
    `ends`, `empty`, `notempty`, `lastdays` (value = number of days), `between` (upper bound as 4th element
    or `value2 =`), `near` (location field: value = km, center as 4th element or `center =`: `{ lat =, lon = }`
    or `"here"` for the device location when the list is shown), e.g. `{ "Place", "near", 25, { lat = 50.85, lon = 4.35 } }`.
  - A collection whose rule references an unknown field is not created.
  - Values: `true`/`false` for a checkbox, `"YYYY-MM-DD"` for a date, a number or a string otherwise.

## 8. Formula syntax (human form)

- A field is written `[Field name]`. The **argument separator is `;`**. Text is in double quotes; in a Lua
  string, use single quotes or `[[…]]` around the formula.
- Operators: `+ - * /`, `%` (remainder), `^` (power), `&` (concatenation), `= <> < <= > >=` (`!=` accepted).
- Functions:
  - logic: `IF(c; a; b)`, `AND(…)`, `OR(…)`, `NOT(x)`, `ISBLANK(x)`, `COALESCE(a; b; …)`;
  - numbers: `ROUND(x; n)`, `ABS(x)`, `MIN(…)`, `MAX(…)`;
  - text: `CONCAT(…)`, `UPPER(t)`, `LOWER(t)`, `LEN(t)`, `TRIM(t)`;
  - dates: `TODAY()`, `NOW()`, `YEAR(d)`, `MONTH(d)`, `DAY(d)`, `DATEADD(d; n; "day"|"week"|"month"|"year")`,
    `DAYS(d1; d2)` (number of days from d2 to d1);
  - French names accepted: `SI`, `ET`, `OU`, `NON`, `ESTVIDE`, `ARRONDI`, `MAJUSCULE`, `MINUSCULE`, `NBCAR`,
    `AUJOURDHUI`, `MAINTENANT`, `ANNEE`, `MOIS`, `JOUR`;
  - aggregates over a link or a sublist: `COUNT([Link])`, `SUM([Link]; [Field])`, `AVG(…)`, `MINOF(…)`,
    `MAXOF(…)`. Useless in a list-of-records import, which creates neither links nor sublists; use them in a
    complete database.
- A duration is in seconds: `([Preparation] + [Cooking]) / 60` gives minutes.
- Errors shown: `#DIV/0!`, `#NUM!`, `#ERR!`.

Examples:

```
IF(ISBLANK([Due date]); ""; DAYS([Due date]; TODAY()))
TRIM([First name] & " " & [Last name])
IF(ISBLANK([Year]); ""; YEAR(TODAY()) - [Year])
```

## 9. The `doobs` module

| Function | Role |
|---|---|
| `doobs.http.request{ method=, url=, headers=, query=, body= \| json= \| form=, timeout= }` | HTTP request. Returns `{ status, ok, body, headers, url }`; `ok` is `true` if 200 ≤ status < 300. `headers` has lowercase names. **Does not raise an error** on a 4xx or 5xx status: check `ok`. |
| `doobs.http.get(url, opts)` | GET, returns the same response. |
| `doobs.http.getJSON(url, opts)` | GET and JSON decoding. **Raises an error** if the status is ≥ 400 or if the JSON is invalid. |
| `doobs.json.decode(text)` / `doobs.json.encode(value, pretty)` | JSON (sorted keys; `pretty` = indented). |
| `doobs.csv.parse(text, { separator = ";" \| "," \| "tab", header = true })` | List of rows: tables `{ column = value }` if `header` (default), arrays otherwise. Separator detected when omitted. |
| `doobs.secret("name")` | Keychain secret declared in the configuration, or saved by the script. |
| `doobs.setSecret("name", value)` | Saves a secret to the Keychain (`nil` erases it). Linked library: its own secrets; import script: secrets stored under its title (first comment), shared by every database where it runs. |
| `doobs.oauth.token(options, renew)` | Access token of an online account (OAuth 2.0 with PKCE), kept in the Keychain and renewed silently; signs in only when needed (§11.5). |
| `doobs.oauth.forget(options)` | Erases the saved token and client. |
| `doobs.oauth.authorize{ authorizeURL=, clientID=, scope=, redirectURI=, params= }` | Opens the service’s sign-in page in the system sheet (PKCE, state checked) and returns `{ code, verifier, redirectURI }`; the script exchanges the code itself. |
| `doobs.oauth.redirectURI` | Return address of the app: `"doobs-oauth://callback"`. A `redirectURI` such as `"http://127.0.0.1:8765/callback"` is received by a local listener instead (services that refuse custom schemes). |
| `doobs.params` | Non-secret parameters (also `ctx.params`). |
| `doobs.log(…)`, `print(…)` | Log shown during trial runs (500 lines at most). |
| `doobs.sleep(seconds)` | Pause, to respect an API’s rate limit (30 s at most per call: loop for longer). |
| `doobs.timeout(seconds)` | Extends the allowed duration from now (import: 30 minutes at most; other kinds: their limit). Returns the remaining seconds. |
| `doobs.sha256(text)` | Hexadecimal digest. |
| `doobs.base64.encode(t)` / `doobs.base64.decode(t)` | Base64. |
| `doobs.url.encode(t)` / `doobs.url.query(table)` | URL encoding, query string. |
| `doobs.luaVersion` | Lua version. |
| `doobs.database()` | Complete database built step by step (§5.5, §5.6); `db:addAction(…)` (§5.7), `db:addReport(…)` (§5.5). |
| `doobs.changes()` | Changes returned by an action: `update`, `create`, `upsert`, `untouched`, `key`, `message` (§5.7). |
| `doobs.parameters(title, { database, message })` | Parameters form built field by field (§5.4). |
| `doobs.trInit(language, { ["English text"] = "translation" })` | Registers translations for one language (`"fr"`, `"de"`, `"pt-BR"`…); calls add up (§4.1). |
| `doobs.tr(text)` | Translation of the English `text` in the user’s first preferred language that has one, otherwise `text` (§4.1). |
| `doobs.language` / `doobs.languages` | User’s preferred language code (`"fr"`, `"de"`…) and ordered list of their languages (full identifiers such as `"pt-BR"`, then codes). |

HTTP options:

- `query`: table appended to the URL, encoded.
- `json`: JSON body, with `Content-Type: application/json` by default.
- `form`: `application/x-www-form-urlencoded` body.
- `body`: raw text.
- `timeout`: seconds, from 1 to 300 (default 30).
- **`https://` only**; any other address raises an error.

### Sandbox

- Available libraries: `string`, `table`, `math`, `utf8`, `coroutine`, plus `os.time`, `os.date`, `os.clock`
  and `os.difftime`.
- Forbidden: `io`, `require`, `load`, `dofile` and any file access.
- Limits: 120 s by default (rule: 60 s), 256 MB of memory, 50 MB per HTTP response. An import may call
  `doobs.timeout(1800)` for a long read (rate-limited API): 30 minutes at most. Time spent in a sign-in page
  does not count. While an import runs, its row shows the last `doobs.log` line: log the progress
  (“Albums: page 12/45”).
- The script always runs in the background; networking is synchronous, so write simple sequential code.
- **Approval**: a script written or edited on the device is approved automatically. A script received with a
  shared database or a `.luaDoobs` file must be reviewed and approved, its SHA-256 fingerprint being recorded
  per device. So write **readable, commented** code that the user can review before approving.

## 10. JSON template (`doobs-template`) for multi-library structures

A template is a `.json` file that describes libraries **without records**. It creates everything in one
transaction.

```json
{
  "format": "doobs-template",
  "version": 1,
  "name": "Retro collection",
  "libraries": [
    {
      "id": "8F0C1E2A-0000-4000-8000-000000000001",
      "name": "Publishers", "icon": "building.2", "color": "orange",
      "fields": [
        { "id": "8F0C1E2A-0000-4000-8000-000000000101", "name": "Name",    "type": "text", "options": { "isTitle": true } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000102", "name": "Country", "type": "choice", "options": { "choices": ["France", "United Kingdom", "Japan"] } }
      ],
      "forms": [], "collections": []
    },
    {
      "id": "8F0C1E2A-0000-4000-8000-000000000002",
      "name": "Games", "icon": "gamecontroller", "color": "indigo",
      "fields": [
        { "id": "8F0C1E2A-0000-4000-8000-000000000201", "name": "No.",       "type": "serial" },
        { "id": "8F0C1E2A-0000-4000-8000-000000000202", "name": "Title",     "type": "text", "options": { "isTitle": true, "required": true } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000203", "name": "Publisher", "type": "relation",
          "options": { "targetLibraryID": "8F0C1E2A-0000-4000-8000-000000000001", "cardinality": "one" } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000204", "name": "Genres",    "type": "multichoice", "options": { "choices": ["Action", "Adventure", "Puzzle"] } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000205", "name": "Price",     "type": "currency", "options": { "currency": "EUR" } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000206", "name": "Quantity",  "type": "integer", "options": { "default": 1 } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000207", "name": "Value",     "type": "formula",
          "options": { "resultType": "currency", "formula": "{8F0C1E2A-0000-4000-8000-000000000205} * {8F0C1E2A-0000-4000-8000-000000000206}" } },
        { "id": "8F0C1E2A-0000-4000-8000-000000000208", "name": "Sessions",  "type": "sublist",
          "options": { "columns": [
            { "id": "date",     "name": "Date",     "type": "date" },
            { "id": "duration", "name": "Duration", "type": "duration" },
            { "id": "done",     "name": "Done",     "type": "boolean" } ] } }
      ],
      "forms": [
        { "id": "8F0C1E2A-0000-4000-8000-000000000301", "name": "Record", "layout": {
          "layoutVersion": 1, "columns": 2, "theme": "system",
          "sections": [
            { "type": "section", "title": "Game", "items": [
              { "type": "field", "fieldUUID": "8F0C1E2A-0000-4000-8000-000000000202", "span": 2 },
              { "type": "field", "fieldUUID": "8F0C1E2A-0000-4000-8000-000000000203", "span": 1 },
              { "type": "field", "fieldUUID": "8F0C1E2A-0000-4000-8000-000000000205", "span": 1 } ] } ] } }
      ],
      "collections": [
        { "id": "8F0C1E2A-0000-4000-8000-000000000401", "name": "Over €20",
          "filter": { "filterVersion": 1, "logic": "and",
                      "rules": [ { "fieldUUID": "8F0C1E2A-0000-4000-8000-000000000205", "operator": "gt", "value": 20 } ] },
          "sorts": [ { "fieldUUID": "8F0C1E2A-0000-4000-8000-000000000202", "descending": false } ] }
      ],
      "view": { "viewType": "split",
                "sorts": [ { "fieldUUID": "8F0C1E2A-0000-4000-8000-000000000202", "descending": false } ] }
    }
  ]
}
```

Template rules:

- **Every `id` is a UUID** (libraries, fields, forms, collections). Doobs replaces them with new identifiers
  and rewrites every reference (`targetLibraryID`, `fieldUUID`, `{UUID}` in formulas). A short identifier would
  not be rewritten reliably in a formula.
- **Formulas in a template**: **stored** form, `{field-UUID}` instead of `[Name]`, separator `;`. Formulas are
  created after the other fields; a formula may depend on another.
- A **link** (`relation`) to a library missing from the template becomes a text field.
- Accepted types: all those in §6, plus `multichoice`, `serial`, `formula`, `relation` and `sublist`. An
  unknown type becomes `text`.
- `view.viewType`: `split`, `table`, `gallery`, `tree` (parent records) or `calendar`.
- The keys `visibleColumns`, `columnWidths`, `formID`, `galleryFieldID` and `galleryItemSize` are optional.
- Filter operators (`operator`): `eq`, `neq`, `contains`, `notcontains`, `begins`, `ends`, `gt`, `gte`, `lt`,
  `lte`, `between` (with `value2`), `empty`, `notempty`, `linked`, `lastdays`, `near` (location: `value` = km,
  `value2` = `{ "lat": …, "lon": … }` or `"here"`). Nesting is possible: a rule can
  be `{ "logic": "or", "rules": [ … ] }`.

Field options (`options`):

| Option | Types | Effect |
|---|---|---|
| `isTitle`, `isSubtitle` | all | records’ title or subtitle field |
| `required` | input | mandatory value |
| `default` | input | initial value (`"@today"` for a date) |
| `choices` | `choice`, `multichoice` | array of labels |
| `max` | `rating` | number of stars, from 1 to 10 (default 5) |
| `decimals`, `grouping` | `decimal` | decimals shown (default 2), thousands separator |
| `currency`, `scale` | `currency` | ISO code (`"EUR"`), decimals from 0 to 4 (default 2) |
| `targetLibraryID`, `cardinality` | `relation` | target library; `"one"` or `"many"` |
| `hierarchy` | `relation` | `true`: parent record (`"one"` link to the **same** library, `tree` view) |
| `columns` | `sublist` | `[ { id, name, type } ]`; simple types (text, number, date, amount, checkbox…) |
| `currency` | `sublist` | currency of the amount columns |
| `formula`, `resultType` | `formula` | stored form; `text`, `number`, `currency`, `date` or `boolean` |

**Combining with Lua**: the agent produces the template, then one `import` script per library. That script
returns records whose keys are the **names** of the template’s fields, without a `library` key. The user
chooses the existing library as the destination in the assistant.

---

## 11. Complete examples

### 11.1 Importing a CSV file with a full setup

```lua
-- Import an inventory CSV: “ref;item;room;qty;price;purchased;warranty;photo”
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
local function num(s)
  s = trim(s):gsub("%s", ""):gsub(",", ".")
  return tonumber(s)
end
local function day(s)           -- "14/03/2024" -> "2024-03-14"
  local d, m, y = trim(s):match("^(%d%d?)/(%d%d?)/(%d%d%d%d)$")
  if not d then return nil end
  return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
end

function import(ctx)
  local rows = doobs.csv.parse(ctx.input.text, { separator = ";" })
  local records, warnings, skipped = {}, {}, 0
  for _, row in ipairs(rows) do
    local name = trim(row.item)
    if name == "" then
      skipped = skipped + 1
    else
      records[#records + 1] = {
        ["Reference"]     = trim(row.ref),
        ["Item"]          = name,
        ["Room"]          = trim(row.room) ~= "" and trim(row.room) or nil,
        ["Quantity"]      = num(row.qty) or 1,
        ["Unit value"]    = num(row.price),
        ["Purchase date"] = day(row.purchased),
        ["Warranty end"]  = day(row.warranty),
        ["Photo"]         = trim(row.photo) ~= "" and trim(row.photo) or nil,
        ["Under warranty"] = false,
      }
    end
  end
  if skipped > 0 then warnings[#warnings + 1] = skipped .. " row(s) without a name skipped." end

  return {
    name = "Inventory",
    records = records,
    warnings = warnings,
    fields = { "Item", "Reference", "Room", "Quantity", "Unit value",
               "Purchase date", "Warranty end", "Photo", "Under warranty" },
    types = {
      ["Item"] = "text", ["Reference"] = "text", ["Room"] = "choice",
      ["Quantity"] = "integer", ["Unit value"] = "currency",
      ["Purchase date"] = "date", ["Warranty end"] = "date",
      ["Photo"] = "imageurl", ["Under warranty"] = "boolean",
    },
    library = {
      icon = "shippingbox", color = "orange",
      formulas = {
        { name = "Total value", type = "currency", formula = "[Quantity] * [Unit value]" },
        { name = "Warranty days", type = "number",
          formula = 'IF(ISBLANK([Warranty end]); ""; DAYS([Warranty end]; TODAY()))' },
      },
      title = "Item", subtitle = "Room",
      hidden = { "Under warranty" },
      sort = { "Room", "Item" }, group = "Room",
      form = {
        columns = 2, theme = "sand",
        sections = {
          { title = "Item", fields = { { "Item", 2 }, "Reference", "Room", "Photo" } },
          { title = "Value", fields = { "Quantity", "Unit value", "Total value" } },
          { title = "Warranty", fields = { "Purchase date", "Warranty end", "Warranty days" } },
        },
      },
      collections = {
        { name = "No reference", rules = { { "Reference", "empty" } } },
        { name = "Over 100", rules = { { "Total value", ">", 100 } } },
        { name = "Bought in the last 30 days", rules = { { "Purchase date", "lastdays", 30 } } },
      },
    },
  }
end
```

### 11.2 Importing from a paginated API, without a file

```lua
-- No ctx.input: the script runs directly.
local BASE = "https://api.example.org/v1/movies"

function import(ctx)
  local records, page = {}, 1
  repeat
    local r = doobs.http.getJSON(BASE, { query = { page = page, per_page = 100 } })
    for _, f in ipairs(r.results or {}) do
      records[#records + 1] = {
        ["Title"]    = f.title,
        ["Year"]     = type(f.year) == "number" and f.year or nil,
        ["Duration"] = type(f.runtime) == "number" and tostring(f.runtime) or nil,    -- minutes
        ["Poster"]   = type(f.poster) == "string" and f.poster or nil,
        ["Rating"]   = type(f.score) == "number" and math.floor(f.score / 2 + 0.5) or nil,  -- /10 -> /5
        ["Synopsis"] = type(f.overview) == "string" and f.overview or nil,
        ["Watched"]  = false,
      }
    end
    page = page + 1
    doobs.sleep(0.2)
  until not r.next or page > 50
  return {
    name = "Movies", records = records,
    fields = { "Title", "Year", "Duration", "Rating", "Watched", "Poster", "Synopsis" },
    types = { ["Title"] = "text", ["Year"] = "integer", ["Duration"] = "duration", ["Rating"] = "rating",
              ["Watched"] = "boolean", ["Poster"] = "imageurl", ["Synopsis"] = "longtext" },
    library = {
      icon = "film", color = "purple", title = "Title", subtitle = "Year",
      sort = { "-Year", "Title" },
      collections = { { name = "To watch", rules = { { "Watched", "=", false } } } },
    },
  }
end
```

### 11.3 Linked library with authentication and pagination

In the assistant, the user declares the `account` parameter and the `token` secret.

```lua
local API = "https://api.example.org/v2"

local function call(path, query)
  local r = doobs.http.request{
    method = "GET", url = API .. path, query = query, timeout = 60,
    headers = { Authorization = "Bearer " .. doobs.secret("token"), Accept = "application/json" },
  }
  if r.status == 429 then doobs.sleep(2); return call(path, query) end   -- rate limit
  if not r.ok then error("The API answered " .. r.status .. " for " .. path) end
  return doobs.json.decode(r.body)
end

function fetch(ctx)
  local account = ctx.params.account or error("Missing “account” parameter.")
  local out, cursor = {}, nil
  repeat
    local data = call("/accounts/" .. doobs.url.encode(account) .. "/products",
                      { limit = ctx.sample and ctx.limit or 200, cursor = cursor })
    for _, p in ipairs(data.items or {}) do
      out[#out + 1] = {
        id        = tostring(p.id),                 -- stable identifier: links guaranteed
        Name      = p.name,
        EAN       = type(p.gtin) == "string" and p.gtin or nil,
        Price     = type(p.price) == "number" and p.price or nil,
        Stock     = type(p.stock) == "number" and p.stock or nil,
        Active    = p.active == true,
        Updated   = type(p.updated_at) == "string" and p.updated_at or nil,
        Image     = type(p.image_url) == "string" and p.image_url or nil,
      }
    end
    cursor = type(data.next_cursor) == "string" and data.next_cursor or nil
  until ctx.sample or not cursor
  return out
end
```

### 11.4 Rule: completing a book from its ISBN

```lua
function rule(ctx)
  local isbn = ctx.record["ISBN"]
  if type(isbn) ~= "string" or isbn == "" then return nil end
  -- Only on creation, or when the ISBN has just changed
  local changed = ctx.trigger == "create"
  for _, n in ipairs(ctx.changed) do if n == "ISBN" then changed = true end end
  if not changed then return nil end

  isbn = isbn:gsub("[^%dX]", "")
  local ok, data = pcall(doobs.http.getJSON, "https://openlibrary.org/isbn/" .. isbn .. ".json")
  if not ok or type(data) ~= "table" then doobs.log("ISBN not found: " .. isbn); return nil end
  local out = {}
  if type(data.title) == "string" and not ctx.record["Title"] then out["Title"] = data.title end
  if type(data.number_of_pages) == "number" then out["Pages"] = data.number_of_pages end
  local year = type(data.publish_date) == "string" and data.publish_date:match("(%d%d%d%d)")
  if year then out["Year"] = tonumber(year) end
  out["Completed on"] = "@today"
  return out
end
```

---

### 11.5 Signing in to an online account (OAuth)

```lua
-- Reads the items of an account protected by OAuth 2.0. The first run opens the service's sign-in page;
-- the next ones reuse or renew the token kept in the Keychain.
local OAUTH = { issuer = "https://account.example.org", scope = "read", resource = "https://api.example.org" }

local function get(path, retried)
  local token = doobs.oauth.token(OAUTH, retried)
  local r = doobs.http.get("https://api.example.org" .. path, { headers = { Authorization = "Bearer " .. token } })
  if r.status == 401 and not retried then return get(path, true) end   -- token revoked: renew once
  if not r.ok then error("Server error " .. r.status, 0) end
  return doobs.json.decode(r.body)
end

function import(ctx)
  local records = {}
  for _, item in ipairs(get("/items").items) do records[#records + 1] = { Name = item.name } end
  return { name = "Items", records = records }
end
```

- `issuer` lets Doobs read the endpoints (`/.well-known/oauth-authorization-server`); otherwise give
  `authorizeURL` and `tokenURL`. Without `clientID`, Doobs registers a public client (dynamic registration)
  if the service offers it, with the redirect `doobs-oauth://callback`. If the service answers
  `invalid_redirect_uri`, use a loopback redirect, `redirectURI = "http://127.0.0.1:8765/callback"` (fixed
  port): Doobs listens on 127.0.0.1 during the sign-in, receives the code and closes the page (RFC 8252).
- Never ask for a password in `parameters`: the sign-in page is the service's own.
- Complete case: [`databases/collections/bdgest.luaDoobs`](../databases/collections/bdgest.luaDoobs) (MCP
  server, JSON-RPC, rate limit, two merged passes).

## 12. Checklist for the agent

1. One library, or several? With links, sublists, multiple choices, a serial number, default values, or
   without records? If so: **complete database with `doobs.database()` (§5.5)**, modeled
   on [`databases/`](../databases/), one statement per library, field, record and collection. Data refreshed
   from an API or a remote CSV: a linked library (§5.6). Otherwise: list of records with `parameters`, `import`
   and `library`.
2. List of records: always return `fields` (order) and `types` (forced types from the allowed list).
   Complete database: every name referenced (formulas, collections, forms, sort, title) must be a field added
   with `addField`; pass the library object to `{ library = … }`.
3. Write texts and comments in English; localize with `doobs.trInit("fr", { … })` (one call per language)
   and `local T = doobs.tr`: form labels, names of libraries, fields, choices, collections and messages
   (§4.1). Compute reused names once (`local READ = T("Read")`).
4. Normalize values according to §6: dates `YYYY-MM-DD`, numeric amounts, booleans `true`/`false`. Leave the
   key absent rather than `""`.
5. Every name referenced in `library` (title, sort, collections, form, formulas) must be **exactly** the name
   of a returned field or of a declared formula.
6. Formulas in human form `[Name]`, separator `;`, double quotes for text; in a JSON template, stored form
   `{UUID}`.
7. Linked library: a stable `id` per record, a single page when `ctx.sample` is true, and secrets through
   `doobs.secret`.
8. Network: `https://` only. Check `r.ok` with `http.request`, `pcall` around `getJSON` to tolerate a failure,
   `doobs.sleep` against rate limits.
9. Check every value coming from an API (`type(v) == "string"`, etc.): a JSON `null` becomes `nil`, and an API
   may return an unexpected type.
10. No `io`, `require`, `load`, nor files. Readable, commented code: the user must be able to approve it after
    reviewing it.
11. Report problems through `warnings` (import) or `doobs.log` (rules, trial runs), without stopping the whole
    import for one faulty row.
12. An account to sign in to: `doobs.oauth.token` (§11.5), never a password in `parameters`. A long read
    (rate-limited API): `doobs.timeout(…)` at the start of `import`, and one `doobs.log` line per page.
13. Data that changes at the source (an online collection, a price list…): add a refresh **action** to the
    database (`db:addAction` + `action(ctx)` with `upsert` on a stable identifier field, §5.7) rather than asking
    the user to create the database again.

The official templates in [`databases/`](../databases/) ship with the app (New database, New library). A
template starts with a description block, read without running the script:

```lua
--[[doobs-template
kind = library        -- library: database and library template; database: database only (demo)
order = 80            -- position in the list, then name
icon = books.vertical
color = brown
name = Livres | Books
summary = Titre, auteur, genre, lu, note | Title, author, genre, read, rating
]]
```

Its `import(ctx)` must return a complete database (`doobs.database()`); it runs without a parameters form
(`ctx.params` is empty).

Official templates (complete databases, localized) in [`databases/`](../databases/): `books`, `contacts`,
`inventory`, `projects` (serial number, default values), `recipes` (multiple choices), `trips` (totaled
sublist) and `movies`; `retro` shows four linked libraries with records, links, a manual collection, extra
forms and a table view.

Examples, organized by type (each folder has its README):

- [`databases/`](../databases/) — `.luaDoobs` files that create a database, by category (`collections/`,
  `home/`, `personal/`, `work/`): the official templates above, plus `home/household-budget` (no network,
  parsed multi-line text), `collections/open-library-books` (public API, images by URL) and
  `personal/running-training-plan` (calculated dates, grouping by week) and `personal/outdoor-journal` (linked
  library fed by an embedded Lua script, with a local journal linked to it).
- [`imports/bdgest.lua`](../imports/bdgest.lua) — real import of a BDGest CSV export (`ctx.input`), with title
  formulas, a form with sections, grouping and collections.
- [`rules/`](../rules/) — rule actions: `isbn-open-library` and `ean-open-food-facts` (completing a record from
  the web), `completion-date` and `recurring-task` (no network).
- [`linked/meteo-open-meteo.lua`](../linked/meteo-open-meteo.lua) — linked library with parameters, a stable
  identifier and test mode (`ctx.sample`).
- [`databases/personal/adeps-points-verts.luaDoobs`](../databases/personal/adeps-points-verts.luaDoobs) —
  creates a linked library for all ADEPS walking events from the ODWB JSON export, with an embedded Lua
  source, typed fields mapped to neutral source keys, English/French labels, configurable periodic refresh,
  composite stable identifiers (source IDs are reused), GPX links and a server-limited sample.
  [`linked/adeps-points-verts.lua`](../linked/adeps-points-verts.lua) remains available for manual setup.
- [`databases/personal/belgian-localities.luaDoobs`](../databases/personal/belgian-localities.luaDoobs) —
  Belgian postal localities from ODWB in an automatically refreshed linked library, with typed geographic
  fields and English/French labels. The source has no record ID: the key combines postal code, locality
  and municipality to distinguish repeated postal/locality pairs. Missing French municipality names and
  provinces remain absent; corrections to any key component change record identity.
- [`databases/work/mini-crm.luaDoobs`](../databases/work/mini-crm.luaDoobs) — four empty local libraries
  for contacts, projects, exchanges and appointments, with multiple contact roles, relations, manual
  follow-up dates, calculated due/overdue flags, sectioned forms and a calendar view. Native device Contacts
  integration is a manual step in the app, as that source kind is not exposed by the documented Lua API.
- [`databases/work/project-management.luaDoobs`](../databases/work/project-management.luaDoobs) —
  project-owned lists of tasks, documents and contacts; aggregates for closed-task percentage and task
  costs, including explicit handling of empty task lists and cancelled statuses.
- [`databases/collections/wine-cellar.luaDoobs`](../databases/collections/wine-cellar.luaDoobs) — estates,
  locations, wine lots and tasting history, with manually maintained inventory, calculated stock value and
  drinking-window status, and two automatic rules (finished date set and cleared).
- [`databases/home/parcel-tracking.luaDoobs`](../databases/home/parcel-tracking.luaDoobs) — incoming and
  outgoing parcels with an “Events” sublist and four automatic rules, including a **Lua action** embedded
  verbatim that formats the carrier’s tracking address and reads English or French field names.
- [`databases/personal/gift-tracker.luaDoobs`](../databases/personal/gift-tracker.luaDoobs) — people with
  calculated next birthday and age, occasions (calendar view, coming dates computed in Lua) and gifts given
  or received, with rules filling purchase and gift dates.
- [`databases/work/job-applications.luaDoobs`](../databases/work/job-applications.luaDoobs) — companies,
  contacts and applications with an “Interviews” sublist; rules with conditions (`match = "any"`), `@clear`
  and a `compute` follow-up date whose delay comes from a parameter.
- [`databases/home/subscriptions.luaDoobs`](../databases/home/subscriptions.luaDoobs) — billing-frequency
  annualization, payment history and totals through a many-record relation in a pre-created summary;
  missing active prices/frequencies leave totals empty instead of silently undercounting.
- [`databases/personal/medication-tracker.luaDoobs`](../databases/personal/medication-tracker.luaDoobs) —
  medicines, manually transcribed treatment instructions and a dose log; no medical lookup or dosing logic.
- [`databases/collections/website-directory.luaDoobs`](../databases/collections/website-directory.luaDoobs) —
  bookmarks with multiple related categories, manually attached screenshots, ratings and smart collections.
