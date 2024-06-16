local _, latencyGuard = ...

latencyGuard:RegisterSettings("LatencyGuardDB", {
	{
		key = "enableGuard",
		type = "toggle",
		title = "Enable Latency Guard",
		tooltip = "Enable or disable the latency guard functionality.",
		default = false,
	},
	{
		key = "userWantsFeedback",
		type = "toggle",
		title = "Enable Feedback",
		tooltip = "Enable or disable feedback messages when the SpellQueueWindow is updated.",
		default = false,
	},
	{
		key = "latencyThreshold",
		type = "slider",
		title = "Latency Threshold",
		tooltip = "The minimum change in latency (in ms) required to update the SpellQueueWindow.",
		default = 1,
		minValue = 1,
		maxValue = 50,
		valueStep = 1,
	},
})

latencyGuard:RegisterSettingsSlash("/lg")
