local http = require('gamesense/http')

local NL = {} -- The main table

function NL.print(text, status)
    if status == 3 then
        client.color_log(0, 0, 255, '[NanoLeaf] \0') --blue for auth token
    elseif status == 2 then
        client.color_log(255, 0, 0, '[NanoLeaf] \0')  --red for error
    else
        client.color_log(0, 255, 0, '[NanoLeaf] \0')  --green for the rest
    end
    return client.color_log(255, 255, 255, text)
end


local link
function NL.main(main_auth_token, main_ip_adress)
    link = 'http://' .. main_ip_adress .. ':16021/api/v1/' .. main_auth_token
end


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




function Authenticate(private_ipv4)
    http.post('http://' .. private_ipv4 .. ':16021/api/v1/new', { headers = { ['Content-Type'] = 'application/json' }}, function(s, response)
        if response.status == 403 then
            return NL.print('Error: not successful, wait for blinking lights', 2)
        elseif response.status == 200 then
            local json = json.parse(response.body)
            NL.print(('AUTH TOKEN: ' .. json.auth_token .. ' IP: ' .. private_ipv4), 3)
        else
            NL.print('Error: Unknown error.' .. response.status, 2)
        end
    end)
end


function NL.auth()
    http.get('https://my.nanoleaf.me/api/v1/devices/discover', function(s, response)
        if response.status == 200 then 
            local ip_adress = json.parse(response.body:sub(2, -2))
            Authenticate(ip_adress.private_ipv4)
        elseif response.status == 404 then
            local error = json.parse(response.body:sub(2, -2))
            NL.print('Error: ' .. error.status .. ' message: ' .. error.name, 2)
        end
    end)
end


function NL.color(r,g,b,alpha)
    local arguments = {r,g,b,alpha}

    --option #1
    local validtypes = {
        type(r),
        type(g),
        type(b),
        type(alpha)
    }
    for i=1, #arguments do
        if validtypes[i] ~= "number" then
            return NL.print('Error: argument: ' .. i .. ' can only be a number', 2)
        end
    end

    --[[ 
        option #2

        if type(r) == 'number' and type(g) == 'number' and type(b) == 'number' and type(alpha) == 'number' then
        else
            eturn NL.print('Error: argument: can only be a number', 2)
        end
    ]]


    if #arguments == 3 or #arguments == 4 and alpha > 100 then
        alpha = 100
    elseif #arguments < 3 then
        return NL.print('Error: you need atleast 3 RGB values', 2)
    end

    local hsv = rgb2hsv(r,g,b)
    data = { 
        hue = { value = math.floor(hsv['hue']) }, 
        sat = { value = math.floor(hsv['saturation']) * 100 }, 
        brightness = { value = alpha,  duration = 0 } 
    }

    if link == nil then
        return NL.print('Error: Auth not defined yet.', 2)
    end

    http.put(link .. '/state', { headers = { ['Content-Type'] = 'application/json' }, body = json.stringify(data) }, function(s, response)
        if not response.status == 204 then 
            return NL.print('Error: '.. json.stringify(data), 2)
        end
    end)
end


function NL.switch(boolean)
    if link == nil then
        return NL.print('Error: Auth not defined yet.', 2)
    end

	if type(boolean) ~= "boolean" and not boolean == nil then
		return NL.print('Error: switch must be a boolean', 2)
	end


    if boolean == nil then
        http.get(link .. '/state/on', { headers = { ['Content-Type'] = 'application/json' } }, function(s, response)
            if not response.status == 204 then 
                return NL.print('Error: ' .. response.status, 2)
            else
                return NL.print(response.body)
            end
        end)
    else
        http.put(link .. '/state', { headers = { ['Content-Type'] = 'application/json' }, body = json.stringify({on = { value = boolean }})}, function(s, response) 
            if not response.status == 204 then 
                return NL.print('Error: ' .. response.status, 2)
            end
        end)
    end
end



function NL.brightness(number)
    if link == nil then
        return NL.print('Error: Auth not defined yet.', 2)
    end

    if type(number) ~= "number" and not number == nil then
        return NL.print('Error: brightness must be a number', 2)
    else
        if not number == nil and number > 100 then number = 100 end
    end

    if number == nil then
        http.get(link .. '/state/brightness', { headers = { ['Content-Type'] = 'application/json' } }, function(s, response)
            if not response.status == 204 then 
                return NL.print('Error: ' .. response.status, 2)
            else
                return NL.print(response.body)
            end
        end)
    else
        http.put(link .. '/state', { headers = { ['Content-Type'] = 'application/json' }, body = json.stringify({ brightness = { value = number,  duration = 0 } }) }, function(s, response)
            if not response.status == 204 then 
                return NL.print('Error: ' .. response.status, 2)
            end
        end)
    end
end


function NL.effect(string)
    if link == nil then
        return NL.print('Error: Auth not defined yet.', 2)
    end

    if type(string) ~= "string" and not string == nil then
        return NL.print('Error: effect must be a string', 2)
    end

    if string == nil then
        http.get(link .. '/effects', { headers = { ['Content-Type'] = 'application/json' } }, function(s, response) 
            if not response.status == 204 then 
                return NL.print('Error: ' .. response.status, 2)
            else
                return NL.print(response.body)
            end
        end)
    else
        http.put(link .. '/effects', { headers = { ['Content-Type'] = 'application/json' }, body = json.stringify({select = string }) }, function(s, response) 
            if not response.status == 204 then 
                return NL.print('Error: ' .. response.status, 2)
            end
        end)
    end
end


function NL.remove(string)
    if link == nil then
        return NL.print('Error: Auth not defined yet.', 2)
    end

    if type(string) ~= "string" and not string == nil then
        return NL.print('Error: effect must be a string', 2)
    end

    if string == nil then
        delete_link = link
    else
        delete_link = string.format('%s%s', link:sub(0, -33), string)
    end

    http.delete(delete_link, function(s, response) 
        if not response.status == 204 then 
            return NL.print('Error: ' .. response.status, 2)
        else
            return NL.print('AUTH Token has been deleted', 2)
        end
    end)
end


return NL
