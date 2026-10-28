$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
. "$PSScriptRoot/intake-profile.ps1"
$pages=Get-Content "$PSScriptRoot/rebuild-content.json" -Raw -Encoding UTF8|ConvertFrom-Json
$photos=Get-Content "$PSScriptRoot/page-photography.json" -Raw -Encoding UTF8|ConvertFrom-Json
$directory=Get-Content "$PSScriptRoot/directory-photography.json" -Raw -Encoding UTF8|ConvertFrom-Json
$topicCards=Get-Content "$PSScriptRoot/topic-cards.json" -Raw -Encoding UTF8|ConvertFrom-Json
$safetyPhotos=Get-Content "$PSScriptRoot/safety-photography.json" -Raw -Encoding UTF8|ConvertFrom-Json
$services=@($pages|Where-Object path -Like 'services/*')
$protection=@($pages|Where-Object path -Like 'protection/*')
$topics=@($pages|Where-Object path -Like 'articles/topics/*')
$homePhotos=[pscustomobject]@{'services/armed-security.html'='private_security_at_palm_lined_shopping_plaza.jpg';'services/unarmed-security.html'='security_officer_reviews_warehouse_inventory.jpg';'services/asset-protection.html'='upscale_retail_security_check_in.jpg';'services/asset-protection/vehicle-bike-patrol.html'='bicycle_patrol_reports_property_observation.jpg';'services/cannabis-and-cash-transport.html'='secure_dispensary_shipment_handoff.jpg';'services/asset-protection/cannabis-dispensaries.html'='private_security_in_a_cannabis_dispensary.jpg';'services/asset-protection/k9-narcotic-detection.html'='k9_patrol_in_an_empty_event_foyer.jpg';'services/asset-protection/loss-prevention.html'='private_security_at_store_entry.jpg'}
function E($s){[Net.WebUtility]::HtmlEncode([string]$s)}
function Photo($file,$prefix){$prefix+'assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos/'+$file}
function Menu($label,$path,$items,$prefix){$links="<a href='$prefix$path'>All $label</a>";foreach($item in $items){$links+="<a href='$prefix$($item.path)'>$(E $item.title)</a>"};"<div class='nav-group'><a href='$prefix$path'>$label</a><div class='dropdown'>$links</div></div>"}
function Cards($items,$map,$prefix){$cards=foreach($item in $items){$action=if($item.path -like 'services/*'){'View Service'}elseif($item.path -like 'protection/*'){'View Protection'}elseif($item.path -like 'articles/topics/*'){'View More'}else{'View Page'};$image=$map.PSObject.Properties[$item.path].Value;$picture=if($image){"<img src='$(E (Photo $image $prefix))' alt='$(E $item.title)' loading='lazy'>"}else{''};"<a class='image-card' href='$prefix$($item.path)'>$picture<div><h2>$(E $item.title)</h2><span class='read-more'>$action</span></div></a>"};"<div class='image-cards'>$(($cards)-join '')</div>"}
foreach($p in $pages){
 $path=$p.path;$prefix='../'*(($path.Split('/')).Count-1);$title=$p.title
 $header="<header class='site-header' id='header'><div class='header-inner'><a class='brand' href='${prefix}index.html' aria-label='Paradigm Security Services home'><img src='${prefix}assets/reference/asset-18.png' alt='Paradigm Security Services' width='1264' height='844'></a><nav id='navigation' aria-label='Main navigation'><a href='${prefix}index.html'>Home</a><a href='${prefix}about.html'>About</a>$(Menu 'Services' 'services.html' $services $prefix)$(Menu 'Protection' 'protection.html' $protection $prefix)<a href='${prefix}safety.html'>Safety</a><a href='${prefix}blog.html'>Blog</a><a href='${prefix}contact.html'>Contact</a><a href='${prefix}employment.html'>Careers</a></nav><span class='header-license'>California License<br><strong># PP0120139</strong></span><a class='header-phone' href='tel:+18187465432'>818-746-5432</a></div></header>"
 $footer="<footer class='site-footer'><div class='footer-grid'><div class='footer-intro'><p class='footer-name'>Paradigm<br>Security Services.</p><a class='footer-phone' href='tel:+18187465432'>818-746-5432</a><p>License # PP0120139</p></div><div><h2>Service Areas</h2><a href='${prefix}los-angeles-county-security.html'>Los Angeles County</a><a href='${prefix}san-bernardino-county-security.html'>San Bernardino County</a></div><div><h2>Company</h2><a href='${prefix}about.html'>About</a><a href='${prefix}contact.html'>Contact</a><a href='${prefix}employment.html'>Careers</a></div><div><h2>Security</h2><a href='${prefix}services.html'>Services</a><a href='${prefix}protection.html'>Protection</a><a href='${prefix}safety.html'>Safety</a></div></div><div class='footer-bottom'><span>&copy; 2026 Paradigm Security Services. All rights reserved.</span><span class='design-credit'>SEO and Website Design by <a href='https://www.startweb7.com/'>StartWeb7</a></span></div></footer>"
 $body=$p.body
 # Remove presentation inherited from earlier builds; retain the actual information.
 $body=[regex]::Replace($body,'(?is)<section\b(?=[^>]*class=["''][^"'']*(?:v5-overview-hero|v5-county-hero|v5-location-hero|topic-hero)[^"'']*["''])[^>]*>.*?</section>','')
 $body=[regex]::Replace($body,'(?is)<(?:figure|video)\b.*?</(?:figure|video)>|<img\b[^>]*>','')
 $body=[regex]::Replace($body,'(?is)<h1\b[^>]*>.*?</h1>','')
 $body=[regex]::Replace($body,'(?is)<(?:style|script)\b.*?</(?:style|script)>','')
 $body=[regex]::Replace($body,'(?is)<span class="v5-index">.*?</span>','')
 $commercial=$path -like 'services/*' -or $path -like 'protection/*' -or $path -eq 'security.html'
 if($commercial){$body=[regex]::Replace($body,'(?is)<(?:section|aside)\b(?=[^>]*class=["''][^"'']*(?:references|related-articles|article-related|further-reading)[^"'']*["''])[^>]*>.*?</(?:section|aside)>','');$body=[regex]::Replace($body,'(?is)<sup\b.*?</sup>|<a\b(?=[^>]*href=["''][^"'']*articles/)[^>]*>.*?</a>','')}
 $category=if($path -like 'services/*'){'Security Services'}elseif($path -like 'protection/*'){'Protection'}elseif($path -like 'articles/*'){'Safety'}elseif($path -like 'locations/*'){'Local Security'}else{'Paradigm Security Services'}
 $categoryPath=if($path -like 'services/*'){'services.html'}elseif($path -like 'protection/*'){'protection.html'}elseif($path -like 'articles/*'){'safety.html'}else{'index.html'}
 $heading="<section class='page-title'><div class='title-inner'><h1>$(E $title)</h1></div></section>"
 $image=$photos.PSObject.Properties[$path].Value
 $feature=if($image){"<figure class='feature-photo'><img src='$(E (Photo $image $prefix))' alt='$(E $title)' fetchpriority='high'></figure>"}else{''}
 if($path -eq 'services/asset-protection/k9-narcotic-detection.html'){$feature="<figure class='feature-photo'><img src='${prefix}assets/client-photos/k9hero.jpg' alt='Security K9 with handler' fetchpriority='high'></figure>"}
 if($path -eq 'services/armed-security.html'){$feature="<figure class='feature-photo'><img src='${prefix}assets/client-photos/Private-Armed-Security-DC.jpg' alt='Armed security officer and K9' fetchpriority='high'></figure>"}
 $intro=[regex]::Match($body,'(?is)<p\b[^>]*>.*?</p>');$lead=if($intro.Success){$intro.Value}else{''}
 if($intro.Success){$body=$body.Remove($intro.Index,$intro.Length)}
 $assignmentTitle="<div class='assignment-title'><h1>$(E $title)</h1><div class='assignment-lead'>$lead</div><a class='button' href='${prefix}contact.html'>Request Security</a></div>"
 $main="<section class='assignment-hero'>$feature$assignmentTitle</section><div class='service-board'>$body</div>"
 $videoFile=if($path -eq 'services/asset-protection.html'){'asset-protection'}elseif($path -eq 'protection/private-homes-estates.html'){'private-estate'}else{''}
 if($videoFile){$main="<section class='home-motion-hero assignment-video'><video data-ambient-video autoplay muted loop playsinline preload='metadata' poster='${prefix}assets/videos/$videoFile-poster.jpg' aria-label='$(E $title) video'><source src='${prefix}assets/videos/$videoFile.mp4' type='video/mp4'></video><div class='motion-copy'><h1>$(E $title)</h1><a class='button' href='${prefix}contact.html'>Request Security</a></div><button type='button' class='video-toggle' data-video-toggle>Pause video</button></section><div class='assignment-introduction'>$lead</div><div class='service-board'>$body</div>"}
 if($path -in @('services.html','protection.html','safety.html')){$items=if($path -eq 'services.html'){$services}elseif($path -eq 'protection.html'){$protection}else{$topics};$map=if($path -eq 'safety.html'){$safetyPhotos}else{$directory};$main="$heading<div class='directory-intro'><p>$(if($path -eq 'services.html'){'Professional security services, with duties defined for each assignment.'}elseif($path -eq 'protection.html'){'Security planned for your property, your activity, and the people you serve.'}else{'Practical information about security responsibilities, planning, and everyday concerns.'})</p></div><section class='directory'>$(Cards $items $map $prefix)</section>"}
 if($path -like 'articles/topics/*'){
  $cards=foreach($card in $topicCards.PSObject.Properties[$path].Value){"<a class='image-card safety-topic-section' href='$(E $card.href)'><img src='$(E (Photo $card.image $prefix))' alt='$(E $card.title)' loading='lazy'><div><h2>$(E $card.title)</h2><span class='read-more'>View More</span></div></a>"}
  $main="$heading<section class='directory safety-topic-gallery'><div class='image-cards'>$(($cards)-join '')</div></section>"
 }
 if($path -eq 'index.html'){
  $title='Paradigm Security Services'
  $homeItems=@($services|Where-Object path -in @('services/armed-security.html','services/unarmed-security.html','services/asset-protection.html','services/asset-protection/vehicle-bike-patrol.html'))
  $main="<section class='home-motion-hero'><video data-ambient-video autoplay muted loop playsinline preload='metadata' poster='assets/videos/home-hero-v2-poster.jpg' aria-label='Paradigm security video'><source src='assets/videos/home-hero-v2.mp4' type='video/mp4'></video><div class='motion-copy'><p class='eyebrow'>LOS ANGELES &amp; SAN BERNARDINO COUNTIES</p><h1>Paradigm<br><em>Security Services</em></h1><p class='hero-description'>Professional security for the people and places that matter to you.</p><a class='button' href='contact.html'>Request Security</a></div><button type='button' class='video-toggle' data-video-toggle>Pause video</button></section><div class='credentials content-width'><span>Licensed &amp; Insured</span><span>California License # PP0120139</span><a href='tel:+18187465432'>818-746-5432</a></div><section class='home-service-gallery content-width'><div class='gallery-heading'><h2>Our Services</h2></div>$(Cards $services $homePhotos '')</section><section class='company-statement content-width'><h2>About Paradigm</h2><p class='company-priority'>Our first priority is to safeguard the lives and property of everyone we serve.</p><p>Founded by a former police officer, Paradigm provides licensed and insured security throughout Los Angeles County and San Bernardino County.</p><a class='button' href='about.html'>Our Story</a></section>"
 }
 if($path -eq 'about.html'){$main="$heading<figure class='about-photo'><img src='assets/reference/asset-14.jpg' alt='Two Paradigm Security officers outside a client property' fetchpriority='high'></figure><section class='about-story content-width'><p class='eyebrow'>OUR STORY</p><h2>Our Story</h2><div class='story-columns'><p>As your professional security providers, our first priority is to safeguard the lives and property of everyone we serve.</p><p>Paradigm Security Services provides licensed and insured coverage throughout Los Angeles County and San Bernardino County. We define each assignment around the people, property, access rules, and responsibilities involved.</p></div><div class='company-values'><article><h3>Our Beginnings</h3><p>Paradigm began as a personal call to serve communities in Los Angeles County and San Bernardino County. The company was established by a former police officer after leaving the LAPD to focus more closely on local businesses and communities.</p></article><article><h3>Our Team</h3><p>Professional conduct, situational awareness, and de-escalation guide the work. Personnel receive training in public and employee relations, observation, recognition skills, written reports, and arrest procedures. Licensing, experience, and qualifications are confirmed for each proposed assignment.</p></article><article><h3>Professional Standards</h3><p>Paradigm uses a screening process that includes background and criminal record checks and drug screening. Coverage, responsibilities, and personnel capabilities are confirmed for each property.</p></article></div><a class='button' href='contact.html'>Contact Paradigm</a></section>"}
 if($path -eq 'contact.html'){$main="$heading<section class='contact-layout content-width'><h2>Tell us what you need.</h2><a class='contact-phone' href='tel:+18187465432'>818-746-5432</a><p>7108 De Soto Avenue, Ste. 201A<br>Canoga Park, CA 91303</p><p>Monday-Friday, 8 am-5 pm</p><a class='button' href='contact.html'>Get Security for Your Property</a></section>"}
 if($path -eq 'employment.html'){$main="<section class='careers-layout content-width'><div><h1>Careers</h1><h2>Apply for employment with Paradigm Security.</h2><a class='button employment-apply' href='https://form.jotform.com/230926818186162' target='_blank' rel='noopener noreferrer'>Apply for Employment</a></div><img src='$(E (Photo 'professional_security_guard_portrait.jpg' ''))' alt='Paradigm security professional'></section>"}
 if($path -eq 'blog.html'){$main="<h1>Blog</h1><div class='blank-blog'></div>"}
 if($path -eq '404.html'){$main="<section class='not-found content-width'><h1>Page Not Found</h1><a class='button' href='index.html'>Home</a></section>"}
 if($path -like 'articles/topics/*'){
  $cards=foreach($card in $topicCards.PSObject.Properties[$path].Value){"<a class='image-card safety-topic-section' href='$(E $card.href)'><img src='$(E (Photo $card.image $prefix))' alt='$(E $card.title)' loading='lazy'><div><h2>$(E $card.title)</h2><span class='read-more'>View More</span></div></a>"}
  $main="$heading<section class='directory safety-topic-gallery'><div class='image-cards'>$(($cards)-join '')</div></section>"
 }
 if($path -in @('los-angeles-county-security.html','san-bernardino-county-security.html')){
  $cityLinks=[regex]::Matches($body,'(?is)<a class="city-directory-row" href="([^"]+)"><h3>(.*?)</h3>.*?</a>')
  $cityCards=foreach($city in $cityLinks){$photoName='southern_california_office_campus_security_at_dusk.jpg';"<a class='image-card' href='$(E $city.Groups[1].Value)'><img src='$(E (Photo $photoName $prefix))' alt='Security coverage for $(E $city.Groups[2].Value)' loading='lazy'><div><h2>$(E $city.Groups[2].Value)</h2><span class='read-more'>View City</span></div></a>"}
  $main="$heading<section class='directory county-city-gallery'><div class='image-cards'>$(($cityCards)-join '')</div></section>"
 }
 if($path -eq 'index.html'){$labels=@('Marked Vehicle Patrol','Loss Prevention','Executive Protection','Extensively Trained Personnel','High Risk Urban Security');$run=($labels|ForEach-Object {"<span>$_</span>"})-join '';$main+="<div class='service-marquee' aria-label='Additional security services'><div class='marquee-track'><div>$run</div><div aria-hidden='true'>$run</div></div></div>"}
 if($false){$main+="<figure class='support-photo'><img src='${prefix}assets/client-photos/estate5.png' alt='Security officer at a private estate entrance' loading='lazy'></figure>"}
 $main=[regex]::Replace($main,'(?is)<(?:a|p) class=''eyebrow''[^>]*>.*?</(?:a|p)>','')

 if($path -eq 'contact.html'){$main="<figure class='feature-photo'><img src='${prefix}assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos/welcoming_security_officer_at_office_reception.jpg' alt='Professional security at a reception area' fetchpriority='high'></figure>"+$main}
 # Keep one centered title before each page's hero media.
 $main=[regex]::Replace($main,'(?is)<sup\b[^>]*>.*?</sup>','')
 $main=[regex]::Replace($main,'(?is)(<section[^>]*class=["'']references["''][^>]*>.*?)(</section>)',[Text.RegularExpressions.MatchEvaluator]{param($m)$m.Value.Replace('<ol>','<ul>').Replace('</ol>','</ul>')})
 if($path -notin @('employment.html','index.html')){
  $pageH1=[regex]::Match($main,'(?is)<h1\b[^>]*>.*?</h1>')
  if($pageH1.Success){
   $main=$main.Remove($pageH1.Index,$pageH1.Length)
   $main=[regex]::Replace($main,"(?is)<section class='page-title'><div class='title-inner'>\s*</div></section>",'')
   $main="<section class='page-title centered-page-title'>$($pageH1.Value)</section>"+$main
  }
 }
 $profile=Get-IntakeProfile $path $title
 $cta="<button type='button' class='button context-cta' data-open-intake>$(E $profile.label)</button>"
 $main=[regex]::Replace($main,"(?is)<a\b(?=[^>]*href=['\""']"+[regex]::Escape($prefix+'contact.html')+"['\""'])[^>]*>.*?</a>",[Text.RegularExpressions.MatchEvaluator]{param($match)$cta})
 $footer="<footer class='site-footer clear-footer'><div class='footer-contact'><p class='footer-name'>Paradigm Security Services</p><a class='footer-call' href='tel:+18187465432'>818-746-5432</a></div><nav class='footer-links' aria-label='Footer navigation'><a href='${prefix}services.html'>Our Services</a><a href='${prefix}protection.html'>Protection</a><a href='${prefix}safety.html'>Safety</a><a href='${prefix}about.html'>About Paradigm</a><a href='${prefix}contact.html'>Contact</a><a href='${prefix}employment.html'>Careers</a><a href='${prefix}los-angeles-county-security.html'>Los Angeles County Security</a><a href='${prefix}san-bernardino-county-security.html'>San Bernardino County Security</a></nav><div class='footer-bottom'><span>&copy; 2026 Paradigm Security Services. License # PP0120139.</span><span class='design-credit'>SEO and Website Design by <a href='https://www.startweb7.com/'>StartWeb7</a></span></div></footer>"
 if($path -ne 'employment.html' -and $main -notmatch '(?is)<button[^>]*data-open-intake[^>]*>[^<]*</button>\s*(?:</(?:section|div|article)>\s*)*$'){$main+="<section class='page-action'>$cta</section>"}
 $profileJson=($profile|ConvertTo-Json -Depth 8 -Compress).Replace('<','\u003c')
 $chat="<script type='application/json' id='intake-profile'>$profileJson</script><dialog id='security-intake' aria-labelledby='intake-title'><header class='intake-heading'><h2 id='intake-title'>$(E $title)</h2><button type='button' data-intake-close aria-label='Close chat'>Close</button></header><p class='intake-intro'>Tell us about the coverage you need.</p><div class='intake-log' data-intake-log role='log' aria-live='polite'></div><form class='intake-form'><label class='visually-hidden' for='intake-answer'>Your reply</label><textarea id='intake-answer' name='answer' rows='2' maxlength='2000' required></textarea><div class='intake-form-actions'><button type='button' data-intake-back>Back</button><button class='button' type='submit'>Continue</button></div></form><div class='intake-review' data-intake-review></div><p class='intake-status' data-intake-status role='status'></p></dialog>"
 $canonical=if($p.canonical){$p.canonical}else{'https://paradigmsecurityservices.com/'+$path}
 $schema=@{'@context'='https://schema.org';'@type'='WebPage';name=$title;url=$canonical;inLanguage='en'}|ConvertTo-Json -Compress
 $html="<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>$(E $title) | Paradigm Security</title><meta name='description' content='$(E $p.description)'><link rel='canonical' href='$canonical'><meta property='og:title' content='$(E $title)'><meta property='og:description' content='$(E $p.description)'><link rel='icon' href='${prefix}assets/favicon.svg'><link rel='stylesheet' href='${prefix}assets/reference/fonts.css'><link rel='stylesheet' href='${prefix}redesign/paradigm.css?v=20261021-1'><script type='application/ld+json'>$schema</script><script src='${prefix}paradigm-lead-config.js' defer></script><script src='${prefix}redesign/new-site.js' defer></script><script src='${prefix}redesign/question-chat.js' defer></script></head><body data-page='$path'><a class='skip-link' href='#main'>Skip to content</a>$header<main id='main'>$main</main>$footer$chat</body></html>"
 $target=Join-Path $root $path;[IO.File]::WriteAllText($target,$html,(New-Object Text.UTF8Encoding $false))
}
Write-Output "Rebuilt all $($pages.Count) pages with the new design."
& "$PSScriptRoot/curate-photography.ps1"
& "$PSScriptRoot/apply-photo-variety.ps1"
& "$PSScriptRoot/build-october21-blogs.ps1"



& "$PSScriptRoot/apply-feedback-corrections.ps1"
