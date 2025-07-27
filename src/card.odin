package game

import "core:math/rand"
import "core:testing"
import "sds"

Rank :: enum {
	Ace,
	Two,
	Three,
	Four,
	Five,
	Six,
	Seven,
	Eight,
	Nine,
	Ten,
	Jack,
	Queen,
	King,
}

Suite :: enum {
	Heart,
	Diamond,
	Spade,
	Club,
}

SUITES :: [4]Suite{.Heart, .Diamond, .Spade, .Club}
RANKS :: [13]Rank {
	.Ace,
	.Two,
	.Three,
	.Four,
	.Five,
	.Six,
	.Seven,
	.Eight,
	.Nine,
	.Ten,
	.Jack,
	.Queen,
	.King,
}

SuiteString :: [Suite]string {
	.Heart   = "H",
	.Diamond = "D",
	.Spade   = "S",
	.Club    = "C",
}

SuiteColor :: [Suite][4]u8 {
	.Heart   = {235, 52, 52, 255},
	.Diamond = {235, 116, 52, 255},
	.Spade   = {52, 52, 116, 255},
	.Club    = {52, 125, 235, 255},
}

RankString :: [Rank]string {
	.Ace   = "A",
	.Two   = "2",
	.Three = "3",
	.Four  = "4",
	.Five  = "5",
	.Six   = "6",
	.Seven = "7",
	.Eight = "8",
	.Nine  = "9",
	.Ten   = "X",
	.Jack  = "J",
	.Queen = "Q",
	.King  = "K",
}

CardData :: struct {
	rank:  Rank,
	suite: Suite,
}

CardInstance :: struct {
	data:         CardData,
	position:     [2]f32,
	rotation:     f32,
	jiggle_timer: f32,
}


Deck :: sds.Pool(1024, CardInstance, CardHandle)
Pile :: sds.Array(1024, CardHandle)

CardHandle :: distinct sds.Handle(i64, i64)


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

	for suite in SUITES {
		for rank in RANKS {
			sds.pool_push(&deck, new_card(rank, suite))
		}
	}

	return deck
}

init_drawing_pile :: proc(deck: ^Deck) -> Pile {
	draw_pile := Pile{}

	for i in 1 ..= deck.max_index {
		_, handle := sds.pool_index_get_ptr_safe(deck, i) or_continue
		sds.array_push(&draw_pile, handle)
	}

	rand.shuffle(draw_pile.data[:draw_pile.len])

	return draw_pile
}

draw_cards_into :: proc(from: ^Pile, to: ^Pile, draw_amount: i32) {
	pile_len := from.len
	max_amount := min(pile_len, draw_amount)

	for i := i32(0); i < max_amount; i += 1 {
		card := sds.array_pop_back(from)
		sds.array_push(to, card)
	}
}

empty_pile :: proc(pile: ^Pile) {
	for pile.len > 0 {
		_ = sds.array_pop_back_safe(pile) or_break
	}
}

pile_contains :: proc(pile: ^Pile, handle: CardHandle) -> bool {
	for h in pile_slice(pile) {
		if h == handle {
			return true
		}
	}
	return false
}

pile_remove_handle :: proc(pile: ^Pile, handle: CardHandle) -> bool {
	for &h, i in pile_slice(pile) {
		if h == handle {
			sds.array_remove(pile, i)
			return true
		}
	}
	return false
}

pile_slice :: #force_inline proc(p: ^Pile) -> []CardHandle {
	return p.data[:p.len]
}

@(test)
my_test :: proc(t: ^testing.T) {

	deck := init_deck()
	draw_pile := init_drawing_pile(&deck)
	hand := Pile{}

	for draw_pile.len > 0 {
		draw_cards_into(&draw_pile, &hand, 5)
	}
}
