#!/bin/sh
# Replaces branding assets with custom versions.
# Run before `npm run build`.

cp patches/assets/scribble.png app/public/src/assets/ui/favicon.ico
cp patches/assets/scribble.png app/public/src/assets/ui/scribble.png

# Change page title
sed -i "s/<title>Pokemon: Auto Chess<\/title>/<title>Smeargle's Auto Chess<\/title>/" app/views/index.html

# Replace login screen logo with scribble.png and keep crisp pixel art edges
sed -i 's|assets/ui/pokemon_autochess_final.svg|assets/ui/scribble.png|' app/public/src/pages/auth.tsx
sed -i 's/object-fit: contain;/object-fit: contain;\n  image-rendering: pixelated;/' app/public/src/pages/auth.css
