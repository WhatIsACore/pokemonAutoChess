#!/bin/sh
# Patches the server to redirect all /assets/* requests to the production CDN.
# Run before `npm run build`.

CDN="https://pokemon-auto-chess.com"
AC="app/app.config.ts"

# Redirect all /assets/* requests to CDN
sed -i.bak '/app\.use(express\.static(clientSrc))/i\
    app.use("/assets", (req, res) => res.redirect(301, "'"$CDN"'" + "/assets" + req.url))
' "$AC" && rm -f "$AC.bak"
