% -*- coding: utf-8 -*-



%% Save our state data
%%
-record(wpstate,
        {
         userid,
         password,
         cowboy_pid,
         ws_loop_pid,
         ssh_host,
         ssh_port,
         ssh_opts,
         ssh_conn_ref,
         ssh_channel_id,
         ssh_channel_pid
        }
       ).

