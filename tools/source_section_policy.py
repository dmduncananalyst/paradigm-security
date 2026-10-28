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

def individual_article(source, route):
    bits = route.split('/', 1)
    if bits[0] in LANGUAGES and len(bits) == 2:
        route = bits[1]
    if route.startswith('blog-') or (route.startswith('blog/') and not route.endswith('/index.html')):
        return True
    if '/topics/' in route:
        return False
    if re.search(r'"@type"\s*:\s*"(?:Article|BlogPosting|NewsArticle|TechArticle)"', source):
        return True
    if re.search(r'class=["\'][^"\']*(?:loanHubGrid|resource-edition|topic-index|clean-question-grid|image-cards)', source):
        return False
    return bool(re.search(r'<article\b[^>]*class=["\'][^"\']*(?:reading-feature|financeArticle|article-body|aeo-article|\barticle\b)', source))

def inappropriate_spans(source, route):
    if individual_article(source, route):
        return []
    document = Document(source)
    found = []
    for n in document.nodes:
        chain = list(ancestors(n))
        if not any(a['tag'] == 'main' for a in chain):
            continue
        if n['tag'] in {'section','aside','div'} and set(n['attrs'].get('class','').split()) & CITATION_CLASSES:
            if n['end'] and any(c['tag'] in {'h1','h2','h3','h4','h5','h6','strong'} for c in n['children']):
                found.append((n['start'], n['end']))
        if n['tag'] not in {'h1','h2','h3','h4','h5','h6','strong'} or not LABEL.fullmatch(' '.join(html.unescape(''.join(n['text'])).split())):
            continue
        parent = n['parent']
        siblings = parent['children']
        following = siblings[siblings.index(n) + 1:]
        if following and following[0]['tag'] in {'ul','ol'} and following[0]['end']:
            found.append((n['start'], following[0]['end']))
    merged = []
    for start, end in sorted(set(found)):
        if merged and start <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(end, merged[-1][1]))
        else:
            merged.append((start, end))
    return merged

def clean(source, route):
    for start, end in reversed(inappropriate_spans(source, route)):
        source = source[:start] + source[end:]
    return source
