local accolades = {}
function accolades.new()
    local self = {}

    self.capture = function(bp, commands)
        local bp        = bp or false
        local commands  = commands or false
        
        if bp and commands and commands[2] then
            local item, count = {}, commands[#commands] or false

            for i=2, #commands do
                
                if tonumber(commands[i]) == nil then
                    table.insert(item, commands[i])
                end

            end
            
            if item and item ~= '' then
                bp.helpers['accolades'].poke(bp, table.concat(item, ' '), count)
            end

        end

    end

    return self

end
return accolades.new()
