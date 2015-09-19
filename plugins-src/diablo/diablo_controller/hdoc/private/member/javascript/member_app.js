var memberApp = angular.module(
    "memberApp",
    ['ngRoute', 'ngResource', 'ngTable',
     'subbmitNotify', 'ngTableUtils', 'ui.bootstrap',
     'userApp']);

memberApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
        when('/member/list_member', {
            templateUrl: '/private/member/html/member_detail.html',
            controller: 'memberListCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
        }).
	when('/member/new_member', {
	    templateUrl: '/private/member/html/member_add.html',
            controller: 'memberAddCtrl'
	}).
	when('/member/acc_score', {
	    templateUrl: '/private/member/html/member_accumulate_score.html',
            controller: 'memberScoreAccumuateCtrl'
	}).
	when('/member/consumed_score', {
	    templateUrl: '/private/member/html/member_consumed_score.html',
            controller: 'memberScoreConsumedCtrl'
	}).
	when('/member/consumed_score/:number', {
	    templateUrl: '/private/member/html/member_consumed_score.html',
            controller: 'memberScoreConsumedCtrl'
	}).
	when('/score/acc_score_detail', {
	    templateUrl: '/private/member/html/member_accscore_detail.html',
            controller: 'memberAccScoreCtrl'
	}).
	when('/score/ex_score_detail', {
	    templateUrl: '/private/member/html/member_exscore_detail.html',
            controller: 'memberExScoreCtrl'
	}).
	when('/strategy/score_strategy', {
	    templateUrl: '/private/member/html/member_score_strategy.html',
            controller: 'memberScoreStrategyCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	otherwise({
	    templateUrl: '/private/member/html/member_detail.html',
            controller: 'memberListCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
            // templateUrl: '/private/member/html/member_index.html',
            // controller: 'memberCtrl'
        })	    
}]);


// VMApp.directive("vmAddButton", ['vmService', function(vmService){
//     return {
// 	restrict: 'AE',
// 	link: function(scope, element, attrs){
// 	    element.bind("click", function(){
// 		window.location = '#/add';
// 	    })
// 	}
//     }
// }]);

// VMApp.directive("ngEnter", function(){
//     return {
// 	restrict: 'AE',
// 	link: function(scope, element, attrs){
// 	    element.bind("keydown keypress", function(event){
// 		if (event.which == 13){
// 		    scope.$apply(function(){
// 			console.log("key down");
// 			scope.$eval(attrs.ngEnter);
// 		    });
// 		    event.preventDefault();
// 		}
// 	    })
// 	}
//     }
// });


memberApp.service("memberService", function($resource, dateFilter){
    var _number       = '';
    var _name         = '';
    var _sex          = '';
    var _birthdy      = '';
    var _mobile       = '';
    var _sla          = '';
    var _balance      = '';

    this.setNumber = function(number){
	_number = number;
    }


    // =========================================================================

    this.getSex = function(){
	_sex = new Array("女", "男");
	return _sex;
    }

    this.getSLA = function(){
	_memory = new Array("普通", "黄金", "钻石");
	return _memory;
    }

    this._sex2number = function(sex){
	if (sex == "女"){
	    return 0;
	} else{
	    return 1;
	}
    };

    this._sla2number = function(sla){
	if (sla == "普通"){
	    return 0;
	} else if(sla == "黄金"){
	    return 1;
	} else {
	    return 2;
	}
    };

    this.error = {
	1001: "会员创建失败，已存在同样的会员号",
	1002: "会员创建失败，已存在同样的手机号码"}

    var members = $resource("/member/:operation/:number",
    			    {operation: '@operation', number: '@number'});

    // var members = $resource("/member/:operation/:number");

    this.list = function(){
	return members.query({operation: "list_member"})};

    this.get_member = function(number){
	return members.get(
	    {operation: "get_member_by_number", number: number}
	)};

    this.add = function(member){
	return members.save(
	    {operation: "new_member", number: member.number},
	    {name:      member.name,
	     sex:       this._sex2number(member.selectedSex),
	     birthday:  dateFilter(member.birthday, "yyyy-MM-dd"),
	     mobile:    member.mobile,
	     sla:       this._sla2number(member.selectedSLA),
	     balance:   member.balance
	    }
	)};

    this.destroy = function(member){
	return members.delete(
	    {operation: "delete_member", number: member.number}
	)} ;

    this.edit = function(member){
	return members.save(
	    {operation: "update_member", number: member.number},
	    {mobile:    member.mobile}
	)};
    
    this.consumed_score = function(member, score, gift){
	return members.save(
	    {operation: "exchange_score", number: member.number},
	    {consumed_score: score, gift: gift}
	)};

    this.acc_score_detail = function(){
	return members.query(
	    {operation: "acc_score_detail"}
	)};

    this.ex_score_detail = function(){
	return members.query(
	    {operation: "exchange_score_detail"}
	)};

    this.score_strategy = function(){
	return members.query(
	    {operation: "query_score_strategy"}
	)};
});

