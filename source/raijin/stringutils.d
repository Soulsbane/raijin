/**
*	This module contains a few additons to handling strings.
*
*	Author: Paul Crane
*/

module raijin.stringutils;

import std.string : indexOf, CaseSensitive;
import std.conv : to;
import std.range.primitives : empty, popFront, front;

/**
*	Determines if a string has the value specified
*
*	Params:
*		value = The string to search.
*		toFindValue = The value to find.
*		cs = Set whether the search term is case sensitive. CaseSensitive.yes or CaseSensitive.no
*
*	Returns:
*		True if the toFindValue is found false otherwise.
*/
bool find(immutable string value, immutable string toFindValue, CaseSensitive cs = CaseSensitive.no) pure @safe
{
	if(value.indexOf(toFindValue, cs) == -1)
	{
		return false;
	}
	return true;
}

/**
*	Pluralizes a string.
*
*	Params:
*		text = The word to pluralize.
*		count = The number of words.
*
*	Returns:
*		The pluralized string if more than one of type or singular form otherwise.
*/
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

/**
*	Removes the charactor from the beginning of a string.
*
*	Params:
*		str = The string to remove characters from.
*		charToRemove = The character to remove.

*	Returns:
*		The modified string with all characters to be removed are removed.
*/
string removeLeadingChars(string str, dchar charToRemove) @trusted
{
	// INFO: Surely there is a phobos function to do this but I couldn't find it.
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

unittest
{
	assert("--help".removeLeadingChars('-') == "help");
	assert("--help-me".removeLeadingChars('-') == "help-me");
	assert("fly".pluralize(10) == "flies");
	assert("fly".pluralize(1) == "fly");
	assert("book".pluralize(10) == "books");
	assert("book".pluralize(1) == "book");
	assert("Hello World".find("Hello") == true);
	assert("Hello World".find("hello") == true);
	assert("Hello World".find("hello", CaseSensitive.yes) == false);
}
