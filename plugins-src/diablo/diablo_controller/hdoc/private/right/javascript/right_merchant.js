// -----------------------------------------------------------------------------
// Merchant role
// -----------------------------------------------------------------------------
rightMerchantApp.controller(
    "roleMerchantNewCtrl",
    function($scope, $q, $location, diabloUtilsService, rightService){
	// get all right catlogs
	var right_catlogs = function(){
	    var deferred = $q.defer();
	    rightService.list_right_catlog().$promise.then(function(catlogs){
		console.log(catlogs);
		deferred.resolve(catlogs);
	    });
	    return deferred.promise;
	}
	$scope.catlogs = $q.all([right_catlogs()]);

	// callback of select a right catlog
	// $scope.selectedNodes = [];
	$scope.onSelect = function(select, node){
	    // console.log($scope.empty_role_right);
	    // console.log($scope.roleAddForm);
	    $scope.selectedNodes = node.tree.getSelectedNodes(true);
	    $scope.$apply(function(){
		$scope.empty_role_right = false;
	    });
	};

	var roleDetailPath = "#/role_merchant/role_detail"
	// add role
	$scope.new_role = function(){
	    console.log($scope.selectedNodes);
	    console.log($scope.roleAddForm);
	    var keyIds = [];
	    angular.forEach($scope.selectedNodes, function(node){
		keyIds.push(node.data.key)
	    });

	    // empty role, should select a right first
	    console.log(keyIds.length);
	    if (keyIds.length < 1){
		$scope.empty_role_right = true;
		return;
	    };

	    rightService.add_role(
		$scope.role, rightService.roleType.merchant, {fun_id:keyIds})
		.$promise.then(function (state){
		    console.log(state);
		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "新增角色", "角色 [" + $scope.role.name + "] 创建成功",
			    $scope, function(){diablo_goto_page(roleDetailPath)}); 
		    } else{
			diabloUtilsService.response(
			    false, "新增角色", "新增角色失败："
				+  rightService.error[state.ecode]); 
		    }
		})
	};

	$scope.cancel_new_role = function(){
	    location.href = roleDetailPath;
	}

    });


