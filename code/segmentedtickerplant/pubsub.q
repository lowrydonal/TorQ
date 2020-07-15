// Pub/sub utilities for segmented tp process
// Functionality for clients to subscribe to all tables or a subset
// Includes option for subsrcibe to apply filters to received data

\d .stpps

// List of pub/sub tables, populated on startup
t:`

// Handles to publish all data
subrequestall:enlist[`]!enlist ()

// Handles and conditions to publish filtered data
subrequestfiltered:([tabname:`$()]handle:`int$();filts:`$();columns:`$())

// Function to send end of period messages to subscribers
// Assumes that .u.endp has been defined on the client side
endp:{
  (neg raze union/[value subrequestall;exec handle from .stpps.subrequestfiltered])@\:(`.u.endp;x;y);
 };

// Function to send end of day messages to subscribers      
// Assumes that .u.end has been defined on the client side   
end:{
  (neg raze union/[value subrequestall;exec handle from .stpps.subrequestfiltered])@\:(`.u.endp;x;y);
 };

suball:{
  delhandle[x].z.w;
  :add[x];
 };

subfiltered:{[x;y]
  delhandlef[x].z.w;
  if[11=type y;:selfiltered[x;y]];
  if[99=type y;:addfiltered[x;y]];
 };

// Add handle to subscriber in sub all mode
add:{
  if[not (count subrequestall x)>i:subrequestall[x;]?.z.w;
    subrequestall[x],:.z.w];
  (x;$[99=type v:value x;v;0#v])
 };

// Add handle to subscriber in sub filtered mode
addfiltered:{[x;y]
  if[not .z.w in subrequestfiltered[x]`handle;
    @[`.stpps.subrequestfiltered;x;:;(enlist[`handle]!enlist .z.w),y[x]]];
  (x;$[99=type v:value x;v;0#v])
 };

// Add handle for subscriber using old API (filter is list of syms)
selfiltered:{[x;y]
  if[not .z.w in subrequestfiltered[x]`handle;
    y:`$"sym in ","`","`"sv string y;
    @[`.stpps.subrequestfiltered;x;:;`handle`filts`columns!(.z.w;y;`)]];
  (x;$[99=type v:value x;v;0#v])
 };

upd:{[t;x]
  x:updtab[t]@x;
  t insert x;
  :x;
 };

pub:{[t;x]
  if[count x;
    if[count h:subrequestall[t];-25!(h;(`upd;t;x))];
    if[t in key subrequestfiltered;
      w:subrequestfiltered[t];
      query:"select ",string[w`columns]," from ",string[t]," where ",string[w`filts];
      x:value query;
      -25!((),w`handle;(`upd;t;x))
    ]
  ]
 };

// Functions to add columns on updates
updtab:enlist[`]!enlist {(enlist(count first x)#.z.p),x}

// Remove handle from subscription meta
delhandle:{[t;h]
  @[`.stpps.subrequestall;t;except;h];
 };

delhandlef:{[t;h]
  delete from  `.stpps.subrequestfiltered where tabname=t,handle=h;
 };

// Remove all handles when connection closed
closesub:{[h]
  delhandle[;h]each t;
  delhandlef[;h]each t;
 };

.z.pc:{[f;x] f@x; closesub x}@[value;`.z.pc;{{}}]

\d .

// Function called on subscription
// Subscriber will call with null y parameter in sub all mode
// In sub filtered mode, y will contain tables to subscribe to and filters to apply
.u.sub:{[x;y]
  if[not x in .stpps.t;
    .lg.e[`rdb;"Table ",string[x]," not in list of stp pub/sub tables"];
    :()];
  if[y~`;:.stpps.suball[x]];
  if[not y~`;:.stpps.subfiltered[x;y]]
 };

