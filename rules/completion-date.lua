-- Rule: stamp the completion date of a task (no network)
--
-- When “Status” becomes “Done”, “Done on” gets today’s date; if the task is reopened, the date is
-- cleared.
-- Setup: Library properties › Rules › “After saving” › Lua Script.
-- Expected fields: Status (choice list), Done on (date). Field names follow the app language
-- (translations below); adapt them to your library.

doobs.trInit("fr", { ["Status"] = "Statut", ["Done"] = "Terminé", ["Done on"] = "Terminé le" })
local T = doobs.tr

local STATUS, DONE_VALUE, DONE_DATE = T("Status"), T("Done"), T("Done on")

function rule(ctx)
  local touched = false
  for _, name in ipairs(ctx.changed) do if name == STATUS then touched = true end end
  if not touched and ctx.trigger ~= "create" then return nil end

  local finished = ctx.record[STATUS] == DONE_VALUE
  if finished and not ctx.record[DONE_DATE] then return { [DONE_DATE] = "@today" } end
  if not finished and ctx.record[DONE_DATE] then return { [DONE_DATE] = "@clear" } end
  return nil
end
