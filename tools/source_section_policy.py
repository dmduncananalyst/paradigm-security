"""Keep citation/resource sections on individual articles and blog posts only.

Source spans are removed without reserializing approved page content. Ordinary
uses of words such as income sources, source records, and a design sourcing step
are not citation sections and are preserved.
"""
import html
from html.parser import HTMLParser
import json
import re

VOID = {'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}
LANGUAGES = {'es','fa','hy','zh-CN','ko','tl','te','ru','ar'}
CITATION_CLASSES = {'references','sources','source-reference-links','article-sources','source-notes','resource-links'}
LABEL = re.compile(r'^(?:(?:primary|official|related|additional|further|selected|key|trusted)\s+)*(?:sources?|resources?|references?|citations?|further reading)(?:\s*(?:and|&)\s*(?:sources?|resources?|references?|citations?))*\s*[:.]?$',re.I)

class Document(HTMLParser):
    def __init__(self, source):
        super().__init__(convert_charrefs=True)
        self.source, self.nodes, self.stack, self.offsets = source, [], [], [0]
        for line in source.splitlines(keepends=True):
            self.offsets.append(self.offsets[-1] + len(line))
        self.feed(source)
    def position(self):
        line, column = self.getpos()
        return self.offsets[line - 1] + column
    def handle_starttag(self, tag, attrs):
        n = {'tag':tag,'attrs':dict(attrs),'parent':self.stack[-1] if self.stack else None,'children':[],'text':[],'start':self.position(),'end':None}
        self.nodes.append(n)
        if self.stack:
            self.stack[-1]['children'].append(n)
        if tag in VOID:
            n['end'] = self.position() + len(self.get_starttag_text())
        else:
            self.stack.append(n)
    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if tag not in VOID:
            self.stack.pop()
    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i]['tag'] == tag:
                for n in self.stack[i:]:
                    n['end'] = self.source.find('>', self.position()) + 1
                del self.stack[i:]
                return
    def handle_data(self, text):
        for n in self.stack:
            n['text'].append(text)

def ancestors(node):
    while node:
        yield node
        node = node['parent']


BLOG_ROUTES=frozenset(['blog-company-holiday-party-security-risks.html', 'blog-construction-site-theft-holiday-shutdowns.html', 'blog-holiday-shopping-parking-lot-security.html', 'blog.html', 'cash-heavy-cannabis-dispensary-risk-los-angeles.html', 'package-theft-unsecured-gates-apartment-complexes.html', 'weekend-bar-nightclub-incidents-liability-los-angeles.html'])

# Blog membership is explicit: service/location pages cannot become citation
# exceptions merely by using an <article> wrapper or Article structured data.
def individual_article(source, route):
    bits=route.split('/',1)
    if bits[0] in LANGUAGES and len(bits)==2:route=bits[1]
    if route.startswith(('locations/','services/','protection/')) or route in {'index.html','about.html','contact.html','services.html','pricing.html','packages.html','faq.html'}:return False
    return route in BLOG_ROUTES or bool(re.search(r'"@type"\s*:\s*"BlogPosting"',source))

ATTRIBUTION_CLASSES={'references','sources','source-reference-links','article-sources','source-notes','bibliography','citations','refs','ref-list','reference-list','reference-links','sources-list','source-list','sources-section','reference-section','references-section','research-attribution','citation-list'}
ATTRIBUTION_LABEL=re.compile(r'^(?:(?:primary|official|additional|further|selected|key|trusted)\s+)*(?:sources?|references?|citations?|bibliography|sources? and references?|Fuentes(?: y referencias)?|Referencias|منابع(?: و مآخذ)?|مراجع|المصادر(?: والمراجع)?|المراجع|Աղբյուրներ|Հղումներ|参考资料|参考文献|参考|來源|来源|참고\s*문헌|출처|참고\s*자료|Mga\s+sanggunian|Sanggunian|మూలాలు|వనరులు|సూచనలు|Источники(?: и ссылки)?|Ссылки|Литература)\s*[:.]?$',re.I)

def inappropriate_spans(source,route):
    if individual_article(source,route):return []
    document=Document(source);found=[]
    def text(n):return ' '.join(html.unescape(''.join(n['text'])).split())
    def inside_body(n):return any(a['tag']=='body' for a in ancestors(n)) and not any(a['tag'] in {'script','style','nav','header','footer'} for a in ancestors(n))
    for n in document.nodes:
        if not n['end'] or not inside_body(n):continue
        classes=set(n['attrs'].get('class','').split())
        if n['tag'] in {'section','aside','div'} and (classes & ATTRIBUTION_CLASSES or 'data-article-references' in n['attrs']):
            found.append((n['start'],n['end']));continue
        label=text(n)
        if n['tag'] in {'h1','h2','h3','h4','h5','h6','strong'} and ATTRIBUTION_LABEL.fullmatch(label):
            parent=n['parent'];siblings=parent['children'] if parent else [];following=siblings[siblings.index(n)+1:];end=n['end']
            # A design process step called Source is not a research citation.
            if not any(c['tag'] in {'ul','ol'} for c in following) and not any(set(a['attrs'].get('class','').split()) & ATTRIBUTION_CLASSES or 'data-article-references' in a['attrs'] for a in ancestors(n)):
                continue
            if parent and parent['tag'] in {'div','section','aside'} and siblings and siblings[0] is n and all(c['tag'] in {'h1','h2','h3','h4','h5','h6','strong','p','ul','ol','div'} for c in siblings) and not any(c is not n and c['tag'] in {'h1','h2','h3','h4','h5','h6'} for c in siblings):
                if parent['end'] and not re.search(r'©|all rights reserved|photo(?:graph)?\s+credit|licensed under|CC[- ]BY',text(parent),re.I):
                    found.append((parent['start'],parent['end']));continue
            for following_node in following:
                if following_node['tag'] in {'ul','ol'} and following_node['end']:end=following_node['end'];break
                if following_node['tag']=='p' and following_node['end'] and any(c['tag']=='a' for c in following_node['children']):end=following_node['end'];continue
                break
            found.append((n['start'],end))
        if n['tag']=='p' and any(c['tag']=='a' for c in n['children']) and re.match(r'^(?:Sources?|References?|Citations?|Fuentes|منابع|المصادر|参考资料|출처|Источники)\s*:',label,re.I):found.append((n['start'],n['end']))
        if n['tag'] in {'sup','a'} and (classes & {'citation','cite','reference-marker'} or re.match(r'^#(?:cite|ref|source|fn)[-_]?\d',n['attrs'].get('href',''),re.I)) and re.fullmatch(r'\[?\d+(?:[,–-]\d+)*\]?',label):found.append((n['start'],n['end']))
    merged=[]
    for start,end in sorted(set(found)):
        if merged and start<=merged[-1][1]:merged[-1]=(merged[-1][0],max(end,merged[-1][1]))
        else:merged.append((start,end))
    return merged

def clean(source,route):
    for start,end in reversed(inappropriate_spans(source,route)):source=source[:start]+source[end:]
    return source
