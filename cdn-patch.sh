#!/bin/sh
# Patches the server to redirect all /assets/* requests to the production CDN.
# Run before `npm run build`.

CDN="https://pokemon-auto-chess.com"
AC="app/app.config.ts"

# Redirect all /assets/* requests to CDN (insert before express.static line)
awk -v cdn="$CDN" '
/app\.use\(express\.static\(clientSrc\)\)/ {
  print "    app.use(\"/assets\", (req, res) => res.redirect(301, \"" cdn "/assets\" + req.url))"
}
{ print }
' "$AC" > "$AC.tmp" && mv "$AC.tmp" "$AC"
