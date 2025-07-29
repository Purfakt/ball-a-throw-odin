package game

import "core:math/rand"
import "core:slice"
import "core:testing"
import hm "handle_map"

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

HandType :: enum {
	None,
	HighCard,
	Pair,
	TwoPair,
	ThreeOfAKind,
	Straight,
	Flush,
	FullHouse,
	FourOfAKind,
	StraightFlush,
	RoyalFlush,
	FiveOfAKind,
	FlushHouse,
	FlushFive,
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

Hands :: enum {
	FlushFive,
	FlushHouse,
	FiveOfAKind,
	RoyalFlush,
	StraightFlush,
	FourOfAKind,
	FullHouse,
	Flush,
	Straight,
	ThreeOfAKind,
	TwoPair,
	Pair,
	HighCard,
	None,
}

SuiteString := [Suite]string {
	.Heart   = "H",
	.Diamond = "D",
	.Spade   = "S",
	.Club    = "C",
}

SuiteColor := [Suite][4]u8 {
	.Heart   = {235, 52, 52, 255},
	.Diamond = {235, 116, 52, 255},
	.Spade   = {52, 52, 116, 255},
	.Club    = {52, 125, 235, 255},
}

RankValue := [Rank]u8 {
	.Ace   = 1,
	.Two   = 2,
	.Three = 3,
	.Four  = 4,
	.Five  = 5,
	.Six   = 6,
	.Seven = 7,
	.Eight = 8,
	.Nine  = 9,
	.Ten   = 10,
	.Jack  = 11,
	.Queen = 12,
	.King  = 13,
}

RankChip := [Rank]u8 {
	.Ace   = 10,
	.Two   = 2,
	.Three = 3,
	.Four  = 4,
	.Five  = 5,
	.Six   = 6,
	.Seven = 7,
	.Eight = 8,
	.Nine  = 9,
	.Ten   = 10,
	.Jack  = 10,
	.Queen = 10,
	.King  = 10,
}

RankString := [Rank]string {
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

HandString := [HandType]string {
	.None          = "",
	.HighCard      = "High Card",
	.Pair          = "Pair",
	.TwoPair       = "Two Pair",
	.ThreeOfAKind  = "Three of a Kind",
	.Straight      = "Straight",
	.Flush         = "Flush",
	.FullHouse     = "Full House",
	.FourOfAKind   = "Four of a Kind",
	.StraightFlush = "Straight Flush",
	.RoyalFlush    = "Royal Flush",
	.FiveOfAKind   = "Five of a Kind",
	.FlushHouse    = "Flush House",
	.FlushFive     = "Flush Five",
}

HandChip := [HandType]u8 {
	.None          = 0,
	.HighCard      = 5,
	.Pair          = 10,
	.TwoPair       = 20,
	.ThreeOfAKind  = 30,
	.Straight      = 30,
	.Flush         = 35,
	.FullHouse     = 40,
	.FourOfAKind   = 60,
	.StraightFlush = 100,
	.RoyalFlush    = 100,
	.FiveOfAKind   = 120,
	.FlushHouse    = 140,
	.FlushFive     = 160,
}

HandMult := [HandType]u8 {
	.None          = 0,
	.HighCard      = 1,
	.Pair          = 2,
	.TwoPair       = 2,
	.ThreeOfAKind  = 3,
	.Straight      = 4,
	.Flush         = 4,
	.FullHouse     = 4,
	.FourOfAKind   = 7,
	.StraightFlush = 8,
	.RoyalFlush    = 8,
	.FiveOfAKind   = 12,
	.FlushHouse    = 14,
	.FlushFive     = 16,
}

CardData :: struct {
	rank:  Rank,
	suite: Suite,
}

CardInstance :: struct {
	handle:       CardHandle,
	data:         CardData,
	position:     [2]f32,
	rotation:     f32,
	jiggle_timer: f32,
}

Deck :: hm.Handle_Map(CardInstance, CardHandle, 1024)
Pile :: [dynamic]CardHandle

CardHandle :: distinct hm.Handle

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

handle_array_contains :: proc(pile: Pile, handle: CardHandle) -> bool {
	for h in pile[:] {
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

contains_rank :: proc(cards: []CardData, rank: Rank) -> bool {
	ranks := slice.mapper(cards, proc(card: CardData) -> Rank {return card.rank})
	defer delete(ranks)
	return slice.contains(ranks, rank)
}

contains_flush :: proc(cards: []CardData) -> bool {
	if len(cards) != 5 {
		return false
	}
	suite := cards[0].suite
	for card in cards {
		if card.suite != suite {return false}
	}
	return true
}

contains_straight :: proc(cards: []CardData) -> bool {
	if len(cards) < 5 {
		return false
	}

	ranks := slice.mapper(cards, proc(card: CardData) -> u8 {return RankValue[card.rank]})
	defer delete(ranks)

	slice.sort(ranks)
	unique_ranks := slice.unique(ranks)

	if len(unique_ranks) < 5 {
		return false
	}

	is_normal_straight := unique_ranks[4] - unique_ranks[0] == 4

	is_ace_high_straight :=
		unique_ranks[0] == 1 &&
		unique_ranks[1] == 10 &&
		unique_ranks[2] == 11 &&
		unique_ranks[3] == 12 &&
		unique_ranks[4] == 13

	return is_normal_straight || is_ace_high_straight
}

same_rank_amount :: proc(cards: []CardData) -> (u8, u8) {
	ranks := slice.mapper(cards, proc(card: CardData) -> Rank {return card.rank})
	defer delete(ranks)
	slice.sort(ranks)

	groups: [dynamic]u8
	defer delete(groups)

	i := 0
	for i < len(ranks) {
		current_rank := ranks[i]
		count: u8 = 1

		j := i + 1
		for j < len(ranks) && ranks[j] == current_rank {
			count += 1
			j += 1
		}

		if count > 1 {
			append(&groups, count)
		}

		i += int(count)
	}

	slice.sort_by(groups[:], proc(a, b: u8) -> bool {return a > b})

	major_group: u8 = 0
	minor_group: u8 = 0

	if len(groups) > 0 {major_group = groups[0]}
	if len(groups) > 1 {minor_group = groups[1]}

	return major_group, minor_group
}

EvaluatedHand :: struct {
	hand_type:       HandType,
	scoring_handles: Pile,
}


evaluate_hand :: proc(cards: []CardInstance) -> (hand: EvaluatedHand, ok: bool) {
	if len(cards) < 1 || len(cards) > 5 {
		return {}, false
	}

	data := slice.mapper(cards, proc(i: CardInstance) -> CardData {return i.data})
	defer delete(data)

	ok = true
	hand.hand_type = .HighCard

	group_1, group_2 := same_rank_amount(data)
	is_flush := contains_flush(data)
	is_straight := contains_straight(data)

	if group_1 == 5 && is_flush {hand.hand_type = .FlushFive
	} else if is_flush && group_1 == 3 && group_2 == 2 {
		hand.hand_type = .FlushHouse
	} else if group_1 == 5 {
		hand.hand_type = .FiveOfAKind
	} else if is_flush && is_straight {
		if contains_rank(data, .Ace) && contains_rank(data, .King) {
			hand.hand_type = .RoyalFlush
		} else {
			hand.hand_type = .StraightFlush
		}
	} else if group_1 == 4 {
		hand.hand_type = .FourOfAKind
	} else if group_1 == 3 && group_2 == 2 {
		hand.hand_type = .FullHouse
	} else if is_flush {
		hand.hand_type = .Flush
	} else if is_straight {
		hand.hand_type = .Straight
	} else if group_1 == 3 {
		hand.hand_type = .ThreeOfAKind
	} else if group_1 == 2 {
		if group_2 == 2 {
			hand.hand_type = .TwoPair
		} else {
			hand.hand_type = .Pair
		}
	}

	#partial switch hand.hand_type {
	case .Straight, .Flush, .StraightFlush, .RoyalFlush, .FullHouse, .FlushHouse, .FlushFive:
		for card in cards {
			append(&hand.scoring_handles, card.handle)
		}
	case .HighCard:
		slice.sort_by(
			cards[:],
			proc(lhs, rhs: CardInstance) -> bool {return lhs.data.rank > rhs.data.rank},
		)
		append(&hand.scoring_handles, cards[0].handle)
	case:
		rank_counts := make(map[Rank]u8)
		defer delete(rank_counts)
		for card in data {rank_counts[card.rank] += 1}

		scoring_ranks: [dynamic]Rank
		defer delete(scoring_ranks)

		#partial switch hand.hand_type {
		case .Pair:
			for r, c in rank_counts {if c >= 2 {append(&scoring_ranks, r)}}
		case .TwoPair:
			for r, c in rank_counts {if c >= 2 {append(&scoring_ranks, r)}}
		case .ThreeOfAKind:
			for r, c in rank_counts {if c >= 3 {append(&scoring_ranks, r)}}
		case .FourOfAKind:
			for r, c in rank_counts {if c >= 4 {append(&scoring_ranks, r)}}
		case .FiveOfAKind:
			for r, c in rank_counts {if c >= 5 {append(&scoring_ranks, r)}}
		}

		for card in cards {
			if slice.contains(scoring_ranks[:], card.data.rank) {
				append(&hand.scoring_handles, card.handle)
			}
		}
	}


	return
}

@(test)
test_draw :: proc(t: ^testing.T) {
	deck := init_deck()

	draw_pile := make(Pile)
	defer delete(draw_pile)
	init_drawing_pile(&deck, &draw_pile)
	hand := make(Pile)
	defer delete(hand)

	for len(draw_pile) > 0 {
		draw_cards_into(&draw_pile, &hand, 5)
	}
}

@(test)
test_is_flush :: proc(t: ^testing.T) {
	same_rank_and_suite_5_times := []CardData {
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
	}

	different_ranks_same_suite := []CardData {
		{Rank.Ace, Suite.Heart},
		{Rank.Five, Suite.Heart},
		{Rank.Nine, Suite.Heart},
		{Rank.Ten, Suite.Heart},
		{Rank.Two, Suite.Heart},
	}

	same_suite_4_cards := []CardData {
		{Rank.Ace, Suite.Heart},
		{Rank.Five, Suite.Heart},
		{Rank.Nine, Suite.Heart},
		{Rank.Ten, Suite.Heart},
	}

	same_rank_different_suite := []CardData {
		{Rank.Ace, Suite.Diamond},
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
		{Rank.Ace, Suite.Heart},
	}

	different_rank_different_suite := []CardData {
		{Rank.Ace, Suite.Diamond},
		{Rank.Five, Suite.Heart},
		{Rank.Nine, Suite.Heart},
		{Rank.Ten, Suite.Spade},
		{Rank.Two, Suite.Club},
	}

	assert_contextless(contains_flush(same_rank_and_suite_5_times))
	assert_contextless(contains_flush(different_ranks_same_suite))
	assert_contextless(!contains_flush(same_suite_4_cards))
	assert_contextless(!contains_flush(same_rank_different_suite))
	assert_contextless(!contains_flush(different_rank_different_suite))
}

@(test)
test_is_straight :: proc(t: ^testing.T) {
	straight_ranks_5_cards := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Five, Suite.Heart},
		{Rank.Four, Suite.Heart},
		{Rank.Three, Suite.Diamond},
		{Rank.Six, Suite.Club},
	}

	low_ace_straight := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Five, Suite.Club},
		{Rank.Four, Suite.Diamond},
		{Rank.Three, Suite.Heart},
		{Rank.Ace, Suite.Heart},
	}

	high_ace_straight := []CardData {
		{Rank.Ten, Suite.Heart},
		{Rank.Jack, Suite.Club},
		{Rank.Queen, Suite.Diamond},
		{Rank.King, Suite.Heart},
		{Rank.Ace, Suite.Heart},
	}

	straight_ranks_4_cards := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Five, Suite.Club},
		{Rank.Four, Suite.Diamond},
		{Rank.Three, Suite.Heart},
	}

	almost_straight := []CardData {
		{Rank.Two, Suite.Diamond},
		{Rank.Three, Suite.Heart},
		{Rank.Five, Suite.Heart},
		{Rank.Six, Suite.Club},
		{Rank.Seven, Suite.Heart},
	}

	assert_contextless(contains_straight(straight_ranks_5_cards))
	assert_contextless(contains_straight(low_ace_straight))
	assert_contextless(contains_straight(high_ace_straight))
	assert_contextless(!contains_straight(straight_ranks_4_cards))
	assert_contextless(!contains_straight(almost_straight))
}

