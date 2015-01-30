from datetime import datetime
import operator
import collections

states = [
	('complete',
		'success',
		'glyphicon glyphicon-ok'),
	('needs review',
		'warning',
		'glyphicon glyphicon-question-sign'),
	('skipped',
		'danger',
		'glyphicon glyphicon-remove'),
	('unattempted',
		'',
		'glyphicon glyphicon-unchecked')
]

def format_ts(ts):
	""" Used to format any timestamp in a readable way """
	now = datetime.now()
	today = now.date()

	if ts.date() == today:
		return "{:%H:%M:%S}".format(ts)
	if ts.date().year == today.year:
		return "{:%b %d, %H:%M}".format(ts)
	else:
		return "{:%Y, %b %d}".format(ts)

def format_ts_html(ts):
	return '<time title="{}">{}</time>'.format(
		ts.isoformat(), format_ts(ts)
	)

def accumulate(iterable, func=operator.add):
    'Return running totals'
    # accumulate([1,2,3,4,5]) --> 1 3 6 10 15
    # accumulate([1,2,3,4,5], operator.mul) --> 1 2 6 24 120
    it = iter(iterable)
    total = next(it)
    yield total
    for element in it:
        total = func(total, element)
        yield total

class Counter(collections.Counter):
	def __add__(self, other):
		result = self.copy()
		for elem, cnt in other.items():
			result[elem] += cnt
		return result
