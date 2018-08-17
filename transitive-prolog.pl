%%%%-------------------
%%connect(X,Y) :- interference(X,Y,_); interference(Y,X,_) .
%%
%%neighbor(X,[X,Y],Min) :- connect(X,Y), minimal([X,Y],Min) .
%%neighbor(X,[X],Min) :- interference(Y,X,_), minimal([X,Y],Min) .
%%neighbor(X,[Z|Visited],Min) :-
%%	connect(X,Z),
%%	\+ member(X,Visited), neighbor(Z,Visited).
%%
%%%%--------------------
%%%% interference is non-symm directed relationship,make sym-interference relationship, build a SAMEGROUP graph
%%sym_interference(X,Y) :- interference(X,Y,_) ; interference(Y,X,_) .
%%interference(L1, L2) :-
%%  t_samegroup(L1, L2, [L1]).                   % <-- [L1] instead of []
%%
%%t_samegroup(L1, L2, IntermediateNodes) :-
%%  sym_interference(L1, L3),
%%  \+ member(L3, IntermediateNodes),
%%  ( L2=L3
%%  ; t_samegroup(L3, L2, [L3 | IntermediateNodes])) .
%%
%%%% --------------------
%%%% given an X, find X's root , a.k.a smallest element in the connected graph
%%minimal([M],M) .
%%minimal([H,S|T],M) :-
%%	H @=< S -> minimal([H|T],M) ;
%%	H @> S -> minimal([S|T],M) .
%%%%
%%findroot(X,Root) :-
%%	setof(Y, brother(X,Y),Bs) ,
%%	minimal([X|Bs],Root) . % make sure include X to it's connected GRAPH
%%
%%%append(Xs,Ys,XYs),
%%%list_to_set(XYs,All_nodes) .
