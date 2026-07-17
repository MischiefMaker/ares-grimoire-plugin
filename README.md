# Grimoire

Grimoire is a plugin for [AresMUSH](https://aresmush.com) that provides a complete magic system with spell learning, casting, and staff management. Players can learn spells through an XP-based system, cast spells in scenes, and propose new spells to staff. Staff can manage spells, approve player proposals, and customize magic branches.

## Status

This plugin is complete and fully supported.

## Overview

### For Players

Grimoire gives you a magical toolkit to develop your character through gameplay:

- **Learn Spells** — Spend XP to learn spells based on your skill in a magical branch
- **Cast Spells** — Use learned spells in scenes; rolls use your skill and the Magic ability
- **Propose Spells** — Submit new spell ideas to staff for review through the job system
- **Track Progress** — The web portal shows all learned spells and available spells you can learn
- **Multiple Branches** — Choose from different schools of magic (configurable: Ceremonial, Hedgecraft, Forbidden Magic, or your own)

### For Staff

Grimoire gives staff full control over the magic system:

- **Manage Spells** — Create, edit, and delete spells directly without restarting the game
- **Review Proposals** — Players submit spell ideas as jobs; approve or reject with feedback
- **Configure Everything** — Define magic branches, skill costs, difficulty, and minimum requirements in YAML
- **Customize Permission** — Use your existing staff permission system or create a new one
- **No Code Changes** — Add new branches or spells by editing the configuration file only

### Key Features

- **Configurable Magic Branches** — Define your own branches (schools of magic) with names and associated skills
- **Skill-Based Learning** — Players must have sufficient skill rating to learn a spell
- **XP-Based Progression** — Learning spells costs XP, configurable per branch
- **FS3 Integration** — Uses FS3 skills and rolls; includes Magic ability bonus in casting rolls
- **Player Proposals** — Players suggest spells through a structured job-based workflow
- **Staff Approval Workflow** — Approve or request changes on proposed spells
- **Web Portal Integration** — Full Ember interface for learning, casting, and managing spells
- **Scene Integration** — Optionally add cast spells directly to scene output from the web portal

## Installation

### Step 1: Install Plugin

From the MUSH, run:

```
plugin/install https://github.com/MischiefMaker/ares-grimoire-plugin
```

This installs the plugin code to `plugins/grimoire/` and creates `game/config/grimoire.yml`.

Restart your game: `@restart`

### Step 2: Install Web Portal Components

Copy the web portal files into your `ares-webportal` directory, preserving paths:

| From this plugin | To your ares-webportal |
|---|---|
| `webportal/app/routes/grimoire.js` | `app/routes/grimoire.js` |
| `webportal/app/templates/grimoire.hbs` | `app/templates/grimoire.hbs` |
| `webportal/app/components/grimoire-*.js` | `app/components/grimoire-*.js` |
| `webportal/app/components/grimoire-*.hbs` | `app/templates/components/grimoire-*.hbs` |

Add the Grimoire route to your `ares-webportal/app/custom-routes.js`:

```javascript
router.route('grimoire');
```

Restart your web portal.

### Step 3: Configure the Plugin

Edit `game/config/grimoire.yml` to customize branches, permissions, and costs. See Configuration section below.

### Step 4: Set Up Job Category (Optional)

If you want players to submit spell proposals (recommended), set up the job category:

```
job/createcategory GRIMOIRE
job/categoryroles GRIMOIRE=<staff roles>
```

## Configuration

Edit `game/config/grimoire.yml` to customize the magic system. Default configuration includes three example branches.

### Magic Branches

Define what types of magic players can learn. Each branch requires a name and an associated skill:

```yaml
branches:
  ceremonial:
    name: "Ceremonial Magic"
    skill: "Ceremonial Magic"
  hedge:
    name: "Hedgecraft"
    skill: "Hedgecraft"
  forbidden:
    name: "Forbidden Magic"
    skill: "Forbidden Magic"
```

- **Branch ID** (the key like `ceremonial`) — Stable identifier; don't change after spells are created
- **name** — Display name shown to players; can be changed anytime
- **skill** — The FS3 skill required for this branch; can be changed anytime

You can add as many branches as you like. Changes take effect immediately without restarting.

### Spell Learning Costs

Configure XP cost for learning spells:

```yaml
learning:
  xp_cost_per_skill_point: 1
```

When a player learns a spell, the cost is: `minimum_skill × xp_cost_per_skill_point`

### Spell Casting

Configure what details are shown when spells are cast:

```yaml
casting:
  show_roll_details: true
```

If true, players see the dice roll details. If false, only the success message displays.

### Job Category for Proposals

Set where spell proposals appear:

```yaml
jobs:
  spell_proposal_category: "Requests"
```

### Staff Permission

Configure which permission is required for staff-only actions:

```yaml
permissions:
  manage: manage_grimoire
```

You can use any existing permission (e.g., `manage_apps`, `manage_jobs`). Default is `manage_grimoire`.

## Commands

### Player Commands

| Command | Purpose |
|---------|---------|
| `+grimoire` | List learned spells and available spells |
| `+grimoire <id>` | Show details of a specific spell |
| `+grimoire/learn <id>` | Learn a spell (costs XP) |
| `+grimoire/cast <id>` | Cast a learned spell (uses FS3 roll) |
| `+grimoire/propose <branch>=<name>/<min>/<diff>/<desc>` | Submit a new spell idea to staff |

**Examples:**

```
+grimoire                                           # List all spells
+grimoire/learn 3                                   # Learn spell ID 3
+grimoire/cast 1                                    # Cast spell ID 1
+grimoire/propose ceremonial=Fireball/2/3/A blast of flame  # Propose spell
```

### Staff Commands

| Command | Purpose |
|---------|---------|
| `+grimoire/add <branch>=<name>/<min>/<diff>/<desc>` | Create a new spell immediately |
| `+grimoire/edit <id>=<name>/<min>/<diff>/<desc>` | Edit an existing spell |
| `+grimoire/delete <id>` | Delete a spell |
| `+grimoire/approve <job_id>` | Approve a spell proposal and create the spell |
| `+grimoire/reject <job_id>=<reason>` | Reject a proposal with feedback |

**Examples:**

```
+grimoire/add ceremonial=Ward Against Evil/1/2/Protects against evil spirits
+grimoire/edit 5=Ward/2/3/Updated description
+grimoire/delete 8
+grimoire/approve 123
+grimoire/reject 124=Difficulty too high; suggest reducing to 2
```

## Web Portal

The Grimoire tab provides a modern interface for all spell operations.

### Player Features

- **Learned Spells Tab** — View all spells you've learned with their details
- **Available Spells Tab** — Browse spells you can learn; see XP cost and skill requirements
- **Propose Spell Tab** — Submit new spell ideas using a form (no command syntax needed)
- **Cast Spells** — In a scene, open your learned spells and cast with one click

### Staff Features

- **Manage Spells Tab** — Create, edit, and delete spells using forms
- **Manage Proposals Tab** — Review player-submitted spells; approve or reject with feedback

All staff features appear only if your character has the configured permission.

## How It Works

### Learning Spells

When you learn a spell:

1. You must have enough XP in your character pool
2. Your skill in that branch must be at least the spell's minimum requirement
3. The XP cost is deducted from your character
4. You can now cast that spell

### Casting Spells

When you cast a spell:

1. You must know the spell (have learned it)
2. An FS3 roll is made using the branch skill
3. Your Magic ability rating modifies the roll (bonus)
4. The spell's difficulty modifies the roll (penalty)
5. Success is determined and a message is generated
6. The message is optionally added to the scene

**Example roll:**
```
Skill: Ceremonial Magic (3)
Magic Ability: 4
Spell Difficulty: 2
Roll Result: Ceremonial Magic roll with +4 modifier (4-2 adjusted by difficulty)
```

### Proposing Spells

When you propose a spell:

1. You submit the spell details through the `+grimoire/propose` command or web form
2. A job is created in the configured category
3. Staff can see your proposal and all the details in one place
4. Staff either approve (creating the spell) or request changes
5. You receive feedback through the job system

### Staff Approval

When staff approve a proposal:

1. The spell is created with all details from the proposal
2. The job is closed with an approval message
3. The player is notified through the job system

## Customization

### Adding Branches

Add a new branch to `game/config/grimoire.yml`:

```yaml
branches:
  transmutation:
    name: "Transmutation"
    skill: "Transmutation"
```

The branch is immediately available for new spells and proposals. No restart needed.

### Changing Branch Names

Edit the `name` in the configuration:

```yaml
branches:
  ceremonial:
    name: "Ritual Magic"  # Changed from "Ceremonial Magic"
```

All spell displays update immediately. No data migration needed.

### Adding Spells via Command

Staff can create spells using the command (no configuration edit needed):

```
+grimoire/add ceremonial=Fireball/2/3/Shoot a ball of flame at an enemy
```

Or use the web portal Manage Spells tab for a friendlier form interface.

## FS3 Requirements

This plugin requires FS3 to be installed. Your FS3 configuration must include:

1. A "Magic" ability (the modifier for spell casting)
2. One skill per branch (the skill level required to learn/cast)

**Example FS3 configuration:**

```yaml
abilities:
  magic: 4

skills:
  ceremonial_magic: 4
  hedgecraft: 3
  forbidden_magic: 5
```

Each branch in your grimoire.yml should reference one of these skills.

## Future Enhancements

This plugin uses FS3 for rolling. In the future, it will support alternative magic systems like SOUL or custom systems without requiring code changes — just configuration.

## Troubleshooting

**Players can't learn spells:**
- Check they have enough XP
- Check their skill rating meets the minimum requirement
- Verify the spell exists and is approved

**Staff commands not working:**
- Verify you have the configured permission (default: `manage_grimoire`)
- Check the permission is assigned to your role

**Web portal not showing Grimoire tab:**
- Confirm you've added `router.route('grimoire');` to `custom-routes.js`
- Restart the web portal after adding the route
- Verify all component files are copied correctly

## License

Same as [AresMUSH](https://aresmush.com/license).
