/* Progressive UI. No success is inferred from an animation or a submitted request. */
(() => {
'use strict';
const reduced=matchMedia('(prefers-reduced-motion: reduce)');
const $=(s,root=document)=>root.querySelector(s);
const $$=(s,root=document)=>Array.from(root.querySelectorAll(s));
const icon=name=>{const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.classList.add('icon');svg.setAttribute('aria-hidden','true');const use=document.createElementNS(svg.namespaceURI,'use');use.setAttribute('href','#i-'+name);svg.append(use);return svg;};
function pulse(node){if(node&&!reduced.matches)node.animate([{opacity:.55,transform:'translateY(2px)'},{opacity:1,transform:'none'}],{duration:200,easing:'ease-out'});}
function remove(node){if(!node)return Promise.resolve();if(reduced.matches){node.remove();return Promise.resolve();}return node.animate([{opacity:1,transform:'none'},{opacity:0,transform:'translateY(-4px)'}],{duration:140,easing:'ease-out'}).finished.catch(()=>{}).then(()=>node.remove());}
function notify(message,type='info'){
 const host=$('#notifications');if(!host)return;
 const toast=document.createElement('div');toast.className='toast '+(['success','error','warning','info'].includes(type)?type:'info');toast.setAttribute('role',type==='error'?'alert':'status');
 const text=document.createElement('span');text.textContent=message;
 const close=document.createElement('button');close.type='button';close.className='icon-btn';close.dataset.dismiss='';close.setAttribute('aria-label','Cerrar notificación');close.append(icon('close'));
 toast.append(icon(type==='success'?'check':type==='error'||type==='warning'?'alert':'info'),text,close);host.append(toast);
}
function closeDialog(dialog,value='cancel'){
 if(!dialog.open||dialog.dataset.closing)return;
 dialog.dataset.closing='1';dialog.classList.add('is-closing');
 const close=()=>{dialog.classList.remove('is-closing');delete dialog.dataset.closing;dialog.close(value);};
 if(reduced.matches)close();else setTimeout(close,140);
}
function confirm(message){
 const dialog=$('#confirm-dialog');if(dialog.open)return Promise.resolve(false);
 $('#confirm-description').textContent=message;dialog.returnValue='cancel';dialog.showModal();
 return new Promise(resolve=>dialog.addEventListener('close',()=>resolve(dialog.returnValue==='accept'),{once:true}));
}
window.Enterprise={notify,confirm,pulse,remove,icon,closeDialog,reduced};
$('#confirm-dialog')?.addEventListener('cancel',event=>{event.preventDefault();closeDialog(event.currentTarget);});
$('#confirm-dialog form')?.addEventListener('submit',event=>{event.preventDefault();closeDialog($('#confirm-dialog'),event.submitter?.value||'cancel');});
document.addEventListener('click',event=>{const close=event.target.closest('[data-dismiss]');if(close){const toast=close.closest('.toast');if(toast.contains(document.activeElement))$('.sidebar-toggle, .login-card input')?.focus();remove(toast);}});
// Sidebar drawer focus is trapped on mobile; the background is inert only while open.
const mobile=matchMedia('(max-width:1023px)'),sidebar=$('#sidebar'),shell=$('.app-shell'),toggle=$('.sidebar-toggle'),backdrop=$('.sidebar-backdrop');
let returnFocus=null;
function drawer(open){if(!sidebar)return;sidebar.classList.toggle('is-open',open);backdrop.hidden=!open;toggle.setAttribute('aria-expanded',String(open));if(shell)shell.inert=open;document.body.style.overflow=open?'hidden':'';if(open){returnFocus=document.activeElement;sidebar.setAttribute('role','dialog');sidebar.setAttribute('aria-modal','true');$('.drawer-close').focus();}else{sidebar.removeAttribute('role');sidebar.removeAttribute('aria-modal');returnFocus?.focus();}}
function updateMenu(){if(!toggle)return;if(mobile.matches){toggle.setAttribute('aria-expanded',String(sidebar.classList.contains('is-open')));}else{drawer(false);toggle.setAttribute('aria-expanded',String(!document.documentElement.classList.contains('sidebar-compact')));}}
toggle?.addEventListener('click',()=>{
 if(mobile.matches){drawer(!sidebar.classList.contains('is-open'));return;}
 const sidebarWidth = sidebar.getBoundingClientRect().width;
 const before=shell.getBoundingClientRect();document.documentElement.classList.toggle('sidebar-compact');
 try{localStorage.setItem('pos.sidebar',document.documentElement.classList.contains('sidebar-compact')?'compact':'expanded');}catch(e){}
 if(!reduced.matches){
   const width = sidebar.getBoundingClientRect().width;
   sidebar.animate([{width: sidebarWidth + 'px'}, {width: width + 'px'}], {duration:220, easing:'ease-out'});
   const after=shell.getBoundingClientRect();shell.animate([{transform:`translateX(${before.left-after.left}px)`},{transform:'none'}],{duration:220,easing:'cubic-bezier(.2,.75,.25,1)'});}
 updateMenu();
});
$('.drawer-close')?.addEventListener('click',()=>drawer(false));backdrop?.addEventListener('click',()=>drawer(false));mobile.addEventListener('change',updateMenu);updateMenu();
document.addEventListener('keydown',event=>{
 if(mobile.matches&&sidebar?.classList.contains('is-open')){
  if(event.key==='Escape'){event.preventDefault();drawer(false);}
  if(event.key==='Tab'){const items=$$('a[href],button',sidebar).filter(e=>e.getClientRects().length),first=items[0],last=items.at(-1);if(event.shiftKey&&document.activeElement===first){event.preventDefault();last.focus();}else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus();}}
 }
 if(event.altKey&&!event.ctrlKey&&!event.metaKey&&event.key.toLowerCase()==='b'){event.preventDefault();focusSearch();}
});
function focusSearch(){const search=$('#pos-search')||$('main input[type=search]');if(search){search.focus();search.select();}else {
    const dialog = document.querySelector('#module-search');
    if (dialog && !dialog.open) {
      dialog.showModal();
      dialog.querySelector('input').focus();
    }
  }}
const moduleSearch = document.querySelector('#module-search');
moduleSearch?.addEventListener('keydown', event => {
  if (event.key === 'Escape') {
    event.preventDefault();
    closeDialog(moduleSearch);
  }
});
moduleSearch?.querySelector('[data-close-search]').addEventListener('click', () => closeDialog(moduleSearch));
moduleSearch?.querySelector('input').addEventListener('input', event => {
  const term = event.target.value.trim().toLocaleLowerCase();
  const links = Array.from(moduleSearch.querySelectorAll('nav a'));
  links.forEach(link => { link.hidden = !link.textContent.toLocaleLowerCase().includes(term); });
  moduleSearch.querySelector('p').hidden = links.some(link => !link.hidden);
});
$('.context-search')?.addEventListener('click',focusSearch);
// Searchable native select: no custom inaccessible combobox.
function searchable(select){
 if(select.dataset.searchReady||select.options.length<8||select.closest('[data-page-filter], [data-pos-form]'))return;
 select.dataset.searchReady='1';const input=document.createElement('input');input.type='search';input.placeholder='Buscar nombre, NIT, ID o SKU';input.setAttribute('aria-label','Filtrar '+(select.getAttribute('aria-label')||'opciones'));select.before(input);
 const originals=Array.from(select.options).map(o=>o.cloneNode(true));
 input.addEventListener('input',()=>{const value=select.value,term=input.value.toLocaleLowerCase();select.replaceChildren(...originals.filter(o=>!o.value||o.value===value||o.textContent.toLocaleLowerCase().includes(term)).map(o=>o.cloneNode(true)));select.value=value;});
}
function enhance(root){
 $$('select',root).forEach(searchable);
 $$('.field input,.field select,.field textarea',root).forEach(input=>{input.addEventListener('invalid',()=>input.setAttribute('aria-invalid','true'));input.addEventListener('input',()=>{if(input.validity.valid)input.removeAttribute('aria-invalid');});});
 $$('form[data-lines-form]',root).forEach(form=>{
  $$('label:not([for])',form).forEach((label,i)=>{const input=label.nextElementSibling;if(input?.matches('input,select,textarea')){input.id ||= 'commercial-'+i;label.htmlFor=input.id;}});
 });
}
enhance(document);
if (!$('.executive')) $('.page-content')?.classList.add('page-enter');
new MutationObserver(records=>records.forEach(r=>r.addedNodes.forEach(n=>{if(n.nodeType!==1)return;if(n.matches('select'))searchable(n);$$('select',n).forEach(searchable);}))).observe($('main'),{childList:true,subtree:true});
$('.password-toggle')?.addEventListener('click',event=>{const input=$('#id_clave'),shown=input.type==='password';input.type=shown?'text':'password';event.currentTarget.textContent=shown?'Ocultar contraseña':'Mostrar contraseña';event.currentTarget.setAttribute('aria-pressed',String(shown));});
// Preserve existing data while GET filters load. Skeletons reflect real requests only.
let navigationController=null;
async function loadPage(url){
 if(navigationController)navigationController.abort();const controller=new AbortController();navigationController=controller;
 const main=$('#main-content'),loader=$('.navigation-loading');main.setAttribute('aria-busy','true');if(loader)loader.hidden=false;
 let timeout=setTimeout(()=>controller.abort(),20000);
 try{
  const response=await fetch(url,{signal:controller.signal,headers:{'X-Requested-With':'XMLHttpRequest'},credentials:'same-origin'});
  if(!response.ok)throw Error('No se pudo actualizar la consulta. Los datos anteriores se conservan.');
  if(new URL(response.url).pathname!==location.pathname){location.assign(response.url);return;}
  const doc=new DOMParser().parseFromString(await response.text(),'text/html');const content=$('.page-content',doc);if(!content)throw Error('La respuesta no es válida.');
  $('.page-content',main).replaceWith(content);history.pushState({},'',response.url);enhance(content);
  if (content.querySelector('.executive')) {
    document.dispatchEvent(new Event('dashboard:updated'));
  } else {
    pulse(content);
  }
  const announce=$('#announcer');if(announce)announce.textContent='Consulta actualizada.';
 }catch(error){if(navigationController===controller)notify(error.name==='AbortError'?'La consulta tardó demasiado. Intenta de nuevo.':error.message,'error');}
 finally{clearTimeout(timeout);if(navigationController===controller){main.removeAttribute('aria-busy');if(loader)loader.hidden=true;navigationController=null;}}
}
document.addEventListener('click',event=>{const link=event.target.closest('a[data-page-link]');if(link&&!event.ctrlKey&&!event.metaKey&&!event.shiftKey){event.preventDefault();loadPage(link.href);}});
window.addEventListener('popstate',()=>location.reload());
document.addEventListener('submit',async event=>{
 const form=event.target;if(form.method==='dialog'||event.defaultPrevented)return;
 if(form.matches('[data-page-filter]')){event.preventDefault();const params=new URLSearchParams(new FormData(form));loadPage(location.pathname+'?'+params.toString());return;}
 if(form.method.toLowerCase()!=='post')return;
 if(form.dataset.submitting){event.preventDefault();return;}
 if(form.dataset.confirm&&!form.dataset.confirmed){event.preventDefault();const button=event.submitter;if(await confirm(form.dataset.confirm)){form.dataset.confirmed='1';form.requestSubmit(button);}return;}
 form.dataset.submitting='1';form.setAttribute('aria-busy','true');
 $$('button[type=submit],button:not([type])',form).forEach(button=>{button.dataset.originalText=button.textContent;button.disabled=true;button.replaceChildren(icon('check'),document.createTextNode(form.dataset.processingLabel||'Procesando…'));button.querySelector('svg').replaceWith(Object.assign(document.createElement('span'),{className:'button-spinner'}));});
});
window.addEventListener('pageshow',event=>{if(event.persisted)$$('form[data-submitting]').forEach(form=>{delete form.dataset.submitting;delete form.dataset.confirmed;form.removeAttribute('aria-busy');$$('button[data-original-text]',form).forEach(button=>{button.disabled=false;button.textContent=button.dataset.originalText;});});});
})();
