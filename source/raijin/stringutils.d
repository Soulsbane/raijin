/**
*	This module contains a few additons to handling strings.
*
*	Author: Paul Crane
*/

module raijin.stringutils;

import std.string : indexOf;
import std.conv : to;

bool find(immutable string value, immutable string toFindValue) pure @safe
{
	if(value.indexOf(toFindValue) == -1)
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
		dchar lastChar = text[$ - 1];

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