memberApp.controller(
    "memberListCtrl",
    function($scope, $routeParams, ngTableUtils, memberService, user){
	// filters segment
	$scope.filters = {name: '', mobile: '', number: ''};

	// list
	memberService.list().$promise.then(function(members){
           $scope.memberTable =
		ngTableUtils.tbl_of_filter_and_sort(members, $scope.filters, {id: 'desc'});
	});
		
	    
	$scope.goto_page = function(path){
	    window.location = path;
	};

	// console.log(user.right);
	$scope.can_modify_member = function(){
	   return rightAction.can_operator_member(user.right, "update_member");
	};

	$scope.can_new_member = function(){
	   return rightAction.can_operator_member(user.right, "new_member");
	};

	$scope.can_delete_member = function(){
	    return rightAction.can_operator_member(user.right, "del_member");
	};

	// edit
	$scope.edit_member = function(member){
	    // console.log(member);
	    // deep copy
	    // $scope.selectedEditMember = JSON.parse(JSON.stringify(member));
	    $scope.selectedEditMember = angular.copy(member);
	    // console.log($scope.selectedEditMember);
	};

	$scope.edit_member_request = function(member){
    	    // console.log(member);
    	    memberService.edit(member).$promise.then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
    		    $scope.editMemberResponse = function(){
    			$scope.response_success_info = "恭喜你，会员 " + member.name + " 修改成功";
    			return true
    		    };
		    $scope.afterResponse = function(){
    			location.reload();
    		    };
    		    // window.location = '#/vmOpList';
    		} else{
    		    $scope.editMemberResponse = function(){
    			$scope.response_error_info = memberService.error[state.ecode];
    			return false
    		    }
    		}
    	    })};

	// delete member
	$scope.set_delete_member = function(member){
	    $scope.selectedDeleteMember = member;
	};
	$scope.member_delete_submit = function(){
	    memberService.destroy($scope.selectedDeleteMember).$promise
		.then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
    			$scope.delete_response = function(){
    			    $scope.response_success_delete_info = "恭喜你，会员 "
				+ $scope.selectedDeleteMember.name + " 删除成功";
    			    return true;
    			};
			$scope.after_delete_response = function(){
    			    location.reload();
    			};
    		    } else{
    			$scope.delete_response = function(){
    			    $scope.response_error_delete_info = memberService.error[state.ecode];
    			    return false;
    			}
    		    }
    		})
	}
	
    });



memberApp.controller(
    "memberAddCtrl",
    function($scope, memberService){
	// canlendar
	$scope.open_calendar = function(event){
	    event.preventDefault();
	    event.stopPropagation();
	    $scope.isOpened = true; 
	}
	
	// member object
	$scope.member = {};
	
	// sex, use first to as the default selection
	$scope.sex = memberService.getSex();
	$scope.member.selectedSex = $scope.sex[0];

	// SAL, use first to as the default selection
	$scope.sla = memberService.getSLA();
	$scope.member.selectedSLA = $scope.sla[0];


	// =====================================================================
	// Actions
	// =====================================================================	
	// new vm request
	$scope.new_member = function(){
	    // console.log($scope.memberAddForm.$invalid);
	    memberService.add($scope.member).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    $scope.newMemberResponse = function(){
			$scope.response_success_info =
			    "恭喜你，会员 " + $scope.member.name + " 成功创建";
			return true
		    };
		    
		    $scope.afterResponse = function(){
    			location.href = "#/member/list_member";
    		    };
		    
		} else{
		    $scope.newMemberResponse = function(){
			$scope.response_error_info = memberService.error[state.ecode];
			return false
		    };
		}
	    })};
	
	$scope.cancel_new_member = function(){
	    window.location = "#/member/list_member";
	};
    });


