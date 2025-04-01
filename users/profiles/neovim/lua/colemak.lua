local wk = require('which-key')

-- Initially following maps are remapped
-- L -> E -> K -> N -> J -> M -> H -> I -> L
wk.register({
	h = { '<left>', 'Left' },
	H = { 'H', 'Top line of window' },

	u = { 'i', 'Insert' },
	U = { 'I', 'Insert at line start' },

	n = {
		[[(v:count > 1 ? "m'" . v:count : '') . '<down>']],
		'Down',
		expr = true,
	},
	N = { 'J', 'Join below line' },

	k = { 'n', 'Find next' },
	K = { 'N', 'Find previous' },

	e = { [[(v:count > 1 ? "m'" . v:count : '') . '<up>']], 'Up', expr = true },
	E = { 'K', 'Keyword lookup' },

	f = { 'e', 'Next end of word' },
	F = { 'E', 'Last char before white space' },

	i = { '<right>', 'Right' },
	I = { 'L', 'Last line of window' },

	m = { 'm', 'Create mark' },
	M = { 'M', 'Middle line of window' },

	['<c-i>'] = { '<c-i>', 'Jump to previous jump point' },
}, {
	mode = { 'n', 'x', 'o' },
})
