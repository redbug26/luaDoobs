# Collections

Databases to catalog what you own, read or watch.

| File | Database | Contents | Official |
|---|---|---|---|
| [`wine-cellar.luaDoobs`](wine-cellar.luaDoobs) | Wine cellar | Estates, Storage locations, Wines and Tastings: wine lots, vintage, appellation, type, grapes, price, remaining bottles, calculated stock value, cellar location, manually entered drinking window with its calculated status (too young, ready, drink soon, past peak), finished date, tasting dates and ratings. Two automatic rules. Empty, English/French labels. | |
| [`website-directory.luaDoobs`](website-directory.luaDoobs) | Website directory | Categories and Websites: multiple categories per bookmark, URL, description, screenshot attachments, rating, review, favorites, archive status and manually entered last-visit date. Empty, English/French labels. | |
| [`books.luaDoobs`](books.luaDoobs) | Books | title, author, cover, genre, year, ISBN, read, rating, lent to, summary; collections “To read”, “On loan” | ✓ |
| [`movies.luaDoobs`](movies.luaDoobs) | Movies | title, poster, director, year, genres (multiple choice), format, duration, watched, rating; collection “To watch” | ✓ |
| [`retro.luaDoobs`](retro.luaDoobs) | Retro collection (demo) | four linked libraries (computers, publishers, games, acquisitions), 22 records, calculated age and totals, smart and manual collections, two extra forms, table view | ✓ |
| [`bdgest.luaDoobs`](bdgest.luaDoobs) | Comics (BDGest) | your [BDGest Online](https://online.bdgest.com) collection read through the official BDGest server (sign-in to your account, read only): **Séries** (statistics: volumes owned and missing, complete, followed, cost to complete) and **Albums** owned and wishlist, linked to their series, with Bedetheque covers, publishing details and your copy (condition, purchase, value, read, signed…); optional complete details (loans, storage, personal fields); grouped by series, collections “À lire”, “Liste de souhaits”, “Éditions originales”… French field names | |
| [`discogs.luaDoobs`](discogs.luaDoobs) | Records (Discogs) | your [Discogs](https://www.discogs.com) collection read through the official Discogs API with a personal access token: **Artists** and **Records** (every copy of the collection with its folder, rating, media and sleeve condition and notes, and the wantlist), linked, with covers, label, catalog number, format, genres and styles; optional tracklists; actions “Refresh from Discogs” and “Load details from Discogs” | |
| [`open-library-books.luaDoobs`](open-library-books.luaDoobs) | Books | the most read books of an [Open Library](https://openlibrary.org) subject (public API, no account), covers shown from the web; parameters: subject, number of books, mark as read | |

`retro.luaDoobs` is the most complete example of a multi-library database: relations by key, a manual
collection, a smart collection on a link, generated and custom forms, and a saved view.

## BDGest

The first run opens the BDGest sign-in page: sign in and authorize Doobs (scope “lecture”, read only). The
tokens stay in the device’s Keychain (**Settings › Saved credentials**) and are renewed silently, so the
next runs, from this database or another one, do not ask again. BDGest accepts 30 requests per minute and
50 albums per request: about 3 minutes for 2,000 albums and 800 wishlist albums, twice as long with the
complete details. The script shows the page being read and can be cancelled.

The database comes with the action **Refresh from BDGest** (sidebar › **Scripts**, or the database menu): it
reads BDGest again and updates the records in place, by BDGest identifier (and BDGest collection for albums).
Only the BDGest fields are written; your own fields and records are kept. A wishlist album you have bought
becomes owned; an album that left your BDGest collection or wishlist is marked so, never deleted. Doobs shows
the number of records created and modified before applying the changes, after a backup.

Covers are the Bedetheque images (`Couv_<album id>.jpg`), shown from the web and never copied: a few albums
have none. To import the file exported from the website instead (no account access), use
[`imports/bdgest.lua`](../../imports/bdgest.lua).

## Discogs

Create a personal access token on discogs.com (**Settings › Developers › Generate new token**) and paste it in
the parameters: it is kept in the Keychain of the device, never in the database, and reused by the actions
(leave the field empty on the next runs). Discogs accepts 60 requests per minute and 100 records per request:
about 15 seconds for 600 records. Tracklists, country and community rating need one request per release:
tick **Tracklists** at creation (about 1 minute for 60 records), or run **Load details from Discogs** from the
menu of a record.

**Refresh from Discogs** (sidebar › **Scripts**, or the database menu) reads the collection again and updates
the records in place by release ID (one record per copy); a wanted record you have bought becomes owned, a
record that left the collection or the wantlist is marked so, never deleted. Your own fields are kept.

## Wine cellar

Create estates and storage locations first. Each wine record represents a lot with the same wine,
vintage, price and location. Use separate lots when these differ; link each tasting to its wine lot.
Remaining bottles are maintained manually: recording bottles opened at a tasting does not decrement
inventory. Enter drinking-window dates yourself: **Drinking window** shows “Too young” before the first
date, “Drink soon” in the last year, “Past peak” after the second date and “Ready” otherwise, with matching
collections for lots in stock. Automatic rules record **Finished on** when remaining bottles reach 0 and clear
it when the lot is restocked. Wine-lot ratings and individual tasting ratings are
independent. Add bottle photos in Doobs after creation.

## Website directory

Create categories, then select any number of them for a website record. Attach screenshots in Doobs;
the script does not browse, capture or scrape pages. Last-visit dates are maintained manually. Ratings
use five stars, with a separate long-text review. Favorite and review collections exclude archived sites.
