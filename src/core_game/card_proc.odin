package core_game

import hm "../handle_map"
import "core:math/rand"

new_card :: proc(rank: Rank, suite: Suite) -> CardInstance {
	return CardInstance {
		data = CardData{rank, suite},
		position = {},
		rotation = 0,
		jiggle_timer = 0,
	}
}

init_deck :: proc() -> Deck {
	deck := Deck{}

	for suite in Suite {
		for rank in Rank {
			handle := hm.add(&deck, new_card(rank, suite))
			card := hm.get(&deck, handle)
			card.handle = handle
		}
	}

	return deck
}

init_drawing_pile :: proc(deck: ^Deck, draw_pile: ^Pile) {
	iter := hm.make_iter(deck)

	for _, h in hm.iter(&iter) {
		append(draw_pile, h)
	}

	rand.shuffle(draw_pile[:])
}

draw_cards_into :: proc(from: ^Pile, to: ^Pile, draw_amount: i32) {
	pile_len := i32(len(from))
	max_amount := min(pile_len, draw_amount)

	for i := i32(0); i < max_amount; i += 1 {
		card := pop_safe(from) or_break
		append(to, card)
	}
}

empty_pile :: proc(pile: ^Pile) {
	for len(pile) > 0 {
		_ = pop_safe(pile) or_break
	}
}

handle_array_contains :: proc(pile: []CardHandle, handle: CardHandle) -> bool {
	for h in pile {
		if h == handle {
			return true
		}
	}
	return false
}

handle_array_remove_handle :: proc(pile: ^Pile, handle: CardHandle) -> bool {
	for &h, i in pile[:] {
		if h == handle {
			ordered_remove(pile, i)
			return true
		}
	}
	return false
}