rightMerchantApp.controller(
    "roleMerchantDetailCtrl",
    function($scope, $q, $modal, rightService, diabloUtilsService){
	// console.log($scope);
	$scope.roleTypeDesc = rightService.roleTypeDesc;
	$scope.filter = {name:'', created_by:''};
	$scope.right_tree = null;
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
	    console.log(role);
	    rightService.get_right_by_role_id(role.id).$promise.then(function(data){
		console.log(data);
		var callback = function(rightTree){
		    rightTree.reload();
		    tree_utils.build_unselect_tree(rightTree, data);
		};

		rightService.tree_modal(
		    'role-merchant-detail.html', $scope, callback, undefined); 
	    })
	};

	/*
	 * update
	 */
	var all_right = function(){
	    var deferred = $q.defer();
	    rightService.list_right_catlog().$promise.then(function(rights){
		deferred.resolve(rights);
	    });

	    return deferred.promise;
	};

	var current_merchant_right = function(role){
	    var deferred = $q.defer();
	    rightService.get_right_by_role_id(role.id).$promise.then(function(rights){
		deferred.resolve(rights);
	    });
	    return deferred.promise;
	};
	
	$scope.pre_update = function(role){
	    $scope.modify_role = role;
	    // build  role tree
	    $q.all([all_right(), current_merchant_right(role)]).then(function(data){
	    	console.log(data);

		// data[0] is the all right
	    	// data[1] is the current role's right
		var tree_callback = function(rightTree){
		    rightTree.reload();
	    	    $scope.all_right = data[0];
	    	    $scope.current_right = data[1];
	    	    tree_utils.build_edit_tree(rightTree, $scope.current_right);
	    	    tree_utils.add_nodes(rightTree, $scope.all_right);

		    // only fire the select, can be any node but not only data[1][0] 
		    var fireNode = rightTree.getNodeByKey(data[1][0].id.toString());
		    $scope.onSelect.call(rightTree, true, fireNode);
		} 

		rightService.tree_modal(
		    'role-merchant-edit.html', $scope, tree_callback, $scope.do_update); 
	    	
	    }) 
	};

	var delete_node = function(nodes, item){
	    for(var i=0, l=nodes.length; i<l; i++){
		if(nodes[i] === parseInt(item)){
		    nodes.splice(i, 1)
		}
	    }
	};

	var get_parent = function(right_nodes, item){
	    for(var i=0, l=right_nodes.length; i<l; i++){
		if(right_nodes[i].id === parseInt(item)){
		    return right_nodes[i].parent
		}
	    }
	};

	var get_children = function(right_nodes, item){
	    var children = [];
	    for(var i=0, l=right_nodes.length; i<l; i++){
		if(right_nodes[i].parent === parseInt(item)){
		    children.push(right_nodes[i].id);
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

	// callback of select or unselect a node from right tee
	$scope.onSelect = function(select, node){
	    $scope.current_selected = node.tree.getSelectedNodes(true);
	    // console.log($scope.current_selected);
	};

	$scope.do_update = function(){
	    console.log("do_update");

	    // sort
	    var rootRight = [];
	    angular.forEach($scope.all_right, function(r){
		if (r.parent === 0){
		    rootRight.push(r.id);
		}
	    });

	    var newSelected = [];
	    angular.forEach($scope.current_selected, function(r){
		newSelected.push(parseInt(r.data.key));
	    });
	    
	    angular.forEach(rootRight, function(n){
		var children = get_children($scope.all_right, n);
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
		var children = get_children($scope.all_right, n);
		if ( children.length > 0 ) {
		    if(has_sub_array(oldSelected, children)){
			angular.forEach(children, function(child){
			    delete_node(oldSelected, child)
			})
		    };

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
	    
	    if (added_nodes.length === 0 && deleted_nodes.length === 0){
		diabloUtilsService.response(
		    false, "权限编辑", "权限编辑失败：" + rightService.error[6001], $scope);
		return;
	    };

	    rightService.update_role(
		$scope.modify_role, added_nodes, deleted_nodes)
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

	$scope.do_delete = function(role){
	    diabloUtilsService.response(
		false, "权限编辑", "权限编辑失败：" + rightService.error[7001], $scope);
	    return;
	}
	
    });



// =============================================================================
// merchant account
// =============================================================================
rightMerchantApp.controller(
    "accountMerchantNewCtrl",
    function($scope, diabloUtilsService, rightService, merchantService){

	$scope.merchants = [];
	merchantService.list().$promise.then(function(merchants){
	    angular.forEach(merchants, function(m){
		$scope.merchants.push({
		    id:     m.id,
		    name:   m.owner,
		    py:     diablo_pinyin(m.owner),
		    mobile: m.mobile 
		})
	    })
	    
	    console.log($scope.merchants);
	});

	$scope.roles = [];
	rightService.list_role().$promise.then(function(roles){
	    // $scope.roles = roles;
	    angular.forEach(roles, function(r){
		$scope.roles.push({
		    id:r.id, name:r.name, py:diablo_pinyin(r.name)})
	    })
	    console.log($scope.roles);
	});

	$scope.show_role_tree=false;
	$scope.on_role_select = function(item, model, label){
	    //console.log(item);
	    //console.log(model);
	    $scope.roleTree.reload();
	    rightService.get_right_by_role_id(model.id).$promise.then(function(catlogs){
		console.log(catlogs);
		tree_utils.build_unselect_tree($scope.roleTree, catlogs);
		$scope.show_role_tree=true;
	    })
	}

	$scope.account = {type:rightService.roleType.merchant};

	// new merchant
	$scope.new_account = function(){
	    rightService.add_account($scope.account).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "新增帐户", "帐户 [" + $scope.account.name + "] 创建成功",
			$scope, function(){
			    diablo_goto_page("#/account_merchant/account_detail")}); 
		} else{
		    diabloUtilsService.response(
			false, "新增帐户", "帐户创建失败："
			    +  rightService.error[state.ecode]); 
		}
	    })};

	$scope.cancel = function(){
	    diablo_goto_page( "#/account_merchant/account_merchant_detail");
	};

    });


rightMerchantApp.controller(
    "accountMerchantDetailCtrl",
    function($scope, $routeParams, $q, $modal, rightService, diabloUtilsService){
	$scope.roleDesc = rightService.roleTypeDesc;
	$scope.accountDesc = rightService.accountDesc;

	// filters segment
	$scope.filter = {name: ''};
	$scope.refresh = function(){
	    // list
	    rightService.list_account().$promise.then(function(accounts){
		console.log(accounts);
		diablo_order(accounts)
		$scope.accounts = accounts;
	    });
	};

	$scope.refresh();
	
	$scope.goto_page = function(path){
	    window.location = path;
	};
	
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

		    var callback = function(tree){
			console.log(tree);
			tree.reload(); 
			tree_utils.build_unselect_tree(tree, data[0]);
			
			angular.forEach(data[1], function(shop){
		    	    tree_utils.add_child(
		    		tree, {name: shop.name, id: shop.shop_id}, shop.func_id)
			});
			
			$scope.init_right = true;
		    };

		    rightService.tree_modal('account_merchant_detail.html', $scope, callback); 
		    
		}) 
	    })
	}

	// delete
	$scope.pre_delete = function(account){
	    var do_delete = function(){
		console.log(account);
		rightService.delete_account(account).$promise.then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "删除帐户", "帐户 " + account.name + " 删除成功",
			    $scope, function(){$scope.refresh()})
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
	var get_roles = function(){
	    var deferred = $q.defer();
	    rightService.list_role().$promise.then(function(roles){
		deferred.resolve(roles);
	    });
	    return deferred.promise;
	};

	var get_account_role = function(account){
	    var deferred = $q.defer();
	    rightService.list_account_right(account).$promise.then(function(roles){
		// get the right of the role, now, one user has only one role
		// so, use roles[0]
		deferred.resolve(roles[0]);
	    });
	    return deferred.promise;
	};
	
	$scope.update_account = function(account){
	    var editAccount = angular.copy(account);
	    editAccount.desc = $scope.roleDesc[account.type];
	    
	    $q.all([get_roles(), get_account_role(account)]).then(function(data){
		console.log(data);
		// data[0] are all the roles;
		// data[1] is the current account roles;
		var roles = data[0];
		var current_role = data[1];
		editAccount.role =
		    function(){
			for(var i=0, l=roles.length; i<l; i++){
			    if (roles[i].id === current_role.role_id){
				return roles[i];
			    }
			}
		    }();

		var callback = function(params){
		    console.log(params);
		    var newRole = params.account.role;
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

		diabloUtilsService.edit_with_modal(
		    'account_merchant_edit.html', undefined, callback, $scope,
		    {account: editAccount, roles: roles}); 
	    })
	};
    });

