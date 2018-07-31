#!/usr/bin/swipl
:- style_check(-singleton).
:- initialization main.
:- set_prolog_flag(verbose, silent).
:- use_module(library(csv)).


%%----Facts Sample:
%%-----------------------
%%==> scheduling_preliminary_app_interference_20180606.csv <==
interference(app_8361,app_2163,0) .
interference(app_8361,app_1919,0) .
interference(app_1919,app_8017,1) .
interference(app_8017,app_8959,0) .
%%==> scheduling_preliminary_instance_deploy_20180606.csv <==
deploy(inst_23673,app_1919,machine_4959) .
deploy(inst_23672,app_8017,machine_4959) .
deploy(inst_74024,app_6123,machine_3949) .
deploy(inst_31055,app_7733,machine_3455) .

%%--- Rules
%%----------
machine_app_cnt(Machine,App,Cnt) :-
	setof(Instance, deploy(Instnace,App,Machine),LS),
	length(LS,Cnt) .

machine_interference(Machine,App1,App2,X,Cnt) :-
	deploy(_, App1,Machine),
	Machine \= empty,
	machine_app_cnt(Machine,App2,Cnt),
	interference(App1,App2,X),
	Cnt >=  X .

machine_interference_cut(Machine) :-
	deploy(_, App1,Machine),
	Machine \= empty,
	machine_app_cnt(Machine,App2,Cnt),
	interference(App1,App2,X),
	Cnt >=  X .

	
%%%%------MAIN-------
import :-
	csv_read_file('scheduling_preliminary_app_interference_20180606.csv', INTERS, [functor(interference),arity(3)]),
	maplist(assert, INTERS),
	csv_read_file('scheduling_preliminary_instance_deploy_20180606.csv', DEPLOY3, [functor(deploy),match_arity(false),arity(3)]),
	maplist(assert, DEPLOY3).

output([]) :- format('------EOF-------') .
output([[Machine,App1,App2,X,Cnt]|Rest]) :-
	format('~w\t~w\t~w\t~w\t~w\n',[Machine,App1,App2,X,Cnt]),
	output(Rest) .
	
main :-
	import,
	findall([Machine,App1,App2,X,Cnt],machine_interference(Machine,App1,App2,X,Cnt),L),
	output(L) .

main :-
	halt(1) .
