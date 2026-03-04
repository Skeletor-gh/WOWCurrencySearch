CurrencySearch

CurrencySearch is a lightweight World of Warcraft addon for interface version 12.x.
It adds a small search box to the default Currency tab so you can quickly filter visible entries by name.

Features
- Inline search field on the Currency tab (max 20 characters).
- Built-in clear button from the default search box template.
- Live filtering while typing.
- Addon is enabled by default.
- Slash commands to enable or disable behavior:
  - `/cs on` or `/cs enable`
  - `/cs off` or `/cs disable`

Notes
- The addon only hooks standard Blizzard UI update functions and does not replace currency data.
- When disabled, the search box is hidden and filtering stops.
- No options panel is included by design.

Installation
1. Copy this folder to your WoW AddOns directory:
   `World of Warcraft/_retail_/Interface/AddOns/CurrencySearch`
2. Ensure the folder contains `CurrencySearch.toc` and `CurrencySearch.lua`.
3. Launch the game and enable the addon on the character select AddOns list if needed.

Usage
1. Open the Character window and switch to the Currency tab.
2. Type a currency name fragment (for example: `honor`, `mark`, `timewarped`).
3. Use the clear button in the search box to reset results.
