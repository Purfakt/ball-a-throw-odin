package test_core_game

import c "../../core_game"
import "core:slice"
import "core:testing"

@(test)
test_draw :: proc(t: ^testing.T) {
	deck := c.init_deck()

	draw_pile := make(c.Pile)
	defer delete(draw_pile)
	c.init_drawing_pile(&deck, &draw_pile)
	hand := make(c.Pile)
	defer delete(hand)

	for len(draw_pile) > 0 {
		c.draw_cards_into(&draw_pile, &hand, 5)
	}
}

@(test)
test_is_flush :: proc(t: ^testing.T) {
	same_rank_and_suite_5_times := []c.CardData {
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
	}

	different_ranks_same_suite := []c.CardData {
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Five, c.Suite.Heart},
		{c.Rank.Nine, c.Suite.Heart},
		{c.Rank.Ten, c.Suite.Heart},
		{c.Rank.Two, c.Suite.Heart},
	}

	same_suite_4_cards := []c.CardData {
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Five, c.Suite.Heart},
		{c.Rank.Nine, c.Suite.Heart},
		{c.Rank.Ten, c.Suite.Heart},
	}

	same_rank_different_suite := []c.CardData {
		{c.Rank.Ace, c.Suite.Diamond},
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
	}

	different_rank_different_suite := []c.CardData {
		{c.Rank.Ace, c.Suite.Diamond},
		{c.Rank.Five, c.Suite.Heart},
		{c.Rank.Nine, c.Suite.Heart},
		{c.Rank.Ten, c.Suite.Spade},
		{c.Rank.Two, c.Suite.Club},
	}

	assert_contextless(c.contains_flush(same_rank_and_suite_5_times))
	assert_contextless(c.contains_flush(different_ranks_same_suite))
	assert_contextless(!c.contains_flush(same_suite_4_cards))
	assert_contextless(!c.contains_flush(same_rank_different_suite))
	assert_contextless(!c.contains_flush(different_rank_different_suite))
}

@(test)
test_is_straight :: proc(t: ^testing.T) {
	straight_ranks_5_cards := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Five, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Three, c.Suite.Diamond},
		{c.Rank.Six, c.Suite.Club},
	}

	low_ace_straight := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Five, c.Suite.Club},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Three, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
	}

	high_ace_straight := []c.CardData {
		{c.Rank.Ten, c.Suite.Heart},
		{c.Rank.Jack, c.Suite.Club},
		{c.Rank.Queen, c.Suite.Diamond},
		{c.Rank.King, c.Suite.Heart},
		{c.Rank.Ace, c.Suite.Heart},
	}

	straight_ranks_4_cards := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Five, c.Suite.Club},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Three, c.Suite.Heart},
	}

	almost_straight := []c.CardData {
		{c.Rank.Two, c.Suite.Diamond},
		{c.Rank.Three, c.Suite.Heart},
		{c.Rank.Five, c.Suite.Heart},
		{c.Rank.Six, c.Suite.Club},
		{c.Rank.Seven, c.Suite.Heart},
	}

	assert_contextless(c.contains_straight(straight_ranks_5_cards))
	assert_contextless(c.contains_straight(low_ace_straight))
	assert_contextless(c.contains_straight(high_ace_straight))
	assert_contextless(!c.contains_straight(straight_ranks_4_cards))
	assert_contextless(!c.contains_straight(almost_straight))
}

