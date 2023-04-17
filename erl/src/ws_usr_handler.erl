%% -*- coding: utf-8 -*-
-module(ws_usr_handler).

-compile([{parse_transform, lager_transform}]).

-export([init/2]).


-export([websocket_init/1, websocket_handle/2, websocket_info/2]).




init(Req, Opts) ->
   {cowboy_websocket, Req, Opts}.



websocket_init(State) ->
   erlang:start_timer(1000, self(), <<"IState">>),
   {[], State}.



websocket_handle({text, Msg}, State) ->
   {[{text, <<"Imesg", Msg/binary>>}], State};

websocket_handle(_Data, State) ->
   {[], State}.



websocket_info({timeout, _Ref, Msg}, State) ->
   erlang:start_timer(1000, self(), <<"Info">>),
   {[{text, Msg}], State};

websocket_info(_Info, State) ->
   {[], State}.
