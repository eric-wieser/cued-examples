<%
from collections import Counter
from utils import format_ts_html

states = [
	('complete', 'success'),
	('needs review', 'warning'),
	('skipped', 'danger'),
	('unattempted', '')
]
%>
<html>
	<head>
		<link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body>
		<div class="container">
			<h1>Editing P{{ paper.paper_no }}: {{ paper.name }} <small>example sheet {{ paper.sheet_no }}</small></h1>
			<form method="POST" class="form-inline">
				<div class="form-group">
					<label for="input-qcount">Change question count</label>
					<input class="form-control" type="number" name="qcount" value="{{ len(paper.questions) }}" />
					<button type="submit" class="btn btn-primary">Update</button><br />
					<span class="text-danger">Warning: if there are logs for questions numbered higher than this number, they will be lost!</span>
				</div>
			</button>
			<hr />
			<h2>Progress log</h2>
			<div class="row">
				% for q in paper.questions:
					<div class="col-md-4">
						<h3>Q{{q.number}}</h3>
						<table class="table table-condensed">
							% for s in q.progress_log:
								<tr class="{{ dict(states).get(s.status) }}">
									<td>
										{{ s.status.title() }}
									</td>
									<td>
										{{! format_ts_html(s.recorded_at) }}
									</td>
								</tr>
							% end
						</table>
					</div>
				% end
			</div>
		</div>
	</body>
</html>