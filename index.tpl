<%
from collections import Counter
from datetime import datetime, time

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
			<h1>Example papers</h1>
			<%
			in_progress_papers = [
				p for p in papers
				if any(q.progress_status == 'unattempted' for q in p.questions)
			]
			done_papers = [
				p for p in papers if p not in in_progress_papers
			]
			%>
			% def make_paper(p):
				<div class="row">
					<div class="col-md-6">
						<h2>
							P{{ p.paper_no }}: {{ p.name }} <small>examples paper {{ p.sheet_no }}</small>
						</h2>
						% if p.questions:
							<div class="progress" style="margin-bottom: 10px" title="Question progress">
								<%
								counts = Counter(q.progress_status for q in p.questions)
								counts = [(counts[k], cls) for k, cls in states if counts[k] and cls ]
								%>
								% for i, (cnt, cls) in enumerate(counts):
									<div class="progress-bar progress-bar-{{cls}}"
									     style="width: {{ cnt * 100.0 / len(p.questions) }}%;">
										{{ cnt }}
									</div>
								% end
							</div>
						% end
						% if p.issue_date:
							<div class="progress" style="height: 10px" title="Time since issue">
								<%
								spent = (datetime.now() - datetime.combine(p.issue_date, time())).total_seconds()
								allocated = (p.class_date - p.issue_date).total_seconds()
								%>
								<div class="progress-bar progress-bar-striped"
								     style="width: {{ spent / allocated * 100 }}%; background-color: #777">
								</div>
							</div>
						% end
						<p>Issued {{ p.issue_date }}, due {{ p.class_date }}</p>
						<a class="btn btn-default pull-left" href='/paper/{{ p.id }}/edit'>Edit paper details</a>
					</div>
					% if p.questions:
						<form class="col-md-6" method="post">
							<table class="table table-condensed">
								<thead>
									<tr>
										<th></th>
										% for q in p.questions:
											<th>Q{{ q.number }}</th>
										% end
									</tr>
								</thead>
								% for name, class_name in states:
									<tr class="{{ class_name }}">
										<th>{{ name.title() }}</th>
										% for q in p.questions:
											<td>
												<label style="display: block">
													<input type="radio" name="paper{{ p.id }}-q{{ q.number }}" value="{{ name }}"
												       {{'checked' if q.progress_status == name else '' }}/>
												</label>
											</td>
										% end
									</tr>
								% end
							</table>
							<button class="btn btn-default pull-right" type="submit">Save</button>
						</form>
					% end
				</div>
			% end
			<h2>In progress</h2>
			% for p in in_progress_papers:
				% make_paper(p)
			% end
		</div>
		<div class="well" style="border-left: none; border-right: none; border-radius: 0;">
			<div class="container">
				<h2>Done</h2>
				% for p in done_papers:
					% make_paper(p)
				% end
			</div>
		</div>
	</body>
</html>