@(test)
test_same_rank :: proc(t: ^testing.T) {
	pair := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Two, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Three, c.Suite.Diamond},
		{c.Rank.Six, c.Suite.Club},
	}

	two_pairs := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Two, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Six, c.Suite.Club},
	}

	full_house := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Two, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Two, c.Suite.Club},
	}

	full_house_2 := []c.CardData {
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Two, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Two, c.Suite.Club},
	}

	four_of_a_kind := []c.CardData {
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Two, c.Suite.Club},
	}

	five_of_a_kind := []c.CardData {
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Four, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Club},
	}

	none := []c.CardData {
		{c.Rank.Two, c.Suite.Heart},
		{c.Rank.Queen, c.Suite.Diamond},
		{c.Rank.Four, c.Suite.Heart},
		{c.Rank.Three, c.Suite.Diamond},
		{c.Rank.Six, c.Suite.Club},
	}

	a_pair, b_pair := c.same_rank_amount(pair)
	a_two_pairs, b_two_pairs := c.same_rank_amount(two_pairs)
	a_full_house, b_full_house := c.same_rank_amount(full_house)
	a_full_house_2, b_full_house_2 := c.same_rank_amount(full_house_2)
	a_four_of_a_kind, b_four_of_a_kind := c.same_rank_amount(four_of_a_kind)
	a_five_of_a_kind, b_five_of_a_kind := c.same_rank_amount(five_of_a_kind)
	a_none, b_none := c.same_rank_amount(none)

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
	high_card := []c.CardData {
		{.King, .Heart},
		{.Two, .Spade},
		{.Five, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	pair := []c.CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.Five, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	two_pair := []c.CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.Nine, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	three_of_a_kind := []c.CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.King, .Club},
		{.Nine, .Diamond},
		{.Jack, .Heart},
	}
	straight := []c.CardData {
		{.Five, .Heart},
		{.Six, .Spade},
		{.Seven, .Club},
		{.Eight, .Diamond},
		{.Nine, .Heart},
	}
	low_ace_straight := []c.CardData {
		{.Ace, .Heart},
		{.Two, .Spade},
		{.Three, .Club},
		{.Four, .Diamond},
		{.Five, .Heart},
	}
	flush := []c.CardData {
		{.Two, .Diamond},
		{.Five, .Diamond},
		{.Nine, .Diamond},
		{.Jack, .Diamond},
		{.King, .Diamond},
	}
	full_house := []c.CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.King, .Club},
		{.Nine, .Diamond},
		{.Nine, .Heart},
	}
	four_of_a_kind := []c.CardData {
		{.King, .Heart},
		{.King, .Spade},
		{.King, .Club},
		{.King, .Diamond},
		{.Jack, .Heart},
	}
	straight_flush := []c.CardData {
		{.Five, .Club},
		{.Six, .Club},
		{.Seven, .Club},
		{.Eight, .Club},
		{.Nine, .Club},
	}
	royal_flush := []c.CardData {
		{.Ten, .Spade},
		{.Jack, .Spade},
		{.Queen, .Spade},
		{.King, .Spade},
		{.Ace, .Spade},
	}
	five_of_a_kind := []c.CardData {
		{.Ace, .Heart},
		{.Ace, .Spade},
		{.Ace, .Club},
		{.Ace, .Diamond},
		{.Ace, .Heart},
	}
	flush_house := []c.CardData {
		{.King, .Heart},
		{.King, .Heart},
		{.King, .Heart},
		{.Nine, .Heart},
		{.Nine, .Heart},
	}
	flush_five := []c.CardData {
		{.Ace, .Heart},
		{.Ace, .Heart},
		{.Ace, .Heart},
		{.Ace, .Heart},
		{.Ace, .Heart},
	}

	empty_hand: []c.CardData
	one_card := []c.CardData{{.Ace, .Heart}}
	six_cards := []c.CardData {
		{.Ace, .Heart},
		{.Two, .Heart},
		{.Three, .Heart},
		{.Four, .Heart},
		{.Five, .Heart},
		{.Six, .Heart},
	}

	evaluate :: proc(cards: []c.CardData) -> (hand: c.EvaluatedHand, ok: bool) {
		instances := slice.mapper(cards, proc(data: c.CardData) -> c.CardInstance {
			return c.CardInstance{data = data}
		})
		defer delete(instances)
		return c.evaluate_hand(instances)
	}

	expect_hand :: proc(cards: []c.CardData, expected_hand: c.HandType, loc := #caller_location) {
		hand, ok := evaluate(cards)
		assert_contextless(ok, "evaluate_hand should have returned ok=true", loc)
		assert_contextless(hand.hand_type == expected_hand, "Incorrect hand detected.", loc)
	}

	expect_nok :: proc(cards: []c.CardData, message: string, loc := #caller_location) {
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
