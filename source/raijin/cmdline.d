/**
	A simple module that handles user input on the command line.
*/
module raijin.cmdline;

import std.stdio;
import std.string;
import std.typecons;
import std.range;

alias ShowPrompt = Flag!"showPrompt";

class CommandProcessor
{
public:
		this()
		{
			// Start up handler for processing before loop starts.
		}

		void onCommand(const string command)
		{
			debug writeln("Received command: ", command);
		}

		void onExitProcessCommands()
		{
			debug writeln("Exiting commmand processing loop!");
		}

		void onEnterProcessCommands()
		{
			debug writeln("Entering commmand processing loop!");
		}

		void onListCommands()
		{
			writeln("Commands:");
			foreach(validCommand; validCommands_)
			{
				writeln("\t", validCommand);
			}
		}

		void processCommands(ShowPrompt showPrompt = ShowPrompt.yes, string promptMsg = "Enter Command>")
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
					case "exit":
						quit();
						break;
					case "list":
						onListCommands();
						break;

					default:
						if(validCommands_.length) // If there are valid commands in the array the user wants to check if they are valid
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

		final bool isValidCommand(const string command)
		{
			foreach(validCommand; validCommands_)
			{
				if(validCommand == command)
				{
					return true;
				}
			}

			return false;
		}

		void addCommand(const string command)
		{
			validCommands_ ~= command;
		}

		final void quit() pure @safe
		{
			keepProcessing_ = false;
		}

private:
	bool keepProcessing_ = true;
	string[] validCommands_;
}

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
