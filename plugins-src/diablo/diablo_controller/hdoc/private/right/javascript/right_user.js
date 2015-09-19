// =============================================================================
// user
// =============================================================================

rightUserApp.controller(
    "roleUserNewCtrl",
    function($scope, $q, $location, diabloUtilsService, rightService){
	var promise = rightService.promise;
	$q.all([
	    promise(rightService.list_right_catlog)(),
	    promise(rightService.get_inventory_children)(),
	    promise(rightService.get_sales_children)(),
	    promise(rightService.list_shop)()
	]).then(function(data){
	    console.log(data);
	    // data[0] are the right catlogs
	    // data[1] are the inventory's children
	    // data[2] are the sale's children
	    // data[3] are the shops of current merchant
	    tree_utils.build_select_tree($scope.userRoleTree, data[0]);

	    // $scope.inventories = data[1];
	    $scope.all_right = data[0];
	    $scope.sales     = data[2];
	    $scope.shops     = data[3];
	    
	    angular.forEach(data[1], function(inv){
		tree_utils.add_children(
		    $scope.userRoleTree, $scope.shops, inv.id)
	    });

	    angular.forEach($scope.sales, function(sale){
		tree_utils.add_children(
		    $scope.userRoleTree, $scope.shops, sale.id)
	    });

	    $scope.init_tree = true;
	    
	});
		
	// callback of select a right catlog
	$scope.onSelect = function(select, node){
	    $scope.selectedNodes = node.tree.getSelectedNodes(true);
	    $scope.$apply(function(){
		$scope.empty_role_right = false;
	    });	    
	};

	var roleDetailPath = "#/role_user/role_detail"
	var in_shop = function(shops, ashopId){
	    if (angular.isArray(shops)){
		var length = shops.length;
		for (var i = 0; i < length; i++){
		    if (angular.equals(shops[i].id.toString(), ashopId)){
			return true;
		    }
		}
	    }
	    return false;
	};

	var in_shop_action = function(actions, item){
	    if (angular.isArray(actions)){
		var length = actions.length;
		for (var i = 0; i < length; i++){
		    if (angular.equals(actions[i], item)){
			return true;
		    }
		}
	    }
	    return false;
	};

	var has_sub_array = function(array, sub){
	    for (var i=0, l=sub.length; i<l; i++){
		if (!in_array(array, sub[i])){
		    return false;
		}
	    }

	    return true;
	};
	
	var get_children_of_catlog = function(catlogs, item){
	    var children = [];
	    for(var i=0, l=catlogs.length; i<l; i++){
		if(catlogs[i].parent === parseInt(item)){
		    children.push(catlogs[i].id);
		}
	    }
	    return children;
	};

	var delete_node = function(nodes, item){
	    for(var i=0, l=nodes.length; i<l; i++){
		if(nodes[i] === parseInt(item)){
		    nodes.splice(i, 1)
		}
	    }
	};

	// add role
	$scope.new_role = function(){
	    console.log($scope.selectedNodes);
	    console.log($scope.userRoleTree);
	    var keyIds = [];
	    var shopInfo = [];
	    angular.forEach($scope.selectedNodes, function(node){
		// console.log(node);
		var selectedKey = node.data.key;
		// leaf node
		if (!node.hasChildren()){
		    var parentKey = node.getParent().data.key;
		    // shop node
		    if (in_shop($scope.shops, selectedKey)){
			shopInfo.push({
			    operation:parseInt(parentKey), shop:parseInt(selectedKey)});

			// add the parent
			if (!in_array(keyIds, parentKey)){
			    keyIds.push(parseInt(parentKey));
			}
		    }else{
			keyIds.push(parseInt(selectedKey));
		    }
		}
		else{
		    // visit child, add the shop node
		    node.visit(function(v){
			if (in_shop($scope.shops, v.data.key)){
			    var parentKey = v.getParent().data.key;
			    var action = {operation: parseInt(parentKey),
					  shop: parseInt(v.data.key)};
			    if (!in_shop_action(shopInfo, action)){
				shopInfo.push(action);
			    }
			}
		    }, false);

		    if (!in_array(keyIds, selectedKey)){
			keyIds.push(parseInt(selectedKey))
		    }
		}
	    });

	    console.log(keyIds, shopInfo);
	    if (keyIds.length < 1 && ShopInfo.length < 1){
		$scope.empty_role_right = true;
		return;
	    };

	    // sort key ids
	    var rootRight = [];
	    angular.forEach($scope.all_right, function(r){
		if (r.parent === 0){
		    rootRight.push(r.id);
		}
	    });
	    
	    angular.forEach(rootRight, function(n){
		var children = get_children_of_catlog($scope.all_right, n);
		if (has_sub_array(keyIds, children)){
		    angular.forEach(children, function(child){
			delete_node(keyIds, child)
		    })

		    if (!in_array(keyIds, n)){
			keyIds.push(n);
		    }
		}
	    });

	    console.log(keyIds);

	    // add
	    rightService.add_role(
	    	$scope.role, rightService.roleType.user, {fun_id:keyIds, shops:shopInfo}
	    ).$promise.then(function (state){
	    	console.log(state);
	    	if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "新增角色", "恭喜你，角色 " + $scope.role.name + " 创建成功！！",
			$scope, function(){location.href = roleDetailPath});
	    	} else{
		    diabloUtilsService.response(
			false, "新增角色", "角色创建失败： "
			    + rightService.error[state.ecode]);
	    	}
	    })
	};

	$scope.cancel_new_role = function(){
	    location.href = roleDetailPath;
	}

    });


