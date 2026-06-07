extends Node

signal request_open_app(app: AppResource)
signal request_close_app(app_id: String)

# Sinal definitivo com os 6 parâmetros exatos que o seu desktop.gd e TimeManager esperam!
signal time_advanced(period: int, days_passed: int, calendar_day: int, calendar_month: String)
signal request_combat(encounter: CombatEncounter)
