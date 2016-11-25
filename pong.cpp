#include <cmath>
#include "pong.h"

#include "Application.h"
#include "AppConfiguration.h"
#include "SceneNode.h"
#include "Texture.h"
#include "Font.h"
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
}

void MyEventHandler::onInit()
{
	nc::SceneNode &rootNode = nc::theApplication().rootNode();

	megaTexture_ = new nc::Texture((nc::IFile::dataPath() + TextureFile).data());
	font_ = new nc::Font((nc::IFile::dataPath() + FontTextureFile).data(),
	                     (nc::IFile::dataPath() + "DroidSans32_256.fnt").data());
	tickAudioBuffer_ = new nc::AudioBuffer((nc::IFile::dataPath() + "tick.wav").data());
	outAudioBuffer_ = new nc::AudioBuffer((nc::IFile::dataPath() + "out.wav").data());

	nc::Recti blueStickRect(24, 22, 54, 212);
	nc::Recti redStickRect(174, 22, 56, 212);
	nc::Recti ballRect(92, 92, 72, 72);
	nc::Recti particleRect(116, 23, 23, 35);
	nc::Vector2f stickSize(30.0f, 200.0f);

	tickSound_ = new nc::AudioBufferPlayer(tickAudioBuffer_);
	outSound_ = new nc::AudioBufferPlayer(outAudioBuffer_);

	dummy_ = new nc::SceneNode(&rootNode);
	blueStick_ = new nc::Sprite(dummy_, megaTexture_, nc::theApplication().width() * 0.1f, nc::theApplication().height() * 0.5f);
	blueStick_->setTexRect(blueStickRect);
	blueStick_->setSize(stickSize);
	redStick_ = new nc::Sprite(dummy_, megaTexture_, nc::theApplication().width() * 0.9f, nc::theApplication().height() * 0.5f);
	redStick_->setTexRect(redStickRect);
	redStick_->setSize(stickSize);
	ball_ = new nc::Sprite(dummy_, megaTexture_, nc::theApplication().width() * 0.5f, nc::theApplication().height() * 0.5f);
	ball_->setTexRect(ballRect);
	ball_->setScale(0.5f);

	targetY_ = blueStick_->y;
	ballVelocity_.set(0.0f, 0.0f);

	blueScore_ = 0;
	blueScoreText_ = new nc::TextNode(dummy_, font_);
	blueScoreText_->setColor(126, 148, 164, 225);
	blueScoreText_->setAlignment(nc::TextNode::ALIGN_RIGHT);

	redScore_ = 0;
	redScoreText_ = new nc::TextNode(dummy_, font_);
	redScoreText_->setColor(170, 135, 181, 225);
	redScoreText_->setAlignment(nc::TextNode::ALIGN_LEFT);

	shouldKickOff_ = true;
	joyAxisValue_ = 0.0f;

	particleSys_ = new nc::ParticleSystem(ball_, 50, megaTexture_, particleRect);
	nc::ColorAffector *colAffector = new nc::ColorAffector();
	colAffector->addColorStep(0.0f, nc::Color(255U, 255U, 255U, 0U));
	colAffector->addColorStep(1.0f, nc::Color(255U, 255U, 255U, 255U));
	particleSys_->addAffector(colAffector);
}

