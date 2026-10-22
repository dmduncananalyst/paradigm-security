const menu=document.querySelector('.v5-menu');
menu?.addEventListener('click',()=>{const header=document.querySelector('.v5-header');const open=header.classList.toggle('menu-open');menu.setAttribute('aria-expanded',String(open));menu.setAttribute('aria-label',open?'Close navigation':'Open navigation');});
document.addEventListener('keydown',event=>{if(event.key==='Escape'){document.querySelector('.v5-header')?.classList.remove('menu-open');menu?.setAttribute('aria-expanded','false');document.querySelectorAll('.subnav-open').forEach(group=>{group.classList.remove('subnav-open');group.querySelector('.subnav-toggle')?.setAttribute('aria-expanded','false');});}});
if(window.matchMedia('(prefers-reduced-motion: reduce)').matches){document.querySelectorAll('video').forEach(video=>{video.pause();video.removeAttribute('autoplay');video.setAttribute('controls','');});}

document.querySelectorAll('.local-nav-label').forEach(button=>button.addEventListener('click',()=>{const group=button.closest('.local-nav-group');const open=group.classList.toggle('subnav-open');button.setAttribute('aria-expanded',String(open));}));
