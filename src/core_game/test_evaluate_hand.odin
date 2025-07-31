package core_game

import "core:slice"
import "core:testing"

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
@(test)
test_check_hand :: proc(t: ^testing.T) {
	high_card := []CardData {
		{.King, .Heart},
		{.Two, .Spade},
		{.Five, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	pair := []CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.Five, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	two_pair := []CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.Nine, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	three_of_a_kind := []CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.King, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	straight := []CardData {
		{.Five, .Heart},
		{.Six, .Spade},
		{.Seven, .Club},
		{.Eight, .Diamond},
		{.Nine, .Heart},
	}
	low_ace_straight := []CardData {
		{.Ace, .Heart},
		{.Two, .Spade},
		{.Three, .Club},
		{.Four, .Diamond},
		{.Five, .Heart},
	}
	flush := []CardData {
		{.Two, .Diamond},
		{.Five, .Diamond},
		{.Nine, .Diamond},
		{.Jack, .Diamond},
		{.King, .Diamond},
	}
	full_house := []CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.King, .Club},
		{.Nine, .Diamond},
		{.Nine, .Heart},
	}
	four_of_a_kind := []CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.King, .Club},
		{.King, .Diamond},
		{.Jack, .Heart},
	}
	straight_flush := []CardData {
		{.Five, .Club},
		{.Six, .Club},
		{.Seven, .Club},
		{.Eight, .Club},
		{.Nine, .Club},
	}
	royal_flush := []CardData {
		{.Ten, .Spade},
		{.Jack, .Spade},
		{.Queen, .Spade},
		{.King, .Spade},
		{.Ace, .Spade},
	}
	five_of_a_kind := []CardData {
		{.Ace, .Heart},
		{.Ace, .Spade},
		{.Ace, .Club},
		{.Ace, .Diamond},
		{.Ace, .Heart},
	}
	flush_house := []CardData {
		{.King, .Heart},
		{.King, .Heart},
		{.King, .Heart},
		{.Nine, .Heart},
		{.Nine, .Heart},
	}
	flush_five := []CardData {
		{.Ace, .Heart},
		{.Ace, .Heart},
		{.Ace, .Heart},
		{.Ace, .Heart},
		{.Ace, .Heart},
	}

	empty_hand: []CardData
	one_card := []CardData{{.Ace, .Heart}}
	six_cards := []CardData {
		{.Ace, .Heart},
		{.Two, .Heart},
		{.Three, .Heart},
		{.Four, .Heart},
		{.Five, .Heart},
		{.Six, .Heart},
	}

	evaluate :: proc(cards: []CardData) -> (hand: EvaluatedHand, ok: bool) {
		instances := slice.mapper(cards, proc(data: CardData) -> CardInstance {
			return CardInstance{data = data}
		})
		defer delete(instances)
		return evaluate_hand(instances)
	}

	expect_hand :: proc(cards: []CardData, expected_hand: HandType, loc := #caller_location) {
		hand, ok := evaluate(cards)
		assert_contextless(ok, "evaluate_hand should have returned ok=true", loc)
		assert_contextless(hand.hand_type == expected_hand, "Incorrect hand detected.", loc)
	}

	expect_nok :: proc(cards: []CardData, message: string, loc := #caller_location) {
		_, ok := evaluate(cards)
		assert_contextless(!ok, message, loc)
	}

	expect_hand(one_card, .HighCard)
	expect_hand(high_card, .HighCard)
	expect_hand(pair, .Pair)
	expect_hand(two_pair, .TwoPair)
	expect_hand(three_of_a_kind, .ThreeOfAKind)
	expect_hand(straight, .Straight)
	expect_hand(low_ace_straight, .Straight)
	expect_hand(flush, .Flush)
	expect_hand(full_house, .FullHouse)
	expect_hand(four_of_a_kind, .FourOfAKind)
	expect_hand(straight_flush, .StraightFlush)
	expect_hand(royal_flush, .RoyalFlush)

	expect_hand(five_of_a_kind, .FiveOfAKind)
	expect_hand(flush_house, .FlushHouse)
	expect_hand(flush_five, .FlushFive)

	expect_nok(empty_hand, "Empty hand should not be ok")

	expect_nok(six_cards, "Hand with six cards should not be ok")
}
