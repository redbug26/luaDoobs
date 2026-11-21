# Rules (`rule(ctx)`)

A rule action runs **after a record is saved** and returns the fields to change. Typical uses: completing a
record from the web (ISBN, barcode) or automating follow-up (dates, recurrence).

## Install

**Properties › Automatic Rules › New Rule**, choose the **Lua Action** and paste the script. Each script names
its fields at the top of the file, in English with their French translation (`doobs.trInit`): the names follow
the app language. Adapt them to your library.

## Scripts

| File | Network | Expected fields | What it does |
|---|---|---|---|
| [`isbn-open-library.lua`](isbn-open-library.lua) | Open Library | ISBN, Title, Pages, Year, Completed on | Completes a book from its ISBN, without overwriting a title already typed |
| [`ean-open-food-facts.lua`](ean-open-food-facts.lua) | Open Food Facts | EAN (EAN-13), Name, Brand, Quantity, Nutri-Score, Image (image URL) | Completes a product from its barcode; only empty fields are filled |
| [`completion-date.lua`](completion-date.lua) | — | Status, Done on | Stamps today’s date when “Status” becomes “Done”, clears it when the task is reopened |
| [`recurring-task.lua`](recurring-task.lua) | — | Done, Due date, Repeat, Last time | When “Done” is checked, moves the due date forward by one period (day, week, month, year — end of month kept) and unchecks the box |

## Writing a rule

```lua
function rule(ctx)
  -- ctx.record: values after the change; ctx.changed: names of the changed fields
  -- ctx.trigger: "create" or "update"; ctx.id: record identifier
  if ctx.record["Status"] == "Done" and not ctx.record["Done on"] then
    return { ["Done on"] = "@today" }
  end
  return nil   -- nothing changes
end
```

- Special values: `"@today"`, `"@now"`, `"@clear"`, `"@toggle"`.
- A rule cannot write to a formula, media, link or sublist field.
- Maximum duration: 60 s. The script does not trigger other rules, and **Undo** does not revert its changes.
- Only work when the relevant field changed (`ctx.changed`), to avoid useless network calls.

Reference: [`docs/lua4agent.md`](../docs/lua4agent.md), §5.3 and §11.4.
