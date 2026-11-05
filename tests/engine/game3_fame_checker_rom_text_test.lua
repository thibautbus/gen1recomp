#!/usr/bin/env luajit
-- pokefirered/src/fame_checker.c:164, :209, :246, :380, :399

package.path = "./?.lua;./?/init.lua;" .. package.path

local BUNDLE = { text = {} }
package.loaded["src.core.game3.scripting.space"] = { ensureBundle = function() return BUNDLE end }
package.loaded["src.core.game3.profile"] = { forSession = function() return { ui = {} } end }
package.loaded["src.ui.game3.stack"] = { push = function() end, pop = function() end }

local T = require("tests.harness")
local eq = T.eq

local FameChecker = require("src.core.game3.fame_checker")
local Ui = require("src.ui.game3.fame_checker")
local RomText = require("src.core.game3.rom_text")

T.suite("fame checker rom text")

local function ir(...)
  local out = { ... }
  out[#out + 1] = { t = "eos" }
  return out
end
local function text(s) return { t = "text", s = s } end

local NSLOT = FameChecker.NUM_FLAVOR_TEXTS
local DAISY, MISTY = FameChecker.PERSON.DAISY, FameChecker.PERSON.MISTY

local function pack()
  return {
    listNames = { [DAISY] = "DAISY" },
    names = { [MISTY] = "MISTY" },
    quotes = { [MISTY] = "My policy is…" },
    flavorText = { [MISTY] = { [0] = "She is a tomboy.", [1] = "Her favorite is\nWATER." } },
    originLocation = { [MISTY] = { [0] = "CERULEAN GYM" } },
    originObject = { [MISTY] = { [0] = "MISTY" } },
  }
end

local function open()
  Ui._pack, Ui._packTried = pack(), true
  BUNDLE.text.gFameCheckerText_Cancel = ir(text("CANCEL"))
  BUNDLE.text[RomText.key("sNonTrainerNamePointers", 0)] = ir(text("PROF. OAK"))
  Ui.show({ modData = {}, name = "RED", rivalName = "BLUE" })
end

BUNDLE.text = {}
open()
eq(Ui.flavorText(MISTY, 0), "She is a tomboy.", "a text the cart tables lack keeps the pack's")
eq(Ui.personName(DAISY), "DAISY", "a list name the cart tables lack keeps the pack's")
Ui.close()

BUNDLE.text = {
  [RomText.key("sNonTrainerNamePointers", 1)] = ir(text("DALIA")),
  [RomText.key("sFameCheckerNameAndQuotesPointers", MISTY)] = ir(text("MISTY ES")),
  [RomText.key("sFameCheckerNameAndQuotesPointers", FameChecker.NUM_PERSONS + MISTY)] = ir(text("Mi lema es…")),
  [RomText.key("sFameCheckerFlavorTextPointers", MISTY * NSLOT)] = ir(text("Es "), { t = "player" },
    { t = "nl" }, text("y "), { t = "strvar", n = 1 }, { t = "para" }, text("fin")),
  [RomText.key("sFameCheckerFlavorTextPointers", MISTY * NSLOT + 1)] = ir(text("Su favorito"),
    { t = "scroll" }, text("AGUA."), { t = "rival" }),
  [RomText.key("sFlavorTextOriginLocationTexts", MISTY * NSLOT)] = ir(text("GIMNASIO CELESTE")),
  [RomText.key("sFlavorTextOriginObjectNameTexts", MISTY * NSLOT)] = ir(text("MISTY ES")),
}
open()
eq(Ui.personName(DAISY), "DALIA", "a list name reads the non-trainer name table")
eq(Ui._texts.names[MISTY], "MISTY ES", "a name reads its row of the name and quote table")
eq(Ui._texts.quotes[MISTY], "Mi lema es…", "a quote reads the second half of that table")
eq(Ui.flavorText(MISTY, 0), "Es {PLAYER}\ny {STR_VAR_1}\\pfin",
  "a flavor text keeps the pack's placeholder and paragraph forms")
eq(Ui.flavorText(MISTY, 1), "Su favorito\\lAGUA.{RIVAL}", "each slot reads its own row")
local loc, obj = Ui.iconDescription(MISTY, 0)
eq(loc, "GIMNASIO CELESTE", "the origin location reads its table")
eq(obj, "MISTY ES", "the origin object reads its table")

local has, reads = RomText.has, 0
RomText.has = function(...) reads = reads + 1 return has(...) end
Ui.flavorText(MISTY, 1)
Ui.iconDescription(MISTY, 0)
eq(reads, 0, "reading a text once the checker is open reads no cart text")
RomText.has = has
Ui.close()

Ui.reloadAssets()
eq(Ui._texts, nil, "reloading the assets drops the resolved texts")

T.finish("fame checker rom text")
