/**
*   Various functions to determine types at runtime.
*/

module raijin.typeutils;

import std.typecons : Flag;

alias AllowNumericBooleanValues = Flag!"allowNumericBooleanValues";

/**
*   Determines if a string is a boolean value using true and false as qualifiers.
*
*   Params:
*       value = string to use.
*
*   Returns:
*       true if the value is a boolean false otherwise.
*/

bool isStringABool(immutable string value) @trusted
{
    return(value == "true" || value == "false");
}

/**
*   Determines if a string is a boolean value using "1" and "0" as qualifiers.
*
*   Params:
*       value = number string to use.
*
*   Returns:
*       true if the value is a boolean false otherwise.
*/
bool isNumberABool(immutable string value) @trusted
{
    return(value == "1" || value == "0");
}

/**
*   Determines if a string is a boolean value using 1 and 0 as qualifiers.
*
*   Params:
*       value = number to use.
*
*   Returns:
*       true if the value is a boolean false otherwise.
*/
bool isNumberABool(immutable int value) @trusted
{
    return(value == 1 || value == 0);
}

/**
*   Determines if a string is a boolean value using isStringABool and isNumberABool as qualifiers.
*
*   Params:
*       value = string to use.
*
*   Returns:
*       true if the value is a boolean false otherwise.
*/
bool isBoolean(immutable string value)
{
    return (isStringABool(value) || isNumberABool(value));
}
