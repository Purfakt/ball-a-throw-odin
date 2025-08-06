package core_game

import hm "../handle_map"

Edition :: enum {
	Base,
	Foil,
	Holographic,
	Polychrome,
	Negative,
}

Deck :: hm.Handle_Map(CardInstance, CardHandle, 1024)
CardPile :: [dynamic]CardHandle
CardSelection :: [5]CardHandle

ConsumablePile :: [dynamic]Consumable

EmptyConsumable :: struct {}

Consumable :: union {
	EmptyConsumable,
	TarotData,
}
