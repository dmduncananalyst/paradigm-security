"""Regression checks for the owner's blog-only public citation rule. No network calls."""
from pathlib import Path
import sys,json
sys.path.insert(0,str(Path(__file__).resolve().parent))
import source_section_policy as policy

def document(content):return '<!doctype html><html><body><main>'+content+'</main><footer>Copyright © 2026. License #123. <a href="contact.html">Contact</a></footer></body></html>'
reference='<section class="references"><h2>References</h2><ul><li><a href="https://example.gov/authority">Official source</a></li></ul></section>'
checks=[]
def check(name,condition):
    assert condition,name
    checks.append(name)
city=document('<h1>Security in a city</h1><article class="editorial-article location-article"><p>City-specific service content.</p>'+reference+'</article>')
clean=policy.clean(city,'locations/example.html')
check('city article wrapper does not exempt references','Official source' not in clean and 'City-specific service content.' in clean)
check('regular page Article schema does not exempt references',not policy.individual_article('<script type="application/ld+json">{"@type":"Article"}</script>','services/example.html'))
check('blog index preserved',policy.clean(document(reference),'blog.html')==document(reference))
article=next(route for route in sorted(policy.BLOG_ROUTES) if route!='blog.html')
check('actual blog article preserved',policy.clean(document(reference),article)==document(reference))
check('saved translated blog preserved',policy.clean(document(reference),'es/'+article)==document(reference))
check('translated standard page cleaned','references' not in policy.clean(document(reference.replace('References','Fuentes')),'es/locations/example.html'))
ordinary=document('<h1>Source records</h1><p>Keep source documents for 3 years where appropriate.</p><a href="services.html">Services</a><a href="https://business.example/contact">Business contact</a>')
check('ordinary numbers business links legal notices preserved',policy.clean(ordinary,'about.html')==ordinary)
wrapped=document('<section class="answer-box" data-article-references=""><h2>References</h2><p>Research attribution.</p><ul><li><a href="https://example.gov">Authority</a></li></ul></section>')
check('complete wrapper removed without empty section','answer-box' not in policy.clean(wrapped,'faq.html'))
marker=document('<p>Service fact<a class="citation" href="#ref1">[1]</a>. Room 2<sup>2</sup>.</p>'+reference)
clean=policy.clean(marker,'locations/example.html')
check('citation marker removed without ordinary exponent','[1]' not in clean and '<sup>2</sup>' in clean)
check('copyright and license footer preserved','Copyright © 2026. License #123.' in clean)
design=document('<article><h3>Source</h3><p>Materials and furniture are chosen for the design.</p></article><article><h3>来源</h3><p>材料和家具。</p></article>')
check('design sourcing steps are not citations',policy.clean(design,'interior-design.html')==design)
chinese=document('<h2>参考</h2><ul><li><a href="https://example.gov">官方资料</a></li></ul>')
check('short Chinese reference heading recognized','官方资料' not in policy.clean(chinese,'zh-CN/faq.html'))
print(json.dumps({'checks':len(checks),'passed':checks,'network_calls':0}))
