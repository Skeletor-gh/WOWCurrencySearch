CurrencySearch
==============

CurrencySearch is a minimal World of Warcraft addon for API 12.x (Midnight era) that adds a small search box to the Currency tab.

Features
--------
- Adds an inline search box to the currency UI.
- Filters currencies in real time while typing.
- Includes a small clear button next to the search box.
- Enabled by default.
- Optional slash command control:
  - `/cs on` or `/cs enable`
  - `/cs off` or `/cs disable`

Behavior and safety notes
-------------------------
- The addon only targets the built-in currency list UI behavior.
- Filtering is active only when the currency frame is visible, the addon is enabled, and the search text is not empty.
- Disabling the addon clears the search text and restores the default list behavior.
- No options panel, no external dependencies, and no gameplay automation.

Files
-----
- `CurrencySearch.toc` addon metadata and load order.
- `CurrencySearch.lua` addon logic and UI.

Usage
-----
1. Open the Character/Currency tab.
2. Type part of a currency name (for example: `honor`, `mark`, `crest`).
3. The list updates immediately to matching entries.
4. Click the `x` button to clear the search.
