% ----------------------------------------------------------------------
% PROLOG: Declaracoes iniciais
% ----------------------------------------------------------------------

:- style_check(-discontiguous).
:- style_check(-singleton).

% ----------------------------------------------------------------------
% PROLOG: definicoes iniciais
% ----------------------------------------------------------------------

:-include('arcos.pl').
:-include('pontos_recolha.pl').
:- use_module(library(lists)).

:- op( 900,xfy,'::' ).
:- dynamic arcos/3.
:- dynamic ponto_recolha/5.


% ----------------------------------------------------------------------
%                       Obtenção de factos 
% ----------------------------------------------------------------------

% Obtém o arco entre dois pontos
% arco(Ponto1,Ponto2,Distancia)
getArco(Origem,Destino,Dist) :- arco(Origem,Destino,Dist).

% ponto_recolha(Nome,Lat,Long,Tipo,QtdTotal)
getPonto(Nome,Lat,Long,Tipo,Qtd):- ponto_recolha(Nome,Lat,Long,Tipo,Qtd).

% Obtém a capacidade num dado ponto de um dado tipo
getCapacidadeTipo(Nodo,Capacidade,T):- ponto_recolha(Nodo,_,_,T,Capacidade).

% Obtém a capacidade total num dado ponto indiferente ao tipo
somaCapacidades([],0).
somaCapacidades([X|T],Capacidade):- somaCapacidades(T,Y), Capacidade is X + Y.

getCapacidadeTotal(Nodo,Capacidade) :- findall( Cap,ponto_recolha(Nodo,_,_,_,Cap),L), somaCapacidades(L,Capacidade).

% ----------------------------------------------------------------------
%                       Algoritmos de Procura 
% ----------------------------------------------------------------------

% inicial('R Ataide').
inicial('R do Alecrim').
% inicial('R Sao Bento').
% inicial('R da Boavista').

% final('Tv Corpo Santo').
% final('R Sao Paulo').
final('Av 24 de Julho').
% final('Pc Sao Paulo').
% final('R Imprensa Nacional').
% final('R Quintinha').

% Predicado que permite medir o tempo de execução de um outro predicado
measuretime(Predicado):- statistics(walltime, [TimeSinceStart | [TimeSinceLastCall]]),
                         Predicado,
                         statistics(walltime, [NewTimeSinceStart | [ExecutionTime]]),
                         write('Execution took '), write(ExecutionTime), write(' ms.'), nl.

% -------------------------- Não Informada -----------------------------%


% Predicado que verifica se dois pontos são adjacentes
adjacente(A,B,C) :- getArco(A,B,C).
adjacente(A,B,C) :- getArco(B,A,C).

% Predicado que verifica se um ponto de recolha contém um tipo de resíduos
isTipo(Nodo,Tipo):- ponto_recolha(Nodo,_,_,Tipo,_).

% Predicado que verifica se dois pontos de recolha são adjacentes e de um dado tipo de resíduos
adjacenteTipo(A,B,C,T) :- isTipo(A,T), isTipo(B,T),getArco(A,B,C).
adjacenteTipo(A,B,C,T) :- isTipo(A,T), isTipo(B,T),getArco(B,A,C).

% --------------------------
%   Procura Depth-First 
% --------------------------

% ------------------ PESQUISA POR RESÍDUO ------------------ 

% Depth-first que dá soluções de acordo com o número de arcos
resolvedf_arcos_tipo([X|Caminho],T):-
                inicial(X),
                resolvedf_arcos_tipo(X,[X],Caminho,T).

resolvedf_arcos_tipo(A, _ ,[],T):- final(A),!.
resolvedf_arcos_tipo(A, Historico, [Prox|Caminho],T):-
                adjacenteTipo(A,Prox,_,T),
                nao(membro(Prox,Historico)),
                resolvedf_arcos_tipo(Prox, [Prox|Historico], Caminho,T).

