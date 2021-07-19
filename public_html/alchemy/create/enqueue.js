// Author: Ivan Kazmenko (gassa@mail.ru)
var queueBuilds = {};
var queueUses = {};
var constructQueue = [];
var inProgress = false;

setInterval (processQueue, 100);

async function processQueue () {
	if (inProgress) {
		return;
	}
	if (numActionsToPack == 1) {
		await processQueueSingle ();
		return;
	}
	inProgress = true;

	if (constructQueue.length > 0) {
		let curNum = Math.min (constructQueue.length,
		    numActionsToPack);
		let curs = [];
		for (i = 0; i < curNum; i++) {
			let cur = constructQueue.shift ();
			curs.push (cur);
			queueBuilds[cur] = (queueBuilds[cur] - 1);
			for (part of recipes[cur]) {
				queueUses[part] = (queueUses[part] || 0) - 1;
			}
		}

		if (await constructMulti (curs)) {
			for (i = 0; i < curNum; i++) {
				let cur = curs.pop ();
				for (part of recipes[cur]) {
					balances[part] =
					    (balances[part] || 0) - 1;
				}
				balances[cur] = (balances[cur] || 0) + 1;
			}
		} else {
			for (i = 0; i < curNum; i++) {
				let cur = curs.pop ();
				constructQueue.unshift (cur);
				queueBuilds[cur] = (queueBuilds[cur] + 1);
				for (part of recipes[cur]) {
					queueUses[part] =
					    (queueUses[part] || 0) + 1;
				}
			}
		}

		updateTable ();
		updateQueueDisplay ();
	}
	inProgress = false;
}

async function processQueueSingle () {
	if (inProgress) {
		return;
	}
	inProgress = true;
	if (constructQueue.length > 0) {
		let cur = constructQueue.shift ();
		queueBuilds[cur] = (queueBuilds[cur] - 1);
		for (part of recipes[cur]) {
			queueUses[part] = (queueUses[part] || 0) - 1;
		}
		updateQueueDisplay ();
		if (await construct (cur)) {
			for (part of recipes[cur]) {
				balances[part] = (balances[part] || 0) - 1;
			}
			balances[cur] = (balances[cur] || 0) + 1;
			updateTable ();
		}
	}
	inProgress = false;
}

async function constructProceed (elem) {
	doLog ('Preparing ' + mode + ' construction: ' + elem + '...');
	if (mode == "SINGLE") {
		await constructSingle (elem);
	} else if (mode == "REUSE") {
		await constructReuse (elem);
	} else if (mode == "ALL") {
		await constructAll (elem);
	}
	updateQueueDisplay ();
	updateTable ();
}

function pushIntoQueueAccount (elem) {
	queueBuilds[elem] = (queueBuilds[elem] || 0) + 1;
	for (part of recipes[elem]) {
		queueUses[part] = (queueUses[part] || 0) + 1;
	}
}

function pushIntoQueue (elem) {
	constructQueue.push (elem);
}

async function constructSingle (elem) {
	pushIntoQueueAccount (elem);
	pushIntoQueue (elem);
}

async function constructReuse (elem) {
	recurRecipesReuse (elem, function (s) {
		if (s in recipes) {
			pushIntoQueueAccount (s);
		}
	}, function (s) {
		if (s in recipes) {
			pushIntoQueue (s);
		}
	});
}

async function constructAll (elem) {
	recurRecipesAll (elem, function (s) {
		if (s in recipes) {
			pushIntoQueueAccount (s);
			pushIntoQueue (s);
		}
	});
}
