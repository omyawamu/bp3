local bootstrap = {}
local player    = windower.ffxi.get_player() or false

bootstrap.load = function()
    local self = {}

    -- Private Settings.
    local events    = {}
    local helpers   = {
        
        'accolades','actions','aftermath','alias','autoload','assist','attachments','bits','bpsocket','bubbles','buffer','buffs','burst','chests','ciphers','commands','coms','console','controls','cures','dax','debuffs','debug','distance','enmity','equipment',
        'inventory','items','keybinds','maintenance','maps','menus','merits','noknock','party','paths','popchat','queue','roboto','rolls','romans','runes','songs','sparks','speed','status','spaz','stratagems','stunner','target','trust','crafting','itemizer'
    
    }
    local directory = string.format('bp/settings/%s', player.name)

    self.party      = false
    self.player     = false
    self.me         = false
    self.info       = false
    self.target     = false
    self.debug      = false
    self.core       = false
    self.hideUI     = false
    self.settings   = {}
    self.helpers    = {}
    self.commands   = {}
    self.common     = {}
    self.events     = {}
    self.JA         = {}
    self.MA         = {}
    self.WS         = {}
    self.IT         = {}
    self.toggles    = {enmity={}, abilities={}, buffs={}, weaponskills={}}
    self.res        = require('resources')
    self.files      = require('files')
    self.packets    = require('packets')
    self.texts      = require('texts')
    self.sets       = require('sets')
    self.images     = require('images')
    self.queues     = require('queues')
    self.extdata    = require('extdata')
    self.json       = require('/bp/resources/JSON')
    self.lzw        = require('/bp/resources/lualzw')
                    require('actions')
                    require('strings')
                    require('lists')
                    require('tables')
                    require('chat')
                    require('logger')
                    require('pack')

    self.pinger     = os.clock()+15
    self.pos        = {x=windower.ffxi.get_mob_by_target('me').x, y=windower.ffxi.get_mob_by_target('me').y, x=windower.ffxi.get_mob_by_target('me').z}
    self.shutdown   = {[131]=131}
    self.blocked    = {
 
    [026]=026,[048]=048,[050]=050,[053]=053,[070]=070,
    [071]=071,[080]=080,[087]=087,[094]=094,[230]=230,
    [231]=231,[232]=232,[233]=233,[234]=234,[235]=235,
    [236]=236,[237]=237,[238]=238,[239]=239,[240]=240,
    [241]=241,[242]=242,[243]=243,[244]=244,[245]=245,
    [246]=246,[247]=247,[248]=248,[249]=249,[250]=250,
    [252]=252,[256]=256,[257]=257,[280]=280,[281]=281,
    [284]=284,[251]=251,

    }

    self.skillup    = {
        
        ['Divine']     = {list={'Banish','Flash','Banish II','Enlight','Repose'}, target='t'},
        ['Enhancing']  = {list={'Barfire','Barfira','Barblizzard','Barblizzara','Baraero','Baraera','Barstone','Barstonra','Barthunder','Barthundra','Barwater','Barwatera'}, target='me'},
        ['Enfeebling'] = {list={'Bind','Blind','Dia','Poison','Gravity','Slow','Silence'}, target='t'},
        ['Elemental']  = {list={'Stone'}, target='t'},
        ['Dark']       = {list={'Aspir','Aspir II','Bio','Bio II','Drain','Drain II'}, target='t'},
        ['Singing']    = {list={"Mage's Ballad","Mage's Ballad II","Mage's Ballad III"}, target='me'},
        ['Summoning']  = {list={'Carbuncle'}, target='me'},
        ['Blue']       = {list={'Cocoon','Pollen'}, target='me'},
        ['Geomancy']   = {list={'Indi-Refresh'}, target='me'},
        
        
    }

    self.writeSettings = function(dir, settings)
        local dir, settings = dir or false, settings or {}

        if dir and settings and type(settings) == 'table' then
            self.files.new(string.format('%s.lua', dir)):write(string.format('return %s', T(settings):tovstring()))
        end

    end

    self.save = function(file, helper, update)

        if file and helper and update then
            helper.persist(update)
        
            if file:exists() then
                file:write(string.format('return %s', T(helper.settings):tovstring()))
    
            elseif not f:exists() then
                file:write(string.format('return %s', T({}):tovstring()))
    
            end
    
        end
    
    end

    self.update = function(update)
        
        if update and type(update) == 'table' then

            for _,v in ipairs(update) do

                if v[1] and v[2] then
                    v[1] = v[2]
                end

            end

        end

    end

    self.buildCore = function(update)
        local player = windower.ffxi.get_player() or false

        if player then
            local dir = string.format('bp/core/%s/%score.lua', player.main_job:lower(), player.main_job:lower())
            local f   = self.files.new(dir)

            if f:exists() then

                if update and self.helpers ~= nil then
                    self.helpers['popchat'].pop(string.format('Core loaded for %s!', player.main_job_full))
                end
                self.core = dofile(string.format('%s%s', windower.addon_path, dir))

                if self.core.setSystem then
                    self.core.setSystem(self)
                end

            end

        end

    end
    self.buildCore(false)

    self.buildSkills = function()
        local JA = windower.ffxi.get_abilities().job_abilities
        local WS = windower.ffxi.get_abilities().weapon_skills
        local MA = windower.ffxi.get_spells()

        coroutine.schedule(function()
            local enmity = T{'Flash','Provoke','Stun',''}
            
            for _,v in ipairs(JA) do
                local skill = bp.res.job_abilities[v]
                
                if skill and self.helpers['actions'].isAvailable('JA', skill.en) then
                    self.toggles.abilities[skill.en] = {enabled=false, skill=skill}
                end

            end
            
            for _,v in ipairs(WS) do
                local skill = bp.res.weapon_skills[v]
                
                if skill and self.helpers['actions'].isAvailable('WS', skill.en) then
                    self.toggles.abilities[skill.en] = {enabled=false, skill=skill}
                end

            end
            
            for i,v in ipairs(MA) do
                local skill = bp.res.spells[i]
                
                if skill and self.helpers['actions'].isAvailable('MA', skill.en) and skill.targets['Self'] and skill.skill == 34 then
                    local blocked = T{'Sneak','Invisible','Deodorize'}

                    if not (skill.en):match('Protect') and not (skill.en):match('Shell') and not (skill.en):match('Bar') and not (skill.en):match('Teleport') and not blocked:contains(skill.en) then
                        self.toggles.abilities[skill.en] = {enabled=false, skill=skill}
                    end                    
                    
                end

            end

        end, 2)


    end

    local buildSettings = function()

        if player then
            local dir = string.format('bp/settings/%s.lua', player.name)
            local f   = self.files.new(dir)

            if f:exists() then
                return dofile(string.format('%s%s', windower.addon_path, dir))

            else
                local f = self.files.new('bp/settings/template/default_settings.lua')

                if f:exists() then
                    local settings = dofile(string.format('%sbp/settings/template/default_settings.lua', windower.addon_path))

                    if settings then
                        self.writeSettings(string.format('bp/settings/%s', player.name), settings)
                        return settings

                    end

                end

            end

        end

    end
    self.settings = buildSettings()

    local buildHelpers = function()
        local dir = {helpers=('bp/helpers/'), commands=('bp/commands/')}

        for _,name in ipairs(helpers) do
            
            if name then
                local f = {helper=self.files.new(string.format('%s%s.lua', dir.helpers, name)), command=self.files.new(string.format('%s%s.lua', dir.commands, name))}
                
                if f.helper:exists() then
                    self.helpers[name] = dofile(string.format('%s%s%s.lua', windower.addon_path, dir.helpers, name))

                    if self.helpers[name].setSystem then
                        self.helpers[name].setSystem(self)
                    end

                end

                if f.command:exists() then
                    self.commands[name] = dofile(string.format('%s%s%s.lua', windower.addon_path, dir.commands, name))
                    
                    if self.commands[name].setSystem then
                        self.commands[name].setSystem(self)
                    end

                end

            end

        end

    end
    buildHelpers()

    local buildResources = function()

        for _,v in pairs(self.res.job_abilities) do
            if v.en then
                self.JA[v.en] = v
            end
        end

        for _,v in pairs(self.res.spells) do
            if v.en then
                self.MA[v.en] = v
            end
        end

        for _,v in pairs(self.res.weapon_skills) do
            if v.en then
                self.WS[v.en] = v
            end
        end

        for _,v in pairs(self.res.items) do
            if v.en then
                self.IT[v.en] = v
            end
        end

    end
    buildResources()

    -- Private Events.
    events.commands = windower.register_event('addon command', function(...)
        local a = T{...}
        local c = a[1] or false
    
        if c then
            c = c:lower()
            
            if self.commands[c] then
                self.commands[c].capture(a)
    
            elseif c == 'mode' then
                self.helpers['maintenance'].toggle(self)

            elseif c == 'music' then
                windower.send_command(('setbgm %s'):format(math.random(1,255)))
    
            elseif c == 'follow' then
                local player = windower.ffxi.get_player()
    
                if player then
                    windower.send_command(string.format('ord r* follow %s', player.name))
                end
    
            elseif c == 'stop' then
                self.helpers['controls'].stop()
    
            elseif c == 'request_stop' then
                windower.send_command('ord r* bp stop')

            elseif c == 'info' then
                local target = windower.ffxi.get_mob_by_target('t') or false

                if target then
                    print(target.id, target.index, target.claim_id, target.x, target.y, target.z)
                end
    
            elseif c == 'trade' and a[2] then
                local target = windower.ffxi.get_mob_by_target('t') or false
                local items = {}
    
                if bp.player and target and target.id and target.id ~= player.id then
                    
                    for i=2, #a do
                        
                        if a[i] and (a[i]):match(':') then
                            local split = a[i]:split(':')
    
                            if self.helpers['inventory'].findItemByName(split[1]) and split[2] and tonumber(split[2]) ~= nil then
                                table.insert(items, {name=self.helpers['inventory'].findItemByName(split[1]).en, count=tonumber(split[2] or 1)})
                            end
    
                        end
    
                    end
                    
                    if items and items[1] then
                        self.helpers['actions'].tradeItem(target, #items, unpack(items))
                    end
    
                end
    
            elseif (c == 'r' or c == 'reload') then
                windower.send_command('lua r bp3')
    
            else
                self.core.handleCommands(a)
    
            end
    
        end
    
    end)

    ActionPacket.open_listener(self.helpers['noknock'].block)
    events.prerender = windower.register_event('prerender', function()
        self.party = windower.ffxi.get_party() or false
        self.player = windower.ffxi.get_player() or false
        self.info = windower.ffxi.get_info() or false
        self.me = windower.ffxi.get_mob_by_target('me') or false
        self.hideUI = (bp.info.mog_house or bp.info.chat_open) or (bp.info.menu_open and self.player.status ~= 1 and not windower.ffxi.get_mob_by_target('t')) and true or false

        if self.player then
            local player = self.player
            local zone = self.info.zone

            self.helpers['stratagems'].render(self)
            self.helpers['distance'].render(self)
            self.helpers['popchat'].render(self)
            self.helpers['debuffs'].render(self)
            self.helpers['runes'].render(self)

            if self.settings['Enabled'] and not self.blocked[zone] and not self.shutdown[zone] and (os.clock() - self.pinger) > self.settings['Ping Delay'] then
                
                if not self.helpers['buffs'].buffActive(69) and not self.helpers['buffs'].buffActive(71) then
                    self.helpers['controls'].checkFacing(self)
                    self.helpers['controls'].checkDistance(self)
                    self.helpers['controls'].checkAssisting(self)
                    self.helpers['items'].queueItems(self)
                    self.core.handleAutomation(self)

                end            
                self.pinger = os.clock()

            elseif self.settings['Enabled'] and self.blocked[zone] and not self.shutdown[zone] and (os.clock() - self.pinger) > self.settings['Ping Delay'] then

                if not self.helpers['buffs'].buffActive(69) and not self.helpers['buffs'].buffActive(71) then
                    self.helpers['items'].queueItems(self)
                    self.helpers['queue'].handle(self)

                end            
                self.pinger = os.clock()

            end
            
        end

    end)

    events.actions = windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
        
        if bp and id == 0x028 then
            local pack      = self.packets.parse('incoming', original)
            local player    = bp.player
            local actor     = windower.ffxi.get_mob_by_id(pack['Actor'])
            local target    = windower.ffxi.get_mob_by_id(pack['Target 1 ID'])
            local count     = pack['Target Count']
            local category  = pack['Category']
            local param     = pack['Param']
            
            if player and actor and target then
                
                -- Melee Attacks.
                if pack['Category'] == 1 then

                    if actor.id == bp.player.id then

                    end
    
                -- Finish Ranged Attack.
                elseif pack['Category'] == 2 then
    
                    if actor.name == player.name then
                        self.helpers['queue'].ready = (os.clock() + self.helpers['actions'].getDelays(bp)['Ranged'])
                        
                        -- Remove from action from queue.
                        self.helpers['queue'].remove(self.helpers['actions'].unique.ranged, actor)
    
                    end
    
                -- Finish Weaponskill.
                elseif pack['Category'] == 3 then
    
                    if actor.name == player.name then
                        self.helpers['queue'].ready = (os.clock() + self.helpers['actions'].getDelays(bp)['WeaponSkill'])
                        
                        -- Remove from action from queue.
                        self.helpers['queue'].remove(self.res.weapon_skills[param], actor)
    
                    end
    
                -- Finish Spell Casting.
                elseif pack['Category'] == 4 then
    
                    if actor.name == player.name then
                        local spell = self.res.spells[param] or false
    
                        if spell and type(spell) == 'table' and spell.type then
                            local debuffs = self.helpers['debuffs'].debuffs
    
                            self.helpers['queue'].ready = (os.clock() + self.helpers['actions'].getDelays(bp)[spell.type] or 1)
                            self.helpers['queue'].remove(spell, actor)
    
                            -- Check for Utsusemi, and protect from over casting.
                            if (player.main_job == 'NIN' or player.sub_job == 'NIN') and (spell.en):match('Utsusemi') then
                                self.core['UTSU BLOCK'].last = os.clock()
                            end
    
                            -- Handle updating debuffs delay.
                            if debuffs and debuffs[player.main_job_id] then
                                
                                for i,v in ipairs(debuffs[player.main_job_id]) do
    
                                    if v.id == spell.id then
                                        debuffs[player.main_job_id][i].last = os.clock()
                                        break
                                    
                                    end
    
                                end
                            end
                        
                        else
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        end
    
                    end
    
                -- Finish using an Item.
                elseif pack['Category'] == 5 then
    
                    if actor.name == player.name then
                        self.helpers['queue'].ready = (os.clock() + self.helpers['actions'].getDelays(bp)['Item'] or 1)
    
                        -- Remove from action from queue.
                        self.helpers['queue'].remove(self.res.items[param], actor)
    
                    end
    
                -- Use Job Ability.
                elseif pack['Category'] == 6 then
                    local rolls = self.res.job_abilities:type('CorsairRoll')
                    local runes = self.res.job_abilities:type('Rune')
    
                    if actor.name == player.name then
                        local action = self.helpers['actions'].buildAction(category, param)
                        local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                        if action then
                            --self.helpers['actions'].midaction = false
                            self.helpers['queue'].ready = (os.clock() + delay)
    
                            -- Remove from action from queue.
                            self.helpers['queue'].remove(self.res.job_abilities[param], actor)
                            
                            -- Handle Rolls.
                            if action.type == 'CorsairRoll' and rolls[param] then
                                self.helpers['rolls'].add(rolls[param], pack['Target 1 Action 1 Param'])
                            end
    
                        else
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        end
    
                    elseif actor.name ~= player.name and actor.spawn_type == 16 and self.res.monster_abilities[param] then
    
                        if self.helpers['stunner'].stunnable(param) then
                            self.helpers['stunner'].stun(param, actor)
                        end
    
                    end
    
                -- Use Weaponskill.
                elseif pack['Category'] == 7 then
    
                    if actor.name == player.name then
                        local param  = pack['Target 1 Action 1 Param']
                        local action = self.helpers['actions'].buildAction(category, param)
                        local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                        if param == 24931 then
                            self.helpers['queue'].ready = (os.clock() + delay)
    
                        elseif param == 28787 then
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        else
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        end
    
    
                    end
    
                -- Begin Spell Casting.
                elseif pack['Category'] == 8 then
    
                    if actor.name == player.name then
    
                        if param == 24931 then
                            local param  = pack['Target 1 Action 1 Param']
                            local action = self.helpers['actions'].buildAction(category, param)
                            local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                            do  -- Update ready status.
                                self.helpers['queue'].ready = (os.clock() + delay)
                            end
    
                        elseif param == 28787 then
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        else
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        end
    
                    end
    
                -- Begin Item Usage.
                elseif pack['Category'] == 9 then
    
                    -- Make sure that I am using an item.
                    if actor.name == player.name then
    
                        if param == 24931 then
                            local param  = pack['Target 1 Action 1 Param']
                            local action = self.helpers['actions'].buildAction(category, param)
                            local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                            do  -- Update ready status.
                                self.helpers['queue'].ready = (os.clock() + delay)
                            end
    
                        elseif param == 28787 then
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        else
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        end
    
                    end
    
                -- NPC TP Move.
                elseif pack['Category'] == 11 then
    
                -- Begin Ranged Attack.
                elseif pack['Category'] == 12 then
    
                    if actor.name == player.name then
                        
                        if param == 24931 then
                            local param  = pack['Target 1 Action 1 Param']
                            local action = self.helpers['actions'].buildAction(category, param)
                            local delay  = self.helpers['actions'].getActionDelay(action) or 1
                            
                            do  -- Update ready status.
                                self.helpers['queue'].ready = (os.clock() + delay)
                            end
    
                        elseif param == 28787 then
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        else
                            self.helpers['queue'].ready = (os.clock() + 1)
    
                        end
    
                    end
    
                -- Finish Pet Ability / Weaponskill.
                elseif pack['Category'] == 13 then
    
                    -- Make sure that I am using the ability.
                    if actor.name == player.name then
                        local action = self.helpers['actions'].buildAction(category, param)
                        local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                        if action then
                            self.helpers['queue'].ready = (os.clock() + delay)
    
                            -- Remove from action from queue.
                            self.helpers['queue'].remove(res.job_abilities[param], actor)
    
                        end
    
                    end
    
                -- DNC Abilities
                elseif pack['Category'] == 14 then
    
                    if actor.name == player.name then
                        local action = self.helpers['actions'].buildAction(category, param)
                        local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                        if action then
                            self.helpers['queue'].ready = os.clock() + delay
    
                            -- Remove from action from queue.
                            self.helpers['queue'].remove(self.res.job_abilities[param], actor)
    
                        end
    
                    end
    
                -- RUN Abilities
                elseif pack['Category'] == 15 then
    
                    if actor.name == player.name then
                        local action = self.helpers['actions'].buildAction(category, param)
                        local delay  = self.helpers['actions'].getActionDelay(action) or 1
    
                        if action then
                            self.helpers['queue'].ready = os.clock() + delay
    
                            -- Remove from action from queue.
                            self.helpers['queue'].remove(self.res.job_abilities[param], actor)
    
                        end
    
                    end
                
                else
                    self.helpers['queue'].ready = (os.clock() + 1)
    
                end
                self.helpers['burst'].registerSkillchain(original)
    
            end
    
        end
        
    end)

    events.incoming = windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    
        if id == 0x0dd then
            self.helpers['party'].updateJobs(original)
    
        elseif id == 0x034 then
            local menu_hacks = self.helpers['menus'].enabled
    
            if menu_hacks and not injected then
                return self.helpers['menus'].capture(original)
    
            elseif not menu_hacks then
    
                if self.helpers['sparks'].busy then
                    self.helpers['sparks'].purchase(original)
    
                elseif self.helpers['accolades'].busy then
                    self.helpers['accolades'].purchase(original)
    
                elseif self.helpers['ciphers'].busy then
                    return self.helpers['ciphers'].build(original)
    
                elseif self.helpers['chests'].busy then
                    return self.helpers['chests'].handleChest(original)
    
                elseif self.helpers['maps'].busy then
                    self.helpers['maps'].buyMaps(original)
    
                end
    
            end
    
        elseif id == 0x05c then
    
            if self.helpers['menus'].enabled and not injected then
                local unpacked  = { original:sub(5,36):unpack("C32") }
                local packed    = {}
                
                for i,v in ipairs(unpacked) do
    
                    if i > 7 then
                        packed[i] = ('C'):pack(unpacked[i])
                    else
                        packed[i] = ('C'):pack(255)
                    end
    
                end
                windower.packets.inject_incoming(0x05c, original:sub(1,4)..table.concat(packed, ''))
                return true
    
            end
    
        elseif id == 0x03C then
            local money = false
    
            if self.files.new('bp/helpers/moneyteam/moneyteam.lua'):exists() then
                money = dofile(string.format('%sbp/helpers/moneyteam/moneyteam.lua', windower.addon_path))
            end
    
        elseif id == 0x058 then
    
        elseif id == 0x037 then
            local packed = self.packets.parse('incoming', original)
    
            if packed then
                local player = windower.ffxi.get_player()
    
                -- Update saved packet data for injection.
                if player and player.id == packed['Player'] and packed['Status'] ~= 31 then
                    self.helpers['maintenance'].updateData(original)
                end
    
            end
            return self.helpers['speed'].adjustSpeed(id, original)
    
        elseif id == 0x00d then
            local packed = self.packets.parse('incoming', original)
    
            if packed then
                local player = windower.ffxi.get_player()
    
                if player and player.id == packed['Player'] then
                    return self.helpers['speed'].adjustSpeed(id, original)
                end
    
            end
    
        end
    
    end)

    local drag = 1
    events.mouse = windower.register_event('mouse', function(param, x, y, delta, blocked)
        local player = windower.ffxi.get_player()
        
        if player then
    
            -- Set dragging.
            if (param == 1 or param == 2) then
                drag = ( drag == 1 and 2 or 1 )
            end
    
            if player.main_job == 'BRD' and param == 0 then
                local jukebox   = self.helpers['songs'].jukebox
                local display   = self.helpers['songs'].display
                local icon      = self.helpers['songs'].icon
                
                if jukebox:length() > 0 and icon:hover(x, y) and not display:visible() then
                    self.helpers['songs'].updatePosition()
                    display:show()
    
                elseif jukebox:length() > 0 and icon:hover(x, y) and display:visible() and drag == 2 then
                    self.helpers['songs'].updatePosition()
                    display:update()
    
                elseif not icon:hover(x, y) and display:visible() then
                    self.helpers['songs'].updatePosition()
                    display:hide()
    
                end
            
            elseif (player.main_job == 'SCH' or player.sub_job == 'SCH') and param == 0 then
                local display = self.helpers['stratagems'].display
    
                if display:visible() and display:hover(x, y) and drag == 2 then
                    self.helpers['stratagems'].updatePosition(x, y)
                end
    
            elseif (player.main_job == 'SCH' or player.sub_job == 'SCH') and param == 2 then
                local display = self.helpers['stratagems'].display
    
                if display:visible() and display:hover(x, y) then
                    self.helpers['stratagems'].writeSettings()
                end
    
            end
    
        end
    
    end)

    events.status = windower.register_event('status change', function(new, old)
    
        if new == 0 and (old == 2 or old == 3) then
            self.pinger = (os.clock() + 30)    
        end
    
    end)

    events.zonechange = windower.register_event('zone change', function(new, old)
        self.pinger = (os.clock() + 10)
    
        for _,helper in pairs(self.helpers) do
    
            if helper.zoneChange then
                helper.zoneChange()        
            end
    
        end
    
    end)

    events.jobchange = windower.register_event('job change', function(...)
        self.buildCore(true)
    
        for _,helper in pairs(self.helpers) do
    
            if helper.jobChange then
                helper.jobChange()        
            end
    
        end
    
    end)

    events.party = windower.register_event('party invite', function(sender, id)
        local whitelist = T(self.settings['Auto Join'])
        
        if whitelist and whitelist:contains(sender) then
            windower.send_command('wait 0.5; input /join')
        end
    
    end)

    events.shortcuts = windower.register_event('unhandled command', function(command, ...)
        self.helpers['console'].handle(command, T{...})

    end)

    events.chat = windower.register_event('chat message', function(message, sender, mode, gm)
        self.helpers['commands'].captureChat(message, sender, mode, gm)
    
    end)
    
    events.load = windower.register_event('load', function()
    
    end)

    return self

end
return bootstrap.load()