/**
	A simple module that handles user input on the command line.
*/
module raijin.cmdline;

import std.stdio;
import std.string;
import std.typecons;
import std.range;

alias ShowPrompt = Flag!"showPrompt";
enum DEFAULT_COMMANDS_COUNT = 3;

/**
	Manages a loop which processes commands via command line input.

	Examples:
		--------------------
		class MyCommand : CommandProcessor
		{
			// All on<name> commands can be overriden.
			override void onCommand(const string command)
			{

				// Will only print "test" since it is the only command registered.
				writeln("inherited onCommand: ", command);
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
	}

	/**
		Recieves commands sent from processCommands

		Params:
			command = The command that was sent
	*/
	void onCommand(const string command)
	{
		debug writeln("Received command: ", command);
	}

	/**
		Called by processCommands before commands are handled.
	*/
	void onExitProcessCommands()
	{
		debug writeln("Exiting commmand processing loop!");
	}

	/**
		Called by processCommands after commands are handled.
	*/
	void onEnterProcessCommands()
	{
		debug writeln("Entering commmand processing loop!");
	}

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
		onEnterProcessCommands();

		while(keepProcessing_)
		{
			if(showPrompt)
			{
				write(promptMsg);
			}

			string command = readln.strip;
			switch(command)
			{
				case "exit", "quit":
					quit();
					break;
				case "list":
					onListCommands();
					break;

				default:
					if(validCommands_.length > DEFAULT_COMMANDS_COUNT) // If there are valid commands in the array the user wants to check if they are valid
					{
						if(isValidCommand(command))
						{
							onCommand(command);
						}
						else
						{
							writeln("Invalid command!");
						}
					}
					else
					{
						onCommand(command);
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
	final bool isValidCommand(const string command)
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
	void addCommand(const string command, const string description)
	{
		validCommands_[command] = description;

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
	string[string] validCommands_;
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
