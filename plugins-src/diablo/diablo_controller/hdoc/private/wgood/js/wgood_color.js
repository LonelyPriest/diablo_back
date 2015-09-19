wgoodApp.controller("wgoodColorDetailCtrl", function(
    $scope, diabloUtilsService, wgoodService, filterColorType, filterColor){
    // console.log(filterColorType);
    $scope.colorTypes = angular.copy(filterColorType); 
    $scope.colors = angular.copy(filterColor);
    diablo_order($scope.colors);
    
    /*
     * New
     */
    $scope.new_color = function(){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
		console.log(state);

		var append_color = function(newColorId){
		    $scope.colors.push({
			order_id: $scope.colors.length + 1,
			id:      newColorId,
			name:    params.color.name,
			tid:     params.color.type.id,
			type:    params.color.type.name, 
			remark:  params.color.remark ? params.color.remark : "NULL"}), 
		    console.log($scope.colors); 
		};
		
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "新增颜色", "新增颜色成功！！", $scope,
			function(){append_color(state.id)});
		} else{
		    diabloUtilsService.response(
			false, "新增颜色",
			"新增颜色失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	diabloUtilsService.edit_with_modal(
	    'new-color.html', undefined, callback,
	    $scope, {color: {types: $scope.colorTypes}})
    }

    /*
     * Update
     */
    $scope.modify_color = function(color){
	diabloUtilsService.response(false, "修改颜色", "暂不支持此操作！！", $scope);
    };

    /*
     * delete 
     */
    $scope.delete_color = function(color){
	diabloUtilsService.response(false, "删除颜色", "暂不支持此操作！！", $scope);
    };
}
		   );



