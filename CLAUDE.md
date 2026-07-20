# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Grimoire is a plugin for [AresMUSH](https://aresmush.com), a Ruby MUSH game server framework. This repo is not a standalone app — it's installed into a running AresMUSH game (`plugins/grimoire/`) and its web portal (`ares-webportal/`). There is no local build, test, or lint tooling in this repo (no Gemfile, Rakefile, or test suite); AresMUSH core provides the runtime, ORM (Ohm), FS3 skill system, job system, and web request framework that this plugin's code depends on.

Because there's no local way to run or test this code, changes should be verified by careful reading and cross-referencing against how AresMUSH core APIs are used elsewhere in this plugin (e.g. `FS3Skills`, `Jobs`, `Global.read_config`, `Website.check_login`, `ObjectModel`/`Ohm::Model`) rather than by executing anything.

## Architecture

### Three-tier structure, one entry point

`plugin/grimoire.rb` is the plugin's registration point — it requires every file and wires up two dispatch tables:
- `get_cmd_handler` maps `+grimoire/<switch>` command switches to command classes in `plugin/commands/`
- `get_web_request_handler` maps web API request names (e.g. `"grimoireAdd"`) to handler classes in `plugin/web/`

Both MUSH commands and web handlers are thin wrappers that call into `plugin/public/grimoire_api.rb` — **all business logic (validation, permission checks, XP/skill math, spell CRUD, proposal workflow) lives in `GrimoireApi`**. When adding a new operation, add it to the API class first, then add a command and/or web handler that calls it. Never duplicate validation or game-state logic in a command or handler.

### Branch configuration: ID vs. display name vs. skill

Magic "branches" (schools of magic) have a three-level separation that must be preserved:

- **Branch key** (`spell.branch_key`, e.g. `"ceremonial"`) — stable identifier stored in the DB, referenced in code/args. Never changes.
- **Branch display name** (`grimoire.yml` → `branches.<key>.name`) — user-facing text, editable anytime with no data migration.
- **Branch skill** (`grimoire.yml` → `branches.<key>.skill`) — the FS3 skill name used for rolls, also editable anytime.

Always go through the helpers in `plugin/grimoire.rb` (`Grimoire.branches`, `Grimoire.branch_display_name`, `Grimoire.branch_skill`, `Grimoire.resolve_branch`) rather than reading `Global.read_config('grimoire', ...)` directly elsewhere — those two methods are the only places YAML config should be parsed for branches.

### Config-driven, not code-driven

`game/config/grimoire.yml` controls branches, staff permission name (`permissions.manage`, checked via `GrimoireApi.can_manage?`), XP cost per skill point, proposal job category, and whether roll details are shown on cast. Adding a branch or renaming one is a YAML-only change — don't hardcode branch lists in Ruby or in the Ember webportal (`webportal/app/routes/grimoire.js` fetches branches from the `grimoireBranches` endpoint rather than hardcoding them, and any new UI should follow that pattern).

### System-agnostic naming

`minimum_skill` and `difficulty` on `Spell`/`SpellProposal` are generic integers — their FS3-specific meaning (skill rating thresholds, roll penalties) is confined to `GrimoireApi`. UI labels and web JSON should stay generic ("Minimum Skill", not "FS3 Skill Rating") so the plugin can support non-FS3 systems (SOUL, custom) later without a data model change. See `PHASE_2B_ARCHITECTURE_NOTES.md` for the specific FS3 coupling points (`GrimoireApi::MAGIC_ABILITY`, `fs3_rating`, `fs3_xp`) that would need a `MagicRollAdapter`-style abstraction if a second system is ever added — this is documented, not implemented.

### Proposal workflow rides on the Jobs system

Player-submitted spells (`GrimoireApi.create_proposal`) create an AresMUSH `Job` plus a local `SpellProposal` record (job_id, branch_key, name, description, minimum_skill, difficulty). Approval (`approve_proposal`) creates the real `Spell` via `create_spell` and closes the job; rejection just closes the job with a reason. `SpellProposal` rows are deleted once resolved either way — they're a staging area, not permanent history.

### Web handlers

Every handler in `plugin/web/` follows the same shape: `Website.check_login(request)`, then a `GrimoireApi.can_manage?` permission check for staff-only endpoints, then `request.log_request`, then delegate to `GrimoireApi` and return `{ success:, spell: }`/`{ error: }`-shaped hashes (using `GrimoireApi.spell_json` for spell serialization). Match this shape for new handlers.

### Ember webportal

`webportal/app/` is a set of files meant to be copied into a separate `ares-webportal` checkout (see README "Installation" for the exact file mapping) — it is not built or run from this repo. It's plain Ember (no React). `routes/grimoire.js` fetches branches and staff-only data server-side; components (`grimoire-learn-spell`, `grimoire-cast-spell`, `grimoire-propose-spell`, `grimoire-manage-spells`, `grimoire-manage-proposals`) each pair a `.js` component with a `.hbs` template.

**Known gotcha**: Avoid `{{#with}}` blocks around properties that are loaded asynchronously (e.g., after a `gameApi` fetch). On some Ember versions this causes `resolvedDefinition is null` crashes. Use direct property access instead (`this.detail.foo` rather than `{{#with this.detail as |detail|}}...{{detail.foo}}`). This affects components that set properties after API calls resolve.

### Localization

All user-facing strings go through `t('grimoire.<key>', ...)` with definitions in `plugin/locales/en.yml` — don't inline strings in commands/services/handlers.

## Reference docs in this repo

- `README.md` — end-user/installer facing docs: installation, configuration, command reference, FS3 requirements.
- `PHASE_2B_ARCHITECTURE_NOTES.md` / `BRANCH_CONFIGURATION_VERIFICATION.md` — design rationale for the branch ID/name/skill separation and notes on what a future multi-system (SOUL/custom) refactor would require. Read these before changing branch config handling or FS3 coupling.
- `HANDOFF.md` — snapshot of in-progress work state from a prior session; useful for picking up context but not authoritative about current repo state — verify against actual code/git history first.

## External reference

For Ares plugin development conventions, patterns, and lessons learned across multiple plugins, see the authoritative guide:
- [ARES_PLUGIN_DEVELOPMENT_GUIDE.md](https://github.com/MischiefMaker/ares-inklings-plugin/blob/main/ARES_PLUGIN_DEVELOPMENT_GUIDE.md) in the ares-inklings-plugin repo

## Git workflow

Always commit and push completed work to the current branch on the GitHub remote unless explicitly told not to. Don't leave finished changes only in the local checkout.
