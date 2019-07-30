set(PACKAGE_NAME "ncPong")
set(PACKAGE_EXE_NAME "ncpong")
set(PACKAGE_VENDOR "Angelo Theodorou")
set(PACKAGE_DESCRIPTION "An example game made with the nCine")
set(PACKAGE_HOMEPAGE "https://ncine.github.io")
set(PACKAGE_REVERSE_DNS "io.github.ncine.ncpong")

set(PACKAGE_SOURCES
	pong.h
	pong.cpp
)

set(PACKAGE_ANDROID_ASSETS
	data/DroidSans32_256.fnt
	data/out.wav
	data/tick.wav
	android/DroidSans32_256.webp
	android/sticks_256.webp
)

function(callback_end)
	if(NOT EMSCRIPTEN)
		include(ncpong_lua)
	endif()
endfunction()
