# Personal

Databases for people, travels and activities.

| File | Database | Contents | Official |
|---|---|---|---|
| [`gift-tracker.luaDoobs`](gift-tracker.luaDoobs) | Gift tracker | People (relationship, date of birth, calculated next birthday, days left and age reached, interests, wish list, sizes), Occasions (date, type, EUR budget, days left, calendar view) and Gifts (given or received, people, occasion, status from idea to given, price, shop, link, web picture, photo, dates, thank-you sent). Three automatic rules. Parameters: coming occasions (New Year, Valentine’s Day, Christmas, optionally Saint Nicholas), budget per occasion. English/French labels, no network. | |
| [`medication-tracker.luaDoobs`](medication-tracker.luaDoobs) | Medication tracker | Medicines, Treatments and Dose log: packaging strength, manually maintained stock, user-entered restock threshold and expiry, prescribed instructions, treatment dates/status, prescription attachments and planned/taken/skipped dose records. Empty, English/French labels. No medical lookup, dosage calculation or notifications. | |
| [`belgian-localities.luaDoobs`](belgian-localities.luaDoobs) | Belgian localities | every postal-locality row of the [ODWB Belgian postal codes export](https://www.odwb.be/api/explore/v2.1/catalog/datasets/code-postaux-belge/exports/json?lang=fr&timezone=Europe%2FBrussels) in a **linked library**: postal code (text), locality, French municipality name where provided, arrondissement, province and coordinates. English/French labels, sectioned form and collections for missing municipality names or provinces. Refreshes on opening and daily by default; configurable interval in minutes (0 disables periodic refresh). Key: postal code + locality + municipality; changes to these values change identity. | |
| [`contacts.luaDoobs`](contacts.luaDoobs) | Contacts | first name, name, full name (calculated, used as title), photo, company, phone, email, address, website, birthday, notes | ✓ |
| [`trips.luaDoobs`](trips.luaDoobs) | Trips | destination, photo, departure, return, duration (calculated), budget, “Expenses” sublist (item, date, amount, paid) with its total, remaining budget, accommodation, place, memories | ✓ |
| [`running-training-plan.luaDoobs`](running-training-plan.luaDoobs) | Training | every session of a progressive running plan up to race day, grouped by week, with planned distance and duration, done, actual duration, feeling; collections “To do”, “Long runs”, “This week”. Parameters: goal (5 km, 10 km, half marathon), start date, weeks, sessions per week, easy pace. No network. | |
| [`outdoor-journal.luaDoobs`](outdoor-journal.luaDoobs) | Outings | a **linked library** “Forecast” (16-day Open-Meteo forecast, read-only, refreshed every 3 hours, fed by a Lua script embedded in the file) and an “Outings” journal linked to it (date, forecast, place, distance, done, notes). Parameters: latitude, longitude. | |
| [`adeps-points-verts.luaDoobs`](adeps-points-verts.luaDoobs) | ADEPS Points verts | all ADEPS walking events from ODWB in a **linked library**, including archives and cancellations; typed fields for date, location, organizer, contact, accessibility, services and GPX links; composite stable identifiers, collections and a sectioned form. English/French labels. Refreshes on opening and every 6 hours by default. Parameter: refresh interval in minutes (0 disables periodic refresh). | |

## Medication tracker

Create medicine records first, then treatment records linked to them. Transcribe prescribed doses,
schedules and instructions as text. Each dose-log entry links to a treatment and records scheduled and
actual date/time, status, recorded dose and observations; entries and status changes are manual.

Stock, stock units, restock thresholds and expiry dates are entered manually. Dose entries do not alter
stock or generate the next dose. The low-stock and past-expiry collections reflect those entered values;
they create no alerts. Prescription files and packaging photos are attached in Doobs after creation.
The script contains no medication recommendations or sample prescriptions.

## Gift tracker

Link each gift to one or more people and to an occasion; group or filter the Gifts list by status.
Birthdays are calculated from the date of birth (next occurrence, days left, age reached); “Birthdays in
the next 30 days” lists the coming ones. The optional coming occasions are named with their year
(“Christmas 2026”): add next year’s yourself. Automatic rules fill **Bought on** when the status becomes
Bought, **Given or received on** when it becomes Given, and choosing **Received** marks the gift as received
today. Spending per occasion is not totaled automatically: group gifts by occasion to compare with its budget.