rightUserApp.controller(
    "roleUserDetailCtrl",
    function($scope, $q, diabloUtilsService, rightService){
	// console.log($scope);
	$scope.roleTypeDesc = rightService.roleTypeDesc;
	$scope.filter = {name:'', created_by:''};
	//$scope.rightCatlogs =[];

	// get all role info
	rightService.list_role().$promise.then(function(roles){
	    console.log(roles);
	    diablo_order(roles);
	    $scope.roles = roles; 
	});


	$scope.goto_page = function(path){
	    window.location = path;
	};
	
	$scope.role_detail = function(role){
	    rightService.user_role_right(role.id).then(function(data){
		console.log(data);
		var callback = function(rightTree){
		    // data[0] are the right catlogs
		    // data[1] are the shops of current role 
		    rightTree.reload(); 
		    tree_utils.build_unselect_tree(rightTree, data[0]);
		    angular.forEach(data[1], function(shop){
			tree_utils.add_child(
			    rightTree, {name: shop.name, id: shop.shop_id}, shop.func_id)
		    });
		};

		rightService.tree_modal(
		    'role-user-detail.html', $scope, callback, undefined);
	    });
	};

	
	/*
	 * update 
	 */
	var get_children_of_tree = function(tree, key){
	    var ids = [];
	    var treeNode = tree.getNodeByKey(key.toString());
	    if ( treeNode !== null ){
		var children = treeNode.getChildren();
		if ( children !== null ){
		    angular.forEach(children, function(child){
			ids.push(parseInt(child.data.key))
		    });
		}
	    }
	    return ids;
	};
	
	$scope.edit_role = function(role){
	    $scope.update_role = role;
	    var promise = rightService.promise;
	    $q.all([
		// role right of all can be select
		promise(rightService.list_right_catlog)(),
		promise(rightService.get_inventory_children)(),
		promise(rightService.get_sales_children)(),
		promise(rightService.list_shop)(),
		// role right of current has been selected
		promise(rightService.get_right_by_role_id, role.id)(),
		promise(rightService.get_shop_by_role, role.id)()])
		.then(function(data){
		    console.log(data); 
		    // data[0] are the right of all role
		    // data[1] are the child node of inventory
		    // data[2] are the child node of sale
		    // data[3] are the shops of all role
		    // data[4] are the right of current role
		    // data[5] are the shops of current role
		    $scope.all_right             = data[0];
		    $scope.children_of_inventory = data[1];
		    $scope.children_of_sale      = data[2];
		    $scope.all_shops             = data[3];
		    $scope.current_right         = data[4];
		    $scope.current_shops         = data[5];

		    var callback = function(tree){
			// build tree of current role
			tree.reload();
			tree_utils.build_edit_tree(tree, $scope.current_right);
			angular.forEach($scope.current_shops, function(shop){
			    tree_utils.add_select_node(
				tree, {name:shop.name, id:shop.shop_id}, shop.func_id)
			});

			var fireNode = tree.getNodeByKey($scope.current_shops[0].shop_id.toString());
			$scope.onSelect.call(tree, true, fireNode);

			// add other right not be selected
			tree_utils.add_nodes(tree, $scope.all_right);

			// add other shops not be selected
			var add_shops = function(nodes, shops){
			    angular.forEach(nodes, function(n){
				// get current shops
				var current = tree.getNodeByKey(n.id.toString());
				if (current !== null){
				    var selectShops = get_children_of_tree(tree, n.id);
				    // console.log(selectShops);
				    if (selectShops.length !== 0){
					angular.forEach(shops, function(shop){
					    if (!in_array(selectShops, shop.id)){
						tree_utils.add_children(tree, [shop], n.id);
					    }
					});
				    } else{
					tree_utils.add_children(tree, shops, n.id);
				    }
				}
			    })
			};

			add_shops($scope.children_of_inventory, $scope.all_shops);
			add_shops($scope.children_of_sale, $scope.all_shops);
		    };

		    rightService.tree_modal(
			'role-user-edit.html', $scope, callback, $scope.do_update);
		})
	};	

	var delete_node = function(nodes, item){
	    for(var i=0, l=nodes.length; i<l; i++){
		if(nodes[i] === parseInt(item)){
		    nodes.splice(i, 1)
		}
	    }
	};
	
	var get_children_of_catlog = function(catlogs, item){
	    var children = [];
	    for(var i=0, l=catlogs.length; i<l; i++){
		if(catlogs[i].parent === parseInt(item)){
		    children.push(catlogs[i].id);
		}
	    }
	    return children;
	};

	var has_sub_array = function(array, sub){
	    for (var i=0, l=sub.length; i<l; i++){
		if (!in_array(array, sub[i])){
		    return false;
		}
	    }

	    return true;
	};

	var in_shop = function(shops, ashopId){
	    if (angular.isArray(shops)){
		var length = shops.length;
		for (var i = 0; i < length; i++){
		    if (angular.equals(shops[i].id.toString(), ashopId)){
			return true;
		    }
		}
	    }

	    return false;
	};

	var in_shop_action = function(actions, item){
	    if (angular.isArray(actions)){
		var length = actions.length;
		for (var i = 0; i < length; i++){
		    if (angular.equals(actions[i], item)){
			return true;
		    }
		}
	    }

	    return false;
	};

	// callback of select tree
	$scope.onSelect = function(select, node){
	    $scope.current_selected = node.tree.getSelectedNodes(true);

	    $scope.newSelectedShops = [];
	    $scope.addonSelect = [];
	    angular.forEach($scope.current_selected, function(node){
		// console.log(node);
		var selectedKey = node.data.key;
		// leaf node
		if (!node.hasChildren()){
		    var parentKey = node.getParent().data.key;
		    // shop node
		    if (node.isSelected() && in_shop($scope.all_shops, selectedKey)){
			$scope.newSelectedShops.push({
			    operation:parseInt(parentKey), shop:parseInt(selectedKey)});
			// add the parent
			if (!in_array($scope.addonSelect, parseInt(parentKey))){
			    $scope.addonSelect.push(parseInt(parentKey));
			}
		    }
		} else{
		    // visit child, add the shop node
		    node.visit(function(v){
			if (v.isSelected() && in_shop($scope.all_shops, v.data.key)){
			    var parentKey = v.getParent().data.key;
			    var action = {operation: parseInt(parentKey),
					  shop: parseInt(v.data.key)};
			    if (!in_shop_action($scope.newSelectedShops, action)){
				$scope.newSelectedShops.push(action);
			    }
			}
		    }, false);
		}
	    });

	    console.log($scope.newSelectedShops);
	    console.log($scope.addonSelect);
	};

	// 
	$scope.do_update = function(){
	    console.log("do update");
	    // sort
	    var rootRight = [];
	    angular.forEach($scope.all_right, function(r){
		if (r.parent === 0){
		    rootRight.push(r.id);
		}
	    });

	    var newSelected = [];
	    angular.forEach($scope.current_selected, function(r){
		if (!in_shop($scope.all_shops, r.data.key)){
		    newSelected.push(parseInt(r.data.key));
		}
	    });
	    newSelected = newSelected.concat($scope.addonSelect);
	    
	    angular.forEach(rootRight, function(n){
		var children = get_children_of_catlog($scope.all_right, n);
		if (has_sub_array(newSelected, children)){
		    angular.forEach(children, function(child){
			delete_node(newSelected, child)
		    })

		    newSelected.push(n);
		}
	    });
	    
	    // added
	    var oldSelected = [];
	    angular.forEach($scope.current_right, function(r){
		oldSelected.push(r.id);
	    });
	    
	    angular.forEach(rootRight, function(n){
		var children = get_children_of_catlog($scope.all_right, n);
		if ( children.length > 0 ) {
		    // delete all the children of the n since the parent saved
		    if(has_sub_array(oldSelected, children)){
			angular.forEach(children, function(child){
			    delete_node(oldSelected, child)
			})
		    };

		    // delete n since the children saved
		    angular.forEach(oldSelected, function(old){
			if (in_array(children, old)){
			    delete_node(oldSelected, n)
			}
		    })
		}
	    });

	    console.log(newSelected);
	    console.log(oldSelected);

	    // get modified nodes
	    var added_nodes = [];
	    angular.forEach(newSelected, function(n){
		if (!in_array(oldSelected, n)){
		    added_nodes.push(n);
		}
	    });

	    var deleted_nodes = [];
	    angular.forEach(oldSelected, function(old){
		if (!in_array(newSelected, old)){
		    deleted_nodes.push(old);
		}
	    });
	    
	    console.log(added_nodes);
	    console.log(deleted_nodes);

	    // shop
	    var added_shops = [];
	    angular.forEach($scope.newSelectedShops, function(shop){
		var to_be_add = function(){
		    for (var i=0, l=$scope.current_shops.length; i<l; i++){
			if (shop.operation === $scope.current_shops[i].func_id
			    && shop.shop === $scope.current_shops[i].shop_id ){
			    return false;
			}
		    }
		    return true;
		}

		if (to_be_add()){
		    added_shops.push(shop);
		}
		
	    });
	    
	    var deleted_shops = [];
	    angular.forEach($scope.current_shops, function(shop){
		var ashop = {operation:shop.func_id, shop:shop.shop_id};
		if (!in_shop_action($scope.newSelectedShops, ashop)){
		    deleted_shops.push(ashop);
		}
	    });

	    
	    console.log(added_shops);
	    console.log(deleted_shops);
	    
	    if (added_nodes.length === 0 && deleted_nodes.length === 0
		&& added_shops.length === 0 && deleted_shops.length === 0){
		diabloUtilsService.response(
		    false, "权限编辑", "权限编辑失败：" + rightService.error[6001], $scope);
		return;
	    };

	    rightService.update_user_role(
		$scope.update_role, added_nodes, deleted_nodes, added_shops, deleted_shops)
		.$promise.then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			diabloUtilsService.response(true, "权限编辑", "权限编辑成功！！", $scope);
			return;
		    } else{
			diabloUtilsService.response(
			    false,
			    "权限编辑", "权限编辑失败："
				+ rightService.error[state.ecode], $scope);
		    }
		});
	};

	$scope.delete_role = function(role){
	    diabloUtilsService.response(
		false, "权限编辑", "权限编辑失败：" + rightService.error[7001], $scope);
	    return;
	};

    });

