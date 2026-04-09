# Project Guidelines

## Code Style
- Prefer small, targeted edits that preserve existing Lua and XML formatting.
- Follow existing Lua naming conventions used throughout manager files:
  - Module globals/constants: `ActionType`, `OOB_MSGTYPE_*`, shared state tables.
  - Locals: prefixed names such as `s*` (string), `n*` (number), `a*` or `t*` (array/table), and `node*` (database node).
- Keep license headers intact in Lua files.
- In XML, preserve tab/anchor structure and use `merge="add"` and `copy="*_base"` patterns when extending existing sheets.

## Architecture
- This workspace is a Fantasy Grounds ruleset plus extensions:
  - `RolemasterClassic.pak/` is the base ruleset.
  - `RMC - Spell Caster.ext/` and `RMC - XP TAB.ext/` are extensions layered on top.
- Use manifests as source of truth for load order and wiring:
  - Base ruleset includes/scripts: `RolemasterClassic.pak/base.xml`.
  - Spell extension manifest: `RMC - Spell Caster.ext/extension.xml`.
  - XP extension manifest: `RMC - XP TAB.ext/extension.xml`.
- Core behavior is split between XML record/window definitions and Lua manager/rules scripts. When changing one side, verify the linked counterpart.

## Build And Test
- There is no local build or automated test harness in this repository.
- Validate changes by consistency checks instead:
  - Ensure new/renamed XML and Lua files are declared in the correct `base.xml` or `extension.xml`.
  - Ensure script names, include paths, and database field names stay consistent.
  - Avoid adding project tooling files unless explicitly requested.

## Conventions
- For action handlers (attack/spell/skill), follow the existing pattern:
  - `onInit` registration
  - OOB notify/handle pairs where needed
  - `performRoll` setup
  - result/modifier handlers
- Prefer existing Fantasy Grounds APIs and patterns already used in the repo (`DB.*`, `ActorManager.*`, `ActionsManager.*`, `OOBManager.*`, `Comm.*`).
- Keep changes scoped to the target ruleset/extension; do not move shared logic across packages unless requested.
- Check load-order-sensitive behavior before changing extension manifests (`loadorder` currently differs across extensions).

## Key Files
- Read these first for context before major edits:
  - `RolemasterClassic.pak/base.xml`
  - `RolemasterClassic.pak/scripts/manager_action_attack.lua`
  - `RolemasterClassic.pak/scripts/manager_combat2.lua`
  - `RolemasterClassic.pak/scripts/rules_constants.lua`
  - `RMC - Spell Caster.ext/scripts/manager_action_basescasting.lua`