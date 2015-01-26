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


class Question(Base):
	__tablename__ = 'questions'

	paper_id = Column(Integer, ForeignKey(Paper.id), primary_key=True)
	number = Column(Integer, primary_key=True)

	unlocked_at = Column(DateTime)

	progress_log = relationship(lambda: QuestionProgress, backref='question', cascade='all,delete-orphan')


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