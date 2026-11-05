#!/usr/bin/env luajit
-- pokegold/engine/events/npc_trade.asm:380, pokecrystal/engine/events/npc_trade.asm:406

package.path = "./?.lua;./?/init.lua;" .. package.path

love = love or require("tests.love_stub")

local T = require("tests.harness")
local eq = T.eq

local TradeMenu = require("src.ui.gen2.TradeMenu")
local TradeAnimView = require("src.ui.gen2.TradeAnim")

T.suite("gen2 npc trade rom text")

local function flat(v)
  if type(v) ~= "table" then return tostring(v) end
  local out = {}
  for i = 1, #v do out[i] = flat(v[i]) end
  return "[" .. table.concat(out, "|") .. "]"
end

eq(TradeMenu.textLabel("TRADE_DIALOG_INTRO", "TRADE_DIALOGSET_NEWBIE", "gold"), "_NPCTradeIntroText3",
  "a Gold newbie asks with the third intro")
eq(TradeMenu.textLabel("TRADE_DIALOG_INTRO", "TRADE_DIALOGSET_NEWBIE", "silver"), "_NPCTradeIntroText3",
  "Silver shares Gold's table")
eq(TradeMenu.textLabel("TRADE_DIALOG_INTRO", "TRADE_DIALOGSET_NEWBIE", "crystal"), "_NPCTradeIntroText2",
  "a Crystal newbie asks with the second intro")
eq(TradeMenu.textLabel("TRADE_DIALOG_COMPLETE", "TRADE_DIALOGSET_NEWBIE", "crystal"), "_NPCTradeCompleteText4",
  "a Crystal newbie thanks with the fourth line")
eq(TradeMenu.textLabel("TRADE_DIALOG_AFTER", "TRADE_DIALOGSET_GIRL", "crystal"), "_NPCTradeAfterText3",
  "Crystal's girl set reads the third line")
eq(TradeMenu.textLabel("TradedForText"), "Text_NPCTraded", "the traded line has its own label")
eq(TradeMenu.textLabel("TRADE_DIALOG_INTRO", nil, "gold"), nil, "no set, no label")

local data = { text = { _NPCTradeIntroText1 = "Je collectionne!\fTu as {STRBUF}?\nContre {STRBUF}?{DONE}" } }
eq(TradeMenu.cartText(data, "_NPCTradeIntroText1", "English"), data.text._NPCTradeIntroText1,
  "the label's line wins over the extracted one")
eq(TradeMenu.cartText(data, "_NPCTradeCancelText1", "English"), "English",
  "a label the table lacks keeps the extracted line")
eq(TradeMenu.cartText(data, "_NPCTradeIntroText1", nil), nil,
  "a cache with no extracted line keeps its fallback, since it has no buffer order")

local row = { dialog = "TRADE_DIALOGSET_COLLECTOR", give = "ABRA", get = "MACHOP" }
local pokemon = { ABRA = { name = "ABRA" }, MACHOP = { name = "MACHOP" } }
eq(TradeMenu.fill("{STRBUF} for {STRBUF}", row, { pokemon = pokemon }, { "wStringBuffer2", "wStringBuffer1" }),
  "MACHOP for ABRA", "the recorded buffer order fills the markers")
eq(TradeMenu.fill("{RAM:wStringBuffer1} contre {RAM:wStringBuffer2}", row, { pokemon = pokemon },
  { "wStringBuffer2", "wStringBuffer1" }), "ABRA contre MACHOP", "a named buffer fills by its name")

local menu = setmetatable({
  data = { pokemon = pokemon, text = { _NPCTradeIntroText1 = "Tu as {STRBUF}?\nContre {STRBUF}?{DONE}" } },
  save = nil,
  row = row,
  eventTables = {
    tradeTexts = { TRADE_DIALOG_INTRO = { TRADE_DIALOGSET_COLLECTOR = "Have {STRBUF}?\nFor {STRBUF}?{DONE}" } },
    tradeBuffers = { TRADE_DIALOG_INTRO = { TRADE_DIALOGSET_COLLECTOR = { "wStringBuffer1", "wStringBuffer2" } } },
  },
}, TradeMenu)
eq(flat(menu:lineFor("TRADE_DIALOG_INTRO")), flat(TradeMenu.paginate("Tu as ABRA?\nContre MACHOP?{DONE}")),
  "the trader speaks the label's line")

eq(TradeAnimView.fill("{RAM:wOTTrademonSpeciesName} pour {STRBUF}",
  { wOTTrademonSpeciesName = "MACHOP", wPlayerTrademonSpeciesName = "ABRA" }, { "wPlayerTrademonSpeciesName" }),
  "MACHOP pour ABRA", "the animation fills a named buffer too")

local view = TradeAnimView.new({ data = { text = {
  _TakeGoodCareOfMonText = "Prends soin de\n{STRBUF}.{DONE}",
  _MonWasSentToText = "Envoyé!{DONE}",
} } }, {
  eventTables = {
    tradeTexts = { _TakeGoodCareOfMonText = "Take good care\nof {STRBUF}.{DONE}" },
    tradeBuffers = { _TakeGoodCareOfMonText = { "wOTTrademonSpeciesName" } },
  },
  row = { give = "ABRA", get = "MACHOP" },
})
view.give, view.get = { name = "ABRA" }, { name = "MACHOP" }
local text = view.data.text
view.data.text = {}
eq(flat(view:lines("take_care")), flat(TradeMenu.paginate("Prends soin de\nMACHOP.{DONE}")[1]),
  "the animation prints the line resolved when it opened")
T.neq(flat(view:lines("sent_text")), flat(TradeMenu.paginate("Envoyé!{DONE}")[1]),
  "a beat the cache has no extracted line for keeps its fallback, which knows its buffers")
view.data.text = text

T.finish("gen2 npc trade rom text")
