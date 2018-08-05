#!/usr/bin/swipl
:- style_check(-singleton).
%:- initialization main.
:- set_prolog_flag(verbose, silent).
:- use_module(library(csv)).

%%----Facts Sample:
%%==> scheduling_preliminary_app_interference_20180606.csv <==
interference(app_8361,app_1919,0) .
interference(app_1919,app_8017,1) .

%%==> scheduling_preliminary_instance_deploy_20180606.csv <==
deploy(inst_23673,app_1919,machine_4959) .
deploy(inst_23672,app_8017,machine_4959) .

%%==> scheduling_preliminary_app_resources_20180606.csv <==
app_resource(App,cpu,CPU) :- app(App,L), findall(E,(nth1(I,L,E),I>=1,I=<98),CPU) .
app_resource(App,memory,Memory) :- app(App,L), findall(E,(nth1(I,L,E),I>=99,I=<196),Memory) .
app_resource(App,disk,Disk) :- app(App,L), nth1(197,L,Disk) .
app_resource(App,m,M) :- app(App,L), nth1(198,L,M) .
app_resource(App,p,P) :- app(App,L), nth1(199,L,P) .
app_resource(App,mp,MP) :- app(App,L), nth1(200,L,MP) .

%%==> scheduling_preliminary_machine_resources_20180606.csv <==
machine(machine_4959,3,64,6,7,3,7) .
machine(machine_1919,32,64,6,7,3,7) .

%%--- property slicer & selector from original machine(x,x,x,x,x,x).
machine_resource(Machine,cpu,CPU) :- machine(Machine,CPU,_,_,_,_,_) .
machine_resource(Machine,memory,Memory) :- machine(Machine,_,Memory,_,_,_,_) .
machine_resource(Machine,disk,Disk) :- machine(Machine,_,_,Disk,_,_,_) .
machine_resource(Machine,m,M) :- machine(Machine,_,_,_,M,_,_) .
machine_resource(Machine,p,P) :- machine(Machine,_,_,_,_,P,_) .
machine_resource(Machine,mp,MP) :- machine(Machine,_,_,_,_,_,MP) .
									 
%%--- Rules
%%---------- helper functors, some may have library implementation to replace with in future --------
vector_sum([],[],[]) .
vector_sum([Ai|As],[Bi|Bs],[Ci|ABs]) :-
	Ci is Ai + Bi,
	vector_sum(As,Bs,ABs) .

vector_minus([],[],[]) .
vector_minus([Ai|As],[Bi|Bs],[Ci|ABs]) :-
	Ci is Ai - Bi,
	vector_minus(As,Bs,ABs) .

nvector_sum([L1],L1) .
nvector_sum([L1,L2],L3) :- vector_sum(L1,L2,L3) .
nvector_sum([L1,L2|Rest],Result) :-
	vector_sum(L1,L2,L3) ,
	nvector_sum(Rest,X) ,
	vector_sum(L3,X,Result) .

%%---- vector - scalar
vector_minus1([],M,[]) .
vector_minus1([X|Rest],M,[X_m|Rest_m]) :-
	X_m is X - M,
	vector_minus1(Rest,M,Rest_m) .

list_resource([X|Rest]) :- is_list(X) .
scalar_resource([X|Rest]) :- number(X) .

%%---------
machine_app_cnt(Machine,App,Cnt) :-
	setof(Instance, deploy(Instnace,App,Machine),LS),
	length(LS,Cnt) .

machine_interference(Machine,App1,App2,X,Cnt) :-
	deploy(_, App1,Machine),
	Machine \= empty,
	machine_app_cnt(Machine,App2,Cnt),
	interference(App1,App2,X),
	Cnt >=  X .

%%%---------
machine_load(Machine,Resource,Load) :-
	findall(X, (deploy(_,App,Machine), Machine \= empty, app_resource(App,Resource,X)), Xs) ,
	(list_resource(Xs) -> nvector_sum(Xs,Load) ; sum_list(Xs,Load)).

machine_overload(Machine,Resource,Overload) :-
	machine_load(Machine,Resource,Load),
	machine_resource(Machine,Resource,Xmax),
	(
		(is_list(Load), \+ forall(member(X,Load), X < Xmax), vector_minus1(Load,Xmax,Overload)) ;
		(number(Load), Load > Xmax , Overload is Load - Xmax) 
	) .

cpu_score1(X,Score) :-
	X =< 0.5 -> Score is 1;
	Score is (1+10*((e ** (X-0.5)) - 1)) / 98 .

cpu_score98(Ls,Score) :-
	maplist(cpu_score1, Ls,Tmp) , sum_list(Tmp,Score) .

machine_score(Machine,Score) :-
	machine_overload(Machine,_,_) -> Score is 1000 ;
	findall(X, (deploy(_,App,Machine), Machine \= empty, app_resource(App,cpu,X)), Xs) ,
	maplist(cpu_score98,Xs,Tmp) , sum_list(Tmp,Score).

%%%------MAIN-------
import :-
	csv_read_file('scheduling_preliminary_app_interference_20180606.csv', INTERS, [functor(interference),arity(3)]) ,
	maplist(assert, INTERS) ,
	csv_read_file('scheduling_preliminary_instance_deploy_20180606.csv', DEPLOY3, [functor(deploy),arity(3)]) ,
	maplist(assert, DEPLOY3) ,
	csv_read_file('scheduling_preliminary_machine_resources_20180606.csv', MACHINE, [functor(machine),arity(7)]) ,
	maplist(assert, MACHINE) ,
	[scheduling_preliminary_app_resources_20180606] .

output([]) :- format('------EOF-------') .
output([[Machine,App1,App2,X,Cnt]|Rest]) :-
	format('~w\t~w\t~w\t~w\t~w\n',[Machine,App1,App2,X,Cnt]),
	output(Rest) .
	
main :-
	import,
	%%findall([Machine,App1,App2,X,Cnt],machine_interference(Machine,App1,App2,X,Cnt),L),
	member(Resource,[cpu,memory,disk,m,p,mp]),
	findall([Machine,Resource,Overload,"null","null"],machine_overload(Machine,Resource,Overload),L),
	output(L) .

main :-
	halt(1) .


uncle(X,Y) :-
	fater_son(X,Z) ,
	brother(Z,Y) .
