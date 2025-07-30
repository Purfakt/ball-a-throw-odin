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
Pile :: [dynamic]CardHandle
Selection :: [5]CardHandle
