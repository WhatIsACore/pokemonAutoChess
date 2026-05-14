import { Synergy, SynergyArray } from "../types/enum/Synergy"
import { Pkm, PkmFamily } from "../types/enum/Pokemon"

function djb2(s: string): number {
  let h = 5381
  for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
  return h >>> 0
}

function mulberry32(seed: number): () => number {
  return () => {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export function getShuffledSynergy(
  roomSeed: string,
  pkm: Pkm,
  synergy: Synergy
): Synergy {
  const rng = mulberry32(djb2(roomSeed + PkmFamily[pkm]))
  const arr = [...SynergyArray]
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1))
    ;[arr[i], arr[j]] = [arr[j], arr[i]]
  }
  return arr[SynergyArray.indexOf(synergy)]
}
