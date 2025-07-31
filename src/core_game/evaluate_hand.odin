package core_game

import "core:slice"


EvaluatedHand :: struct {
	hand_type:       HandType,
	scoring_handles: Selection,
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

	is_ace_low_straight :=
		unique_ranks[0] == 2 &&
		unique_ranks[1] == 3 &&
		unique_ranks[2] == 4 &&
		unique_ranks[3] == 5 &&
		unique_ranks[4] == 14

	return is_normal_straight || is_ace_low_straight
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
		for card, i in cards {
			hand.scoring_handles[i] = card.handle
		}
	case .HighCard:
		slice.sort_by(
			cards[:],
			proc(lhs, rhs: CardInstance) -> bool {return lhs.data.rank > rhs.data.rank},
		)
		hand.scoring_handles[0] = cards[0].handle
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

		for card, i in cards {
			if slice.contains(scoring_ranks[:], card.data.rank) {
				hand.scoring_handles[i] = card.handle
			}
		}
	}


	return
}
