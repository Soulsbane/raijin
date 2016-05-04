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

			funcCall.stop(); // Calling funcCall() will no longer call the assigned function.
			writeln("^^^^^^^^^");
			funcCall();

			funcCall.start(); // Calling resumed for assigned function.
			writeln("^^^^^^^^^");
			funcCall();
		}
		--------------------------------------
*/
struct Callback(T, ReturnType = void)
{
	static if(is(ReturnType == void))
	{
		/**
			Overload used for calling the registered function/delegate.

			Params:
				args = The arguments to pass to the function/delegate
		*/
		void opCall(Args...)(Args args)
		{
			if(callback_ && !stopped_)
			{
				callback_(args);
			}
		}
	}
	else
	{
		/**
			Overload used for calling the registered function/delegate.

			Params:
				args = The arguments to pass to the function/delegate

			Returns:
				The ReturnType passed to Callback!(T, ReturnType) when it was created.
		*/
	 	ReturnType opCall(Args...)(Args args)
		{
			ReturnType value;

			if(callback_ && !stopped_)
			{
				value = callback_(args);
			}
			
			return value;
		}
	}

	Callback opAssign(T callback) pure @safe
	{
		set(callback);
		return this;
	}

	/**
		Sets the callback used with opCall

		callback = The callback function/delegate to use with opCall.
	*/
	void set(T callback) pure @safe
	{
		callback_ = callback;
	}

	/**
		Returns whether the callback has a valid function/delegate assigned to it.

		Returns:
			Whether the callback has a valid function/delegate assigned to it
	*/
	bool isSet() pure const @safe
	{
		if(callback_)
		{
			return true;
		}

		return false;
	}

	/**
		Starts/Restarts the calling of the assigned function/delegate.
	*/
	void start() pure @safe
	{
		stopped_ = false;
	}

	/**
		Stops the calling of the assigned function/delegate.
	*/
	void stop() pure @safe
	{
		stopped_ = true;
	}

private:
	T callback_;
	bool stopped_;
}

///
unittest
{
	void voidFunc()
	{
		import std.stdio : writeln;
		writeln("A voidFunc call.");
	}

	alias VoidCall = void delegate(); // This could be a function. Unittests won't allow function pointers inside its block.
	Callback!VoidCall voidCall;

	voidCall.set(&voidFunc);
	voidCall();

	int intFunc()
	{
		import std.stdio : writeln;

		writeln("Returning from intFunc");
		return 0;
	}

	alias IntCall = int delegate();
	Callback!(IntCall, int) intCall;

	intCall = &intFunc;

	immutable int value = intCall();
	assert(value == 0);
}
