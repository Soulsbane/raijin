/**
	A simple module that handles user input on the command line.

	Authors:
		Paul Crane
*/
module raijin.cmdline;

import std.stdio;
import std.string;
import std.typecons;
import std.range;
import core.thread;

import raijin.types.callbacks;

alias ShowPrompt = Flag!"showPrompt";

private
{
	alias OnCommandDelegate = void delegate(const string command, const string[] args);
	alias VoidDelegate = void delegate();
	alias OnInvalidCommandDelegate = void delegate(const string command);
}

/**
	Manages a loop which processes commands via command line input.

	Examples:
		--------------------
		class MyCommand : CommandProcessor
		{
			// All on<name> commands can be overriden.
			override void onCommand(const string command, const string[] args)
			{
				// Will only print "test" since it is the only command registered.
				writeln("Command: ", command, " Args: ", args);
			}
		}

		auto cmd = new MyCommand;

		cmd.addCommand("test", "this is a test");
		cmd.processCommands();
		--------------------
*/
class CommandProcessor
{
public:
	this()
	{
		addCommand("clear", "Clear screen of output and display command prompt.");
		addCommand("list", "Lists all available commands.");
		addCommand("exit", "Exits the program.");
		addCommand("quit", "Exits the program.");

		defaultCommandsCount_ = validCommands_.length;

		setCallback("onCommand", &onCommand);
		setCallback("onInvalidCommand", &onInvalidCommand);
		setCallback("onEnterProcessCommands", &onEnterProcessCommands);
		setCallback("onExitProcessCommands", &onExitProcessCommands);

	}

	/**
		Receives commands sent from processCommands

		Params:
			command = The command that was sent
			args = Additional arguments sent with command.
	*/
	void onCommand(const string command, const string[] args) {}

	/**
		Called by processCommands before commands are handled.
	*/
	void onExitProcessCommands() {}

	/**
		Called by processCommands after commands are handled.
	*/
	void onEnterProcessCommands() {}

	/**
		Called by processCommands when the "list" command is sent.
	*/
	void onListCommands()
	{
		import std.algorithm : sort, each;
		auto keys = sort(validCommands_.keys);

		writeln("Commands:");
		keys.each!((key) => writeln("\t", key, " - ", validCommands_[key]));
	}

	/**
		Called by processCommands when an invalid command is sent.
	*/
	void onInvalidCommand(const string command)
	{
		writeln("Invalid command '", command, "'. Use 'list' for a list of valid commands.\n");
	}

	/**
		Sets a callback to a function instead of having to inherit from class.

		Params:
			name = Name of the callback to use(valid values are: onTimer, onTimerStart or onTimerStop).
			callback = The function to be called. Function must take no arguments and have void return type.
	*/
	void setCallback(const string name, VoidDelegate callback)
	{
		final switch(name)
		{
			case "onExitProcessCommands":
				onExitProcessCommands_ = callback;
				break;
			case "onEnterProcessCommands":
				onEnterProcessCommands_ = callback;
				break;
		}
	}

	/**
		Sets a callback to a function instead of having to inherit from class.

		Params:
			name = Name of the callback to use(valid values are: onTimer, onTimerStart or onTimerStop).
			callback = The function to be called. Function must take no arguments and have void return type.
	*/
	void setCallback(const string name, OnCommandDelegate callback)
	{
		final switch(name)
		{
			case "onCommand":
				onCommand_ = callback;
				break;
		}
	}

	/**
		Sets a callback to a function instead of having to inherit from class.

		Params:
			name = Name of the callback to use(valid values are: onTimer, onTimerStart or onTimerStop).
			callback = The function to be called. Function must take no arguments and have void return type.
	*/
	void setCallback(const string name, OnInvalidCommandDelegate callback)
	{
		final switch(name)
		{
			case "onInvalidCommand":
				onInvalidCommand_ = callback;
				break;
		}
	}

	/**
		Processes commands sent via the command line.

		Params:
			showPrompt = Set to yes to show a prompt(A message saying Enter Command> by default). Set to no to ignore prompt.
			promptMsg = The message to print if showPrompt is enabled.
	*/
	final void processCommands(ShowPrompt showPrompt = ShowPrompt.yes, string promptMsg = "Enter Command>")
	{
		showPrompt_ = showPrompt;
		promptMsg_ = promptMsg;

		//validateCallbacks();

		thread_ = new Thread(&run);
		thread_.start();
	}

	private void run()
	{
		onEnterProcessCommands_();

		while(keepProcessing_)
		{
			if(showPrompt_)
			{
				write(promptMsg_);
			}

			immutable string[] commands = readln.strip.split(' ');
			immutable string command = commands[0];
			immutable string[] args = commands[1..$];

			if(isValidCommand(command))
			{
				switch(command)
				{
					case "exit", "quit":
						quit();
						break;
					case "list":
						onListCommands();
						break;
					case "clear":
						clear();
						break;
					default:
						if(validCommands_.length > defaultCommandsCount_) // If length is greater the user added a command so process it.
						{
							onCommand_(command, args);
						}

						break;
				}
			}
			else
			{
				onInvalidCommand_(command);
			}

			thread_.sleep(dur!("msecs")(10)); // Throttle so we don't take up too much CPU
		}

		onExitProcessCommands_();
	}
	/**
		Determines if a command is valid(added via addCommand).

		Params:
			command = The command to check for.
	*/
	final bool isValidCommand(const string command) pure @safe
	{
		foreach(validCommand, description; validCommands_)
		{
			if(validCommand == command)
			{
				return true;
			}
		}

		return false;
	}

	/**
		Adds a command that should be processed.

		Params:
			command = The command to add.
			description = A description of what the command does.
	*/
	void addCommand(const string command, const string description)// pure @safe
	{
		validCommands_[command] = description;
	}

	void removeCommand(const string command)
	{
		validCommands_.remove(command);
	}

	/**
		Called by processCommands when the "exit" command is sent.
	*/
	final void quit() pure @safe
	{
		keepProcessing_ = false;
	}

	/**
		Helper property for accessing whether the prompt is set to be shown.

		Returns:
			true if the prompt will show false otherwise.
	*/
	bool showPrompt() @property const
	{
		return showPrompt_;
	}

private:
	bool keepProcessing_ = true;
	string promptMsg_;
	ShowPrompt showPrompt_;
	string[string] validCommands_;
	size_t defaultCommandsCount_;
	Thread thread_;

	Callback!OnCommandDelegate onCommand_;
	Callback!OnInvalidCommandDelegate onInvalidCommand_;
	Callback!VoidDelegate onEnterProcessCommands_;
	Callback!VoidDelegate  onExitProcessCommands_;
}

/**
	Pauses the program until the enter key is pressed

	Params:
		msg = The message to display.
*/
void pause(const string msg = "Press enter/return to continue...")
{
	write(msg);
	getchar();
}

/**
	Clears the terminal of all output.
*/
void clear()
{
	version(linux)
	{
		write("\x1B[2J\x1B[H");
	}

	version(windows)
	{
		// call cls
	}
}

/**
	Display a prompt that contains a yes(Y/y) or no instruction.
*/
bool confirmationPrompt(string msg = "Do you wish to continue(y/n): ")
{
	write(msg);
	immutable auto answer = readln();

	if(answer.front == 'Y' || answer.front == 'y')
	{
		return true;
	}

	return false;
}
