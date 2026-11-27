(function(){
var R=window.DOCS_ROOT||'',H=document.documentElement;
document.getElementById('theme').onclick=function(){var dark=H.dataset.theme==='dark'||(H.dataset.theme==='auto'&&matchMedia('(prefers-color-scheme:dark)').matches);var n=dark?'light':'dark';H.dataset.theme=n;try{localStorage.setItem('docs-theme',n)}catch(e){}};
document.getElementById('menu').onclick=function(){document.body.classList.toggle('nav')};
var on=document.querySelector('.navlink.on');if(on)on.scrollIntoView({block:'center'});
document.querySelectorAll('.copy').forEach(function(b){b.onclick=function(){navigator.clipboard&&navigator.clipboard.writeText(b.parentNode.querySelector('code').innerText);b.textContent='OK';setTimeout(function(){b.textContent='Copy'},1200)}});
var q=document.getElementById('q'),res=document.getElementById('results'),sel=-1,items=[];
function show(){var v=q.value.trim().toLowerCase();if(!v){res.hidden=true;return}
 var words=v.split(/\s+/);items=(window.DOCS_INDEX||[]).map(function(d){var hay=(d.t+' '+d.k+' '+d.s+' '+d.g).toLowerCase(),sc=0;for(var i=0;i<words.length;i++){var w=words[i];if(d.t.toLowerCase()==w)sc+=10;else if(d.t.toLowerCase().indexOf(w)>=0)sc+=5;else if(hay.indexOf(w)>=0)sc+=1;else return null}return{d:d,sc:sc}}).filter(Boolean).sort(function(a,b){return b.sc-a.sc}).slice(0,12);
 res.innerHTML=items.length?items.map(function(x,i){return '<a href="'+R+x.d.u+'"><b>'+x.d.t+'</b><small>'+x.d.g+' · '+x.d.s.replace(/`/g,'')+'</small></a>'}).join(''):'<a>Ничего не найдено</a>';res.hidden=false;sel=-1}
q.oninput=show;q.onfocus=show;
q.onkeydown=function(e){var a=res.querySelectorAll('a');if(e.key==='ArrowDown'||e.key==='ArrowUp'){e.preventDefault();sel=Math.max(0,Math.min(a.length-1,sel+(e.key==='ArrowDown'?1:-1)));a.forEach(function(x,i){x.classList.toggle('sel',i===sel)})}else if(e.key==='Enter'&&a.length){location.href=a[Math.max(sel,0)].href}else if(e.key==='Escape'){res.hidden=true;q.blur()}};
document.addEventListener('click',function(e){if(!e.target.closest('.search'))res.hidden=true});
document.addEventListener('keydown',function(e){if(e.key==='/'&&document.activeElement!==q){e.preventDefault();q.focus()}});
})();
