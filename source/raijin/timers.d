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
		class MyRepeatingTimer : RepeatingTimer
		{
			override void onTimer()
			{
				writeln("MyRepeatingTimer");
			}
		}

		auto delay = dur!("seconds")(1);

		auto myTimer = new MyRepeatingTimer;
		myTimer.start(delay);
		--------------------------------------
*/
class RepeatingTimer
{
	this()
	{
		thread_ = new Thread(&run);
		thread_.name = this.toString.chompPrefix("app.");
	}

	void start(const Duration dur = dur!("seconds")(1), const Duration initialDelay = dur!("seconds")(0))
	{
		dur_ = dur;
		initialDelay_ = initialDelay;

		thread_.start();
	}

	void onTimerStart()
	{
		debug writeln("Starting timer:", name);
	}

	void onTimer()
	{
		debug writeln(name);
	}

	void onTimerStop()
	{
		debug writeln("Stopping timer: ", name);
	}

	void stop()
	{
		running_ = false;
	}

protected:
	string name() @property
	{
		return thread_.name;
	}

	void name(const string name) @property
	{
		thread_.name = name;
	}

private:
	void run()
	{
		if(initialDelay_ != seconds(0))
		{
			thread_.sleep(initialDelay_);
		}

		onTimerStart();

		while(running_)
		{
			onTimer();
			thread_.sleep(dur_);
		}

		onTimerStop();
	}

private:
	bool running_ = true;
	Thread thread_;
	Duration dur_;
	Duration initialDelay_;
}

class CountdownTimer
{
	this()
	{
		thread_ = new Thread(&run);
		thread_.name = this.toString.chompPrefix("app.");
	}

	void start(const Duration waitTime)
	{
		waitTime_ = waitTime;
		thread_.start();
	}

	void onCountdownFinished()
	{
		debug writeln("Countdown finished: ", name);
	}

private:
	void run()
	{
		thread_.sleep(waitTime_);
		onCountdownFinished();
	}

protected:
	string name() @property
	{
		return thread_.name;
	}

	void name(const string name) @property
	{
		thread_.name = name;
	}

private:
	Thread thread_;
	Duration waitTime_;
}
