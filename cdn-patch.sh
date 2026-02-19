#!/bin/sh
# Patches source files to load heavy assets from the production CDN
# instead of locally. Run before `npm run build`.

CDN="https://pokemon-auto-chess.com"
LM="app/public/src/game/components/loading-manager.ts"
AV="app/utils/avatar.ts"
AU="app/public/src/pages/utils/audio.ts"
AC="app/app.config.ts"

# Phaser loader: insert baseURL and crossOrigin before the xhr.timeout line
sed -i.bak '/scene\.load\.xhr\.timeout/i\
    scene.load.crossOrigin = "anonymous"\
    scene.load.setBaseURL("'"$CDN"'")
' "$LM" && rm -f "$LM.bak"

# Portraits: prefix getAvatarSrc so React <img> tags load from CDN
sed -i.bak 's|return `/assets/portraits/|return `'"$CDN"'/assets/portraits/|' "$AV" && rm -f "$AV.bak"

# Sound effects: prefix HTML5 Audio URLs
sed -i.bak 's|new Audio(`assets/sounds/|new Audio(`'"$CDN"'/assets/sounds/|' "$AU" && rm -f "$AU.bak"

# Redirect all /assets/* requests to CDN (covers React UI icons, items, types, etc.)
sed -i.bak '/app\.use(express\.static(clientSrc))/i\
    app.use("/assets", (req, res) => res.redirect(301, "'"$CDN"'" + "/assets" + req.url))
' "$AC" && rm -f "$AC.bak"
