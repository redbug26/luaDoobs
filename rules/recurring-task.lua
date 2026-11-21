-- Rule: recurring task (no network)
--
-- When “Done” is checked on a repeating task, its due date moves forward by one period and the box
-- is unchecked: the task comes back by itself. “Last time” keeps the completion date.
-- Setup: Library properties › Rules › “After saving” › Lua Script.
-- Expected fields: Done (checkbox), Due date (date), Repeat (choice list: Every day, Every week,
-- Every month, Every year), Last time (date). Field names and choices follow the app language
-- (translations below); adapt them to your library.

doobs.trInit("fr", {
  ["Done"] = "Fait", ["Due date"] = "Échéance", ["Repeat"] = "Répétition", ["Last time"] = "Dernière fois",
  ["Every day"] = "Chaque jour", ["Every week"] = "Chaque semaine", ["Every month"] = "Chaque mois",
  ["Every year"] = "Chaque année",
})
local T = doobs.tr

local F = { done = T("Done"), due = T("Due date"), repeat_ = T("Repeat"), last = T("Last time") }
local STEP = {
  [T("Every day")] = { day = 1 }, [T("Every week")] = { day = 7 },
  [T("Every month")] = { month = 1 }, [T("Every year")] = { year = 1 },
}

-- Adds a period to a “YYYY-MM-DD” date. Months and years: the day is moved back to the end of the
-- month when needed (January 31 + 1 month = February 28 or 29).
local function advance(day, step)
  local y, m, d = day:match("^(%d+)-(%d+)-(%d+)$")
  if not y then return nil end
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  if step.day then
    return os.date("%Y-%m-%d", os.time({ year = y, month = m, day = d + step.day, hour = 12 }))
  end
  local months = m - 1 + (step.month or 0) + 12 * (step.year or 0)
  y, m = y + months // 12, months % 12 + 1
  -- Last day of the target month: day 0 of the next month.
  local last = tonumber(os.date("%d", os.time({ year = y, month = m + 1, day = 0, hour = 12 })))
  return string.format("%04d-%02d-%02d", y, m, math.min(d, last))
end

function rule(ctx)
  local r = ctx.record
  local step = STEP[r[F.repeat_]]
  if r[F.done] ~= true or not step then return nil end

  -- No due date: start again from today.
  local due = advance(type(r[F.due]) == "string" and r[F.due] or os.date("%Y-%m-%d"), step)
  if not due then return nil end
  return { [F.due] = due, [F.done] = false, [F.last] = "@today" }
end
