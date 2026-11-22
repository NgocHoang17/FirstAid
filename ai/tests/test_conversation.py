from uuid import uuid4
import pytest
from firstaid_rag.models import Query

def ask(engine, message, history, age=None):
    return engine.query(Query(request_id=uuid4(),message=message,context_messages=history,age_group=age,context_mode='learning'))

def test_follow_up_retrieves_topic_and_focuses_on_warnings(engine):
    history=['Tìm hiểu về bỏng']
    reply=ask(engine,'Cần tránh gì?',history)
    assert reply.status=='answered'
    doc=next(d for d in engine.documents if d['article_id']==str(reply.suggested_article_id))
    assert all(warning in [b.text for b in reply.answer_blocks] for warning in doc['sections']['warnings'])
    assert len(reply.answer_blocks)<len(doc['paragraphs'])

def test_age_switch_does_not_reuse_adult_context_for_child(engine):
    reply=ask(engine,'Còn trẻ em thì sao?',['Kiến thức CPR người lớn'],'CHILD')
    assert reply.status=='answered'
    doc=next(d for d in engine.documents if d['article_id']==str(reply.suggested_article_id))
    assert doc['age_group']=='CHILD'

@pytest.mark.parametrize('message,status', [('Con tôi không thở','emergency_redirect'),('Bé 6 tháng','out_of_scope'),('Cho uống thuốc gì?','out_of_scope')])
def test_latest_message_policy_cannot_be_bypassed_by_learning_history(engine,message,status):
    assert ask(engine,message,['Kiến thức sơ cứu bỏng']).status==status

def test_new_topic_and_unrelated_questions_do_not_inherit_stale_topic(engine):
    reply=ask(engine,'Tìm hiểu về chó cắn',['Kiến thức bỏng'])
    assert reply.suggested_category_code=='FA18'
    assert ask(engine,'Thời tiết hôm nay',['Kiến thức bỏng']).status=='insufficient_evidence'

def test_unsupported_explanations_and_nonexistent_steps_are_not_invented(engine):
    assert ask(engine,'Tại sao vậy?',['Kiến thức bỏng']).status=='insufficient_evidence'
    assert ask(engine,'Bước 99',['Kiến thức bỏng']).status=='insufficient_evidence'
