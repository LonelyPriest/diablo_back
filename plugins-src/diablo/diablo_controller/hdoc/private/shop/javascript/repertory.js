shopApp.controller("repoNewCtrl", function(
    $scope, shopService, diabloPattern, diabloUtilsService){
    $scope.pattern = {repo_name: diabloPattern.ch_name_address,
		      repo_addr: diabloPattern.ch_name_address};

    var dialog = diabloUtilsService;
    
    $scope.new_repo = function(){
	console.log($scope.repo); 
	shopService.new_repo($scope.repo).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增仓库", "恭喜你，仓库 " + $scope.repo.name + " 成功创建！！",
		    $scope, function(){diablo_goto_page("#/repo/repo_detail")});
	    } else{
		dialog.response(
		    false, "新增仓库", shopService.error[state.ecode]); 
	    }
	})
    };
    
    $scope.cancel = function(){
	diablo_goto_page("#/repo/repo_detail");
    };	
});

shopApp.controller("repoDetailCtrl", function(
    $scope, shopService, diabloPattern, diabloUtilsService){
    $scope.goto_page = diablo_goto_page;
    var dialog = diabloUtilsService;

    shopService.list_repo().then(function(result){
	console.log(result);
	$scope.repertories = result;
	diablo_order($scope.repertories);
    });

    // $scope.bind_print = function(r){
	
    // }
});



shopApp.controller("badRepoNewCtrl", function(
    $scope, shopService, diabloPattern, diabloUtilsService, user){
    $scope.pattern = {repo_name: diabloPattern.ch_name_address,
		      repo_addr: diabloPattern.ch_name_address};

    $scope.repertories = user.sortAvailabeShops;
    
    var dialog = diabloUtilsService;

    $scope.repo = {repo: $scope.repertories[0]};
    
    $scope.new_badrepo = function(){
	console.log($scope.repo); 
	shopService.new_badrepo($scope.repo).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增次品仓", "恭喜你，次品仓 " + $scope.repo.name + " 成功创建！！",
		    $scope, function(){diablo_goto_page("#/repo/badrepo_detail")});
	    } else{
		dialog.response(
		    false, "新增次品仓", shopService.error[state.ecode]); 
	    }
	})
    };
    
    $scope.cancel = function(){
	diablo_goto_page("#/repo/badrepo_detail");
    };	
});

shopApp.controller("badRepoDetailCtrl", function(
    $scope, shopService, diabloPattern, diabloUtilsService, user){
    $scope.goto_page = diablo_goto_page;
    var dialog = diabloUtilsService;
    
    $scope.shops = user.sortAvailabeShops;
    
    shopService.list_badrepo().then(function(result){
	console.log(result);
	$scope.repertories = angular.copy(result);
	angular.forEach($scope.repertories, function(r){
	    r.repo = diablo_get_object(r.repo_id, $scope.shops);
	})

	console.log($scope.repertories);
	diablo_order($scope.repertories);
    });

    // $scope.bind_print = function(r){
    
    // }
});
