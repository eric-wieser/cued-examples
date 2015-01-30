<%
rebase('layout')

from collections import Counter
from utils import format_ts_html, states
%>
<div class="container">
	<h1>Editing P{{ paper.paper_no }}: {{ paper.name }} <small>example sheet {{ paper.sheet_no }}</small></h1>
	<form method="POST" class="form-inline">
		<div class="form-group">
			<label for="input-qcount">Change question count</label>
			<input class="form-control" type="number" name="qcount" value="{{ len(paper.questions) }}" />
			<button type="submit" class="btn btn-primary">Update</button><br />
			<span class="text-danger">Warning: if there are logs for questions numbered higher than this number, they will be lost!</span>
		</div>
	</form>
	<hr />
	<h2>Progress log</h2>
	<form method="POST">
		<div class="row">
			% for q in paper.questions:
				<div class="col-md-4">
					<h3>Q{{q.number}}</h3>
					<table class="table table-condensed">
						% for s in q.progress_log:
							<tr class="{{ next(cls for st, cls, _ in states if st == s.status) }}">
								<td>
									{{ s.status.title() }}
								</td>
								<td>
									{{! format_ts_html(s.recorded_at) }}
								</td>
							</tr>
						% end
						<tr>
							<td>
								Unlocked
							</td>
							<td>
								<input class="form-control"
								       type="datetime-local"
								       name="q{{ q.number }}-unlocked"
								       step="3600"
								       value="{{q.unlocked_at.isoformat() if q.unlocked_at else ''}}" />
							</td>
					</table>
				</div>
			% end
		</div>
		<button type="submit" class="btn btn-primary">Update unlock dates</button><br />
	</form>
</div>
