--[[Copyright © 2026, Zyphira
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Libra nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL KENSHI BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

-- No AI was used in the making of this AddOn

_addon.name = 'Libra'
_addon.author = 'Zyphira, based on InfoBar by Kenshi'
_addon.version = '1.0b'
_addon.commands = {'libra'}

config = require('config')
texts = require('texts')
images = require('images')
require('vectors')
res = require('resources')
require('sqlite3')

local spritesWidth = 16
local spritesHeight = 16
local previousXExtent = 0
local previousYExtent = 0
local currentXExtent = 0
local currentYExtent = 0
local dependentExtent = nil

defaults = {}

defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = 0
defaults.display.pos.y = 0
defaults.display.scale = 1
defaults.display.padding = 0
defaults.display.alpha = 0.5
defaults.display.multiline = false

settings = config.load(defaults)

box = texts.new("", settings.display, settings)

mob_name_text = texts.new("")
nm_name_text = texts.new("")
player_name_text = texts.new("")
pc_name_text = texts.new("")
npc_name_text = texts.new("")
aggro_text = texts.new("")
resistance_text = texts.new("")
notes_text = texts.new("")

type_fire_text = texts.new("")
type_wind_text = texts.new("")
type_lightning_text = texts.new("")
type_ice_text = texts.new("")
type_earth_text = texts.new("")
type_water_text = texts.new("")
type_light_text = texts.new("")
type_darkness_text = texts.new("")
type_blunt_text = texts.new("")
type_slashing_text = texts.new("")
type_piercing_text = texts.new("")
type_h2h_text = texts.new("")
type_ranged_text = texts.new("")
type_breath_text = texts.new("")
type_magical_text = texts.new("")
type_physical_text = texts.new("")

local currentMobWeakness = {}
local currentMobResistance = {}
local currentMobImmunity = {}
local libra = {}
local properResKeyOrder = {"Ph", "Ma", "Br", "Sl", "Bl", "H2H", "Pi", "Ra", "Fi", "Wi", "Th", "Li", "Ic", "Ea", "Wa", "Da"}
local properAggroKeyOrder = {"passive", "links", "detectSight", "detectTruSight", "detectSound", "detectTruSound", "detectMagic", "detectLowHP", "detectJobAb"}

windower.register_event('load',function()
    load_sprites()
    load_texts()
    mobsdb = sqlite3.open(windower.addon_path..'/mobs.db')
    familiesdb = sqlite3.open(windower.addon_path..'/families.db')
    if not windower.ffxi.get_info().logged_in then return end
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_player()
    get_target(target.index)
end)

windower.register_event('unload',function()
    mobsdb:close()
    familiesdb:close()
end)

function load_sprites()

    windower.prim.create('BackgroundLeft')
	windower.prim.set_color('BackgroundLeft', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('BackgroundLeft', false)
    windower.prim.set_texture('BackgroundLeft', windower.addon_path .. 'assets/BackgroundLeft.png')
	windower.prim.set_repeat('BackgroundLeft', 1, 1)
	windower.prim.set_visibility('BackgroundLeft', true)
	windower.prim.set_position('BackgroundLeft', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('BackgroundLeft', 100 * settings.display.scale, 100 * settings.display.scale)

    windower.prim.create('BackgroundRight')
	windower.prim.set_color('BackgroundRight', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('BackgroundRight', false)
    windower.prim.set_texture('BackgroundRight', windower.addon_path .. 'assets/BackgroundRight.png')
	windower.prim.set_repeat('BackgroundRight', 1, 1)
	windower.prim.set_visibility('BackgroundRight', true)
	windower.prim.set_position('BackgroundRight', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('BackgroundRight', 100 * settings.display.scale, 100 * settings.display.scale)

    windower.prim.create('Background')
	windower.prim.set_color('Background', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Background', false)
    windower.prim.set_texture('Background', windower.addon_path .. 'assets/Background.png')
	windower.prim.set_repeat('Background', 1, 1)
	windower.prim.set_visibility('Background', true)
	windower.prim.set_position('Background', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Background', 100 * settings.display.scale, 100 * settings.display.scale)

    windower.prim.create('Fi')
	windower.prim.set_color('Fi', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Fi', false)
	windower.prim.set_texture('Fi', windower.addon_path .. 'assets/Fire-Icon.png')
	windower.prim.set_repeat('Fi', 1, 1)
	windower.prim.set_visibility('Fi', true)
	windower.prim.set_position('Fi', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Fi', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Wi')
	windower.prim.set_color('Wi', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Wi', false)
	windower.prim.set_texture('Wi', windower.addon_path .. 'assets/Wind-Icon.png')
	windower.prim.set_repeat('Wi', 1, 1)
	windower.prim.set_visibility('Wi', true)
	windower.prim.set_position('Wi', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Wi', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Th')
	windower.prim.set_color('Th', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Th', false)
	windower.prim.set_texture('Th', windower.addon_path .. 'assets/Lightning-Icon.png')
	windower.prim.set_repeat('Th', 1, 1)
	windower.prim.set_visibility('Th', true)
	windower.prim.set_position('Th', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Th', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Ic')
	windower.prim.set_color('Ic', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Ic', false)
	windower.prim.set_texture('Ic', windower.addon_path .. 'assets/Ice-Icon.png')
	windower.prim.set_repeat('Ic', 1, 1)
	windower.prim.set_visibility('Ic', true)
	windower.prim.set_position('Ic', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Ic', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Ea')
	windower.prim.set_color('Ea', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Ea', false)
	windower.prim.set_texture('Ea', windower.addon_path .. 'assets/Earth-Icon.png')
	windower.prim.set_repeat('Ea', 1, 1)
	windower.prim.set_visibility('Ea', true)
	windower.prim.set_position('Ea', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Ea', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Wa')
	windower.prim.set_color('Wa', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Wa', false)
	windower.prim.set_texture('Wa', windower.addon_path .. 'assets/Water-Icon.png')
	windower.prim.set_repeat('Wa', 1, 1)
	windower.prim.set_visibility('Wa', true)
	windower.prim.set_position('Wa', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Wa', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Li')
	windower.prim.set_color('Li', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Li', false)
	windower.prim.set_texture('Li', windower.addon_path .. 'assets/Light-Icon.png')
	windower.prim.set_repeat('Li', 1, 1)
	windower.prim.set_visibility('Li', true)
	windower.prim.set_position('Li', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Li', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Da')
	windower.prim.set_color('Da', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Da', false)
	windower.prim.set_texture('Da', windower.addon_path .. 'assets/Dark-Icon.png')
	windower.prim.set_repeat('Da', 1, 1)
	windower.prim.set_visibility('Da', true)
	windower.prim.set_position('Da', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Da', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Ra')
	windower.prim.set_color('Ra', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Ra', false)
	windower.prim.set_texture('Ra', windower.addon_path .. 'assets/Ranged_v3.png')
	windower.prim.set_repeat('Ra', 1, 1)
	windower.prim.set_visibility('Ra', true)
	windower.prim.set_position('Ra', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Ra', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Pi')
	windower.prim.set_color('Pi', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Pi', false)
	windower.prim.set_texture('Pi', windower.addon_path .. 'assets/Piercing_v3.png')
	windower.prim.set_repeat('Pi', 1, 1)
	windower.prim.set_visibility('Pi', true)
	windower.prim.set_position('Pi', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Pi', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('H2H')
	windower.prim.set_color('H2H', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('H2H', false)
	windower.prim.set_texture('H2H', windower.addon_path .. 'assets/H2H_v3.png')
	windower.prim.set_repeat('H2H', 1, 1)
	windower.prim.set_visibility('H2H', true)
	windower.prim.set_position('H2H', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('H2H', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Bl')
	windower.prim.set_color('Bl', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Bl', false)
	windower.prim.set_texture('Bl', windower.addon_path .. 'assets/Blunt_v3.png')
	windower.prim.set_repeat('Bl', 1, 1)
	windower.prim.set_visibility('Bl', true)
	windower.prim.set_position('Bl', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Bl', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Sl')
	windower.prim.set_color('Sl', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Sl', false)
	windower.prim.set_texture('Sl', windower.addon_path .. 'assets/Slashing_v3.png')
	windower.prim.set_repeat('Sl', 1, 1)
	windower.prim.set_visibility('Sl', true)
	windower.prim.set_position('Sl', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Sl', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Br')
	windower.prim.set_color('Br', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Br', false)
	windower.prim.set_texture('Br', windower.addon_path .. 'assets/Spirit_Damage.png')
	windower.prim.set_repeat('Br', 1, 1)
	windower.prim.set_visibility('Br', true)
	windower.prim.set_position('Br', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Br', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Ma')
	windower.prim.set_color('Ma', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Ma', false)
	windower.prim.set_texture('Ma', windower.addon_path .. 'assets/Magic_Damage.png')
	windower.prim.set_repeat('Ma', 1, 1)
	windower.prim.set_visibility('Ma', true)
	windower.prim.set_position('Ma', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Ma', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('Ph')
	windower.prim.set_color('Ph', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('Ph', false)
	windower.prim.set_texture('Ph', windower.addon_path .. 'assets/Physical_Damage.png')
	windower.prim.set_repeat('Ph', 1, 1)
	windower.prim.set_visibility('Ph', true)
	windower.prim.set_position('Ph', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('Ph', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('passive')
	windower.prim.set_color('passive', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('passive', false)
	windower.prim.set_texture('passive', windower.addon_path .. 'assets/Passive_v1.png')
	windower.prim.set_repeat('passive', 1, 1)
	windower.prim.set_visibility('passive', true)
	windower.prim.set_position('passive', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('passive', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('links')
	windower.prim.set_color('links', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('links', false)
	windower.prim.set_texture('links', windower.addon_path .. 'assets/LinksIconv2.png')
	windower.prim.set_repeat('links', 1, 1)
	windower.prim.set_visibility('links', true)
	windower.prim.set_position('links', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('links', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectSight')
	windower.prim.set_color('detectSight', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectSight', false)
	windower.prim.set_texture('detectSight', windower.addon_path .. 'assets/Aggro_Sight.png')
	windower.prim.set_repeat('detectSight', 1, 1)
	windower.prim.set_visibility('detectSight', true)
	windower.prim.set_position('detectSight', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectSight', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectSound')
	windower.prim.set_color('detectSound', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectSound', false)
	windower.prim.set_texture('detectSound', windower.addon_path .. 'assets/Aggro_Sound.png')
	windower.prim.set_repeat('detectSound', 1, 1)
	windower.prim.set_visibility('detectSound', true)
	windower.prim.set_position('detectSound', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectSound', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectMagic')
	windower.prim.set_color('detectMagic', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectMagic', false)
	windower.prim.set_texture('detectMagic', windower.addon_path .. 'assets/Aggro_Magic_v2.png')
	windower.prim.set_repeat('detectMagic', 1, 1)
	windower.prim.set_visibility('detectMagic', true)
	windower.prim.set_position('detectMagic', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectMagic', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectLowHP')
	windower.prim.set_color('detectLowHP', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectLowHP', false)
	windower.prim.set_texture('detectLowHP', windower.addon_path .. 'assets/Aggro_HP.png')
	windower.prim.set_repeat('detectLowHP', 1, 1)
	windower.prim.set_visibility('detectLowHP', true)
	windower.prim.set_position('detectLowHP', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectLowHP', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectJobAb')
	windower.prim.set_color('detectJobAb', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectJobAb', false)
	windower.prim.set_texture('detectJobAb', windower.addon_path .. 'assets/Aggro_JA.png')
	windower.prim.set_repeat('detectJobAb', 1, 1)
	windower.prim.set_visibility('detectJobAb', true)
	windower.prim.set_position('detectJobAb', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectJobAb', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectTruSight')
	windower.prim.set_color('detectTruSight', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectTruSight', false)
	windower.prim.set_texture('detectTruSight', windower.addon_path .. 'assets/Aggro_True_Sight.png')
	windower.prim.set_repeat('detectTruSight', 1, 1)
	windower.prim.set_visibility('detectTruSight', true)
	windower.prim.set_position('detectTruSight', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectTruSight', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

    windower.prim.create('detectTruSound')
	windower.prim.set_color('detectTruSound', 0, 0, 0, 0)
	windower.prim.set_fit_to_texture('detectTruSound', false)
	windower.prim.set_texture('detectTruSound', windower.addon_path .. 'assets/Aggro_True_Sound.png')
	windower.prim.set_repeat('detectTruSound', 1, 1)
	windower.prim.set_visibility('detectTruSound', true)
	windower.prim.set_position('detectTruSound', (settings.display.pos.x * settings.display.scale), (settings.display.pos.x * settings.display.scale))
	windower.prim.set_size('detectTruSound', spritesWidth * settings.display.scale, spritesHeight * settings.display.scale)

end

function load_texts()

	texts.visible(mob_name_text, false)
	texts.size(mob_name_text, 12 * settings.display.scale)
	texts.pos(mob_name_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(mob_name_text, 255,255,170)
	texts.stroke_width(mob_name_text, 1)
	texts.stroke_color(mob_name_text, 0,0,0)
    texts.stroke_alpha(nm_name_text, 100)
	texts.bg_alpha(mob_name_text, 0)
    texts.font(mob_name_text, 'Consolas')
    texts.draggable(mob_name_text, false)

    texts.visible(nm_name_text, false)
	texts.size(nm_name_text, 12 * settings.display.scale)
	texts.pos(nm_name_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(nm_name_text, 255,255,255)
	texts.stroke_width(nm_name_text, 1)
	texts.stroke_color(nm_name_text, 255,140,140)
    texts.stroke_alpha(nm_name_text, 100)
	texts.bg_alpha(nm_name_text, 0)
    texts.font(nm_name_text, 'Consolas')
    texts.draggable(nm_name_text, false)

    texts.visible(player_name_text, false)
	texts.size(player_name_text, 12 * settings.display.scale)
	texts.pos(player_name_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(player_name_text, 255,255,255)
	texts.stroke_width(player_name_text, 1)
	texts.stroke_color(player_name_text, 0,0,0)
    texts.stroke_alpha(player_name_text, 100)
	texts.bg_alpha(player_name_text, 0)
    texts.font(player_name_text, 'Consolas')
    texts.draggable(player_name_text, false)

    texts.visible(pc_name_text, false)
	texts.size(pc_name_text, 12 * settings.display.scale)
	texts.pos(pc_name_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(pc_name_text, 170,255,255)
	texts.stroke_width(pc_name_text, 1)
	texts.stroke_color(pc_name_text, 0,0,0)
    texts.stroke_alpha(pc_name_text, 100)
	texts.bg_alpha(pc_name_text, 0)
    texts.font(pc_name_text, 'Consolas')
    texts.draggable(pc_name_text, false)

    texts.visible(npc_name_text, false)
	texts.size(npc_name_text, 12 * settings.display.scale)
	texts.pos(npc_name_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(npc_name_text, 170,220,170)
	texts.stroke_width(npc_name_text, 1)
	texts.stroke_color(npc_name_text, 0,0,0)
    texts.stroke_alpha(npc_name_text, 100)
	texts.bg_alpha(npc_name_text, 0)
    texts.font(npc_name_text, 'Consolas')
    texts.draggable(npc_name_text, false)

    texts.visible(aggro_text, false)
	texts.size(aggro_text, 12 * settings.display.scale)
	texts.pos(aggro_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(aggro_text, 255,255,170)
	texts.stroke_width(aggro_text, 1)
	texts.stroke_color(aggro_text, 0,0,0)
    texts.stroke_alpha(npc_name_text, 100)
	texts.bg_alpha(aggro_text, 0)
    texts.font(aggro_text, 'Consolas')
    texts.draggable(aggro_text, false)

    texts.visible(resistance_text, false)
	texts.size(resistance_text, 12 * settings.display.scale)
	texts.pos(resistance_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
    texts.color(resistance_text, 255,255,170)
	texts.stroke_width(resistance_text, 1)
	texts.stroke_color(resistance_text, 0,0,0)
    texts.stroke_alpha(npc_name_text, 100)
	texts.bg_alpha(resistance_text, 0)
    texts.font(resistance_text, 'Consolas')
    texts.draggable(resistance_text, false)

    texts.visible(type_fire_text, false)
	texts.size(type_fire_text, 6 * settings.display.scale)
	texts.pos(type_fire_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_fire_text, 1)
	texts.stroke_color(type_fire_text, 0,0,0)
	texts.bg_alpha(type_fire_text, 0)
    texts.bold(type_fire_text, true)
    texts.draggable(type_fire_text, false)

    texts.visible(type_wind_text, false)
	texts.size(type_wind_text, 6 * settings.display.scale)
	texts.pos(type_wind_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_wind_text, 1)
	texts.stroke_color(type_wind_text, 0,0,0)
	texts.bg_alpha(type_wind_text, 0)
    texts.bold(type_wind_text, true)
    texts.draggable(type_wind_text, false)

    texts.visible(type_lightning_text, false)
	texts.size(type_lightning_text, 6 * settings.display.scale)
	texts.pos(type_lightning_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_lightning_text, 1)
	texts.stroke_color(type_lightning_text, 0,0,0)
	texts.bg_alpha(type_lightning_text, 0)
    texts.bold(type_lightning_text, true)
    texts.draggable(type_lightning_text, false)

    texts.visible(type_ice_text, false)
	texts.size(type_ice_text, 6 * settings.display.scale)
	texts.pos(type_ice_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_ice_text, 1)
	texts.stroke_color(type_ice_text, 0,0,0)
	texts.bg_alpha(type_ice_text, 0)
    texts.bold(type_ice_text, true)
    texts.draggable(type_ice_text, false)

    texts.visible(type_earth_text, false)
	texts.size(type_earth_text, 6 * settings.display.scale)
	texts.pos(type_earth_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_earth_text, 1)
	texts.stroke_color(type_earth_text, 0,0,0)
	texts.bg_alpha(type_earth_text, 0)
    texts.bold(type_earth_text, true)
    texts.draggable(type_earth_text, false)

    texts.visible(type_water_text, false)
	texts.size(type_water_text, 6 * settings.display.scale)
	texts.pos(type_water_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_water_text, 1)
	texts.stroke_color(type_water_text, 0,0,0)
	texts.bg_alpha(type_water_text, 0)
    texts.bold(type_water_text, true)
    texts.draggable(type_water_text, false)

    texts.visible(type_light_text, false)
	texts.size(type_light_text, 6 * settings.display.scale)
	texts.pos(type_light_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_light_text, 1)
	texts.stroke_color(type_light_text, 0,0,0)
	texts.bg_alpha(type_light_text, 0)
    texts.bold(type_light_text, true)
    texts.draggable(type_light_text, false)

    texts.visible(type_darkness_text, false)
	texts.size(type_darkness_text, 6 * settings.display.scale)
	texts.pos(type_darkness_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_darkness_text, 1)
	texts.stroke_color(type_darkness_text, 0,0,0)
	texts.bg_alpha(type_darkness_text, 0)
    texts.bold(type_darkness_text, true)
    texts.draggable(type_darkness_text, false)

    texts.visible(type_blunt_text, false)
	texts.size(type_blunt_text, 6 * settings.display.scale)
	texts.pos(type_blunt_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_blunt_text, 1)
	texts.stroke_color(type_blunt_text, 0,0,0)
	texts.bg_alpha(type_blunt_text, 0)
    texts.bold(type_blunt_text, true)
    texts.draggable(type_blunt_text, false)

    texts.visible(type_slashing_text, false)
	texts.size(type_slashing_text, 6 * settings.display.scale)
	texts.pos(type_slashing_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_slashing_text, 1)
	texts.stroke_color(type_slashing_text, 0,0,0)
	texts.bg_alpha(type_slashing_text, 0)
    texts.bold(type_slashing_text, true)
    texts.draggable(type_slashing_text, false)

    texts.visible(type_piercing_text, false)
	texts.size(type_piercing_text, 6 * settings.display.scale)
	texts.pos(type_piercing_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_piercing_text, 1)
	texts.stroke_color(type_piercing_text, 0,0,0)
	texts.bg_alpha(type_piercing_text, 0)
    texts.bold(type_piercing_text, true)
    texts.draggable(type_piercing_text, false)

    texts.visible(type_h2h_text, false)
	texts.size(type_h2h_text, 6 * settings.display.scale)
	texts.pos(type_h2h_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_h2h_text, 1)
	texts.stroke_color(type_h2h_text, 0,0,0)
	texts.bg_alpha(type_h2h_text, 0)
    texts.bold(type_h2h_text, true)
    texts.draggable(type_h2h_text, false)

    texts.visible(type_ranged_text, false)
	texts.size(type_ranged_text, 6 * settings.display.scale)
	texts.pos(type_ranged_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_ranged_text, 1)
	texts.stroke_color(type_ranged_text, 0,0,0)
	texts.bg_alpha(type_ranged_text, 0)
    texts.bold(type_ranged_text, true)
    texts.draggable(type_ranged_text, false)

    texts.visible(type_breath_text, false)
	texts.size(type_breath_text, 6 * settings.display.scale)
	texts.pos(type_breath_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_breath_text, 1)
	texts.stroke_color(type_breath_text, 0,0,0)
	texts.bg_alpha(type_breath_text, 0)
    texts.bold(type_breath_text, true)
    texts.draggable(type_breath_text, false)

    texts.visible(type_magical_text, false)
	texts.size(type_magical_text, 6 * settings.display.scale)
	texts.pos(type_magical_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_magical_text, 1)
	texts.stroke_color(type_magical_text, 0,0,0)
	texts.bg_alpha(type_magical_text, 0)
    texts.bold(type_magical_text, true)
    texts.draggable(type_magical_text, false)

    texts.visible(type_physical_text, false)
	texts.size(type_physical_text, 6 * settings.display.scale)
	texts.pos(type_physical_text, (settings.display.pos.x) * settings.display.scale, (settings.display.pos.y) * settings.display.scale)
	texts.stroke_width(type_physical_text, 1)
	texts.stroke_color(type_physical_text, 0,0,0)
	texts.bg_alpha(type_physical_text, 0)
    texts.bold(type_physical_text, true)
    texts.draggable(type_physical_text, false)

end

function render_libra(textTypeUsed)
    local runningHeight = 0
    local runningWidth = 0
    local singleLineBumper = 0
    if (libra.mob_name) then
        if (libra.mob_name ~= '') then
            texts.pos(textTypeUsed, (settings.display.pos.x), (settings.display.pos.y + runningHeight))
            local nameElement = libra.mob_name
            if (libra.family and libra.family ~= '') then
                nameElement = nameElement .. ' (' .. libra.family .. ')'
            end
            if (libra.level and libra.level ~= '') then
                nameElement = nameElement .. '  Lv ' .. libra.level
            end
            if (libra.job and libra.job ~= '') then
                nameElement = nameElement .. '  ' .. libra.job
            end
            texts.text(textTypeUsed, nameElement)
            texts.visible(textTypeUsed, true)
            dependentExtent = textTypeUsed
            if (nameElement) then
                runningWidth = currentXExtent
            end
     
        end
        if (libra.res and next(libra.res) ~= nil) then
            local singleLineOffset = 0
            if (settings.display.multiline) then 
                runningHeight = runningHeight + (currentYExtent)
            else
                singleLineOffset = runningWidth + 20
            end
            texts.pos(resistance_text, (settings.display.pos.x + singleLineOffset), (settings.display.pos.y + runningHeight))
            local resistanceElement = 'Weak/Res:'
            texts.text(resistance_text, resistanceElement)
            tempRunningWidth = update_and_show_res_sprites(libra.res, 90, runningHeight + (3 * settings.display.scale), singleLineOffset)
            if settings.display.multiline then
                if (tempRunningWidth > runningWidth) then
                    runningWidth = tempRunningWidth
                end
            else
                runningWidth = tempRunningWidth
            end
            texts.visible(resistance_text, true)
        end
        if (libra.aggro and next(libra.aggro) ~= nil) then
            local singleLineOffset = 0
            if (settings.display.multiline) then 
                runningHeight = runningHeight + (currentYExtent)
            else
                singleLineOffset = runningWidth + 20
            end
            texts.pos(aggro_text, (settings.display.pos.x + singleLineOffset), (settings.display.pos.y + runningHeight))
            local aggroElement = 'Aggro:'
            texts.text(aggro_text, aggroElement)
            local tempRunningWidth = update_and_show_aggro_sprites(libra.aggro, 60, runningHeight + (3 * settings.display.scale), singleLineOffset)
            if settings.display.multiline then
                if (tempRunningWidth > runningWidth) then
                    runningWidth = tempRunningWidth
                end
            else
                runningWidth = tempRunningWidth
            end
            texts.visible(aggro_text, true)
        end
    end
    if not settings.display.multiline then
        singleLineBumper = 20 * settings.display.scale
    end
    update_and_show_background_sprites(runningWidth + singleLineBumper, runningHeight + (currentYExtent))
end

function relevantPercentage(key)
    local percentageText = nil
    if (key == 'Fi') then
        percentageText = type_fire_text
    elseif (key == 'Wi') then
        percentageText = type_wind_text
    elseif (key == 'Th') then
        percentageText = type_lightning_text
    elseif (key == 'Ic') then
        percentageText = type_ice_text
    elseif (key == 'Ea') then
        percentageText = type_earth_text
    elseif (key == 'Wa') then
        percentageText = type_water_text
    elseif (key == 'Li') then
        percentageText = type_light_text
    elseif (key == 'Da') then
        percentageText = type_darkness_text
    elseif (key == 'Bl') then
        percentageText = type_blunt_text
    elseif (key == 'Sl') then
        percentageText = type_slashing_text
    elseif (key == 'Pi') then
        percentageText = type_piercing_text
    elseif (key == 'H2H') then
        percentageText = type_h2h_text
    elseif (key == 'Ra') then
        percentageText = type_ranged_text
    elseif (key == 'Br') then
        percentageText = type_breath_text
    elseif (key == 'Ma') then
        percentageText = type_magical_text
    elseif (key == 'Ph') then
        percentageText = type_physical_text
    end
    return percentageText
end

function update_and_show_res_sprites(table, xoffset, yoffset, singleLineOffset)
    local x_pos_shift = (xoffset * settings.display.scale) + singleLineOffset;
    for i, key in ipairs(properResKeyOrder) do
        local value = table[key]
        if value then
            windower.prim.set_color(key, 255, 255, 255, 255)
            windower.prim.set_position(key, (settings.display.pos.x + x_pos_shift), (settings.display.pos.y + yoffset))
            local percentage = relevantPercentage(key)
            if percentage ~= nil and value then
                texts.pos(percentage, (settings.display.pos.x + (x_pos_shift - 2)), (settings.display.pos.y + (yoffset + (8 * settings.display.scale))))
                if (value == -100) then
                    texts.text(percentage, 'Imm.')
                    texts.color(percentage, 255, 0, 0)
                elseif (value > 0) then
                    texts.text(percentage, '+' .. tostring(value) .. '%')
                    texts.color(percentage, 125, 200, 125)
                elseif (value < 0) then
                    texts.text(percentage, '' .. tostring(value) .. '%')
                    texts.color(percentage, 200, 125, 125)
                end
                texts.visible(percentage, true)
            end
            x_pos_shift = x_pos_shift + (25 * settings.display.scale)
        end
    end
    return x_pos_shift
 end

 function update_and_show_background_sprites(runningWidth, runningHeight)
    windower.prim.set_color('BackgroundLeft', 255 * settings.display.alpha, 255, 255, 255)
    windower.prim.set_size('BackgroundLeft', settings.display.padding * settings.display.scale, ((runningHeight + (settings.display.padding * 2) )))
    windower.prim.set_position('BackgroundLeft', (settings.display.pos.x) - (settings.display.padding * settings.display.scale), (settings.display.pos.y - settings.display.padding))

    windower.prim.set_color('Background', 255 * settings.display.alpha, 255, 255, 255)
    windower.prim.set_size('Background', (runningWidth), ((runningHeight + (settings.display.padding * 2) )))
    windower.prim.set_position('Background', (settings.display.pos.x), (settings.display.pos.y - settings.display.padding))

    windower.prim.set_color('BackgroundRight', 255 * settings.display.alpha, 255, 255, 255)
    windower.prim.set_size('BackgroundRight',  settings.display.padding * settings.display.scale, ((runningHeight + (settings.display.padding * 2) )))
    windower.prim.set_position('BackgroundRight', ((settings.display.pos.x) + (runningWidth)), (settings.display.pos.y - settings.display.padding))
 end

 function update_and_show_aggro_sprites(table, xoffset, yoffset, singleLineOffset)
    local x_pos_shift = (xoffset * settings.display.scale) + singleLineOffset;
    for i, key in ipairs(properAggroKeyOrder) do
        local value = table[i]
        if value then
            windower.prim.set_color(value, 255, 255, 255, 255)
            windower.prim.set_position(value, (settings.display.pos.x + x_pos_shift), (settings.display.pos.y + yoffset))
            x_pos_shift = x_pos_shift + (25 * settings.display.scale)
        end
    end
    return x_pos_shift - (25 * settings.display.scale)
 end


function hide_libra_texts()
    texts.visible(mob_name_text, false)
    texts.visible(nm_name_text, false)
    texts.visible(player_name_text, false)
    texts.visible(pc_name_text, false)
    texts.visible(npc_name_text, false)
    texts.visible(aggro_text, false)
    texts.visible(resistance_text, false)
    texts.visible(notes_text, false)

    texts.visible(type_fire_text, false)
    texts.visible(type_wind_text, false)
    texts.visible(type_lightning_text, false)
    texts.visible(type_ice_text, false)
    texts.visible(type_earth_text, false)
    texts.visible(type_water_text, false)
    texts.visible(type_light_text, false)
    texts.visible(type_darkness_text, false)
    texts.visible(type_blunt_text, false)
    texts.visible(type_slashing_text, false)
    texts.visible(type_piercing_text, false)
    texts.visible(type_h2h_text, false)
    texts.visible(type_ranged_text, false)
    texts.visible(type_breath_text, false)
    texts.visible(type_magical_text, false)
    texts.visible(type_physical_text, false)

end

function hide_libra_sprites()
    windower.prim.set_color('BackgroundLeft', 0, 0, 0, 0)
    windower.prim.set_color('BackgroundRight', 0, 0, 0, 0)
    windower.prim.set_color('Background', 0, 0, 0, 0)
    windower.prim.set_color('Fi', 0, 0, 0, 0)
    windower.prim.set_color('Wi', 0, 0, 0, 0)
    windower.prim.set_color('Th', 0, 0, 0, 0)
    windower.prim.set_color('Ic', 0, 0, 0, 0)
    windower.prim.set_color('Ea', 0, 0, 0, 0)
    windower.prim.set_color('Wa', 0, 0, 0, 0)
    windower.prim.set_color('Li', 0, 0, 0, 0)
    windower.prim.set_color('Da', 0, 0, 0, 0)
    windower.prim.set_color('Pi', 0, 0, 0, 0)
    windower.prim.set_color('Bl', 0, 0, 0, 0)
    windower.prim.set_color('Sl', 0, 0, 0, 0)
    windower.prim.set_color('H2H', 0, 0, 0, 0)
    windower.prim.set_color('Ra', 0, 0, 0, 0)
    windower.prim.set_color('Br', 0, 0, 0, 0)
    windower.prim.set_color('Ma', 0, 0, 0, 0)
    windower.prim.set_color('Ph', 0, 0, 0, 0)
    windower.prim.set_color('passive', 0, 0, 0, 0)
    windower.prim.set_color('links', 0, 0, 0, 0)
    windower.prim.set_color('detectSight', 0, 0, 0, 0)
    windower.prim.set_color('detectSound', 0, 0, 0, 0)
    windower.prim.set_color('detectMagic', 0, 0, 0, 0)
    windower.prim.set_color('detectLowHP', 0, 0, 0, 0)
    windower.prim.set_color('detectJobAb', 0, 0, 0, 0)
    windower.prim.set_color('detectTruSight', 0, 0, 0, 0)
    windower.prim.set_color('detectTruSound', 0, 0, 0, 0)
end


function getDegrees(value)
    return math.round(360 / math.tau * value)
end

local dir_sets = L{'W', 'WNW', 'NW', 'NNW', 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W'}
function DegreesToDirection(val)
    return dir_sets[math.round((val + math.pi) / math.pi * 8) + 1]
end

function combineStrings(string1, string2)
    local finalValue = ''
	if (string1 ~= nil and string2 ~= nil) then
		if (string1 ~= 'None' and string2 ~= 'None') then
			finalValue = string1 .. ', ' .. string2
		elseif (string1 == 'None' and string2 ~= 'None') then
			finalValue = string2
		elseif (string1 ~= 'None' and string2 == 'None') then
			finalValue = string1
		end
	end
    return finalValue
end

function get_db(target, zones, level)
    local mobQuery = 'SELECT * FROM "mobs" WHERE name = "'..target..'" AND zone = "'..zones..'"'
    libra = {}
    if mobsdb:isopen() and mobQuery then
        for id, name,family,zone,level,job,passive,link,nm,url,notes in mobsdb:urows(mobQuery) do
            local mobJob = job
            if name == target and zone == zones and family then
                -- get family info
                local familyQuery = 'SELECT * FROM "families" WHERE family = "'..family..'"'
                if familiesdb:isopen() and familyQuery then
                    for family,mobType,job,detectSight,detectSound,detectMagic,detectLowHP,detectJobAb,detectTruSight,detectTruSound,physical,magical,breath,slashing,blunt,hand2hand,piercing,ranged,fire,wind,lightning,light,ice,earth,water,dark,needsManualSubfamily in familiesdb:urows(familyQuery) do
                        currentMobAllRes = format_damage_type_table(physical,magical,breath,slashing,blunt,hand2hand,piercing,ranged,fire,wind,lightning,light,ice,earth,water,dark)
                        libra.mob_name = name or ''
                        libra.family = family or ''
                        libra.mobtype = mobType or ''
                        libra.job = mobJob or ''
                        if libra.job == '???' then
                            libra.job = job or ''
                        end
                        libra.level = level or ''
                        libra.nm = nm

                        libra.res = currentMobAllRes

                        libra.innacurateWarning = needsManualSubfamily or ''

                        libra.aggro = format_aggro_type_table(passive,link,detectSight,detectSound,detectMagic,detectLowHP,detectJobAb,detectTruSight,detectTruSound)

                    end
                end
            else
                libra.mob_name = 'No information for ' .. target .. ' in ' .. zone
            end

        end
    end
    if libra.nm == 1 then
        render_libra(nm_name_text)
    else
        render_libra(mob_name_text)
    end
end

function render_non_mob(textTypeUsed)
    local runningHeight = 0
    local runningWidth = 0
    if (libra.target_name ~= '') then
        texts.pos(textTypeUsed, (settings.display.pos.x), (settings.display.pos.y + runningHeight))
        local nameElement = checkCraftGuildNPC(libra.target_name)
        if (libra.main_job and libra.main_job ~= '' and libra.main_job_level and libra.main_job_level ~= '') then
            nameElement = nameElement .. ' (' .. libra.main_job .. libra.main_job_level
            if (libra.sub_job and libra.sub_job ~= '' and libra.sub_job_level and libra.sub_job_level ~= '') then
                nameElement = nameElement .. '/' .. libra.sub_job .. libra.sub_job_level .. ')'
            else
                nameElement = nameElement .. ')'
            end
        elseif (libra.target_race and libra.target_race >= 0 and libra.target_race < 9) then
            if (libra.target_race == 0) then
                nameElement = nameElement .. ' (NPC)'
            elseif (libra.target_race == 1 or libra.target_race == 2) then
                nameElement = nameElement .. ' (Hume)'
            elseif (libra.target_race == 3 or libra.target_race == 4) then
                nameElement = nameElement .. ' (Elvaan)'
            elseif (libra.target_race == 5 or libra.target_race == 6) then
                nameElement = nameElement .. ' (Tarutaru)'
            elseif (libra.target_race == 7) then
                nameElement = nameElement .. ' (Mithra)'
            elseif (libra.target_race == 8) then
                nameElement = nameElement .. ' (Galka)'
            end
        end
        texts.text(textTypeUsed, nameElement)
        texts.visible(textTypeUsed, true)
        dependentExtent = textTypeUsed
        if (nameElement) then
            runningWidth = currentXExtent
        end
    end
    update_and_show_background_sprites(runningWidth, runningHeight + (currentYExtent))
end

function checkCraftGuildNPC(name)
    local newName = name
    if (name == 'Doggomehr' and libra.smithing) then
        newName = name .. libra.smithing
        libra.target_race = 11
    elseif (name == 'Amulya' and libra.smithing) then
        newName = name .. libra.smithing
        libra.target_race = 11
    elseif (name == 'Kamilah' and libra.smithing) then
        newName = name .. libra.smithing
        libra.target_race = 11
    elseif (name == 'Maymunah' and libra.alchemy) then
        newName = name .. libra.alchemy
        libra.target_race = 11
    elseif (name == 'Wahraga' and libra.alchemy) then
        newName = name .. libra.alchemy
        libra.target_race = 11
    elseif (name == 'Gathweeda' and libra.alchemy) then
        newName = name .. libra.alchemy
        libra.target_race = 11
    elseif (name == 'Shih Tayuun' and libra.bonecraft) then
        newName = name .. libra.bonecraft
        libra.target_race = 11
    elseif (name == 'Kuzah Hpirohpon' and libra.clothcraft) then
        newName = name .. libra.clothcraft
        libra.target_race = 11
    elseif (name == 'Tilala' and libra.clothcraft) then
        newName = name .. libra.clothcraft
        libra.target_race = 11
    elseif (name == 'Kopopo' and libra.cooking) then
        newName = name .. libra.cooking
        libra.target_race = 11
    elseif (name == 'Babubu' and libra.fishing) then
        newName = name .. libra.fishing
        libra.target_race = 11
    elseif (name == 'Mendoline' and libra.fishing) then
        newName = name .. libra.fishing
        libra.target_race = 11
    elseif (name == 'Graegham' and libra.fishing) then
        newName = name .. libra.fishing
        libra.target_race = 11
    elseif (name == 'Yabby Tanmikey' and libra.goldsmithing) then
        newName = name .. libra.goldsmithing
        libra.target_race = 11
    elseif (name == 'Visala' and libra.goldsmithing) then
        newName = name .. libra.goldsmithing
        libra.target_race = 11
    elseif (name == 'Bornahn' and libra.goldsmithing) then
        newName = name .. libra.goldsmithing
        libra.target_race = 11
    elseif (name == 'Kueh Igunahmori' and libra.leathercraft) then
        newName = name .. libra.leathercraft
        libra.target_race = 11
    elseif (name == 'Chaupire' and libra.woodworking) then
        newName = name .. libra.woodworking
        libra.target_race = 11
    elseif (name == 'Dehbi Moshal' and libra.woodworking) then
        newName = name .. libra.woodworking
        libra.target_race = 11
    end
    return newName
end


function get_target(index)
    hide_libra_sprites()
    hide_libra_texts()
    clear_libra_variables()
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
    libra.target_name = target.name
    libra.target_id = target.id
    libra.target_index = target.index
    libra.target_race = target.race
    if index == 0 or index == player.index then
        libra.main_job = player.main_job
        libra.main_job_level = player.main_job_level
        libra.sub_job = player.sub_job
        libra.sub_job_level = player.sub_job_level
        render_non_mob(player_name_text)
    else
        if target.spawn_type == 13 or target.spawn_type == 14 or target.spawn_type == 9 or target.spawn_type == 1 then
            if target.spawn_type == 1 then
                render_non_mob(player_name_text)
            else
                render_non_mob(pc_name_text)
            end
        elseif target.spawn_type == 2 or target.spawn_type == 34 then
            libra.target_race = 0
            render_non_mob(npc_name_text)
        elseif target.spawn_type == 16 then
            local zone = res.zones[windower.ffxi.get_info().zone].name
            get_db(target.name, zone, player.main_job_level)
        end
    end
end

function clear_libra_variables()
    libra.mob_name = nil
    libra.family = nil
    libra.mobtype = nil
    libra.job = nil
    libra.level = nil
    libra.res = nil
    libra.innacurateWarning = nil
    libra.aggro = nil
    libra.target_name = nil
    libra.target_id = nil
    libra.target_index = nil
    libra.target_race = nil
    libra.main_job = nil
    libra.main_job_level = nil
    libra.sub_job = nil
    libra.sub_job_level = nil
    dependentExtent = nil
    currentXExtent = 0
    currentYExtent = 0
end

math.round = function(n) return n >= 0.0 and n-n%-1 or n-n% 1 end

function format_damage_type_table(physical,magical,breath,slashing,blunt,hand2hand,piercing,ranged,fire,wind,lightning,light,ice,earth,water,dark)
    local all = {}
    if physical then
        if physical == -100 then
            all['Ph'] = math.round(physical)
        elseif physical ~= 100 then
            all['Ph'] = math.round(physical) - 100
        end
    end
    if magical then
        if magical == -100 then
            all['Ma'] = math.round(magical)
        elseif magical ~= 100 then
            all['Ma'] = math.round(magical) - 100
        end
    end
    if breath then
        if breath == -100 then
            all['Br'] = math.round(breath)
        elseif breath ~= 100 then
            all['Br'] = math.round(breath) - 100
        end
    end
    if slashing then
        if slashing == -100 then
            all['Sl'] = math.round(slashing)
        elseif slashing ~= 100 then
            all['Sl'] = math.round(slashing) - 100
        end
    end
    if blunt then
        if blunt == -100 then
            all['Bl'] = math.round(blunt)
        elseif blunt ~= 100 then
            all['Bl'] = math.round(blunt) - 100
        end
    end
    if hand2hand then
        if hand2hand == -100 then
            all['H2H'] = math.round(hand2hand)
        elseif hand2hand ~= 100 then
            all['H2H'] = math.round(hand2hand) - 100
        end
    end
    if piercing then
        if piercing == -100 then
            all['Pi'] = math.round(piercing)
        elseif piercing ~= 100 then
            all['Pi'] = math.round(piercing) - 100
        end
    end
    if ranged then
        if ranged == -100 then
            all['Ra'] = math.round(ranged)
        elseif ranged ~= 100 then
            all['Ra'] = math.round(ranged) - 100
        end
    end
    if fire then
        if fire == -100 then
            all['Fi'] = math.round(fire)
        elseif fire ~= 100 then
            all['Fi'] = math.round(fire) - 100
        end
    end
    if wind then
        if wind == -100 then
            all['Wi'] = math.round(wind)
        elseif wind ~= 100 then
            all['Wi'] = math.round(wind) - 100
        end
    end
    if lightning then
        if lightning == -100 then
            all['Th'] = math.round(lightning)
        elseif lightning ~= 100 then
            all['Th'] = math.round(lightning) - 100
        end
    end
    if light then
        if light == -100 then
            all['Li'] = math.round(light)
        elseif light ~= 100 then
            all['Li'] = math.round(light) - 100
        end
    end
    if ice then
        if ice == -100 then
            all['Ic'] = math.round(ice)
        elseif ice ~= 100 then
            all['Ic'] = math.round(ice) - 100
        end
    end
    if earth then
        if earth == -100 then
            all['Ea'] = math.round(earth)
        elseif earth ~= 100 then
            all['Ea'] = math.round(earth) - 100
        end
    end
    if water then
        if water == -100 then
            all['Wa'] = math.round(water)
        elseif water ~= 100 then
            all['Wa'] = math.round(water) - 100
        end
    end
    if dark then
        if dark == -100 then
            all['Da'] = math.round(dark)
        elseif dark ~= 100 then
            all['Da'] = math.round(dark) - 100
        end
    end
    return all
end

function format_aggro_type_table(passive,link,detectSight,detectSound,detectMagic,detectLowHP,detectJobAb,detectTruSight,detectTruSound)
    local aggro = {}
    if passive ~= 'YES' then
        if detectSight == 1 then
            table.insert(aggro, 'detectSight')
        end
        if detectSound == 1 then
            table.insert(aggro, 'detectSound')
        end
        if detectMagic == 1 then
            table.insert(aggro, 'detectMagic')
        end
        if detectLowHP == 1 then
            table.insert(aggro, 'detectLowHP')
        end
        if detectJobAb == 1 then
            table.insert(aggro, 'detectJobAb')
        end
        if detectTruSight == 1 then
            table.insert(aggro, 'detectTruSight')
        end
        if detectTruSound == 1 then
            table.insert(aggro, 'detectTruSound')
        end
    else
        table.insert(aggro, 'passive')
    end
    if link == 'YES' then
        table.insert(aggro, 'links')
    end
    return aggro
end

function refresh()
    load_sprites()
    load_texts()
    get_target(windower.ffxi.get_player().index)
end

windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
    if id == 0xB then
        zoning_bool = true
    elseif id == 0xA then
        zoning_bool = false
    end
end)

windower.register_event('prerender', function()
    local info = windower.ffxi.get_info()

    if not info.logged_in or not windower.ffxi.get_player() or zoning_bool then
        -- box:hide()
        hide_libra_texts()
        hide_libra_sprites()
        clear_libra_variables()
        return
    end
    if dependentExtent then
        previousXExtent = currentXExtent
        previousYExtent = currentYExtent
        currentXExtent, currentYExtent = texts.extents(dependentExtent)
        if previousXExtent ~= 0 and currentXExtent == previousXExtent then
            if libra.mob_name then
                if libra.nm == 1 then
                    render_libra(nm_name_text)
                else
                    render_libra(mob_name_text)
                end
            else
                render_non_mob(dependentExtent)
            end
            dependentExtent = nil
        end
    end
end)

windower.register_event('target change', get_target)
windower.register_event('job change', function()
    get_target(windower.ffxi.get_player().index)
end)

windower.register_event('time change', function(new, old)
    local alchemy = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    libra.alchemy = ' (Open 8:00 - 23:00, Currently: ' .. (alchemy == "Closed" and '\\cs(255,0,0)'..alchemy..'\\cr' or '\\cs(0,255,0)'..alchemy..'\\cr') .. ')'
    local bonecraft = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    libra.bonecraft = ' (Open 8:00 - 23:00, Currently: ' .. (bonecraft == "Closed" and '\\cs(255,0,0)'..bonecraft..'\\cr' or '\\cs(0,255,0)'..bonecraft..'\\cr') .. ')'
    local clothcraft = new >= 6*60 and new <= 21*60 and 'Open' or 'Closed'
    libra.clothcraft = ' (Open 6:00 - 21:00, Currently: ' .. (clothcraft == "Closed" and '\\cs(255,0,0)'..clothcraft..'\\cr' or '\\cs(0,255,0)'..clothcraft..'\\cr') .. ')'
    local cooking = new >= 5*60 and new <= 20*60 and 'Open' or 'Closed'
    libra.cooking = ' (Open 5:00 - 20:00, Currently: ' .. (cooking == "Closed" and '\\cs(255,0,0)'..cooking..'\\cr' or '\\cs(0,255,0)'..cooking..'\\cr') .. ')'
    local fishing = new >= 3*60 and new <= 18*60 and 'Open' or 'Closed'
    libra.fishing = ' (Open 3:00 - 18:00, Currently: ' .. (fishing == "Closed" and '\\cs(255,0,0)'..fishing..'\\cr' or '\\cs(0,255,0)'..fishing..'\\cr') .. ')'
    local goldsmithing = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    libra.goldsmithing = ' (Open 8:00 - 23:00, Currently: ' .. (goldsmithing == "Closed" and '\\cs(255,0,0)'..goldsmithing..'\\cr' or '\\cs(0,255,0)'..goldsmithing..'\\cr') .. ')'
    local leathercraft = new >= 3*60 and new <= 18*60 and 'Open' or 'Closed'
    libra.leathercraft = ' (Open 3:00 - 18:00, Currently: ' .. (leathercraft == "Closed" and '\\cs(255,0,0)'..leathercraft..'\\cr' or '\\cs(0,255,0)'..leathercraft..'\\cr') .. ')'
    local smithing = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    libra.smithing = ' (Open 8:00 - 23:00, Currently: ' .. (smithing == "Closed" and '\\cs(255,0,0)'..smithing..'\\cr' or '\\cs(0,255,0)'..smithing..'\\cr') .. ')'
    local woodworking = new >= 6*60 and new <= 21*60 and 'Open' or 'Closed'
    libra.woodworking = ' (Open 6:00 - 21:00, Currently: ' .. (woodworking == "Closed" and '\\cs(255,0,0)'..woodworking..'\\cr' or '\\cs(0,255,0)'..woodworking..'\\cr') .. ')'
    -- box:update(infobar)
end)

windower.register_event('addon command', function(...)
    local args = T{...}
    if args[1] then
        if args[1]:lower() == 'help' or args[1]:lower() == 'config' then
            windower.add_to_chat(207,"Libra Commands:")
            windower.add_to_chat(207,"//libra scale <number 0.5 through 3>")
            windower.add_to_chat(207,"//libra pos <x_value> <y_value>")
            windower.add_to_chat(207,"//libra padding <number>")
            windower.add_to_chat(207,"//libra alpha <number 0 through 1>")
            windower.add_to_chat(207,"//libra multiline <yes or no>")
            windower.add_to_chat(207,"Current scale: " .. settings.display.scale)
            windower.add_to_chat(207,"Current position: x" .. settings.display.pos.x .. " y" .. settings.display.pos.y)
            windower.add_to_chat(207,"Current padding: " .. settings.display.padding)
            windower.add_to_chat(207,"Current alpha: " .. settings.display.alpha)
            windower.add_to_chat(207,"Multi-line mode: " .. settings.display.multiline)
        elseif args[1]:lower() == 'scale' then
            if not args[2] then
                windower.add_to_chat(207,"Libra: Second argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) then
                local newScale = tonumber(args[2])
                if newScale > 3 or newScale < 0.5 then
                    windower.add_to_chat(207,"Libra: Scale must be a number between 0.5 and 3, decimals are allowed")
                else
                    settings.display.scale = newScale
                    config.save(settings)
                    refresh()
                    windower.add_to_chat(207,"Libra: Scale now set to " .. newScale)
                end
            else
                windower.add_to_chat(207,"Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'pos' then
            if not args[2] then
                windower.add_to_chat(207,"Libra: Second argument not specified, use '//libra help' for info.")
            elseif not args[3] then
                windower.add_to_chat(207,"Libra: Third argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) and tonumber(args[3]) then
                local newX = tonumber(args[2])
                local newY = tonumber(args[3])
                settings.display.pos.x = newX
                settings.display.pos.y = newY
                config.save(settings)
                refresh()
                windower.add_to_chat(207,"Libra: Position now set to x" .. newX .. " y" .. newY)
            else
                windower.add_to_chat(207,"Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'padding' then
            if not args[2] then
                windower.add_to_chat(207,"Libra: Second argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) then
                local newPadding = tonumber(args[2])
                settings.display.padding = newPadding
                config.save(settings)
                refresh()
                windower.add_to_chat(207,"Libra: Padding now set to " .. newPadding)
            else
                windower.add_to_chat(207,"Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'alpha' then
            if not args[2] then
                windower.add_to_chat(207,"Libra: Second argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) then
                local newAlpha = tonumber(args[2])
                if newAlpha > 1 or newAlpha < 0 then
                    windower.add_to_chat(207,"Libra: Alpha must be a number between 0 and 1")
                else
                    settings.display.alpha = newAlpha
                    config.save(settings)
                    refresh()
                    windower.add_to_chat(207,"Libra: Alpha now set to " .. newAlpha)
                end
            else
                windower.add_to_chat(207,"Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'multiline' then
            if not args[2] then
                windower.add_to_chat(207,"Libra: Second argument not specified, use '//libra help' for info.")
            elseif string.lower(args[2]) == 'yes' or string.lower(args[2]) == 'no' then
                local newMultiline = false
                if string.lower(args[2]) == 'yes' then
                    newMultiline = true
                end
                settings.display.multiline = newMultiline
                config.save(settings)
                refresh()
                windower.add_to_chat(207,"Libra: Multi-line mode is now set to " .. tostring(newMultiline))
            else
                windower.add_to_chat(207,"Libra: Second argument wrong, use '//libra help' for info.")
            end
        else
            windower.add_to_chat(207,"Libra: First argument wrong, use '//libra help' for info.")
        end
    else
        windower.add_to_chat(207,"Libra: First argument not specified, use '//libra help' for info.")
    end
end)
