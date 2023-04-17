//


const WTERM = {};
WTERM.UI = {};
WTERM.UI.userdata = {};
WTERM.UI.userdata.websocket = '';
WTERM.UI.utils = {};
WTERM.UI.terms = {};
WTERM.UI.curr_term = '';
//
WTERM.UI.fitAddon = 0;



WTERM.UI.utils.handle_command_form = function(){
  WTERM.UI.utils.ws_send_s(WTERM.UI.userdata.websocket, "hello", "world");
  return 0;
}

WTERM.UI.utils.handle_user_inputcommand = function(data){
  console.log("_usr_input1: '"+data+"'");
  WTERM.UI.utils.ws_send_s(WTERM.UI.userdata.websocket, 'user_msg', bin(data));
  return 0;
}

WTERM.UI.utils.handle_user_inputshell_req = function(){
  var data = "WtermClient::InitSync:1.0";
  WTERM.UI.utils.ws_send_s(WTERM.UI.userdata.websocket, 'user_shellreq', bin(data));
  return 0;
}

WTERM.UI.utils.handle_user_inputshell_msg = function(data){
  console.log("_usr_input2: '"+data+"'");
  WTERM.UI.utils.ws_send_s(WTERM.UI.userdata.websocket, 'user_shellmsg', bin(data));
  return 0;
}

WTERM.UI.utils.handle_user_inputshell = function(data){
  console.log("_usr_input3: '"+data+"'");
  WTERM.UI.utils.ws_send_s(WTERM.UI.userdata.websocket, 'user_shellmsg', bin(data));
  return 0;
}

WTERM.UI.utils.send_msg_to_term = function(data){
   console.log("_msg_from_erl: '"+data+"'"); 
   WTERM.UI.curr_term.write( data );
}


WTERM.UI.utils.conect_ws_internal_msgs_socket = function(uri){
    return ezws_connect(uri);
}

WTERM.UI.utils.conect_ws_user_msgs_socket = function(uri){
    return ezws_connect(uri);
}

WTERM.UI.utils.ws_send_s = function(WS, subcmd, resource){
   ezws_send_raw( WS,
                  enc(tuple(atom('client'), tuple(atom(subcmd), resource)))
                );
   console.log('called ws_send_s() ['+subcmd+'] {'+resource+'}');
   return 0;
}

WTERM.UI.utils.ws_send_sj = function(WS, type, subcmd, resource){
   ezws_send_json( WS,
                   enc(tuple(atom(type), tuple(atom(subcmd), resource)))
                 );
   console.log('called ws_send_sj() type('+type+') ['+subcmd+'] {'+resource+'}');
   return 0;
}

WTERM.UI.utils.ws_send_sb = function(WS, subcmd, resource){
   var enc_uri = encodeURI(resource);
   ezws_send_raw( WS,
                  enc(tuple(atom('client'), tuple(atom(subcmd), bin(enc_uri) )))
                );
   console.log('called ws_send_sb() ['+subcmd+'] {'+resource+'}');
   return 0;
}

WTERM.UI.utils.ws_send_pong = function(WS){
   var subcmd = "pong";
   var enc_uri = "pong";
   ezws_send_raw( WS,
	          enc(tuple(atom('pong'), atom(subcmd)) )
	        );
   return 0;
}

WTERM.UI.utils.start_terminal = function(termName, webSocket){
      const term = new Terminal({cols: 120,
                                 rows: 54,
                                 cursorBlink: true});
      WTERM.UI.curr_term = term;
      const attAddon = new AttachAddon.AttachAddon(webSocket);
      if (WTERM.UI.fitAddon){
          const fitAddon = new FitAddon.FitAddon();
          term.loadAddon(fitAddon);
      }
      term.loadAddon(attAddon);
      const demo_elemid = document.getElementById(termName);
      term.open(demo_elemid);
      // Make the terminal's size and geometry fit the size of terminal-container
      if (WTERM.UI.fitAddon){
	  fitAddon.fit();
      }
      var termInitWS = 0;
      term.onData(data => {
	                   console.log("Sending data to service: '"+data+"'");
                           if (termInitWS == 0){
                               WTERM.UI.utils.handle_user_inputshell_req();
                               termInitWS = 1;
                           }
                           WTERM.UI.utils.handle_user_inputshell_msg(data);
                 });
}


function ping(WS) {
  WTERM.UI.utils.ws_send_pong(WS);
}


WTERM.UI.utils.pingpong = function(WS) {
   let timerId = setInterval(ping, 5000, WS);
}
