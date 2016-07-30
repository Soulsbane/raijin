module raijin.commander;

import std.stdio;
import std.string;

struct CommandHelp
{
	string value;
	string[] argDocs;
}

mixin template Commander(string modName = __MODULE__)
{
	import std.traits, std.conv, std.stdio;
	/**
		Handles commands sent via the commandline.

		Examples:
			void create(const string language, generator)
			{
				DoStuff(language, generator);
			}

			void main(string[] arguments)
			{
				mixin Commander;
				Commander commands;
				commands.process(arguments);
			}

			prompt>skeletor create d raijin
	*/
	struct Commander
	{
		alias helper(alias T) = T;

		private auto getAttribute(alias mem, T)()
		{
			foreach(attr; __traits(getAttributes, mem))
			{
				static if(is(typeof(attr) == T))
				{
					return attr;
				}
			}
		}

		private void processHelp(alias member)(string memberName, string[] args)
		{
			if(args.length)
			{
				if(memberName == args[0])
				{
					writef("Usage: %s", memberName);

					foreach(argName; ParameterIdentifierTuple!member)
					{
						writef(" %s", argName);
					}

					writefln("\n\t%s", getAttribute!(member, CommandHelp).value);

					if(ParameterTypeTuple!member.length)
					{
						writeln("Arguments:");
					}

					auto argDocs = getAttribute!(member, CommandHelp).argDocs;

					foreach(idx, argName; ParameterIdentifierTuple!member)
					{
						string defaultValue;
						bool hasDefaultValue;

						static if(!is(ParameterDefaultValueTuple!member[idx] == void))
						{
							defaultValue = to!string(ParameterDefaultValueTuple!member[idx]);
							hasDefaultValue = true;
						}

						string argDoc;

						if(idx < argDocs.length)
						{
							argDoc = argDocs[idx];
						}

						if(argDoc.length)
						{
							writefln("\t%s (%s): %s %s", argName, ParameterTypeTuple!member[idx].stringof, argDoc,
								hasDefaultValue ? "[default=" ~ defaultValue ~ "]" : "");
						}
						else
						{
							writefln("\t%s (%s) %s", argName, ParameterTypeTuple!member[idx].stringof,
								hasDefaultValue ? ": [default=" ~ defaultValue ~ "]" : "");
						}
					}
				}
			}
			else
			{
				writefln("%16s - %s", memberName, getAttribute!(member, CommandHelp).value);
			}
		}

		private void processCommand(alias member)(string memberName, string[] args)
		{
			ParameterTypeTuple!member params;
			alias argumentNames = ParameterIdentifierTuple!member;
			alias defaultArguments = ParameterDefaultValueTuple!member;

			try
			{
				foreach(idx, ref arg; params)
				{
					if(idx < args.length)
					{
						try
						{
							arg = to!(typeof(arg))(args[idx]);
						}
						catch(ConvException ex)
						{
							writeln(ex.msg);
							writeln("See --help ", memberName, " for correct usage.");
						}
					}
					else static if(!is(defaultArguments[idx] == void))
					{
						arg = defaultArguments[idx];
					}
					else
					{
						throw new Exception("Required argument, " ~ argumentNames[idx] ~ "(" ~ typeof(arg).stringof ~ ")," ~ " is missing.");
					}
				}

				static if(is(ReturnType!member == void))
				{
					member(params);
				}
				else
				{ //TODO:  Perhaps Add support for returning the result later.
					debug writeln(to!string(member(params)));
				}
			}
			catch(Exception e)
			{
				stderr.writefln(e.msg);
			}
		}

		/**
			Handles processing of commands sent from the commandline.

			Params:
				arguments = The arguments sent from the commandline.

			Returns:
				A true value if command/helpoption was found and its required arguments were found. Note that no
				arguments will also return a true value and should be checked in user's program. False otherwise.
		*/
		void process()(string[] arguments)
		{
			string name;
			string[] args = arguments[1 .. $];
			bool headerShown;

			if(args.length)
			{
				name = args[0];
				args = args[1 .. $];
			}

			alias mod = helper!(mixin(modName));

			foreach(memberName; __traits(allMembers, mod))
			{
				alias member = helper!(__traits(getMember, mod, memberName));

				static if(is(typeof(member) == function) && hasUDA!(member, CommandHelp))
				{
					if(name.removechars("-") == "help")
					{
						if(args.length)
						{
							if(memberName == args[0])
							{
								processHelp!member(memberName, args);
							}
						}
						else
						{
							if(!headerShown)
							{
								writeln("The following options are available:");
								writeln("For additional help for a command use help <command>.");
								writeln;
							}

							processHelp!member(memberName, args);
							headerShown = true;
						}
					}
					else if(memberName == name)
					{
						processCommand!member(memberName, args);
					}
				}
			}
		}
	}
}
