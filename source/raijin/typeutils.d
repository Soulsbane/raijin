module raijin.typeutils;

import std.typecons : Flag;

alias AllowNumericBooleanValues = Flag!"allowNumericBooleanValues";

bool isStringABool(immutable string value) @trusted
{
    return(value == "true" || value == "false");
}

bool isNumberABool(immutable string value) @trusted
{
    return(value == "1" || value == "0");
}

bool isNumberABool(immutable int value) @trusted
{
    return(value == 1 || value == 0);
}

bool isBoolean(immutable string value)
{
    return (isStringABool(value) || isNumberABool(value));
}