df_TodasSolucoes_arcos_tipo(L,T):- findall((C,N),(resolvedf_arcos_tipo(C,T),comprimento(C,N)),L).

df_Arcos_min_tipo(X,T):- findall((P,C),(resolvedf_arcos_tipo(P,T),comprimento(P,C)),L),pairwise_min(L,X).

df_Arcos_max_tipo(X,T):- findall((P,C),(resolvedf_arcos_tipo(P,T),comprimento(P,C)),L),pairwise_max(L,X).

% Depth-first que dá soluções de acordo com a distância
resolvedf_dist_tipo(Nodo,[Nodo|Caminho],Dist,T):-
                inicial(Nodo),
                df_dist_tipo(Nodo,[Nodo],Caminho,Dist,T).

df_dist_tipo(Nodo, _, [], 0,T):-
                final(Nodo).

df_dist_tipo(Nodo,Historico,[NodoProx|Caminho],Dist,T):-
                adjacenteTipo(Nodo,NodoProx,Dist1,T),
                nao(membro(NodoProx, Historico)),
                df_dist_tipo(NodoProx,[NodoProx|Historico],Caminho,Dist2,T),
                Dist is Dist1 + Dist2.

df_DistTodasSolucoes_tipo(L,T):- findall((S,D),(resolvedf_dist_tipo(N,S,D,T)),L).

df_Dist_melhor_tipo(Nodo,Cam,Dist,T):- findall((Ca,D), resolvedf_dist_tipo(Nodo,Ca,D,T), L),pairwise_min(L,(Cam,Dist)),imprime(Cam).

% Depth-first que dá soluções de acordo com a capacidade
resolvedf_cap_tipo(Nodo,[Nodo|Caminho],Cap,T):-
                inicial(Nodo),
                df_cap_tipo(Nodo,[Nodo],Caminho,Cap,T).

df_cap_tipo(Nodo, _, [], 0,T):-
                final(Nodo).

df_cap_tipo(Nodo,Historico,[NodoProx|Caminho],Cap,T):-
                adjacenteTipo(Nodo,NodoProx,_,T),
                getCapacidadeTipo(NodoProx,Cap1,T),
                nao(membro(NodoProx, Historico)),
                df_cap_tipo(NodoProx,[NodoProx|Historico],Caminho,Cap2,T),
                Cap is Cap1 + Cap2.

df_CapTodasSolucoes_tipo(L,T):- findall((S,C),(resolvedf_cap_tipo(N,S,C,T)),L).

df_Cap_melhor_tipo(Nodo,Cam,Cap,T):- findall((Ca,C), resolvedf_cap_tipo(Nodo,Ca,C,T), L),pairwise_min(L,(Cam,Cap)),imprime(Cam).


% ------------------ PESQUISA NORMAL ------------------ 


% Depth-first que dá soluções de acordo com o número de arcos
resolvedf_arcos([X|Caminho]):-
            inicial(X),
            resolvedf_arcos(X,[X],Caminho).

resolvedf_arcos(A, _ ,[]):- final(A),!.
resolvedf_arcos(A, Historico, [Prox|Caminho]):- 
            adjacente(A,Prox,_),
            nao(membro(Prox,Historico)),
            resolvedf_arcos(Prox, [Prox|Historico], Caminho).

df_TodasSolucoes_arcos(L):- findall((C,N),(resolvedf_arcos(C),comprimento(C,N)),L).

df_Arcos_min(X):- findall((P,C),(resolvedf_arcos(P),comprimento(P,C)),L),pairwise_min(L,X).

df_Arcos_max(X):- findall((P,C),(resolvedf_arcos(P),comprimento(P,C)),L),pairwise_max(L,X).

% Depth-first que dá soluções de acordo com a distância
resolvedf_dist(Nodo,[Nodo|Caminho],Dist):-
                inicial(Nodo),
                df_dist(Nodo,[Nodo],Caminho,Dist).

