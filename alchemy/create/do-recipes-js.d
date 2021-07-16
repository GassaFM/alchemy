// Author: Ivan Kazmenko (gassa@mail.ru)
module do_recipes_js;
import std.algorithm;
import std.ascii;
import std.conv;
import std.format;
import std.range;
import std.stdio;
import std.string;

void main ()
{
	string [] materials;
	materials ~= "AIR";
	materials ~= "EARTH";
	materials ~= "WATER";
	materials ~= "FIRE";

	string [] [] tierList;

	int [string] tier;
	void addToTier (string s)
	{
		auto num = tier[s];
		if (tierList.length <= num)
		{
			tierList.length = num + 1;
		}
		tierList[num] ~= s;
	}

	foreach (ref material; materials)
	{
		tier[material] = 0;
		addToTier (material);
	}

	auto input = File ("recipes.csv", "rt").byLineCopy.array;
	string [] [string] recipes;

	foreach (ref line; input.retro)
	{
		auto t = line.strip.split (',');
		auto parts = t[3..7];
		auto result = t[7];
		recipes[result] = parts;
		tier[result] = parts.map !(x => tier[x]).maxElement + 1;
		addToTier (result);
	}

	writefln ("// This script is auto-generated.");
	writefln !("");
	writefln !("recipes = {");
	foreach (t, tierLine; tierList.drop (1))
	{
		foreach (elem; tierLine)
		{
			writefln !("\t%s: [%(%s, %)],") (elem, recipes[elem]);
		}
	}
	writefln !("};");
}
