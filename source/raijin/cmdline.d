/**
	A simple module that handles user input on the command line.
*/
module raijin.cmdline;

import std.stdio;
import std.string;

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

		void process()
		{
			while(keepProcessing)
			{
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

		void quit()
		{
			keepProcessing = false;
		}
private:
	bool keepProcessing = true;
}
