--[[
    API USAGE:
    Nanoleaf("Effect Name") --Sets lights to selected effect
    NanoLeaf(true) --Turns lights on
    NanoLeaf(false) --Turns lights off
    NanoLeaf(255, 255, 255, 255) --Sets color
    NanoLeaf(50) --Sets brightness to 50%
]]


local http = require("gamesense/http")



function print_color(text)
    client.color_log(0, 255, 0, '[NanoLeaf] \0') 
    return client.color_log(255, 255, 255, text)
end

--Request new auth key via IPV4 adress
function Auth(private_ipv4)
    http.post('http://' .. private_ipv4 .. ':16021/api/v1/new', { headers = { ["Content-Type"] = "application/json" }}, function(s, r)
        print_color('Sending AUTH request')
        if r.status == 403 then
            return client.error_log('[NanoLeaf] Not successful wait for blinking lights and retry.')
        elseif r.status == 200 then
            auth = json.parse(r.body)

            database.write('setup_nanoleaf', true)
            print_color('AUTH request successful')
            print_color('STORING YOUR AUTH_TOKEN: ' .. auth.auth_token)
            print_color('STORING YOUR PRIVATE_IPV4: ' .. tostring(private_ipv4))
            database.write('AUTH_TOKEN_TEST', auth.auth_token)
            database.write('PRIVATE_IPV4_TEST', ipv4)
        else
            client.error_log('Unknown error.')
        end
    end)
end

--Check if setup has been completed
if database.read('setup_nanoleaf') == not nil then
    ui.new_button('LUA', 'a', 'Nanoleaf Setup', function()
        http.get('https://my.nanoleaf.me/api/v1/devices/discover', function(s, response)
            if not response.status == 304 then return end
            local json = json.parse(response.body:sub(2, -2))
            print_color('Grabbing IPV4 address')
            Auth(json.private_ipv4)
        end)
        --Show all menu elements.
    end)
    --do return end --kill rest of the code because the setup is not completed yet.
end

local color_picker = ui.new_color_picker('LUA', 'a', 'NanoLeaf Color Picker', 255 ,0 ,255 ,255)
local on_off = ui.new_checkbox('LUA', 'a', 'NanoLeaf Main')
local brightness = ui.new_slider('LUA', 'a', 'NanoLeaf Max Brightness', 0, 100, 50)
local miss_flash = ui.new_checkbox('LUA', 'a', 'Hit/Miss color flash')
local return_color = ui.new_checkbox('LUA', 'a', 'Return to selected color')
local health_lights = ui.new_checkbox('LUA', 'a', 'Health based lights')
local flash_lights = ui.new_checkbox('LUA', 'a', 'Turn lights on flashed')



function rgb2hsv(r,g,b)
	local R = r/255
	local G = g/255
	local B = b/255
	local cMax = math.max(R,G,B)
	local cMin = math.min(R,G,B)
	local diff = cMax - cMin

	local hue = 0
	if diff == 0 then
		hue = 0
	elseif cMax == R then
		hue = 60 * (((G-B)/diff)%6)
	elseif cMax == G then
		hue = 60 * (((B-R)/diff)+2)
	elseif cMax == B then
		hue = 60 * (((R-G)/diff)+4)
	end

	local saturation = 0
	if cMax ~= 0 then
		saturation = diff/cMax
	end

	local value = cMax
    local hsv = {hue=hue,saturation=saturation,value=value}

	return hsv
end


local ipv4
local link
local listbox
local token = 'fobZRplVuZdPMR1IGg8ZjhoTUEb5IZRk'
local main_link = 'http://192.168.178.241:16021/api/v1/fobZRplVuZdPMR1IGg8ZjhoTUEb5IZRk'


local effect_list = {}

http.get(main_link .. '/effects/effectsList', function(s, response)
    local list = response.body:sub(2, -2)
    for match in (list:gsub('"', "")..","):gmatch("(.-)"..",") do
        table.insert(effect_list, match);
    end
    listbox = ui.new_listbox('LUA', 'a', 'Effect list', effect_list)
    local effect_button = ui.new_button('LUA', 'a', 'NanoLeaf set effect', function()
        NanoLeaf(effect_list[ui.get(listbox) + 1])
    end)
end)




