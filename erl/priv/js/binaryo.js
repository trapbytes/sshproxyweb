
$binary = {};

$binary.on = function onbinary(evt, debug, callback)  //
{
  if (debug) console.log("Binary on");
  var isBin = Blob.prototype.isPrototypeOf(evt.data);
  if (debug) console.log("BloBlob.prototype.isPrototypeOf() == ["+isBin+"]");
  if (isBin) {
      if (debug) console.log("isBin == (true)");
      var reader = new FileReader();
      /* 
       //var text_data1 = String.fromCharCode.apply(null, new Uint8Array(evt.data.slice(0, evt.data.size)));
       var text_data1 = String.fromCharCode.apply(null, evt.data.slice(0, evt.data.size));
      console.log("TEXT-1: '"+ evt.data.text() +"'");
*/
      reader.addEventListener("loadend", function() {
          var text_data = String.fromCharCode.apply(null, new Uint8Array(reader.result));
          if (debug) console.log("Event-loaded: RESULT+ '" + text_data +"'");
          if (typeof callback === 'function') {
              callback( text_data );
          } else {
              try {
                  eval( text_data );
              } catch( e ) {
                  // swallow syntax error warnings due to eval of buff 
                  // data results, why syntax ??
                  if(e instanceof SyntaxError ){ 
                     //console.log("Error: '" + e + "'");
                  }
              } 
          }
      });
      //reader.addEventListener("error", function() {
      //});
      reader.readAsArrayBuffer(evt.data.slice(0, evt.data.size));
      return {status: "ok"};
  } else {
      if (debug) {
          console.log('Non-binary data');
          console.dir({EventData: evt});
      } 
      if (typeof callback === 'function') { 
          callback( evt.data );
      } 
      return {status: "error", desc: "not #binary()" };
  }
};