@(test)
test_same_rank :: proc(t: ^testing.T) {
	pair := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Two, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Three, Suite.Diamond},
		{Rank.Six, Suite.Club},
	}

	two_pairs := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Two, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Six, Suite.Club},
	}

	full_house := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Two, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Two, Suite.Club},
	}

	full_house_2 := []CardData {
		{Rank.Four, Suite.Heart},
		{Rank.Two, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Two, Suite.Club},
	}

	four_of_a_kind := []CardData {
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Two, Suite.Club},
	}

	five_of_a_kind := []CardData {
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Four, Suite.Diamond},
		{Rank.Four, Suite.Club},
	}

	none := []CardData {
		{Rank.Two, Suite.Heart},
		{Rank.Queen, Suite.Diamond},
		{Rank.Four, Suite.Heart},
		{Rank.Three, Suite.Diamond},
		{Rank.Six, Suite.Club},
	}

	a_pair, b_pair := same_rank_amount(pair)
	a_two_pairs, b_two_pairs := same_rank_amount(two_pairs)
	a_full_house, b_full_house := same_rank_amount(full_house)
	a_full_house_2, b_full_house_2 := same_rank_amount(full_house_2)
	a_four_of_a_kind, b_four_of_a_kind := same_rank_amount(four_of_a_kind)
	a_five_of_a_kind, b_five_of_a_kind := same_rank_amount(five_of_a_kind)
	a_none, b_none := same_rank_amount(none)

	assert_contextless(a_pair == 2 && b_pair == 0)
	assert_contextless(a_two_pairs == 2 && b_two_pairs == 2)
	assert_contextless(a_full_house == 3 && b_full_house == 2)
	assert_contextless(a_full_house_2 == 3 && b_full_house_2 == 2)
	assert_contextless(a_four_of_a_kind == 4 && b_four_of_a_kind == 0)
	assert_contextless(a_five_of_a_kind == 5 && b_five_of_a_kind == 0)
	assert_contextless(a_none == 0 && b_none == 0)
}

