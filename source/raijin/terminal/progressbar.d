/**
	Module for creating a progressbar in the terminal.
*/
module raijin.terminal.progressbar;

import std.stdio;
import std.math;
import std.conv;
import std.range;

struct ProgressBar
{
	void create(const size_t total, const string prefix = "Progress", const string suffix = "Complete",
		const size_t barLength = 100)
	{
		total_ = total;
		prefix_ = prefix;
		suffix_ = suffix;
		barLength_ = barLength;

		update(0);
	}

	void update(size_t iteration)
	{
		immutable auto filledLength = to!size_t(round(barLength_ * iteration / to!float(total_)));
		immutable auto percents = round(100.00 * (iteration / to!float(total_)));
		immutable auto bar = to!string('█'.repeat(filledLength)) ~ to!string('░'.repeat(barLength_ - filledLength));

		writef("\r%s %s %s%s %s", prefix_, bar, percents, '%', suffix_);
		stdout.flush;

		if(iteration == total_)
		{
			writeln;
			stdout.flush();
		}
	}
private:
	size_t total_;
	size_t barLength_;
	string prefix_;
	string suffix_;
}
