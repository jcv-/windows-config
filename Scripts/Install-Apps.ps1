$apps = @(
    "7zip.7zip",
    "PuTTY.PuTTY",
    "Starship.Starship",
    "Spotify.Spotify",
    "Microsoft.PowerShell",
    "WinSCP.WinSCP",
    "Microsoft.VisualStudioCode",
    "VideoLAN.VLC",
    "mpv.net",
    "RoyalApps.RoyalTS",
    "Discord.Discord"
)

Foreach ($app in $apps) {
    winget install $app --scope machine
}