// @(test)
// test_check_hand :: proc(t: ^testing.T) {
// 	high_card := []CardData {
// 		{.King, .Heart},
// 		{.Two, .Spade},
// 		{.Five, .Club},
// 		{.Nine, .Diamond},
// 		{.Jack, .Heart},
// 	}
// 	pair := []CardData {
// 		{.King, .Heart},
// 		{.King, .Spade},
// 		{.Five, .Club},
// 		{.Nine, .Diamond},
// 		{.Jack, .Heart},
// 	}
// 	two_pair := []CardData {
// 		{.King, .Heart},
// 		{.King, .Spade},
// 		{.Nine, .Club},
// 		{.Nine, .Diamond},
// 		{.Jack, .Heart},
// 	}
// 	three_of_a_kind := []CardData {
// 		{.King, .Heart},
// 		{.King, .Spade},
// 		{.King, .Club},
// 		{.Nine, .Diamond},
// 		{.Jack, .Heart},
// 	}
// 	straight := []CardData {
// 		{.Five, .Heart},
// 		{.Six, .Spade},
// 		{.Seven, .Club},
// 		{.Eight, .Diamond},
// 		{.Nine, .Heart},
// 	}
// 	low_ace_straight := []CardData {
// 		{.Ace, .Heart},
// 		{.Two, .Spade},
// 		{.Three, .Club},
// 		{.Four, .Diamond},
// 		{.Five, .Heart},
// 	}
// 	flush := []CardData {
// 		{.Two, .Diamond},
// 		{.Five, .Diamond},
// 		{.Nine, .Diamond},
// 		{.Jack, .Diamond},
// 		{.King, .Diamond},
// 	}
// 	full_house := []CardData {
// 		{.King, .Heart},
// 		{.King, .Spade},
// 		{.King, .Club},
// 		{.Nine, .Diamond},
// 		{.Nine, .Heart},
// 	}
// 	four_of_a_kind := []CardData {
// 		{.King, .Heart},
// 		{.King, .Spade},
// 		{.King, .Club},
// 		{.King, .Diamond},
// 		{.Jack, .Heart},
// 	}
// 	straight_flush := []CardData {
// 		{.Five, .Club},
// 		{.Six, .Club},
// 		{.Seven, .Club},
// 		{.Eight, .Club},
// 		{.Nine, .Club},
// 	}
// 	royal_flush := []CardData {
// 		{.Ten, .Spade},
// 		{.Jack, .Spade},
// 		{.Queen, .Spade},
// 		{.King, .Spade},
// 		{.Ace, .Spade},
// 	}
// 	five_of_a_kind := []CardData {
// 		{.Ace, .Heart},
// 		{.Ace, .Spade},
// 		{.Ace, .Club},
// 		{.Ace, .Diamond},
// 		{.Ace, .Heart},
// 	}
// 	flush_house := []CardData {
// 		{.King, .Heart},
// 		{.King, .Heart},
// 		{.King, .Heart},
// 		{.Nine, .Heart},
// 		{.Nine, .Heart},
// 	}
// 	flush_five := []CardData {
// 		{.Ace, .Heart},
// 		{.Ace, .Heart},
// 		{.Ace, .Heart},
// 		{.Ace, .Heart},
// 		{.Ace, .Heart},
// 	}

