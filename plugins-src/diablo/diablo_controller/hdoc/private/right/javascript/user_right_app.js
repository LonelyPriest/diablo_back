var userApp = angular.module("userApp", ['ngResource']); 


userApp.factory("userService", function($resource, $q){
    var _user = $resource("/right/:operation", {operation: '@operation'});

    var _shops     = [];
    var _rights    = [];
    var _loginType = undefined;

    // var promise = function(callback, params){
    // 	return function(){
    // 	    var deferred = $q.defer();
    // 	    callback(params).$promise.then(function(data){
    // 		// console.log(data);
    // 		deferred.resolve(data);
    // 	    });
    // 	    return deferred.promise;
    // 	}
    // };

    // var get_right = function(){
    // 	return user.query({operation: "list_login_user_right"}); 
    // };

    // var get_shop = function(){
    // 	return user.query({operation: "list_login_user_shop"});
    // };

    // var get_type = function(){
    // 	return user.query({op})
    // };

    // var setting = $resource("/wbase/:operation", {operation: '@operation'}); 
    
    // var get_base_setting = function(){
    // 	return setting.query({operation: "list_base_setting"})
    // };

    // var get_repo = function(){
    // 	return user.query({operation: "list_login_user_repo"});
    // };
    var sort = function(){
	var shops = _shops;
	return {
    	    right: _rights,
	    type: _loginType,

	    // shops exclude the shop that bind to the repository,
	    // or repository itself
    	    availableShopIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
			 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // shops, include the shop that bind to the repository but not repository
	    shopIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if (s.type === 0 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    badrepoIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if (s.type === 2 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // repository only
	    repoIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if (s.type === 1 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // shops only, include the shop bind to repository
	    sortShops: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var shop = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				py:diablo_pinyin(s.name)};
		    if (s.type === 0 && !in_array(sort, shop)){
			sort.push(shop); 
		    }
		})
		return sort;
	    }(),

	    // repository only
	    sortRepoes: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var repo = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				py:diablo_pinyin(s.name)};
		    if (s.type === 1 && !in_array(sort, repo)){
			sort.push(repo); 
		    }
		})
		return sort;
	    }(),

	    sortBadRepoes: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var shop = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				py:diablo_pinyin(s.name)};
		    if (s.type === 2 && !in_array(sort, shop)){
			sort.push(shop); 
		    }
		})
		return sort;
	    }(),

	    // shops exclude the shop that bind to the repository,
	    // or repository itself
	    sortAvailabeShops: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var repo = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				py:diablo_pinyin(s.name)};

		    if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
			 && !in_array(sort, repo)){
			sort.push(repo); 
		    } 
		})
		return sort;
	    }()

	    // sortRepoes: function(){
	    //     var sort = []; 
	    //     angular.forEach(shops, function(s){
	    // 	var repo = {id:  s.shop_id,
	    // 		    name:s.name,
	    // 		    repo:s.repo_id,
	    // 		    py:diablo_pinyin(s.name)};
	    // 	if (s.repo_id === -1 && !in_array(sort, repo)){
	    // 	    sort.push(repo); 
	    // 	}
	    //     })
	    //     return sort;
	    // }()
	}
    };

    return function(){
    	// return $q.all([
    	//     promise(get_right)(),
    	//     promise(get_shop)(),
    	//     // promise(get_base_setting)()
    	// ]).then(function(data){
	//     var rights    = data[0];
	//     var shops     = data[1];
	//     console.log(shops);
	if (_shops.length !== 0
	    && _rights !== 0
	    && angular.isDefined(_loginType)){
	    return sort();
	    
	} else {
	    return _user.get(
		{operation: "get_login_user_info"}
	    ).$promise.then(function(result){
		// console.log(result);
		_shops     = result.shop;
		_rights    = result.right;
		_loginType = result.type;
		return sort();
    	    });
	}
	
    }; 
    
});

/*
* use to get common field, such as firm, shop, employee
*/
// userApp.factory("commonFieldService", function($resource, $q){
//     var user = $resource("/right/:operation", {operation: '@operation'});

//     var promise = function(callback, params){
// 	return function(){
// 	    var deferred = $q.defer();
// 	    callback(params).$promise.then(function(data){
// 		// console.log(data);
// 		deferred.resolve(data);
// 	    });
// 	    return deferred.promise;
// 	}
//     };

//     var get_right = function(){
//     	return user.query({operation: "list_login_user_right"}); 
//     };

//     var get_shop = function(){
//     	return user.query({operation: "list_login_user_shop"});
//     };

//     // var get_rainbow = function(){
//     // 	return user.query({operation: "list_login_user_rainbow"});
//     // }

//     return function(){
//     	return $q.all([
// 	    promise(get_right)(), promise(get_shop)()
// 	]).then(function(data){
//     	    return {
//     		right: data[0],
//     		shop: data[1]
//     	    };
//     	});
//     }; 
    
// });



