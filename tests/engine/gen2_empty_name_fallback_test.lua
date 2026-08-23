-- World:load's getMonName/getItemName hooks (src/world/gen2/World.lua) fed
-- the VM's "<PLAYER> received\n<STRBUF>." and "<MON> was sent out" style
-- messages. Both used to read `def.name` with a bare Lua truth test:
--
--   if def and def.name then return def.name end
--   return (def and def.name) or id or "?"
--
-- An empty string is truthy in Lua, so a row whose ROM-extracted name
-- decoded to nothing -- a dummy ItemNames/PokemonNames slot, its terminator
-- sitting right at the read address (src/import/RomExtractorGen2.lua's
-- extractItems: `value` stays whatever readString gave back, nil only when
-- the index is past nameCount) -- won this test and printed as a blank
-- name, instead of falling through to the id/"ITEM<n>" placeholder the
-- function's own fallback exists for. Reported against a real Gold build as
-- "<PLAYER> receives ." with nothing after it (gen1recomp#1642).
--
-- World:load builds these two closures inline and hands them straight to
-- Vm.new (src/script/gen2/Vm.lua's getMonNameFn/getItemNameFn), so this
-- drives the real World:load path -- with data.gen2Maps/gen2Tilesets
-- pre-set so the hard-fail check at its top passes without a cache on disk
-- -- rather than a hand-built stand-in, the way every other Gold VM test
-- covering these two hooks does (see tests/gen2_vm_test.lua and friends,
-- none of which exercise World.lua's own implementation).
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.harness")

love = require("tests.love_stub")

require("src.core.Logger").warn = function() end

local World = require("src.world.gen2.World")

local game = {
  data = {
    gen2Maps = {},
    gen2Tilesets = {},
    pokemon = {
      BULBASAUR = { name = "BULBASAUR", index = 1 },
      -- a dummy PokemonNames row: extracted, present, name decoded empty
      MON_DUMMY = { name = "", index = 253 },
    },
    items = {
      POTION = { name = "POTION", index = 20 },
      -- a dummy ItemNames row (a reserved/placeholder id, its terminator
      -- immediately at the read address)
      ITEM_DUMMY = { name = "", index = 100 },
    },
  },
  save = { party = {}, inventory = {} },
}

local world = World.new(game)
-- :load()'s own return value tracks whether it reached a live map (there is
-- none here -- gen2Maps is empty on purpose, to keep this fixture tiny), not
-- whether the VM got built; the VM is wired up well before that spawn step,
-- which is the only part this suite needs.
world:load()
T.check(world.vm ~= nil, "the VM is up")

T.eq(world.vm.getMonNameFn(1), "BULBASAUR", "a real species name still wins")
T.eq(world.vm.getMonNameFn(253), "MON_DUMMY",
  "an empty extracted name falls through to the id instead of printing blank")
T.eq(world.vm.getMonNameFn(9999), "?",
  "an index with no row at all keeps its own placeholder")

T.eq(world.vm.getItemNameFn(20), "POTION", "a real item name still wins")
T.eq(world.vm.getItemNameFn(100), "ITEM_DUMMY",
  "an empty extracted name falls through to the id instead of printing blank")
T.eq(world.vm.getItemNameFn(9999), "ITEM9999",
  "an index with no row at all keeps its own ITEM<n> placeholder")

T.finish("gen2_empty_name_fallback_test")
