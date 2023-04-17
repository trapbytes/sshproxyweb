%% -*- coding: utf-8 -*-
-module('wterm_loop_actions').

-compile([{parse_transform, lager_transform}]).


-export([loop_actions/3]).

-export([replace_unix_term_chars/1]).




%%
%%
replace_unix_term_chars([]) ->
   [];
replace_unix_term_chars(Data) ->
   binary:replace(Data, <<"\r\n">>, <<"<br>">>, [global]).
  



%%
loop_actions(_ParentPid, _User, {user_msg, _UsrData}=_Data) ->
   %% Really a debug routine bounce back user_msg to browser ..
   %%JSFun = [<<"WTERM.UI.utils.send_msg_to_term(\"">>,UsrData,<<"\")">>],
   %%wterm_javascript:eval(ParentPid, JSFun),
   ok;

%% ping the string back
loop_actions(ParentPid, _User, {wtssh_exec_msg, UsrData}=_Data) ->
   wterm_javascript:eval(ParentPid, UsrData),
   ok;

%% handle other messages
%%
loop_actions(ParentPid, User, Data) ->
   lager:debug("loop_actions: ~p / ~p  data: ~p~n", [ParentPid, User, Data]),
   ok.
