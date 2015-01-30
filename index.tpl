<%
from utils import Counter, accumulate, states
import itertools
from datetime import datetime, time, timedelta

rebase('layout')

%>
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
	done_papers.sort(key=lambda p: (p.class_date, p.issue_date, -p.paper_no), reverse=True)
	%>
	% def make_paper(p):
		<h2 class="clip">
			<a class="right" href='/paper/{{ p.id }}/edit' title="Edit paper details">
				<small>examples paper {{ p.sheet_no }}</small>
			</a>
			<span class="inner" title="{{ p.name }}">P{{ p.paper_no }}: {{ p.name }}</span>
		</h2>
		<div class="progress-multi">
			% if p.questions:
				<div class="progress" title="Question progress">
					<%
					counts = Counter(q.progress_status for q in p.questions)
					counts = [(counts[k], cls) for k, cls, icon in states if counts[k] and cls ]
					%>
					% for i, (cnt, cls) in enumerate(counts):
						<div class="progress-bar progress-bar-{{cls}}"
						     style="width: {{ cnt * 100.0 / len(p.questions) }}%;">
							{{ cnt }}
						</div>
					% end
				</div>
			% end
			<%
			if p.issue_date:
				i = p.issue_date
			else:
				i = datetime.now().date() - timedelta(days=14)
			end
			spent = (datetime.now() - datetime.combine(i, time())).total_seconds()
			allocated = (p.class_date - i).total_seconds()
			progress_t = spent / allocated
			%>
			<div class="progress" style="height: 10px" title="Issued {{ p.issue_date or 'last term'}}, due {{ p.class_date }}">
				<div class="progress-bar progress-bar-striped"
				     style="width: {{ spent / allocated * 100 }}%; background-color: #777">
				</div>
			</div>
		</div>
		% if p.questions:
			<form method="post" class="row">
				<div class="col-xs-10">
					<div class="table-responsive">
						<table class="table table-condensed" style="table-layout: fixed">
							<thead>
								<tr>
									% for q in p.questions:
										<th>Q{{ q.number }}</th>
									% end
								</tr>
							</thead>
							<tr>
								% for q in p.questions:
									<td class="multi-radio">
										% for i, (name, class_name, icon) in enumerate(states):
											% next_name, _, _ = states[(i+1) % len(states)]
											<div>
												<input type="radio"
												       name="paper{{ p.id }}-q{{ q.number }}"
												       id="paper{{ p.id }}-q{{ q.number }}-{{name}}"
												       value="{{ name }}"
												       {{'checked' if q.progress_status == name else '' }}/>
												<label title="{{ name }}" for="paper{{ p.id }}-q{{ q.number }}-{{next_name}}">
													<a class="text-{{ class_name or 'muted' }}">
														<span class="{{ icon }}"></span>
													</a>
												</label>
											</div>
										% end
									</td>
								% end
							</tr>
						</table>
					</div>
				</div>
				<div class="col-xs-2">
					<button class="btn btn-default btn-block" type="submit">
						Save
					</button>
				</div>
			</form>
		% end
	% end
	<h2>In progress</h2>
	<div class="row">
		% for p in in_progress_papers:
			<div class="col-md-6">
				% make_paper(p)
			</div>
		% end
	</div>
</div>
<div class="well" style="border-left: none; border-right: none; border-radius: 0;">
	<div class="container">
		<h2>Done</h2>
		<div class="row">
			% for p in done_papers:
				<div class="col-md-6">
					% make_paper(p)
				</div>
			% end
		</div>
	</div>
</div>