// 	empty_hand: []CardData
// 	one_card := []CardData{{.Ace, .Heart}}
// 	six_cards := []CardData {
// 		{.Ace, .Heart},
// 		{.Two, .Heart},
// 		{.Three, .Heart},
// 		{.Four, .Heart},
// 		{.Five, .Heart},
// 		{.Six, .Heart},
// 	}

// 	expect_hand :: proc(cards: []CardData, expected_hand: HandType, loc := #caller_location) {
// 		hand, ok := evaluate_hand(cards)
// 		assert_contextless(ok, "check_hand should have returned ok=true", loc)
// 		assert_contextless(hand == expected_hand, "Incorrect hand detected.", loc)
// 	}

// 	expect_hand(high_card, .HighCard)
// 	expect_hand(pair, .Pair)
// 	expect_hand(two_pair, .TwoPair)
// 	expect_hand(three_of_a_kind, .ThreeOfAKind)
// 	expect_hand(straight, .Straight)
// 	expect_hand(low_ace_straight, .Straight)
// 	expect_hand(flush, .Flush)
// 	expect_hand(full_house, .FullHouse)
// 	expect_hand(four_of_a_kind, .FourOfAKind)
// 	expect_hand(straight_flush, .StraightFlush)
// 	expect_hand(royal_flush, .RoyalFlush)

// 	expect_hand(five_of_a_kind, .FiveOfAKind)
// 	expect_hand(flush_house, .FlushHouse)
// 	expect_hand(flush_five, .FlushFive)

// 	_, ok_empty := evaluate_hand(empty_hand)
// 	assert_contextless(!ok_empty, "Empty hand should not be ok")

// 	_, ok_six := evaluate_hand(six_cards)
// 	assert_contextless(!ok_six, "Hand with six cards should not be ok")

// 	hand_one, ok_one := evaluate_hand(one_card)
// 	assert_contextless(ok_one, "Hand with one card should be ok")
// 	assert_contextless(hand_one == .HighCard, "Hand with one card should be HighCard")
// }
