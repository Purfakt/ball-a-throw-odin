package core_game

Tarot :: enum {
	None,
	Fool,
	Magician,
	HighPriestess,
	Empress,
	Emperor,
	Hierophant,
	Lovers,
	Chariot,
	Justice,
	Hermit,
	WheelOfFortune,
	Strength,
	HangedMan,
	Death,
	Temperance,
	Devil,
	Tower,
	Star,
	Moon,
	Sun,
	Judgment,
	World,
}

TarotCards := [Tarot]TarotData {
	.None = {},
	.Fool = {
		tarot = .Fool,
		name = "The Fool",
		description = "Creates a copy of the last Tarot or Planet card used. (The Fool excluded)",
	},
	.Magician = {
		tarot = .Magician,
		name = "The Magician",
		description = "Enhances 2 selected cards to Lucky Cards",
	},
	.HighPriestess = {
		tarot = .HighPriestess,
		name = "The High Priestess",
		description = "Creates up to 2 random Planet cards (Must have room)",
	},
	.Empress = {
		tarot = .Empress,
		name = "The Empress",
		description = "Enhances 2 selected cards to Mult Cards",
	},
	.Emperor = {
		tarot = .Emperor,
		name = "The Emperor",
		description = "Creates up to 2 random Tarot cards(Must have room)",
	},
	.Hierophant = {
		tarot = .Hierophant,
		name = "The Hierophant",
		description = "Enhances 2 selected cards to Bonus Cards",
	},
	.Lovers = {
		tarot = .Lovers,
		name = "The Lovers",
		description = "Enhances 1 selected card into a Wild Card",
	},
	.Chariot = {
		tarot = .Chariot,
		name = "The Chariot",
		description = "Enhances 1 selected card into a Steel Card",
	},
	.Justice = {
		tarot = .Justice,
		name = "Justice",
		description = "Enhances 1 selected card into a Glass Card",
	},
	.Hermit = {tarot = .Hermit, name = "The Hermit", description = "Doubles money(Max of $20)"},
	.WheelOfFortune = {
		tarot = .WheelOfFortune,
		name = "The Wheel Of Fortune",
		description = "1 in 4 chance to add Foil, Holographic, or Polychrome edition to a random Joker",
	},
	.Strength = {
		tarot = .Strength,
		name = "Strength",
		description = "Increases rank of up to 2 selected cards by 1",
	},
	.HangedMan = {
		tarot = .HangedMan,
		name = "The Hanged Man",
		description = "Destroys up to 2 selected cards",
	},
	.Death = {
		tarot = .Death,
		name = "Death",
		description = "Select 2 cards, convert the right card into the left card",
	},
	.Temperance = {
		tarot = .Temperance,
		name = "Temperance",
		description = "Gives the total sell value of all current Jokers(Max of $50)",
	},
	.Devil = {
		tarot = .Devil,
		name = "The Devil",
		description = "Enhances 1 selected card into a Gold Card",
	},
	.Tower = {
		tarot = .Tower,
		name = "The Tower",
		description = "Enhances 1 selected card into a Stone Card",
	},
	.Star = {
		tarot = .Star,
		name = "The Star",
		description = "Converts up to 3 selected cards to Diamonds",
	},
	.Moon = {
		tarot = .Moon,
		name = "The Moon",
		description = "Converts up to 3 selected cards to Clubs",
	},
	.Sun = {
		tarot = .Sun,
		name = "The Sun",
		description = "Converts up to 3 selected cards to Hearts",
	},
	.Judgment = {
		tarot = .Judgment,
		name = "Judgment",
		description = "Creates a random Joker card (Must have room)",
	},
	.World = {
		tarot = .World,
		name = "The World",
		description = "Converts up to 3 selected cards to Spades",
	},
}

TarotData :: struct {
	tarot:       Tarot,
	name:        string,
	description: string,
}
