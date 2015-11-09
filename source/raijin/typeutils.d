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

bool isBooleanString(immutable string value) @trusted
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
bool isBooleanNumber(immutable string value) @trusted
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
bool isBooleanNumber(immutable int value) @trusted
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
    return (isBooleanString(value) || isBooleanNumber(value));
}

/**
 * Same as TypeTuple, but meant to be used with values.
 *
 * Example:
 *   foreach (char channel; ValueTuple!('r', 'g', 'b'))
 *   {
 *     // the loop is unrolled at compile-time
 *     // "channel" is a compile-time value, and can be used in string mixins
 *   }
 */

 // NOTE: The following functions can be found in CyberShadows ae lib https://github.com/CyberShadow/ae/
template ValueTuple(T...)
{
    alias T ValueTuple;
}

template RangeTupleImpl(size_t N, R...)
{
    static if (N==R.length)
        alias R RangeTupleImpl;
    else
        alias RangeTupleImpl!(N, ValueTuple!(R, R.length)) RangeTupleImpl;
}

/// Generate a tuple containing integers from 0 to N-1.
/// Useful for static loop unrolling. (staticIota)
template RangeTuple(size_t N)
{
    alias RangeTupleImpl!(N, ValueTuple!()) RangeTuple;
}

/// Equivalent of PHP's `list` language construct:
/// http://php.net/manual/en/function.list.php
/// Works with arrays and tuples.
/// Specify `null` as an argument to ignore that index
/// (equivalent of `list(x, , y)` in PHP).
auto list(Args...)(auto ref Args args)
{
    import std.format : format;

    struct List
    {
        auto dummy() { return args[0]; }

        void opAssign(T)(auto ref T t)
        {
            assert(t.length == args.length,
                "Assigning %d elements to list with %d elements"
                .format(t.length, args.length));

            foreach (i; RangeTuple!(Args.length))
                static if (!is(Args[i] == typeof(null)))
                    args[i] = t[i];
        }
    }

    return List();
}

unittest
{
    assert("true".isBoolean == true);
    assert("trues".isBoolean == false);
    assert("0".isBooleanString == false);
    assert("true".isBooleanString == true);
    assert(0.isBooleanNumber == true);
    assert(2.isBooleanNumber == false);
    assert("0".isBooleanNumber == true);
    assert("2".isBooleanNumber == false);

    import std.algorithm : findSplit;
	string name, value;
	list(name, null, value) = "key=value".findSplit("=");
    assert(name == "key" && value == "value");
}
