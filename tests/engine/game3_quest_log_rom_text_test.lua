#!/usr/bin/env luajit
-- pokefirered/src/data/text/quest_log.h:1, src/quest_log.c:522

package.path = "./?.lua;./?/init.lua;" .. package.path

local BUNDLE = { text = {} }
package.loaded["src.core.game3.scripting.space"] = { ensureBundle = function() return BUNDLE end }
package.loaded["src.core.game3.profile"] = { forSession = function() return { ui = {} } end }

local T = require("tests.harness")
local eq = T.eq

local UI = require("src.ui.game3.quest_log")
local RomText = require("src.core.game3.rom_text")

T.suite("quest log rom text")

local function ir(...)
  local out = { ... }
  out[#out + 1] = { t = "eos" }
  return out
end
local function text(s) return { t = "text", s = s } end

local session = { name = "RED", rivalName = "BLUE", questLog = { version = 1, scenes = {} } }

UI.pack = { text = {
  PreviouslyOnYourQuest = "Previously on your quest...",
  ArrivedInLocation = "Arrived in {S1}.",
  SavedGameAtLocation = "{PLAYER} saved the game\nat {S1}.",
  TookOnTrainersMonWithMonAndWon = "{D4} took on {D5}...",
  Home = "HOME",
} }
UI.lines = nil

BUNDLE.text = {}
UI.begin(session)
eq(UI.text("ArrivedInLocation", { ["1"] = "PALLET TOWN" }, session), "Arrived in PALLET TOWN.",
  "a line the cart table lacks keeps the pack's text")

BUNDLE.text = {
  gText_QuestLog_PreviouslyOnYourQuest = ir(text("Anteriormente en tu aventura...")),
  gText_QuestLog_ArrivedInLocation = ir(text("Llegaste a "), { t = "strvar", n = 1 }, text(".")),
  gText_QuestLog_SavedGameAtLocation = ir({ t = "player" }, text(" guardó"), { t = "nl" }, text("en "),
    { t = "strvar", n = 1 }, text(".")),
  gText_QuestLog_TookOnTrainersMonWithMonAndWon = ir({ t = "dynamic", n = 4 }, text(" contra "),
    { t = "dynamic", n = 5 }),
  gText_QuestLog_Home = ir(text("CASA")),
}
UI.begin(session)
eq(UI.text("PreviouslyOnYourQuest", {}, session), "Anteriormente en tu aventura...",
  "the title reads the cart table")
eq(UI.text("ArrivedInLocation", { ["1"] = "PUEBLO PALETA" }, session), "Llegaste a PUEBLO PALETA.",
  "a string var is filled from the event")
eq(UI.text("SavedGameAtLocation", { ["1"] = { text = "Home" } }, session), "RED guardó\nen CASA.",
  "the player, a line break and a place the pack names read the cart table")
eq(UI.text("TookOnTrainersMonWithMonAndWon", { D4 = "PIKACHU", D5 = "ONIX" }, session), "PIKACHU contra ONIX",
  "the dynamic slots are filled from the event")

local has, reads = RomText.has, 0
RomText.has = function(...) reads = reads + 1 return has(...) end
UI.text("ArrivedInLocation", { ["1"] = "X" }, session)
eq(reads, 0, "showing a line reads no cart text")
RomText.has = has

UI.install(nil)
eq(UI.lines, nil, "a new pack drops the lines resolved for the previous one")

T.finish("quest log rom text")
