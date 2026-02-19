#!/bin/sh
# Patches gadgets.ts to make all gadgets available at level 0.
# Run before `npm run build`.

sed -i 's/levelRequired: [0-9][0-9]*/levelRequired: 0/' app/core/gadgets.ts

# Default collection filter to "all" instead of "unlockable" so new players see pokemon
sed -i "s/prevState?.filter ?? \"unlockable\"/prevState?.filter ?? \"all\"/" app/public/src/pages/component/collection/pokemon-collection.tsx

# Make getEmotionCost always return 0
sed -i 's/return isShiny ? EmotionCost\[emotion\] \* 3 : EmotionCost\[emotion\]/return 0/' app/config/game/collection.ts

# Replace in-memory and mongo collection guards with default-entry creation
LC="app/rooms/commands/lobby-commands.ts"
awk '
/const pokemonCollectionItem = user\.pokemonCollection\.get\(index\)/ {
  print "      let pokemonCollectionItem = user.pokemonCollection.get(index)"
  next
}
/const shardCollectionItem = user\.pokemonCollection\.get\(shardIndex\)/ {
  print "      let shardCollectionItem = user.pokemonCollection.get(shardIndex)"
  next
}
/if \(!pokemonCollectionItem \|\| !shardCollectionItem\) return/ {
  print "      if (!pokemonCollectionItem) {"
  print "        pokemonCollectionItem = { id: index, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 } as IPokemonCollectionItemMongo"
  print "        user.pokemonCollection.set(index, pokemonCollectionItem)"
  print "      }"
  print "      if (!shardCollectionItem) {"
  print "        shardCollectionItem = { id: shardIndex, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 } as IPokemonCollectionItemMongo"
  print "        user.pokemonCollection.set(shardIndex, shardCollectionItem)"
  print "      }"
  next
}
/const mongoItem = mongoUser\.pokemonCollection\.get\(index\)/ {
  print "      let mongoItem = mongoUser.pokemonCollection.get(index)"
  next
}
/const mongoShardItem = mongoUser\.pokemonCollection\.get\(shardIndex\)/ {
  print "      let mongoShardItem = mongoUser.pokemonCollection.get(shardIndex)"
  next
}
/if \(!mongoItem \|\| !mongoShardItem\) return/ {
  print "      if (!mongoItem) {"
  print "        mongoUser.pokemonCollection.set(index, { id: index, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 })"
  print "        mongoItem = mongoUser.pokemonCollection.get(index)!"
  print "      }"
  print "      if (!mongoShardItem) {"
  print "        mongoUser.pokemonCollection.set(shardIndex, { id: shardIndex, unlocked: Buffer.alloc(5, 0), dust: 0, selectedEmotion: Emotion.NORMAL, selectedShiny: false, played: 0 })"
  print "        mongoShardItem = mongoUser.pokemonCollection.get(shardIndex)!"
  print "      }"
  next
}
{ print }
' "$LC" > "$LC.tmp" && mv "$LC.tmp" "$LC"

# Display infinity symbol for shards in the emotions modal
EM="app/public/src/pages/component/collection/pokemon-emotions-modal.tsx"
sed -i 's/{shards} {t("shards")}/{"∞"} {t("shards")}/' "$EM"

# Make all pokemon display as unlocked and show infinity for dust in collection view
CI="app/public/src/pages/component/collection/pokemon-collection-item.tsx"
sed -i 's/unlocked: isUnlocked/unlocked: true/' "$CI"
sed -i 's/<span>{props.item ? props.item.dust : 0}<\/span>/<span>∞<\/span>/' "$CI"
