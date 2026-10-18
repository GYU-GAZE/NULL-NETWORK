# Phase 03 save fixture

`phase03_reserved_combat.json` is the unmodified manual checkpoint produced by `tests/navigator/navigator_activity_contract_test.tscn` while running baseline commit `bb22b8eecfa8d2fd6cd85c9fde645005122b4f84` in an isolated APPDATA directory for this task.

It contains a synthetic acceptance campaign (`navigator_activity`), Navigator session v6, population v2, combat session v2, the original closed 1v1 actor ID and an unpaid two-block voluntary reservation. It contains no real player data. The migration test copies it to its own `user://` storage and uses the real SaveManager and CombatApp to restore and settle it under the one-block Phase 04 rule.
