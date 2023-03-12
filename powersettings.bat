:: Disable hibernation
powercfg -h off

:: Disable specific processes from keeping a wake lock
powercfg -requestsoverride process edge.exe display
powercfg -requestsoverride process discord.exe display
powercfg -requestsoverride process battle.net.exe display
powercfg -requestsoverride process brave.exe display