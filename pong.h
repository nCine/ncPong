#ifndef CLASS_MYEVENTHANDLER
#define CLASS_MYEVENTHANDLER

#include "IAppEventHandler.h"
#include "IInputEventHandler.h"
#include "Vector2.h"
#include "nctl/String.h"
#include "nctl/UniquePtr.h"

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
class MyEventHandler :
	public nc::IAppEventHandler,
	public nc::IInputEventHandler
{
  public:
	void onPreInit(nc::AppConfiguration &config) override;
	void onInit() override;
	void onFrameStart() override;

#ifdef __ANDROID__
	virtual void onTouchDown(const nc::TouchEvent &event) override;
	virtual void onTouchMove(const nc::TouchEvent &event) override;
#endif
	void onKeyReleased(const nc::KeyboardEvent &event) override;
	void onMouseButtonPressed(const nc::MouseEvent &event) override;
	void onMouseMoved(const nc::MouseState &state) override;
	void onJoyMappedAxisMoved(const nc::JoyMappedAxisEvent &event) override;
	void onJoyMappedButtonReleased(const nc::JoyMappedButtonEvent &event) override;

  private:
	nctl::UniquePtr<nc::Texture> megaTexture_;
	nctl::UniquePtr<nc::Font> font_;
	nctl::UniquePtr<nc::SceneNode> dummy_;
	nctl::UniquePtr<nc::Sprite> blueStick_;
	nctl::UniquePtr<nc::Sprite> redStick_;
	nctl::UniquePtr<nc::Sprite> ball_;

	float targetY_;
	nc::Vector2f ballVelocity_;
	int blueScore_;
	int redScore_;
	nctl::UniquePtr<nc::TextNode> blueScoreText_;
	nctl::UniquePtr<nc::TextNode> redScoreText_;
	nctl::String scoreString_;
	bool shouldKickOff_;
	float joyAxisValue_;

	nctl::UniquePtr<nc::ParticleSystem> particleSys_;
	nctl::UniquePtr<nc::AudioBuffer> tickAudioBuffer_;
	nctl::UniquePtr<nc::AudioBuffer> outAudioBuffer_;
	nctl::UniquePtr<nc::AudioBufferPlayer> tickSound_;
	nctl::UniquePtr<nc::AudioBufferPlayer> outSound_;

	void kickOff();
	void reset();
};

#endif
