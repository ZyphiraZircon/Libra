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
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]] -- No AI was used in the making of this AddOn
_addon.name = 'Libra'
_addon.author = 'Zyphira, based on InfoBar by Kenshi'
_addon.version = '1.1.0'
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
local properResKeyOrder = {"Ph", "Ma", "Br", "Sl", "Bl", "H2H", "Pi", "Ra", "Fi", "Wi", "Th", "Li", "Ic", "Ea", "Wa",
                           "Da"}
local properAggroKeyOrder = {"passive", "links", "detectSight", "detectTruSight", "detectSound", "detectTruSound",
                             "detectMagic", "detectLowHP", "detectJobAb"}
local spriteNamesList = {"BackgroundLeft", "BackgroundRight", "Background", "Fi", "Wi", "Th", "Ic", "Ea", "Wa", "Li",
                         "Da", "Pi", "Bl", "Sl", "H2H", "Ra", "Br", "Ma", "Ph", "passive", "links", "detectSight",
                         "detectSound", "detectMagic", "detectLowHP", "detectJobAb", "detectTruSight", "detectTruSound"}

local textObjectsList = {mob_name_text, nm_name_text, player_name_text, pc_name_text, npc_name_text, aggro_text,
                         resistance_text, notes_text, type_fire_text, type_wind_text, type_lightning_text,
                         type_ice_text, type_earth_text, type_water_text, type_light_text, type_darkness_text,
                         type_blunt_text, type_slashing_text, type_piercing_text, type_h2h_text, type_ranged_text,
                         type_breath_text, type_magical_text, type_physical_text}

local percentageTextKeyValue = {
    ["Fi"] = type_fire_text,
    ["Wi"] = type_wind_text,
    ["Th"] = type_lightning_text,
    ["Ic"] = type_ice_text,
    ["Ea"] = type_earth_text,
    ["Wa"] = type_water_text,
    ["Li"] = type_light_text,
    ["Da"] = type_darkness_text,
    ["Pi"] = type_piercing_text,
    ["Bl"] = type_blunt_text,
    ["Sl"] = type_slashing_text,
    ["H2H"] = type_h2h_text,
    ["Ra"] = type_ranged_text,
    ["Br"] = type_breath_text,
    ["Ma"] = type_magical_text,
    ["Ph"] = type_physical_text
}

local raceTable = {"Interactable", "Hume ♂", "Hume ♀", "Elvaan ♂", "Elvaan ♀", "Tarutaru ♂", "Tarutaru ♀",
                   "Mithra", "Galka"}

windower.register_event('load', function()
    load_sprites()
    load_texts()
    mobsdb = sqlite3.open(windower.addon_path .. '/mobs.db')
    familiesdb = sqlite3.open(windower.addon_path .. '/families.db')
    guildNpcsdb = sqlite3.open(windower.addon_path .. '/guild_npcs.db')
    if not windower.ffxi.get_info().logged_in then
        return
    end
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or
                       windower.ffxi.get_player()
    get_target(target.index)
end)

windower.register_event('unload', function()
    mobsdb:close()
    familiesdb:close()
    guildNpcsdb:close()
    unload_sprites()
    unload_texts()
end)

function load_sprites()
    for i, value in ipairs(spriteNamesList) do
        windower.prim.create(value)
        windower.prim.set_color(value, 0, 0, 0, 0)
        windower.prim.set_fit_to_texture(value, false)
        windower.prim.set_texture(value, windower.addon_path .. 'assets/' .. value .. '.png')
        windower.prim.set_repeat(value, 1, 1)
        windower.prim.set_visibility(value, true)
        windower.prim.set_position(value, (settings.display.pos.x * settings.display.scale),
            (settings.display.pos.x * settings.display.scale))
        windower.prim.set_size(value, spritesWidth * settings.display.scale, spritesWidth * settings.display.scale)
    end
end

function unload_sprites()
    for i, value in ipairs(spriteNamesList) do
        windower.prim.delete(value)
    end
end

function load_texts()
    for i, value in ipairs(textObjectsList) do
        texts.visible(value, false)
        texts.size(value, 12 * settings.display.scale)
        texts.pos(value, (settings.display.pos.x) * settings.display.scale,
            (settings.display.pos.y) * settings.display.scale)
        texts.color(value, 255, 255, 225)
        texts.stroke_width(value, 1)
        texts.stroke_color(value, 0, 0, 0)
        texts.stroke_alpha(value, 100)
        texts.bg_alpha(value, 0)
        texts.font(value, 'Consolas')
        texts.draggable(value, false)
    end

    -- manual color settings
    texts.color(mob_name_text, 255, 255, 170)
    texts.stroke_color(nm_name_text, 255, 140, 140)
    texts.color(player_name_text, 255, 255, 255)
    texts.color(pc_name_text, 170, 255, 255)
    texts.color(npc_name_text, 170, 220, 170)
    texts.color(aggro_text, 255, 255, 170)
    texts.color(resistance_text, 255, 255, 170)
