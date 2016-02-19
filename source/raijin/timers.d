/**
	Add support for creating a repeating timer.
*/
module raijin.timers;

import core.thread;
import std.datetime;
debug import std.stdio;

class RepeatingTimer
{
	// Only used for testing will be removed in the future
	void setTimerName(const string name)
	{
		timerName_ = name;
	}

	void start(const Duration dur)
	{
		dur_ = dur;
		thread_ = new Thread(&run);
		thread_.start();
	}

	void onTimer()
	{
		debug writeln(timerName_);
	}

private:
	void run()
	{
		while(running_)
		{
			onTimer();
			thread_.sleep(dur_);
		}
	}
private:
	string timerName_;
	bool running_ = true;
	Thread thread_;
	Duration dur_;
}
