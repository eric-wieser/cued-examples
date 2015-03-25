import bottle
from bottle import *
from bottle.ext.sqlalchemy import SQLAlchemyPlugin
import models as m

import re
from datetime import datetime

# create our app
app = Bottle()

# install the sqlalchemy plugin, which injects a `db` argument into every route
app.install(SQLAlchemyPlugin(
	engine=m.engine,
	metadata=m.Base.metadata,
	keyword='db',
	use_kwargs=True
))

@app.route('/')
@view('index')
def index(db):
	return dict(papers=db.query(m.Paper).filter(
		(m.Paper.issue_date < datetime.now()) | (m.Paper.issue_date == None)
	).all())

@app.route('/graph')
@view('graph')
def index(db):
	return dict(papers=db.query(m.Paper).filter(
		(m.Paper.issue_date < datetime.now()) | (m.Paper.issue_date == None)
	).all())

@app.post('/')
def index(db):
	for k, v in request.forms.items():
		mat = re.match(r'^paper(\d+)-q(\d+)$', k)
		if not mat:
			print k
			continue

		paper_id, q_no = map(int, mat.groups())
		q = db.query(m.Question).filter_by(paper_id=paper_id, number=q_no).one()

		if q.progress_status != v:
			q.progress_log.append(
				m.QuestionProgress(status=v, recorded_at=datetime.now())
			)

	redirect('/')

@app.route('/paper/<paper_id:int>/edit')
@view('edit-paper')
def edit_paper(db, paper_id):
	paper = db.query(m.Paper).filter(m.Paper.id==paper_id).one()
	return dict(paper=paper)

@app.post('/paper/<paper_id:int>/edit')
def edit_paper(db, paper_id):
	if request.forms.qcount:
		qcount = int(request.forms.qcount)
		assert qcount > 0

		paper = db.query(m.Paper).filter(m.Paper.id==paper_id).one()

		new_qs = xrange(1, qcount + 1)
		old_qs = {q.number for q in paper.questions}

		to_remove = [
			q for q in paper.questions
			if q.number not in new_qs
		]
		to_add = [
			m.Question(number=n) for n in new_qs
			if n not in old_qs
		]
		for r in to_remove:
			db.delete(r)
		paper.questions += to_add

	else:
		for k, v in request.forms.items():
			mat = re.match(r'^q(\d+)-unlocked$', k)
			if not mat:
				continue
			v = datetime(*(int(x) for x in re.findall(r'\d+', v))) if v else None

			print mat.groups(), v

			q = db.query(m.Question).filter(
				m.Question.paper_id == paper_id,
				m.Question.number == mat.group(1)
			).one()
			q.unlocked_at = v


	redirect(request.url)



bottle.run(app=app, host='0.0.0.0', port=8080, debug=True, reloader=True)