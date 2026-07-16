# Grimoire Plugin

A magic system plugin for AresMUSH with spell learning, FS3-based casting, and web portal integration.

## Features

- Configurable magic branches via YAML
- Ohm/Redis database models (Spell, SpellProposal, CharacterSpellLearned) with reference associations
- Per-switch command classes following AresMUSH dispatch conventions
- FS3-based casting using the Magic ability and branch skills with difficulty modifiers
- Spell learning with configurable XP costs
- Player spell proposals via the Ares Jobs system
- Staff approval/rejection of proposals via Jobs API
- Web portal page for browsing and learning spells
- Web portal Cast Spell modal for scene play menus

## Installation

1. In your game shell, run: `plugin/install https://github.com/YOURNAME/ares-grimoire-plugin`
2. Restart the game.

## Repository Structure

```
ares-grimoire-plugin/
    README.md
    plugin/
        grimoire/
            grimoire.rb
            commands/
                grimoire_list_cmd.rb
                grimoire_learn_cmd.rb
                grimoire_cast_cmd.rb
                grimoire_propose_cmd.rb
                grimoire_add_cmd.rb
                grimoire_edit_cmd.rb
                grimoire_delete_cmd.rb
                grimoire_approve_cmd.rb
                grimoire_reject_cmd.rb
            help/
                grimoire.txt
                admin/
                    managing_grimoire.txt
            locales/
                en.yml
            models/
                spell.rb
                spell_proposal.rb
                character_spell_learned.rb
            public/
                grimoire_api.rb
            services/
                grimoire_service.rb
            web/
                grimoire_page_request_handler.rb
                grimoire_spells_request_handler.rb
                grimoire_available_request_handler.rb
                grimoire_learned_request_handler.rb
                grimoire_learn_request_handler.rb
                grimoire_cast_request_handler.rb
    game/
        config/
            grimoire.yml
    webportal/
        app/
            components/
                grimoire-cast-spell.hbs
                grimoire-cast-spell.js
                grimoire-learn-spell.hbs
                grimoire-learn-spell.js
            routes/
                grimoire.js
            templates/
                grimoire.hbs
```

## Configuration

Configuration is in `game/config/grimoire.yml`:

- **branches** - Magic branches with display names and FS3 skill mappings
- **jobs** - Spell proposal category (defaults to the Jobs request_category)
- **casting** - Roll detail visibility
- **learning** - XP cost per skill point

### Branches

Each branch must specify:
- `name` - Display name shown to players
- `fs3_skill` - The FS3 action skill used for casting and learning

Branches are stored as configurable keys (e.g., `ceremonial`), not display names.

### FS3 Setup

The plugin requires a "Magic" ability in your FS3 skills configuration. Casting rolls the branch skill with the Magic ability rating as a bonus modifier and the spell difficulty as a penalty.

Ensure your FS3 config includes:
- A "Magic" action skill
- One action skill per configured branch (e.g., "Ceremonial Magic", "Hedgecraft", "Forbidden Magic")

## Commands

### Player Commands
- `+grimoire` - List learned spells and the full catalogue
- `+grimoire <branch>` - List spells in a branch
- `+grimoire <id>` - Show a spell's details
- `+grimoire/learn <id>` - Learn a spell (costs XP)
- `+grimoire/cast <id>` - Cast a learned spell
- `+grimoire/propose <branch>=<name>/<min>/<diff>/<desc>` - Propose a spell

### Staff Commands
- `+grimoire/add <branch>=<name>/<min>/<diff>/<desc>` - Add a spell directly
- `+grimoire/edit <id>=<name>/<min>/<diff>/<desc>` - Edit a spell
- `+grimoire/delete <id>` - Delete a spell
- `+grimoire/approve <job id>` - Approve a spell proposal
- `+grimoire/reject <job id>=<reason>` - Reject a spell proposal

Staff commands require admin access or the 'manage_grimoire' permission.

## Spell Proposal Workflow

Players propose spells with `+grimoire/propose`. This creates a standard Ares Job in the configured request category. The Job is the source of truth for proposal status — the Grimoire plugin stores only enough metadata to identify the proposal and create the spell later.

### Approving a Proposal

Staff approve with `+grimoire/approve <job id>`:

1. Finds the Job using the Jobs API (`Job[id]`)
2. Verifies it is a Grimoire spell proposal (via SpellProposal lookup)
3. Creates the spell (marked approved)
4. Closes the Job with an approval comment via `Jobs.close_job`
5. Removes the proposal metadata

Duplicate approval is prevented: if the proposal has already been processed or a spell with that name already exists, the command fails.

### Rejecting a Proposal

Staff reject with `+grimoire/reject <job id>=<reason>`:

1. Finds the Job using the Jobs API
2. Verifies it is a Grimoire spell proposal
3. Closes the Job with the rejection reason via `Jobs.close_job`
4. Removes the proposal metadata
5. No spell is created

## FS3 Integration

Casting uses the standard FS3 Skills API:
- Ability rating: `FS3Skills.ability_rating(char, ability)`
- XP: `char.fs3_xp` and `FS3Skills.modify_xp(char, -amount)`
- Rolling: `FS3Skills.roll_ability(char, RollParams)`
- Success level: `FS3Skills.get_success_level(die_result)`
- Success title: `FS3Skills.get_success_title(success_level)`
- Dice display: `FS3Skills.print_dice(die_result)`

The roll uses the branch skill as the primary ability, with the Magic ability rating as a positive modifier and the spell difficulty as a negative modifier.

## Web Portal

The web portal integration includes:
- A Grimoire page at `/grimoire` showing learned and available spells
- A Cast Spell component for scene play menus
- A Learn Spell component

### Adding the Grimoire Route

Add this to your `ares-webportal/app/custom-routes.js`:

```javascript
router.route('grimoire');
```

### Adding Cast Spell to the Scene Play Menu

To add a "Cast Spell" button to the scene play menu, edit your `ares-webportal/app/templates/components/scene-play-menu.hbs` and add a menu item that opens the `grimoire-cast-spell` component in a modal. Pass the current scene ID as `sceneId` so the cast result is added to the scene.

The web portal components use the AresMUSH GameApi service with these request commands:
- `grimoirePage` - Fetch learned and available spells for the Grimoire page
- `grimoireSpells` - Fetch castable (learned) spells
- `grimoireLearn` - Learn a spell (args: spell_id)
- `grimoireCast` - Cast a spell (args: spell_id, scene_id)

## Permissions

Staff commands require admin access or the 'manage_grimoire' permission. To grant non-admins access, add 'manage_grimoire' to the appropriate roles in your game's permissions configuration.
