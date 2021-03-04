// Author: Ivan Kazmenko (gassa@mail.ru)
module show_log_alchemy;
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
import std.typecons;

import a_rplanet_abi;
import transaction;
import utilities;

struct Record
{
	string timeStamp;
	string author;
	string [] recipe;
	string result;
	int num;
	int tries;
	int [5] cost;

	string toCsv ()
	{
		return chain (only (num.text, timeStamp, author),
		    recipe, only (result, tries.text, cost[0].text))
		    .join (",");
	}
}

int main (string [] args)
{
	auto nowTime = Clock.currTime (UTC ());
	auto nowString = nowTime.toISOExtString[0..19];
	auto nowUnix = nowTime.toUnixTime ();

	auto fileName = sha256Of ("account:a.rplanet action:discover")
	    .format !("%(%02x%)") ~ ".log";
	auto alchemyLog = File (fileName, "rb").byLineCopy.map !(split).array;

	string [] materials;
	materials ~= "AIR";
	materials ~= "EARTH";
	materials ~= "WATER";
	materials ~= "FIRE";

	CurrencySymbol [CurrencySymbol []] recipes;
	Record [] records;
	int [CurrencySymbol []] p;
	int [5] [string] cost;
	foreach (i, mat; materials)
	{
		cost[mat] = [10_000, 0, 0, 0, 0];
		cost[mat][i + 1] = 1;
	}

	void doHtmlAlchemyLog (string name)
	{
		string [] [] htmlLog;
		string [] csvLog;
		bool [] lineIsNew;
		int num = 0;
		foreach (line; alchemyLog)
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
//				writeln (c.elements.front.prettyName);
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

			num += 1;
			bool isNew = (g.element != g.element.init);
			lineIsNew ~= isNew;
			auto key = c.elements.idup;
			if (isNew)
			{
				recipes[key] = g.element;
			}
			if (c.elements in recipes)
			{
				g.element = recipes[c.elements];
			}
			if (g.element == g.element.init)
			{
				g.element.name = "-";
			}

			if (key !in p)
			{
				p[key] = records.length.to !(int);
				auto record = Record
				    (line[0] ~ " " ~ line[1], actor,
				    key.map !(x => x.prettyName).array,
				    g.element.prettyName,
				    num, 0, 0);
				foreach (j; 0..5)
				{
					record.cost[j] = record.recipe
					    .map !(x => cost[x][j]).sum;
				}
				if (record.result != "-")
				{
					materials ~= record.result;
					cost[record.result] = record.cost;
				}
				records ~= record;
			}
			records[p[key]].tries += 1;

			string [] curHtmlLog;
			curHtmlLog ~= `<tr>`;
			curHtmlLog ~= format (`<td class="amount">%s</td>`,
			    num);
			curHtmlLog ~= format (`<td class="time">%s %s</td>`,
			    line[0], line[1]);
			curHtmlLog ~= format (`<td class="name">%s</td>`,
			    actor);
			foreach (i; 0..4)
			{
				curHtmlLog ~= format
				    (`<td class="place">%s</td>`,
				    c.elements[i].prettyName);
			}
			curHtmlLog ~= format
			    (`<td class="place">%s%s</td>`,
			    g.element.prettyName, isNew ? "!" : "");
			curHtmlLog ~= `</tr>`;
			htmlLog ~= curHtmlLog;

			csvLog ~= chain (only (num.text,
			    line[0] ~ " " ~ line[1], actor),
			    c.elements.map !(x => x.prettyName),
			    only (g.element.prettyName.text
			    ~ (isNew ? "!" : ""))).join (",");
		}

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
			    `href="./log2.css" type="text/css">`);
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
			auto file = File (name ~ "-log.html", "wt");
			writeHeader (file,
			    "Alchemy log (last 10,000 entries)");

			file.writeln (`<table class="log">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln !(`<th>#</th>`);
			file.writefln !(`<th>Timestamp</th>`);
			file.writefln !(`<th>Actor</th>`);
			file.writefln !(`<th>1</th>`);
			file.writefln !(`<th>2</th>`);
			file.writefln !(`<th>3</th>`);
			file.writefln !(`<th>4</th>`);
			file.writefln !(`<th>Result</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach (const ref line; htmlLog.retro.take (10_000))
			{
				file.writefln ("%-(%s\n%)", line);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			writeFooter (file);

			auto fileCsv = File (name ~ "-log.csv", "wt");
			csvLog.retro.each !(line => fileCsv.writeln (line));
		}

		{
			auto file = File (name ~ "-table.html", "wt");
			writeHeader (file, "Alchemy table");

			immutable int filterColumns = 10;
			immutable real oneWidth = 100.0 / filterColumns;
			file.writeln (`<table class="log" ` ~
			    `id="filters-table">`);
			file.writeln (`<thead>`);
			file.writefln !(`<th colspan="%s">Filters</th>`)
			    (filterColumns);
			file.writeln (`</thead>`);
			file.writeln (`<tr>`);
			foreach (i, mat; materials)
			{
				file.writefln !(`<td class="place filter ` ~
				    `filter-off" width=%.3f%%>%s</td>`)
				    (oneWidth, mat);
				if ((i + 1) % filterColumns == 0)
				{
					file.writeln (`</tr>`);
					file.writeln (`<tr>`);
				}
			}
			file.writeln (`</tr>`);
			file.writeln (`</table>`);
			file.writeln (`<p height="5px"></p>`);

			file.writeln (`<table class="log" ` ~
			    `id="recipes-table">`);
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
			file.writefln !(`<th>Total Tries</th>`);
			file.writefln !(`<th>Aether Cost</th>`);
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
				file.writefln !(`<td class="amount">%s</td>`)
				    (record.cost[0]);
				file.writefln !(`</tr>`);
			}

			file.writeln (`</tbody>`);
			file.writeln (`</table>`);
			file.writeln (`<script src="filter-table.js">` ~
			    `</script>`);
			writeFooter (file);

			auto fileCsv = File (name ~ "-table.csv", "wt");
			records.retro.map !(record => record.toCsv)
			    .each !(line => fileCsv.writeln (line));
		}

		{
			auto file = File (name ~ "-recipes.html", "wt");
			writeHeader (file, "Alchemy recipes");

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
			file.writefln !(`<th>Total Tries</th>`);
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
				if (record.result == "-")
				{
					continue;
				}

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

			auto fileCsv = File (name ~ "-recipes.csv", "wt");
			records.retro.filter !(record => record.result != "-")
			    .map !(record => record.toCsv)
			    .each !(line => fileCsv.writeln (line));
		}
	}

	doHtmlAlchemyLog ("alchemy");

	return 0;
}
