wgoodApp.controller("wgoodSizeDetailCtrl", function(
    $scope, diabloPattern, diabloUtilsService, diabloFilter,
    wgoodService, filterSizeGroup){
    $scope.size_group = angular.copy(filterSizeGroup); 
    // console.log($scope.size_group);
    diablo_order($scope.size_group);

    $scope.pattern = {size: diabloPattern.size};
    
    
    $scope.refresh = function(){
	diabloFilter.get_size_group().then(function(groups){
	    $scope.size_group = angular.copy(groups);
	    diablo_order($scope.size_group);
	    // console.log($scope.size_group);
	})
    }
    
    /*
     * add
     */
    var valid_group = function(size){
	var all_size = [];
	for (var s in size){
	    if (s === 'name') continue;

	    if (angular.isDefined(size[s]) && size[s]){
		// same size in group
		if (in_array(all_size, size[s])){
		    return false;
		} else{
		    all_size.push(size[s]);
		}
	    }
	}

	// at lest one size was input 
	return all_size.length === 0 ? false : true;
    };

    var check_same = function(size, key, value){
	// console.log(size, key, value);
	for (var s in size){
	    if (s === 'name' || s === key) continue;

	    if (angular.isDefined(size[s])
		&& size[s] && size[s] === value){
		return false;
	    }
	}

	return true;
    };
    
    $scope.new_size = function(){

	var callback = function(params){
	    console.log(params);
	    var size = {};
	    for (var k in params.size){
		if (angular.isDefined(params.size[k]) && params.size[k]){
		    size[k] = params.size[k]
		}
	    }

	    console.log(size);

	    wgoodService.add_purchaser_size(size).then(function(state){
	        console.log(state);
	        if (state.ecode == 0){
		    var append_size_group = function(gid){
			$scope.size_group.push(
			    angular.extend({
				id:gid, order_id:$scope.size_group.length + 1}, size));
		    };
		    
		    diabloUtilsService.response_with_callback(
			true, "新增尺码组", "新增尺码组成功！！", $scope,
			function(){append_size_group(state.id)}); 
	        } else{
	    	diabloUtilsService.response(
	    	    false, "尺码组", "新增尺码组失败，原因："
	    		+ wgoodService.error[state.ecode]);
	        };
	    });
	}
	
	diabloUtilsService.edit_with_modal(
	    'new-size.html', undefined, callback, $scope,
	    {size: {}, valid_group: valid_group, check_same: check_same})
	
	// // delete empty size
	// for(var k in group){
	//     if(!group[k]){
	// 	delete group[k];
	//     }
	// };
	// console.log(group);
	// // add
	// wgoodService.add_purchaser_size(group).then(function(state){
	//     console.log(state);
	//     if (state.ecode == 0){
    	// 	// location.reload();
	// 	$scope.refresh();
	// 	$scope.group_new = {$new:true, $editable:false};
	//     } else{
	// 	diabloUtilsService.response(
	// 	    false, "尺码组", "新增尺码组失败，原因："
	// 		+ wgoodService.error[state.ecode]);
	//     };
	// });
    };


    /*
     * modify
     */
    $scope.do_modify = function(group){
	// group.$editable=true;
	diabloUtilsService.response(false, "修改尺码组", "暂不支持此操作！！", $scope);
    };

    /*
     * delete
     */

    $scope.do_update = function(group){
	diabloUtilsService.response(false, "删除尺码组", "暂不支持此操作！！", $scope);
    }
    
});
