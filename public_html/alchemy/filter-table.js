// Author: Ivan Kazmenko (gassa@mail.ru)
let filters = document.getElementById ('filters-table')
    .getElementsByClassName ('filter');
for (f of filters) {
	f.addEventListener ('click', function (event) {
		updateFilters (event.target);
	});
//	let g = f;
//	f.addEventListener ('click', event => {updateFilters (g);});
}
var theTable = document.getElementById ('recipes-table');

function updateFilters (f) {
	f.classList.toggle ("filter-off");
	f.classList.toggle ("filter-on");
	reFilter (theTable);
};

function reFilter (table) {
	const body = table.querySelector ('tbody');
	var strings = [];
	for (f of filters) {
		if (f.classList.contains ("filter-on")) {
			strings.push (f.innerText);
		}
	}
	body.querySelectorAll ('tr').forEach ((row, i) => {
		let ok = true;
		for (s of strings) {
			ok = false;
			row.querySelectorAll ('td').forEach ((cell, j) => {
				if (3 <= j && j < 7) {
					if (cell.innerText == s) {
						ok = true;
					}
				}
			});
			if (!ok) {
				break;
			}
		}
		if (ok) {
			row.style.display = 'table-row';
		} else {
			row.style.display = 'none';
		}
	});
}

function getData (body) {
	const data = [];
	body.querySelectorAll ('tr').forEach (row => {
		const line = [];
		row.querySelectorAll ('td').forEach (cell => {
			line.push (cell.innerText);
			line.push (cell.getAttribute ('class'));
			line.push (cell.getAttribute ('style'));
		});
		data.push (line);
	});
	return data;
}

function putData (body, data) {
	body.querySelectorAll ('tr').forEach ((row, i) => {
		const line = data[i];
		row.querySelectorAll ('td').forEach ((cell, j) => {
			if (j >= 0) {
				cell.innerText = line[j * 3 + 0];
				cell.setAttribute ('class', line[j * 3 + 1]);
				cell.setAttribute ('style', line[j * 3 + 2]);
			}
		});
	});
}
