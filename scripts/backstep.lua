-- backstep.lua
--
-- Faster frame-back-step for mpv

local mp = require('mp')
local utils = require('mp.utils')

function ffprobe()
	local subprocess = utils.subprocess({args = {
		'ffprobe',
		'-v', '0',
		'-of', 'compact=p=0',
		'-select_streams', '0',
		'-show_entries', 'stream=r_frame_rate',
		mp.get_property('path')
	}})
	if subprocess.status == 0 then
		local frames, seconds = subprocess.stdout:match('r_frame_rate=(%d+)/(%d+)')
		return seconds / frames
	end
	return nil
end

function change_direction(direction)
	if mp.get_property('play-direction') ~= direction then
		mp.command('cycle play-direction')
		mp.osd_message(string.format('P: %s', direction:gsub('^%l', string.upper)))
	end
end

function frame_step(event, direction)
	change_direction(direction)
	if event.event == 'down' or event.event == 'repeat' then
		mp.command('frame-step')
	elseif event.event == 'up' then -- counters imprecision of 'repeat'
		mp.set_property('pause', 'yes')
	end
end

function frame_seek(event, direction) -- different method of stepping frames
	local frame_duration = ffprobe()
	if direction ~= 'forward' then
		frame_duration = frame_duration * -1
	end
	if event.event == 'down' then
		mp.command('seek ' .. frame_duration .. ' exact')
	elseif event.event == 'up' then
		mp.set_property('pause', 'yes')
	end
end

mp.add_key_binding(nil, 'frame-forestep', function(event)
	frame_step(event, 'forward')
end, {complex = true})

mp.add_key_binding(nil, 'frame-backstep', function(event)
	frame_step(event, 'backward')
end, {complex = true})

mp.add_key_binding(nil, 'frame-foreseek', function(event)
	frame_seek(event, 'forward')
end, {complex = true})

mp.add_key_binding(nil, 'frame-backseek', function(event)
	frame_seek(event, 'backward')
end, {complex = true})

mp.add_key_binding(nil, 'video-foreplay', function(event) -- intentionally named
	change_direction('forward')
	mp.command('cycle pause')
end)

mp.add_key_binding(nil, 'video-backplay', function(event)
	change_direction('backward')
	mp.command('cycle pause')
end)