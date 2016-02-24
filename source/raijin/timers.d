/**
	Add support for creating a repeating timer.
*/
module raijin.timers;

import core.thread;
import core.time;
import std.string;
debug import std.stdio;

alias dur = core.time.dur; // Avoids having to import core.time in the user's program.

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

		thread_.start();
	}

	/**
		Called when the timer starts.
	*/
	void onTimerStart()
	{
		debug writeln("Starting timer:", name);
	}

	/**
		Called each every Duration specified.
	*/
	void onTimer()
	{
		debug writeln(name);
	}

	/**
		Called when the timer stops.
	*/
	void onTimerStop()
	{
		debug writeln("Stopping timer: ", name);
	}

	/**
		Stops the timer.
	*/
	void stop()
	{
		running_ = false;
	}

protected:
	/**
		Returns the name of the thread(this.toString by default).
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
		Called when thread is created.
	*/
	void run()
	{
		if(initialDelay_ != seconds(0))
		{
			thread_.sleep(initialDelay_);
		}

		onTimerStart();

		MonoTime before = MonoTime.currTime;

		while(running_)
		{
			thread_.sleep(dur!("msecs")(10)); // Throttle so we don't take up too much CPU

			MonoTime after = MonoTime.currTime;
			Duration dur = after - before;

			if(dur >= dur_)
			{
				onTimer();

				before = MonoTime.currTime;
				after = MonoTime.currTime;
			}
		}

		onTimerStop();
	}

private:
	bool running_ = true;
	Thread thread_;
	Duration dur_;
	Duration initialDelay_;
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
		thread_.start();
	}

	/**
		Called after time has elapsed set it start's waitTime parameter.
	*/
	void onCountdownFinished()
	{
		debug writeln("Countdown finished: ", name);
	}

private:
	/**
		Called when thread is created.
	*/
	void run()
	{
		MonoTime before = MonoTime.currTime;

		while(running_)
		{
			thread_.sleep(dur!("msecs")(10)); // Throttle so we don't take up too much CPU

			MonoTime after = MonoTime.currTime;
			Duration dur = after - before;

			if(dur >= waitTime_)
			{
				onCountdownFinished();
				running_ = false;
			}
		}
	}

protected:
	/**
		Returns the name of the thread(this.toString by default).
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
	bool running_ = true;
	Thread thread_;
	Duration waitTime_;
}
