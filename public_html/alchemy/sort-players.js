// Author: Ivan Kazmenko (gassa@mail.ru)
// Inspired by: https://stackoverflow.com/questions/10683712#57080195
const tableToSort = document.getElementById ('players-table');
document.getElementById ('col-player').addEventListener ('click',
    event => {sortTable (tableToSort,  1 * 3, +1, 'str');});
document.getElementById ('col-all-crafts').addEventListener ('click',
    event => {sortTable (tableToSort,  2 * 3, -1, 'num');});
document.getElementById ('col-good-crafts').addEventListener ('click',
    event => {sortTable (tableToSort,  3 * 3, -1, 'num');});
document.getElementById ('col-fail-crafts').addEventListener ('click',
    event => {sortTable (tableToSort,  4 * 3, -1, 'num');});
document.getElementById ('col-inventions').addEventListener ('click',
    event => {sortTable (tableToSort,  5 * 3, -1, 'num');});
document.getElementById ('col-nft-crafts').addEventListener ('click',
    event => {sortTable (tableToSort,  6 * 3, -1, 'num');});
document.getElementById ('col-aether-used').addEventListener ('click',
    event => {sortTable (tableToSort,  7 * 3, -1, 'num');});
document.getElementById ('col-aether-burnt').addEventListener ('click',
    event => {sortTable (tableToSort,  8 * 3, -1, 'num');});
document.getElementById ('col-highest-burn').addEventListener ('click',
    event => {sortTable (tableToSort,  9 * 3, -1, 'num');});

function sortTable (table, col, dir, type) {
	const body = table.querySelector ('tbody');
	const data = getData (body);
	data.sort ((a, b) => {
		mult = (a[col][0] == '-') ? -1 : +1;
		if (type == 'num') {
			if (a[col].length != b[col].length) {
				return ((a[col].length < b[col].length) ?
					-dir : +dir) * mult;
			}
		}
		if (a[col] != b[col]) {
			return ((a[col] < b[col]) ? -dir : +dir) * mult;
		}
		return 0;
	});
	putData (body, data);
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
			if (j >= 1) {
				cell.innerText = line[j * 3 + 0];
				cell.setAttribute ('class', line[j * 3 + 1]);
				cell.setAttribute ('style', line[j * 3 + 2]);
			}
		});
	});
}