void MyEventHandler::onFrameStart()
{
	float step = nc::theApplication().interval();

#ifndef __ANDROID__
	const nc::KeyboardState &keyState = nc::theApplication().inputManager().keyboardState();

	if (keyState.isKeyDown(nc::KEY_UP) || keyState.isKeyDown(nc::KEY_W))
	{
		if (shouldKickOff_) { kickOff(); }
		targetY_ = blueStick_->y + 1.0f;
	}
	else if (keyState.isKeyDown(nc::KEY_DOWN)  || keyState.isKeyDown(nc::KEY_S))
	{
		if (shouldKickOff_) { kickOff(); }
		targetY_ = blueStick_->y - 1.0f;
	}
#endif

	if (joyAxisValue_ > LeftStickDeadZone)
	{
		if (shouldKickOff_) { kickOff(); }
		targetY_ = blueStick_->y + 1.0f;
	}
	else if (joyAxisValue_ < -LeftStickDeadZone)
	{
		if (shouldKickOff_) { kickOff(); }
		targetY_ = blueStick_->y - 1.0f;
	}

	// Moving the blue stick
	if (blueStick_->y > targetY_ + 0.5f)
	{
		blueStick_->y -= StickSpeed * step;
	}
	else if (blueStick_->y < targetY_ - 0.5f)
	{
		blueStick_->y += StickSpeed * step;
	}

	// Moving the red stick
	if (redStick_->y > ball_->y + 0.5f)
	{
		redStick_->y -= StickSpeed * step;
	}
	else if (redStick_->y < ball_->y - 0.5f)
	{
		redStick_->y += StickSpeed * step;
	}

	// Moving the ball
	ball_->x += ballVelocity_.x * BallSpeed * step;
	ball_->y += ballVelocity_.y * BallSpeed * step;

	// Checking for ball and sticks collisions
	nc::Rectf ballRect = ball_->rect();
	nc::Rectf blueRect = blueStick_->rect();
	nc::Rectf redRect = redStick_->rect();
	if (ballRect.x <  blueRect.x + blueRect.w &&
	    ballRect.y + ballRect.h >= blueRect.y &&
	    ballRect.y <= blueRect.y + blueRect.h)
	{
		ball_->x = blueRect.x + blueRect.w + ballRect.w;
		ballVelocity_.x *= -1.0f;
		ballVelocity_.y = -1.0f * ((blueStick_->y - ball_->y) / static_cast<float>(blueRect.h));
		particleSys_->emitParticles(10, 0.2f, -ballVelocity_ * 250.0f);
		tickSound_->play();
	}
	else if (ballRect.x + ballRect.w > redRect.x &&
	         ballRect.y + ballRect.h >= redRect.y &&
	         ballRect.y <= redRect.y + redRect.h)
	{
		ball_->x = redRect.x - ballRect.w;
		ballVelocity_.x *= -1.0f;
		ballVelocity_.y = -1.0f * ((redStick_->y - ball_->y) / float(redRect.h));
		particleSys_->emitParticles(10, 0.2f, -ballVelocity_ * 250.0f);
		tickSound_->play();
	}

	// Ball collision with top or bottom
	if (ballRect.y + ballRect.h > nc::theApplication().height())
	{
		ball_->y = nc::theApplication().height() - ballRect.h * 0.5f;
		ballVelocity_.y *= -1.0f;
		particleSys_->emitParticles(10, 0.2f, -ballVelocity_ * 250.0f);
		tickSound_->play();
	}
	else if (ballRect.y < 0)
	{
		ball_->y = ballRect.h * 0.5f;
		ballVelocity_.y *= -1.0f;
		particleSys_->emitParticles(10, 0.2f, -ballVelocity_ * 250.0f);
		tickSound_->play();
	}

	// Scoring
	if (ballRect.x <= 0)
	{
		particleSys_->emitParticles(30, 1.0f, -ballVelocity_ * 350.0f);
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
		particleSys_->emitParticles(30, 1.0f, -ballVelocity_ * 350.0f);
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
	blueScoreText_->setPosition(0.0f, static_cast<float>(nc::theApplication().height()));

	scoreString_.clear();
	scoreString_.format(static_cast<const char *>("Red: %d"), redScore_);
	redScoreText_->setString(scoreString_);
	redScoreText_->setPosition(static_cast<float>(nc::theApplication().width() - blueScoreText_->width()), static_cast<float>(nc::theApplication().height()));
}

void MyEventHandler::onShutdown()
{
	delete dummy_; // and all its children
	delete tickSound_;
	delete outSound_;
	delete tickAudioBuffer_;
	delete outAudioBuffer_;
	delete font_;
	delete megaTexture_;
}

#ifdef __ANDROID__
void MyEventHandler::onTouchDown(const nc::TouchEvent &event)
{
	targetY_ = event.pointers[0].y;
	if (shouldKickOff_) { kickOff(); }
}

void MyEventHandler::onTouchMove(const nc::TouchEvent &event)
{
	if (abs(targetY_ - event.pointers[0].y) > 3.0f)
	{
		targetY_ = event.pointers[0].y;
	}
}

void MyEventHandler::onKeyReleased(const nc::KeyboardEvent &event)
{
	if (event.sym == nc::KEY_VOLUME_UP || event.sym == nc::KEY_VOLUME_DOWN)
	{
		float volume = nc::theServiceLocator().audioDevice().gain();
		if (event.sym == nc::KEY_VOLUME_UP && volume <= 0.9f)
		{
			volume += 0.1f;
		}
		else if (event.sym == nc::KEY_VOLUME_DOWN && volume >= 0.1f)
		{
			volume -= 0.1f;
		}
		nc::theServiceLocator().audioDevice().setGain(volume);
	}
}
#else
void MyEventHandler::onMouseButtonPressed(const nc::MouseEvent &event)
{
	if (event.isLeftButton())
	{
		targetY_ = static_cast<float>(event.y);
	}

	if (event.isLeftButton() && shouldKickOff_) { kickOff(); }
}

void MyEventHandler::onMouseMoved(const nc::MouseState &state)
{
	if (state.isLeftButtonDown())
	{
		targetY_ = static_cast<float>(state.y);
	}
}

void MyEventHandler::onKeyReleased(const nc::KeyboardEvent &event)
{
	if (event.sym == nc::KEY_ESCAPE || event.sym == nc::KEY_Q)
	{
		nc::theApplication().quit();
	}
	else if (event.sym == nc::KEY_SPACE)
	{
		nc::theApplication().togglePause();
	}
}
#endif

void MyEventHandler::onJoyAxisMoved(const nc::JoyAxisEvent &event)
{
	if (event.joyId == 0 && event.axisId == 1)
	{
#ifdef _WIN32
		joyAxisValue_ = event.normValue;
#else
		joyAxisValue_ = -event.normValue;
#endif
	}
}

void MyEventHandler::kickOff()
{
	shouldKickOff_ = false;
	if (redScore_ > blueScore_)
	{
		ballVelocity_.set(-1.0f, 0.0f);
	}
	else
	{
		ballVelocity_.set(1.0f, 0.0f);
	}
}
