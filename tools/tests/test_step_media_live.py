"""Run against a disposable seeded backend, never a shared user database."""
import copy
import os
import struct
import zlib
from uuid import uuid4
import httpx
import pytest

def png():
    def chunk(kind, data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',2,2,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b'\0'+b'\0\xff\xff'*2+b'\0'+b'\0\xff\xff'*2))+chunk(b'IEND',b'')

def test_media_security_layout_and_publication_lifecycle():
    url=os.getenv('FIRSTAID_MEDIA_TEST_URL')
    if not url: pytest.skip('Set FIRSTAID_MEDIA_TEST_URL to a disposable backend')
    with httpx.Client(base_url=url,trust_env=False,timeout=20) as client:
        token=client.get('/admin/auth/csrf').json()['data']
        headers={token['header_name']:token['token']}
        assert client.post('/admin/media',files={'file':('x.png',png(),'image/png')}).status_code in (401,403)
        client.post('/admin/auth/login',headers=headers,json={'username':os.environ['FIRSTAID_MEDIA_TEST_USER'],'password':os.environ['FIRSTAID_MEDIA_TEST_PASSWORD']}).raise_for_status()
        token=client.get('/admin/auth/csrf').json()['data'];headers={token['header_name']:token['token']}
        assert client.post('/admin/media',files={'file':('x.png',png(),'image/png')}).status_code==403
        assert client.post('/admin/media',headers=headers,files={'file':('x.png',b'<svg/>','image/png')}).status_code==400
        media=client.post('/admin/media',headers=headers,files={'file':('x.png',png(),'image/png')})
        assert media.status_code==201,media.text
        image=media.json()['data']
        with httpx.Client(base_url=url,trust_env=False) as public:
            assert public.get(image['url'].replace('/api/v1','')).status_code==404
            seed=client.get('/articles').json()['data']['items'][0]
            article=copy.deepcopy(client.get('/admin/articles/'+seed['id']).json()['data'])
            article.pop('id');article['slug']='media-test-'+uuid4().hex;article['variant_key']='media_test_'+uuid4().hex
            article['content_checked']=True
            article['steps'][0]['images']=[{'media_id':image['id'],'alt_text':'Test image, no medical instructions','caption':'Test'}]
            for step in article['steps']:step.pop('id',None)
            saved=client.post('/admin/articles',headers=headers,json=article)
            assert saved.status_code==201,saved.text
            saved=saved.json()['data'];identifier=saved['id']
            for layout in ['grid','carousel','stacked']:
                saved['image_layout']=layout
                saved['steps'][0]['image_layout']=layout
                saved['expected_revision']=saved['content_revision']
                response=client.put('/admin/articles/'+identifier,headers=headers,json=saved)
                assert response.status_code==200,response.text
                saved=response.json()['data']
                assert saved['steps'][0]['image_layout']==layout
                assert saved['steps'][0]['images'][0]['media_id']==image['id']
            response=client.post(f'/admin/articles/{identifier}/publish',headers=headers,json={'expected_revision':saved['content_revision']})
            assert response.status_code==200,response.text
            assert public.get(image['url'].replace('/api/v1','')).status_code==200
            client.post(f'/admin/articles/{identifier}/unpublish',headers=headers,json={'expected_revision':saved['content_revision']}).raise_for_status()
            assert public.get(image['url'].replace('/api/v1','')).status_code==404
            assert client.get(image['url'].replace('/api/v1','')).status_code==200
