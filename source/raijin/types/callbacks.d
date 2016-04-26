/**
	Basic interface for working with callbacks(wrapped functions/delegates).

	Authors:
		Paul Crane
*/
module raijin.types.callbacks;

/**
	A simple interface for holding either a function or delegate to be called later.

	Examples:
		--------------------------------------
		alias VoidDelegate = void delegate();

		void func()
		{
			import std.stdio : writeln;
			writeln("Called func..");
		}

		void main()
		{
			Callback!VoidDelegate func;
			func.set(&func);
			func();
		}
		--------------------------------------
*/
struct Callback(T)
{
	void opCall(Args...)(Args args)
	{
		if(callback_)
		{
			callback_(args);
		}
	}

	/**
		Sets the callback used with opCall

		callback = The callback function/delegate to use with opCall.
	*/
	void set(T callback)
	{
		callback_ = callback;
	}

	/**
		Returns whether the callback has a valid function/delegate assigned to it.

		Returns:
			Whether the callback has a valid function/delegate assigned to it
	*/
	bool isSet() const
	{
		if(callback_)
		{
			return true;
		}

		return false;
	}

	T callback_;
}