end

function unload_texts()
    for i, value in ipairs(textObjectsList) do
        texts.destroy(value)
    end
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
            texts.pos(resistance_text, (settings.display.pos.x + singleLineOffset),
                (settings.display.pos.y + runningHeight))
            local resistanceElement = 'Weak/Res:'
            texts.text(resistance_text, resistanceElement)
            tempRunningWidth = update_and_show_res_sprites(libra.res, 90, runningHeight + (3 * settings.display.scale),
                singleLineOffset)
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
            local tempRunningWidth = update_and_show_aggro_sprites(libra.aggro, 60,
                runningHeight + (3 * settings.display.scale), singleLineOffset)
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

    for k, value in pairs(percentageTextKeyValue) do
        if k == key then
            percentageText = value
        end
    end
    return percentageText
end

function update_and_show_res_sprites(table, xoffset, yoffset, singleLineOffset)
    local x_pos_shift = (xoffset * settings.display.scale) + singleLineOffset;
    for i, key in ipairs(properResKeyOrder) do
        local value = table[key]
        if value and value ~= 0 then
            windower.prim.set_color(key, 255, 255, 255, 255)
            windower.prim.set_position(key, (settings.display.pos.x + x_pos_shift), (settings.display.pos.y + yoffset))
            local percentage = relevantPercentage(key)
            if percentage ~= nil and value then
                texts.pos(percentage, (settings.display.pos.x + (x_pos_shift - 2)),
                    (settings.display.pos.y + (yoffset + (8 * settings.display.scale))))
                texts.size(percentage, 6 * settings.display.scale)
                texts.stroke_alpha(percentage, 255)
                texts.font(percentage, 'Arial')
                texts.bold(percentage, true)
                if (value == -200) then
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
    windower.prim.set_size('BackgroundLeft', settings.display.padding * settings.display.scale,
        ((runningHeight + (settings.display.padding * 2))))
    windower.prim.set_position('BackgroundLeft',
        (settings.display.pos.x) - (settings.display.padding * settings.display.scale),
        (settings.display.pos.y - settings.display.padding))

    windower.prim.set_color('Background', 255 * settings.display.alpha, 255, 255, 255)
    windower.prim.set_size('Background', (runningWidth), ((runningHeight + (settings.display.padding * 2))))
    windower.prim.set_position('Background', (settings.display.pos.x),
        (settings.display.pos.y - settings.display.padding))

    windower.prim.set_color('BackgroundRight', 255 * settings.display.alpha, 255, 255, 255)
    windower.prim.set_size('BackgroundRight', settings.display.padding * settings.display.scale,
        ((runningHeight + (settings.display.padding * 2))))
    windower.prim.set_position('BackgroundRight', ((settings.display.pos.x) + (runningWidth)),
        (settings.display.pos.y - settings.display.padding))
end

function update_and_show_aggro_sprites(table, xoffset, yoffset, singleLineOffset)
    local x_pos_shift = (xoffset * settings.display.scale) + singleLineOffset;
    for i, key in ipairs(properAggroKeyOrder) do
        local value = table[key]
        if value and tonumber(value) > 0 then
            windower.prim.set_color(key, 255, 255, 255, 255)
            windower.prim.set_position(key, (settings.display.pos.x + x_pos_shift), (settings.display.pos.y + yoffset))
            x_pos_shift = x_pos_shift + (25 * settings.display.scale)
        end
    end
    return x_pos_shift - (25 * settings.display.scale)
end

function hide_libra_texts()
    for i, value in ipairs(textObjectsList) do
        texts.visible(value, false)
    end
end

function hide_libra_sprites()
    for i, value in ipairs(spriteNamesList) do
        windower.prim.set_color(value, 0, 0, 0, 0)
    end
end

function getDegrees(value)
    return round(360 / math.tau * value)
end

local dir_sets = L {'W', 'WNW', 'NW', 'NNW', 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW',
                    'W'}
