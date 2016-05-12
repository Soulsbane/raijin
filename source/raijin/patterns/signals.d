/**
	A simple implementation of the signals pattern.
*/
module raijin.patterns.signals;

import std.algorithm;

/**
	The implementation of the signals pattern.
*/
struct Signals(Slot)
{
	/**
		Adds a function/delegate to the array of functions/delegates to be called later.

		Params:
			slot = The function/delegate to add.
	*/
	void connect(Slot slot)
	{
		slots_ ~= slot;
	}

	/**
		Remove a function/delegate from the array of functions/delegates.

		Params:
			slot = The function/delegate to remove.
	*/
	void disconnect(Slot slot)
	{
		slots_ = slots_.remove!((Slot a) { return a is slot; });
	}

	/**
		Removes all stored delegates/functions from the signals array.
	*/
	void disconnectAll()
	{
		slots_ = [];
	}

	/**
		Calls all functions/delegates in the signals array.
	*/
	void emit(Args...)(Args args)
	{
		slots_.each!(a => a(args));
	}

private:
	Slot[] slots_;
}

///
unittest
{
	import std.stdio : writeln;

	writeln;
	writeln("<=====================Beginning test for signals module=====================>");

	alias NotifyFunction = void delegate(); // Must be a delegate if functions are inside the unittest block.
	Signals!NotifyFunction signals;

	void firstFunc()
	{
		writeln("This is the FirstFunc calling...");
	}

	void secondFunc()
	{
		writeln("This is the SecondFunc calling...");
	}

	signals.connect(&firstFunc);
	signals.connect(&secondFunc);
	signals.emit();

	writeln("Removing firstFunc.");
	signals.disconnect(&firstFunc);
	signals.emit();

	writeln("Removing all slots.");
	signals.disconnectAll();
	signals.emit();

	alias NotifyDelegate = void delegate();
	alias NotifyDelegateArg = void delegate(string value);

	class TestDelegates
	{
		this()
		{
			signals_.connect(&aVoidDel);
			signals_.connect(&aVoidDel2);
			signals_.emit();
			signals_.disconnect(&aVoidDel2);
			signals_.emit();
			signals_.disconnectAll();
			signals_.emit();
		}

		void aVoidDel()
		{
			writeln("Calling TestDelegates.aVoidDel");
		}

		void aVoidDel2()
		{
			writeln("Calling TestDelegates.aVoidDel2");
		}

		void aArgDel()
		{
			writeln("Calling TestDelegates.aArgDel");
		}

	private:
		Signals!NotifyDelegate signals_;
	}

	auto test = new TestDelegates;
}
