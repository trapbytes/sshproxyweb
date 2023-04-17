function ezws_connect(Uri) {
   var websock;
   websock = new WebSocket(Uri);
   websock.onopen = ezws_onopen;
   websock.onclose = ezws_onclose;
   websock.onmessage = ezws_onmessage;
   websock.onerror = ezws_onerror;
   return websock;
}

function ezws_onopen(Event){
   console.log('onOpen', Event);
}

function ezws_onclose(Event){
   console.log('onClose', Event);
   if (Event.wasClean){
       window.location.reload(true);
   }
}

function ezws_onmessage(Msg){
   console.log('onMessage', Event);
   var data = $binary.on(Msg, 1, {} );
   //console.log('--msg: ', Msg);
   //console.log('--msg_dat: ', data);
}

function ezws_onerror(Event){
   console.log('onError', Event);
}

function ezws_send_json(WS, Data){
  Jdata = JSON.stringify(Data);
  ezws_send_raw(WS, Jdata);
}

function ezws_send_raw(WS, Data){
   WS.send(Data);
}

function showMsgBox(Msg) {
  console.log("TODO: show msg box for msg: "+Msg+"");
}
