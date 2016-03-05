/**
	A simple module that handles user input on the command line.
*/
module raijin.cmdline;

import std.stdio;
import std.string;
import std.typecons;
import std.range;
import core.thread;

alias ShowPrompt = Flag!"showPrompt";

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
		addCommand("list", "Lists all available commands.");
		addCommand("exit", "Exits the program.");
		addCommand("quit", "Exits the program.");

		defaultCommandsCount_ = validCommands_.length;
	}

	/**
		Recieves commands sent from processCommands

		Params:
			command = The command that was sent
	*/
	abstract void onCommand(const string command, const string[] args);

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
		writeln("Commands:");

		foreach(validCommand, description; validCommands_)
		{
			writeln("\t", validCommand, " - ", description);
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

		thread_ = new Thread(&run);
		thread_.start();
	}

	private void run()
	{
		onEnterProcessCommands();

		while(keepProcessing_)
		{
			if(showPrompt_)
			{
				write(promptMsg_);
			}

			immutable string input = readln.strip;
			immutable string[] commands = input.split(' ');
			immutable string command = commands[0];
			immutable string[] args = commands[1..$];

			if(command == "exit" && isValidCommand("exit")) // Make sure one of the default commands weren't removed before calling quit.
			{
				quit();
			}
			else if(command == "quit" && isValidCommand("quit"))
			{
				quit();
			}
			else if(command == "list" && isValidCommand("list"))
			{
				onListCommands();
			}
			else
			{
				if(validCommands_.length > defaultCommandsCount_) // If length is greater the user added a command so process it.
				{
					if(isValidCommand(command))
					{
						onCommand(command, args);
					}
					else
					{
						writeln("Invalid command!");
					}
				}
				else
				{
					onCommand(command, args);
				}
			}
		}

		onExitProcessCommands();
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

private:
	bool keepProcessing_ = true;
	string promptMsg_;
	ShowPrompt showPrompt_;
	string[string] validCommands_;
	size_t defaultCommandsCount_;
	Thread thread_;
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
	auto answer = readln();

	if(answer.front == 'Y' || answer.front == 'y')
	{
		return true;
	}

	return false;
}
