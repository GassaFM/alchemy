// Author: Ivan Kazmenko (gassa@mail.ru)
module extract_bootstrap;
import std.algorithm;
import std.ascii;
import std.conv;
import std.datetime;
import std.digest.sha;
import std.format;
import std.json;
import std.math;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import a_rplanet_abi;
import transaction;
import utilities;

int main (string [] args)
{
	bool [string] visited;
	auto fileName = sha256Of ("account:a.rplanet action:discover")
	    .format !("%(%02x%)") ~ ".log";
	foreach (lineInFull; File (fileName, "rb").byLineCopy)
	{
		auto line = lineInFull.split.array;
		auto actor = line[3];

		cauldronsElement c;
		if (line[4] != "-")
		{
			auto buf = line[4].hexStringToBinary;
			c = buf.parseBinary !(cauldronsElement);
			assert (buf.empty);
		}
		if (c.elements.length != 4)
		{
			continue;
		}
		sort (c.elements);

		gmelementsElement g;
		if (line[5] != "-")
		{
			auto buf = line[5].hexStringToBinary;
			g = buf.parseBinary !(gmelementsElement);
			assert (buf.empty);
		}
		else
		{
			continue;
		}

		auto result = g.element.text;
		if (result !in visited)
		{
			visited[result] = true;
			writeln (lineInFull);
		}
	}

	return 0;
}
