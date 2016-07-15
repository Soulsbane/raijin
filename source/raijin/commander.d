module raijin.commander;

import std.stdio;

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

		private bool processHelp(alias member)(string memberName, string[] args)
		{
			bool helpOptionFound;

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
					helpOptionFound = true;
				}
			}
			else
			{
				writefln("%16s -- %s", memberName, getAttribute!(member, CommandHelp).value);
				helpOptionFound = true;
			}

			return helpOptionFound;
		}

		private bool processCommand(alias member)(string[] args)
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
						arg = to!(typeof(arg))(args[idx]); //FIXME:  Need to catch exception that could be thrown here.
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
				{
					writeln(to!string(member(params)));
				}

				return true;
			}
			catch(Exception e)
			{
				stderr.writefln(e.msg);
				return false;
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
		bool process()(string[] arguments)
		{
			string name;
			string[] args = arguments[1 .. $];
			bool helpOptionFound;
			bool commandFound;
			string invalidHelpOption;

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
					if(name == "--help")
					{
						if(args.length)
						{
							if(memberName == args[0])
							{
								helpOptionFound = processHelp!member(memberName, args);
							}
						}
						else
						{
							helpOptionFound = processHelp!member(memberName, args);
						}
					}
					else if(memberName == name)
					{
						commandFound = processCommand!member(args);
					}
				}
			}

			if(commandFound && helpOptionFound)
			{
				return true;
			}
			else
			{
				if(!helpOptionFound && args.length)
				{
					return false;
				}

				if(!commandFound && arguments.length)
				{
					return false;
				}
			}

			return true;
		}
	}
}
