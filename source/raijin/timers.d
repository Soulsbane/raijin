/**
	Add support for creating a repeating timer.

	Authors:
		Paul Crane
*/
module raijin.timers;

import core.thread : Thread;
import core.time;
import std.string : chompPrefix;
import std.traits : isDelegate;

alias dur = core.time.dur; // Avoids having to import core.time in the user's program.
alias VoidDelegate = void delegate();

/**
	A class for creating a RepeatingTimer.

	Examples:
		--------------------------------------
		import std.stdio;
		import raijin;

		class MyRepeatingTimer : RepeatingTimer
		{
			this()
			{
				name = "This is the name MyRepeatingTimer";
			}
			override void onTimer()
			{
				writeln(name);
			}
		}

		class InitialDelayRepeatingTimer : RepeatingTimer
		{
		}

		void main()
		{
			auto myDelay = dur!("seconds")(1);

			auto myTimer = new MyRepeatingTimer;

			myTimer.start(myDelay);

			auto initialDelayTimer = new InitialDelayRepeatingTimer ;
			auto initialDelay = dur!("seconds")(3);

			initialDelayTimer.start(myDelay, initialDelay);

			auto delay = dur!("seconds")(1);
			auto countdownDelay = dur!("seconds")(3);

			writeln("HELLO");
		}
		--------------------------------------
*/
class RepeatingTimer
{
	this()
	{
		thread_ = new Thread(&run);
		thread_.name = this.toString.chompPrefix("app.");
	}

	/**
		Starts the timer

		Params:
			dur = $(LINK2 http://dlang.org/phobos/core_time.html#.Duration, Duration) in which onTimer should be called.
			initialDelay = The $(LINK2 http://dlang.org/phobos/core_time.html#.Duration, Duration) to wait before starting the timer.
	*/
	void start(const Duration dur = dur!("seconds")(1), const Duration initialDelay = dur!("seconds")(0))
	{
		dur_ = dur;
		initialDelay_ = initialDelay;

		if(!onTimer_)
		{
			onTimer_ = &onTimer;
		}

		if(!onTimerStart_)
		{
			onTimerStart_ = &onTimerStart;
		}

		if(!onTimerStop_)
		{
			onTimerStop_ = &onTimerStop;
		}

		thread_.start();
	}

	/**
		Sets a callback to a function instead of having to inherit from class.

		Params:
			callBackName = Name of the callback to use(valid values are: onTimer, onTimerStart or onTimerStop).
			callback = The function to be called. Function must take no arguments and have void return type.
	*/
	void setCallBack(T)(const string callBackName, T callback)
	{
		VoidDelegate voidCall;

		static if(!isDelegate!T)
		{
			import std.functional : toDelegate;
			voidCall = toDelegate(callback);
		}
		else
		{
			voidCall = callback;
		}

		final switch(callBackName)
		{
			case "onTimer":
				onTimer_ = voidCall;
				break;
			case "onTimerStart":
				onTimerStart_ = voidCall;
				break;
			case "onTimerStop":
				onTimerStop_ = voidCall;
				break;
		}
	}

	/**
		Called when the timer starts.
	*/
	void onTimerStart() {}

	/**
		Called each every Duration specified.
	*/
	void onTimer() {}

	/**
		Called when the timer stops.
	*/
	void onTimerStop() {}

	/**
		Stops the timer.
	*/
	void stop()
	{
		running_ = false;
	}

protected:
	/**
		Returns the name of the timer(this.toString by default).
	*/
	string name() @property
	{
		return thread_.name;
	}

	/**
		Sets the threads name.
	*/
	void name(const string name) @property
	{
		thread_.name = name;
	}

private:
	/**
		Called when the timer is created.
	*/
	void run()
	{
		onTimerStart_();

		if(initialDelay_ != seconds(0))
		{
			thread_.sleep(initialDelay_);
		}

		onTimer_();

		MonoTime before = MonoTime.currTime;

		while(running_)
		{
			thread_.sleep(dur!("msecs")(10)); // Throttle so we don't take up too much CPU

			MonoTime after = MonoTime.currTime;
			immutable Duration dur = after - before;

			if(dur >= dur_)
			{
				onTimer_();

				before = MonoTime.currTime;
				after = MonoTime.currTime;
			}
		}

		onTimerStop_();
	}

private:
	bool running_ = true;
	Thread thread_;
	Duration dur_;
	Duration initialDelay_;

	VoidDelegate onTimer_;
	VoidDelegate onTimerStart_;
	VoidDelegate onTimerStop_;
}

/**
	Creates a timer that fires onCountdownFinished after the specified time is elapsed.

	Examples:
		--------------------------------------
		import std.stdio;
		import raijin;

		class CustomCountdown : CountdownTimer
		{
			override void onCountdownFinished()
			{
				writeln("My onCountdownFinished = ", name);
			}
		}

		void main()
		{
			auto delay = dur!("seconds")(1);

			auto countdown = new CountdownTimer;
			countdown.start(delay);

			auto custom = new CustomCountdown;
			custom.start(delay);
		}
		--------------------------------------
*/
class CountdownTimer
{
	this()
	{
		thread_ = new Thread(&run);
		thread_.name = this.toString.chompPrefix("app.");
	}

	/**
		Starts the timer

		Params:
			waitTime = $(LINK2 http://dlang.org/phobos/core_time.html#.Duration, Duration) to wait before calling onTimer.
	*/
	void start(const Duration waitTime)
	{
		waitTime_ = waitTime;

		if(!onCountdownFinished_)
		{
			onCountdownFinished_ = &onCountdownFinished;
		}

		thread_.start();
	}

	/**
		Sets a callback to a function instead of having to inherit from class.

		Params:
			callBackName = Name of the callback to use(valid values are: onTimer, onTimerStart or onTimerStop).
			callback = The function to be called. Function must take no arguments and have void return type.
	*/
	void setCallBack(T)(const string callBackName, T callback)
	{
		VoidDelegate voidCall;

		static if(!isDelegate!T)
		{
			import std.functional : toDelegate;
			voidCall = toDelegate(callback);
		}
		else
		{
			voidCall = callback;
		}

		final switch(callBackName)
		{
			case "onCountdownFinished":
				onCountdownFinished_ = voidCall;
				break;
		}
	}

	/**
		Called after time has elapsed set it start's waitTime parameter.
	*/
	void onCountdownFinished() {}

	/**
		Stops the timer.
	*/
	void stop()
	{
		running_ = false;
	}
private:
	/**
		Called when the timer is created.
	*/
	void run()
	{
		immutable MonoTime before = MonoTime.currTime;

		while(running_)
		{
			thread_.sleep(dur!("msecs")(10)); // Throttle so we don't take up too much CPU

			immutable MonoTime after = MonoTime.currTime;
			immutable Duration dur = after - before;

			if(dur >= waitTime_)
			{
				onCountdownFinished_();
				running_ = false;
			}
		}
	}

protected:
	/**
		Returns the name of the timer(this.toString by default).
	*/
	string name() @property
	{
		return thread_.name;
	}

	/**
		Sets the timers name.
	*/
	void name(const string name) @property
	{
		thread_.name = name;
	}

private:
	bool running_ = true;
	Thread thread_;
	Duration waitTime_;

	VoidDelegate onCountdownFinished_;
}
