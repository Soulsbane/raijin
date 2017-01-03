/**
	Provides functions for showing/hiding the mouse cursor in a terminal.
*/
module raijin.terminal.cursor;

import std.stdio : write;

private immutable SHOW_CURSOR = "\x1b[?25h";
private immutable HIDE_CURSOR = "\x1b[?25l";

/**
	Shows the cursor.
*/
void showCursor()
{
	write(SHOW_CURSOR);
}

/**
	Hides the cursor.
*/
void hideCursor()
{
	write(HIDE_CURSOR);
}
