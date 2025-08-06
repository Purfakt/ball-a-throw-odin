package game

import "core:fmt"
import "core:math/rand"
import c "core_game"
import rl "vendor:raylib"

ShopData :: struct {
	run_data:       ^RunData,
	tarot_for_sale: [2]c.Consumable,
}

init_shop_screen :: proc(run_data: ^RunData) -> Screen {
	shop_data := new(ShopData)
	shop_data.run_data = run_data

	shop_data.tarot_for_sale[0] = c.TarotCards[c.Tarot(rand.int_max(len(c.TarotCards) - 1) + 1)]
	shop_data.tarot_for_sale[1] = c.TarotCards[c.Tarot(rand.int_max(len(c.TarotCards) - 1) + 1)]

	return Screen {
		data = shop_data,
		draw = draw_shop_screen,
		update = update_shop_screen,
		delete = delete_shop_screen,
		uses_hud = true,
	}
}

update_shop_screen :: proc(ctx: ^GameContext, layout: Layout, dt: f32) {
	data, ok := ctx.screen.data.(^ShopData)
	if !ok {
		return
	}

	ante_button_rect := rl.Rectangle{layout.center_area.x + 20, layout.center_area.y + 20, 150, 50}
	if is_clicked(ante_button_rect) {
		transition_to_ante(ctx)
		return
	}

	booster_section := rl.Rectangle {
		layout.center_area.x + layout.center_area.width / 2,
		layout.center_area.y + layout.center_area.height / 2,
		layout.center_area.width / 2,
		layout.center_area.height / 2,
	}

	for i in 0 ..< 2 {
		card_data := data.tarot_for_sale[i].(c.TarotData) or_continue

		buy_button_rect := get_tarot_buy_button_rect(booster_section, i)

		if is_clicked(buy_button_rect) &&
		   data.run_data.money >= 5 &&
		   len(data.run_data.tarot_cards) < 2 {
			data.run_data.money -= 5
			data.tarot_for_sale[i] = c.EmptyConsumable{}
			append(&data.run_data.tarot_cards, card_data)
		}
	}
}

draw_shop_screen :: proc(ctx: ^GameContext, layout: Layout, dt: f32) {
	data, ok := ctx.screen.data.(^ShopData)
	if !ok {
		return
	}

	top_half := rl.Rectangle {
		layout.center_area.x,
		layout.center_area.y,
		layout.center_area.width,
		layout.center_area.height / 2,
	}
	rl.DrawRectangleRec(top_half, {20, 20, 20, 255})
	center_text_in_rect("Jokers For Sale (Not Implemented)", top_half, 30, rl.WHITE)

	ante_button_rect := rl.Rectangle{layout.center_area.x + 20, layout.center_area.y + 20, 150, 50}
	ante_button_color := rl.DARKBLUE
	if is_hovered(ante_button_rect) {
		ante_button_color = rl.BLUE
	}

	rl.DrawRectangleRec(ante_button_rect, ante_button_color)
	center_text_in_rect("To Ante", ante_button_rect, 20, rl.WHITE)

	bottom_half := rl.Rectangle {
		layout.center_area.x,
		layout.center_area.y + layout.center_area.height / 2,
		layout.center_area.width,
		layout.center_area.height / 2,
	}

	voucher_section := rl.Rectangle {
		bottom_half.x,
		bottom_half.y,
		bottom_half.width / 2,
		bottom_half.height,
	}
	rl.DrawRectangleRec(voucher_section, {30, 30, 30, 255})
	center_text_in_rect("Vouchers (Not Implemented)", voucher_section, 20, rl.WHITE)

	booster_section := rl.Rectangle {
		bottom_half.x + bottom_half.width / 2,
		bottom_half.y,
		bottom_half.width / 2,
		bottom_half.height,
	}
	rl.DrawRectangleRec(booster_section, {40, 40, 40, 255})
	center_text_in_rect("Boosters", booster_section, 30, rl.WHITE)

	for i in 0 ..< 2 {
		card_data := data.tarot_for_sale[i].(c.TarotData) or_continue
		card_area := rl.Rectangle {
			booster_section.x + f32(i) * (200 + 20) + 20,
			booster_section.y + 20,
			200,
			150,
		}
		rl.DrawRectangleRec(card_area, rl.PURPLE)
		center_text_in_rect(
			fmt.ctprint(card_data.name),
			rl.Rectangle{card_area.x, card_area.y + 10, card_area.width, 20},
			20,
			rl.WHITE,
		)
		center_text_in_rect(
			fmt.ctprint(card_data.description),
			rl.Rectangle{card_area.x, card_area.y + 40, card_area.width, 60},
			14,
			rl.WHITE,
		)

		buy_button_rect := get_tarot_buy_button_rect(booster_section, i)
		buy_button_color := rl.DARKGREEN
		if data.run_data.money >= 5 {
			if is_hovered(buy_button_rect) {
				buy_button_color = rl.GREEN
			}
		} else {
			buy_button_color = rl.GRAY
		}
		rl.DrawRectangleRec(buy_button_rect, buy_button_color)
		center_text_in_rect("Buy ($5)", buy_button_rect, 20, rl.WHITE)
	}
}

get_tarot_buy_button_rect :: proc(booster_section: rl.Rectangle, i: int) -> rl.Rectangle {
	card_area_x := booster_section.x + f32(i) * (200 + 20) + 20
	card_area_y := booster_section.y + 20
	return {card_area_x + 25, card_area_y + 100, 150, 40}
}

delete_shop_screen :: proc(ctx: ^GameContext) {
	if data_ptr, ok := ctx.screen.data.(^ShopData); ok {
		free(data_ptr)
	}
}