// =============================================================================
// user account
// =============================================================================
rightUserApp.controller(
    "accountUserNewCtrl",
    function($scope, diabloUtilsService, rightService, merchantService){

	rightService.list_role().$promise.then(function(roles){
	    console.log(roles)
	    // $scope.roles = roles;
	    // diablo_order($scope.roles)
	    $scope.roles = [];
	    angular.forEach(roles, function(r){
		$scope.roles.push({
		    id:   r.id,
		    name: r.name,
		    py:   diablo_pinyin(r.name)   
		})
	    });
	    
	    // diablo_order($scope.roles);
	})

	$scope.on_role_select = function(item, model, label){
	    //console.log(item);
	    //console.log(model);
	    $scope.roleTree.reload();
	    rightService.user_role_right(model.id).then(function(data){
		// console.log(data);
		tree_utils.build_unselect_tree($scope.roleTree, data[0]);

		// add shop right
		angular.forEach(data[1], function(shop){
		    tree_utils.add_child(
			$scope.roleTree,
			{name: shop.name, id: shop.shop_id}, shop.func_id)
		});
		$scope.init_tree=true;
	    })
	};

	$scope.account = {type: rightService.roleType.user};

	// new user account
	$scope.new_account = function(){
	    console.log($scope.account);
	    rightService.add_account($scope.account).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "新增帐户", "帐户 [" + $scope.account.name + "] 创建成功",
			$scope, function(){
			    diablo_goto_page("#/account_user/account_detail")}); 

		} else{
		    diabloUtilsService.response(
			false, "新增帐户", "帐户创建失败："
			    +  rightService.error[state.ecode]); 
		}
	    })};

	$scope.cancel = function(){
	     diablo_goto_page("#/account_user/account_detail");
	};

    });



