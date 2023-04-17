%% -*- coding: utf-8 -*-
%%
-module('wterm_tssh').

-description('SSH wterm interface'). 

-compile([{parse_transform, lager_transform}]).


-behaviour(ssh_client_channel).


-include("wterm.hrl").


-export([connect_shell/2, connect_shell_pty/1]).

-export([shell/1, single_exec_connect/2]).

-export([loop/3]).

-export([spawn_loop_proc/3]).

%% ssH_server_channel callbacks
-export([init/1, handle_ssh_msg/2, handle_call/3, handle_msg/2]).

-export([handle_cast/2, code_change/3, terminate/2]).


%% From ssh_connect.hrl
-define(DEFAULT_PACKET_SIZE, 65536).
-define(DEFAULT_WINDOW_SIZE, 10*?DEFAULT_PACKET_SIZE).




init(_Args) ->
   {ok, {}}.


handle_call(_Req, _From, State) ->
   {reply, ok, State}.


handle_msg(_Msg, State) ->
   {noreply, State}.


handle_cast(_Req, State) ->
   {noreply, State}.


terminate(_Msg, _State) ->
   ok.


code_change(_OldVsn, State, _Extra) ->
   {ok, State}.


handle_ssh_msg(_Msg, State) ->
   {noreply, State}.



%%
%%
spawn_loop_proc(Pid, State, ActionFun) ->
   case get('$initial_call') of
        undefined ->
            put('$ancestors',
                [wterm_utils:get_registered_name() | wterm_utils:get_ancestors()]),

            put('$initial_call', {?MODULE, init, []});
        _ ->
            ok
   end,
   {group_leader, GIO} = process_info(self(), group_leader),

   %
   IoPid = spawn_link(fun() -> monitor(process, Pid),
                               loop(Pid, State, ActionFun)
                      end),
   {ok, IoPid, GIO}.

%%
%%
loop(ParentPid, State, Fun) ->
  OState = receive
    { 'DOWN', _MonitorRef, process, ParentPid, _Reason} -> exit(normal);

    { 'EXIT', MonitorRef, Reason} ->

      lager:debug("Exit Msg: pid: ~p reason: ~p state: ~p", [MonitorRef, Reason, State]),
      %
      handle_ssh_close(State, <<"pty">>),
      exit(normal);

    Msg ->
      NewState = handle_messages(State, ParentPid, Fun, Msg),

      loop(ParentPid, NewState, Fun)
  after 10 -> % was a 100
    State
  end,
  loop(ParentPid, OState, Fun).



handle_messages(State, ParentPid, Fun, Msg) ->
  %
  case Msg of
    %% Messages from the websocket
    <<"ping">> -> State;

    {client, MsgData} -> handle_client_request(MsgData, State);

    %% Messages from a ssh server connection
    %%
   
    % channel up message
    {ssh_channel_up, _ChannelId, _SshRef} -> State;

    {ssh_cm, _SshRef, {eof, _ChannelId}} -> State;

    {ssh_cm, _SshRef, {exit_status, _ChannelId, _ExitStatus}} -> State;

    {ssh_cm, _SshRef, {closed, _ChanId}} -> handle_ssh_close(State, <<"">>);

    {ssh_cm, _SshRef, Data} -> handle_connection_data(ParentPid, State, Data, Fun);
    %% all other messages
    _  -> State
  end.



%%
%%
handle_client_request({Utype, Mesg}, State) when Utype =:= user_msg ->
  %
  wterm_tssh:single_exec_connect(State, Mesg);

%%
handle_client_request({Utype, _Mesg}, State) when Utype =:= user_shellreq ->
  %
  {ConRef, ChannelId, ChanPid} = wterm_tssh:connect_shell_pty(State),

  State#wpstate{ssh_conn_ref = ConRef, ssh_channel_id = ChannelId, 
                ssh_channel_pid = ChanPid};

%% initializer for the ssh terminal request
handle_client_request({Utype, _Mesg}, State) when Utype =:= user_shellreq_notty ->
  %
  {ok, ConRef, ChannelId} = wterm_tssh:connect_shell(State, true),

  DefaultShell = wterm_utils:get_config_val(default_shell),

  {_Res1, _ShellState} = ssh_cli:init([ DefaultShell ]),


  case ssh_connection:shell(ConRef, ChannelId) of
       ok -> lager:debug("SSH-WTERM-Connect-shell ok");
       Error -> lager:debug("SSH-WTERM-Connect-shell error ~p", [Error])
  end,

  State#wpstate{ssh_conn_ref = ConRef, ssh_channel_id = ChannelId };

