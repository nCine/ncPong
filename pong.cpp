#include <cmath>
#include "pong.h"

#include "Application.h"
#include "AppConfiguration.h"
#include "SceneNode.h"
#include "Texture.h"
#include "Sprite.h"
#include "TextNode.h"
#include "ParticleSystem.h"
#include "AudioBuffer.h"
#include "AudioBufferPlayer.h"
#include "IFile.h" // for dataPath()

namespace {

#ifdef __ANDROID__
const char *TextureFile = "sticks_256.webp";
const char *FontTextureFile = "DroidSans32_256.webp";
#else
const char *TextureFile = "sticks_256.png";
const char *FontTextureFile = "DroidSans32_256.png";
#endif

const float BallSpeed = 300.0f;
const float StickSpeed = 100.0f;
const float LeftStickDeadZone = 7849 / 32767.0f;

}

nc::IAppEventHandler *createAppEventHandler()
{
	return new MyEventHandler;
}

void MyEventHandler::onPreInit(nc::AppConfiguration &config)
{
	config.enableProfilerGraphs(false);
	config.enableProfilerText(false);
	config.enableThreads(false);

	config.setWindowTitle("ncPong");
#ifdef __ANDROID__
	config.setDataPath("asset::");
#else
	#ifdef NCPONG_DEFAULT_DATA_DIR
	config.setDataPath(NCPONG_DEFAULT_DATA_DIR);
	#else
	config.setDataPath("data/");
	#endif
#endif
	config.setWindowIconFilename("icon48.png");
}

void MyEventHandler::onInit()
{
	nc::SceneNode &rootNode = nc::theApplication().rootNode();

	megaTexture_ = nctl::makeUnique<nc::Texture>((nc::IFile::dataPath() + TextureFile).data());
	font_ = nctl::makeUnique<nc::Font>((nc::IFile::dataPath() + FontTextureFile).data(),
	                                   (nc::IFile::dataPath() + "DroidSans32_256.fnt").data());
	tickAudioBuffer_ = nctl::makeUnique<nc::AudioBuffer>((nc::IFile::dataPath() + "tick.wav").data());
	outAudioBuffer_ = nctl::makeUnique<nc::AudioBuffer>((nc::IFile::dataPath() + "out.wav").data());

	const nc::Recti blueStickRect(24, 22, 54, 212);
	const nc::Recti redStickRect(174, 22, 56, 212);
	const nc::Recti ballRect(92, 92, 72, 72);
	const nc::Recti particleRect(116, 23, 23, 35);
	const nc::Vector2f stickSize(30.0f, 200.0f);

	tickSound_ = nctl::makeUnique<nc::AudioBufferPlayer>(tickAudioBuffer_.get());
	outSound_ = nctl::makeUnique<nc::AudioBufferPlayer>(outAudioBuffer_.get());

	dummy_ = nctl::makeUnique<nc::SceneNode>(&rootNode);
	blueStick_ = nctl::makeUnique<nc::Sprite>(dummy_.get(), megaTexture_.get(), nc::theApplication().width() * 0.1f, nc::theApplication().height() * 0.5f);
	blueStick_->setTexRect(blueStickRect);
	blueStick_->setSize(stickSize);
	redStick_ = nctl::makeUnique<nc::Sprite>(dummy_.get(), megaTexture_.get(), nc::theApplication().width() * 0.9f, nc::theApplication().height() * 0.5f);
	redStick_->setTexRect(redStickRect);
	redStick_->setSize(stickSize);
	ball_ = nctl::makeUnique<nc::Sprite>(dummy_.get(), megaTexture_.get(), nc::theApplication().width() * 0.5f, nc::theApplication().height() * 0.5f);
	ball_->setTexRect(ballRect);
	ball_->setScale(0.5f);

	targetY_ = blueStick_->y;
	ballVelocity_.set(0.0f, 0.0f);

	blueScore_ = 0;
	blueScoreText_ = nctl::makeUnique<nc::TextNode>(dummy_.get(), font_.get());
	blueScoreText_->setColor(126, 148, 164, 225);
	blueScoreText_->setAlignment(nc::TextNode::Alignment::RIGHT);

	redScore_ = 0;
	redScoreText_ = nctl::makeUnique<nc::TextNode>(dummy_.get(), font_.get());
	redScoreText_->setColor(170, 135, 181, 225);
	redScoreText_->setAlignment(nc::TextNode:: Alignment::LEFT);

	shouldKickOff_ = true;
	joyAxisValue_ = 0.0f;

	particleSys_ = nctl::makeUnique<nc::ParticleSystem>(ball_.get(), 50, megaTexture_.get(), particleRect);
	nctl::UniquePtr<nc::ColorAffector> colAffector = nctl::makeUnique<nc::ColorAffector>();
	colAffector->addColorStep(0.0f, nc::Color(255U, 255U, 255U, 0U));
	colAffector->addColorStep(1.0f, nc::Color(255U, 255U, 255U, 255U));
	particleSys_->addAffector(nctl::move(colAffector));
}

