#ifndef CLASS_MYEVENTHANDLER
#define CLASS_MYEVENTHANDLER

#include "IAppEventHandler.h"
#include "IInputEventHandler.h"
#include "Vector2.h"
#include "ncString.h"

namespace ncine {

class AppConfiguration;
class SceneNode;
class Texture;
class Font;
class Sprite;
class TextNode;
class ParticleSystem;
class AudioBuffer;
class AudioBufferPlayer;

}

namespace nc = ncine;

/// My nCine event handler
class MyEventHandler
	: public nc::IAppEventHandler,
	  public nc::IInputEventHandler
{
  public:
	virtual void onPreInit(nc::AppConfiguration &config);
	virtual void onInit();
	virtual void onFrameStart();
	virtual void onShutdown();

	virtual void onKeyReleased(const nc::KeyboardEvent &event);
#ifdef __ANDROID__
	virtual void onTouchDown(const nc::TouchEvent &event);
	virtual void onTouchMove(const nc::TouchEvent &event);
#else
	virtual void onMouseButtonPressed(const nc::MouseEvent &event);
	virtual void onMouseMoved(const nc::MouseState &state);
#endif
	virtual void onJoyAxisMoved(const nc::JoyAxisEvent &event);

  private:
	nc::SceneNode *dummy_;
	nc::Texture *megaTexture_;
	nc::Font *font_;
	nc::Sprite *blueStick_;
	nc::Sprite *redStick_;
	nc::Sprite *ball_;

	float targetY_;
	nc::Vector2f ballVelocity_;
	int blueScore_;
	int redScore_;
	nc::TextNode *blueScoreText_;
	nc::TextNode *redScoreText_;
	nc::String scoreString_;
	bool shouldKickOff_;
	float joyAxisValue_;

	nc::ParticleSystem *particleSys_;
	nc::AudioBuffer *tickAudioBuffer_;
	nc::AudioBuffer *outAudioBuffer_;
	nc::AudioBufferPlayer *tickSound_;
	nc::AudioBufferPlayer *outSound_;

	void kickOff();
};

#endif