memberApp.controller(
    "memberScoreConsumedCtrl",
    function($scope, $routeParams, memberService){
	//console.log($routeParams);
	var _set_member = function(member){
	    $scope.member = member;
	    $scope.leftScore = member.total_score - member.exchange_score ;
	    // make sex and sla to readable
	    $scope.member.sex  = memberService.getSex()[$scope.member.sex];
	    $scope.member.sla  = memberService.getSLA()[$scope.member.sla];
	};
	
	if ($routeParams.hasOwnProperty("number")){
	    memberService.get_member($routeParams.number).$promise.then(function(member){		
		$scope.isSelect = false;
		_set_member(member);
	    });
	} else{
	    memberService.list().$promise.then(function(members){
		$scope.members = members;
		$scope.isSelect = true;
	    })
	};

	$scope.on_selected = function(item, model, label){
	    // console.log(model);
	    _set_member(model);
	};

	$scope.validConsumedScore = true;
	$scope.consumed_score = function(member, score, gift){
	    if (score > $scope.leftScore){
		$scope.memberScoreConsumedForm.consumedScore.$invalid = true;
		$scope.validConsumedScore = false;
	    }
	    else{
		memberService.consumed_score(member, score, gift)
		    .$promise.then(function(state){
    			console.log(state);
    			if (state.ecode == 0){
    			    $scope.member_consumed_response = function(){
    				$scope.response_success_info =
				    "恭喜你，会员 " + member.name + " 兑换积分成功";
    				return true
    			    };
			    $scope.after_response = function(){
				//console.log("aftre_response");
    				//location.reload();
				window.location = '#/member/list_member';

    			    };
    			} else{
			    $scope.member_consumed_response = function(){
    				$scope.response_error_info = memberService.error[state.ecode];
    				return false
    			    };
    			}
    		    });
	    }
	}

	$scope.cancel_score_consumed = function(){
	    window.location = '#/member/list_member';
	}

    });


memberApp.controller(
    "memberAccScoreCtrl",
    function($scope, $routeParams, ngTableUtils, memberService){
	$scope.filter = {name: '', mobile: ''};
	memberService.acc_score_detail().$promise.then(function(members){
            $scope.accScoredetailTable =
		ngTableUtils.tbl_of_filter_and_sort(members, $scope.filter, {id: 'asc'});
	});

	$scope.reload = function(){
	  console.log("reload");  
	}

    });

memberApp.controller(
    "memberExScoreCtrl",
    function($scope, dateFilter, ngTableUtils, memberService){
	$scope.filter = {name: '', mobile: ''};
	memberService.ex_score_detail().$promise.then(function(members){
            $scope.accScoredetailTable =
		ngTableUtils.tbl_of_filter_and_sort(members, $scope.filter, {id: 'asc'});
	});

	$scope.reload = function(){
	    
	}

    });

memberApp.controller(
    "memberScoreStrategyCtrl",
    function($scope, $routeParams, ngTableUtils, memberService, user){
	memberService.score_strategy().$promise.then(function(rules){
            $scope.ruleMoneyToScoreTable =
		ngTableUtils.tbl_of_sort(rules, {id: 'asc'});
	});

	$scope.can_modify = function(){
	    return rightAction.can_operator_member(
		user.right, "update_score_stratege");
	};

	$scope.reload = function(){
	    
	}

    });

var memberCtrl = function ($scope, $routeParams, $location){
    // console.log($location);
};











