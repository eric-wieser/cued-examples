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
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql.expression import select, extract, case
from sqlalchemy import func

Base = declarative_base()

CRSID = String(10)

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


	progress_log = relationship(
		lambda: QuestionProgress,
		order_by=lambda: QuestionProgress.recorded_at,
		backref='question', cascade='all,delete-orphan')



class QuestionProgress(Base):
	__tablename__ = 'question_progresses'
	id = Column(Integer, primary_key=True)

	paper_id    = Column(Integer, nullable=False)
	question_no = Column(Integer, nullable=False)

	status = Column(Enum("complete", "needs review", "skipped", "unattempted"))
	recorded_at = Column(DateTime, nullable=False)

	__table_args__ = (
		ForeignKeyConstraint([paper_id,          question_no],
							 [Question.paper_id, Question.number]),
	)


_QP = aliased(QuestionProgress)
QuestionProgress.is_newest = column_property(
	select([
		QuestionProgress.recorded_at == func.max(_QP.recorded_at)
	])
	.select_from(_QP)
	.where(
		(_QP.question_no == QuestionProgress.question_no) &
		(_QP.paper_id == QuestionProgress.paper_id)
	)
)
Question.progress = relationship(
	QuestionProgress,
	viewonly=True,
	uselist=False,
	primaryjoin=(QuestionProgress.question_no == Question.number)
			  & (QuestionProgress.paper_id == Question.paper_id)
			  & QuestionProgress.is_newest
)
Question.progress_status = column_property(
	func.coalesce(
		select([
			QuestionProgress.status
		])
		.where(
			(QuestionProgress.question_no == Question.number)
			& (QuestionProgress.paper_id == Question.paper_id)
			& QuestionProgress.is_newest
		)
		.as_scalar()
	, "unattempted")
)



if 0:
	s = Session()

	print s.query(Question).first().progress_status

if 0:
	Base.metadata.drop_all(engine)
	Base.metadata.create_all(engine)