%% handle browser -> ssh host terminal interaction
handle_client_request({Utype, Mesg}, State) when Utype =:= user_shellmsg ->
  %
  _SendState = ssh_connection:send(State#wpstate.ssh_conn_ref,
                                   State#wpstate.ssh_channel_id,
                                   Mesg),
  State;

% print unknown messages
handle_client_request(MsgData, State) ->
  %
  lager:debug("[~s@~s:~p] unknown client service request '~p'",
              [State#wpstate.userid, State#wpstate.ssh_host, State#wpstate.ssh_port, MsgData]),
  State.




%%
%%
handle_ssh_close(State, Type) when Type =:= <<"pty">>  ->
  %
  ssh_connection:send_eof(State#wpstate.ssh_conn_ref, State#wpstate.ssh_channel_id),

  lager:debug("Closed ssh pty session ~s@~s:~p", 
              [State#wpstate.userid, State#wpstate.ssh_host, State#wpstate.ssh_port]),
  State;

handle_ssh_close(State, _Type ) ->

  ssh_connection:close(State#wpstate.ssh_conn_ref, State#wpstate.ssh_channel_id),

  lager:debug("Closed single execute session ~s@~s:~p",
             [State#wpstate.userid, State#wpstate.ssh_host, State#wpstate.ssh_port]),
  State.



%%
%%
handle_connection_data(ParentPid, State, Data, Fun) ->
  %
  {data, _X, _Y, MsgFromServer} = Data,
  %
  Fun(ParentPid, State#wpstate.userid, {wtssh_exec_msg, MsgFromServer}),

  State.


%%
%%
single_exec_connect(State, Mesg) ->
  %
  {ok, ConRef, ChannelId} = wterm_tssh:connect_shell(State, false),

  ssh_connection:exec(ConRef, ChannelId, Mesg, infinity),

  State.


%%
%%
connect_shell(State, Single) ->
  %
  lager:debug("Connecting to ~p ~p opts: ~p",
              [State#wpstate.ssh_host, State#wpstate.ssh_port, State#wpstate.ssh_opts]),
  case ssh:connect(State#wpstate.ssh_host, State#wpstate.ssh_port, State#wpstate.ssh_opts) of
    {ok, ConnectionRef} ->
         {ok, ChannelId} =
             case Single of
               true -> ssh_connection:session_channel(ConnectionRef, infinity);
               _   ->
                WindowSz = ?DEFAULT_WINDOW_SIZE,
                MaxPacketSz = ?DEFAULT_PACKET_SIZE,
                ssh_connection:session_channel(ConnectionRef, WindowSz, MaxPacketSz, infinity)
             end,

         {ok, ConnectionRef, ChannelId};

    Other  ->
         lager:debug("connect error: ~p", [Other]),
         {error, Other}
  end.


%%
connect_shell_pty(State) ->
  %
  lager:debug("Connecting to ~p ~p opts: ~p",
              [State#wpstate.ssh_host, State#wpstate.ssh_port, State#wpstate.ssh_opts]),

  case ssh:connect(State#wpstate.ssh_host, State#wpstate.ssh_port, State#wpstate.ssh_opts) of
    {ok, ConnectionRef} ->
         Value = shell(ConnectionRef),
         Value;

    Other ->
         lager:info("connect error: ~p", [Other]),
         {error, Other}
  end.


%%
%%
shell(ConnectionRef) ->
  case ssh_connection:session_channel(ConnectionRef, infinity) of
       {ok, ChannelId}  ->
            success = ssh_connection:ptty_alloc(ConnectionRef, ChannelId, []),

            Args = [{channel_cb, ssh_shell},
                    {init_args, [ConnectionRef, ChannelId]},
                    {cm, ConnectionRef},
                    {channel_id, ChannelId}],

            {ok, State} = ssh_client_channel:init([Args]),

            {state, _ConRef, _Shell, {state, ChanPid, 0, _CRef}, _O, _Bool} = State,

            {ConnectionRef, ChannelId, ChanPid};
       Error ->
            Error
  end.

%%
%%
