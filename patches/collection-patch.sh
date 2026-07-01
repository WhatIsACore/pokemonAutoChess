#!/bin/sh
# Patches gadgets.ts to make all gadgets available at level 0.
# Run before `npm run build`.

sed -i 's/levelRequired: [0-9][0-9]*/levelRequired: 0/' app/config/game/gadgets.ts

# Default collection filter to "all" instead of "unlockable" so new players see pokemon
sed -i "s/prevState?.filter ?? \"unlockable\"/prevState?.filter ?? \"all\"/" app/public/src/pages/component/collection/pokemon-collection.tsx

# Make getEmotionCost always return 0
sed -i 's/return isShiny ? EmotionCost\[emotion\] \* 3 : EmotionCost\[emotion\]/return 0/' app/config/game/collection.ts

# Replace collection guards with default-entry creation.
# (collection mutations were moved from lobby-commands.ts into app/services/collection.ts)
CS="app/services/collection.ts"
awk '
/const mongoItem = mongoUser\.pokemonCollection\.get\(index\)/ {
  sub(/const /, "let ")
  print
  next
}
/const mongoShardItem = mongoUser\.pokemonCollection\.get\(shardIndex\)/ {
  sub(/const /, "let ")
  print
  next
}
/if \(!mongoItem\) return null/ {
  print "  if (!mongoItem) {"
  print "    mongoItem = { id: index, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 } as IPokemonCollectionItemMongo"
  print "    mongoUser.pokemonCollection.set(index, mongoItem)"
  print "  }"
  next
}
/if \(!mongoItem \|\| !mongoShardItem\) return null/ {
  print "  if (!mongoItem) {"
  print "    mongoItem = { id: index, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 } as IPokemonCollectionItemMongo"
  print "    mongoUser.pokemonCollection.set(index, mongoItem)"
  print "  }"
  print "  if (!mongoShardItem) {"
  print "    mongoShardItem = { id: shardIndex, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 } as IPokemonCollectionItemMongo"
  print "    mongoUser.pokemonCollection.set(shardIndex, mongoShardItem)"
  print "  }"
  next
}
{ print }
' "$CS" > "$CS.tmp" && mv "$CS.tmp" "$CS"

# Display infinity symbol for shards in the emotions modal
EM="app/public/src/pages/component/collection/pokemon-emotions-modal.tsx"
sed -i 's/{shards} {t("shards")}/{"∞"} {t("shards")}/' "$EM"

# Make all pokemon display as unlocked and show infinity for dust in collection view
CI="app/public/src/pages/component/collection/pokemon-collection-item.tsx"
sed -i 's/unlocked: props.isUnlocked/unlocked: true/' "$CI"
sed -i 's/<span>{props.item?.dust ?? 0}<\/span>/<span>∞<\/span>/' "$CI"
