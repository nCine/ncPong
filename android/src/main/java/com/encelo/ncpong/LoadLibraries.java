package com.encelo.ncpong;

import android.app.NativeActivity;

public class LoadLibraries extends NativeActivity {

	static {
		System.loadLibrary("openal");
		System.loadLibrary("ncine");
		System.loadLibrary("game");
	}

} 
