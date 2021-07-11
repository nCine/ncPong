#!/usr/bin/env lua

if ncine == nil then
	ncine_library_dir = "@NCINE_LIBRARY_DIRECTORY@"
	ncine_library_ext = "@CMAKE_SHARED_LIBRARY_SUFFIX@"
	if ncine_library_dir ~= "@".."NCINE_LIBRARY_DIRECTORY".."@" then
		package.cpath = ncine_library_dir.."/?"..ncine_library_ext..";"..package.cpath
	end

	ncine_library_name = "@NCINE_LIBRARY_NAME_WLE@"
	if ncine_library_name == "@".."NCINE_LIBRARY_NAME_WLE".."@" then
		ncine_library_name = "libncine"
	end
	ncine = require(ncine_library_name)
	needs_start = true
end

nc = ncine

if nc.ANDROID then
	font_tex_file = "DroidSans32_256.webp"
	texture_file = "sticks_256.webp"
else
	font_tex_file = "DroidSans32_256.png"
	texture_file = "sticks_256.png"
end

BallSpeed = 300
StickSpeed = 100

function ncine.on_pre_init(cfg)
	cfg.window_title = "Lua ncPong"
if nc.ANDROID then
	cfg.data_path = "asset::"
else
	data_dir = "@NCPROJECT_DEFAULT_DATA_DIR@"
	if data_dir == "@".."NCPROJECT_DEFAULT_DATA_DIR".."@" then
		data_dir = "data/"
	end
	cfg.data_path = data_dir
end
	cfg.window_icon = "icon48.png"

	return cfg
end

function ncine.on_init()
	local rootnode = nc.application.rootnode()
	screen_ = nc.application.screen_dimensions()

	mega_texture_ = nc.texture.new(nc.fs.get_datapath()..texture_file)
	font_ = nc.font.new(nc.fs.get_datapath().."DroidSans32_256.fnt",
	                    nc.fs.get_datapath()..font_tex_file)

	tick_audio_ = nc.audiobuffer.new(nc.fs.get_datapath().."tick.wav")
	out_audio_ = nc.audiobuffer.new(nc.fs.get_datapath().."out.wav")

	local blue_stick_rect = {x = 24, y = 22, w = 54, h = 212}
	local red_stick_rect = {x = 174, y = 22, w = 56, h = 212}
	local ball_rect = {x = 92, y = 92, w = 72, h = 72}
	local particle_rect = {x = 116, y = 23, w = 23, h = 35}
	local stick_size = {x = 30, y = 200}

	tick_sound_ = nc.audiobuffer_player.new(tick_audio_)
	out_sound_ = nc.audiobuffer_player.new(out_audio_)

	blue_stick_ = nc.sprite.new(rootnode, mega_texture_, screen_.x * 0.1, screen_.y * 0.5)
	nc.sprite.set_texrect(blue_stick_, blue_stick_rect)
	nc.sprite.set_size(blue_stick_, stick_size.x, stick_size.y)
	red_stick_ = nc.sprite.new(rootnode, mega_texture_, screen_.x * 0.9, screen_.y * 0.5)
	nc.sprite.set_texrect(red_stick_, red_stick_rect)
	nc.sprite.set_size(red_stick_, stick_size.x , stick_size.y)
	ball_ = nc.sprite.new(rootnode, mega_texture_, screen_.x * 0.5, screen_.y * 0.5)
	nc.sprite.set_texrect(ball_, ball_rect)
	nc.sprite.set_scale(ball_, 0.5)

	local blue_stick_pos = nc.sprite.get_position(blue_stick_)
	target_y_ = blue_stick_pos.y
	ball_velocity_ = {x = 0, y = 0}

	blue_score_ = 0
	blue_score_text_ = nc.textnode.new(rootnode, font_, 256)
	nc.textnode.set_color(blue_score_text_, 126/255, 148/255, 164/255, 225/255)
	nc.textnode.set_alignment(blue_score_text_, nc.text_alignment.RIGHT)

	red_score_ = 0
	red_score_text_ = nc.textnode.new(rootnode, font_, 256)
	nc.textnode.set_color(red_score_text_, 170/255, 135/255, 181/255, 225/255)
	nc.textnode.set_alignment(red_score_text_, nc.text_alignment.LEFT)

	should_kickoff_ = true
	joy_axis_value_ = 0.0

	particlesys_ = nc.particle_system.new(ball_, 50, mega_texture_, particle_rect)
	nc.particle_system.add_color_affector(particlesys_, {
		{0.0, {r = 1.0, g = 1.0, b = 1.0, a = 1.0}},
		{1.0, {r = 1.0, g = 1.0, b = 1.0, a = 0.0}}
	})
end

