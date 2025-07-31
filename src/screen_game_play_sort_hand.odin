package game

import "core:sort"
import c "core_game"
import hm "handle_map"


HandSortContext :: struct {
	pile: []c.CardHandle,
	deck: ^c.Deck,
}

hand_sort_len :: proc(it: sort.Interface) -> int {
	ctx := (^HandSortContext)(it.collection)
	return len(ctx.pile)
}


hand_sort_swap :: proc(it: sort.Interface, i, j: int) {
	ctx := (^HandSortContext)(it.collection)
	ctx.pile[i], ctx.pile[j] = ctx.pile[j], ctx.pile[i]
}

hand_sort_less_by_rank :: proc(it: sort.Interface, i, j: int) -> bool {
	ctx := (^HandSortContext)(it.collection)

	card_a := hm.get(ctx.deck, ctx.pile[i])
	card_b := hm.get(ctx.deck, ctx.pile[j])

	return card_a.data.rank > card_b.data.rank
}

hand_sort_less_by_suite :: proc(it: sort.Interface, i, j: int) -> bool {
	ctx := (^HandSortContext)(it.collection)

	card_a := hm.get(ctx.deck, ctx.pile[i])
	card_b := hm.get(ctx.deck, ctx.pile[j])

	if card_a.data.suite != card_b.data.suite {
		return card_a.data.suite < card_b.data.suite
	}
	return card_a.data.rank > card_b.data.rank
}

sort_hand :: proc(data: ^GamePlayData) {
	ctx := HandSortContext {
		pile = data.hand_pile[:],
		deck = &data.run_data.deck,
	}

	sorter: sort.Interface
	sorter.collection = &ctx
	sorter.len = hand_sort_len
	sorter.swap = hand_sort_swap

	switch data.sort_method {
	case .ByRank:
		sorter.less = hand_sort_less_by_rank
		sort.sort(sorter)
	case .BySuite:
		sorter.less = hand_sort_less_by_suite
		sort.sort(sorter)
	}
}
