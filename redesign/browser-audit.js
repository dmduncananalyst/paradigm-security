(async()=>{
const results={width:innerWidth,pages:[],interactions:[],errors:[]};window.addEventListener('error',e=>results.errors.push(e.message));
const frame=document.createElement('iframe');frame.style.cssText='width:100%;height:'+innerHeight+'px;border:0';document.body.style.margin='0';document.body.append(frame);
const wait=ms=>new Promise(r=>setTimeout(r,ms));
for(const path of window.QA_PAGES){
frame.src='../'+path;while(true){await wait(20);try{if(frame.contentDocument.body?.dataset.page===path&&frame.contentWindow.PARADIGM_READY)break}catch{}}await wait(20);
const d=frame.contentDocument,w=frame.contentWindow;d.querySelectorAll('img').forEach(i=>i.loading='eager');await Promise.all([...d.images].map(i=>i.complete?Promise.resolve():new Promise(r=>{i.onload=r;i.onerror=r;setTimeout(r,1500)})));
const row={path,h1:d.querySelectorAll('h1').length,overflow:d.documentElement.scrollWidth>w.innerWidth,images:[...d.images].filter(i=>!i.naturalWidth).map(i=>i.getAttribute('src')),siteHeaders:d.querySelectorAll('#header').length,navigation:!!d.querySelector('nav'),topicSections:d.querySelectorAll('.safety-topic-section').length};results.pages.push(row);
if(path==='index.html'){
 const heading=d.querySelector('main h1');row.emptyHomeHeading=!heading?.textContent.trim();
 row.directServiceLinks=d.querySelectorAll('.home-service-gallery .image-card').length;
 row.hiddenServiceLinks=[...d.querySelectorAll('.home-service-gallery .image-card')].filter(a=>!a.getBoundingClientRect().height).length;
 row.rejectedDecoration=!!d.querySelector('.orbital-art,.service-tabs,.service-panel');
}
row.multicolumnText=[...d.querySelectorAll('.service-board .v5-chapter>div')].some(e=>Number(w.getComputedStyle(e).columnCount)>1);row.ctaCount=d.querySelectorAll('[data-open-intake]').length;row.intakeMissing=!d.querySelector('#intake-profile');
const cards=[...d.querySelectorAll('a.image-card')];
row.missingCardPhotos=cards.filter(a=>!a.querySelector('img')).map(a=>a.getAttribute('href'));
row.cardPhotoIssues=cards.flatMap(a=>{const img=a.querySelector('img');if(!img)return [];const r=img.getBoundingClientRect();return !img.naturalWidth||Math.abs(img.naturalWidth/img.naturalHeight-1.5)>.005||Math.abs(r.width/r.height-1.5)>.005?[img.getAttribute('src')]:[]});
row.cardRowSizeMismatch=cards.some((a,i)=>{const r=a.querySelector('img')?.getBoundingClientRect();if(!r)return false;return cards.slice(i+1).some(b=>{const s=b.querySelector('img')?.getBoundingClientRect();return s&&Math.abs(r.top-s.top)<2&&(Math.abs(r.width-s.width)>1||Math.abs(r.height-s.height)>1)})});
if(['index.html','services/asset-protection/vehicle-bike-patrol.html','protection/hospitals-medical-facilities.html','articles/topics/police-private-security.html'].includes(path)||path.startsWith('blog-')){
 for(let i=0;i<30&&!w.PARADIGM_INTAKE_READY;i++)await wait(20);
 const profile=JSON.parse(d.querySelector('#intake-profile').textContent),dialog=d.querySelector('#security-intake');d.querySelector('[data-open-intake]').click();
 row.chatOpens=dialog.open;row.chatContextCorrect=dialog.querySelector('h2').textContent===profile.title&&dialog.querySelector('[data-intake-log]').textContent.includes(profile.questions[0].prompt);
 const form=dialog.querySelector('form');for(let step=0;step<30&&!form.hidden;step++){const input=form.elements.answer;input.value=input.inputMode==='tel'?'8185550101':input.inputMode==='email'?'local-qa@example.com':input.autocomplete==='name'?'Local QA':'Local preview test';form.dispatchEvent(new w.Event('submit',{bubbles:true,cancelable:true}))}
 row.chatCompletes=form.hidden&&!!dialog.querySelector('.intake-review .button')&&!dialog.querySelector('iframe,.hs-form-frame');row.noEmbeddedForm=!dialog.querySelector('iframe,.hs-form-frame');
 const originalFetch=w.fetch;let request;w.fetch=async()=>({ok:false});dialog.querySelector('.intake-review .button').click();await wait(5);row.chatFailureKeepsAnswers=dialog.querySelector('[data-intake-status]').textContent.includes('has not been sent')&&form.hidden&&!dialog.querySelector('.intake-review .button').disabled;
 w.fetch=async(url,options)=>{request={url,body:JSON.parse(options.body)};return {ok:true}};
 dialog.querySelector('.intake-review .button').click();await wait(5);w.fetch=originalFetch;
 row.chatTranscriptMapped=request?.body.fields.some(f=>f.name==='message'&&f.value.includes('Local preview test')&&f.value.includes('8185550101')&&f.value.includes('local-qa@example.com'));row.chatContactFields=request?.body.fields.filter(f=>['firstname','lastname','email','phone','message'].includes(f.name)).length===5;row.chatSendConfirmed=dialog.querySelector('[data-intake-log]').textContent.includes('Your request has been sent');
 dialog.querySelector('[data-intake-close]').click();row.chatCloses=!dialog.open;
 if(path.includes('vehicle-bike'))row.chatSpecific=profile.questions.some(q=>/vehicle|bike/.test(q.prompt));if(path.includes('hospitals-medical'))row.chatSpecific=profile.questions.some(q=>/hospital|healthcare/.test(q.prompt));
}
const openingPhoto=d.querySelector('.reference-photo-hero>img,.local-home-hero>.opening-photo');if(openingPhoto){const r=openingPhoto.getBoundingClientRect();row.heroBelowFold=r.bottom>w.innerHeight+2;row.heroPhotoHeight=Math.round(r.height);row.heroPreservesProportions=['cover','contain','scale-down'].includes(w.getComputedStyle(openingPhoto).objectFit);row.heroUsesCropping=w.getComputedStyle(openingPhoto).objectFit==='cover'&&Math.abs(r.width/r.height-openingPhoto.naturalWidth/openingPhoto.naturalHeight)>.01;const headerBottom=d.querySelector('#header').getBoundingClientRect().bottom;row.heroGap=Math.abs(r.top-headerBottom)>2;const section=openingPhoto.parentElement.getBoundingClientRect();row.heroDoesNotFillSection=Math.abs(r.width-section.width)>2||Math.abs(r.height-section.height)>2}
const footerColumns=[...d.querySelectorAll('.footer-grid>*')].map(e=>e.getBoundingClientRect());row.footerOverlap=footerColumns.some((r,i)=>footerColumns.some((s,j)=>j>i&&Math.min(r.right,s.right)>Math.max(r.left,s.left)+1&&Math.min(r.bottom,s.bottom)>Math.max(r.top,s.top)+1));
row.croppedImages=[...d.images].filter(i=>{if(i.classList.contains('restored-reference-photo'))return false;const r=i.getBoundingClientRect();if(!r.width||!r.height||!i.naturalWidth)return false;const style=w.getComputedStyle(i),scale=Math.min(r.width/i.naturalWidth,r.height/i.naturalHeight),width=i.naturalWidth*scale,height=i.naturalHeight*scale;const content={left:r.left+(r.width-width)/2,right:r.left+(r.width+width)/2,top:r.top+(r.height-height)/2,bottom:r.top+(r.height+height)/2};if(style.objectFit!=='contain')return true;for(let p=i.parentElement;p&&p!==d.body;p=p.parentElement){const s=w.getComputedStyle(p);if(s.clipPath!=='none'||s.maskImage&&s.maskImage!=='none')return true;if(/hidden|clip/.test(s.overflowX+' '+s.overflowY)){const b=p.getBoundingClientRect();if(content.left<b.left-2||content.right>b.right+2||content.top<b.top-2||content.bottom>b.bottom+2)return true}}return false}).map(i=>i.getAttribute('src'));
if(path==='safety.html')row.categoryPhotos=d.querySelectorAll('.directory .image-card>img').length;
row.scrollingDropdowns=[...d.querySelectorAll('.header-nav-list .dropdown')].filter(el=>{const s=w.getComputedStyle(el);return /auto|scroll/.test(s.overflowY)&&s.maxHeight!=='none'}).length;
const title=d.querySelector('.reference-photo-title h1'),header=d.querySelector('#header');if(title&&header)row.headingUnderHeader=title.getBoundingClientRect().top<header.getBoundingClientRect().bottom-1;
if(w.innerWidth>=768){const links=[...d.querySelectorAll('#navigation>a,#navigation>.nav-group>a')],ys=links.map(a=>Math.round(a.getBoundingClientRect().top));row.navigationWraps=new Set(ys).size>1;row.headerOverflows=[...d.querySelectorAll('#navigation>a,#navigation>.nav-group>a,.header-phone')].some(a=>{const r=a.getBoundingClientRect();return r.right>w.innerWidth+1||r.left<0})}
row.stretchedImages=[...d.images].filter(img=>{const r=img.getBoundingClientRect();return r.width&&r.height&&img.naturalWidth&&w.getComputedStyle(img).objectFit==='fill'&&Math.abs((r.width/r.height)/(img.naturalWidth/img.naturalHeight)-1)>.02}).map(img=>img.getAttribute('src'));row.questionHeadings=[...d.querySelectorAll('main h1,main h2,main h3')].filter(e=>e.textContent.includes('?')).length;row.blogLink=[...d.querySelectorAll('nav a')].some(a=>a.textContent==='Blog'&&a.href.endsWith('/blog.html'));
if(path==='employment.html'){const apply=d.querySelector('.employment-apply');results.interactions.push({path,applicationDestination:apply?.href,opensSeparately:apply?.target==='_blank',noEmbeddedApplication:!d.querySelector('iframe')})}
if(path==='blog.html'){row.readArticleWhite=[...d.querySelectorAll('.journal-read')].every(e=>w.getComputedStyle(e).color==='rgb(255, 255, 255)');row.readArticleCentered=[...d.querySelectorAll('.journal-read')].every(e=>w.getComputedStyle(e).justifyContent==='center'&&!e.children.length);results.interactions.push({path,title:d.querySelector('h1')?.textContent,articles:d.querySelectorAll('.journal-preview').length,safetyArticlesInBlog:d.querySelectorAll('.journal-preview[href*="articles/"]').length})}
if(path==='about.html')row.aboutHeadingsCentered=[...d.querySelectorAll('main h2,main h3')].every(e=>w.getComputedStyle(e).textAlign==='center');
if(path.startsWith('blog-'))row.articleButtonGap=d.querySelector('.page-action .button').getBoundingClientRect().top-d.querySelector('.journal-copy').getBoundingClientRect().bottom;
if(['index.html','protection/events.html','articles/topics/homes-estates.html','contact.html'].includes(path)){
const record={path};record.navigationAlwaysVisible=w.getComputedStyle(d.querySelector('#navigation')).display!=='none';record.noMenuButtons=!d.querySelector('.mobile-toggle,.sub-toggle');
if(w.innerWidth<1200){const link=d.querySelector('.nav-group>a');link.click();record.dropdown=link.getAttribute('aria-expanded')==='true'&&w.getComputedStyle(link.parentElement.querySelector('.dropdown')).display!=='none';await wait(500);record.dropdownStable=link.getAttribute('aria-expanded')==='true';link.click();record.dropdownCloses=link.getAttribute('aria-expanded')==='false';}
record.guideRemoved=!d.querySelector('[data-chat],#chat-dialog');
if(path==='contact.html'){record.contactFormConfigured=!!w.PARADIGM_LEAD_CONFIG?.portalId}
row.footerHasCTA=!!d.querySelector('footer [data-open-intake]');row.pageHasCTA=!!d.querySelector('main [data-open-intake]');
results.interactions.push(record);
}
if(path==='blog.html'){
 const previews=[...d.querySelectorAll('.journal-preview')].map(a=>({href:a.getAttribute('href'),photo:a.querySelector('img').getAttribute('src')}));
 for(const preview of previews){
  frame.contentDocument.querySelector(`.journal-preview[href="${preview.href}"]`).click();
  for(let n=0;n<100;n++){await wait(20);if(frame.contentDocument.body?.dataset.page===preview.href&&frame.contentWindow.PARADIGM_READY)break}
  const article=frame.contentDocument;results.interactions.push({path:'blog.html',card:preview.href,opensCorrectArticle:article.body.dataset.page===preview.href,sameFeaturedPhoto:article.querySelector('.journal-feature img')?.getAttribute('src')===preview.photo});
  frame.src='../blog.html';for(let n=0;n<100;n++){await wait(20);if(frame.contentDocument.body?.dataset.page==='blog.html'&&frame.contentWindow.PARADIGM_READY)break}
 }
}
}
frame.remove();const pre=document.createElement('pre');pre.id='qa-results';pre.textContent=JSON.stringify(results,null,2);document.body.append(pre);document.title='AUDIT COMPLETE';
})();
