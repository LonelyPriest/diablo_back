%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 27 Oct 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_tree).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

make(Trees, #diablo_node{parent=0} = NewTree) ->
    [NewTree|Trees];
make(Trees, Node) ->
    %% ?DEBUG("make tree ~p, node ~p", [Trees, Node]),
    add([], Trees, Node).

add(_Left, [], _Child) ->
    none;
add(Left, [H|T], Child)->
    case add(H, Child) of
	none ->
	    add([H|Left], T, Child);
	NewChild-> lists:append([NewChild|T], Left)
    end.

add(#diablo_node{id=ParentId} = Parent, #diablo_node{parent = ParentId} = Child) ->
    Parent#diablo_node{children=[Child|node(children, Parent)]};
add(Parent, Child) ->
    case add([], node(children, Parent), Child) of
	none -> none;
	NewChildren ->
	    Parent#diablo_node{children=NewChildren}
    end.
    

node(id, #diablo_node{id=Id} = _N) ->
    Id;
node(name, #diablo_node{name=Name} = _N) ->
    Name;
node(action, #diablo_node{action=Action} = _N) ->
    Action;
node(parent, #diablo_node{parent=Parent} = _N) ->
    Parent;
node(children, #diablo_node{children=Children} = _N) ->
    Children.

list(Trees) ->
    travel(Trees, []).

travel([], Acc) ->
    Acc;
travel([H|T], Acc)->
    travel(T, Acc ++ travel(H)).

travel(Node) ->
    travel(node(children, Node),
	   [format(Node)]).


find_child([], _Node)->
    none;
find_child([H|T], Node) ->
    case find_child(H, Node) of
	none ->
	    find_child(T, Node);
	Child ->
	    Child
    end;
find_child(#diablo_node{id=Id} = Node, #diablo_node{id=Id}) ->
   Node;
find_child(Node, TobeFind) ->
    case find_child(node(children, Node), TobeFind) of
	none -> none;
	Children -> Children
    end.


get_root([], _Node)->
    none;
get_root([H|T], Node) ->
    case get_root(H, Node) of
	none ->
	    get_root(T, Node);
	Parent ->
	    Parent
    end;
get_root(#diablo_node{id=Id} = Node, #diablo_node{id=Id}) ->
   #diablo_node{id=node(id, Node),
		name=node(name, Node),
		action=node(action, Node),
		parent=node(parent, Node)};
get_root(Node, TobeFind) ->
    case get_root(node(children, Node), TobeFind) of
	none ->
	    none;
	_Children ->
	    ?DEBUG("find ~p", [_Children]),
	    #diablo_node{id=node(id, Node),
	    		 name=node(name, Node),
	    		 action=node(action, Node),
	    		 parent=node(parent, Node)}
    end.


    

format(#diablo_node{id=Id, name=Name, action=Action, parent=Parent} = _Node) ->
    {[{<<"id">>, Id},
      {<<"name">>, Name},
      {<<"action">>, Action},
      {<<"parent">>, Parent}]}.
	
test() ->
    
    N0 = #diablo_node{id=1000, name=a, parent=0},
    Tree0 = make([], N0),
    ?DEBUG("Tree0 ~p", [Tree0]),
    
    N1 = #diablo_node{id=1001, name=a1, parent=1000},
    Tree1 = make(Tree0, N1),
    ?DEBUG("Tree1 ~p", [Tree1]),

    N2 = #diablo_node{id=2002, name=a2, parent=1000},
    Tree2 = make(Tree1, N2),
    ?DEBUG("Tree2 ~p", [Tree2]),

    N3 = #diablo_node{id=1011, name=a11, parent=1001},
    Tree3 = make(Tree2, N3),
    ?DEBUG("Tree3 ~p", [Tree3]),

    N4 = #diablo_node{id=1012, name=a12, parent=1011},
    Tree4 = make(Tree3, N4),
    ?DEBUG("Tree4 ~p", [Tree4]),

    N5 = #diablo_node{id=1100, name=a1111, parent=1012},
    Tree5 = make(Tree4, N5),
    ?DEBUG("Tree5 ~p", [Tree5]),

    N6 = #diablo_node{id=1110, name=a11111, parent=1100},
    Tree6 = make(Tree5, N6),
    ?DEBUG("Tree6 ~p", [Tree6]),


    %% L = travel(Tree5#diablo_node.children, []),
    %% ?DEBUG("L ~p", [L]),
    %%L = list(Tree6),
    %%?DEBUG("L ~p", [L]),
    F = find_child(Tree6, N5),
    ?DEBUG("F = ~p", [F]),
    L = list([F]),
    ?DEBUG("L ~p", [L]),
    
    P = get_root(Tree6, N0),
    ?DEBUG("root = ~p, N0 ~p", [P, N0]),

    P5 = get_root(Tree6, N5),
    ?DEBUG("root = ~p, N0 ~p", [P5, N5]),

    
    ok.


