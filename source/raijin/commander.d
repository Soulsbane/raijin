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

		auto getAttribute(alias mem, T)()
		{
			foreach(attr; __traits(getAttributes, mem))
			{
				static if(is(typeof(attr) == T))
				{
					return attr;
				}
			}
		}

		void processHelp(alias member)(string memberName, string[] args)
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
				writefln("%16s -- %s", memberName, getAttribute!(member, CommandHelp).value);
			}
		}

		bool processCommand(alias member)(string[] args)
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
				A true value is command was found and it's required arguments were found. False otherwise.
		*/
		bool process()(string[] arguments)
		{
			string name;
			string[] args = arguments[1 .. $];

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
						processHelp!member(memberName, args);
					}
					else if(memberName == name)
					{
						return processCommand!member(args);
					}
				}
			}

			return true;
		}
	}
}
