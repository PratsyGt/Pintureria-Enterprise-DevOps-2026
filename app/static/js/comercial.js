(() => {
'use strict';
const root = document.querySelector('[data-commercial-mode]');
if (!root) return;
const mode = root.dataset.commercialMode;
const form = root.querySelector('form[data-lines-form]');
const lines = root.querySelector('#line-rows');
const products = JSON.parse(document.querySelector('#product-data')?.textContent || '[]');
const payments = JSON.parse(document.querySelector('#payment-data')?.textContent || '[]');
const locations = JSON.parse(document.querySelector('#location-data')?.textContent || '[]');
const order = JSON.parse(document.querySelector('#order-data')?.textContent || '[]');
const money = val => (Number(val) || 0).toLocaleString('es-GT',{minimumFractionDigits:2,maximumFractionDigits:2});
const n = value => Number(value || 0);
const el = (tag, cls='', attrs={}) => { const x=document.createElement(tag); if(cls)x.className=cls; Object.entries(attrs).forEach(([k,v])=>x.setAttribute(k,v)); return x; };
function select(items,id,text,extra=()=> '') { const s=el('select','',{'aria-label':text,'required':'required'}); s.dataset.field=id; items.forEach(v=>{let op=el('option'); op.value=String(v[id]);op.textContent=extra(v);s.append(op);}); return s; }
function input(field,value,type='number',step='0.001') {const x=el('input','',{'type':type,'aria-label':field});x.dataset.field=field;x.value=value;if(type==='number'){x.min=field==='cantidad'?'0.001':'0';x.step=step;x.required=true;} if(field==='codigoLote')x.maxLength=60;return x;}
function cell(row,child) {let td=el('td');td.append(child);row.append(td);}
function buildLine(saved=null) {
 const tr=el('tr','row-enter'); const isReceipt=mode==='recepcion';
 const items=isReceipt?order:products;
 const key=isReceipt?'OrdenCompraDetalleID':'VarianteID';
 const s=select(items,key,'Producto',v=>isReceipt?`${v.Producto} · ${v.SKU} (pendiente ${v.Pendiente})`:`${v.Nombre} · ${v.SKU} (Q ${money(v.PrecioVenta)})`);
 cell(tr,s);
 const quantity=input('cantidad',isReceipt?'0':'1');cell(tr,quantity);
 if(mode==='compra'||isReceipt){const cost=input('costo',isReceipt?items[0]?.CostoUnitario||0:'0','number','0.01');cell(tr,cost);}
 else {const discount=input('descuento','0','number','0.01');cell(tr,discount);}
 if(isReceipt){cell(tr,select(locations,'UbicacionID','Ubicación',v=>`${v.Bodega} · ${v.Codigo}`));cell(tr,input('codigoLote','','text'));}
 const subtotal=el('span'); subtotal.textContent='—';cell(tr,subtotal);const rem=el('button');rem.type='button';rem.className='button button-small';rem.textContent='Quitar';rem.addEventListener('click',async()=>{await window.Enterprise.remove(tr);recompute();});cell(tr,rem);
 s.addEventListener('change',()=>{if(isReceipt){tr.querySelector('[data-field="costo"]').value=items.find(v=>String(v[key])===s.value)?.CostoUnitario||0;}recompute();});
 if(saved){const keys={VarianteID:'varianteId',OrdenCompraDetalleID:'ordenCompraDetalleId',UbicacionID:'ubicacionId'};tr.querySelectorAll('[data-field]').forEach(field=>{const value=saved[keys[field.dataset.field]||field.dataset.field];if(value!==undefined&&value!==null)field.value=value;});}
 tr.addEventListener('input',recompute);lines.append(tr);recompute();
 }
 function recompute() {
  let total=0;
  lines.querySelectorAll('tr').forEach(tr=>{
   const variant=tr.querySelector('select');const item=(mode==='recepcion'?order:products).find(v=>String(v[mode==='recepcion'?'OrdenCompraDetalleID':'VarianteID'])===variant?.value);
   let price=(mode==='compra'||mode==='recepcion')?n(tr.querySelector('[data-field="costo"]')?.value):n(item?.PrecioVenta);
   let subtotal=Math.max(0,n(tr.querySelector('[data-field="cantidad"]')?.value)*price-n(tr.querySelector('[data-field="descuento"]')?.value));
   subtotal=Math.round((subtotal+Number.EPSILON)*100)/100;tr.querySelector('td:nth-last-child(2) span').textContent='Q '+money(subtotal);total+=subtotal;
  });
  if(mode==='factura' && root.querySelector('#cotizacion-id')?.value) total=n(root.querySelector('#cotizacion-id').selectedOptions[0].dataset.total);
  const totalOutput=root.querySelector('#grand-total');if(totalOutput)totalOutput.textContent='Q '+money(total);
  const remaining=root.querySelector('#payment-remaining');if(remaining){const sum=Array.from(root.querySelectorAll('#payment-rows tr')).reduce((s,tr)=>s+n(tr.querySelector('[data-field="monto"]').value),0);remaining.textContent='Q '+money(total-sum);}
 }
 function addPayment(){const tr=el('tr');cell(tr,select(payments,'MedioPagoID','Medio de pago',x=>x.Nombre));cell(tr,input('monto','0','number','0.01'));cell(tr,input('referencia','','text'));let td=el('td');const b=el('button');b.type='button';b.textContent='Quitar';b.addEventListener('click',async()=>{await window.Enterprise.remove(tr);recompute();});td.append(b);tr.append(td);tr.addEventListener('input',recompute);root.querySelector('#payment-rows').append(tr);recompute();}
 root.querySelector('#add-line')?.addEventListener('click',()=>buildLine());
 root.querySelector('#add-payment')?.addEventListener('click',addPayment);
 if(mode==='factura') {
  const cot=root.querySelector('#cotizacion-id');
  cot?.addEventListener('change',()=>{const on=!!cot.value;root.querySelector('#line-editor').hidden=on;root.querySelectorAll('#line-editor input,#line-editor select').forEach(x=>x.disabled=on);root.querySelector('#quote-note').hidden=!on;if(on){const opt=cot.selectedOptions[0];const client=form.querySelector('[name="cliente_id"]');client.value=opt.dataset.cliente;const first=root.querySelector('#payment-rows [data-field="monto"]');if(first)first.value=Number(opt.dataset.total).toFixed(2);root.querySelector('#quote-note').textContent='Total de la cotización: Q '+money(opt.dataset.total)+'. Se utilizarán los productos y precios originales.';}recompute();});

 }
 let restored=false;
 try{const draft=JSON.parse(document.querySelector('#commercial-draft')?.textContent||'{}');for(const key of ['cliente_id','proveedor_id','vigencia','observaciones','documento'])if(draft[key]!==undefined&&form.elements[key])form.elements[key].value=draft[key];if(draft.detalle_json){const saved=JSON.parse(draft.detalle_json);saved.forEach(buildLine);restored=saved.length>0;}}catch(e){window.Enterprise.notify('Revisa los datos de la operación antes de volver a guardar.','warning');}
 if(!restored&&(mode!=='recepcion'||order.length))buildLine();
 if(mode==='factura'){addPayment();root.querySelector('#cotizacion-id')?.dispatchEvent(new Event('change'));}
 form.addEventListener('submit',event=>{
  try {
   const selected=[];const used=new Set();
   const isQuoteInvoice=mode==='factura'&&!!root.querySelector('#cotizacion-id')?.value;
   if(!isQuoteInvoice){
   lines.querySelectorAll('tr').forEach(tr=>{
    const fields=Object.fromEntries(Array.from(tr.querySelectorAll('[data-field]')).map(x=>[x.dataset.field,x.value]));
    const key=mode==='recepcion'?'ordenCompraDetalleId':'varianteId';
    const id=Number(tr.querySelector('select').value);
    if(used.has(id))throw Error('Un producto no puede aparecer dos veces.');used.add(id);
    const quantity=Number(fields.cantidad);
    if(!Number.isFinite(quantity)||quantity<=0||Math.abs(Math.round(quantity*1000)-quantity*1000)>1e-7)throw Error('Revise las cantidades (máximo tres decimales).');
    let item={[key]:id,cantidad:quantity};
    if(mode==='cotizacion'||mode==='factura'){item.descuento=Number(fields.descuento);const price=n(products.find(v=>v.VarianteID===id)?.PrecioVenta);if(item.descuento<0||item.descuento>quantity*price)throw Error('Descuento mayor al importe de la línea.');}
    if(mode==='compra'||mode==='recepcion'){item.costo=Number(fields.costo);if(!Number.isFinite(item.costo)||item.costo<0)throw Error('Costo inválido.');}
    if(mode==='recepcion'){item.ubicacionId=Number(tr.querySelectorAll('select')[1].value);item.codigoLote=fields.codigoLote||null;const d=order.find(v=>v.OrdenCompraDetalleID===id);if(quantity>n(d.Pendiente))throw Error('Cantidad superior al pendiente de '+d.Producto);}
    selected.push(item);
   });
   if(!selected.length)throw Error('Agregue al menos un producto.');
   }
   root.querySelector('[name="detalle_json"]').value=JSON.stringify(selected);
   if(mode==='factura'){
    let arr=Array.from(root.querySelectorAll('#payment-rows tr')).map(tr=>({medioPagoId:Number(tr.querySelector('select').value),monto:Number(tr.querySelector('[data-field="monto"]').value),referencia:tr.querySelector('[data-field="referencia"]').value}));
    if(!arr.length||arr.some(p=>!Number.isFinite(p.monto)||p.monto<=0))throw Error('Ingrese pagos positivos.');
    if(isQuoteInvoice){const amount=n(root.querySelector('#cotizacion-id').selectedOptions[0].dataset.total);if(Math.abs(arr.reduce((s,p)=>s+p.monto,0)-amount)>0.001)throw Error('Los pagos deben sumar Q '+money(amount));}
    if(!isQuoteInvoice){const total=selected.reduce((s,x)=>s+Math.round((n(products.find(p=>p.VarianteID===x.varianteId)?.PrecioVenta)*x.cantidad-x.descuento+Number.EPSILON)*100)/100,0);if(Math.abs(arr.reduce((s,p)=>s+p.monto,0)-total)>0.001)throw Error('Los pagos deben sumar Q '+money(total));}
    root.querySelector('[name="pagos_json"]').value=JSON.stringify(arr);
   }
  }catch(error){event.preventDefault();window.Enterprise.notify(error.message,'error');}
 });
})();