rightUserApp.controller(
    "accountUserDetailCtrl",
    function($scope, $routeParams, $q, $modal, rightService, diabloUtilsService){
	$scope.roleDesc = rightService.roleTypeDesc;
	$scope.accountDesc = rightService.accountDesc;

	// list
	rightService.list_account().$promise.then(function(accounts){
	    console.log(accounts);
	    diablo_order(accounts);
	    $scope.accounts = accounts; 
	});

	$scope.goto_page = function(path){
	    window.location = path;
	};


	$scope.show_account_right = false;
	// lookup account right
	$scope.right_detail = function(account){
	    console.log(account); 
	    // get the roles of the account
	    rightService.list_account_right(account).$promise.then(function(roles){
		console.log(roles);
		// get the right of the role, now, one user has only one role
		// so, use roles[0]
		rightService.user_role_right(roles[0].role_id).then(function(data){
		    console.log(data);
		    // reload right tree
		    var callback = function(tree){
			tree.reload();
			tree_utils.build_unselect_tree(tree, data[0]);
			angular.forEach(data[1], function(shop){
			    tree_utils.add_child(
				tree, {name: shop.name, id: shop.shop_id}, shop.func_id)
			});
		    };

		    rightService.tree_modal(
			'account_user_detail.html', $scope, callback, undefined);
		})
	    })
	};

	// delete
	$scope.delete_account = function(account){
	    var do_delete = function(){
		console.log(account);
		rightService.delete_account(account).$promise.then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "删除帐户", "帐户 " + account.name + " 删除成功",
			    $scope, function(){location.reload()})
		    } else{
			diabloUtilsService.response(
			    false, "删除帐户", "帐户 " + account.name
				+ " 删除失败：" + rightService.error[state.ecode], $scope)
		    }
		})
	    };
	    
	    diabloUtilsService.request(
		"删除帐户", "确认要删除该帐户吗？", do_delete, undefined, $scope);
	};
	
	// update	
	$scope.update_account = function(account){
	    var editAccount = angular.copy(account);
	    editAccount.desc = $scope.roleDesc[account.type];

	    var promise = rightService.promise;
	    $q.all([
		promise(rightService.list_role)(),
		promise(rightService.list_account_right, account)()
	    ]).then(function(data){
		console.log(data);
		// data[0] are all the roles;
		// data[1] is the current account roles;
		var roles = data[0];
		roles = diablo_order(roles);
		// get the right of the role, now, one user has only one role
		// so, use roles[0]
		var current_role = data[1][0];
		editAccount.role =
		    function(){
			for(var i=0, l=roles.length; i<l; i++){
			    if (roles[i].id === current_role.role_id){
				return roles[i];
			    }
			}
		    }();

		var callback = function(newRole){
		    if (newRole.id === current_role.role_id){
			return;
		    };

		    rightService.update_account_role(account, newRole)
			.$promise.then(function(state){
			    console.log(state);
			    if (state.ecode == 0){
				diabloUtilsService.response_with_callback(
				    true, "帐户权限修改",
				    "帐户 " + account.name + "权限修改成功！！",
				    $scope, function(){location.reload()})
			    } else{
				diabloUtilsService.response(
				    false, "帐户权限修改",
				    "帐户 " + account.name + "权限修改失败："
					+ rightService.error[state.ecode], $scope)
			    }
			});
		};
		
		$modal.open({
		    templateUrl: 'account_user_edit.html',
		    controller: 'accountUserModalCtrl',
		    backdrop: 'static',
		    scope: $scope,
		    resolve:{
			params: function(){
			    return {
				account: editAccount,
				roles:   roles,
				callback: callback
			    }
			}
		    }
		})
	    })
	};
    });


rightUserApp.controller("accountUserModalCtrl", function($scope, $modalInstance, params){
    // console.log($scope);
    console.log(params);
    $scope.account = params.account;
    $scope.roles   = params.roles;

    $scope.cancel = function(){
	$modalInstance.dismiss('cancel');
    };

    $scope.ok = function() {
	$modalInstance.dismiss('ok');
	var callback = params.callback;
	if (angular.isDefined(callback) && typeof(callback) === "function"){
	    callback($scope.account.role);
	}	    
    };
}); 
