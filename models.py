from __future__ import division

import os

import sqlalchemy
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

base_dir = os.path.dirname(__file__)
engine = create_engine('sqlite:///{}'.format(os.path.join(base_dir, 'dev.sqlite3')))
Session = sessionmaker(engine)


from sqlalchemy import Table, Column, ForeignKey, UniqueConstraint, ForeignKeyConstraint
from sqlalchemy import (
	Boolean,
	Date,
	DateTime,
	Enum,
	Float,
	Integer,
	Numeric,
	SmallInteger,
	String,
	Unicode,
	UnicodeText,
)
from sqlalchemy.orm import relationship, backref, column_property, aliased, join
from sqlalchemy.orm.collections import attribute_mapped_collection
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql.expression import select, extract, case
from sqlalchemy.ext.hybrid import hybrid_method
from sqlalchemy import func

Base = declarative_base()

CRSID = String(10)

class User(Base):
	__tablename__ = 'users'

	crsid = Column(CRSID, primary_key=True)

class Paper(Base):
	__tablename__ = 'papers'

	id       = Column(Integer, primary_key=True)
	paper_no = Column(Integer, nullable=False)
	sheet_no = Column(Integer, nullable=False)
	name     = Column(UnicodeText)

	issue_date = Column(Date)

	class_date = Column(Date)

	questions = relationship(lambda: Question, backref='paper')

	def _unlocked_questions(self, at):
		return (
			q for q in self.questions
			if q.unlocked_at is not None and q.unlocked_at < at
		)

	def unlocked_count(self, at):
		try:
			return max(q.number for q in self._unlocked_questions(at))
		except ValueError:
			return 0

	def unlocked_questions(self, at):
		m = self.unlocked_count(at)
		return (
			q for q in self.questions
			if q.number <= m
		)

	def unlocked_progress(self, at):
		try:
			return max(q.number for q in self._unlocked_questions(at)) / len(self.questions)
		except ValueError:
			return 0

	def guessed_progress(self, at):
		from datetime import datetime, timedelta, time
		try:
			latest = max(
				q.unlocked_at for q in self._unlocked_questions(at)
			)
		except ValueError:
			# no unlocked questions - use issue date
			if self.issue_date:
				latest = datetime.combine(self.issue_date, time())
			# if no issue date, assume 2 weeks ago
			else:
				latest = at - timedelta(days=14)

		due = datetime.combine(self.class_date, time())

		if due < latest:
			due = latest + timedelta(days=1)

		spent = (at - latest).total_seconds()
		allocated = (due - latest).total_seconds()
		progress_t = min(spent / allocated, 1)

		p = self.unlocked_progress(at)
		return p + progress_t * (1 - p)


class Question(Base):
	__tablename__ = 'questions'

	paper_id = Column(Integer, ForeignKey(Paper.id), primary_key=True)
	number = Column(Integer, primary_key=True)

	unlocked_at = Column(DateTime)

	@property
	def is_pending(self):
		from datetime import datetime
		return (
			self.is_unlocked and
			self.progress_status == 'unattempted'
		)

	is_unlocked = column_property(
		(unlocked_at != None) &
		(unlocked_at < func.now())
	)

	# dictionary of users to their progress log of this question
	all_progress_logs = relationship(
		lambda: QuestionProgress,
		order_by=lambda: QuestionProgress.recorded_at,
		backref='question', cascade='all,delete-orphan')

	def progress_log_for(self, user):
		return (l for l in self.all_progress_logs if l.user == user)

	@hybrid_method
	def progress_status_for(self, user):
		s = self.progress_for.get(user)
		return s.status if s else 'unattempted'

	@progress_status_for.expression
	def progress_status_for(self, user):
		return func.coalesce(
			select([
				QuestionProgress.status
			])
			.where(
				(QuestionProgress.question_no == Question.number)
				& (QuestionProgress.paper_id == Question.paper_id)
				& (QuestionProgress.user_crsid == user.crsid)
				& QuestionProgress.is_newest
			)
			.as_scalar(),
			"unattempted"
		)



class QuestionProgress(Base):
	__tablename__ = 'question_progresses'
	id = Column(Integer, primary_key=True)

	paper_id    = Column(Integer, nullable=False)
	question_no = Column(Integer, nullable=False)
	user_crsid  = Column(CRSID, ForeignKey(User.crsid), nullable=False)

	status = Column(Enum("complete", "needs review", "skipped", "unattempted"))
	recorded_at = Column(DateTime, nullable=False)

	user = relationship(User, backref='all_progresses')

	__table_args__ = (
		ForeignKeyConstraint([paper_id,          question_no],
							 [Question.paper_id, Question.number]),
	)

# indicates if this is the most recent info for the current (question, user)
# separate definition due to self reference
__QP = aliased(QuestionProgress)
QuestionProgress.is_newest = column_property(
	select([
		QuestionProgress.recorded_at == func.max(__QP.recorded_at)
	])
	.select_from(__QP)
	.where(
		(__QP.question_no == QuestionProgress.question_no) &
		(__QP.paper_id == QuestionProgress.paper_id) &
		(__QP.user_crsid == QuestionProgress.user_crsid)
	)
)

# a dictionary mapping users to the latest progress for the current (question, user)
# separate definition due to reference to QuestionProgress, defined after Quetsion
Question.progress_for = relationship(
	QuestionProgress,
	collection_class=attribute_mapped_collection('user'),
	viewonly=True,
	primaryjoin=(QuestionProgress.question_no == Question.number)
			  & (QuestionProgress.paper_id == Question.paper_id)
			  & QuestionProgress.is_newest
)


if 0:
	s = Session()

	print s.query(Question).first().progress_status

if 0:
	Base.metadata.drop_all(engine)
	Base.metadata.create_all(engine)