df_dist(Nodo, _, [], 0):-
                final(Nodo).

df_dist(Nodo,Historico,[NodoProx|Caminho],Dist):-
                adjacente(Nodo,NodoProx,Dist1),
                nao(membro(NodoProx, Historico)),
                df_dist(NodoProx,[NodoProx|Historico],Caminho,Dist2),
                Dist is Dist1 + Dist2.

df_DistTodasSolucoes(L):- findall((S,D),(resolvedf_dist(N,S,D)),L).

df_Dist_melhor(Nodo,Cam,Dist):- findall((Ca,D), resolvedf_dist(Nodo,Ca,D), L),pairwise_min(L,(Cam,Dist)),imprime(Cam).

% Depth-first que dá soluções de acordo com a capacidade
resolvedf_cap(Nodo,[Nodo|Caminho],Cap):-
                inicial(Nodo),
                df_cap(Nodo,[Nodo],Caminho,Cap).

df_cap(Nodo, _, [], 0):-
                final(Nodo).

df_cap(Nodo,Historico,[NodoProx|Caminho],Cap):-
                adjacente(Nodo,NodoProx,_),
                getCapacidadeTotal(NodoProx,Cap1),
                nao(membro(NodoProx, Historico)),
                df_cap(NodoProx,[NodoProx|Historico],Caminho,Cap2),
                Cap is Cap1 + Cap2.

df_CapTodasSolucoes(L):- findall((S,C),(resolvedf_dist(N,S,C)),L).

df_Cap_melhor(Nodo,Cam,Cap):- findall((Ca,C), resolvedf_cap(Nodo,Ca,C), L),pairwise_max(L,(Cam,Cap)),imprime(Cam).


% --------------------------
%   Procura Breadth-First 
% --------------------------

% ------------------ PESQUISA NORMAl ------------------ 

% Pesquisa breadth first de acordo com o número de arcos
resolve_bfs(Nodo,Final) :- inicial(Nodo),solve_bfs([[Nodo]],F),reverseL(F,Final).

solve_bfs([[N|Path]|_],[N|Path]) :- final(N).

solve_bfs([Path|Paths],Solution) :-
        extend_bfs(Path,NewPaths),
        append(Paths,NewPaths,Paths1),
        solve_bfs(Paths1,Solution).

extend_bfs([Node|Path], NewPaths) :-
        findall([NewNode, Node|Path],
        (adjacente(Node, NewNode,_),
        nao(membro(NewNode,[Node|Path]))),
        NewPaths),!.
        
extend_bfs(Path,_).

bfs_todas_solucoes(L):- findall((F,C),resolve_bfs(N,F),comprimento(F,C),L).

bfs_min(C,A):- findall((F,X),(resolve_bfs(N,F),comprimento(F,X)),L),pairwise_min(L,(C,A)).

bfs_max(C,A):- findall((F,X),(resolve_bfs(N,F),comprimento(F,X)),L),pairwise_max(L,(C,A)).

% ------------------ PESQUISA POR RESÍDUO ------------------ 

resolve_bfs_tipo(Nodo,Final,T,L) :- inicial(Nodo),solve_bfs_tipo([[Nodo]],F,T),reverseL(F,Final),comprimento(Final,L).

solve_bfs_tipo([[N|Path]|_],[N|Path],T) :- final(N).

solve_bfs_tipo([Path|Paths],Solution,T) :-
        extend_bfs_tipo(Path,NewPaths,T),
        append(Paths,NewPaths,Paths1),
        solve_bfs_tipo(Paths1,Solution,T).

extend_bfs_tipo([Node|Path], NewPaths,T) :-
        findall([NewNode, Node|Path],
        (adjacenteTipo(Node, NewNode,_,T),
        nao(membro(NewNode,[Node|Path]))),
        NewPaths),!.
        
extend_bfs_tipo(Path,_,T).

% -------------------------------
%   Procura Depth-First Limitada
% -------------------------------

