package core_game

import hm "../handle_map"


Rank :: enum {
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
	Ace,
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

SortMethod :: enum {
	ByRank,
	BySuite,
}

SuiteColor := [Suite][4]u8 {
	.Heart   = {235, 52, 52, 255},
	.Diamond = {235, 116, 52, 255},
	.Spade   = {52, 52, 116, 255},
	.Club    = {52, 125, 235, 255},
}

RankValue := [Rank]u8 {
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
	.Ace   = 14,
}

RankChip := [Rank]u8 {
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
	.Ace   = 10,
}

RankString := [Rank]string {
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
	.Ace   = "A",
}

IsFace := [Rank]bool {
	.Two   = false,
	.Three = false,
	.Four  = false,
	.Five  = false,
	.Six   = false,
	.Seven = false,
	.Eight = false,
	.Nine  = false,
	.Ten   = false,
	.Jack  = true,
	.Queen = true,
	.King  = true,
	.Ace   = false,
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

Enhancement :: enum {
	None,
	Bonus,
	Mult,
	Wild,
	Glass,
	Steel,
	Stone,
	Gold,
	Lucky,
}

Seal :: enum {
	None,
	Gold,
	Red,
	Blue,
	Purple,
}

CardData :: struct {
	rank:  Rank,
	suite: Suite,
}

CardInstance :: struct {
	handle:       CardHandle,
	data:         CardData,
	enhancement:  Enhancement,
	seal:         Seal,
	edition:      Edition,
	position:     [2]f32,
	rotation:     f32,
	jiggle_timer: f32,
}

CardHandle :: distinct hm.Handle
