import { SpecialGameRule } from "../types/enum/SpecialGameRule"

export const DEFAULT_MAX_ITEMS = 3

export function getMaxItemCount(
  specialGameRule: SpecialGameRule | null | undefined
): number {
  return specialGameRule === SpecialGameRule.MEGASTACK
    ? Infinity
    : DEFAULT_MAX_ITEMS
}
