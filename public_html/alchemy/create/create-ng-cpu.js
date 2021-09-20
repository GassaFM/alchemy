// Author: Ivan Kazmenko (gassa@mail.ru)
// const urlWax = 'https://wax.greymass.com';
// const urlWax = 'https://chain.wax.io';
const urlWax = 'https://wax.cryptolions.io';
const wax = new waxjs.WaxJS ({rpcEndpoint: urlWax});

const delay = msecs => new Promise ((resolve, reject) => {
	setTimeout (_ => resolve (), msecs)
});

var responseElement = document.getElementById ('response');

function scrollToBottom () {
	responseElement.scrollTop = responseElement.scrollHeight;
}

var scrollingObserver = new MutationObserver (scrollToBottom);
scrollingObserver.observe (responseElement,
    {characterData: true, childList: true});

var bank = 0.0;
var bankUpdate = 0;
var balances = {};
var balancesUpdate = 0;

var numMultiplier = 1;
document.getElementById ('num-multiplier').value = numMultiplier;

var mode = "SINGLE";
modeSingle ();

init ();

async function initBalances () {
	balances = {['AIR']: 0, ['EARTH']: 0, ['WATER']: 0, ['FIRE']: 0};
}

async function init () {
	initBalances ();
	updateBank ();
	var loggedIn = await wax.isAutoLoginAvailable ();
	if (loggedIn) {
		updateBalances ();
//		wax.api.getAbi ('eosio.token');
	}
}

async function doLog (s) {
	responseElement.append (s + '\n');
}

async function loginSwitch () {
	await login ();
/*
	if (wax.userAccount) {
		await logout ();
	} else {
		await login ();
	}
*/
}

async function logout () {
	doLog ('Logging out...');
//	???
	initBalances ();
	updateTable ();
}

async function login () {
	doLog ('Logging in...');
	try {
		const userAccount = await wax.login ();
		doLog ('Logged in as ' + userAccount);
	} catch (e) {
		doLog ('Login error: ' + e.message);
	}
	updateBalances ();
//	wax.api.getAbi ('eosio.token');
}

async function updateBank () {
	doLog ('Gameinfo: updating...');
	try {
		bankUpdate = Date.now ();
		let data = {limit: 1, code: "a.rplanet",
		    table: "globalc", scope: "a.rplanet", json: true};
		var xhr = new XMLHttpRequest ();
		xhr.open ("POST",
		    urlWax + '/v1/chain/get_table_rows', true);
		xhr.setRequestHeader ('Content-Type', 'application/json');
		xhr.send (JSON.stringify (data));
		xhr.onload = async function () {
			var response = JSON.parse (this.responseText);
			bank = response.rows[0].bank;
			bank = bank.substring (0, bank.length - 4);
			bank = bank * 1.0;
			doLog ('Gameinfo: done, price is ~' +
			    (bank * 1E-7 * 0.2).toFixed (8) + ' WAX');
		}
	} catch (e) {
		doLog ('Gameinfo error: ' + e.message);
	}
}

async function updateBalances () {
	doLog ('Balances: updating...');
	if (!wax.api) {
		doLog ('Balances error: ' + 'login first');
		return;
	}

	try {
		balancesUpdate = Date.now ();
		let data = {limit: 250, code: 'simpleassets',
		    table: 'accounts', scope: wax.userAccount, json: true};
		var xhr = new XMLHttpRequest ();
		xhr.open ("POST",
		    urlWax + '/v1/chain/get_table_rows', true);
		xhr.setRequestHeader ('Content-Type', 'application/json');
		xhr.send (JSON.stringify (data));
		xhr.onload = async function () {
			const response = JSON.parse (this.responseText);
			for (row of response.rows) {
				if (row.author == 'a.rplanet') {
					const temp = row.balance.split (' ');
					balances[temp[1]] = temp[0] | 0;
				}
			}
			doLog ('Balances: done');
			updateTable ();
		}
		while (xhr.readyState < 4) {
			await delay (100);
		}
		await delay (100);
	} catch (e) {
		doLog ('Balances error: ' + e.message);
	}
}

function modeSingle () {
	mode = "SINGLE";
	constructReset ();
	for (temp of document.getElementsByClassName ('mode-single')) {
		temp.classList.remove ('mode-single');
		temp.classList.add ('mode-single-selected');
	}
	for (temp of document.getElementsByClassName ('mode-reuse-selected')) {
		temp.classList.remove ('mode-reuse-selected');
		temp.classList.add ('mode-reuse');
	}
	for (temp of document.getElementsByClassName ('mode-all-selected')) {
		temp.classList.remove ('mode-all-selected');
		temp.classList.add ('mode-all');
	}
	var overview = document.getElementById ('mode-overview');
	overview.innerText = 'SINGLE mode: First click selects the element. ' +
	    'Second click tries a single craft from the ingredients. ' +
	    'Useful for small crafts.';
}

