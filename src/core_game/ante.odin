package core_game


Blind :: enum {
	Small,
	Big,
	Boss,
}

BlindStatus :: enum {
	Selectable,
	Upcoming,
	Defeated,
}

Ante :: enum {
	One,
	Two,
	Three,
	Four,
	Five,
	Six,
	Seven,
	Eight,
}

BlindScaling := [Blind]i64 {
	.Small = 100,
	.Big   = 150,
	.Boss  = 250,
}

BlindText := [Blind]string {
	.Small = "Small Blind",
	.Big   = "Big Blind",
	.Boss  = "Boss Blind",
}

BlindStatusText := [BlindStatus]string {
	.Selectable = "Selectable",
	.Upcoming   = "Upcoming",
	.Defeated   = "Defeated",
}

AnteScaling := [Ante]i64 {
	.One   = 3,
	.Two   = 8,
	.Three = 20,
	.Four  = 50,
	.Five  = 11_0,
	.Six   = 20_0,
	.Seven = 35_0,
	.Eight = 50_0,
}

score_at_least :: proc(blind: Blind, ante: Ante) -> i64 {
	return BlindScaling[blind] * AnteScaling[ante]
}