% ------------------ PESQUISA NORMAl ------------------ 

% Depth-first com profundidade limitada que dá soluções de acordo com o número de arcos
resolvedf_arcos_profundidade([X|Caminho],Prof):-
                inicial(X),
                resolvedf_arcos_profundidade(X,[X],Caminho,Prof).

resolvedf_arcos_profundidade(A, _ ,[],_):- final(A),!.
resolvedf_arcos_profundidade(A, Historico, [Prox|Caminho],ProfMax):- 
                ProfMax > 0,
                adjacente(A,Prox,_),
                nao(membro(Prox,Historico)),
                NewProf is ProfMax - 1,
                resolvedf_arcos_profundidade(Prox, [Prox|Historico], Caminho,NewProf).

df_TodasSolucoes_arcos_profundidade(L,Prof):- findall((C,N),(resolvedf_arcos_profundidade(C,Prof),comprimento(C,N)),L).

df_Arcos_profundidade_min(X,Prof):- findall((P,C),(resolvedf_arcos_profundidade(P,Prof),comprimento(P,C)),L),pairwise_min(L,X).

df_Arcos_profundidade_max(X,Prof):- findall((P,C),(resolvedf_arcos_profundidade(P,Prof),comprimento(P,C)),L),pairwise_max(L,X).

% Depth-first com profundidade limitada que dá soluções de acordo com a distância
resolvedf_dist_profundidade(Nodo,[Nodo|Caminho],Dist,Prof):-
                inicial(Nodo),
                df_dist_profundidade(Nodo,[Nodo],Caminho,Dist,Prof).

df_dist_profundidade(Nodo, _, [], 0,_):-
                final(Nodo).

df_dist_profundidade(Nodo,Historico,[NodoProx|Caminho],Dist,ProfMax):-
                ProfMax > 0,
                adjacente(Nodo,NodoProx,Dist1),
                nao(membro(NodoProx, Historico)),
                NewProf is ProfMax - 1,
                df_dist_profundidade(NodoProx,[NodoProx|Historico],Caminho,Dist2,NewProf),
                Dist is Dist1 + Dist2.

df_DistTodasSolucoes_profundidade(L,P):- findall((S,D),(resolvedf_dist_profundidade(N,S,D,P)),L).

df_Dist_melhor_profundidade(Nodo,Cam,Dist,P):- findall((Ca,D), resolvedf_dist_profundidade(Nodo,Ca,D,P), L),pairwise_min(L,(Cam,Dist)).

% ------------------ PESQUISA POR RESÍDUO ------------------ 

% Depth-first com profundidade limitada que dá soluções de acordo com o número de arcos
resolvedf_arcos_profundidade_tipo([X|Caminho],Prof,T):-
                inicial(X),
                resolvedf_arcos_profundidade_tipo(X,[X],Caminho,Prof,T).

resolvedf_arcos_profundidade_tipo(A, _ ,[],_,_):- final(A),!.
resolvedf_arcos_profundidade_tipo(A, Historico, [Prox|Caminho],ProfMax,T):- 
                ProfMax > 0,
                adjacenteTipo(A,Prox,_,T),
                nao(membro(Prox,Historico)),
                NewProf is ProfMax - 1,
                resolvedf_arcos_profundidade_tipo(Prox, [Prox|Historico], Caminho,NewProf,T).

df_TodasSolucoes_arcos_profundidade_tipo(L,Prof,T):- findall((C,N),(resolvedf_arcos_profundidade_tipo(C,Prof,T),comprimento(C,N)),L).

df_Arcos_profundidade_melhor_tipo(X,Prof,T):- findall((P,C),(resolvedf_arcos_profundidade_tipo(P,Prof,T),comprimento(P,C)),L),pairwise_max(L,X).

% Depth-first com profundidade limitada que dá soluções de acordo com a distância
resolvedf_dist_profundidade_tipo(Nodo,[Nodo|Caminho],Dist,Prof,T):-
                inicial(Nodo),
                df_dist_profundidade_tipo(Nodo,[Nodo],Caminho,Dist,Prof,T).

