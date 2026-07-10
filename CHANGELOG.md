# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow major.minor.hotfix (e.g. 1.2.3).

## [1.1.0] - 2026-07-10

### Added
- Native ModernSpellBook tab integration (`WhatsTrainingUI_MSB.lua`): when
  **TeronModernSpellBook** is installed and loaded, this addon registers its own
  "What's Training" tab inside its frame — same icons, badges, tooltips, and category
  headers as every other tab — instead of overlaying the default Blizzard spellbook.
  The original Blizzard-overlay UI is used unchanged when ModernSpellBook isn't present
  (or if its vanilla-mode toggle, `/msb`, is active for the session).
- `## OptionalDeps: TeronModernSpellBook` in the `.toc`, making the detection order
  explicit (alphabetical load order already guaranteed it either way).

### Changed
- Renamed from `WhatsTraining` to `TeronWhatsTraining` (folder, `.toc`, and the
  `ADDON_LOADED` self-check) to free up the original name for the pre-existing Turtle
  WoW fork, which moved to `TeronWhatsTraining-TW`.
