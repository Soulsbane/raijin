/**
*	This module contains a few additons to handling strings.
*
*	Author: Paul Crane
*/

module raijin.stringutils;

import std.string : indexOf, CaseSensitive;
import std.conv : to;

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
		pluralizedNumber = "1 " ~ text;
	}
	else
	{
		char lastChar = text[$ - 1];

		if(lastChar == 'y')
		{
			pluralizedNumber = text[0 .. $ - 1];
			pluralizedNumber = to!string(count) ~" " ~ pluralizedNumber ~ "ies";
		}
		else
		{
			pluralizedNumber = to!string(count) ~" " ~ text ~ "s";
		}
	}

	return pluralizedNumber;
}