function NanoLeaf(r,g,b,a)
    local arguments = {r,g,b,a}
    if a == nil or a > 100 then a = 100 end
    if #arguments < 2 then
        datatype = r
    end

    if #arguments == 1 and type(datatype) == 'string' then 
        link = main_link .. '/effects'
        data = { select= datatype}
    elseif #arguments == 1 and type(datatype) == 'boolean' then
        link = main_link .. '/state'
        data = { on = { value = datatype } } --on/off
    elseif #arguments == 1 and type(datatype) == 'number' then
        link = main_link .. '/state'
        data = { brightness = { value = datatype, duration = 0 }}
    elseif #arguments == 4 then
        local hsv = rgb2hsv(r,g,b)
        data = { 
            hue = { value = math.floor(hsv["hue"]) }, 
            sat = { value = math.floor(hsv["saturation"]) * 100 }, 
            brightness = { value = a,  duration = 0 } 
        }
    end

    http.put(link, { headers = { ["Content-Type"] = "application/json" }, body = json.stringify(data) }, function(s, response)
        if not response.status == 404 then 
            return client.error_log('Bad request:', json.stringify(data)  )
        end
    end)
end






local button = ui.new_button('LUA', 'a', 'NanoLeaf Switch/Color', function()
    local r,g,b = ui.get(color_picker)
    if not ui.get(on_off) then
        NanoLeaf(false)
    else
        NanoLeaf(true)
        NanoLeaf(r, g, b, ui.get(brightness))
    end
end)



local isFlashed
local flashtime

client.set_event_callback("paint", function ()
    if ui.get(flash_lights) then
        flashtime = entity.get_prop(entity.get_local_player(), "m_flFlashDuration")
        if flashtime > 0 and not isFlashed then
            isFlashed = true
            NanoLeaf(255, 255, 255, 100)
            client.delay_call(entity.get_prop(entity.get_local_player(), "m_flFlashDuration") / 1.75, function()
                NanoLeaf(false)
            end)
        elseif flashtime == 0 and isFlashed then
            isFlashed = not isFlashed
        end
    end
end)


         
client.set_event_callback('aim_hit', function()
    local r,g,b = ui.get(color_picker)
    if ui.get(on_off) and ui.get(miss_flash) then
        NanoLeaf(0, 255 , 0, ui.get(brightness))
        client.delay_call(1, function()
            if ui.get(return_color) then
                NanoLeaf(r, g , b, ui.get(brightness))
            else
                NanoLeaf(false)
            end  
        end)
    end
end)

client.set_event_callback('aim_miss', function(e)
    local r,g,b = ui.get(color_picker)
    if ui.get(on_off) and ui.get(miss_flash) then
        NanoLeaf(255, 0 , 0, ui.get(brightness))
        client.delay_call(1, function()
            if ui.get(return_color) then
                NanoLeaf(r, g , b, ui.get(brightness))
            else
                NanoLeaf(false)
            end      
        end)
    end
end)


client.set_event_callback("player_hurt", function(e)
    local health = entity.get_prop(entity.get_local_player(), 'm_iHealth')
    if client.userid_to_entindex(e.userid) == entity.get_local_player() and ui.get(health_lights) and ui.get(on_off) then
        if (health > 80) then
            NanoLeaf(0, 255, 0, ui.get(brightness))
        elseif (health > 60) then
            NanoLeaf(154, 255, 0, ui.get(brightness))
        elseif (health > 40) then
            NanoLeaf(251, 101, 0, ui.get(brightness))
        elseif (health > 30) then
            NanoLeaf(185, 60, 0, ui.get(brightness))
        else
            NanoLeaf(255, 0, 0, ui.get(brightness))
        end
    end
end)
client.set_event_callback("round_prestart", function()
    if ui.get(on_off) and ui.get(health_lights) then
        NanoLeaf(0, 255, 0, ui.get(brightness))
    end
end)




client.set_event_callback('paint_ui', function()


    if ui.get(miss_flash) then
        ui.set_visible(return_color, true)
    else
        ui.set_visible(return_color, false)
    end

    if ui.get(on_off) then
        ui.set_visible(color_picker, true)
        ui.set_visible(brightness, true)
        ui.set_visible(health_lights, true)
        ui.set_visible(miss_flash, true)
        ui.set_visible(flash_lights, true)
    else
        ui.set_visible(color_picker, false)
        ui.set_visible(brightness, false)
        ui.set_visible(health_lights, false)
        ui.set_visible(miss_flash, false)
        ui.set_visible(flash_lights, false)
    end
end)