function ncine.on_frame_start()
	local step = nc.application.interval()
	local key_state = nc.input.key_state()

	local blue_stick_pos = nc.sprite.get_position(blue_stick_)
	local blue_stick_size = nc.sprite.get_size(blue_stick_)
	local red_stick_pos = nc.sprite.get_position(red_stick_)
	local red_stick_size = nc.sprite.get_size(red_stick_)
	local ball_pos = nc.sprite.get_position(ball_)
	local ball_size = nc.sprite.get_size(ball_)

	if nc.input.key_down(key_state, nc.keysym.UP) or nc.input.key_down(key_state, nc.keysym.W) then
		if should_kickoff_ then
			kickoff()
		end
		target_y_ = blue_stick_pos.y + 1
	elseif nc.input.key_down(key_state, nc.keysym.DOWN) or nc.input.key_down(key_state, nc.keysym.S) then
		if should_kickoff_ then
			kickoff()
		end
		target_y_ = blue_stick_pos.y - 1
	end

	if joy_axis_value_ > nc.joy_dead_zone.LEFT_STICK then
		if should_kickoff_ then
			kickoff()
		end
		target_y_ = blue_stick_pos.y - 1
	elseif joy_axis_value_ < -nc.joy_dead_zone.LEFT_STICK then
		if should_kickoff_ then
			kickoff()
		end
		target_y_ = blue_stick_pos.y + 1
	end

	-- Moving the blue stick
	if blue_stick_pos.y > target_y_ + 0.5 then
		blue_stick_pos.y = blue_stick_pos.y - StickSpeed * step
	elseif blue_stick_pos.y < target_y_ - 0.5 then
		blue_stick_pos.y = blue_stick_pos.y + StickSpeed * step
	end
	nc.sprite.set_position(blue_stick_, blue_stick_pos)

	-- Moving the red stick
	if red_stick_pos.y >ball_pos.y + 0.5 then
		red_stick_pos.y = red_stick_pos.y - StickSpeed * step
	elseif red_stick_pos.y < ball_pos.y - 0.5 then
		red_stick_pos.y = red_stick_pos.y + StickSpeed * step
	end
	nc.sprite.set_position(red_stick_,red_stick_pos)

	-- Moving the ball
	ball_pos.x = ball_pos.x + ball_velocity_.x * BallSpeed * step
	ball_pos.y = ball_pos.y + ball_velocity_.y * BallSpeed * step

	local init_particles = {
		amount = 10, life = {0.2, 0.25},
		position = {{x = -10, y = -10}, {x = 10, y = 10}},
		velocity = {{x = ball_velocity_.x * 200, y = -10}, {x = ball_velocity_.x * 250, y = 10}}
	}

	-- Checking for ball and sticks collisions
	local ball_rect = nc.rect.create_center_size(ball_pos.x, ball_pos.y, ball_size.x, ball_size.y)
	local blue_rect = nc.rect.create_center_size(blue_stick_pos.x, blue_stick_pos.y, blue_stick_size.x, blue_stick_size.y)
	local red_rect = nc.rect.create_center_size(red_stick_pos.x, red_stick_pos.y, red_stick_size.x, red_stick_size.y)

	if (ball_rect.x <  blue_rect.x + blue_rect.w and
	    ball_rect.y + ball_rect.h >= blue_rect.y and
	    ball_rect.y <= blue_rect.y + blue_rect.h)
	then
		nc.particle_system.emit_particles(particlesys_, init_particles)
		ball_pos.x = blue_rect.x + blue_rect.w + ball_rect.w
		ball_velocity_.x = ball_velocity_.x * -1
		ball_velocity_.y = -1 * ((blue_stick_pos.y - ball_pos.y) / blue_rect.h)
		nc.audiobuffer_player.play(tick_sound_)
	elseif (ball_rect.x + ball_rect.w > red_rect.x and
	        ball_rect.y + ball_rect.h >= red_rect.y and
	        ball_rect.y <= red_rect.y + red_rect.h)
	then
		nc.particle_system.emit_particles(particlesys_, init_particles)
		ball_pos.x = red_rect.x - ball_rect.w
		ball_velocity_.x = ball_velocity_.x * -1
		ball_velocity_.y = -1 * ((red_stick_pos.y - ball_pos.y) / red_rect.h)
		nc.audiobuffer_player.play(tick_sound_)
	end

	-- Ball collision with top or bottom
	if ball_rect.y + ball_rect.h > screen_.y then
		nc.particle_system.emit_particles(particlesys_, init_particles)
		ball_pos.y = screen_.y - ball_rect.h * 0.5
		ball_velocity_.y = ball_velocity_.y * -1
		nc.audiobuffer_player.play(tick_sound_)
	elseif ball_rect.y < 0 then
		nc.particle_system.emit_particles(particlesys_, init_particles)
		ball_pos.y = ball_rect.h * 0.5
		ball_velocity_.y = ball_velocity_.y * -1
		nc.audiobuffer_player.play(tick_sound_)
	end
	nc.sprite.set_position(ball_, ball_pos)

	-- Scoring
	if ball_rect.x <= 0 then
		nc.particle_system.emit_particles(particlesys_, init_particles)
		nc.audiobuffer_player.play(out_sound_)
		red_score_ = red_score_ + 1
		reset()
	elseif ball_rect.x + ball_rect.w > screen_.x then
		nc.particle_system.emit_particles(particlesys_, init_particles)
		nc.audiobuffer_player.play(out_sound_)
		blue_score_ = blue_score_ + 1
		reset()
	end

	-- Score texts
	local blue_score_width = nc.textnode.get_width(blue_score_text_)
	local blue_score_height = nc.textnode.get_height(blue_score_text_)
	nc.textnode.set_string(blue_score_text_, "Blue: "..blue_score_)
	nc.textnode.set_position(blue_score_text_, blue_score_width * 0.5, screen_.y - blue_score_height * 0.5)

	local red_score_width = nc.textnode.get_width(red_score_text_)
	local red_score_height = nc.textnode.get_height(red_score_text_)
	nc.textnode.set_string(red_score_text_, "Red: "..red_score_)
	nc.textnode.set_position(red_score_text_, screen_.x - red_score_width * 0.5, screen_.y - red_score_height * 0.5)