function DegreesToDirection(val)
    return dir_sets[round((val + math.pi) / math.pi * 8) + 1]
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
    local mobQuery = 'SELECT * FROM "mobs" WHERE name = "' .. target .. '" AND zone = "' .. zones .. '"'
    libra = {}
    if mobsdb:isopen() and mobQuery then
        libra.mob_name = 'No information for ' .. target .. ' in ' .. zones
        for id, name, family, zone, level, job, passive, link, nm, url, notes in mobsdb:urows(mobQuery) do
            local mobJob = job
            if name == target and zone == zones and family then
                -- get family info
                local familyQuery = 'SELECT * FROM "families" WHERE family = "' .. family .. '"'
                if familiesdb:isopen() and familyQuery then
                    for family, mobType, job, detectSight, detectSound, detectMagic, detectLowHP, detectJobAb,
                        detectTruSight, detectTruSound, physical, magical, breath, slashing, blunt, hand2hand, piercing,
                        ranged, fire, wind, lightning, light, ice, earth, water, dark, needsManualSubfamily in
                        familiesdb:urows(familyQuery) do
                        currentMobAllRes = format_damage_type_table(tonumber(physical), tonumber(magical),
                            tonumber(breath), tonumber(slashing), tonumber(blunt), tonumber(hand2hand),
                            tonumber(piercing), tonumber(ranged), tonumber(fire), tonumber(wind), tonumber(lightning),
                            tonumber(light), tonumber(ice), tonumber(earth), tonumber(water), tonumber(dark))
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
                        libra.aggro = format_aggro_type_table(passive, link, detectSight, detectSound, detectMagic,
                            detectLowHP, detectJobAb, detectTruSight, detectTruSound)

                    end
                end
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
            for i, v in ipairs(raceTable) do
                if (libra.target_race == (i - 1)) then
                    nameElement = nameElement .. ' (' .. v .. ')'
                end
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
    local guildNpcsQuery = 'SELECT * FROM "guild_npcs" WHERE name = "' .. name .. '"'
    if guildNpcsdb:isopen() and guildNpcsQuery then
        for name, craft, open, close, dayoff in guildNpcsdb:urows(guildNpcsQuery) do
            local openOrClosed = libra.currentTime and libra.currentTime >= tonumber(open) * 60 and libra.currentTime <=
                                     tonumber(close) * 60 and 'Open' or 'Closed'
            newName = name .. ' (Open ' .. open .. ':00 - ' .. close .. ':00, Currently: ' ..
                          (openOrClosed == "Closed" and '\\cs(255,0,0)' .. openOrClosed .. '\\cr' or '\\cs(0,255,0)' ..
                              openOrClosed .. '\\cr') .. ')'
            libra.target_race = 11
        end
    end
    return newName
end

function get_target(index)
    hide_libra_sprites()
    hide_libra_texts()
    clear_libra_variables()
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
    libra.target_name = target.name:gsub('"','')
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

function round(n)
    if n ~= nil then
        return  tonumber(n) >= 0.0 and tonumber(n) - tonumber(n) % -1 or tonumber(n) - tonumber(n) % 1
    else
        return 100
    end
end

function format_damage_type_table(physical, magical, breath, slashing, blunt, hand2hand, piercing, ranged, fire, wind,
    lightning, light, ice, earth, water, dark)
    local all = {
        ['Ph'] = round(physical) - 100,
        ['Ma'] = round(magical) - 100,
        ['Br'] = round(breath) - 100,
        ['Sl'] = round(slashing) - 100,
        ['Bl'] = round(blunt) - 100,
        ['H2H'] = round(hand2hand) - 100,
        ['Pi'] = round(piercing) - 100,
        ['Ra'] = round(ranged) - 100,
        ['Fi'] = round(fire) - 100,
        ['Wi'] = round(wind) - 100,
        ['Th'] = round(lightning) - 100,
        ['Li'] = round(light) - 100,
        ['Ea'] = round(earth) - 100,
        ['Wa'] = round(water) - 100,
        ['Ic'] = round(ice) - 100,
        ['Da'] = round(dark) - 100
    }
    return all
end

function format_aggro_type_table(passive, link, detectSight, detectSound, detectMagic, detectLowHP, detectJobAb,
    detectTruSight, detectTruSound)
    local aggro = {
        ['passive'] = passive == 'YES' and 1 or 0,
        ['links'] = link == 'YES' and 1 or 0,
        ['detectSight'] = detectSight,
        ['detectSound'] = detectSound,
        ['detectMagic'] = detectMagic,
        ['detectLowHP'] = detectLowHP,
        ['detectJobAb'] = detectJobAb,
        ['detectTruSight'] = detectTruSight,
        ['detectTruSound'] = detectTruSound
    }
    return aggro
end

function refresh()
    unload_sprites()
    load_sprites()
    load_texts()
    get_target(windower.ffxi.get_player().index)