df_dist_profundidade_tipo(Nodo, _, [], 0,_,_):-
                final(Nodo).

df_dist_profundidade_tipo(Nodo,Historico,[NodoProx|Caminho],Dist,ProfMax,T):-
                ProfMax > 0,
                adjacenteTipo(Nodo,NodoProx,Dist1,T),
                nao(membro(NodoProx, Historico)),
                NewProf is ProfMax - 1,
                df_dist_profundidade_tipo(NodoProx,[NodoProx|Historico],Caminho,Dist2,NewProf,T),
                Dist is Dist1 + Dist2.

df_DistTodasSolucoes_profundidade_tipo(L,P,T):- findall((S,D),(resolvedf_dist_profundidade_tipo(N,S,D,P,T)),L).

df_Dist_melhor_profundidade_tipo(Nodo,Cam,Dist,P,T):- findall((Ca,D), resolvedf_dist_profundidade_tipo(Nodo,Ca,D,P,T), L),pairwise_min(L,(Cam,Dist)),imprime(Cam).



% ---------------------------- Informada -------------------------------%

distance(Origem, Dis):-
    ponto_recolha(Origem,Lat1,Lon1,_,_),
    final(Destino),
    ponto_recolha(Destino,Lat2,Lon2,_,_),
    P is 0.017453292519943295,
    A is (0.5 - cos((Lat2 - Lat1) * P) / 2 + cos(Lat1 * P) * cos(Lat2 * P) * (1 - cos((Lon2 - Lon1) * P)) / 2),
    Dis1 is (12742 * asin(sqrt(A))),
    Dis is Dis1 * 1000.


estimaTipo(Nodo,Estima,Tipo) :- ponto_recolha(Nodo,_,_,Tipo,_),distance(Nodo,Estima).

estima(Nodo,Estima) :- distance(Nodo,Estima).

% --------------------------
%       Pesquisa Gulosa 
% --------------------------

% ------------------ PESQUISA NORMAl ------------------ 

resolve_gulosa(Nodo,Caminho/Custo):-
        estima(Nodo,Estima),
        agulosa([[Nodo]/0/Estima],InvCaminho/Custo/_),
        reverseL(InvCaminho,Caminho),!.

agulosa(Caminhos,Caminho):-
        obtem_melhor_g(Caminhos,Caminho),
        Caminho = [Nodo|_]/_/_,
        final(Nodo).

agulosa(Caminhos, SolucaoCaminho):-
        obtem_melhor_g(Caminhos,MelhorCaminho),
        escolhe(MelhorCaminho,Caminhos,OutrosCaminhos),
        expande_gulosa(MelhorCaminho,ExpCaminhos),
        append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
        agulosa(NovoCaminhos,SolucaoCaminho).

expande_gulosa(Caminho,ExpCaminhos):-
        findall(NovoCaminho,adjacente_gulosa(Caminho,NovoCaminho),ExpCaminhos).

adjacente_gulosa([Nodo|Caminho]/Custo/_,[ProxNodo,Nodo|Caminho]/NovoCusto/Est):-
        adjacente(Nodo,ProxNodo,PassoCusto), 
        nao(membro(ProxNodo,Caminho)),
        NovoCusto is Custo + PassoCusto,
        estima(ProxNodo,Est).

obtem_melhor_g([Caminho],Caminho):-!.

obtem_melhor_g([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos],MelhorCaminho):-
        Est1 =< Est2 , !,
        obtem_melhor_g([Caminho1/Custo1/Est1|Caminhos],MelhorCaminho).

obtem_melhor_g([_|Caminhos],MelhorCaminho):-
        obtem_melhor_g(Caminhos,MelhorCaminho).


% ------------------ PESQUISA POR RESÍDUO ------------------ 

