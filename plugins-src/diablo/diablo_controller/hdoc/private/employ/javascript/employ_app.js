
var employApp = angular.module(
    "employApp", ['ngRoute', 'ngResource', 'diabloPattern',
		  'diabloAuthenApp', 'diabloUtils', 'ui.bootstrap'])
// .config(diablo_authen);
.config(function($httpProvider, authenProvider){
    // $httpProvider.responseInterceptors.push(authenProvider.interceptor);
    $httpProvider.interceptors.push(authenProvider.interceptor); 
 });

employApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/employ_detail', {
	    templateUrl: '/private/employ/html/employ_detail.html',
            controller: 'employDetailCtrl'
	}).
	when('/employ_new', {
	    templateUrl: '/private/employ/html/employ_new.html',
            controller: 'employNewCtrl'
	}).
	otherwise({
	    templateUrl: '/private/employ/html/employ_detail.html',
            controller: 'employDetailCtrl' 
        })
}]);


employApp.service("employService", function($resource, dateFilter){
    // error information
    this.error = {
	1401: "员工创建失败，已存在同样的员工手机号码"};

    // =========================================================================    
    var employ = $resource("/employ/:operation/:id",
    			 {operation: '@operation', id: '@id'});
    // var members = $resource("/member/:operation/:number");

    this.list = function(){
	return employ.query({operation: "list_employe"})};

    this.query = function(employId){
	return employ.get(
	    {operation: "get_employ", id: employId}
	)};

    this.add = function(one){
	console.log(one);
	return employ.save(
	    {operation: "new_employe"},
	    {name:      one.name,
	     sex:       one.sex.id,
	     mobile:    one.mobile,
	     address:   one.address,
	     entry:     dateFilter(one.entry, "yyyy-MM-dd"),
	    }
	)};

    this.destroy = function(one){
	return employ.delete(
	    {operation: "delete_employe", id: one.id}
	)};

    this.edit = function(one){
	return employ.save(
	    {operation: "update_employe", id: one.id},
	    {
		name:    one.name,
		sex:     angular.isDefined(one.sex) ? one.sex.id : undefined,
		mobile:  one.mobile,
		address: one.address,
	    }
	)};
});


employApp.controller("employDetailCtrl", function(
    $scope, diabloPattern, diabloUtilsService, employService){
    // filters segment
    // $scope.filter = {number: '', name: '', mobile: ''};

    $scope.refresh = function(){
	employService.list().$promise.then(function(employees){
	    angular.forEach(employees, function(e){
		e.sex = diablo_sex2object[e.sex];
	    });
	    
	    $scope.employees = employees;
	    diablo_order($scope.employees);
	}); 
    }

    $scope.goto_page = diablo_goto_page;

    $scope.refresh();

    // edit
    $scope.edit_employ = function(old_employ){
	// console.log(employ);
	var callback = function(params){
	    // console.log(params);
	    console.log(params.employ);

	    var update_employ = {};
	    for (var o in params.employ){
		if (!angular.equals(params.employ[o], old_employ[o])){
		    update_employ[o] = params.employ[o];
		}
	    }
	    
	    update_employ.id = params.employ.id;
	    console.log(update_employ);
	    
	    employService.edit(update_employ).$promise.then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "员工编辑",
			"恭喜你，员工 [" + old_employ.name + "] 信息修改成功！！",
			$scope, function(){$scope.refresh()});
    		} else{
		    diabloUtilsService.response(
			false, "员工编辑",
			"员工编辑失败：" + employService.error[state.ecode]);
    		}
    	    })
	};

	var check_same = function(new_employ){
	    return angular.equals(new_employ, old_employ); 
	};

	var check_exist = function(new_employ){
	    for(var i=0, l=$scope.employees.length; i<l; i++){
		if(new_employ.name === $scope.employees[i].name
		   && new_employ.name !== old_employ.name){
		    return true;
		}
	    }

	    return false;
	}
	
	diabloUtilsService.edit_with_modal(
	    "edit-employ.html", "sm", callback, $scope,
	    {employ:      old_employ,
	     pattern:     {name:    diabloPattern.chinese_name,
			   mobile:  diabloPattern.mobile,
			   address: diabloPattern.ch_name_address},
	     sexes:       diablo_sex2object,
	     check_same:  check_same,
	     check_exist: check_exist});
    };

    // delete
    $scope.delete_employ = function(employ){
	var callback = function(){
	    employService.destroy(employ).$promise.then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "删除员工",
			"恭喜你，员工 [" + employ.name + "] 删除成功！！", $scope,
			function(){$scope.refresh()});
    		} else{
		    diabloUtilsService.response(
			false, "删除员工",
			"删除员工失败：" + employService.error[state.ecode]);
    		}
    	    })
	};
	
	diabloUtilsService.request(
	    "删除员工", "确定要删除该员工吗？", callback, undefined, $scope);
    };
    
    $scope.employ_delete_submit = function(){
	// console.log($scope.selectedDeleteEmploy);
	employService.destroy($scope.selectedDeleteEmploy).$promise
	    .then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
    		    $scope.delete_response = function(){
    			$scope.response_success_delete_info = "恭喜你，员工 "
			    + $scope.selectedDeleteEmploy.name + " 删除成功";
    			return true;
    		    };
		    $scope.after_delete_response = function(){
    			location.reload();
    		    };
    		} else{
    		    $scope.delete_response = function(){
    			$scope.response_error_delete_info = employService.error[state.ecode];
    			return false;
    		    }
    		}
    	    })
    };	
});

employApp.controller("employNewCtrl", function(
    $scope, $location, diabloPattern, diabloUtilsService, employService){

    $scope.name_pattern = diabloPattern.chinese_name;
    $scope.mobile_pattern = diabloPattern.mobile;
    $scope.address_pattern = diabloPattern.ch_name_address;
    
    // canlendar
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true; 
    }

    $scope.sexes = diablo_sex2object;
    
    // new merchant
    var dialog = diabloUtilsService;
    $scope.new_employ = function(){
	employService.add($scope.employ).$promise.then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增员工", "恭喜你，员工 " + $scope.employ.name + " 成功创建！！",
		    $scope, function(){diablo_goto_page("#/employ_detail")});
	    } else{
		dialog.response(
		    false, "新增员工", "员工 [" + $scope.employ.name + "] 创建失败："
			+ employService.error[state.ecode]); 
	    }
	})};
    
    $scope.cancel = function(){
	$location.path("/employ_detail");
    };
    
});

employApp.controller("employCtrl", function($scope){});

employApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});






