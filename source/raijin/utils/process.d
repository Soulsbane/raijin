/**
	Small wrapper functions for std.process functions.

	Authors:
		Paul Crane
*/
module raijin.utils.process;

import std.exception : ifThrown;
import std.typecons : Tuple;
import std.process;
import std.array : join;
import std.stdio;
import core.time : dur;

import raijin.utils.path : isInPath;
import raijin.timers : RepeatingTimer;

// BUG: DMD can't infer a return type for both launchApplication functions without this.
alias LaunchApplicationReturnType = Tuple!(int, "status", string, "output");

/**
	Small wrapper function that launches an application using std.process.executeShell.

	Params:
		fileName = Name of the application to launch.
		args = The arguments to the program.

	Returns:
		Returns the same tuple as $(LINK2 http://dlang.org/phobos/std_process.html#executeShell, std.process.executeShell)
*/
LaunchApplicationReturnType  launchApplication(const string fileName, const string[] args...) @safe
{
	return launchApplication(fileName, args.join(' '));
}

/**
	Small wrapper function that launches an application using std.process.executeShell.

	Params:
		fileName = Name of the application to launch.
		args = The arguments to the program.

	Returns:
		Returns the same tuple as $(LINK2 http://dlang.org/phobos/std_process.html#executeShell, std.process.executeShell)
*/
LaunchApplicationReturnType launchApplication(const string fileName, const string args) @safe
{
	import std.file : exists;

	auto result = Tuple!(int, "status", string, "output")(127, "Executable not found.");
	immutable auto inPath = isInPath(fileName);
	immutable string fileNameAndArgs = fileName ~ ' ' ~ args;

	if(fileName.exists)
	{
		return executeShell(fileNameAndArgs).ifThrown!Exception(result);
	}
	else if(inPath.length)
	{
		return executeShell(fileNameAndArgs).ifThrown!Exception(result);
	}
	else
	{
		return result;
	}
}

///
unittest
{
	version(linux)
	{
		immutable auto result = launchApplication("ls", "-l -h");
		assert(result.status == 0);

		immutable auto result2 = launchApplication("ls", "-l", "-h");
		assert(result2.status == 0);

		immutable auto errorResult = launchApplication("ls2lss", "-l -h");
		assert(errorResult.status == 127);

		immutable auto errorResult2 = launchApplication("ls2lss", "-l", "-h");
		assert(errorResult2.status == 127);

		import raijin.utils.file: ensureFileExists, removeFileIfExists;

		ensureFileExists("myprocessapp");
		immutable auto fileNameResult = launchApplication("./myprocessapp", "-l", "-h");
		assert(fileNameResult.status == 126);
		removeFileIfExists("myprocessapp");
	}
}

/**
	A simple wrapper around ProcessWait.

	Params:
		args = The application name followed by the arguments to pass to it.

		Returns:
			The same value as $(LINK2 http://dlang.org/phobos/std_process.html#.wait, std.process.wait).
*/
auto waitForApplication(const size_t phaseType, const string[] args...)
{
	ProcessWait process;
	auto exitStatus = process.execute(phaseType, args);

	return exitStatus;
}

///
unittest
{
	waitForApplication(0, "ls");
}

/// Provides a progress indicator while waiting for the spawned process to complete.
struct ProcessWait
{
	alias ProcessReturnType = Tuple!(bool, "terminated", int, "status");

public:

	/**
		Executes an process that will wait using a progress indicator until the process exits.

		Params:
			args = The args to pass to the process where the first argument is the process name.

		Returns:
			The same value as $(LINK2 http://dlang.org/phobos/std_process.html#.wait, std.process.wait).
	*/
	auto execute(const size_t phaseType, const string[] args...)
	{
		phases_ = phaseTypes_[phaseType];
		timer_ = new RepeatingTimer;
		timer_.setCallBack("onTimer", &onStatusUpdate);

		auto pipes = pipeProcess(args);

		hideCursor();
		timer_.start(dur!("msecs")(500));

		auto exitStatus = wait(pipes.pid);

		timer_.stop();

		clearLine();
		showCursor();
		writeln;

		return exitStatus;
	}

private:
	void onStatusUpdate()
	{
		if(tickCount_ == phases_.length)
		{
			clearLine();
			tickCount_ = 0;
		}

		clearLine();
		write(phases_[tickCount_]);
		stdout.flush();

		++tickCount_;
	}

	void showCursor()
	{
		write(SHOW_CURSOR);
	}

	void hideCursor()
	{
		write(HIDE_CURSOR);
	}

	void clearLine()
	{
		write("\x1B[2K");
		write("\r");
	}

private:
	string[] phases_;
	RepeatingTimer timer_;
	size_t tickCount_;

	string[][] phaseTypes_ =
	[
		["◑", "◒", "◐", "◓"],
		["○", "◔", "◑", "◕", "●"],
		["-", "\\", "|", "/"],
		["◷", "◶", "◵", "◴"],
		["⎻", "⎼", "⎽", "⎼", "⎻"],
		["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
	];

	immutable SHOW_CURSOR = "\x1b[?25h";
	immutable HIDE_CURSOR = "\x1b[?25l";
}
