/**
	Add support for creating a repeating timer.
*/
module raijin.timers;

import core.thread;
import core.time;
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
	void start(const Duration dur)
	{
		dur_ = dur;
		thread_ = new Thread(&run);
		thread_.start();
	}

	void onTimerStart()
	{
		debug writeln("Starting timer...");
	}

	void onTimer()
	{
		debug writeln(thread_.name);
	}

	void onTimerStop()
	{
		debug writeln("Stopping timer: ", thread_.name);
	}

	void stop()
	{
		running_ = false;
	}

private:
	void run()
	{
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
}
