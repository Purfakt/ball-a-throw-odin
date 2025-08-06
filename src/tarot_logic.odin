package game

import "core:fmt"
import c "core_game"
import hm "handle_map"

is_tarot_usage_valid :: proc(tarot_data: c.TarotData, selected_cards: c.CardPile) -> bool {
	num_selected := len(selected_cards)

	#partial switch req in tarot_data.card_selected {
	case c.CardSelectedNone:
		return num_selected == 0
	case c.CardSelectedMax:
		return num_selected > 0 && num_selected <= req.max
	case c.CardSelectedEqual:
		return num_selected == req.equal
	}
	return false
}

apply_tarot_effect :: proc(data: ^GamePlayData, consumable_index: int) {
	if consumable_index < 0 || consumable_index >= len(data.run_data.tarot_cards) {
		return
	}

	consumable := data.run_data.tarot_cards[consumable_index]
	tarot_data, ok := consumable.(c.TarotData)
	if !ok || tarot_data.tarot == .None {
		return
	}

	if !is_tarot_usage_valid(tarot_data, data.selected_cards) {
		fmt.printf("Invalid number of cards selected for %s\n", tarot_data.name)
		return
	}

	#partial switch tarot_data.tarot {
	case .Hermit:
		data.run_data.money *= 2
		if data.run_data.money > 20 {
			data.run_data.money = 20
		}
	case .Strength:
		for handle in data.selected_cards {
			if card := hm.get(&data.run_data.deck, handle); card != nil {
				if card.data.rank < .Ace {
					card.data.rank = c.Rank(int(card.data.rank) + 1)
				}
			}
		}
	case .HangedMan:
		for handle in data.selected_cards {
			hm.remove(&data.run_data.deck, handle)
		}
	}

	ordered_remove(&data.run_data.tarot_cards, consumable_index)
	append(&data.run_data.tarot_cards, c.EmptyConsumable{})

	c.empty_pile(&data.selected_cards)
	data.selected_consumable_index = -1
	data.selected_hand = .None
}
