wprintApp.controller("serverNewCtrl", function(
    $scope, diabloPattern, wprintService, diabloUtilsService){
    
    var url_pattern = diabloPattern.url; 

    var re=new RegExp(url_pattern);

    $scope.valid_url = function(){
	return re.test($scope.print_server.url);
    };
    
    // new server
    $scope.new_server = function(){
	wprintService.new_wprint_server($scope.print_server).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "新增服务器",
		    "恭喜你，服务器 " + $scope.print_server.name + " 成功创建！！",
	    	    $scope,
		    function(){diablo_goto_page("#/server/detail");});
	    } else{
		diabloUtilsService.response(
	    	    false, "新增服务器",
	    	    "新增服务器失败：" + wprintService.error[state.ecode]);
	    };
	})
    };
    
    $scope.cancel = function(){
	diablo_goto_page("#/server/detail");
    };
});


wprintApp.controller("serverDetailCtrl", function(
    $scope, $location, wprintService, diabloUtilsService){

    $scope.goto_page = diablo_goto_page;

    $scope.refresh = function(){
	wprintService.list_wprint_server().then(function(data){
	    console.log(data);
	    $scope.servers = data;
	});	
    };

    $scope.refresh();
    
    $scope.update_server = function(){
	diabloUtilsService.response(false, "修改服务器", "暂不支持此操作！！", $scope);
    };

    $scope.delete_server = function(){
	diabloUtilsService.response(false, "删除服务器", "暂不支持此操作！！", $scope);
    }
});
