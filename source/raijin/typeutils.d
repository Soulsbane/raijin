module raijin.typeutils;

import std.typecons : Flag;

alias AllowNumericBooleanValues = Flag!"allowNumericBooleanValues";

bool isBooleanString(immutable string value) @trusted
{
    if(value == "true" || value == "false")
    {
        return true;
    }

    return false;
}

bool isBooleanNumber(immutable string value)
{
    if(value == "1" || value == "0")
    {
        return true;
    }

    return false;
}

bool isBooleanValue(immutable string value, AllowNumericBooleanValues allowNumeric = AllowNumericBooleanValues.yes) @trusted
{
    if(value == "true" || value == "false")
    {
        return true;
    }

    if(allowNumeric && (value == "1" || value == "0"))
    {
        return true;
    }

    return false;
}
