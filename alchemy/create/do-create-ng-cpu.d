// Author: Ivan Kazmenko (gassa@mail.ru)
module do_create_ng_cpu;
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

/*
	foreach (i, t; tierList)
	{
		writeln (i + 1, ": ", t.length, " ", t);
	}
*/

	auto writeTdElement (string str)
	{
		auto event = "";
		auto elementType = "ae-disabled";
		if (str in recipes)
		{
			event = format !(` onclick="constructPre ` ~
			    `(this, '%s')"`) (str);
			elementType = "ae-clickable";
		}
		writefln !(`<td id="ae-%s" class="alchemy-element %s" ` ~
		    `%s><span class="elem-text">%s</span></td>`)
		    (str, elementType, event, str);
	}

	writefln !(`<!DOCTYPE html>`);
	writefln !(`<html xmlns="http://www.w3.org/1999/xhtml">`);
	writefln !(`<meta http-equiv="content-type" content="text/html;` ~
	    ` charset=UTF-8">`);
	writefln !(`<head>`);
	writefln !(`<title>Element Creation NG` ~
	    ` &mdash; Slow &mdash; Game CPU</title>`);
	writefln !(`<link rel="stylesheet" href="./create-ng.css" ` ~
	    `type="text/css">`);
	writefln !(`</head>`);
	writefln !(``);

	immutable bool forceHttps = true;
	if (forceHttps)
	{
		writefln !(`<script>`);
		writefln !(`if (location.protocol !== 'https:') {`);
		writefln !(`	location.replace ('https://' +`);
		writefln !(`	    location.href.substring ` ~
		    `(location.protocol.length));`);
		writefln !(`}`);
		writefln !(`</script>`);
	}

	writefln !(`<script src='waxjs2.js'></script>`);
	writefln !(``);
	writefln !(`<body>`);
	writefln !(``);
	writefln !(`<div class="top-part">`);
	writefln !(`<h2>Element Creation NG` ~
	    ` &mdash; Slow &mdash; Game CPU` ~
	    ` <a href="./create-ng.html">(switch)</a></h2>`);
	writefln !(``);
	writefln !(`<p><a href="../index.html">Back to main page</a></p>`);
	writefln !(`<p>Warning: this third-party tool for the game ` ~
	    `is provided as is, with no warranty of any kind! ` ~
	    `The tool is <a href="https://github.com/GassaFM/alchemy">` ~
	    `open source</a>.</p>`);
	writefln !(`<p>Currently, this page has no way of buying ` ~
	    `base elements. This may change in the future.</p>`);
	writefln !(`<p>If stuck, click the Discover button.</p>`);
	writefln !(``);
	writefln !(`<p height="5px"></p>`);
	writefln !(``);

	writefln !(`<p id="multiplier-overview">`);
	writefln !(`<label for="num-multiplier" style="float:left;">` ~
	    `<b>Multiplier:</b>&nbsp;</label>`);
	writefln !(`<input type="number" id="num-multiplier" ` ~
	    `min="1" max="100" value="1" ` ~
	    `style="width: 50px; float:left; margin-right:20px;">`);
	writefln !(`The number of same elements to craft in one go. ` ~
	    `For example, you may want to create 100 PRESS ` ~
	    `by clicking just once.</p>`);
	writefln !(`<p height="5px"></p>`);
	writefln !(``);

	writefln !(`<table class="modes" ` ~
	    `style="float:left; margin-right:20px;">`);
	writefln !(`<tr>`);
	writefln !(`<th>Mode:</th>`);
	writefln !(`<td class="mode mode-single-selected" ` ~
	    `onclick="modeSingle ()">SINGLE</td>`);
	writefln !(`<td class="mode mode-reuse" ` ~
	    `onclick="modeReuse ()">REUSE</td>`);
	writefln !(`<td class="mode mode-all" ` ~
	    `onclick="modeAll ()">ALL</td>`);
	writefln !(`</tr>`);
	writefln !(`</table>`);
	writefln !(`<p id="mode-overview">&nbsp;</p>`);
	writefln !(``);
	writefln !(`<p height="5px"></p>`);
	writefln !(``);

	writefln !(`<table class="log" id="recipes-table">`);
	writefln !(`<thead>`);
	writefln !(`<tr>`);
	writefln !(`<th colspan="%s">Elements by Tier</th>`)
	    (tierList.length);
	writefln !(`</tr>`);
	writefln !(`<tr>`);
	foreach (i, ref line; tierList)
	{
		writefln !(`<th>Tier %s</th>`) (i + 1);
	}
	writefln !(`</tr>`);
	writefln !(`</thead>`);

	writefln !(`</tbody>`);
	while (tierList.any !(line => !line.empty))
	{
		stderr.writeln (tierList.map !(line => line.length));
		writefln !(`<tr>`);
		foreach (ref line; tierList)
		{
			if (!line.empty)
			{
				writeTdElement (line.front);
				line.popFront ();
			}
			else
			{
				writefln !(`<td>&nbsp;</td>`);
			}
		}
		writefln !(`</tr>`);
	}
/*
	foreach (ref line; input)
	{
		auto t = line.strip.split (',');
		auto parts = t[3..7];
		auto result = t[7];
		writefln !(`<tr>`);
		writeTdElement (result);
		writefln !(`<td class="item" width=10px>&nbsp;</td>`);
		writefln !(`</tr>`);
	}
*/
	writefln !(`</tbody>`);
	writefln !(`</table>`);
	writefln !(`</div>`);
	writefln !(``);

	writefln !(`<div class="bottom-part">`);
	writefln !(`<p>`);
	writefln !(`<button id="login" onclick="loginSwitch ()">` ~
	    `Login</button>`);
	writefln !(`<button id="discover" onclick="discover ()">` ~
	    `Discover</button>`);
	writefln !(`<button id="updatebank" onclick="updateBank ()">` ~
	    `Update Gameinfo</button>`);
	writefln !(`<button id="updatebalances" onclick="updateBalances ()">` ~
	    `Update Balances</button>`);
	writefln !(`<button id="claim" onclick="claim ()">` ~
	    `Claim Aether</button>`);
	writefln !(`<span class="log" id="queue-element"">` ~
	    `</span>`);
	writefln !(`</p>`);
//	writefln !(`<p height="5px"></p>`);
//	writefln !(`<center><h3>Events Log</h3></center>`);
	writefln !(`<pre id="response" style="height:15vh;` ~
	    `background-color:#EEEEEE;overflow-y:scroll;"></pre>`);
	writefln !(`</div>`);
	writefln !(``);

	// quick fix: embed recipes to not have to hard-refresh the page
//	writefln !(`<script src='recipes.js'></script>`);
	writefln !(`<script>`);
	foreach (line; File ("recipes.js", "rt").byLineCopy)
	{
		writeln ("\t", line);
	}
	writefln !(`</script>`);
	writefln !(`<script src='traverse.js'></script>`);
	writefln !(`<script src='enqueue.js'></script>`);
	writefln !(`<script src='create-ng-cpu.js'></script>`);
	writefln !(`</body>`);
	writefln !(`</html>`);
}
