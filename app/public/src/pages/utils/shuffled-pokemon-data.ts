import { getShuffledSynergy } from "../../../../core/synergy-shuffle"
import {
  getPokemonData,
  PRECOMPUTED_POKEMONS_DATA
} from "../../../../models/precomputed/precomputed-pokemon-data"
import {
  PRECOMPUTED_POKEMONS_PER_TYPE_AND_CATEGORY
} from "../../../../models/precomputed/precomputed-types-and-categories"
import { IPokemon } from "../../../../types"
import { Rarity } from "../../../../types/enum/Game"
import { Pkm, PkmFamily } from "../../../../types/enum/Pokemon"
import { SpecialGameRule } from "../../../../types/enum/SpecialGameRule"
import { Synergy } from "../../../../types/enum/Synergy"
import { IPokemonData } from "../../../../types/interfaces/PokemonData"

type TypeAndCategory = {
  [key in Synergy]: {
    pokemons: Pkm[]
    uniquePokemons: Pkm[]
    legendaryPokemons: Pkm[]
    additionalPokemons: Pkm[]
    specialPokemons: Pkm[]
  }
}

let cachedSeed: string | null = null
let cachedPerType: TypeAndCategory | null = null

function buildShuffledPerType(roomSeed: string): TypeAndCategory {
  const data: Partial<TypeAndCategory> = {}

  for (const name of Object.values(Pkm)) {
    if (!(name in PRECOMPUTED_POKEMONS_DATA)) continue
    const pokemon = getPokemonData(name)
    const shuffledTypes = pokemon.types.map((t) =>
      getShuffledSynergy(roomSeed, name, t)
    )

    for (const type of shuffledTypes) {
      if (!(type in data)) {
        data[type] = {
          pokemons: [],
          uniquePokemons: [],
          legendaryPokemons: [],
          additionalPokemons: [],
          specialPokemons: []
        }
      }

      if (pokemon.rarity === Rarity.UNIQUE) {
        data[type]!.uniquePokemons.push(name)
      } else if (pokemon.rarity === Rarity.LEGENDARY) {
        data[type]!.legendaryPokemons.push(name)
      } else if (pokemon.rarity === Rarity.SPECIAL) {
        data[type]!.specialPokemons.push(name)
      } else if (pokemon.additional) {
        if (
          !data[type]!.additionalPokemons.some(
            (p) => PkmFamily[p] === PkmFamily[name]
          )
        ) {
          data[type]!.additionalPokemons.push(name)
        }
      } else if (
        !data[type]!.pokemons.some(
          (p) => PkmFamily[p] === PkmFamily[name]
        )
      ) {
        data[type]!.pokemons.push(name)
      }
    }
  }

  // Fill in empty synergies
  for (const syn of Object.values(Synergy)) {
    if (!(syn in data)) {
      data[syn] = {
        pokemons: [],
        uniquePokemons: [],
        legendaryPokemons: [],
        additionalPokemons: [],
        specialPokemons: []
      }
    }
  }

  return data as TypeAndCategory
}

export function getShuffledPokemonData(
  roomSeed: string,
  name: Pkm
): IPokemonData {
  const original = getPokemonData(name)
  return {
    ...original,
    types: original.types.map((t) => getShuffledSynergy(roomSeed, name, t))
  }
}

export function getShuffledPerTypeAndCategory(
  roomSeed: string
): TypeAndCategory {
  if (cachedSeed === roomSeed && cachedPerType) return cachedPerType
  cachedPerType = buildShuffledPerType(roomSeed)
  cachedSeed = roomSeed
  return cachedPerType
}

export function getDisplayPokemonData(
  specialGameRule: SpecialGameRule | null,
  roomSeed: string,
  name: Pkm
): IPokemonData {
  if (specialGameRule === SpecialGameRule.RANDOMIZER) {
    return getShuffledPokemonData(roomSeed, name)
  }
  return getPokemonData(name)
}

export function getDisplayPerTypeAndCategory(
  specialGameRule: SpecialGameRule | null,
  roomSeed: string
): TypeAndCategory {
  if (specialGameRule === SpecialGameRule.RANDOMIZER) {
    return getShuffledPerTypeAndCategory(roomSeed)
  }
  return PRECOMPUTED_POKEMONS_PER_TYPE_AND_CATEGORY
}

// Mutates a Pokemon object's types in-place to show shuffled synergies.
// Safe to call on factory-created pokemon (local objects, not Colyseus-synced).
export function shufflePokemonTypes(
  pokemon: IPokemon,
  specialGameRule: SpecialGameRule | null,
  roomSeed: string | undefined
) {
  if (
    specialGameRule === SpecialGameRule.RANDOMIZER &&
    roomSeed
  ) {
    const types = Array.from(pokemon.types.values()) as Synergy[]
    pokemon.types.clear()
    types.forEach((t) =>
      pokemon.types.add(
        getShuffledSynergy(roomSeed, pokemon.name as Pkm, t)
      )
    )
  }
}
