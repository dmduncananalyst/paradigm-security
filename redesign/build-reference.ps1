$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$encoding=New-Object Text.UTF8Encoding $false
$assets=Get-Content (Join-Path $PSScriptRoot 'reference/assets.json') -Raw -Encoding UTF8|ConvertFrom-Json
$reference=@{}
foreach($name in @('home','about','contact')){$snapshot=Join-Path $PSScriptRoot "reference/$name-rendered.html";if(!(Test-Path $snapshot)){$snapshot=Join-Path $PSScriptRoot "reference/$name.html"};$reference[$name]=Get-Content $snapshot -Raw -Encoding UTF8}
$catalogue=Get-Content (Join-Path $PSScriptRoot 'content.json') -Raw -Encoding UTF8|ConvertFrom-Json
$services=@($catalogue|Where-Object path -Like 'services/*')
$protection=@($catalogue|Where-Object path -Like 'protection/*')
$pagePhotos=Get-Content (Join-Path $PSScriptRoot 'page-photography.json') -Raw -Encoding UTF8|ConvertFrom-Json
$safetyPhotos=Get-Content (Join-Path $PSScriptRoot 'safety-photography.json') -Raw -Encoding UTF8|ConvertFrom-Json
$directoryPhotos=Get-Content (Join-Path $PSScriptRoot 'directory-photography.json') -Raw -Encoding UTF8|ConvertFrom-Json
$heroTemplate=[regex]::Match($reference['about'],'(?is)<section\b(?=[^>]*data-test="page-section")[^>]*>.*?</section>').Value
function Encode($value){[Net.WebUtility]::HtmlEncode([string]$value)}
function NavItem($label,$path,$prefix){"<div class='header-nav-item header-nav-item--collection'><a href='$prefix$path'>$label</a></div>"}
function Menu($label,$path,$items,$prefix){$links="<a href='$prefix$path'>All $label</a>";foreach($item in $items){$links+="<a href='$prefix$($item.path)'>$(Encode $item.title)</a>"};"<div class='header-nav-item header-nav-item--folder nav-group'><a class='header-nav-folder-title' href='$prefix$path'>$label</a><button class='nav-toggle' type='button' aria-label='Show $label menu' aria-expanded='false'>Menu</button><div class='header-nav-folder-content dropdown'>$links</div></div>"}
$contactForm=@'
<form id='contact-form' class='local-reference-form'><label>Company Name <span>(required)</span><input name='company' autocomplete='organization' required></label><fieldset><legend>Name</legend><div class='form-grid'><label>First Name <span>(required)</span><input name='firstname' autocomplete='given-name' required></label><label>Last Name <span>(required)</span><input name='lastname' autocomplete='family-name' required></label></div></fieldset><label>Email <span>(required)</span><input name='email' type='email' autocomplete='email' required></label><label>Phone <span>(required)</span><input name='phone' type='tel' autocomplete='tel' required></label><fieldset class='reason-field'><legend>Reason for Contact <span>(required)</span></legend><label><input type='checkbox' name='reason' value='Security Services'> Security Services</label><label><input type='checkbox' name='reason' value='Property Solutions'> Property Solutions</label></fieldset><label>Anything you'd like to share with us about your needs?<textarea name='message' rows='4'></textarea></label><div class='reference-form-submit'><button class='reference-outline-button' type='submit'>Send Information Request</button></div><p id='form-status' role='status'>Online delivery is not configured. Please call 818-746-5432.</p></form>
'@
$files=@(Get-ChildItem -Recurse -Filter *.html|Where-Object FullName -NotMatch '\\redesign\\')
foreach($file in $files){
 $path=$file.FullName.Substring($root.Length+1).Replace('\','/');$prefix='../'*(($path.Split('/')).Count-1)
 $generated=Get-Content $file.FullName -Raw -Encoding UTF8
 $name=switch($path){'index.html'{'home'}'about.html'{'about'}'contact.html'{'contact'}default{'about'}}
 $isReference=$path -in @('index.html','about.html','contact.html')
 $html=$reference[$name]
 $sourceHead=[regex]::Match($html,'(?is)<head\b[^>]*>(.*?)</head>').Groups[1].Value
 $links=([regex]::Matches($sourceHead,'<link[^>]+rel="stylesheet"[^>]*>')|ForEach-Object Value)-join ''
 $headStyles=([regex]::Matches($sourceHead,'(?is)<style\b.*?</style>')|Where-Object {$_.Value -notmatch '@font-face'}|ForEach-Object Value)-join ''
 $meta=([regex]::Matches($generated,'(?is)<title>.*?</title>|<meta\b[^>]*>|<link rel=''canonical''[^>]*>|<script type=''application/ld\+json''>.*?</script>')|ForEach-Object Value)-join ''
 $head="<head>$meta$links$headStyles<link rel='stylesheet' href='${prefix}assets/reference/fonts.css'><link rel='stylesheet' href='${prefix}redesign/site.css'><link rel='icon' href='${prefix}assets/favicon.svg'></head>"
 $html=[regex]::Replace($html,'(?is)<head\b.*?</head>',[Text.RegularExpressions.MatchEvaluator]{param($m)$head},1)
 if(!$isReference){
  $title=[Net.WebUtility]::HtmlDecode([regex]::Match($generated,'(?is)<h1\b[^>]*>(.*?)</h1>').Groups[1].Value)
  $body=[regex]::Match($generated,"(?is)<div class='page-body'>(.*?)</div></main>").Groups[1].Value
  $body=[regex]::Replace($body,'(?is)<figure\b.*?</figure>|<video\b.*?</video>|<img\b[^>]*>','')
  $body=[regex]::Replace($body,'(?is)<section class="(?:v5-article-hero|article-hero|topic-hero)".*?</section>','')
  $body=[regex]::Replace($body,'(?is)<h[1-6]\b[^>]*>\s*Questions(?:\s+and\s+answers)?\s*</h[1-6]>','')
  $body=[regex]::Replace($body,'(?is)<header class="article-heading"[^>]*>(.*?)</header>',[Text.RegularExpressions.MatchEvaluator]{param($m)([regex]::Matches($m.Groups[1].Value,'(?is)<p class="article-lead"[^>]*>.*?</p>')|ForEach-Object Value)-join ''})
  if($path -like 'services/*' -or $path -like 'protection/*' -or $path -in @('services.html','protection.html','security.html')){
   $body=[regex]::Replace($body,'(?is)<(?:section|aside)\b(?=[^>]*class=["''][^"'']*\b(?:references|related-articles|article-related|further-reading)\b)[^>]*>.*?</(?:section|aside)>','')
   $body=[regex]::Replace($body,'(?is)<sup\b[^>]*>.*?</sup>','')
   $body=[regex]::Replace($body,'(?is)<a\b(?=[^>]*href=["''][^"'']*articles/)[^>]*>.*?</a>','')
   $body=[regex]::Replace($body,'(?is)<(?:h[1-6]|p)\b[^>]*>\s*(?:Further Reading|Related Articles|References)\s*</(?:h[1-6]|p)>','')
  }
  $assignment=$pagePhotos.PSObject.Properties[$path]
  $hero=''
  if($assignment){
   $photo=$prefix+'assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos/'+$assignment.Value
   $hero="<section class='reference-photo-hero' aria-label='$(Encode $title)'><img src='$(Encode $photo)' alt='$(Encode $title)' fetchpriority='high'><div class='reference-photo-title'><h1>$(Encode $title)</h1></div></section>"
   $head=[regex]::Replace($head,"<meta property='og:image' content='[^']*'",("<meta property='og:image' content='https://www.paradigmsecurityservices.com/assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos/"+$assignment.Value+"'"))
   $html=[regex]::Replace($html,'(?is)<head\b.*?</head>',[Text.RegularExpressions.MatchEvaluator]{param($m)$head},1)
  }
  if($path -in @('services.html','protection.html','safety.html')){
   $items=switch($path){'services.html'{$services}'protection.html'{$protection}'safety.html'{$catalogue|Where-Object path -Like 'articles/topics/*'}}
   $links=foreach($item in $items){$label=$item.title -replace ' Articles$','';$picture='';$photoMap=if($path -eq 'safety.html'){$safetyPhotos}else{$directoryPhotos};$filename=$photoMap.PSObject.Properties[$item.path].Value;if($filename){$src=$prefix+'assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos/'+$filename;$picture="<img src='$(Encode $src)' alt='$(Encode $label)' loading='lazy'>"};if($item.path -eq 'articles/topics/banking-transport-cannabis.html'){$label='Bank, Cash Transport, and Cannabis Security'};$action=if($path -eq 'safety.html'){'Read More'}else{'View'};"<a href='$prefix$($item.path)'>$picture<h2>$(Encode $label)</h2><span class='card-action'>$action</span></a>"}
   $body="<section class='reference-link-directory'><div class='reference-link-grid'>$(($links)-join '')</div></section>"
  }
  $intro=''
  if($path -like 'services/*' -or $path -like 'protection/*'){
   $source=Get-Content (Join-Path $PSScriptRoot "originals/$path") -Raw -Encoding UTF8
   $summary=[Net.WebUtility]::HtmlDecode([regex]::Replace([regex]::Match($source,'(?is)<section class="v5-assignment-summary">(.*?)</section>').Groups[1].Value,'<[^>]+>','')).Trim()
   $sentences=@([regex]::Split($summary,'(?<=\.)\s+'));$middle=[int][Math]::Ceiling($sentences.Count/2)
   if($summary){$left=($sentences|Select-Object -First $middle)-join ' ';$right=($sentences|Select-Object -Skip $middle)-join ' ';$intro="<section class='reference-story-intro'><p>$(Encode $left)</p><p>$(Encode $right)</p></section>"}
  }
  $main="<main id='page' class='container local-page has-reference-hero' role='main'>$hero$intro<div class='reference-derived-content'>$body</div></main>"
  if($path -notin @('employment.html','safety.html','blog.html','404.html')){$main=$main.Replace('has-reference-hero','has-reference-hero rebuilt-interior')}
  if($path -eq 'blog.html'){$main="<main id='page' class='container blank-blog' role='main'><h1 class='visually-hidden'>Blog</h1></main>"}
  if($path -eq '404.html'){$main="<main id='page' class='container local-page' role='main'><section class='page-heading'><h1>Page Not Found</h1><a href='${prefix}index.html'>Home</a></section></main>"}
  $html=[regex]::Replace($html,'(?is)<main\b.*?</main>',[Text.RegularExpressions.MatchEvaluator]{param($m)$main},1)
 }
 if($path -eq 'contact.html'){if($html -match '<form\b'){$html=[regex]::Replace($html,'(?is)<form\b.*?</form>',[Text.RegularExpressions.MatchEvaluator]{param($m)$contactForm},1)}else{$html=[regex]::Replace($html,'<div class="sqs-site-style-form"[^>]*>',[Text.RegularExpressions.MatchEvaluator]{param($m)$m.Value+$contactForm},1)}}
 # The published runtime submits to Squarespace and loads analytics. Use only local interactions.
 $html=[regex]::Replace($html,'(?is)<script\b(?![^>]*type=''application/ld\+json'').*?</script>','')
 $html=[regex]::Replace($html,'(?is)<noscript\b.*?</noscript>','')
 $nav=(NavItem 'Home' 'index.html' $prefix)+(NavItem 'About' 'about.html' $prefix)+(Menu 'Services' 'services.html' $services $prefix)+(Menu 'Protection' 'protection.html' $protection $prefix)+(NavItem 'Safety' 'safety.html' $prefix)+(NavItem 'Blog' 'blog.html' $prefix)+(NavItem 'Contact' 'contact.html' $prefix)+(NavItem 'Careers' 'employment.html' $prefix)
 $desktop="<nav class='header-nav-list'>$nav</nav>"
 $localHeader="<header id='header' class='local-header'><div class='header-inner'><a class='local-brand' href='${prefix}index.html' aria-label='Paradigm Security Services home'><img src='${prefix}assets/reference/asset-18.png' alt='Paradigm Security Services' width='1264' height='844'></a>$desktop<a class='local-license' href='${prefix}about.html'>License# PP0120139</a></div></header>"
 $headerPattern=New-Object Text.RegularExpressions.Regex '(?is)<header\b.*?</header>'
 $html=$headerPattern.Replace($html,[Text.RegularExpressions.MatchEvaluator]{param($m)$localHeader},1)
 $mobile="<button class='mobile-toggle' type='button' aria-expanded='false' aria-controls='navigation'>Menu</button></header><nav id='navigation' class='local-mobile-navigation' aria-label='Mobile navigation'>$nav</nav>"
 $html=$html.Replace('</header>',$mobile)
 $html=[regex]::Replace($html,'<body\b([^>]*)>',[Text.RegularExpressions.MatchEvaluator]{param($m)"<body$($m.Groups[1].Value) data-page='$path' data-prefix='$prefix'>"},1)
 # Keep all reference spacing, grid definitions, and image components; localize their URLs.
 foreach($asset in $assets){
  $url=$asset.url.TrimEnd('"');$local=$prefix+$asset.path
  if($asset.url.EndsWith('"')){continue}
  $pattern=[regex]::Escape($url)
  if($url.StartsWith('https://images.')){
   $pattern=$pattern.Replace('https://','(?:https:)?//')+'(?:\?[^\s"''<>]*)?'
  }
  $html=[regex]::Replace($html,$pattern,[Text.RegularExpressions.MatchEvaluator]{param($m)$local})
 }
 $routes=@{'/'='index.html';'/about'='about.html';'/security-services'='security.html';'/services'='services.html';'/protection'='protection.html';'/contact'='contact.html';'/banks-2-2-1'='services/armed-security.html';'/cart'='contact.html';'/blog'='blog.html'}
 foreach($route in $routes.Keys){$html=$html.Replace(('href="'+$route+'"'),('href="'+$prefix+$routes[$route]+'"'))}
 $html=$html.Replace('href="https://form.jotform.com/230926818186162"',('href="'+$prefix+'employment.html"'))
 $html=[regex]::Replace($html,'747\s*[- ]\s*226\s*[- ]\s*1335','818-746-5432')
 $html=$html.Replace('+17472261335','+18187465432').Replace('7472261335','8187465432')
 $html=[regex]::Replace($html,'(?is)<a[^>]+href=["'']mailto:[^"'']+["''][^>]*>.*?</a>','')
 $html=$html.Replace('desiraemduncan@gmail.com','')
 $footer="<footer id='footer-sections' class='local-footer'><div class='footer-columns'><div class='footer-brand'><a href='${prefix}index.html'><img src='${prefix}assets/reference/asset-18.png' alt='Paradigm Security Services' width='1264' height='844'></a><a href='tel:+18187465432'>818-746-5432</a></div><div><h2>Service Area</h2><p>Los Angeles County<br>San Bernardino County</p></div><nav aria-label='Footer services'><h2>Learn</h2><a href='${prefix}services.html'>Security Services</a><a href='${prefix}about.html'>Our Story</a><a href='${prefix}safety.html'>Safety</a></nav><nav aria-label='Footer contact'><h2>Connect</h2><a href='${prefix}contact.html'>Contact</a><a href='${prefix}employment.html'>Careers</a></nav></div><div class='footer-bottom'><p>&copy; 2026 Paradigm Security Services. All Rights Reserved.</p><p>SEO managed by <a href='https://startweb7.com/'>StartWeb7</a></p></div></footer>"
 $html=[regex]::Replace($html,'(?is)<footer\b.*?</footer>',[Text.RegularExpressions.MatchEvaluator]{param($m)$footer},1)
 # Keep the requested rendering while avoiding duplicate top-level headings.
 $script:headingCount=0
 $html=[regex]::Replace($html,'(?is)<h1\b([^>]*)>(.*?)</h1>',[Text.RegularExpressions.MatchEvaluator]{param($m)$script:headingCount++;if($script:headingCount -eq 1){return $m.Value};$attrs=$m.Groups[1].Value;if($attrs -match 'class="'){ $attrs=$attrs.Replace('class="','class="reference-h1 ')}else{$attrs+=' class="reference-h1"'};return '<h2'+$attrs+'>'+$m.Groups[2].Value+'</h2>'})
 if($script:headingCount -eq 0){$script:promoted=$false;$html=[regex]::Replace($html,'(?is)<h2\b([^>]*)>(.*?)</h2>',[Text.RegularExpressions.MatchEvaluator]{param($m)if($script:promoted){return $m.Value};$script:promoted=$true;return '<h1 class="reference-h2"'+$m.Groups[1].Value+'>'+$m.Groups[2].Value+'</h1>'},1)}
 $html=$html.Replace('We will not hire anyone that has a serious criminal record or a history of mental illness.','Qualifications are reviewed for the requirements of each assignment.')
 $html=$html.Replace('Insurance and Project Continuity Address Different Questions','Insurance and Project Continuity Have Different Roles')
 if($path -eq 'index.html'){
  $html=$html.Replace('id="block-yui_3_17_2_1_1764478482531_3210"','id="block-yui_3_17_2_1_1764478482531_3210" data-restored-presentation="original"')
  $html=[regex]::Replace($html,'<img\b(?=[^>]*src="assets/reference/asset-8.jpg")[^>]*>',[Text.RegularExpressions.MatchEvaluator]{param($m)$m.Value.Replace('<img ','<img class="restored-reference-photo" ')})
 }

 $runtime="<script src='${prefix}paradigm-lead-config.js' defer></script><script src='${prefix}redesign/site.js' defer></script>"
 $html=$html.Replace('</body>',($runtime+'</body>'))
 [IO.File]::WriteAllText($file.FullName,$html,$encoding)
}
Write-Output "Applied the live website design to $($files.Count) local pages."
