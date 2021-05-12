// Author: Ivan Kazmenko (gassa@mail.ru)
module show_recipes;
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

immutable int nftLimit = 600;

char [] toCommaNumber (long value)
{
	int pos = 24;
	auto res = new char [pos];
	do
	{
		pos -= 1;
		if (!(pos & 3))
		{
			res[pos] = ',';
			pos -= 1;
		}
		res[pos] = cast (char) (value % 10 + '0');
		value /= 10;
	}
	while (value != 0);
	return res[pos..$];
}

struct Record
{
	string timeStamp;
	string lastChecked;
	string author;
	string [] recipe;
	string result;
	int num;
	int tries;
	int [5] cost;

	string toCsv ()
	{
		auto curResult = result;
		auto curTime = SysTime.fromSimpleString (lastChecked, UTC ());
		return chain (only (num.text, timeStamp, author),
		    recipe, only (curResult, tries.text, cost[0].text))
		    .join (",");
	}
}

int main (string [] args)
{
	void doHtmlRecipesLog (string name)
	{
		auto nowTime = Clock.currTime (UTC ());

		string [] materials;
		materials ~= "AIR";
		materials ~= "EARTH";
		materials ~= "WATER";
		materials ~= "FIRE";

		bool [string] baseElements;
		foreach (ref material; materials)
		{
			baseElements[material] = true;
		}

		int [string] tier;
		foreach (ref material; materials)
		{
			tier[material] = 0;
		}

		CurrencySymbol [CurrencySymbol []] recipes;
		Record [] records;
		int [CurrencySymbol []] p;
		int [5] [string] cost;
		foreach (i, mat; materials)
		{
			cost[mat] = [10_000, 0, 0, 0, 0];
			cost[mat][i + 1] = 1;
		}

		auto input1 = File ("recipes-bootstrap.txt", "rt")
		    .byLineCopy.array;
		auto fileName = sha256Of
		    ("account:a.rplanet action:discover db.table:inventornfts")
		    .format !("%(%02x%)") ~ ".log";
		auto input2 = File (fileName, "rb")
		    .byLineCopy.array;
		auto recipesLog = chain (input1, input2).map !(split).array;

		int num = 0;
		foreach (line; recipesLog)
		{
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

			num += 1;
			auto key = c.elements.idup;
			recipes[key] = g.element;

			auto curTimeStamp = line[0] ~ " " ~ line[1];
			auto curResult = g.element.prettyName;

			p[key] = records.length.to !(int);
			auto record = Record
			    (curTimeStamp, curTimeStamp, actor,
			    key.map !(x => x.prettyName).array,
			    curResult, num, 0, 0);
			foreach (j; 0..5)
			{
				record.cost[j] = record.recipe
				    .map !(x => cost[x][j]).sum;
			}
			materials ~= curResult;
			cost[curResult] = record.cost;
			records ~= record;

			records[p[key]].tries += 1;
			records[p[key]].lastChecked = line[0] ~ " " ~ line[1];
		}

		auto nowString = nowTime.toISOExtString[0..19];
		auto nowUnix = nowTime.toUnixTime ();

		void writeHeader (ref File file, string title)
		{
			file.writeln (`<!DOCTYPE html>`);
			file.writeln (`<html xmlns=` ~
			    `"http://www.w3.org/1999/xhtml">`);
			file.writeln (`<meta http-equiv="content-type" ` ~
			    `content="text/html; charset=UTF-8">`);
			file.writeln (`<head>`);
			file.writefln (`<title>%s</title>`, title);
			file.writeln (`<link rel="stylesheet" ` ~
			    `href="./log4.css" type="text/css">`);
			file.writeln (`</head>`);
			file.writeln (`<body>`);
			file.writefln (`<p><a href="./index.html">` ~
			    `Back to main page</a></p>`);

			file.writefln (`<h2 style="margin: 0; float: left; ` ~
			    `margin-right: 20px;">%s:</h2>`, title);
			file.writefln (`<p id="updated-at"></p>`);
		}

		void writeFooter (ref File file)
		{
			file.writefln (`<p>Generated on %s (UTC).</p>`,
			    nowString);
			file.writefln (`<p><a href="./index.html">` ~
			    `Back to main page</a></p>`);
			file.writefln (`<script type="text/javascript">` ~
			    `genTime = %s;</script>`, nowUnix);
			file.writefln (`<script type="text/javascript" ` ~
			    `src="alert-time.js"></script>`);
			file.writeln (`</body>`);
			file.writeln (`</html>`);
		}

		{
			auto file = File (name ~ ".html", "wt");
			writeHeader (file, "Recipes Lite");

			file.writeln (`<table class="log">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln !(`<th>#</th>`);
			file.writefln !(`<th>First Tried</th>`);
			file.writefln !(`<th>Daring Soul</th>`);
			file.writefln !(`<th>1</th>`);
			file.writefln !(`<th>2</th>`);
			file.writefln !(`<th>3</th>`);
			file.writefln !(`<th>4</th>`);
			file.writefln !(`<th>Result</th>`);
			file.writefln !(`<th>Total Crafts</th>`);
			file.writefln !(`<th>Aether Cost</th>`);
			file.writefln !(`<th style="width: 5%%">AIR</th>`);
			file.writefln !(`<th style="width: 5%%">EARTH</th>`);
			file.writefln !(`<th style="width: 5%%">WATER</th>`);
			file.writefln !(`<th style="width: 5%%">FIRE</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach_reverse (record; records)
			{
				file.writefln !(`<tr>`);
				file.writefln !(`<td class="amount">%s</td>`)
				    (record.num);
				file.writefln !(`<td class="time">%s</td>`)
				    (record.timeStamp);
				file.writefln !(`<td class="name">%s</td>`)
				    (record.author);
				foreach (i; 0..4)
				{
					file.writefln !(`<td class="place">` ~
					    `%s</td>`) (record.recipe[i]);
				}
				file.writefln !(`<td class="place">%s</td>`)
				    (record.result);
				file.writefln !(`<td class="amount">%s</td>`)
				    (record.tries);
				foreach (j; 0..5)
				{
					file.writefln !(`<td class="amount">` ~
					    `%s</td>`) (record.cost[j]);
				}
				file.writefln !(`</tr>`);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			writeFooter (file);

			auto fileCsv = File (name ~ ".csv", "wt");
			records.retro.filter !(record => record.result != "-")
			    .map !(record => record.toCsv)
			    .each !(line => fileCsv.writeln (line));
		}
	}

	doHtmlRecipesLog ("recipes");

	return 0;
}
