function Get-IntakeProfile($path,$title){
 $kind='property';$label='Get Security for Your Property'
 $text=($path+' '+$title).ToLowerInvariant()
 if($text -match 'vehicle|bike|patrol'){$kind='patrol';$label='Get Vehicle and Bike Patrol'}
 elseif($text -match 'hospital|medical|clinic'){$kind='medical';$label='Get Hospital and Medical Facility Security'}
 elseif($text -match 'construction|warehouse|loading'){$kind='construction';$label='Get Construction Site Security'}
 elseif($text -match 'private-homes|estate|homes-estates'){$kind='estate';$label='Get Private Estate Security'}
 elseif($text -match 'apartment|residential'){$kind='residential';$label='Get Residential Community Security'}
 elseif($text -match 'school|campus'){$kind='school';$label='Get School and Campus Security'}
 elseif($text -match 'cannabis-and-cash|cash-transport|banking-transport'){$kind='transport';$label='Arrange Secure Transport'}
 elseif($text -match 'dispensar|cannabis'){$kind='dispensary';$label='Get Dispensary Security'}
 elseif($text -match 'bank|financial|atm'){$kind='bank';$label='Get Bank Security'}
 elseif($text -match 'k9|narcotic'){$kind='k9';$label='Arrange K9 Detection'}
 elseif($text -match 'loss-prevention|retail|shopping|mall'){$kind='retail';$label='Get Retail Security'}
 elseif($text -match 'film|production'){$kind='production';$label='Get Production Security'}
 elseif($text -match 'event|gala'){$kind='event';$label='Get Event Security'}
 elseif($text -match 'individual|executive|personal-protection|stalking'){$kind='personal';$label='Get Personal Protection'}
 elseif($text -match 'unarmed'){$kind='unarmed';$label='Get Unarmed Security'}
 elseif($text -match 'armed'){$kind='armed';$label='Get Armed Security'}
 elseif($text -match 'asset-protection'){$kind='assets';$label='Get Asset Protection'}
 elseif($text -match 'office|workplace|corporate'){$kind='office';$label='Get Office Security'}
 elseif($path -eq 'employment.html'){$kind='careers';$label='Contact Paradigm About Employment'}
 elseif($path -like 'locations/*'){$label='Get Security in '+($title -replace '(?i)\bsecurity\b|\bservices\b','').Trim(' ','.','|','-')}
 $prompts=switch($kind){
  'patrol' {@('What kind of property needs vehicle or bike patrol?','Would you prefer vehicle patrol, bike patrol, or a combination?','Which hours and days need patrol coverage?')}
  'medical' {@('Is this a hospital, medical office, clinic, or another healthcare facility?','Which areas need security, such as entrances, reception, or parking?','What coverage hours and start date do you have in mind?')}
  'construction' {@('What type of project or warehouse needs security?','Do you need support for site access, equipment and materials, or property observation?','Which work hours or overnight periods need coverage?')}
  'estate' {@('Is coverage for a private home, estate, or residential event?','Do you need entrance coverage, property observation, or another service?','When would you like coverage to begin, and for which hours?')}
  'residential' {@('What type of residential community needs security?','Which areas need coverage, such as entrances, common areas, or parking?','What hours and start date are you considering?')}
  'school' {@('What type of school or campus needs coverage?','Is the priority visitor access, campus observation, an event, or another need?','Which school hours, event dates, or other periods need coverage?')}
  'transport' {@('What kind of business transport support are you looking for?','Which cities are involved in the transport?','What dates or frequency are you considering?')}
  'dispensary' {@('Is this an operating dispensary, a new location, or another cannabis business?','Do you need entry coverage, premises security, or asset protection?','What business hours and start date need coverage?')}
  'bank' {@('Is this a bank branch, financial office, or ATM location?','Which public areas or access points need a security presence?','What hours and start date are you considering?')}
  'k9' {@('What type of property or event is the K9 inquiry for?','What detection service are you looking for?','What dates and general areas need to be reviewed?')}
  'retail' {@('What type of store, shopping center, or retail property needs security?','Is your priority loss prevention, customer areas, entrances, or another concern?','Which business hours or other periods need coverage?')}
  'production' {@('Is coverage for a studio, location shoot, or production site?','Do you need support for access, equipment areas, or another production need?','What filming dates and coverage hours are planned?')}
  'event' {@('What kind of event are you organizing?','What is the expected guest count and type of venue?','What are the event date and coverage hours?')}
  'personal' {@('Are you arranging personal protection for yourself or someone else?','Is this for a workplace, travel, an event, or another setting?','What dates and general coverage needs would you like to review?')}
  'unarmed' {@('What kind of property needs unarmed security?','Which duties are needed, such as visitor assistance, access support, or observation?','What hours and start date are you considering?')}
  'armed' {@('What type of property or assignment are you considering armed security for?','Which responsibilities would you like the officer to cover?','What hours and start date are you considering?')}
  'assets' {@('What type of business or property needs asset protection?','Is the concern inventory, equipment, access, or another business asset?','What coverage hours and start date are you considering?')}
  'office' {@('Is this a single office, an office building, or a business campus?','Do you need reception coverage, visitor access, parking observation, or another duty?','What working hours or after-hours periods need coverage?')}
  'careers' {@('Which position or type of security work interests you?','What relevant experience or current credentials would you like to share?','What city and availability would you like us to know?')}
  default {@('What type of property, business, or event needs security?','What responsibilities would you like security personnel to cover?','What start date and hours are you considering?')}
 }
 if($path -eq 'services/asset-protection/loss-prevention.html'){$label='Get Loss Prevention'}
 $questions=@($prompts|ForEach-Object {@{prompt=$_;type='text'}})
 if($kind -ne 'careers'){$questions+=@{prompt='Which city is the property or assignment in?';type='text'}}
 $questions+=@{prompt='What is your name?';type='name'}
 $questions+=@{prompt='What phone number can Paradigm reach you at?';type='tel'}
 return @{label=$label;title=$title;questions=$questions}
}