end

windower.register_event('incoming chunk', function(id, org, modi, is_injected, is_blocked)
    if id == 0xB then
        zoning_bool = true
    elseif id == 0xA then
        zoning_bool = false
    end
end)

windower.register_event('prerender', function()
    local info = windower.ffxi.get_info()

    if not info.logged_in or not windower.ffxi.get_player() or zoning_bool then
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
    libra.currentTime = new
end)

windower.register_event('addon command', function(...)
    local args = T {...}
    if args[1] then
        if args[1]:lower() == 'help' or args[1]:lower() == 'config' then
            windower.add_to_chat(207, "Libra Commands:")
            windower.add_to_chat(207, "//libra scale <number 0.5 through 3>")
            windower.add_to_chat(207, "//libra pos <x_value> <y_value>")
            windower.add_to_chat(207, "//libra padding <number>")
            windower.add_to_chat(207, "//libra alpha <number 0 through 1>")
            windower.add_to_chat(207, "//libra multiline <yes or no>")
            windower.add_to_chat(207, "Current scale: " .. settings.display.scale)
            windower.add_to_chat(207, "Current position: x" .. settings.display.pos.x .. " y" .. settings.display.pos.y)
            windower.add_to_chat(207, "Current padding: " .. settings.display.padding)
            windower.add_to_chat(207, "Current alpha: " .. settings.display.alpha)
            windower.add_to_chat(207, "Multi-line mode: " .. tostring(settings.display.multiline))
        elseif args[1]:lower() == 'scale' then
            if not args[2] then
                windower.add_to_chat(207, "Libra: Second argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) then
                local newScale = tonumber(args[2])
                if newScale > 3 or newScale < 0.5 then
                    windower.add_to_chat(207, "Libra: Scale must be a number between 0.5 and 3, decimals are allowed")
                else
                    settings.display.scale = newScale
                    config.save(settings)
                    refresh()
                    windower.add_to_chat(207, "Libra: Scale now set to " .. newScale)
                end
            else
                windower.add_to_chat(207, "Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'pos' then
            if not args[2] then
                windower.add_to_chat(207, "Libra: Second argument not specified, use '//libra help' for info.")
            elseif not args[3] then
                windower.add_to_chat(207, "Libra: Third argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) and tonumber(args[3]) then
                local newX = tonumber(args[2])
                local newY = tonumber(args[3])
                settings.display.pos.x = newX
                settings.display.pos.y = newY
                config.save(settings)
                refresh()
                windower.add_to_chat(207, "Libra: Position now set to x" .. newX .. " y" .. newY)
            else
                windower.add_to_chat(207, "Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'padding' then
            if not args[2] then
                windower.add_to_chat(207, "Libra: Second argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) then
                local newPadding = tonumber(args[2])
                settings.display.padding = newPadding
                config.save(settings)
                refresh()
                windower.add_to_chat(207, "Libra: Padding now set to " .. newPadding)
            else
                windower.add_to_chat(207, "Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'alpha' then
            if not args[2] then
                windower.add_to_chat(207, "Libra: Second argument not specified, use '//libra help' for info.")
            elseif tonumber(args[2]) then
                local newAlpha = tonumber(args[2])
                if newAlpha > 1 or newAlpha < 0 then
                    windower.add_to_chat(207, "Libra: Alpha must be a number between 0 and 1")
                else
                    settings.display.alpha = newAlpha
                    config.save(settings)
                    refresh()
                    windower.add_to_chat(207, "Libra: Alpha now set to " .. newAlpha)
                end
            else
                windower.add_to_chat(207, "Libra: Second argument wrong, use '//libra help' for info.")
            end
        elseif args[1]:lower() == 'multiline' then
            if not args[2] then
                windower.add_to_chat(207, "Libra: Second argument not specified, use '//libra help' for info.")
            elseif string.lower(args[2]) == 'yes' or string.lower(args[2]) == 'no' then
                local newMultiline = false
                if string.lower(args[2]) == 'yes' then
                    newMultiline = true
                end
                settings.display.multiline = newMultiline
                config.save(settings)
                refresh()
                windower.add_to_chat(207, "Libra: Multi-line mode is now set to " .. tostring(newMultiline))
            else
                windower.add_to_chat(207, "Libra: Second argument wrong, use '//libra help' for info.")
            end
        else
            windower.add_to_chat(207, "Libra: First argument wrong, use '//libra help' for info.")
        end
    else
        windower.add_to_chat(207, "Libra: First argument not specified, use '//libra help' for info.")
    end
end)
