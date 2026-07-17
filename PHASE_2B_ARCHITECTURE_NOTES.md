# Phase 2B Architecture Review

**Date**: 2026-07-17
**Purpose**: Identify abstraction points before implementing staff web UI to ensure future SOUL/custom system support.

## 1. Spell Data Model

### Current Design

The Spell model (plugin/models/spell.rb) is **system-agnostic**:

```ruby
attribute :branch_key        # Generic branch identifier (e.g., "ceremonial")
attribute :name              # Generic spell name
attribute :description       # Generic spell description
attribute :minimum_skill     # Integer - system-independent requirement
attribute :difficulty        # Integer - system-independent casting difficulty
attribute :approved          # Boolean - approval status
reference :created_by        # Character reference
```

### Data Sources

| Field | Source | System-Specific? |
|-------|--------|------------------|
| `branch_key` | grimoire.yml config | No - generic key, mapped to skills in config |
| `name` | Staff/player input | No |
| `description` | Staff/player input | No |
| `minimum_skill` | Staff input (integer) | No - meaning depends on system |
| `difficulty` | Staff input (integer) | No - meaning depends on system |
| `approved` | Staff approval | No |
| `created_by` | System tracking | No |

### Branch Configuration

**File**: `game/config/grimoire.yml`

```yaml
branches:
  ceremonial:
    name: "Ceremonial Magic"
    fs3_skill: "Ceremonial Magic"  # ← FS3-SPECIFIC
```

**Current Pattern**:
- `branch_key`: Generic identifier (e.g., "ceremonial")
- `name`: Generic display name
- `fs3_skill`: **FS3-specific mapping** - maps branch to FS3 skill name

**Future Pattern** (proposed, not implemented):
```yaml
branches:
  ceremonial:
    name: "Ceremonial Magic"
    fs3_skill: "Ceremonial Magic"      # For FS3 system
    soul_skill: "Wizardry"              # For SOUL system
    custom_skill: "Magic Type 1"        # For custom system
```

## 2. Roll System Boundary

### Current Boundary (FS3-coupled)

```
GrimoireService.cast_spell()
    ↓
    Grimoire.branch_skill()  [returns FS3 skill name from config]
    ↓
    GrimoireService.fs3_rating()
    ↓
    FS3Skills.roll_ability()  [FS3-specific rolling]
    ↓
    FS3Skills.get_success_level()
    ↓
    Scene output
```

**Hard-coded FS3 assumptions** in GrimoireService (lines 130-137):
```ruby
MAGIC_ABILITY = "Magic"
magic_rating = fs3_rating(char, MAGIC_ABILITY)      # ← Assumes "Magic" ability exists
modifier = magic_rating - spell.difficulty.to_i     # ← Assumes numeric modifier model
roll_params = FS3Skills::RollParams.new(skill, modifier)  # ← Assumes RollParams API
die_result = FS3Skills.roll_ability(...)            # ← FS3-specific call
```

### Ideal Future Boundary (abstracted)

```
GrimoireService.cast_spell()
    ↓
    MagicRollAdapter.roll_cast()  [system-agnostic interface]
    ↓
    FS3RollImpl / SOULRollImpl / CustomRollImpl
    ↓
    Scene output
```

**Not implemented yet** - this is a design note for future refactoring.

### What Needs Abstraction

1. **Ability mapping**: Currently hardcoded `MAGIC_ABILITY = "Magic"`
2. **Modifier calculation**: Currently hardcoded `magic_rating - spell.difficulty`
3. **Rolling interface**: Currently calls FS3Skills directly
4. **Success level determination**: Currently uses FS3Skills.get_success_level

## 3. Staff UI Design Requirements

### Phase 2B Will Create

The new staff web interface (grimoire-manage-spells component) will allow staff to:
- Add spells with branch, name, minimum_skill, difficulty, description
- Edit spells
- Delete spells
- Approve/reject proposals

### Naming Constraints ✓ GOOD

The UI components use **generic terminology**:

```handlebars
<label for="spell-branch">Branch *</label>
<label for="spell-min-skill">Min Skill *</label>
<label for="spell-difficulty">Difficulty *</label>
<label for="spell-description">Description *</label>
```

**Not**:
```handlebars
<label>FS3 Magic Skill Rating</label>
<label>FS3 Difficulty Modifier</label>
```

### Potential Phase 2B Pitfalls to Avoid

❌ **Do NOT**:
- Hardcode branch names in Ember route (branches are currently hardcoded in grimoire.js:110-114)
- Make assumptions about how minimum_skill or difficulty are calculated
- Assume FS3-specific validation rules
- Embed skill names or FS3 terminology in UI labels

✓ **DO**:
- Fetch branches from server endpoint
- Treat minimum_skill and difficulty as opaque integers
- Use generic labels: "Minimum Skill", "Difficulty", "Branch"
- Allow future config to specify different systems

### Hardcoded Branch Issue (MUST FIX FOR PHASE 2B)

**Current state** - branches hardcoded in route:
```javascript
controller.set('branches', [
  { key: 'ceremonial', name: 'Ceremonial Magic' },
  { key: 'hedge', name: 'Hedgecraft' },
  { key: 'forbidden', name: 'Forbidden Magic' }
]);
```

**Should be**:
```javascript
// Fetch from server - implement grimoireBranches endpoint
api.requestOne('grimoireBranches')
  .then((response) => {
    controller.set('branches', response.branches);
  })
```

**Server would return**:
```json
{
  "branches": [
    { "key": "ceremonial", "name": "Ceremonial Magic" },
    { "key": "hedge", "name": "Hedgecraft" },
    { "key": "forbidden", "name": "Forbidden Magic" }
  ]
}
```

