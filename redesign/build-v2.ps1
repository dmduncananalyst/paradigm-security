$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$encoding=New-Object Text.UTF8Encoding $false
$domain='https://paradigmsecurityservices.com'
$pages=Get-Content (Join-Path $PSScriptRoot 'content.json') -Raw -Encoding UTF8|ConvertFrom-Json
$posts=@()
$assignments=Get-Content (Join-Path $PSScriptRoot 'photo-assignments.json') -Raw -Encoding UTF8|ConvertFrom-Json
function Save($path,$text){$target=Join-Path $root $path;New-Item -ItemType Directory -Force (Split-Path $target)|Out-Null;[IO.File]::WriteAllText($target,$text,$encoding)}
function E($text){[Net.WebUtility]::HtmlEncode([string]$text)}
function Plain($text){[Net.WebUtility]::HtmlDecode(([regex]::Replace([string]$text,'<[^>]+>',' ') -replace '\s+',' ').Trim())}
function Summary($p){$text=Plain ([regex]::Match($p.body,'(?is)<p[^>]*>(.*?)</p>').Groups[1].Value);if($text.Length -gt 210){$text=$text.Substring(0,207)+'...'};return $text}
function ImageFor($p){$item=$assignments.PSObject.Properties[$p.path];if($item){return $item.Value};return $p.image}
function Dropdown($label,$path,$items,$prefix){$links="<a href='$prefix$path'>All $label</a>";foreach($item in $items){$links+="<a href='$prefix$($item.path)'>$(E $item.title)</a>"};return "<div class='nav-group'><a href='$prefix$path'>$label</a><button class='nav-toggle' type='button' aria-label='Show $label menu' aria-expanded='false'>Menu</button><div class='dropdown'>$links</div></div>"}
$services=@($pages|Where-Object path -Like 'services/*')
$protection=@($pages|Where-Object path -Like 'protection/*')
$topics=@($pages|Where-Object path -Like 'articles/topics/*')
foreach($post in $posts){
 $body="<article class='blog-article'><a class='article-back' href='../blog.html'>Blog</a><p class='article-category'>$(E $post.category)</p>"
 foreach($section in $post.sections){$body+="<section><h2>$(E $section.heading)</h2>";foreach($paragraph in $section.paragraphs){$body+="<p>$(E $paragraph)</p>"};$body+='</section>'}
 $body+="<p class='article-contact'>For service inquiries, call <a href='tel:+18187465432'>818-746-5432</a>.</p></article>"
 $pages+=@{path="blog/$($post.slug).html";title=$post.title;description=$post.description;image=$post.image;canonical="$domain/blog/$($post.slug).html";body=$body;faq=@();category=$post.category}
}
$blogPosts=@($pages|Where-Object path -Like 'blog/*')
$chat=@{}
foreach($p in $pages){
 $prefix='../'*(($p.path.Split('/')).Count-1)
 $title=$p.title;$description=$p.description;$image=ImageFor $p;$body=$p.body
 $kind='standard';$parent='';$parentUrl=''
 if($p.path -like 'services/*'){$kind='service';$parent='Services';$parentUrl='services.html'}
 elseif($p.path -like 'protection/*'){$kind='service';$parent='Protection';$parentUrl='protection.html'}
 elseif($p.path -like 'articles/*'){$kind='education';$parent='Safety';$parentUrl='safety.html'}
 elseif($p.path -like 'blog/*'){$kind='post';$parent='Blog';$parentUrl='blog.html'}
 if($p.path -eq 'about.html'){$title='About Paradigm Security'}
 if($p.path -eq 'contact.html'){$title='Contact';$description='Discuss security coverage in Los Angeles County and San Bernardino County. Call 818-746-5432.'}
 if($p.path -eq 'employment.html'){$title='Careers';$description='Apply for employment with Paradigm Security Services through our existing application.'}
 if($p.path -eq 'blog.html'){$title='Blog';$description='Paradigm Security Services blog.'}
 $nav="<a href='${prefix}index.html'>Home</a>"+(Dropdown 'Services' 'services.html' $services $prefix)+(Dropdown 'Protection' 'protection.html' $protection $prefix)+"<a href='${prefix}safety.html'>Safety</a><a href='${prefix}blog.html'>Blog</a><a href='${prefix}about.html'>About</a><a href='${prefix}employment.html'>Careers</a><a href='${prefix}contact.html'>Contact</a>"
 $header="<header class='site-header'><a class='brand' href='${prefix}index.html'><img src='${prefix}assets/paradigmsecurity-logoblack.png' width='146' height='98' alt='Paradigm Security Services'></a><button class='mobile-toggle' type='button' aria-expanded='false' aria-controls='navigation'>Menu</button><nav id='navigation' aria-label='Main navigation'>$nav</nav><a class='header-phone' href='tel:+18187465432'>818-746-5432</a></header>"
 $footer="<footer><div class='footer-address'><h2>Paradigm Security Services</h2><a class='footer-phone' href='tel:+18187465432'>818-746-5432</a><p>7108 De Soto Avenue, Ste. 201A<br>Canoga Park, CA 91303</p></div><div class='footer-links'><a href='${prefix}index.html'>Home</a><a href='${prefix}services.html'>Services</a><a href='${prefix}protection.html'>Protection</a><a href='${prefix}safety.html'>Safety</a><a href='${prefix}blog.html'>Blog</a><a href='${prefix}about.html'>About</a><a href='${prefix}employment.html'>Careers</a><a href='${prefix}contact.html'>Contact</a></div><div class='footer-area'><h2>Service Areas</h2><a href='${prefix}los-angeles-county-security.html'>Los Angeles County</a><a href='${prefix}san-bernardino-county-security.html'>San Bernardino County</a><p>Office hours<br>Monday through Friday, 8 am to 5 pm</p></div><div class='copyright'>&copy; 2026 Paradigm Security Services</div></footer>"
 $breadcrumb="<a href='${prefix}index.html'>Home</a>";if($parent){$breadcrumb+="<span>/</span><a href='$prefix$parentUrl'>$parent</a>"}
 $pageHeader="<section class='page-heading'><div class='breadcrumbs'>$breadcrumb</div><h1>$(E $title)</h1><p>$(E $description)</p></section>"
 if($kind -eq 'service'){$pageHeader+="<div class='assignment-image'><img src='$prefix$image' alt='$(E $title)' fetchpriority='high'></div><div class='assignment-actions'><a class='button' href='${prefix}contact.html'>Request Security</a><button type='button' class='quiet-button' data-chat>Service Information</button></div>"}
 if($p.path -eq 'index.html'){
  $kind='home';$title='Armed and Unarmed Security Services';$description='Paradigm Security Services provides armed security, unarmed security, and protection for clients in Los Angeles County and San Bernardino County.'
  $image='assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos/twilight_estate_gate_security_checkpoint.jpg'
  $pageHeader="<section class='home-hero'><img src='$image' alt='Security officer managing access at a private property at dusk' fetchpriority='high'><div class='hero-content'><p class='hero-company'>Paradigm Security Services</p><h1>Armed &amp; Unarmed<br>Security Services</h1><p>For businesses, properties, events,<br>and private clients in Southern California.</p><a class='button white-button' href='contact.html'>Request Security</a></div></section><div class='coverage-band'><a href='los-angeles-county-security.html'>Los Angeles County</a><a href='san-bernardino-county-security.html'>San Bernardino County</a><a href='tel:+18187465432'>818-746-5432</a></div>"
  $serviceList=foreach($item in $services){"<a class='home-service-link' href='$($item.path)'><h3>$(E $item.title)</h3></a>"}
  $body="<section class='home-services'><div class='section-introduction'><p class='section-label'>Services</p><h2>Professional security,<br>defined around the assignment.</h2><p>Coverage starts with the location, the responsibilities, and the people involved. Read about each service to understand what can be discussed for your setting.</p><a class='plain-link' href='services.html'>All Services</a></div><div class='service-link-list'>$(($serviceList)-join '')</div></section><section class='home-protection'><div class='section-introduction'><p class='section-label'>Protection</p><h2>Security for the places<br>people use every day.</h2><a class='plain-link' href='protection.html'>All Protection</a></div><div class='protection-composition'><a href='protection/office-buildings.html'><img src='assets/officebuilding.webp' alt='Security officer at a commercial office property' loading='lazy'><span>Office Buildings</span></a><a href='protection/apartments.html'><img src='assets/apartmentguardhero.webp' alt='Security at an apartment community' loading='lazy'><span>Residential Communities</span></a><a href='protection/events.html'><img src='assets/article-private-event-checkin.webp' alt='Security personnel at event guest check in' loading='lazy'><span>Events</span></a></div></section><section class='home-company'><div><p class='section-label'>About Paradigm</p><h2>Serving Southern<br>California.</h2></div><div><p>Paradigm provides security services across Los Angeles County and San Bernardino County. Business owners, property managers, event organizers, and private clients can discuss the responsibilities and coverage they need directly with the team.</p><a class='plain-link' href='about.html'>About the Company</a></div></section><section class='home-editorial'><div><p class='section-label'>Blog</p><h2>Security planning,<br>in practical terms.</h2><a class='plain-link' href='blog.html'>Blog</a></div><div class='home-posts'>$(($blogPosts|Select-Object -First 2|ForEach-Object {"<a href='$($_.path)'><span>$($_.category)</span><h3>$(E $_.title)</h3></a>"})-join '')</div></section>"
 }elseif($p.path -in @('services.html','protection.html')){
  $items=if($p.path -eq 'services.html'){$services}else{$protection}
  $rows=foreach($item in $items){"<a class='service-index-item' href='$prefix$($item.path)'><img src='$prefix$(ImageFor $item)' alt='$(E $item.title)' loading='lazy'><div><h2>$(E $item.title)</h2><p>$(E (Summary $item))</p></div></a>"}
  $body="<section class='service-index'>$(($rows)-join '')</section>"
 }elseif($p.path -eq 'safety.html'){
  $rows=foreach($item in $topics){"<a class='safety-index-item' href='$prefix$($item.path)'><img src='$prefix$(ImageFor $item)' alt='$(E $item.title)' loading='lazy'><div><h2>$(E $item.title)</h2><p>$(@($item.faq[0].mainEntity).Count) security guidance</p></div></a>"}
  $body="<section class='safety-introduction'><h2>Find a safety topic</h2><p>Choose a setting or subject for information and links to the supporting educational articles.</p></section><section class='safety-index'>$(($rows)-join '')</section>"
 }elseif($p.path -eq 'blog.html'){
  $rows=foreach($item in $blogPosts){"<a class='blog-index-item' href='$prefix$($item.path)'><img src='$prefix$($item.image)' alt='$(E $item.title)' loading='lazy'><div><p class='article-category'>$(E $item.category)</p><h2>$(E $item.title)</h2><p>$(E $item.description)</p><span class='post-label'>Read Article</span></div></a>"}
  $body="<section class='blog-index'>$(($rows)-join '')</section>"
 }elseif($p.path -eq 'employment.html'){
  $body="<section class='employment-content'><div><h2>Apply to join Paradigm.</h2><p>Have your work history, availability, and relevant registration or training information ready. Opportunities depend on available assignments and the qualifications required for each role.</p><a class='button employment-apply' href='https://form.jotform.com/230926818186162' target='_blank' rel='noopener noreferrer'>Apply for Employment</a><p class='application-note'>The existing application opens on a separate Jotform page.</p></div><img src='${prefix}assets/article-armed-shift-briefing.webp' alt='Security officers reviewing assignment information' loading='lazy'></section>"
 }elseif($p.path -eq 'contact.html'){
  $body="<section class='contact-layout'><div><h2>Contact Information</h2><a class='contact-phone' href='tel:+18187465432'>818-746-5432</a><p>7108 De Soto Avenue, Ste. 201A<br>Canoga Park, CA 91303</p><p>Office hours<br>Monday through Friday, 8 am to 5 pm.<br>Office closed Saturday and Sunday.</p></div><form id='contact-form'><h2>Request a Consultation</h2><div class='form-grid'><label>First name<input name='firstname' autocomplete='given-name' required></label><label>Last name<input name='lastname' autocomplete='family-name' required></label><label>Email<input name='email' type='email' autocomplete='email' required></label><label>Phone<input name='phone' type='tel' autocomplete='tel'></label><label>City<input name='city' autocomplete='address-level2' required></label><label>Business or property name<input name='company' autocomplete='organization'></label></div><label>Coverage needs<textarea name='message' rows='5' required></textarea></label><button class='button' type='submit'>Send Inquiry</button><p id='form-status' role='status'>Online delivery is not configured. Please call 818-746-5432 to discuss coverage.</p></form></section>"
 }
 if($kind -eq 'post'){$pageHeader+="<figure class='post-image'><img src='$prefix$image' alt='$(E $title)' fetchpriority='high'></figure>"}
 # Remove leftover presentation fragments while keeping the substantive content.
 $body=[regex]::Replace($body,'(?is)<section class="v5-county-hero".*?</section>','')
 $body=[regex]::Replace($body,'(?is)<section class="p-[^"]*".*?</section>','')
 $body=[regex]::Replace($body,'<a\b[^>]*href=["'']mailto:[^"'']+["''][^>]*>.*?</a>','')
 $body=$body.Replace('desiraemduncan@gmail.com','').Replace('747 226 1335','818-746-5432').Replace('+17472261335','+18187465432')
 $body=[regex]::Replace($body,'[\u2190-\u21ff]|&#(?:8592|8593|8594|8595|8599);','')
 $body=$body.Replace('Explore','View').Replace('explore','view')
 $canonical=$p.canonical;if(!$canonical){$canonical="$domain/$($p.path)"}
 $schema=@{'@context'='https://schema.org';'@type'='WebPage';name=$title;description=$description;url=$canonical;inLanguage='en'}
 $structured=@($schema)+@($p.faq)
 if($kind -eq 'service'){$structured+=@{'@context'='https://schema.org';'@type'='Service';name=$title;url=$canonical;areaServed=@('Los Angeles County','San Bernardino County');provider=@{'@type'='Organization';name='Paradigm Security Services';telephone='+18187465432'}}}
 if($kind -eq 'post'){$structured+=@{'@context'='https://schema.org';'@type'='BlogPosting';headline=$title;description=$description;url=$canonical;image="$domain/$image";inLanguage='en';articleSection=$p.category}}
 if($p.path -eq 'blog.html'){$structured+=@{'@context'='https://schema.org';'@type'='Blog';name='Paradigm Security Blog';url=$canonical;blogPost=@($blogPosts|ForEach-Object {@{'@type'='BlogPosting';headline=$_.title;url=$_.canonical}})}}
 $json=($structured|Where-Object {$_}|ForEach-Object {"<script type='application/ld+json'>$($_|ConvertTo-Json -Depth 20 -Compress)</script>"})-join ''
 $chat[$p.path]=@{title=$title;description=$description;facts=@([regex]::Matches($body,'(?is)<p[^>]*>(.*?)</p>')|Select-Object -First 12|ForEach-Object {Plain $_.Groups[1].Value})}
 $dialog="<button class='chat-launch' type='button' data-chat>Website Guide</button><dialog id='chat-dialog' aria-labelledby='chat-title'><div class='chat-header'><h2 id='chat-title'>Website Guide</h2><button id='chat-close' type='button' aria-label='Close chat'>&times;</button></div><p class='chat-note'>Local website guide. Call 818-746-5432 for confirmed service information.</p><div id='chat-log' role='log' aria-live='polite'></div><div id='chat-suggestions'></div><form id='chat-form'><label for='chat-input'>Your message</label><div><input id='chat-input' required autocomplete='off' placeholder='Ask about this page'><button type='submit'>Send</button></div></form></dialog>"
 $html="<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'><title>$(E $title) | Paradigm Security</title><meta name='description' content='$(E $description)'><link rel='canonical' href='$canonical'><meta property='og:title' content='$(E $title) | Paradigm Security'><meta property='og:description' content='$(E $description)'><meta property='og:image' content='$domain/$image'><meta property='og:type' content='$(if($kind -eq 'post'){'article'}else{'website'})'><link rel='icon' href='${prefix}assets/favicon.svg'><link rel='stylesheet' href='${prefix}redesign/site.css'>$json<script src='${prefix}paradigm-lead-config.js' defer></script><script src='${prefix}redesign/chat-data.js' defer></script><script src='${prefix}redesign/site.js' defer></script></head><body data-page='$($p.path)' data-prefix='$prefix' class='page-$kind'><a class='skip' href='#main'>Skip to content</a>$header<main id='main'>$pageHeader<div class='page-body'>$body</div></main>$footer$dialog</body></html>"
 Save $p.path $html
}
Save 'redesign/chat-data.js' ('window.PARADIGM_PAGES='+($chat|ConvertTo-Json -Depth 12 -Compress)+';')
$urls=($pages|Where-Object path -NotIn @('404.html','pictures-to-use.html')|ForEach-Object {"<url><loc>$domain/$($_.path)</loc></url>"})-join ''
Save 'sitemap.xml' ("<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>$urls</urlset>")
Write-Output "Built $($pages.Count) pages, including $($blogPosts.Count) separate blog posts."
