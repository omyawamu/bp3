local debuffs   = {}
local player    = windower.ffxi.get_player()
local files     = require('files')
local texts     = require('texts')
local res       = require('resources')
local f = files.new(string.format('bp/helpers/settings/debuffs/%s_settings.lua', player.name))

if not f:exists() then
  f:write(string.format('return %s', T({}):tovstring()))
end

function debuffs.new()
    local self = {}

    -- Static Variables.
    self.settings = dofile(string.format('%sbp/helpers/settings/debuffs/%s_settings.lua', windower.addon_path, player.name))
    self.layout   = self.settings.layout or {pos={x=300, y=400}, colors={text={alpha=255, r=100, g=215, b=0}, bg={alpha=0, r=0, g=0, b=0}, stroke={alpha=255, r=0, g=25, b=15}}, font={name='Mulish', size=8}, padding=2, stroke_width=2, draggable=false}
    self.update   = self.settings.update or {delay=2, last=0}
    self.display  = texts.new('', {flags={draggable=self.layout.draggable}})

    -- Public Variables.
    self.debuffs  = self.settings.debuffs or {}
    self.active   = {}

    -- Private Functions
    local persist = function()
        local next = next

        if self.settings then
            self.settings.debuffs = self.debuffs
            self.settings.update  = self.update
            self.settings.layout  = self.layout

        end

    end
    persist()

    local resetDisplay = function()
        self.display:pos(self.layout.pos.x, self.layout.pos.y)
        self.display:font(self.layout.font.name)
        self.display:color(self.layout.colors.text.r, self.layout.colors.text.g, self.layout.colors.text.b)
        self.display:alpha(self.layout.colors.text.alpha)
        self.display:size(self.layout.font.size)
        self.display:pad(self.layout.padding)
        self.display:bg_color(self.layout.colors.bg.r, self.layout.colors.bg.g, self.layout.colors.bg.b)
        self.display:bg_alpha(self.layout.colors.bg.alpha)
        self.display:stroke_width(self.layout.stroke_width)
        self.display:stroke_color(self.layout.colors.stroke.r, self.layout.colors.stroke.g, self.layout.colors.stroke.b)
        self.display:stroke_alpha(self.layout.colors.stroke.alpha)
        self.display:hide()
        self.display:update()

    end
    resetDisplay()

    -- Static Functions.
    self.writeSettings = function()
        persist()

        if f:exists() then
            f:write(string.format('return %s', T(self.settings):tovstring()))

        elseif not f:exists() then
            f:write(string.format('return %s', T({}):tovstring()))

        end

    end
    self.writeSettings()

    self.clear = function()
        local player = windower.ffxi.get_player()

        if self.debuffs[player.main_job_id] then
            helpers['popchat'].pop(string.format('Clearing all debuffs from %s!', res.jobs[player.main_job_id].en))
            self.debuffs[player.main_job_id] = {}
            self.writeSettings()

        end

    end

    self.reset = function()
        local player = windower.ffxi.get_player() or false

        if player then

            for i in pairs(self.debuffs[player.main_job_id]) do
                self.debuffs[player.main_job_id][i].last = 0
            end

        end

    end

    -- Public Functions.
    self.add = function(bp, spell, delay)
        local bp      = bp or false
        local spell   = spell or false
        local delay   = delay or 180

        if bp and spell and type(spell) == 'table' and tonumber(delay) ~= nil then
            local player  = windower.ffxi.get_player()
            local helpers = bp.helpers

            if player and helpers then

                if spell and self.debuffs[player.main_job_id] and not self.exists(bp, spell) then
                    table.insert(self.debuffs[player.main_job_id], {id=spell.id, name=spell.en, delay=delay, last=os.clock()})
                    helpers['popchat'].pop(string.format('Adding %s to debuffs list.', spell.en))

                elseif spell and not self.exists(bp, spell) then
                    self.debuffs[player.main_job_id] = {}
                    table.insert(self.debuffs[player.main_job_id], {id=spell.id, name=spell.en, delay=delay, last=os.clock()})
                    helpers['popchat'].pop(string.format('Adding %s to debuffs list.', spell.en))

                end

            end

        elseif bp and spell and (type(spell) == 'number' or type(spell) == 'string') and tonumber(spell) ~= nil and tonumber(delay) ~= nil then
            local player  = windower.ffxi.get_player()
            local helpers = bp.helpers

            if player and helpers then
                local spell = res.spells[tonumber(spell)]

                if spell and self.debuffs[player.main_job_id] and not self.exists(bp, spell) then
                    table.insert(self.debuffs[player.main_job_id], {id=spell.id, name=spell.en, delay=delay, last=os.clock()})
                    helpers['popchat'].pop(string.format('Adding %s to debuffs list.', spell.en))

                elseif spell and not self.exists(bp, spell) then
                    self.debuffs[player.main_job_id] = {}
                    table.insert(self.debuffs[player.main_job_id], {id=spell.id, name=spell.en, delay=delay, last=os.clock()})
                    helpers['popchat'].pop(string.format('Adding %s to debuffs list.', spell.en))

                end

            end

        elseif bp and spell and type(spell) == 'string' then
            local player  = windower.ffxi.get_player()
            local helpers = bp.helpers

            if player and helpers then
                local spell = bp.MA[spell]

                if spell and self.debuffs[player.main_job_id] and not self.exists(bp, spell) then
                    table.insert(self.debuffs[player.main_job_id], {id=spell.id, name=spell.en, delay=delay, last=os.clock()})
                    helpers['popchat'].pop(string.format('Adding %s to debuffs list.', spell.en))

                elseif spell and not self.exists(bp, spell) then
                    self.debuffs[player.main_job_id] = {}
                    table.insert(self.debuffs[player.main_job_id], {id=spell.id, name=spell.en, delay=delay, last=os.clock()})
                    helpers['popchat'].pop(string.format('Adding %s to debuffs list.', spell.en))

                end

            end

        end
        self.writeSettings()

    end

    self.remove = function(bp, spell)
        local bp    = bp or false
        local spell = spell or false
        local next  = next

        if bp and spell and type(spell) == 'table' then
            local player  = windower.ffxi.get_player()
            local helpers = bp.helpers

            if player and helpers then

                for i,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.id == spell.id and self.exists(bp, spell) then
                        local removed = table.remove(self.debuffs[player.main_job_id], i)

                        if removed then
                            helpers['popchat'].pop(string.format('Removing %s to debuffs list.', res.spells[spell.id].en))
                            self.writeSettings()
                            return removed

                        end

                    end

                end

            end

        elseif bp and spell and (type(spell) == 'number' or type(spell) == 'string') and tonumber(spell) ~= nil then
            local player  = windower.ffxi.get_player()
            local helpers = bp.helpers

            if player and helpers and res.spells[spell] then
                local spell = res.spells[spell]

                for i,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.id == spell.id and self.exists(bp, spell) then
                        local removed = table.remove(self.debuffs[player.main_job_id], i)

                        if removed then
                            helpers['popchat'].pop(string.format('Removing %s to debuffs list.', res.spells[spell.id].en))
                            self.writeSettings()
                            return removed

                        end

                    end

                end

            end

        elseif bp and spell and type(spell) == 'string' then
            local player  = windower.ffxi.get_player()
            local helpers = bp.helpers

            if player and helpers and bp.MA[spell] then
                local spell = bp.MA[spell]

                for i,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.id == spell.id and self.exists(bp, spell) then
                        local removed = table.remove(self.debuffs[player.main_job_id], i)

                        if removed then
                            helpers['popchat'].pop(string.format('Removing %s to debuffs list.', res.spells[spell.id].en))
                            self.writeSettings()
                            return removed

                        end

                    end

                end

            end

        end

    end

    self.render = function(bp)
        local bp = bp or false

        if bp and bp.helpers['target'].getTarget() and os.clock()-self.update.last > self.update.delay then
            local player    = windower.ffxi.get_player()
            local helpers   = bp.helpers
            local next      = next
            local math      = math

            if next(self.debuffs) ~= nil then
                local update = {}

                for _,v in pairs(self.debuffs[player.main_job_id]) do
                    local spell     = v
                    local timer     = (spell.delay-(os.clock()-spell.last))
                    local color     = string.format('%s,%s,%s', math.abs(self.layout.colors.text.r/0.2), math.abs(self.layout.colors.text.g/0.2), math.abs(self.layout.colors.text.b/0.2))

                    if timer < 0 then
                        timer = 0
                    end

                    if color and timer and spell then
                        table.insert(update, string.format(' \\cs(%s)[%.1f]\\cr: %s', color, timer, spell.name))
                    end

                end

                if update and next(update) ~= nil then
                    self.display:text(table.concat(update, '\n'))
                    self.display:update()

                    if not self.display:visible() then
                        self.display:show()
                    end

                end

            end
            self.update.last = os.clock()

        elseif not bp.helpers['target'].getTarget() and os.clock()-self.update.last > self.update.delay then
            local next = next

            if self.display:visible() then
                self.display:hide()

            end
            self.update.last = os.clock()

        end

    end

    self.exists = function(bp, spell)
        local bp    = bp or false
        local spell = spell or false

        if bp and spell and type(spell) == 'table' then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.id == spell.id then
                        return true
                    end

                end

            end

        elseif bp and spell and (type(spell) == 'string' or type(spell) == 'number') and tonumber(spell) ~= nil then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.id and v.id == spell then
                        return true
                    end

                end

            end

        elseif bp and spell and type(spell) == 'string' and tonumber(spell) == nil then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.name and v.name == spell then
                        return true
                    end

                end

            end

        end
        return false

    end

    self.ready = function(bp, spell)
        local bp    = bp or false
        local spell = spell or false

        if bp and spell and type(spell) == 'table' then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.id and spell.id and v.id == spell.id and (v.delay-(os.clock()-v.last)) <= 0 then
                        return true
                    end

                end

            end

        elseif bp and spell and (type(spell) == 'string' or type(spell) == 'number') and tonumber(spell) ~= nil then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.id and v.id == spell and res.spells[tonumber(spell)] then
                        local spell = res.spells[tonumber(spell)]

                        if (v.delay-(os.clock()-v.last)) <= 0 then
                            return true
                        end

                    end

                end

            end

        elseif bp and spell and type(spell) == 'string' and tonumber(spell) == nil then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.name and v.name == spell and bp.MA[spell] then
                        local spell = bp.MA[spell]

                        if (v.delay-(os.clock()-v.last)) <= 0 then
                            return true
                        end

                    end

                end

            end

        end
        return false

    end

    self.getDelay = function(bp, spell)
        local bp    = bp or false
        local spell = spell or false

        if bp and spell and type(spell) == 'table' then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.id and spell.id and v.id == spell.id then
                        return v.delay
                    end

                end

            end

        elseif bp and spell and (type(spell) == 'string' or type(spell) == 'number') and tonumber(spell) ~= nil then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.id and v.id == spell then
                        return v.delay
                    end

                end

            end

        elseif bp and spell and type(spell) == 'string' and tonumber(spell) == nil then
            local player = windower.ffxi.get_player()

            if self.debuffs[player.main_job_id] then

                for _,v in pairs(self.debuffs[player.main_job_id]) do

                    if v.delay and v.name and v.name == spell then
                        return v.delay
                    end

                end

            end

        end
        return false

    end

    self.hide = function()

        if self.display and self.display:visible() then
            self.display:hide()
        end

    end

    self.show = function()

        if self.display[i] and not self.display:visible() then
            self.display:show()
        end

    end

    self.pos = function(bp, x, y)
        local bp    = bp or false
        local x     = tonumber(x) or self.layout.pos.x
        local y     = tonumber(y) or self.layout.pos.y

        if bp and x and y then
            self.display:pos(x, y)
            self.layout.pos.x = x
            self.layout.pos.y = y
            self.writeSettings()
        
        elseif bp and (not x or not y) then
            bp.helpers['popchat'].pop('PLEASE ENTER AN "X" OR "Y" COORDINATE!')

        end

    end

    return self

end
return debuffs.new()
