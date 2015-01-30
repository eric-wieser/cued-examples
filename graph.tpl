<%
from datetime import datetime, timedelta
import itertools
import json
from bottle import request

from utils import accumulate, Counter, states

rebase('layout')
%>
<div class="container">
<h2>Progress</h2>
<div>
	<%
	changes = []
	end_date = datetime.now()
	start_date = end_date - timedelta(int(request.params.days) if request.params.days else 7)
	for p in papers:
		for q in p.questions:
			last_s = 'unattempted'
			for r in q.progress_log:
				s = r.status
				if r.recorded_at > start_date:
					changes.append(
						(r.recorded_at, Counter({s: 1, last_s: -1}))
					)
				end
				last_s = s
			end
		end
	end

	# merge together simultaneous changes
	date_key = lambda (d, c): d
	changes.sort(key=date_key)
	changes = [
		(d, sum((c for _, c in group), Counter()))
		for d, group in itertools.groupby(changes, date_key)
	]

	# accumulate changes, and add end states
	dates = [start_date] + [d for d, _ in changes] + [end_date]
	count_totals = [Counter()] + list(accumulate(c for _, c in changes))
	data = dict(
		date_range=[start_date, end_date],
		values=[
			# convert the Counter to a row
			dict(
				date=d,
				counts=[count[k] for k, cls, _ in states if cls]
			)

			# accumulate over all dates
			for d1, d2, count in zip(dates, dates[1:], count_totals)
			for d in [d1, d2]
		]
	)

	def json_default(val):
		if isinstance(val, datetime):
			return val.isoformat()
		else:
			return val
		end
	end
	%>
	<style>

	.axis path,
	.axis line {
		fill: none;
		stroke: #000;
		shape-rendering: crispEdges;
	}

	.complete {
		fill: rgb(92, 184, 92);
	}
	.needs-review {
		fill: rgb(240, 173, 78);
	}
	.skipped {
		fill: rgb(217, 83, 79);
	}

	</style>
	<svg class="graph"></svg>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.3/d3.js"></script>
	<script>
		var data = {{! json.dumps(data, default=json_default) }};
		data.values.forEach(function(d) {
			d.date = new Date(d.date);
		});

		var margin = {top: 20, right: 20, bottom: 30, left: 50};
		var width = 1000 - margin.left - margin.right;
		var height = 500 - margin.top - margin.bottom;

		// axes
		var x = d3.time.scale()
			.range([0, width])
			.domain(d3.extent(data.values, function(d) { return d.date; }));
		var y = d3.scale.linear().range([height, 0])

		var xAxis = d3.svg.axis()
			.scale(x)
			.orient("bottom");
		var yAxis = d3.svg.axis()
			.scale(y)
			.orient("left");


		var area = d3.svg.area()
			.x(function(d) { return x(d.date); })
			.y0(function(d) { return y(d.y0); })
			.y1(function(d) { return y(d.y0 + d.y); });

		var stack = d3.layout.stack()
			.values(function(d) { return d.values; });

		var names = ['complete', 'needs review', 'skipped'];

		var data_series = stack(
			names.map(function(name, i) {
				return {
					name: name,
					values: data.values.map(function(d) {
						return {date: d.date, y: Math.max(0, d.counts[i])};
					})
				};
			}).reverse()
		).concat(stack(
				names.map(function(name, i) {
				return {
					name: name,
					values: data.values.map(function(d) {
						return {date: d.date, y: Math.min(0, d.counts[i])};
					})
				};
			}).reverse()
		));

		y.domain([
			d3.min(data_series.map(function(s) {
				return d3.min(s.values.map(function(x) {
					return x.y0 + x.y;
				}))
			})),
			d3.max(data_series.map(function(s) {
				return d3.max(s.values.map(function(x) {
					return x.y0 + x.y;
				}))
			}))
		]);

		// stuff
		var svg = d3.select("svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom)
			.append("g")
				.attr("transform", "translate(" + margin.left + "," + margin.top + ")");


		var st = svg.selectAll(".status-series").data(data_series)
			.enter().append("g")
				.attr("class", "status-series");

		st.append("path")
			.attr("class", function(d) {
				return "area " + d.name.replace(' ', '-')
			})
			.attr("d", function(d) { return area(d.values); })
			.style("fill", function(d) { "rgb(92, 184, 92)" });


		svg.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0," + y(0) + ")")
			.call(xAxis);

		svg.append("g")
			.attr("class", "y axis")
			.call(yAxis)
	</script>
</div>
</div>