function modeReuse () {
	mode = "REUSE";
	constructReset ();
	for (temp of document.getElementsByClassName ('mode-single-selected')) {
		temp.classList.remove ('mode-single-selected');
		temp.classList.add ('mode-single');
	}
	for (temp of document.getElementsByClassName ('mode-reuse')) {
		temp.classList.remove ('mode-reuse');
		temp.classList.add ('mode-reuse-selected');
	}
	for (temp of document.getElementsByClassName ('mode-all-selected')) {
		temp.classList.remove ('mode-all-selected');
		temp.classList.add ('mode-all');
	}
	var overview = document.getElementById ('mode-overview');
	overview.innerText = 'REUSE mode: First click selects the element. ' +
	    'Second click tries to create it using your existing FTs. ' +
	    'Useful for quick results.';
}

function modeAll () {
	mode = "ALL";
	constructReset ();
	for (temp of document.getElementsByClassName ('mode-single-selected')) {
		temp.classList.remove ('mode-single-selected');
		temp.classList.add ('mode-single');
	}
	for (temp of document.getElementsByClassName ('mode-reuse-selected')) {
		temp.classList.remove ('mode-reuse-selected');
		temp.classList.add ('mode-reuse');
	}
	for (temp of document.getElementsByClassName ('mode-all')) {
		temp.classList.remove ('mode-all');
		temp.classList.add ('mode-all-selected');
	}
	var overview = document.getElementById ('mode-overview');
	overview.innerText = 'ALL mode: First click selects the element. ' +
	    'Second click tries to create it all the way from base FTs. ' +
	    'Useful for precrafting.';
}

function constructClear () {
	let tempList = [];
	for (temp of document.getElementsByClassName ('ae-required')) {
		tempList.push (temp);
	}
	for (temp of tempList) {
		temp.classList.remove ('ae-required');
	}
	preUses = {};
	preBuilds = {};
}

function constructReset () {
	constructClear ();
	for (temp of document.getElementsByClassName ('ae-selected')) {
		temp.classList.remove ('ae-selected');
		temp.classList.add ('ae-clickable');
	}
	updateTable ();
}

var preUses = {};
var preBuilds = {};

const defaultActionsToPack = 1;
var numActionsToPack = defaultActionsToPack;
var singleActionFromTime = 0;

setInterval (updateMultiActions, 100);

async function updateMultiActions () {
	const curMoment = Date.now ();
	if (curMoment - singleActionFromTime > 15000) {
		numActionsToPack = defaultActionsToPack;
		singleActionFromTime = curMoment;
	}
}

function constructPre (cell, elem) {
	constructClear ();
	if (cell.classList.contains ('ae-selected')) {
		cell.classList.remove ('ae-selected');
		cell.classList.add ('ae-clickable');
		updateTable ();
		constructProceed (elem);
	} else {
		constructReset ();
		cell.classList.add ('ae-selected');
		cell.classList.remove ('ae-clickable');
		numMultiplier = document.getElementById ('num-multiplier').value;
		if (elem in recipes) {
			for (var numCur = 0; numCur < numMultiplier; numCur++) {
				if (mode == "SINGLE") {
					preBuilds[elem] = (preBuilds[elem] || 0) + 1;
					for (part of recipes[elem]) {
						let button = document.getElementById ('ae-' + part);
						button.classList.add ('ae-required');
						preUses[part] = (preUses[part] || 0) + 1;
					}
				} else if (mode == "REUSE") {
					recurRecipesReuse (elem, function (s) {
						let button = document.getElementById ('ae-' + s);
						button.classList.add ('ae-required');
						if (s in recipes) {
							preBuilds[s] = (preBuilds[s] || 0) + 1;
							for (part of recipes[s]) {
								let button = document.getElementById ('ae-' + part);
								button.classList.add ('ae-required');
									preUses[part] = (preUses[part] || 0) + 1;
								}
							}
						}, function (s) {
					});
				} else if (mode == "ALL") {
					recurRecipesAll (elem, function (s) {
						let button = document.getElementById ('ae-' + s);
						button.classList.add ('ae-required');
						if (s in recipes) {
							preBuilds[s] = (preBuilds[s] || 0) + 1;
							for (part of recipes[s]) {
								preUses[part] = (preUses[part] || 0) + 1;
							}
						}
					});
				}
			}
		}
/*
		for (s in preBuilds) {
			alert (s + ': ' + preBuilds[s]);
		}
*/
		updateTable ();
	}
}

async function construct (elem) {
	return await constructMulti ([elem]);
}