resolve_gulosa_tipo(Nodo,Caminho/Custo,T):-
        estimaTipo(Nodo,Estima,T),
        agulosa_tipo([[Nodo]/0/Estima],InvCaminho/Custo/_,T),
        reverseL(InvCaminho,Caminho),!.

agulosa_tipo(Caminhos,Caminho,T):-
        obtem_melhor_g(Caminhos,Caminho),
        Caminho = [Nodo|_]/_/_,
        final(Nodo).

agulosa_tipo(Caminhos, SolucaoCaminho,T):-
        obtem_melhor_g(Caminhos,MelhorCaminho),
        escolhe(MelhorCaminho,Caminhos,OutrosCaminhos),
        expande_gulosa_tipo(MelhorCaminho,ExpCaminhos,T),
        append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
        agulosa_tipo(NovoCaminhos,SolucaoCaminho,T).

expande_gulosa_tipo(Caminho,ExpCaminhos,T):-
        findall(NovoCaminho,adjacente_gulosa_tipo(Caminho,NovoCaminho,T),ExpCaminhos).

adjacente_gulosa_tipo([Nodo|Caminho]/Custo/_,[ProxNodo,Nodo|Caminho]/NovoCusto/Est,T):-
        adjacente(Nodo,ProxNodo,PassoCusto), 
        nao(membro(ProxNodo,Caminho)),
        NovoCusto is Custo + PassoCusto,
        estimaTipo(ProxNodo,Est,T).

obtem_melhor_g([Caminho],Caminho):-!.

obtem_melhor_g([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos],MelhorCaminho):-
        Est1 =< Est2 , !,
        obtem_melhor_g([Caminho1/Custo1/Est1|Caminhos],MelhorCaminho).

obtem_melhor_g([_|Caminhos],MelhorCaminho):-
        obtem_melhor_g(Caminhos,MelhorCaminho).


descobre_todas_gulosa_tipo(S,T):- findall((N,Caminho/Custo/Estima/T),resolve_gulosa_tipo(N,Caminho/Custo/Estima/T,T),S).

% --------------------------
%    Pesquisa A Estrela 
% --------------------------

% ------------------ PESQUISA NORMAl ------------------ 

resolve_aestrela(Nodo,Caminho/Custo):-
        estima(Nodo,Estima),
        aestrela([[Nodo]/0/Estima],InvCaminho/Custo/_),
        reverseL(InvCaminho,Caminho),!.

aestrela(Caminhos,Caminho):-
        obtem_melhor(Caminhos,Caminho),
        Caminho = [Nodo|_]/_/_,final(Nodo).

aestrela(Caminhos,SolucaoCaminho):-
        obtem_melhor(Caminhos,MelhorCaminho),
        escolhe(MelhorCaminho,Caminhos,OutrosCaminhos),
        expande_aestrela(MelhorCaminho,ExpCaminhos),
        append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
        aestrela(NovoCaminhos,SolucaoCaminho).

expande_aestrela(Caminho,ExpCaminhos):-
        findall(NovoCaminho,adjacente_aestrela(Caminho,NovoCaminho),ExpCaminhos).

adjacente_aestrela([Nodo|Caminho]/Custo/_,[ProxNodo,Nodo|Caminho]/NovoCusto/Est):-
        adjacente(Nodo,ProxNodo,PassoCusto), 
        nao(membro(ProxNodo,Caminho)),
        NovoCusto is Custo + PassoCusto,
        estima(ProxNodo,Est).

obtem_melhor([Caminho],Caminho):- !.

obtem_melhor([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos],MelhorCaminho):-
        Custo1 + Est1 =< Custo2 + Est2,!,
        obtem_melhor([Caminho1/Custo1/Est1|Caminhos],MelhorCaminho).

obtem_melhor([_|Caminhos],MelhorCaminho):-
        obtem_melhor(Caminhos,MelhorCaminho).

% ------------------ PESQUISA POR RESÍDUO ------------------

