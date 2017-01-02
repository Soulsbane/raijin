module raijin.terminal.cursor;

import std.stdio : write;

private immutable SHOW_CURSOR = "\x1b[?25h";
private immutable HIDE_CURSOR = "\x1b[?25l";


void showCursor()
{
	write(SHOW_CURSOR);
}

void hideCursor()
{
	write(HIDE_CURSOR);
}
