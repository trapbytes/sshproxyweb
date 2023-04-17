%% -*- coding: utf-8 -*-
%%
-module('wterm_utils').

-compile([{parse_transform, lager_transform}]).


-include("wterm.hrl").


-export([priv_dir/0]).

-export([add_state_data/3]).

-export([set_ssh_opts/2]).

-export([get_registered_name/0, get_ancestors/0]).

-export([read_configuration_file/0, read_configuration_file/1]).

-export([create_config_ets_table/0, create_config_ets_table/2]).

-export([write_config_to_ets_table/1, write_config_to_ets_table/2]).

-export([get_config_val/1]).



-define(CONFIG_FILE, "/workdir/config/sshwebproxy.config").




%%
%% @doc Return the path to the application's priv dir (assuming directory
%% structure is intact).
priv_dir() ->
  filename:join(filename:dirname(filename:dirname(code:which(?MODULE))),
                  "priv").


%%
%%
add_state_data(State, Key, Value) when Key =:= ws_loop_pid ->
  State#wpstate{ws_loop_pid = Value};
add_state_data(State, Key, Value) when Key =:= ssh_conn_ref ->
  State#wpstate{ssh_conn_ref = Value};
add_state_data(State, Key, Value) when Key =:= ssh_channel_pid ->
  State#wpstate{ssh_channel_pid = Value};
add_state_data(State, Key, Value) when Key =:= ssh_channel_id ->
  State#wpstate{ssh_channel_id = Value};
% dont change the other unmatched keys by this function
add_state_data(State, _Key, _Value) ->
  State.


%%
%% set our ssh options based on contents of configuration file.
set_ssh_opts(User, Pass) ->
  %
  lists:flatten(lists:join([{user, User},{password, Pass}],
                           lists:flatten(ets:match(sshproxyweb, {ssh_opts, '$1'})))
                ).


%%
%%
get_registered_name() ->
   case process_info(self(), registered_name) of
      {registered_name, Name} -> Name;
      _ -> self()
   end.


%%
%%
get_ancestors() ->
   case get('$ancestors') of
      A when is_list(A) -> A;
      _  -> []
   end.


%%
%%
read_configuration_file() ->
  read_configuration_file(?CONFIG_FILE).

%%
read_configuration_file(ConfigFileName) ->
   case file:consult(ConfigFileName) of
      {ok, Data} ->
           {ok, Data};
      Other ->
           lager:info("Error: ~p~n", [Other]),
           {error, Other}
   end.



%%
create_config_ets_table() ->
   create_config_ets_table(sshproxyweb,  [bag, named_table, public, {read_concurrency, true}]).

%%
create_config_ets_table(Name, Options) ->
   ets:new(Name,  Options).



%%
write_config_to_ets_table(Data) ->
   write_config_to_ets_table(sshproxyweb, Data).

%%
write_config_to_ets_table(Table, Data) ->
   ets:insert(Table, Data).
   

%%
get_config_val(Name) ->
   lists:flatten(ets:match(sshproxyweb, {Name, '$1'})).