end

function ncine.on_shutdown()
	nc.particle_system.delete(particlesys_)

	nc.textnode.delete(red_score_text_)
	nc.textnode.delete(blue_score_text_)

	nc.sprite.delete(ball_)
	nc.sprite.delete(red_stick_)
	nc.sprite.delete(blue_stick_)

	nc.audiobuffer_player.delete(out_sound_)
	nc.audiobuffer_player.delete(tick_sound_)
	nc.audiobuffer.delete(out_audio_)
	nc.audiobuffer.delete(tick_audio_)

	nc.font.delete(font_)
	nc.texture.delete(mega_texture_)
end

function ncine.on_touch_down(event)
	target_y_ = event[0].y
	if should_kickoff_ then
		kickoff()
	end
end

function ncine.on_touch_move(event)
	local diff = target_y_ - event[0].y
	if diff > 3 or diff < -3 then
		target_y_ = event[0].y
	end
end

function ncine.on_key_released(event)
if nc.ANDROID then
	if event.sym == nc.keysym.VOLUME_UP or event.sym == nc.keysym.VOLUME_DOWN then
		local volume = nc.audio_device.get_gain()

		if event.sym == nc.keysym.VOLUME_UP and volume <= 0.9 then
			volume = volume + 0.1
		elseif event.sym == nc.keysym.VOLUME_DOWN and volume >= 0.1 then
			volume = volume - 0.1
		end

		nc.audio_device.set_gain(volume)
	end
end

	if event.sym == nc.keysym.R then
		red_score_ = 0
		blue_score_ = 0
		reset()
	elseif event.sym == nc.keysym.Q or event.sym == nc.keysym.ESCAPE then
		nc.application.quit()
	elseif event.sym == nc.keysym.SPACE then
		local is_suspended = nc.application.is_suspended()
		nc.application.set_suspended(not is_suspended)
	end
end


function ncine.on_mouse_button_pressed(event)
	if event.button == nc.mouse_button.LEFT then
		target_y_ = event.y
	end

	if event.button == nc.mouse_button.LEFT and should_kickoff_ then
		kickoff()
	end
end

function ncine.on_mouse_moved(state)
	if state.left_pressed then
		target_y_ = state.y
	end
end

function ncine.on_joymapped_axis_moved(event)
	if event.axis == nc.joy_axis.LY then
		joy_axis_value_ = event.value
	end
end

function ncine.on_joymapped_button_released(event)
	if event.button == nc.joy_button.START then
		red_score_ = 0
		blue_score_ = 0
		reset()
	elseif event.button == nc.joy_button.GUIDE then
		nc.application.quit()
	end
end

function kickoff()
	should_kickoff_ = false

	if red_score_ > blue_score_ then
		ball_velocity_ = {x = -1, y = 0}
	else
		ball_velocity_ = {x = 1, y = 0}
	end
end

function reset()
	local blue_stick_pos = nc.sprite.get_position(blue_stick_)
	local red_stick_pos = nc.sprite.get_position(red_stick_)

	blue_stick_pos.y = screen_.y * 0.5
	nc.sprite.set_position(blue_stick_, blue_stick_pos)
	red_stick_pos.y = screen_.y * 0.5
	nc.sprite.set_position(red_stick_, red_stick_pos)
	target_y_ = screen_.y * 0.5
	nc.sprite.set_position(ball_, screen_.x * 0.5, screen_.y * 0.5)
	ball_velocity_ = {x = 0, y = 0}
	should_kickoff_ = true
end

if needs_start then
	ncine.start()
end

