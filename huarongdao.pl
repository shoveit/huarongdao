#!/usr/bin/swipl
:- style_check(-singleton).
%:- initialization main.
:- set_prolog_flag(verbose, silent).
:- use_module(library(csv)).
:- use_module(library(lambda)).

%%==> scheduling_preliminary_app_resources_20180606.csv <==
app_resource(App,cpu,CPU) :- app(App,L), findall(E,(nth1(I,L,E),I>=1,I=<98),CPU) .
app_resource(App,memory,Memory) :- app(App,L), findall(E,(nth1(I,L,E),I>=99,I=<196),Memory) .
app_resource(App,disk,Disk) :- app(App,L), nth1(197,L,Disk) .
app_resource(App,m,M) :- app(App,L), nth1(198,L,M) .
app_resource(App,p,P) :- app(App,L), nth1(199,L,P) .
app_resource(App,mp,MP) :- app(App,L), nth1(200,L,MP) .

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
vector_sum([Ai|As],[Bi|Bs],[Ci|ABs]) :- Ci is Ai + Bi, vector_sum(As,Bs,ABs) .

vector_minus([],[],[]) .
vector_minus([Ai|As],[Bi|Bs],[Ci|ABs]) :- Ci is Ai - Bi, vector_minus(As,Bs,ABs) .

nvector_sum([L1],L1) .
nvector_sum([L1,L2],L3) :- vector_sum(L1,L2,L3) .
nvector_sum([L1,L2|Rest],Result) :- vector_sum(L1,L2,L3) , nvector_sum(Rest,X) , vector_sum(L3,X,Result) .

vector_minus1([],M,[]) .
vector_minus1([X|Rest],M,[X_m|Rest_m]) :-
	X_m is X - M,
	vector_minus1(Rest,M,Rest_m) .

list_resource([X|Rest]) :- is_list(X) .
scalar_resource([X|Rest]) :- number(X) .

%%--------- business rules
machine_app_cnt(Machine,App,Cnt) :-
	setof(Instance, deploy(Instnace,App,Machine),LS),
	length(LS,Cnt) .

machine_interference(Machine,App1,App2,X,Cnt) :-
	deploy(_, App1,Machine),
	Machine \= empty,
	machine_app_cnt(Machine,App2,Cnt),
	interference(App1,App2,X),
	Cnt >  X .

%%%---------
machine_load(Machine,Resource, LoadPercent) :-
	findall(X, ( Machine \= empty,deploy(_,App,Machine), app_resource(App,Resource,X)), Xs) ,
	machine_resource(Machine,Resource,Xmax),
	scalar_resource(Xs), machine_resource(Machine,Resource,Xmax), sum_list(Xs,Load) , LoadPercent is Load / Xmax .
machine_load(Machine,Resource, LoadPercent) :-
	findall(X, ( Machine \= empty,deploy(_,App,Machine), app_resource(App,Resource,X)), Xs) ,
	machine_resource(Machine,Resource,Xmax),
	list_resource(Xs) , (nvector_sum(Xs,Load), maplist(\X^Y^(Y is X / Xmax), Load, LoadPercent)).

%--- always call with instanciated Machine
machine_overload(Machine,Resource) :-
	machine_load(Machine,Resource,Load), is_list(Load), \+ forall(member(X,Load), X =< 1) .
machine_overload(Machine,Resource) :-
	machine_load(Machine,Resource,Load), number(Load), Load >= 1 .

cpu_score1(X,Score) :-
	X =< 0.5 -> Score is 0;
	Score is 10*((e ** (X-0.5)) - 1) / 98 .

machine_score(Machine,100) :-
	machine_overload(Machine,_)  .
machine_score(Machine,1) :-	%%----- empty machine or machine not exist
	machine_load(Machine,cpu,0) .
machine_score(Machine,Score) :-
	%-- penalty score
	findall(100*(Cnt-X), machine_interference(Machine, App1,App2,X,Cnt), Penalty),
	sum_list(Penalty, PenaltyScore),
	%-- load score
	machine_resource(Machine,cpu,Max), machine_load(Machine,cpu,Load),
	maplist(\X^Y^(cpu_score1(X/Max,Y)), Load, LoadScore),
	%-- sum
	sum_list([1+PenaltyScore|LoadScore] , Score) .

%%-------test: findall([Machine,Inst,App],( deploy(Inst,App,Machine), Machine \= empty), Dispatch) , findall(Move, (nth1(I, Dispatch,Move),I>=10, I=<20),Moves) , evaluate_move(Inst,Machine1,Machine2,Score,Moves) .
evaluate_move(Inst,Machine1,Machine2,Score,Moves) :-
	deploy(Inst,App,Machine1),
	member([Machine1,Inst,_] , Moves),	member([Machine2,_,_] , Moves),
	Machine1 \= Machine2, \+ machine_interference(Machine2,_,_,_,_) , 
	machine_score(Machine1,Score1), machine_score(Machine2,Score2),
	retract(deploy(Inst,App,Machine1)), assert(deploy(Inst,App,Machine2)),
	machine_score(Machine1,Score1_), machine_score(Machine2,Score2_),
	retract(deploy(Inst,App,Machine2)), assert(deploy(Inst,App,Machine1)),
	% any difference < 0 is good; desolve a interferenced machine will decrease  score -100.
	Score is Score1_ + Score2_ - Score1 - Score2  .  

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
	%------- test1 
	%%findall([Machine,App1,App2,X,Cnt],machine_interference(Machine,App1,App2,X,Cnt),L),
	%------- test2
	member(Resource,[cpu,memory,disk,m,p,mp]),
	findall([Machine,Resource,Overload,"null","null"],machine_overload(Machine,Resource,Overload),L),
	%------- test3
	output(L) .

main :-
	halt(1) .
