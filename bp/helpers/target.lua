local target = {}
local files = require('files')
local texts = require('texts')
local res   = require('resources')
local f     = files.new('bp/helpers/settings/target_settings.lua')

if not f:exists() then
    f:write(string.format('return %s', T({}):tovstring()))
end

function target.new()
    local self = {}

    -- Static Variables.
    self.settings   = dofile(string.format('%sbp/helpers/settings/target_settings.lua', windower.addon_path))
    self.layout     = self.settings.layout or {pos={x=495, y=865}, colors={text={alpha=255, r=245, g=200, b=20}, bg={alpha=200, r=0, g=0, b=0}, stroke={alpha=255, r=0, g=0, b=0}}, font={name='Lucida Console', size=9}, padding=4, stroke_width=1, draggable=false}
    self.display    = texts.new('', {flags={draggable=self.layout.draggable}})
    self.important  = string.format('%s,%s,%s', 25, 165, 200)

    -- Public Variables.
    self.targets    = {player=false, party=false, luopan=false, entrust=false}
    self.mode       = self.settings.mode or 1

    -- Private Variables.
    local debug     = false

    -- Private Functions.
    local persist = function()
        local next = next

        if self.settings then
            self.settings.mode      = self.mode
            self.settings.layout    = self.layout
            self.settings.important = self.important

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

    self.getTarget = function()
        return self.targets.player or self.targets.party or false
    end

    self.clear = function()
        self.targets.player     = false
        self.targets.party      = false
        self.targets.entrust    = false
        self.targets.luopan     = false

    end

    -- Public Functions.
    self.setTarget = function(bp, target)
        local bp        = bp or false
        local target    = target or false

        if bp then
            local helpers = bp.helpers

            if target then

                if type(target) == 'table' and self.isEnemy(bp, target) then
                    target = windower.ffxi.get_mob_by_id(target.id) or false

                elseif type(target) == 'number' and self.isEnemy(bp, target) then
                    target = windower.ffxi.get_mob_by_id(target) or false

                elseif windower.ffxi.get_mob_by_target('t') and self.isEnemy(bp, windower.ffxi.get_mob_by_target('t')) then
                    target = windower.ffxi.get_mob_by_target('t')

                else
                    target = false

                end

            end

            if self.mode == 1 and target and self.canEngage(bp, target) then

                if target.distance:sqrt() < 35 then
                    self.targets.player = target
                    helpers['popchat'].pop(string.format('SETTING CURRENT PLAYER TARGET TO: %s.', target.name))
                end

            elseif self.mode == 2 and target and self.canEngage(target) then

                if target.distance:sqrt() < 35 then
                    self.targets.party = target
                    helpers['popchat'].pop(string.format('SETTING CURRENT PARTY TARGET TO: %s.', target.name))
                end

            end

        end

    end

    self.setLuopan = function(bp, target)
        local bp        = bp or false
        local target    = target or false

        if target then

            if type(target) == 'number' then
                target = windower.ffxi.get_mob_by_id(target) or false

            elseif type(target) == 'table' then
                target = windower.ffxi.get_mob_by_id(target.id) or false

            elseif type(target) == 'string' and windower.ffxi.get_mob_by_name(target) then
                target = windower.ffxi.get_mob_by_name(target) or false

            elseif windower.ffxi.get_mob_by_target('t') then
                target = windower.ffxi.get_mob_by_target('t')

            else
                target = false

            end

        end

        if target then

            if (target.distance):sqrt() < 22 then
                self.targets.luopan = target
            end

        end

    end

    self.setEntrust = function(bp, target)
        local bp        = bp or false
        local target    = target or false
        local player    = windower.ffxi.get_player()

        if target and target ~= '' then

            if type(target) == 'number' then
                target = windower.ffxi.get_mob_by_id(target) or false

            elseif type(target) == 'table' then
                target = windower.ffxi.get_mob_by_id(target.id) or false

            elseif type(target) == 'string' and windower.ffxi.get_mob_by_name(target) and not self.isEnemy(bp, windower.ffxi.get_mob_by_name(target)) then
                target = windower.ffxi.get_mob_by_name(target) or false

            elseif windower.ffxi.get_mob_by_target('t') then
                target = windower.ffxi.get_mob_by_target('t')

            else
                target = false

            end

        end

        if target and target.id == player.id then
            self.targets.entrust = false

        else

            if (target.distance):sqrt() < 22 and target.name ~= player.name and helpers['party'].isInParty(bp, target, false) then
                self.targets.entrust = target
            end

        end

    end

    self.canEngage = function(bp, mob)
        local bp    = bp or false
        local mob   = mob or false

        if bp and mob and mob.spawn_type == 16 and not mob.charmed and (mob.status ~= 2 or mob.status ~= 3) then
            local player    = windower.ffxi.get_player() or false
            local party     = windower.ffxi.get_party()
            local helpers   = bp.helpers

            if player and party then

                if (mob.claim_id == 0 or helpers['party'].isInParty(bp, mob.claim_id, true) or helpers['buffs'].buffActive(603) or helpers['buffs'].buffActive(511) or helpers['buffs'].buffActive(257) or helpers['buffs'].buffActive(267)) then
                    return true
                end

            end

        end
        return false

    end

    self.isEnemy = function(bp, target)
        local bp        = bp or false
        local target    = target or false

        if bp and target then
            local helpers = bp.helpers

            if type(target) == 'table' and target.spawn_type == 16 then
                return true

            elseif type(target) == 'number' and tonumber(target) ~= nil then
                local target = windower.ffxi.get_mob_by_id(target)

                if type(target) == 'table' and target.spawn_type == 16 then
                    return true
                end

            elseif type(target) == 'string' then
                local target = windower.ffxi.get_mob_by_target(target) or windower.ffxi.get_mob_by_name(target) or false

                if type(target) == 'table' and target.spawn_type == 16 then
                    return true
                end

            end

        end
        return false

    end

    self.castable = function(bp, target, spell)
        local bp        = bp or false
        local target    = target or false
        local targets   = spell.targets

        if bp and target then
            local helpers = bp.helpers

            for i,v in pairs(targets) do

                if i == 'Self' and target.name == windower.ffxi.get_player().name then
                    return v

                elseif i == 'Party' and helpers['party'].isInParty(bp, target, false) then
                    return v

                elseif i == 'Ally' and helpers['party'].isInParty(bp, target, true) then
                    return v

                elseif i == 'Player' and not target.is_npc then
                    return v

                elseif i == 'NPC' and target.is_npc then
                    return v

                elseif i == 'Enemy' and target.spawn_type == 16 then
                    return v

                end

            end

        end
        return false

    end

    self.onlySelf = function(bp, spell)
        local bp    = bp or false
        local spell = spell or false

        if spell then
            local targets = T(spell.targets)

            if #targets == 1 and targets[1] == 'Self' and spell.prefix ~= '/song' then
                return true
            end

        end
        return false

    end

    self.validTarget = function(bp, id, target)
        local bp        = bp or false
        local player    = windower.ffxi.get_player() or false
        local target    = target or false
        local id        = id or false
        
        if bp and player and id and target and res.spells[id] then
            local helpers   = bp.helpers
            local spell     = res.spells[id]

            if type(target) == 'table' then
                local target = windower.ffxi.get_mob_by_id(target) or false

                if target then

                    if (spell.targets):contains("Self") and player.name == target.name then
                        return target
                        
                    elseif (spell.targets):contains("Ally") and helpers['party'].isInParty(bp, target, true) then
                        return target
                        
                    elseif (spell.targets):contains("Party") and helpers['party'].isInParty(bp, target, false) then
                        return target
                            
                    elseif (spell.targets):contains("Self") and (spell.targets):contains("Party") and (spell.targets):contains("NPC") and (spell.targets):contains("Player") and (spell.targets):contains("Ally") and (spell.targets):contains("Enemy") then
                        return target
                            
                    end

                end

            elseif (type(target) == 'number' or tonumber(target) ~= nil) then
                local target = windower.ffxi.get_mob_by_id(target) or false

                if target then

                    if (spell.targets):contains("Self") and player.name == target.name then
                        return target
                        
                    elseif (spell.targets):contains("Ally") and helpers['party'].isInParty(bp, target, true) then
                        return target
                        
                    elseif (spell.targets):contains("Party") and helpers['party'].isInParty(bp, target, false) then
                        return target
                            
                    elseif (spell.targets):contains("Self") and (spell.targets):contains("Party") and (spell.targets):contains("NPC") and (spell.targets):contains("Player") and (spell.targets):contains("Ally") and (spell.targets):contains("Enemy") then
                        return target
                            
                    end

                end

            elseif type(target) == 'string' then
                local target = windower.ffxi.get_mob_by_name(target) or false

                if target then

                    if (spell.targets):contains("Self") and player.name == target.name then
                        return target
                        
                    elseif (spell.targets):contains("Ally") and helpers['party'].isInParty(bp, target, true) then
                        return target
                        
                    elseif (spell.targets):contains("Party") and helpers['party'].isInParty(bp, target, false) then
                        return target
                            
                    elseif (spell.targets):contains("Self") and (spell.targets):contains("Party") and (spell.targets):contains("NPC") and (spell.targets):contains("Player") and (spell.targets):contains("Ally") and (spell.targets):contains("Enemy") then
                        return target
                            
                    end

                end

            end
            
        elseif bp and player and id and target and res.job_abilities[id] then
            local spell = res.job_abilities[id]
            
            if type(target) == 'table' then
                local target = windower.ffxi.get_mob_by_id(target) or false

                if target then

                    if (spell.targets):contains("Self") and player.name == target.name then
                        return target
                        
                    elseif (spell.targets):contains("Ally") and helpers['party'].isInParty(bp, target, true) then
                        return target
                        
                    elseif (spell.targets):contains("Party") and helpers['party'].isInParty(bp, target, false) then
                        return target
                            
                    elseif (spell.targets):contains("Self") and (spell.targets):contains("Party") and (spell.targets):contains("NPC") and (spell.targets):contains("Player") and (spell.targets):contains("Ally") and (spell.targets):contains("Enemy") then
                        return target
                            
                    end

                end

            elseif (type(target) == 'number' or tonumber(target) ~= nil) then
                local target = windower.ffxi.get_mob_by_id(target) or false

                if target then

                    if (spell.targets):contains("Self") and player.name == target.name then
                        return target
                        
                    elseif (spell.targets):contains("Ally") and helpers['party'].isInParty(bp, target, true) then
                        return target
                        
                    elseif (spell.targets):contains("Party") and helpers['party'].isInParty(bp, target, false) then
                        return target
                            
                    elseif (spell.targets):contains("Self") and (spell.targets):contains("Party") and (spell.targets):contains("NPC") and (spell.targets):contains("Player") and (spell.targets):contains("Ally") and (spell.targets):contains("Enemy") then
                        return target
                            
                    end

                end

            elseif type(target) == 'string' then
                local target = windower.ffxi.get_mob_by_name(target) or false

                if target then

                    if (spell.targets):contains("Self") and player.name == target.name then
                        return target
                        
                    elseif (spell.targets):contains("Ally") and helpers['party'].isInParty(bp, target, true) then
                        return target
                        
                    elseif (spell.targets):contains("Party") and helpers['party'].isInParty(bp, target, false) then
                        return target
                            
                    elseif (spell.targets):contains("Self") and (spell.targets):contains("Party") and (spell.targets):contains("NPC") and (spell.targets):contains("Player") and (spell.targets):contains("Ally") and (spell.targets):contains("Enemy") then
                        return target
                            
                    end

                end

            end
            
        end
        return false
        
    end

    self.isDead = function(bp, target)
        local bp        = bp or false
        local target    = target or false

        if target and type(target) == 'table' and (target.status == 2 or target.status == 3) then
            return true
        end
        return false

    end

    self.allowed = function(bp, target)
        local bp        = bp or false
        local target    = target or false

        if bp and target and type(target) == 'table' then
            local helpers   = bp.helpers
            local target    = windower.ffxi.get_mob_by_id(target.id) or false

            if target and type(target) == 'table' and target.distance ~= nil then
                local distance = (target.distance:sqrt())

                if (distance == 0.089004568755627 or distance > 35) and distance ~= 0 then
                    if debug then print('Distance failure!') end
                    return false
                end

                if not target then
                    if debug then print('Target failure!') end
                    return false
                end

                if target.hpp == 0 then
                    if debug then print('HPP failure!') end
                    return false
                end

                if not target.valid_target then
                    if debug then print('Valid target failure!') end
                    return false
                end

                if not self.isEnemy(bp, target) and not helpers['party'].isInParty(bp, target) then
                    if debug then print('Is enemy failure!') end
                    return false
                end

                if target.charmed then
                    if debug then print('Charmed target failure!') end
                    return false
                end
                return true

            end

        end
        return false

    end

    self.updateTargets = function(bp)

        if self.targets.player and not self.allowed(bp, self.targets.player) then
            self.targets.player = false
        end

        if self.targets.party and not self.allowed(bp, self.targets.party) then
            self.targets.party = false
        end

        if self.targets.entrust and not self.allowed(bp, self.targets.entrust) then
            self.targets.entrust = false
        end

        if self.targets.luopan and not self.allowed(bp, self.targets.luopan) then
            self.targets.luopan = false
        end

    end

    self.render = function(bp)
        local bp        = bp or false
        local player    = windower.ffxi.get_player()
        local update    = {[1]='',[2]=''}

        -- Handle Player Target.
        if self.targets.player then
            update[1] = string.format('Player:  \\cs(%s)[ %s ]\\cr ', self.important, self.targets.player.name)

        elseif not self.targets.player then
            update[1] = ''

        end

        -- Handle Party Target.
        if self.targets.party then
            update[2] = string.format(' +  Party:  \\cs(%s)[ %s ]\\cr ', self.important, self.targets.party.name)

        elseif not self.targets.party then
            update[2] = ''

        end

        if (update[1] ~= '' or update[2] ~= '') then
            self.display:text(table.concat(update, ''))
            self.display:update()

            if not self.display:visible() then
                self.display:show()
            end
        
        else
            update[1] = string.format(' Targets:  \\cs(%s)[ %s ]\\cr ', self.important, ' None ')
            self.display:text(table.concat(update, ''))
            self.display:update()
            
            if not self.display:visible() then
                self.display:show()
            end

        end

    end

    self.changeMode = function()

        if self.mode == 1 then
            self.mode = 2
        else
            self.mode = 1
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
return target.new()