void MyEventHandler::onFrameStart()
{
	const float step = nc::theApplication().interval();

	const nc::KeyboardState &keyState = nc::theApplication().inputManager().keyboardState();

	if (keyState.isKeyDown(nc::KeySym::UP) || keyState.isKeyDown(nc::KeySym::W))
	{
		if (shouldKickOff_)
			kickOff();
		targetY_ = blueStick_->y + 1.0f;
	}
	else if (keyState.isKeyDown(nc::KeySym::DOWN)  || keyState.isKeyDown(nc::KeySym::S))
	{
		if (shouldKickOff_)
			kickOff();
		targetY_ = blueStick_->y - 1.0f;
	}

	if (joyAxisValue_ > LeftStickDeadZone)
	{
		if (shouldKickOff_)
			kickOff();
		targetY_ = blueStick_->y + 1.0f;
	}
	else if (joyAxisValue_ < -LeftStickDeadZone)
	{
		if (shouldKickOff_)
			kickOff();
		targetY_ = blueStick_->y - 1.0f;
	}

	// Moving the blue stick
	if (blueStick_->y > targetY_ + 0.5f)
		blueStick_->y -= StickSpeed * step;
	else if (blueStick_->y < targetY_ - 0.5f)
		blueStick_->y += StickSpeed * step;

	// Moving the red stick
	if (redStick_->y > ball_->y + 0.5f)
		redStick_->y -= StickSpeed * step;
	else if (redStick_->y < ball_->y - 0.5f)
		redStick_->y += StickSpeed * step;

	// Moving the ball
	ball_->x += ballVelocity_.x * BallSpeed * step;
	ball_->y += ballVelocity_.y * BallSpeed * step;

	// Checking for ball and sticks collisions
	const nc::Rectf ballRect = nc::Rectf::fromCenterAndSize(ball_->position(), ball_->size());
	const nc::Rectf blueRect = nc::Rectf::fromCenterAndSize(blueStick_->position(), blueStick_->size());
	const nc::Rectf redRect = nc::Rectf::fromCenterAndSize(redStick_->position(), redStick_->size());
	if (ballRect.x <  blueRect.x + blueRect.w &&
	    ballRect.y + ballRect.h >= blueRect.y &&
	    ballRect.y <= blueRect.y + blueRect.h)
	{
		particleSys_->emitParticles(10, 0.25f, ballVelocity_ * 250.0f);
		ball_->x = blueRect.x + blueRect.w + ballRect.w;
		ballVelocity_.x *= -1.0f;
		ballVelocity_.y = -1.0f * ((blueStick_->y - ball_->y) / blueRect.h);
		tickSound_->play();
	}
	else if (ballRect.x + ballRect.w > redRect.x &&
	         ballRect.y + ballRect.h >= redRect.y &&
	         ballRect.y <= redRect.y + redRect.h)
	{
		particleSys_->emitParticles(10, 0.25f, ballVelocity_ * 250.0f);
		ball_->x = redRect.x - ballRect.w;
		ballVelocity_.x *= -1.0f;
		ballVelocity_.y = -1.0f * ((redStick_->y - ball_->y) / redRect.h);
		tickSound_->play();
	}

	// Ball collision with top or bottom
	if (ballRect.y + ballRect.h > nc::theApplication().height())
	{
		particleSys_->emitParticles(10, 0.2f, ballVelocity_ * 250.0f);
		ball_->y = nc::theApplication().height() - ballRect.h * 0.5f;
		ballVelocity_.y *= -1.0f;
		tickSound_->play();
	}
	else if (ballRect.y < 0)
	{
		particleSys_->emitParticles(10, 0.2f, ballVelocity_ * 250.0f);
		ball_->y = ballRect.h * 0.5f;
		ballVelocity_.y *= -1.0f;
		tickSound_->play();
	}

	// Scoring
	if (ballRect.x <= 0)
	{
		particleSys_->emitParticles(30, 1.0f, ballVelocity_ * 350.0f);
		outSound_->play();
		blueStick_->y = nc::theApplication().height() * 0.5f;
		redStick_->y = nc::theApplication().height() * 0.5f;
		targetY_ = nc::theApplication().height() * 0.5f;
		ball_->setPosition(nc::theApplication().width() * 0.5f, nc::theApplication().height() * 0.5f);
		ballVelocity_.set(0.0f, 0.0f);
		redScore_++;
		shouldKickOff_ = true;
	}
	else if (ballRect.x + ballRect.w > nc::theApplication().width())
	{
		particleSys_->emitParticles(30, 1.0f, ballVelocity_ * 350.0f);
		outSound_->play();
		blueStick_->y = nc::theApplication().height() * 0.5f;
		redStick_->y = nc::theApplication().height() * 0.5f;
		targetY_ = nc::theApplication().height() * 0.5f;
		ball_->setPosition(nc::theApplication().width() * 0.5f, nc::theApplication().height() * 0.5f);
		ballVelocity_.set(0.0f, 0.0f);
		blueScore_++;
		shouldKickOff_ = true;
	}

	// Score texts
	scoreString_.clear();
	scoreString_.format(static_cast<const char *>("Blue: %d"), blueScore_);
	blueScoreText_->setString(scoreString_);
	blueScoreText_->setPosition(blueScoreText_->width() * 0.5f, nc::theApplication().height() - blueScoreText_->height() * 0.5f);

	scoreString_.clear();
	scoreString_.format(static_cast<const char *>("Red: %d"), redScore_);
	redScoreText_->setString(scoreString_);
	redScoreText_->setPosition(nc::theApplication().width() - redScoreText_->width() * 0.5f, nc::theApplication().height() - redScoreText_->height() * 0.5f);
}

