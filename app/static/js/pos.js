/* POS state never updates stock locally. SQL Server remains the authority. */
(() => {
'use strict';
const form=document.querySelector('[data-pos-form]');if(!form)return;
const ui=window.Enterprise,$=s=>document.querySelector(s);
const read=id=>JSON.parse(document.getElementById(id)?.textContent||'[]');
const products=read('pos-product-data'),methods=read('pos-payment-data'),draft=read('pos-draft-data')||{};
const map=new Map(products.map(p=>[String(p.VarianteID),p])),cart=new Map();let page=0,locked=false;
const money=cents=>'Q '+(Number(cents)/100).toLocaleString('es-GT',{minimumFractionDigits:2,maximumFractionDigits:2});
function scaled(value,places){const text=String(value??'');if(!new RegExp('^\\d+(?:\\.\\d{1,'+places+'})?$').test(text))throw Error('Revisa la cantidad y la precisión de los importes.');const [whole,fraction='']=text.split('.');return BigInt(whole)*10n**BigInt(places)+BigInt(fraction.padEnd(places,'0'));}
// Quantity has three decimal places, unit price two. Round HALF UP at each line.
function lineMoney(quantity,price,discount){return (scaled(quantity,3)*scaled(price,2)+500n)/1000n-scaled(discount,2);}
window.POSMoney={scaled,lineMoney};
function node(tag,className,text){const e=document.createElement(tag);if(className)e.className=className;if(text!==undefined)e.textContent=text;return e;}
function empty(message){const e=node('div','cart-empty',message);e.style.gridColumn='1 / -1';return e;}
function matching(){const q=$('#pos-search').value.trim().toLocaleLowerCase(),cat=$('#pos-category').value,brand=$('#pos-brand').value;return products.filter(p=>(!q||(p.Nombre+' '+p.SKU+' '+p.Presentacion+' '+(p.Color||'')).toLocaleLowerCase().includes(q))&&(!cat||p.Categoria===cat)&&(!brand||p.Marca===brand));}
const compactCatalog=matchMedia('(max-width:767px)');
compactCatalog.addEventListener('change',()=>{page=0;renderProducts();});
function renderProducts(){
 const size=compactCatalog.matches?6:18,all=matching(),pages=Math.max(1,Math.ceil(all.length/size));page=Math.min(page,pages-1);const host=$('#pos-products');host.replaceChildren();
 all.slice(page*size,(page+1)*size).forEach(p=>{
  const button=node('button','product-card');button.type='button';button.disabled=Number(p.StockActual)<=0||!!$('#pos-quote').value;button.setAttribute('aria-label','Agregar '+p.Nombre+' '+p.Presentacion+' '+(p.Color||''));
  const symbol=node('span','product-symbol');symbol.append(ui.icon('box'));
  const footer=node('span','product-card-footer');footer.append(node('b','',money(scaled(p.PrecioVenta,2))),node('span','product-add','+'));
  button.append(symbol,node('small','',p.SKU+' · '+p.Marca),node('strong','',p.Nombre),node('small','',p.Presentacion+(p.Color?' · '+p.Color:'')),footer,node('span','stock-caption',Number(p.StockActual)>0?p.StockActual+' disponibles':'Sin existencias'));
  button.addEventListener('click',()=>add(p));host.append(button);
 });
 if(!all.length)host.append(empty('No hay productos que coincidan con tu búsqueda.'));
 $('#pos-count').textContent=all.length+' productos · Catálogo disponible';$('#products-page').textContent=(page+1)+' / '+pages;$('#products-previous').disabled=page===0;$('#products-next').disabled=page>=pages-1;
}
for(const [id,key] of [['pos-category','Categoria'],['pos-brand','Marca']]){[...new Set(products.map(p=>p[key]))].sort((a,b)=>a.localeCompare(b,'es')).forEach(value=>$('#'+id).add(new Option(value,value)));$('#'+id).addEventListener('change',()=>{page=0;renderProducts();ui.pulse($('#pos-products'));});}
let searchTimer;$('#pos-search').addEventListener('input',()=>{clearTimeout(searchTimer);$('#pos-count').textContent='Buscando…';searchTimer=setTimeout(()=>{page=0;renderProducts();},120);});
$('#products-previous').addEventListener('click',()=>{page--;renderProducts();});$('#products-next').addEventListener('click',()=>{page++;renderProducts();});
function add(p){const key=String(p.VarianteID),existing=cart.get(key),qty=existing?Number(existing.quantity)+1:Math.min(1,Number(p.StockActual));if(qty>Number(p.StockActual)){ui.notify('No hay más existencias disponibles de este producto.','warning');return;}cart.set(key,{quantity:qty.toFixed(3),discount:existing?.discount||'0.00'});renderCart(key);$('#announcer').textContent=p.Nombre+' agregado al carrito.';}
function totals(){
 if($('#pos-quote').value){const total=scaled($('#pos-quote').selectedOptions[0].dataset.total,2);return {subtotal:total,discount:0n,total};}
 let subtotal=0n,discount=0n;
 for(const [key,line] of cart){const p=map.get(key);if(!p)throw Error('Un producto del carrito ya no está disponible.');const q=scaled(line.quantity,3),d=scaled(line.discount,2);if(q<=0n||q>scaled(p.StockActual,3))throw Error('La cantidad de '+p.Nombre+' supera las existencias o no es válida.');const gross=lineMoney(line.quantity,p.PrecioVenta,'0');if(d>gross)throw Error('El descuento de '+p.Nombre+' supera su importe.');subtotal+=gross;discount+=d;}
 const total=subtotal-discount;if(total>999999999999n)throw Error('El total excede el límite permitido.');return {subtotal,discount,total};
}
function updateTotals(){
 try{const t=totals();for(const [id,value] of [['cart-subtotal',t.subtotal],['cart-discount',t.discount],['cart-total',t.total]]){const e=$('#'+id),text=money(value);if(e.textContent!==text){e.textContent=text;ui.pulse(e);}}$('#cart-error').textContent='';$('#open-checkout').disabled=(!cart.size&&!$('#pos-quote').value)||t.total<=0n;}
 catch(error){$('#cart-error').textContent=error.message;$('#open-checkout').disabled=true;}
 $('#cart-count').textContent=cart.size;$('#cart-empty').hidden=cart.size>0||!!$('#pos-quote').value;
}
function renderCart(added){
 const host=$('#cart-items');host.replaceChildren();
 for(const [key,line] of cart){const p=map.get(key);if(!p)continue;const row=node('article','cart-line'+(key===added?' row-enter':''));row.dataset.variant=key;
  const head=node('div','cart-line-head'),title=node('div');title.append(node('strong','',p.Nombre),node('small','',p.Presentacion+' · '+p.SKU+' · '+money(scaled(p.PrecioVenta,2))));const remove=node('button','icon-btn');remove.type='button';remove.setAttribute('aria-label','Quitar '+p.Nombre);remove.append(ui.icon('close'));remove.addEventListener('click',async()=>{cart.delete(key);updateTotals();await ui.remove(row);$('#pos-search').focus();});head.append(title,remove);
  const controls=node('div','cart-line-controls'),amount=node('strong','');
  for(const [field,label,step] of [['quantity','Cantidad','0.001'],['discount','Descuento Q','0.01']]){const wrap=node('label','',label),input=node('input');input.type='number';input.min=field==='quantity'?'0.001':'0';input.step=step;input.value=line[field];input.required=true;input.setAttribute('aria-label',label+' de '+p.Nombre);input.dataset.field=field;if(field==='quantity')input.max=p.StockActual;
   input.addEventListener('input',()=>{line[field]=input.value;try{amount.textContent=money(lineMoney(line.quantity,p.PrecioVenta,line.discount));input.removeAttribute('aria-invalid');}catch(error){input.setAttribute('aria-invalid','true');amount.textContent='Revisar';}updateTotals();});wrap.append(input);controls.append(wrap);}
  try{amount.textContent=money(lineMoney(line.quantity,p.PrecioVenta,line.discount));}catch(e){amount.textContent='Revisar';}controls.append(amount);row.append(head,controls);host.append(row);
 }
 updateTotals();
}
$('#clear-cart').addEventListener('click',async()=>{if(!cart.size)return;if(await ui.confirm('¿Vaciar el carrito actual?')){cart.clear();renderCart();$('#pos-search').focus();}});
const client=$('#pos-client'),clients=Array.from(client.options).map(o=>o.cloneNode(true));$('#pos-client-search').addEventListener('input',event=>{const q=event.target.value.toLocaleLowerCase(),value=client.value;client.replaceChildren(...clients.filter(o=>o.value===value||o.textContent.toLocaleLowerCase().includes(q)).map(o=>o.cloneNode(true)));client.value=value;});
function quoteChanged(){const active=!!$('#pos-quote').value;$('#cart-items').hidden=active;$('#pos-quote-note').hidden=!active;$('#clear-cart').disabled=active;$('#pos-client-search').disabled=active;client.style.pointerEvents=active?'none':'';client.setAttribute('aria-readonly',String(active));if(active){const option=$('#pos-quote').selectedOptions[0];if(!Array.from(client.options).some(o=>o.value===option.dataset.client))client.replaceChildren(...clients.map(o=>o.cloneNode(true)));client.value=option.dataset.client;$('#pos-quote-note').textContent='Cotización #'+option.value+' · '+money(scaled(option.dataset.total,2))+'. Se conservarán sus productos y precios.';}hostDisableCart(active);renderProducts();updateTotals();}
function hostDisableCart(disabled){document.querySelectorAll('#cart-items input').forEach(input=>input.disabled=disabled);}
$('#pos-quote').addEventListener('change',quoteChanged);client.addEventListener('change',()=>{if($('#pos-quote').value)client.value=$('#pos-quote').selectedOptions[0].dataset.client;});
const dialog=$('#checkout-dialog');
function paymentRows(){return Array.from(document.querySelectorAll('.payment-line'));}
function balance(){let sum=0n;try{paymentRows().forEach(row=>sum+=scaled(row.querySelector('[data-amount]').value,2));const remaining=totals().total-sum;$('#payment-balance').textContent=money(remaining);$('#payment-balance').classList.toggle('error',remaining!==0n);}catch(e){$('#payment-balance').textContent='Revisar importes';}}
function addPayment(data={}){const row=node('div','payment-line');const label=node('label','','Medio de pago'),select=node('select');select.required=true;select.setAttribute('aria-label','Medio de pago');methods.forEach(m=>select.add(new Option(m.Nombre,m.MedioPagoID)));if(data.medioPagoId)select.value=data.medioPagoId;label.append(select);const amountLabel=node('label','','Monto Q'),amount=node('input');amount.type='number';amount.step='0.01';amount.min='0.01';amount.required=true;amount.dataset.amount='';amount.value=data.monto||'';amount.setAttribute('aria-label','Monto del pago');amountLabel.append(amount);const remove=node('button','icon-btn');remove.type='button';remove.setAttribute('aria-label','Quitar medio de pago');remove.append(ui.icon('close'));remove.addEventListener('click',()=>{row.remove();balance();});const refLabel=node('label','reference','Referencia (opcional)'),ref=node('input');ref.maxLength=100;ref.dataset.reference='';ref.value=data.referencia||'';ref.setAttribute('aria-label','Referencia del pago');refLabel.append(ref);row.append(label,amountLabel,remove,refLabel);amount.addEventListener('input',balance);$('#pos-payments').append(row);balance();}
$('#pos-add-payment').addEventListener('click',()=>addPayment());
function openCheckout(){
 try{const t=totals();if(!client.value)throw Error('Selecciona un cliente.');if((!cart.size&&!$('#pos-quote').value)||t.total<=0n)throw Error('Agrega productos con un total mayor que cero.');if(!form.reportValidity())return;
 $('#checkout-error').textContent='';$('#checkout-summary').textContent=client.selectedOptions[0].textContent;$('#checkout-total').textContent=money(t.total);if(!paymentRows().length)addPayment({monto:(Number(t.total)/100).toFixed(2)});paymentRows().forEach(row=>row.querySelectorAll('input,select').forEach(e=>e.disabled=false));balance();dialog.showModal();$('#confirm-sale').disabled=false;
 }catch(error){ui.notify(error.message,'error');}
}
$('#open-checkout').addEventListener('click',openCheckout);
function cancelCheckout(){if(locked)return;paymentRows().forEach(row=>row.querySelectorAll('input,select').forEach(e=>e.disabled=true));ui.closeDialog(dialog);}
$('#close-checkout').addEventListener('click',cancelCheckout);$('#cancel-checkout').addEventListener('click',cancelCheckout);dialog.addEventListener('cancel',event=>{event.preventDefault();cancelCheckout();});
form.addEventListener('submit',event=>{
 if(locked){event.preventDefault();return;}
 if(!dialog.open){event.preventDefault();openCheckout();return;}
 try{
  const t=totals();const payments=paymentRows().map(row=>({medioPagoId:Number(row.querySelector('select').value),monto:row.querySelector('[data-amount]').value,referencia:row.querySelector('[data-reference]').value}));
  if(!payments.length||payments.some(p=>scaled(p.monto,2)<=0n)||payments.reduce((n,p)=>n+scaled(p.monto,2),0n)!==t.total)throw Error('Los pagos deben cubrir exactamente '+money(t.total)+'.');
  const lines=$('#pos-quote').value?[]:Array.from(cart,([key,line])=>({varianteId:Number(key),cantidad:line.quantity,descuento:line.discount}));
  if(lines.length>100)throw Error('Una venta admite hasta 100 productos diferentes.');form.elements.detalle_json.value=JSON.stringify(lines);form.elements.pagos_json.value=JSON.stringify(payments);
  locked=true;$('#checkout-processing').hidden=false;$('#close-checkout').disabled=true;$('#cancel-checkout').disabled=true;$('#pos-add-payment').disabled=true;
 }catch(error){event.preventDefault();$('#checkout-error').textContent=error.message;ui.pulse($('#checkout-error'));}
});
// Restore only the submitted payload returned by Django. No persistent browser customer data.
try{if(draft.cliente_id)client.value=draft.cliente_id;if(draft.detalle_json){for(const line of JSON.parse(draft.detalle_json)){const key=String(line.varianteId);if(map.has(key))cart.set(key,{quantity:String(line.cantidad),discount:String(line.descuento)});else ui.notify('Un producto enviado ya no está disponible. Revisa el carrito.','warning');}}}catch(e){ui.notify('No se pudo recuperar todo el carrito; revisa los productos.','warning');}
renderCart();quoteChanged();
try{if(draft.pagos_json){JSON.parse(draft.pagos_json).forEach(addPayment);paymentRows().forEach(row=>row.querySelectorAll('input,select').forEach(e=>e.disabled=true));}}catch(e){}
window.addEventListener('pageshow',event=>{if(event.persisted){locked=false;$('#checkout-processing').hidden=true;$('#close-checkout').disabled=false;$('#cancel-checkout').disabled=false;$('#pos-add-payment').disabled=false;}});
})();