## 4. Configuration Review

### Current Config (grimoire.yml)

```yaml
grimoire:
  permissions:
    manage: manage_grimoire
  
  branches:
    ceremonial:
      name: "Ceremonial Magic"
      fs3_skill: "Ceremonial Magic"
  
  jobs:
    spell_proposal_category: "Requests"
  
  casting:
    show_roll_details: true
  
  learning:
    xp_cost_per_skill_point: 1
```

### Future Configuration Points (Not Implemented)

**Where system abstraction would connect**:

```yaml
grimoire:
  permissions:
    manage: manage_grimoire
  
  # NEW: Would specify which roll system to use
  magic_system: fs3  # Options: fs3, soul, custom
  
  branches:
    ceremonial:
      name: "Ceremonial Magic"
      
      # FS3 configuration
      fs3_skill: "Ceremonial Magic"
      
      # SOUL configuration (future)
      soul_skill: "Magic"
      
      # Custom configuration (future)
      custom_skill: null
  
  # NEW: Would allow system-specific skill mappings
  skill_mapping:
    magic_ability: "Magic"  # What ability/skill represents magical power?
  
  casting:
    show_roll_details: true
  
  learning:
    xp_cost_per_skill_point: 1
```

**Future hooks** where config would be consulted:
1. `Grimoire.magic_system` - which system to use for rolling
2. `Grimoire.skill_for_branch(branch_key)` - gets skill name based on system
3. `Grimoire.magic_ability_name` - what ability provides the "magic" bonus
4. `RollAdapter.get_implementation(system_name)` - factory for roll implementations

## 5. Player Access Handlers - FS3-Specific Leakage

### Current Issue: Player data includes FS3-specific fields

**File**: plugin/web/grimoire_page_request_handler.rb

```ruby
GrimoireService.available_spells(enactor).map do |s|
  GrimoireService.spell_json(s).merge(
    can_learn: GrimoireService.can_learn_spell?(enactor, s),
    cost: GrimoireService.calculate_learning_cost(s),
    current_xp: GrimoireService.fs3_xp(enactor),           # ← FS3-specific
    current_skill: GrimoireService.fs3_rating(enactor, ...) # ← FS3-specific
  )
end
```

**Impact**: If supporting SOUL, would need to return different field names:
- SOUL: `current_soul_points` instead of `current_xp`
- SOUL: Different skill rating system

**Future solution**: Abstract this in a `CharacterSkillAdapter` or similar, but not for Phase 2B.

## 6. Summary of Architecture

### What's Good ✓
- **Spell model**: System-agnostic (all generic attributes)
- **Configuration**: Separates generic from system-specific (branch = generic, fs3_skill = system-specific)
- **UI terminology**: Uses generic labels (not FS3-specific)
- **Service layer**: Centralizes business logic
- **Permission model**: Configurable (just refactored)

### What Needs Attention ⚠️

**Phase 2B Must Address**:
1. **Hardcoded branches in route** (grimoire.js:110-114)
   - Must fetch from server endpoint
   - Create `grimoireBranches` request handler
   - Severity: **MEDIUM** - blocks future multi-system support

2. **FS3-specific fields in player handlers** (grimoire_page_request_handler.rb)
   - Player data includes `current_xp` and `current_skill` (FS3-specific names)
   - Acceptable for now - document as limitation
   - Severity: **LOW** - future SOUL support can map fields

**Phase 2B May Introduce**:
- Staff UI forms will make assumptions about `minimum_skill` and `difficulty` being integers
- This is fine - they are generic integers, meaning depends on system
- Future systems can repurpose these fields or add new ones

**Future Work (Not Phase 2B)**:
1. Create `MagicRollAdapter` abstraction
2. Implement system-specific roll implementations
3. Fetch branches from server instead of hardcoding
4. Add `magic_system` config option
5. Abstract player data fields for system compatibility

## 7. Warnings for Phase 2B Implementation

### DO ✓
- Use generic form field labels ("Minimum Skill", "Difficulty", not "FS3 Skill Rating")
- Call service methods (GrimoireService) instead of FS3 APIs directly
- Store fields as configured integers without assumptions about meaning
- Implement `grimoireBranches` endpoint to return server-side branch data
- Fetch branches in route instead of hardcoding

### DO NOT ❌
- Reference FS3-specific terminology in UI labels
- Hardcode branch names anywhere in Ember
- Assume skill ratings follow FS3 rating scale (1-5)
- Assume difficulty works like FS3 roll penalties
- Call FS3Skills APIs directly from web handlers
- Add new fields that only make sense for FS3

### Open Questions
- Should minimum_skill validation happen server-side (current) or client-side (proposed)?
  - **Answer**: Keep server-side validation (current approach) for security
- Should difficulty have min/max constraints?
  - **Answer**: Configurable limits, not hardcoded

## 8. Phase 2B Acceptance Criteria

After Phase 2B staff web UI is complete:

- [ ] All staff forms use generic labels (not FS3-specific)
- [ ] Branches are fetched from server (not hardcoded in route)
- [ ] Staff can add/edit/delete spells with branch, name, min_skill, difficulty, description
- [ ] Validation errors are clear and system-agnostic
- [ ] Future systems could add config option for system type without code changes
- [ ] Documentation updated with future roadmap (roll adapter, SOUL support)
- [ ] No new hardcoded FS3 references outside GrimoireService

---

**Next Steps**:
1. Implement Phase 2B staff UI with generic terminology
2. Add `grimoireBranches` endpoint and fetch in route
3. Document this architecture review in README
4. Post-Phase-2B: Plan roll system abstraction for SOUL/custom support
