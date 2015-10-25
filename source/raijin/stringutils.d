/**
*	This module contains a few additons to handling strings.
*
*	Author: Paul Crane
*/

module raijin.stringutils;

import std.string : indexOf, CaseSensitive;
import std.conv : to;
import std.range.primitives : empty, popFront, front;

bool find(immutable string value, immutable string toFindValue, CaseSensitive cs = CaseSensitive.no) pure @safe
{
	if(value.indexOf(toFindValue, cs) == -1)
	{
		return false;
	}
	return true;
}

string pluralize(string text, immutable uint count)
{
	string pluralizedNumber = text[0 .. $ - 1];

	if(count == 1)
	{
		pluralizedNumber = text;
	}
	else
	{
		immutable char lastChar = text[$ - 1];

		if(lastChar == 'y')
		{
			pluralizedNumber = text[0 .. $ - 1];
			pluralizedNumber = pluralizedNumber ~ "ies";
		}
		else
		{
			pluralizedNumber = text ~ "s";
		}
	}

	return pluralizedNumber;
}

// INFO: Surely there is a phobos function to do this but I couldn't find it.
string removeLeadingChars(string str, dchar charToRemove) @trusted
{
    while (!str.empty)
    {
        auto c = str.front;

        if (c != charToRemove)
		{
            break;
		}

        str.popFront();
    }
    return str;
}
