/**
*	This module contains a few additons to handling strings.
*
*	Author: Paul Crane
*/

module raijin.stringutils;

import std.string : indexOf;

bool find(immutable string value, immutable string toFindValue) pure @safe
{
	if(value.indexOf(toFindValue) == -1)
	{
		return false;
	}
	return true;
}