#ifdef __ANDROID__
void MyEventHandler::onTouchDown(const nc::TouchEvent &event)
{
	targetY_ = event.pointers[0].y;
	if (shouldKickOff_)
		kickOff();
}

void MyEventHandler::onTouchMove(const nc::TouchEvent &event)
{
	if (abs(targetY_ - event.pointers[0].y) > 3.0f)
		targetY_ = event.pointers[0].y;
}
#endif

void MyEventHandler::onKeyReleased(const nc::KeyboardEvent &event)
{
#ifdef __ANDROID__
	if (event.sym == nc::KEY_VOLUME_UP || event.sym == nc::KEY_VOLUME_DOWN)
	{
		float volume = nc::theServiceLocator().audioDevice().gain();

		if (event.sym == nc::KEY_VOLUME_UP && volume <= 0.9f)
			volume += 0.1f;
		else if (event.sym == nc::KEY_VOLUME_DOWN && volume >= 0.1f)
			volume -= 0.1f;

		nc::theServiceLocator().audioDevice().setGain(volume);
	}
	else
#endif
	if (event.sym == nc::KeySym::ESCAPE || event.sym == nc::KeySym::Q)
		nc::theApplication().quit();
	else if (event.sym == nc::KeySym::SPACE)
		nc::theApplication().togglePause();
}

void MyEventHandler::onMouseButtonPressed(const nc::MouseEvent &event)
{
	if (event.isLeftButton())
		targetY_ = static_cast<float>(event.y);

	if (event.isLeftButton() && shouldKickOff_)
		kickOff();
}

void MyEventHandler::onMouseMoved(const nc::MouseState &state)
{
	if (state.isLeftButtonDown())
		targetY_ = static_cast<float>(state.y);
}

void MyEventHandler::onJoyMappedAxisMoved(const nc::JoyMappedAxisEvent &event)
{
	if (event.axisName == nc::AxisName::LY)
		joyAxisValue_ = event.value;
}

void MyEventHandler::kickOff()
{
	shouldKickOff_ = false;

	if (redScore_ > blueScore_)
		ballVelocity_.set(-1.0f, 0.0f);
	else
		ballVelocity_.set(1.0f, 0.0f);
}
