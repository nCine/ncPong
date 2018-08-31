set(PACKAGE_NAME "ncPong")
set(PACKAGE_EXE_NAME "ncpong")
set(PACKAGE_ICON_NAME ${PACKAGE_NAME})
set(PACKAGE_DESCRIPTION "An example game made with the nCine")
set(PACKAGE_AUTHOR_MAIL "encelo@gmail.com")
set(PACKAGE_DESKTOP_FILE "io.github.ncine.ncpong.desktop")
set(PACKAGE_JAVA_URL "io/github/ncine/ncpong")

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
