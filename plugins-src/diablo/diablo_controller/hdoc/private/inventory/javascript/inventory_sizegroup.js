inventoryApp.controller(
    "inventorySizeGroupCtrl",
    function($scope, inventoryService, diabloUtilsService){

	$scope.refresh = function(){
	    inventoryService.list_size_group().$promise.then(function(groups){
		$scope.size_group = groups;
		var order_id = 1;
		angular.forEach($scope.size_group, function(g){
		    g.$editable = false;
		    g.order_id = order_id;
		    order_id++;
		});

		console.log($scope.size_group);
	    });
	};

	// load all size group when start
	$scope.refresh();
	
	
	// size group to add
	$scope.form = {};
	$scope.group_new = {$new:true, $editable:false};
	
	// check size input valid	
	var check_size = function(size){
	    // console.log(size);
	    var renumber = /^[2-4][0-9]$/;

	    if (renumber.test(size)){
		return true;
	    }
	    
	    if (size.indexOf("/") == -1){
		return false;
	    };

	    
	    var part = size.split("/");

	    // console.log(re.test(part[0]));
	    // console.log(renumber.test(part[1]));
	    var re = /^(s|S|m|M|l|L)$|^(x|X)+(l|L)$|^[1-9][0-9]?(x|X)(l|L)$/;
	    if (re.test(part[0]) && renumber.test(part[1])){
		return true;
	    };

	    return false
	    
	};
	
	var size_name = ["si", "sii", "siii", "siv", "sv", "svi"];
	var check_group = function(group){	    
	    for (var i = 0, l = size_name.length; i < l; i++){
		var name = size_name[i];
		// console.log(name);
		// console.log(check_size(group[name].toString()));
		if (!check_size(group[name].toString())){
		    console.log($scope.form[name].name);
		    $scope.form[name].name.$invalid=true;
		    $scope.form[name].name.$valid=false;
		    return false;
		} else {
		    $scope.form[name].name.$invalid=false;
		}
	    };
	    
	    return true;
	};

	/*
	 * add
	 */
	$scope.add_group = function(group){
	    // check
	    if (!check_group(group)){
		return;
	    };

	    console.log(group);
	    // add
	    inventoryService.add_size_group(group).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
    		    // location.reload();
		    $scope.group_new = {$new:true, $editable:false};
		    $scope.refresh();
		} else{
		    diabloUtilsService.response(
			false, "尺码组", "新增尺码组失败，原因："
			    + inventoryService.error[state.ecode]);
		};
	    });
	};

	/*
	 * modify
	 */
	$scope.pre_modify = function(group){
	    $scope.modify_group = angular.copy(group);
	    angular.forEach($scope.size_group, function(g){
		if (g.id !== group.id ){
		    g.$editable = false;
		}
	    });
	};
	
	$scope.do_modify = function(group){
	    console.log(group);
	    console.log($scope.modify_group)
	    if (!check_group($scope.modify_group)){
		return;
	    };

	    // get changed
	    var changed = {};
	    for (var i = 0, l = size_name.length; i < l; i++){
		var name = size_name[i];
		if ($scope.modify_group[name] !== group[name]){
		    changed[name] = $scope.modify_group[name];
		}
	    };

	    // nothing can be modified
	    if (diablo_is_empty(changed)){
		diabloUtilsService.response(
		    false, "新增尺码组", "新增失败，原因：" + inventoryService.error[6001]);
		return;
	    };

	    changed.id = $scope.modify_group.id;
	    console.log(changed);

	    inventoryService.modify_size_group(changed).$promise.then(function(state){
		if (state.ecode == 0){
		    $scope.refresh();
		} else{
		    diabloUtilsService.response(
			false, "尺码组", "修入尺码组失败，原因："
			    + inventoryService.error[state.ecode]);
		}
	    })
	    
	};

	/*
	 * delete 
	 */
	$scope.del_group = function(group){
	    var callback = function(gid){
		inventoryService.delete_size_group(gid).$promise.then(function(state){
		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "尺码组", "删除尺码组成功！！", $scope, $scope.refresh)
		    } else{
			diabloUtilsService.response(
			    false, "尺码组", "删除尺码组失败！！，原因："
				+ inventoryService.error[state.ecode]);
		    }
		})
	    };
	    
	    diabloUtilsService.request(
		"删除尺码组", "确认要删除该尺码吗？", callback, group.id, $scope);
	}
	
    });
