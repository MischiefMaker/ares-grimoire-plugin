# Branch Configuration Separation Verification

**Status**: ✓ VERIFIED - Ready for Phase 2B
**Date**: 2026-07-17

## Architecture: IDs vs. Display Names vs. Skills

### Three-Level Separation (Correct)

| Level | Stored In | Example | Mutable? | Notes |
|-------|-----------|---------|----------|-------|
| **Branch ID** | `spell.branch_key` (DB) | `"ceremonial"` | No | Stable identifier, foreign key |
| **Branch Name** | `config.branches.ceremonial.name` | `"Ceremonial Magic"` | Yes | Display text, user-facing |
| **Branch Skill** | `config.branches.ceremonial.skill` | `"Ceremonial Magic"` | Yes | System mapping (FS3/SOUL/custom) |

### Configuration Example

```yaml
branches:
  ceremonial:
    name: "Ceremonial Magic"      # Display name (UI only)
    skill: "Ceremonial Magic"     # Associated skill (for FS3 rolls)
  hedge:
    name: "Hedgecraft"            # Can rename without affecting DB
    skill: "Herbalism"            # Can remap without affecting DB
  forbidden:
    name: "Forbidden Magic"
    skill: "Forbidden Magic"
```

## Verification Results

### ✓ Stored Values
- Spell model uses `branch_key` attribute (not display name)
- Service layer creates spells with `branch_key` parameter
- Database stores IDs: `spell.branch_key = "ceremonial"`
- Not vulnerable to display name changes
- No migration needed for existing spells (if any)

### ✓ Helper Functions (Centralized)

```ruby
Grimoire.branches               # Full config hash
Grimoire.branch_display_name(id)  # "ceremonial" → "Ceremonial Magic"
Grimoire.branch_skill(id)       # "ceremonial" → "Ceremonial Magic"
Grimoire.resolve_branch(name)   # "Ceremonial Magic" → "ceremonial"
```

### ✓ No YAML Parsing Duplication
- Only 2 places read YAML directly:
  1. `Grimoire.branches` method
  2. `Grimoire.check_config` method
- All other code calls these helpers
- No direct `read_config` calls in commands, handlers, or components

### ✓ Spell Display Correctness

**JSON Response Example**:
```json
{
  "id": 1,
  "name": "Ward Against Evil",
  "branch": "Ceremonial Magic",    # Display name (from config)
  "branch_key": "ceremonial",      # Stable ID (from DB)
  "description": "...",
  "minimum_skill": 2,
  "difficulty": 3
}
```

**Web Display**:
- Table shows `spell.branch` (display name)
- Dropdown shows `branch.name` (display name)
- Dropdown uses `branch.key` as value (ID)
- Form sends `branch_key` to server

### ✓ Roll Logic Can Retrieve Skill

```ruby
skill = Grimoire.branch_skill(spell.branch_key)
# "ceremonial" → "Ceremonial Magic"

rating = FS3Skills.ability_rating(char, skill)
# Can adapt to other systems by changing YAML only
```

### ✓ Safe Branch Renaming

**Change**: `ceremonial.name = "Mystical Arts"`

**Result**:
- All existing spells unaffected (stored IDs)
- All displays update automatically
- No data migration
- No code changes

### ✓ Safe Skill Remapping

**Change**: `ceremonial.skill = "Mysticism"`

**Result**:
- All existing spells unaffected (stored IDs)
- All roll logic automatically uses new skill
- No data migration
- No code changes

## Data Flow Examples

### Creating a Spell

```
Web UI → grimoire_add_request_handler
  ↓
  Receives: branch_key: "ceremonial"
  ↓
  Service validates: Grimoire.branches.key?("ceremonial")
  ↓
  Database stores: spell.branch_key = "ceremonial"
  ↓
  JSON response:
    branch: "Ceremonial Magic"      [from config.branches.ceremonial.name]
    branch_key: "ceremonial"         [from spell.branch_key]
```

### Learning a Spell

```
Player learns spell with branch_key "ceremonial"
  ↓
  GrimoireService.can_learn_spell(char, spell)
  ↓
  skill = Grimoire.branch_skill("ceremonial")
  ↓
  rating = FS3Skills.ability_rating(char, "Ceremonial Magic")
  ↓
  Verify: rating >= spell.minimum_skill
```

### Casting a Spell

```
Player casts spell with branch_key "ceremonial"
  ↓
  name = Grimoire.branch_display_name("ceremonial")
    → "Ceremonial Magic"
  ↓
  skill = Grimoire.branch_skill("ceremonial")
    → "Ceremonial Magic"
  ↓
  magic_rating = FS3Skills.ability_rating(char, "Magic")
  ↓
  modifier = magic_rating - spell.difficulty
  ↓
  roll = FS3Skills.roll_ability(char, RollParams.new(skill, modifier))
  ↓
  Output: "PlayerName casts Ward Against Evil (Ceremonial Magic): Success!"
```

## Code Examples

### Commands (Use IDs)
```ruby
class GrimoireAddCmd
  def handle
    result = GrimoireService.create_spell(
      branch_key: self.branch,  # ID from user input
      name: self.name,
      # ...
    )
  end
end
```

### Service Layer (Use Helpers)
```ruby
def self.spell_json(spell)
  {
    id: spell.id,
    branch: Grimoire.branch_display_name(spell.branch_key),  # Display name
    branch_key: spell.branch_key,                             # ID
    # ...
  }
end

def self.cast_spell(char, spell, opts = {})
  skill = Grimoire.branch_skill(spell.branch_key)  # Get skill from config
  rating = fs3_rating(char, skill)
  # ...
end
```

### Web Components (Display Names, Send IDs)
```handlebars
{{#each branches as |branch|}}
  <option value={{branch.key}}>{{branch.name}}</option>
{{/each}}

<!-- Renders: <option value="ceremonial">Ceremonial Magic</option> -->
```

```javascript
this.get('gameApi').requestOne('grimoireAdd', {
  branch_key: branch,  // Send ID, not display name
  name: name,
  // ...
})
```

## Phase 2B Readiness

✓ Branch model is correctly separated (ID/name/skill)
✓ Web UI will receive branches from server (grimoireBranches endpoint)
✓ All forms will use server data (not hardcoded)
✓ Components will display names but send IDs
✓ Helpers prevent YAML parsing duplication
✓ Roll logic can adapt to other systems via config only
✓ No migration or data changes needed

**Status**: Ready to proceed with Phase 2B staff web interface implementation.

## Summary

The branch configuration model correctly separates:
- **IDs** (stable, stored in DB) 
- **Display Names** (configurable, for UI)
- **Skills** (system-mapped, configurable)

Renaming or remapping requires YAML changes only. No code changes or data migrations needed. Web forms receive data from server, not hardcoded. Roll logic retrieves skills via helpers. Architecture is extensible for SOUL/custom systems.
