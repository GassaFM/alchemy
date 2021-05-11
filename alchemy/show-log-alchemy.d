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
import std.traits;
import std.typecons;

import a_rplanet_abi;
import transaction;
import utilities;

immutable SysTime timeSeparator;
immutable int nftLimit = 600;

shared static this ()
{
	timeSeparator = SysTime.fromSimpleString
	    ("2021-Mar-30 20:52:06", UTC ());
}

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
		if ((curTime < timeSeparator) && curResult == "-")
		{
			curResult = "=";
		}
		return chain (only (num.text, timeStamp, author),
		    recipe, only (curResult, tries.text, cost[0].text))
		    .join (",");
	}
}

struct PlayerInfo
{
	string name;
	int totalCrafts;
	int okCrafts;
	int failCrafts;
	int inventCrafts;
	int nftCrafts;
	long totalBurnt;
	long failBurnt;
	long maxBurnt;
}

int main (string [] args)
{
	auto outOfSync = false;
	try
	{
		File ("out-of-sync.txt", "rt");
		outOfSync = true;
	}
	catch (Exception e)
	{
	}

	auto nowTime = Clock.currTime (UTC ());
	auto lastTime = nowTime.toSimpleString ();

	auto fileName = sha256Of ("account:a.rplanet action:discover")
	    .format !("%(%02x%)") ~ ".log";
	auto alchemyLog = File (fileName, "rb").byLineCopy.map !(split).array;

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

	PlayerInfo [string] playersTable;
	PlayerInfo totals;
	totals.name = "Total:";

	CurrencySymbol [CurrencySymbol []] recipes;
	Record [] records;
	int [CurrencySymbol []] p;
	int [5] [string] cost;
	foreach (i, mat; materials)
	{
		cost[mat] = [10_000, 0, 0, 0, 0];
		cost[mat][i + 1] = 1;
	}

	immutable int logToDisplay = 10_000;

	void doHtmlAlchemyLog (string name)
	{
		string [] [] htmlLog;
		string [] csvLog;
		bool [] lineIsNew;
		int num = 0;
		foreach (lineIndex, line; alchemyLog)
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

			auto curTimeStamp = line[0] ~ " " ~ line[1];
			lastTime = curTimeStamp;
			auto curResult = g.element.prettyName;

			bool toAdd = (key !in p);
			if (!toAdd)
			{
				toAdd |= (records[p[key]].result != curResult);
			}
			if (!toAdd)
			{
				auto prevTime = SysTime.fromSimpleString
				    (records[p[key]].lastChecked, UTC ());
				auto nextTime = SysTime.fromSimpleString
				    (curTimeStamp, UTC ());
				toAdd |= (prevTime < timeSeparator &&
				    timeSeparator <= nextTime &&
				    records[p[key]].result == "-");
			}

			if (toAdd)
			{
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
				if (curResult != "-")
				{
					materials ~= curResult;
					cost[curResult] = record.cost;
				}
				records ~= record;
			}

			records[p[key]].tries += 1;
			records[p[key]].lastChecked = line[0] ~ " " ~ line[1];

			if (actor !in playersTable)
			{
				playersTable[actor] = PlayerInfo (actor);
			}
			with (playersTable[actor])
			{
				auto curCost = records[p[key]].cost[0];
				auto isOk = (records[p[key]].result != "-");
				auto curTries = records[p[key]].tries;

				totalCrafts += 1;
				totals.totalCrafts += 1;

				auto isNftCraft = isOk && curTries <= nftLimit;
				nftCrafts += isNftCraft;
				totals.nftCrafts += isNftCraft;

				auto burnt = records[p[key]].recipe
				    .count !(c =>
				    (c in baseElements) !is null) * 10_000;
				totalBurnt += burnt;
				totals.totalBurnt += burnt;
				if (isOk)
				{
					okCrafts += 1;
					totals.okCrafts += 1;
				}
				if (!isOk)
				{
					failCrafts += 1;
					totals.failCrafts += 1;

					failBurnt += curCost;
					totals.failBurnt += curCost;

					maxBurnt = max (maxBurnt, curCost);
					totals.maxBurnt = max
					    (totals.maxBurnt, curCost);
				}
				if (isOk && curTries == 1)
				{
					inventCrafts += 1;
					totals.inventCrafts += 1;
				}
			}

			if (lineIndex + logToDisplay >= alchemyLog.length)
			{
				string [] curHtmlLog;
				curHtmlLog ~= `<tr>`;
				curHtmlLog ~= format (`<td class="amount">` ~
				    `%s</td>`, num);
				curHtmlLog ~= format (`<td class="time">` ~
				    `%s %s</td>`, line[0], line[1]);
				curHtmlLog ~= format (`<td class="name">` ~
				    `%s</td>`, actor);
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
			}

			csvLog ~= chain (only (num.text,
			    line[0] ~ " " ~ line[1], actor),
			    c.elements.map !(x => x.prettyName),
			    only (g.element.prettyName.text
			    ~ (isNew ? "!" : ""))).join (",");
		}

		auto players = playersTable.byValue.array;
		auto playersIndex = players.length.iota.array;
		playersIndex.schwartzSort !(z =>
		    tuple (-players[z].totalCrafts, players[z].name));

		if (outOfSync)
		{
			nowTime = SysTime.fromSimpleString
			    (lastTime ~ "Z", UTC ());
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

			foreach (const ref line; htmlLog.retro)
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

/*			file.writeln (`<p>Blue lines were last attempted ` ~
			    `before new elements were added. ` ~
			    `Yellow lines were tried after that.</p>`);
*/
			file.writeln (`<p>The attempts before addition ` ~
			    `of new elements are not shown.</p>`);
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
			file.writefln !(`<th>Total Crafts</th>`);
			file.writefln !(`<th>Aether Cost</th>`);
			file.writeln (`</tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);

			foreach_reverse (record; records)
			{
				auto curTime = SysTime.fromSimpleString
				    (record.lastChecked, UTC ());
				if (curTime < timeSeparator)
				{
					continue;
				}
				file.writefln !(`<tr class="%s">`)
				    ((timeSeparator <= curTime) ?
				    "attempt-new" : "attempt-old");
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

		{
			auto file = File (name ~ "-players.html", "wt");
			writeHeader (file, "Alchemy players");

			file.writeln (`<p>Click on a column header ` ~
			    `to sort.</p>`);
			file.writeln (`<p height="5px"></p>`);
			file.writeln (`<table class="log" ` ~
			    `id="players-table">`);
			file.writeln (`<thead>`);
			file.writeln (`<tr>`);
			file.writefln !(`<th>#</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-player">Player</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-all-crafts">All Crafts</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-good-crafts">Good Crafts</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-fail-crafts">Fail Crafts</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-inventions">Inventions</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-nft-crafts">NFT Crafts</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-aether-used">Aether Used</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-aether-burnt">Aether Burnt</th>`);
			file.writefln !(`<th class="header" ` ~
			    `id="col-highest-burn">Highest Burn</th>`);
			file.writeln (`</tr>`);

			auto writePlayer (long i, ref PlayerInfo player)
			{
				file.writefln !(`<tr>`);
				file.writefln !(`<td class="amount">%s</td>`)
				    ((i >= 0) ? text (i + 1) : "&nbsp;");
				file.writefln !(`<td class="name">%s</td>`)
				    (player.name);
				static foreach (field;
				    FieldNameTuple !(PlayerInfo)[1..$])
				{
					file.writefln !(`<td class="amount">` ~
					    `%s</td>`) (mixin ("player." ~
					    field ~ ".toCommaNumber"));
				}
				file.writefln !(`</tr>`);
			}

			writePlayer (-1, totals);
			file.writefln !(`<tr height=5px></tr>`);
			file.writeln (`</thead>`);
			file.writeln (`<tbody>`);
			foreach (i, j; playersIndex)
			{
				writePlayer (cast (long) (i), players[j]);
			}
			file.writeln (`</tbody>`);
			file.writeln (`<tfoot>`);
			file.writefln !(`<tr height=5px></tr>`);
			writePlayer (-1, totals);
			file.writeln (`</tfoot>`);

			file.writeln (`</table>`);
			file.writefln (`<script type="text/javascript" ` ~
			    `src="sort-players.js"></script>`);
			writeFooter (file);
		}
	}

	doHtmlAlchemyLog ("alchemy");

	return 0;
}
