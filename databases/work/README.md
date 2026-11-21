# Work

Databases for projects and tasks.

| File | Database | Contents | Official |
|---|---|---|---|
| [`job-applications.luaDoobs`](job-applications.luaDoobs) | Job applications | Companies, Contacts and Applications: position, company, ten statuses from wish list to offer, priority, source, posting link, location, work mode, contract, EUR salary range, applied/follow-up/last contact/answer dates, days since applying, follow-up due flag, contacts, “Interviews” sublist, résumé and cover letter. Three automatic rules. Parameter: follow-up delay in days. Empty, English/French labels, no network. | |
| [`project-management.luaDoobs`](project-management.luaDoobs) | Project management | four related libraries: Contacts, Tasks, Documents and Projects. Each project selects multiple tasks, documents and contacts; task assignments, status, dates, costs, EUR budget, calculated task count, closed-task percentage and remaining budget. Empty template, English/French labels. | |
| [`projects.luaDoobs`](projects.luaDoobs) | Projects | project, serial number, status (default “To do”), priority (rating out of 3), start (default today), due date, days remaining (calculated), budget, time spent, description; collections “In progress”, “Not completed” | ✓ |
| [`freshservice.luaDoobs`](freshservice.luaDoobs) | Service desk | Requesters (name, email, phones, job title, active) and Tickets read from Freshservice (API v2, read only): number, subject, linked requester, agent and group (names), status (custom statuses included), priority, urgency, impact, source, type, category, due dates, escalated, assigned, tags, description, custom fields, link to the ticket. Seven collections (open, pending, urgent and high, unassigned, escalated, resolved or closed, created in the last 7 days). Report “Open tickets”: overview, by requester, by group, requester × group. Actions “Refresh from Freshservice” and “Refresh this ticket”. Parameters: domain, API key (Keychain), which tickets. Network. | |
| [`mini-crm.luaDoobs`](mini-crm.luaDoobs) | Mini CRM | four empty related libraries: Contacts (multiple roles, contact details, notes, follow-up), Projects (participants, status, dates, EUR budget), Exchanges (history, participants, project, channel, summary, follow-up) and Appointments (participants, project, date/time, duration, preparation, outcome, calendar view). English/French labels, sectioned forms and smart collections. No network or personal data. | |

## Freshservice

Open [`freshservice.luaDoobs`](freshservice.luaDoobs) and enter your Freshservice domain (`yourcompany` for
`yourcompany.freshservice.com`) and your API key (your profile › Profile settings › API key). The key and the
choices are kept in the Keychain of the device, never in the database. The script only reads: tickets,
requesters, agents, groups and the names of custom statuses. Reading agents and groups may need more rights
than reading tickets: without them, the script warns and the tickets keep the agent and group IDs only.

Which tickets:

- **Updated during the last months** (12 by default): every ticket updated since then. Without this date,
  the Freshservice list would stop at the tickets created during the last 30 days.
- **New and my open**, **Watching**: the predefined Freshservice filters, for the owner of the key.
- **Filter query**: your own query in the Freshservice syntax, for example `status:2 AND priority:4`,
  `agent_id:null` or `tag:'vpn'` (status 2 Open, 3 Pending, 4 Resolved, 5 Closed; priority 1 Low to
  4 Urgent). Freshservice returns 300 tickets at most for a query; the script warns when more match.

Only the requesters of the imported tickets are created, unless **All requesters** is on. A ticket whose
requester is not in the requesters list (an agent, a deleted requester) keeps the **Requester ID** only.
Custom ticket fields are gathered as `name : value` lines in **Other fields**. **Agent** and **Group** show the
names of the assigned agent and group (section **Assignment** of the ticket).

The report **Open tickets** (sidebar › Reports) counts the tickets that are neither resolved nor closed (open,
pending, custom statuses): overview (unresolved, unassigned, urgent and high, escalated), by requester (the 20
largest), by group, and a requester × group table. It is computed each time it is shown, so it follows the
refreshes. Requesters missing from the requesters list (agents who opened a ticket) are named too.

**Refresh from Freshservice** (Scripts entry or database menu) reads the account again with the same
choices and updates the records in place, by **Number** for tickets and **Freshservice ID** for requesters:
only the fields read from Freshservice are written, your own fields and records are kept, nothing is deleted.
**Refresh this ticket** (menu of a ticket) reads one ticket again. Freshservice limits the requests per
minute; the script waits when it reaches the limit.

## Project management

Create contacts, tasks and document records, then select them in the project's **Contacts**, **Tasks**
and **Documents** fields. These project fields are the single place where membership is maintained;
there is no second project field to synchronize on each task/document. Task assignees are selected from
Contacts. Avoid selecting the same task in several projects unless its cost should count in each.

Attach files to document records in Doobs after creation, or use HTTPS document URLs. Project cost is the
sum of the selected tasks' entered costs, and remaining budget is budget minus that sum. The closed-task
percentage counts both completed and cancelled tasks; it is zero for a project without tasks. Completed
and cancelled tasks/projects are excluded from overdue flags. This database is separate from the official
`projects.luaDoobs` template, which is unchanged.

## Mini CRM

Open [`mini-crm.luaDoobs`](mini-crm.luaDoobs) in Doobs to create an empty CRM. Create contacts first,
then select them in projects, exchanges and appointments. The contact title uses first and last names,
or the company name for a company-only record. A contact can have several roles (customer, supplier,
acquaintance, prospect). Projects can include several contacts; each exchange or appointment can refer
to several contacts and one project.

Record each interaction in **Exchanges**, with its date/time, channel and summary. Use **Appointments**
for scheduled meetings and their preparation/outcome. Enter follow-up dates and next actions manually;
the corresponding smart collections show pending or due follow-ups. A contact's follow-up and an exchange's
follow-up are independent. Project overdue calculations exclude completed and cancelled projects. The
script creates no automatic rules, notifications or calendar synchronization.

### Optional iPad Contacts link

After creation, add a native **Contacts** linked library through Doobs's linked-library assistant and
grant contact access when the app requests it. In the editable CRM **Contacts** library, add a relation
field targeting that linked library, then select the corresponding device contact in each CRM record.
Keep CRM roles, notes and follow-up in the local library; the native linked library is read-only.

The documented Lua API only supports creating `lua`, `csv` and `rest` linked sources, so the native
Contacts source and relation to it must be added in the app. This template does not copy device contacts,
match them automatically or synchronize the local contact-detail fields with them.

Pair it with the rules [`completion-date`](../../rules/) and [`recurring-task`](../../rules/) to stamp finished
tasks or make them come back.

## Job applications

Create the company first, then the application; contacts (recruiters, interviewers) can be linked to both.
Automatic rules, applied to applications saved after creation: **Applied today** fills the application date
and plans a follow-up after the delay chosen when creating the database (change it in the rule’s formula);
**Interview contact** records the date of the last contact on screening, interview or test; **Answer
received** records the answer date and clears the follow-up on an offer, acceptance, rejection or withdrawal.
“No answer” is set by hand. **Follow-up due** is checked once the follow-up date is reached without answer.
