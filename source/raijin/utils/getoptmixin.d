module raijin.utils.getoptmixin;

import std.getopt;
import std.traits;
import std.stdio;

///The attribute used for marking members
struct GetOptDescription
{
	string value;
}

//FIXME: According to what I've read only the enum <name> part is needed; but it fails unless it's assigned a value.
enum GetOptRequired = "GetOptRequireds";

mixin template GetOptMixin(T)
{
	/*
		Using the example struct below this string mixin generates this code.

		struct VariedData
		{
			@GetOptDescription("The name of the program")
			string name;
			@GetOptDescription("The id of the program")
			size_t id;
		}

		//The actual generated string.
		auto helpInformation = getopt(arguments, "name", "The name of the program",
			&options.name, "id", "The id of the program", &options.id);
	*/

	string wrapped()
	{
		//string getOptCode = "auto helpInformation = getopt(arguments, std.getopt.config.passThrough, ";
		string getOptCode = "auto helpInformation = getopt(arguments,";

		foreach(field; __traits(allMembers, T))
		{
			auto memAttrs = __traits(getAttributes, mixin("options." ~ field));

			foreach(attr; memAttrs)
			{
				static if(is(typeof(attr) == GetOptDescription))
				{
					static if(hasUDA!(mixin("options." ~ field), GetOptRequired))
					{
						getOptCode = getOptCode ~ "std.getopt.config.required," ~ "\"" ~ field ~ "\", \"" ~  attr.value ~ "\", &options." ~ field ~ ", ";
					}
					else
					{
						getOptCode = getOptCode ~ "\"" ~ field ~ "\", \"" ~  attr.value ~ "\", &options." ~ field ~ ", ";
					}
				}
			}
		}

		getOptCode = getOptCode[0..$ - 2] ~ ");"; // Remove the extra , and space
		return getOptCode;
	}

	mixin(wrapped);
}

/**
	Generates generic code for use in std.getopt.

	Params:
		arguments = The arguments sent from the command-line
		options = The struct that will be used to generate getopt options from.

	Examples:
		import std.stdio;

		struct VariedData
		{
			//Sets the description in --help for command and makes this command a std.getopt.command.required argument.
			@GetOptDescription("The name of the program") @GetOptRequired
			string name;
			@GetOptDescription("The id of the program")
			size_t id;
		}

		void main(string[] arguments)
		{
			VariedData data;

			data.name = "Paul Crane";
			data.id = 13;
			insertGetOptCode!VariedData(arguments, data);

			writeln("after data.id => ", data.id);
		}
*/
void insertGetOptCode(T)(string[] arguments, ref T options)
{
	try
	{
		mixin GetOptMixin!T;

		if(helpInformation.helpWanted)
		{
			defaultGetoptPrinter("The following options are available:",
			helpInformation.options);
		}
	}
	catch(GetOptException ex)
	{
		writeln(ex.msg);
	}
}
