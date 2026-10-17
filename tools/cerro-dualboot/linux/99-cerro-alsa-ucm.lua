-- WirePlumber: prefer ALSA UCM HiFi on SM8650-CERRO so Speaker/Earpiece ports appear.
-- Install to /etc/wireplumber/main.lua.d/99-cerro-alsa-ucm.lua (WP 0.4)
-- or /etc/wireplumber/wireplumber.conf.d/ for WP 0.5+.

alsa_monitor = alsa_monitor or {}
alsa_monitor.rules = alsa_monitor.rules or {}

table.insert(alsa_monitor.rules, {
  matches = {
    {
      { "device.name", "equals", "alsa_card.platform-sound" },
    },
  },
  apply_properties = {
    ["api.alsa.use-acp"] = true,
    ["api.acp.auto-profile"] = true,
    ["api.acp.auto-port"] = true,
    ["device.profile"] = "HiFi",
  },
})
