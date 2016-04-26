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
		import std.stdio : writeln;

		alias VoidDelegate = void delegate();

		void func()
		{
			writeln("Called func..");
		}

		void assignedTo()
		{
			writeln("It was assignedTo");
		}

		void main()
		{
			Callback!VoidDelegate func;
			func.set(&func);
			func();

			funcCall = &assignedTo;
			funcCall();
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

	Callback opAssign(T callback)
	{
		set(callback);
		return this;
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
