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

		void process(ShowPrompt showPrompt = ShowPrompt.yes, string promptMsg = "Enter Command>")
		{
			while(keepProcessing)
			{
				if(showPrompt)
				{
					write(promptMsg);
				}

				string command = readln;

				switch(command.strip)
				{
					case "exit":
						keepProcessing = false;
						break;
					default:
						onCommand(command.strip);
				}
			}

			onExitProcessCommands();
		}

		final void quit() pure @safe
		{
			keepProcessing = false;
		}


private:
	bool keepProcessing = true;
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
