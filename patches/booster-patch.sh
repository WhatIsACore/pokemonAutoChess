#!/bin/sh
# Patches lobby-commands.ts to make boosters effectively free.
# Run before `npm run build`.

# Server booster-opening logic lives in app/services/booster.ts (openBoosterForUser)
BS="app/services/booster.ts"

# Remove the booster > 0 check line so users can always open boosters
sed -i '/booster: { \$gt: 0 }/d' "$BS"

# Change $inc: { booster: -1 } to $inc: { booster: 0 } so count never decrements
sed -i 's/\$inc: { booster: -1 }/$inc: { booster: 0 }/' "$BS"

# Make the client always treat booster count as positive so the button stays enabled
BC="app/public/src/pages/component/booster/booster.tsx"
sed -i 's/const numberOfBooster = user ? user.booster : 0/const numberOfBooster = Infinity/' "$BC"
sed -i 's/<span className="booster-count">{numberOfBooster}<\/span>/<span className="booster-count">∞<\/span>/' "$BC"