async function constructMulti (elems) {
	doLog ('Constructing: ' + elems + '...');
	if (!wax.api) {
		doLog ('Construct error: ' + 'login first');
		return false;
	}

	const steps = 2;
	for (var step = 0; step < steps; step++) {
		try {
			const curMoment = Date.now ();
			if (curMoment - bankUpdate > 5000) {
				updateBank ();
			}
			const payment = bank * 0.0000001 * 0.2;
			const payString = payment.toFixed (8) + ' WAX';
			var actionsVar = [];
			for (elem of elems) {
				doLog ('Construct: ' + payString + ' to game');
				const recipe = recipes[elem].join ();
				actionsVar.push ({
					account: 'eosio.token',
					name: 'transfer',
					authorization: [{
						actor: 'w.rplanet',
						permission: 'active',
					}, {
						actor: wax.userAccount,
						permission: 'active',
					}],
					data: {
						from: wax.userAccount,
						to: 'a.rplanet',
						quantity: payString,
						memo: 'construct:' + recipe
					}
				});
			}
//			console.log (actionsVar);
			const myKeys = await wax.api
			    .signatureProvider.getAvailableKeys ();
/*
			const allKeys = myKeys + ',EOS8NpCnBbL1qoQsrPPeSDkWRjrnvXWT4H432yV9UmEXS8qFxneyC';
			console.log (allKeys);
*/
			const result = await wax.api.transact ({
				actions: actionsVar
			}, {
//				useLastIrreversible: true,
				blocksBehind: 60,
				expireSeconds: 300,
				sign: true,
				requiredKeys: myKeys,
				broadcast: false,
			});
//			console.log (result);

			var xhr = new XMLHttpRequest ();
			xhr.open ("POST",
			    "https://prospectors.online/alchemy/create/rplanet-send.php", true);
			xhr.setRequestHeader ('Content-Type', 'application/json');
			let data = {
				account: wax.userAccount,
				data: {
					payload: btoa (String.fromCharCode
					    .apply (null, result.serializedTransaction)),
					signatures: result.signatures
				}
			};
			xhr.send (JSON.stringify (data));
			var response = {};
			xhr.onload = async function () {
				response = JSON.parse (this.responseText);
//				doLog ('Construct done! ' + this.responseText);
//				doLog ('Construct done!');
			}
			while (xhr.readyState < 4) {
				await delay (100);
			}
			if ("error" in response) {
//				doLog ('Construct error! ' + response);
				doLog ('Construct error!');
				await delay (1000);
				if (step == 1)
				{
					numActionsToPack = 1;
					singleActionFromTime = Date.now ();
					return false;
				}
			} else {
				break;
			}
		} catch (e) {
			doLog ('Construct error: ' + e.message);
			await delay (1000);
			if (step == 1)
			{
				numActionsToPack = 1;
				singleActionFromTime = Date.now ();
				return false;
			}
		}
	}
	doLog ('Construct done!');
	await delay (1000);

	if (constructQueue.length == 0) {
		updateBalances ();
	}

	return true;
}

async function updateTable () {
	var elements = document.getElementsByClassName ('alchemy-element');
	var good = false;
	for (elem in balances) {
		if (balances[elem] > 0) {
			good = true;
		}
	}
	for (elem of elements) {
		var s = elem.innerHTML;
		s = s.split (/[<>]/);
		s = s[2];
		s = s.split ('*');
		s = s[s.length - 1];
		var numPre = '';
		var numPost = '';
		if (good) {
			numPre = '' + (balances[s] || 0);
			if (preBuilds[s] || queueBuilds[s]) {
				numPost += '<span style="color: #007700">' +
				    '+' + ((preBuilds[s] || 0) +
				    (queueBuilds[s] || 0)) + '</span>';
			}
			if (preUses[s] || queueUses[s]) {
				numPost += '<span style="color: #770000">' +
				    '&ndash;' + ((preUses[s] || 0) +
				    (queueUses[s] || 0)) + '</span>';
			}
		}
		if (numPre != '') {
			s = numPre + '*' + s;
		}
		s = '<span class="elem-text">' + s + '</span>';
		if (numPost != '') {
			s = s + '<span class="delta">' + numPost + '</span>';
		}
		elem.innerHTML = s;
	}
}

const queueElement = document.getElementById ('queue-element');
updateQueueDisplay ();

async function updateQueueDisplay () {
	var num = 0;
	var s = "";
	for (elem of constructQueue) {
		if (s != "") {
			s += ", ";
		}
		num += 1;
		if (num >= 10) {
			s += "...";
			break;
		}
		s += elem;
	}
	if (s == "") {
		s = "(empty)";
	}
	queueElement.innerText = "Queue (" + constructQueue.length + "): " + s;
}

async function claim () {
	doLog ('Claiming...');
	try {
		const result = await wax.api.transact ({
			actions: [{
				account: 's.rplanet',
				name: 'claim',
				authorization: [{
					actor: wax.userAccount,
					permission: 'active',
				}],
				data: {
					to: wax.userAccount
				},
			}]
		}, {
//			useLastIrreversible: true,
			blocksBehind: 60,
			expireSeconds: 300
		});
		value = result.processed.action_traces[0].inline_traces[0]
		    .act.data.quantity;
		doLog ('Claim done! ' + value);
	} catch (e) {
		doLog ('Claim error: ' + e.message);
	}
}
