/**
	A simple module that handles user input on the command line.
*/
module raijin.cmdline;

import std.stdio;
import std.string;
import std.typecons;

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

		void process(ShowPrompt showPrompt = ShowPrompt.yes)
		{
			while(keepProcessing)
			{
				if(showPrompt)
				{
					write("Enter Command>");
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
