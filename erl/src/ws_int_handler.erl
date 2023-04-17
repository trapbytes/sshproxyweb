%% -*- coding: utf-8 -*-
-module(ws_int_handler).
%%
%% websock_proc ->[ loop_proc ]
%%
-compile([{parse_transform, lager_transform}]).


-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2, terminate/3]).


-include("wterm.hrl").




%%
%%
set_state_record(Pid) ->
  %
  UserId = wterm_utils:get_config_val(ssh_user_id),
  Password = wterm_utils:get_config_val(ssh_user_password),
  [SshPort] = wterm_utils:get_config_val(ssh_port),

  #wpstate{userid = UserId,
           password = Password,
           cowboy_pid = Pid,
           ws_loop_pid = undefined,   %% rename wsocket_input_loop
           ssh_host = wterm_utils:get_config_val(ssh_host),
           ssh_port = SshPort,
           ssh_opts = wterm_utils:set_ssh_opts(UserId, Password),
           ssh_conn_ref=undefined,
           ssh_channel_id=undefined
          }.

%%
%%
%% get idle timeout and other runtime admin config defaults
%% and assign them into State var
init(Req, State) ->
  {cowboy_websocket, Req, State, #{idle_timeout => 864000000}}.


%%
%%
websocket_init(_State) ->
  Pid = self(),
  %
  WS = set_state_record(Pid),

  % spawn the process to handle the mesgs from the websocket
  {ok, LooperPid, _Gio} =
       wterm_tssh:spawn_loop_proc(Pid, WS, fun wterm_loop_actions:loop_actions/3),

  NewState = wterm_utils:add_state_data(WS, ws_loop_pid, LooperPid),

  % other front side/browser init goes here
  {reply, {text, <<"Wterm::InitSync:1.0\r\nHit Enter to Connect\r\n">>}, NewState}.



%%
%%
websocket_handle({binary, Msg}, State) ->
  Bin2Term = erlang:binary_to_term(Msg, [safe]),

  case Bin2Term of
     {pong, pong} -> {reply, {ping, <<>>}, State};

     _  -> erlang:send( State#wpstate.ws_loop_pid, Bin2Term),
           {ok, State}
  end;

websocket_handle({text, Msg}, State) ->
  erlang:send( State#wpstate.ws_loop_pid, Msg),
  {ok, State};

websocket_handle({pong, <<>>}, State) ->
  {reply, {ping, <<>>}, State};

websocket_handle(pong, State) ->
  {reply, {ping, <<>>}, State};

websocket_handle(Data, State) ->
  lager:debug("handle: other msg: ~p state: ~p~n", [Data, State]),
  {ok, State}.



%%
%%
websocket_info({eval, Eval}, State) ->
  {reply, {binary, Eval}, State};

websocket_info({ok, Data}, State) ->
  {reply, {text, Data}, State};

websocket_info({timeout, _Ref, Msg}, State) ->
  {reply, {text, Msg}, State};

websocket_info(_Info, State) ->
  {ok, State}.




terminate(Type, Req, State) ->
  lager:debug("ws_terminate type: ~p req: ~p state ~p~n", [Type, Req, State]),
  % unsibscribe, etc
  ok.