resolve_aestrela_tipo(Nodo,Caminho/Custo,T):-
        estimaTipo(Nodo,Estima,T),
        aestrela_tipo([[Nodo]/0/Estima],InvCaminho/Custo/_,T),
        reverseL(InvCaminho,Caminho),!.

aestrela_tipo(Caminhos,Caminho,T):-
        obtem_melhor(Caminhos,Caminho),
        Caminho = [Nodo|_]/_/_,
        final(Nodo).

aestrela_tipo(Caminhos,SolucaoCaminho,T):-
        obtem_melhor(Caminhos,MelhorCaminho),
        escolhe(MelhorCaminho,Caminhos,OutrosCaminhos),
        expande_aestrela_tipo(MelhorCaminho,ExpCaminhos,T),
        append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
        aestrela_tipo(NovoCaminhos,SolucaoCaminho,T).

adjacenteEstrela_tipo([Nodo|Caminho]/Custo/_,[ProxNodo,Nodo|Caminho]/NovoCusto/Est,T):-
        adjacente(Nodo,ProxNodo,PassoCusto), 
        nao(membro(ProxNodo,Caminho)),
        NovoCusto is Custo + PassoCusto,
        estimaTipo(ProxNodo,Est,T).

expande_aestrela_tipo(Caminho,ExpCaminhos,T):-
        findall(NovoCaminho,adjacenteEstrela_tipo(Caminho,NovoCaminho,T),ExpCaminhos).

obtem_melhor([Caminho],Caminho):- !.

obtem_melhor([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos],MelhorCaminho):-
        Custo1 + Est1 =< Custo2 + Est2,!,
        obtem_melhor([Caminho1/Custo1/Est1|Caminhos],MelhorCaminho).

obtem_melhor([_|Caminhos],MelhorCaminho):-
        obtem_melhor(Caminhos,MelhorCaminho).


% --------------------------
%   Funcionalidades Extra 
% --------------------------

getTotalPontosRecolha(Qtd) :- findall(Nodo,ponto_recolha(Nodo,_,_,_,_),R),comprimento(R,Qtd).

getTotalPontosRecolhaTipo(Tipo,Qtd) :- findall(Nodo,ponto_recolha(Nodo,_,_,Tipo,_),R),comprimento(R,Qtd).

getTotalArcos(Qtd) :- findall(Nodo,arco(Nodo,_,_),R),comprimento(R,Qtd). 


% ----------------------------------------------------------------------
%                       Predicados Úteis
% ----------------------------------------------------------------------


% Extensao do meta-predicado nao
nao( Questao ) :-
    Questao, !, fail.
nao( _ ).

% Calcula o comprimento de uma lista
comprimento(S,N) :- length(S,N).

% Predicado que da um print no terminal
imprime([]).
imprime([X|T]) :- write(X), nl, imprime(T).

% Tira o elemento D de uma lista
escolhe(E,[E|Xs],Xs).
escolhe(E,[X|Xs],[X|Ys]):- escolhe(E,Xs,Ys).

% Inverte uma lista
reverseL(Ds,Es) :- reverseL(Ds, [], Es).
reverseL([],Ds,Ds).
reverseL([D|Ds],Es,Fs) :- reverseL(Ds, [D|Es], Fs).

% Verifica se um dado elemento já pertence à lista
membro(X, [X|_]).
membro(X, [_|Xs]):-
	membro(X, Xs).

% Predicado que devolve o par de menor valor no 2o elemento de uma lista
pairwise_min(L, (A,B)) :-
    select((A,B), L, R),
    \+ ( member((A1,B1), R), B1 < B ).

% Predicado que devolve o par de maior valor no 2o elemento de uma lista
pairwise_max(L, (A,B)) :-
    select((A,B), L, R),
    \+ ( member((A1,B1), R), B1 > B ).

% Permite limpar o terminal do PROLOG
cls :- write('\33\[2J').