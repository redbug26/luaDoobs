# Home

Databases for the household: belongings, cooking, money.

| File | Database | Contents | Official |
|---|---|---|---|
| [`parcel-tracking.luaDoobs`](parcel-tracking.luaDoobs) | Parcel tracking | Parcels and Contacts: incoming/outgoing direction, nine statuses, carrier (bpost, PostNL, DHL, DPD, GLS, UPS, FedEx, La Poste, Royal Mail, USPS, other), tracking number and link, shop, order, price and shipping cost with total, ordered/shipped/expected/delivered dates, days in transit, late flag, pickup point, “Events” sublist, recipient. Four automatic rules. Parameter: default carrier. Empty, English/French labels, no network. | |
| [`subscriptions.luaDoobs`](subscriptions.luaDoobs) | Subscriptions and services | Subscriptions, Payments and Summary: service category, recurring EUR price, seven billing frequencies, debit and renewal dates, notice period, calculated cancellation deadline and annual/monthly cost; actual payment history and a selected-services total. English/French labels; one instructional summary record. | |
| [`inventory.luaDoobs`](inventory.luaDoobs) | Inventory | item, photo, room, quantity (default 1), unit and total value (calculated), purchase date, warranty end, receipt, serial number; collection “Under warranty” | ✓ |
| [`recipes.luaDoobs`](recipes.luaDoobs) | Recipes | recipe, photo, category, diet (multiple choice), preparation and cooking time, total time (calculated), servings (default 4), rating, ingredients, steps, source | ✓ |
| [`household-budget.luaDoobs`](household-budget.luaDoobs) | Budget | one row per category and month with the planned amount, actual amount, paid, difference (calculated); collections “To pay”, “Income”, “Actual amount missing”. Parameters: year, first month, categories (“Name = amount”, one per line), monthly income. No network. | |

## Subscriptions and services

Enter the full price per payment in EUR and choose a billing frequency. Annual cost is a recurring run
rate for **active** services, not actual spending in a calendar year; trial, paused and cancelled services
contribute zero. Weekly and fortnightly estimates use 52 and 26 payments per year. Monthly, every-two-months,
quarterly, semiannual and annual frequencies use 12, 6, 4, 2 and 1 payments respectively. There is no currency
conversion or proration.

In the pre-created **Summary** record, select all subscriptions to include in the total; update that
selection when adding services. The total remains empty if a selected active service lacks a price or
frequency, and the summary shows the number of missing costs. With no selection, the total is zero.
Multiple summary records can describe different sets of services.

Record actual charges in **Payments**, linked to the subscription, with amount, payment date, paid status
and optional receipt attached in Doobs. Payment history does not change the recurring cost calculation.
Renewal and next-debit dates are entered and advanced manually; a cancellation deadline subtracts the
entered notice period in calendar days from the renewal date. The script creates no bank connection,
automatic debits or notifications. Store only an account label, never banking credentials.

## Parcel tracking

Statuses are updated by hand: carriers have no free public tracking API. The database creates four
automatic rules (**Properties › Automatic Rules**), which only apply to parcels saved afterwards:

- **Tracking link** (Lua action, no network) builds the address of the carrier’s tracking page from the
  carrier and the tracking number; any other carrier uses [17TRACK](https://www.17track.net). The addresses
  are in the `CARRIERS` table at the top of the rule script: check them, and add a carrier there and in the
  **Carrier** choice list. The script reads English or French field names; rename those fields and the rule
  must be edited too.
- **Shipping date** and **Delivery date** fill in today’s date when the status moves on (only if empty).
- **Delivered when dated**: entering a delivery date sets the status to **Delivered**.

**Late** means the expected date has passed without delivery (returned and lost parcels excluded).
