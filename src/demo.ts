import {defaults, iso, uid, type DB, type Product} from './types'
const today=iso()
const products:Product[]=[
  {id:'demo-p1',name:'Colar ponto de luz',sku:'COL-001',description:'Um toque de delicadeza para qualquer ocasião.',category_id:'demo-cat1',cost_price:38,sale_price:89.9,stock:7,min_stock:3,photo_urls:[],active:true,supplier:'',created_at:today},
  {id:'demo-p2',name:'Brinco argola dourada',sku:'BRI-002',description:'Clássico e versátil.',category_id:'demo-cat1',cost_price:24,sale_price:59.9,stock:2,min_stock:4,photo_urls:[],active:true,supplier:'',created_at:today},
  {id:'demo-p3',name:'Conjunto delicado',sku:'CON-003',description:'Elegância para presentear.',category_id:'demo-cat1',cost_price:58,sale_price:139.9,stock:4,min_stock:2,photo_urls:[],active:true,supplier:'',created_at:today},
  {id:'demo-p4',name:'Blusa feminina básica',sku:'ROU-004',description:'Conforto com estilo.',category_id:'demo-cat2',cost_price:32,sale_price:79.9,stock:3,min_stock:2,photo_urls:[],active:true,supplier:'',created_at:today},
  {id:'demo-p5',name:'Vestido casual',sku:'ROU-005',description:'Para seus dias especiais.',category_id:'demo-cat2',cost_price:65,sale_price:149.9,stock:1,min_stock:3,photo_urls:[],active:true,supplier:'',created_at:today},
  {id:'demo-p6',name:'Pulseira com brilho',sku:'PUL-006',description:'Charme em cada detalhe.',category_id:'demo-cat1',cost_price:28,sale_price:69.9,stock:6,min_stock:2,photo_urls:[],active:true,supplier:'',created_at:today},
]
export const demoSeed:DB={categories:[{id:'demo-cat1',name:'Semijoias',enabled:true,sort_order:1},{id:'demo-cat2',name:'Roupas',enabled:true,sort_order:2}],products,customers:[{id:'demo-cli1',name:'Cliente exemplo',phone:'',email:'',notes:'',created_at:today}],sales:[],sale_items:[],receivables:[],cash_entries:[],stock_movements:[],online_orders:[],store_settings:[defaults]}
export const getDemo=():DB=>{try {const x=localStorage.getItem('sf-demo-v2');if(x)return {...demoSeed,...JSON.parse(x)}}catch{}return structuredClone(demoSeed)}
export const saveDemo=(d:DB)=>localStorage.setItem('sf-demo-v2',JSON.stringify(d))
export const makeId=uid
