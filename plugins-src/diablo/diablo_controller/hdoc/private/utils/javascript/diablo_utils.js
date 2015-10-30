var diabloUtils = angular.module("diabloUtils", []);

// diabloUtils.directive('input', [
//     function(){
// 	return {
// 	    restrict: 'E',
//             link: function(scope, element, attrs){
// 		element.bind("blur", function(event){
// 		    console.log("blur");
// 		    // event.preventDefault();
// 		    // event.stopPropagation();
// 		})
// 	    }
// 	}
//     }
// ]);

diabloUtils.directive('ngEnter', function () {
    return function (scope, element, attrs) {
        element.bind("keydown keypress", function (event) {
            if(event.which === 13) {
                scope.$apply(function (){
                    scope.$eval(attrs.ngEnter);
                });

                event.preventDefault();
            }
        });
    };
});


diabloUtils.directive('ngPulsate', function () {
    return {
	restrict: 'AE',
	link: function(scope, element, attrs){
	    element.pulsate({
                color: "#bf1c56"
            });
	}
    }
});

diabloUtils.directive("barChart", function($parse, $compile){
    function postLinkFn (scope, element, attrs){
	
	var ctx = element.get(0).getContext("2d"); 
	var chart = new Chart(ctx);

	var colorLeft = "rgba(220,220,220,0.5)";
	var strokeColorLeft = "rgba(220,220,220,1)";
	
	var colorRight = "rgba(151,187,205,0.5)";
	var strokeColorRight = "rgba(151,187,205,1)";
	
	var barLeft = function(dataLeft){
	    return {
		fillColor: colorLeft,
		strokeColor: strokeColorLeft,
		data: dataLeft
	    }
	};

	var barRight = function(dataRight){
	    return {
		fillColor: colorRight,
		strokeColor: strokeColorRight,
		data: dataRight
	    }
	};

	var barData = function(chartData){
	    return {
		labels: chartData.label,
		datasets: [
		    barLeft(chartData.left),
		    barRight(chartData.right)
		]
	    }
	};
	
	if (angular.isDefined(scope.chartData)){
	    scope.barChart = chart.Bar(barData(scope.chartData), {
		datasetFill: false
	    });
	}
	
	scope.$watch("chartData", function(newValue, oldValue){
	    console.log(newValue);
	    console.log(oldValue);
	    if (angular.isUndefined(newValue)
	       && angular.isUndefined(oldValue)){
		return;
	    };
	    
	    if (!angular.equals(newValue, oldValue)){
		if (angular.isDefined(scope.barChart)){
		    scope.barChart.destroy();
		    scope.barChart = chart.Bar(barData(newValue), {
			datasetFill: false
		    });
		} else{
		    scope.barChart = chart.Bar(barData(newValue), {
			datasetFill: false
		    });
		}
		
	    };

	    // chart.Line(scope.chartData);
	}, false);
    };
    
    return{
	restrict: 'AE',
	// template: '<canvas height="400" width="300"></canvas>',
	template: '<canvas class="canvas"></canvas>', 
	replace: true,
	transclude: true,
	// require: "ngModel",
	scope: {
	    chartData: '=',
	},

	compile: function(element, attrs){
	    element.attr("Width", $(document).width());
	    element.attr("Height", $(document).height()/2);
	    // element.attr("height", diablo_viewport().height);
	    return postLinkFn;
	}
    }
}); 

diabloUtils.directive('nextPage', function ($parse) {
    return {
	restrict: 'A',
	link: function(scope, element, attrs){

	    // console.log(scope);
	    var hander = $parse(attrs['pageByscroll']).bind(null, scope);
	    
	    $(window).on("scroll", function() {
		var scrollHeight = $(document).height();
		var top = $(window).scrollTop();
		var scrollPosition = $(window).height() + top;
		
		// console.log(scrollHeight, top);
		// console.log($(window).height());
		
		if ((scrollHeight - scrollPosition) / scrollHeight === 0) {
		    if (scope.scroll_page){
			
			// scope.$apply(function(){
			//     hander();
			// 	$('html, body').animate({
			//             scrollTop: top
			// 	}, 'slow')
			// })
		    }
		    
		} 
	    });
	}
    }
});


diabloUtils.directive('capitalize', function() {
   return {
       require: 'ngModel',
       link: function(scope, element, attrs, modelCtrl) {
           var capitalize = function(inputValue) {
               if(inputValue == undefined) inputValue = '';
               var capitalized = inputValue.toUpperCase();
               if(capitalized !== inputValue) {
		   modelCtrl.$setViewValue(capitalized);
		   modelCtrl.$render();
               }         
               return capitalized;
           }

           modelCtrl.$parsers.push(capitalize);
           capitalize(scope[attrs.ngModel]);  // capitalize initial value
       }
   };
});

diabloUtils.directive('ngModelOnblur', function() {
    return {
        restrict: 'A',
        require: 'ngModel',
        priority: 1, // needed for angular 1.2.x
        link: function(scope, elm, attr, ngModelCtrl) {
            if (attr.type === 'radio' || attr.type === 'checkbox') return;

            elm.unbind('input').unbind('keydown').unbind('change');
            elm.bind('blur', function() {
                scope.$apply(function() {
                    ngModelCtrl.$setViewValue(elm.val());
                });         
            });
        }
    };
});

diabloUtils.directive("diabloMap", function($parse, $compile){
    function postLinkFn (scope, element, attrs){
	// console.log(element);
	// $compile(element);
	// if (scope.active){
	var ctx = element[0]; 
	var map = new BMap.Map(ctx, {});
	var style = {
	    styleJson:[
		{
                    "featureType": "land",
                    "elementType": "geometry",
                    "stylers": {
                        // "color": "#e7f7fc"
			"color": "#ccccccc"
                    }
		},
		{
                    "featureType": "water",
                    "elementType": "all",
                    "stylers": {
                        "color": "#96b5d6"
                    }
		},
		{
                    "featureType": "green",
                    "elementType": "all",
                    "stylers": {
                        "color": "#b0d3dd"
                    }
		},
		{
                    "featureType": "highway",
                    "elementType": "geometry.fill",
                    "stylers": {
                        "color": "#a6cfcf"
                    }
		},
		{
                    "featureType": "highway",
                    "elementType": "geometry.stroke",
                    "stylers": {
                        "color": "#7dabb3"
                    }
		},
		{
                    "featureType": "arterial",
                    "elementType": "geometry.fill",
                    "stylers": {
                        "color": "#e7f7fc"
                    }
		},
		{
                    "featureType": "arterial",
                    "elementType": "geometry.stroke",
                    "stylers": {
                        "color": "#b0d5d4"
                    }
		},
		{
                    "featureType": "local",
                    "elementType": "labels.text.fill",
                    "stylers": {
                        "color": "#7a959a"
                    }
		},
		{
                    "featureType": "local",
                    "elementType": "labels.text.stroke",
                    "stylers": {
                        "color": "#d6e4e5"
                    }
		},
		{
                    "featureType": "arterial",
                    "elementType": "labels.text.fill",
                    "stylers": {
                        "color": "#374a46"
                    }
		},
		{
                    "featureType": "highway",
                    "elementType": "labels.text.fill",
                    "stylers": {
                        "color": "#374a46"
                    }
		},
		{
                    "featureType": "railway",
                    "elementType": "labels.icon",
                    "stylers": {
                        "color": "#ffffff",
                        "hue": "#ffffff"
                    }
		},
		{
                    "featureType": "road",
                    "elementType": "all",
                    "stylers": {
                        "visibility": "off"
                    }
		}
	    ]
	};

	map.setMapStyle(style);
	
	map.disableScrollWheelZoom();

	// map.centerAndZoom(new BMap.Point(116.404, 39.915), 8); 
	map.centerAndZoom("株洲", 8);

	// var cr = new BMap.CopyrightControl({anchor: BMAP_ANCHOR_TOP_RIGHT});
	// map.addControl(cr);
	// var bs = map.getBounds(); 
	
	// map.addControl(new BMap.NavigationControl());
	
	var geo = new BMap.Geocoder();
	geo.getPoint("株洲", function(p){
	    if (p){
		map.centerAndZoom(p, 8);
		 var myIcon =
		    new BMap.Icon(
			"http://api.map.baidu.com/img/markers.png",
			new BMap.Size(23, 25), {  
			    offset: new BMap.Size(10, 25),
			    imageOffset: new BMap.Size(0, 0 - 10 * 25)});
		
		var marker = new BMap.Marker(p, {icon:myIcon});
		// marker.setAnimation(BMAP_ANIMATION_BOUNCE);
		marker.setZIndex(10000);
		map.addOverlay(marker);
	    }
	}, "湖南省");

	// console.log(scope.retailer);
	angular.forEach(scope.retailer, function(r){
	    if (r.pid !== -1 && r.cid !== -1){
		geo.getPoint(r.city.name, function(p){
		    if (p){
			var marker = new BMap.Marker(p);
			// marker.setTitle(r.address);
			map.addOverlay(marker);
		    } else {
			// console.log(r);
		    } 
		}, r.province.name)
	    } 
	})
	
    };
    
    return{
	restrict: 'E',
	// template: '<canvas width="800" height="400"></canvas>',
	// template: '<div style="width:800px;height:400px"></div>',
	template: '<div></div>', 
	replace: true,
	transclude: true,
	// require: "ngModel",
	scope: {
	    retailer: '=',
	},

	compile: function(element, attrs){
	    // console.log(element);
	    element.css({height:diablo_viewport().height});
	    // element.css({height:"100%"} );
	    // element.css({height:"880px", width:"800px"});
	    // element.attr("width", $(document).width()/2);
	    // element.attr("height", $(document).height()/2);
	    return postLinkFn;
	}
    }
});

diabloUtils.directive('infiniteScroll', ['$rootScope', '$window', '$timeout', function($rootScope, $window, $timeout){
    return {
	link: function(scope, elem, attrs) {
	    var checkWhenEnabled, handler, scrollDistance, scrollEnabled;
	    $window = angular.element($window);
	    scrollDistance = 0;
	    if (attrs.infiniteScrollDistance != null) {
		scope.$watch(attrs.infiniteScrollDistance, function(value) {
		    return scrollDistance = parseInt(value, 10);
		});
	    }
	    scrollEnabled = true;
	    checkWhenEnabled = false;
	    if (attrs.infiniteScrollDisabled != null) {
		scope.$watch(attrs.infiniteScrollDisabled, function(value) {
		    scrollEnabled = !value;
		    if (scrollEnabled && checkWhenEnabled) {
			checkWhenEnabled = false;
			return handler();
		    }
		});
	    }
	    handler = function() {
		var elementBottom, remaining, shouldScroll, windowBottom;
		windowBottom = $window.height() + $window.scrollTop();
		elementBottom = elem.offset().top + elem.height();
		remaining = elementBottom - windowBottom;

		// console.log(windowBottom);
		// console.log(elementBottom);
		// console.log(remaining);
		shouldScroll = remaining + 110 <= $window.height() * scrollDistance;
		// shouldScroll = remaining <= -110;
		// shouldScroll = 
		if (shouldScroll && scrollEnabled) {
		    if ($rootScope.$$phase) {
			return scope.$eval(attrs.infiniteScroll);
		    } else {
			return scope.$apply(attrs.infiniteScroll);
		    }
		} else if (shouldScroll) {
		    return checkWhenEnabled = true;
		}
	    };
	    
	    $window.on('scroll', handler);
	    scope.$on('$destroy', function() {
		return $window.off('scroll', handler);
	    });
	    
	    return $timeout((function() {
		if (attrs.infiniteScrollImmediateCheck) {
		    if (scope.$eval(attrs.infiniteScrollImmediateCheck)) {
			return handler();
		    }
		} else {
		    return handler();
		}
	    }), 0);
	}
    };
}]);

diabloUtils.directive('queryGroup', function () {
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/queryGroup.html',
	replace: true,
	transclude: true,
	scope: {
	    filters:      '=', 
	    prompt:       '=',
	    ok:  '&'
	},
	
	link: function(scope, element, attrs){
	    // console.log(scope);
	    // scope.$watch('filters', function(newValue, oldValue){
	    // 	// console.log(newValue);
	    // 	// console.log(oldValue);
		
	    // })

	    // console.log(scope.prompt);
	    scope.is_even = function() {
		console.log(scope.filters.length);
		var even = scope.filters.length % 2 === 0;
		console.log(even);
		return even;
	    }

	    scope.change_field = function(field){
		// console.log(field);
		field.value = undefined;
	    };
	}
    }
});

diabloUtils.directive('queryPattern', function () {
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/queryPattern.html',
	replace: true,
	transclude: true,
	require: "ngModel",
	scope:{
	    filters:  '=',
	    filter:   '='
	},
	link: function(scope, element, attr, ngModel){
	    // console.log(scope);
	    // pattern
	    scope.pattern = {};
	    scope.pattern.matches = [{op:"and", chinese:"匹配所有"}
				     // {op:"or",  chinese:"匹配任意一个"}
				    ];
	    scope.pattern.match = scope.pattern.matches[0];

	    ngModel.$setViewValue(scope.pattern.match);
	    scope.$watch('pattern.match', function(newValue, oldValue){
		if (angular.equals(newValue, oldValue)) return;
		
		ngModel.$setViewValue(newValue);
	    });

	    // console.log(scope.filters);

	    // scope.increment = 0;
	    scope.increment = scope.filters.length;
	    angular.forEach(scope.filters, function(f){
	    	angular.forEach(f.fields, function(e){
	    	    if (e.name === f.field.name){
	    		f.field = e;
	    	    }
	    	})
	    });

	    // console.log(scope.filters);
	    
	    // add a filter
	    scope.add_filter = function(){
		// console.log("add_filter...");
		scope.filters[scope.increment] = angular.copy(scope.filter);
		// use first as default field
		scope.filters[scope.increment].field
		    = scope.filters[scope.increment].fields[scope.increment];
		scope.increment++;
	    };

	    // delete a filter
	    scope.del_filter = function(){
		scope.filters.splice(-1, 1);
		scope.increment--; 
	    };
	    
	}
    }
});


diabloUtils.directive('addDeleteFilter', function () {
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/add-delete-filter.html',
	replace: true,
	transclude: true,
	// require: "ngModel",
	scope:{
	    filters:  '=',
	    filter:   '=',
	},
	link: function(scope, element, attr){
	    scope.increment = 0;
	    // add a filter
	    scope.add_filter = function(){
		// console.log("add_filter...");
		scope.filters[scope.increment] = angular.copy(scope.filter);
		// use first as default field
		scope.filters[scope.increment].field
		    = scope.filters[scope.increment].fields[scope.increment];
		scope.increment++;
	    };

	    // delete a filter
	    scope.del_filter = function(){
		scope.filters.splice(-1, 1);
		scope.increment--; 
	    };
	}
    } 
});

diabloUtils.directive('timeSearch', function (){
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/timeSearch.html',
	replace: true,
	transclude: true,
	scope: {
	    glyphicon: '@',
	    time:      '=',
	    ok:        '&'
	},
	
	link: function(scope, element, attrs){
	    scope.open_calendar = function(event){
		event.preventDefault();
		event.stopPropagation();
		scope.opened = true;
	    };

	    // scope.time = $.now();
	}
    }
});

diabloUtils.service("diabloUtilsService", function($modal){
    // response dialog
    this.response = function(result, title, body, scope){
	return $modal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'diabloDialogCtrl',
	    // backdrop: 'false',
	    backdrop: 'static',
	    // scope: scope,
	    resolve:{
		message: function(){
		    return {
			success     :result,
			title       :title,
			body        :body,
			show_cancel :false,
		    }
		}
	    }
	})
    };

    this.response_with_callback = function(result, title, body, scope, callback){
	return $modal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'diabloDialogCtrl',
	    // backdrop: 'false',
	    backdrop: 'static',
	    // scope: scope,
	    resolve:{
		message: function(){
		    return {
			success     :result,
			title       :title,
			body        :body,
			callback    :callback,
			show_cancel :false,
		    }
		}
	    }
	})
    };

    this.request = function(title, body, callback, params, scope){
	return $modal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'diabloDialogCtrl',
	    // backdrop: 'true',
	    backdrop: 'static',
	    // animation: true,
	    // openedClass: "modal-open-noscroll",
	    scope: scope,
	    resolve:{
		message: function(){
		    return {
			success :false,
			title   :title,
			body    :body,
			callback:callback,
			params  :params
		    }
		}
	    }
	})
    };

    this.edit_with_modal = function(templateUrl, size, callback, scope, params){
	return $modal.open({
	    templateUrl: templateUrl,
	    controller: 'diabloEditDialogCtrl',
	    // backdrop: 'false',
	    backdrop: 'static',
	    openedClass: "modal-open-noscroll",
	    size:  size,
	    scope: scope,
	    resolve:{
		message: function(){
		    return {
			callback:callback,
			params: params
		    }
		}
	    }
	})
    };
});

diabloUtils.controller("diabloDialogCtrl", function($scope, $modalInstance, message){
    // console.log($scope);
    console.log($modalInstance);
    console.log(message);
    $scope.success = message.success;
    $scope.title = message.title;
    $scope.body  = message.body; 
    
    $scope.show_cancel = angular.isDefined(message.show_cancel) ? message.show_cancel : true;
    
    $scope.cancel = function(){
	$modalInstance.dismiss('cancel');
    };

    $scope.ok = function() {
	$modalInstance.dismiss('ok');
	if (angular.isDefined(message.callback) && typeof(message.callback) === "function"){
	    var callback = message.callback;
	    if (angular.isDefined(message.params)){
		callback(message.params)
	    } else{
		callback();
	    }
	}
    };
});


diabloUtils.controller("diabloEditDialogCtrl", function($scope, $modalInstance, message){
    // console.log($scope);
    // console.log($modalInstance);
    // console.log(message); 
    
    var deviceAgent = navigator.userAgent.toLowerCase();
    if (deviceAgent.match(/iphone|ipod|ipad/i)
    	// && (navigator.sayswho.match(/^Chrome\s+\d+/i).length !== 0 )
       ) {
    	$modalInstance.opened.then(function(){
    	    $('.header').hide();
            $('.footer').hide();
	    
    	    setTimeout(function () {
    	    	$('.modal')
    		    .addClass('modal-ios')
    	    	    .height($(window).height())
    	    	    .css({'margin-top': $(window).scrollTop() + 'px'});


    		// $('.modal-backdrop').css({
                //     position: 'absolute', 
                //     top: 0, 
                //     left: 0,
                //     width: '100%',
                //     height: Math.max(
    		// 	document.body.scrollHeight,
    		// 	document.documentElement.scrollHeight,
			
    		// 	document.body.offsetHeight,
    		// 	document.documentElement.offsetHeight,
			
    		// 	document.body.clientHeight,
    		// 	document.documentElement.clientHeight
                //     ) + 'px'
    		// });
		
    	    }, 0);

    	    $('input').on('blur', 'input, select, textarea', function(){
    		setTimeout(function() {
    		    // This causes iOS to refresh, fixes problems when virtual keyboard closes
    		    $(window).scrollLeft(0);

    		    var $focused = $(':focus');
    		    // Needed in case user clicks directly from one input to another
    		    if(!$focused.is('input')) {
    			// Otherwise reset the scoll to the top of the modal
    			$(window).scrollTop($(window).scrollTop());
    		    }
    		}, 0);
    	    });
	    
    	});

    	$modalInstance.result.then(function () {
            $('.header').show();
            $('.footer').show(); 
    	}, function () {
            $('.header').show();
            $('.footer').show(); 
    	}, function(){
            $('.header').show();
            $('.footer').show(); 
    	});
    };
    
    
    // $scope.out = {};
    var callback = message.callback;
    $scope.params = angular.copy(message.params);
    // console.log($scope.params);
        
    $scope.cancel = function(){
	$modalInstance.dismiss('cancel');
    };

    $scope.ok = function() {
	$modalInstance.dismiss('ok');
	if (angular.isDefined(callback) && typeof(callback) === "function"){
	    callback($scope.params);
	}	    
    };
});

// =============================================================================
// @desc :$q.all([
//          promise(rightService.list_role)(),
//          promise(rightService.list_account_right, account)()
// ]).then
// =============================================================================

diabloUtils.service("diabloPromise", function($q){
    this.promise = function(callback, params){
	return function(){
	    var deferred = $q.defer();
	    callback(params).then(function(data){
		// console.log(data);
		deferred.resolve(data);
	    });
	    return deferred.promise;
	}
    }
});

diabloUtils.service("diabloPagination", function(){
    var _pageData = null;
    var _itemsPerpage = null;
    var _index = [];
    
    this.set_data = function(data){
	_pageData = data;
    };

    this.get_data = function(){
	return _pageData;
    }

    this.set_items_perpage = function(items){
	_itemsPerpage = items;
    };

    this.get_length = function(){
	return _pageData.length;
    };

    this.get_itmes_perpage = function(){
	return _itemsPerpage;
    };
    
    this.get_page = function(currentPage){
	var begin = (currentPage - 1) * _itemsPerpage;
	var end = begin + _itemsPerpage > this.get_length()
	    ? (this.get_length()) : begin + _itemsPerpage;
	
	// console.log(begin);
	// console.log(end);
	// console.log(_pageData.slice(begin, end));
	
	// _index = [];
	// for (var i=begin; i<end; i++){
	//     _index.push(i);
	// }
	// return _index;
	return _pageData.slice(begin, end);
    };
});


diabloUtils.directive('diabloItmesPerpage', function(diabloPagination) {
    return {
	restrict: 'AE',
	template: '<ul class="pagination" x-ng-repeat="p in [5, 10, 25, 50]">'
	    + '<li><a href="javascript:;" x-ng-click="change(p)">{{p}}</a></li>'
	    + '</ul>',
	replace: true,
	transclude: true,
	scope:{
	    afterChange: '&'
	},
	
	link: function(scope, element, attr){
	    scope.change = function(p){
		// console.log(p);
		diabloPagination.set_items_perpage(p);
		if (diabloPagination.get_data() !== null){
		    scope.afterChange();
		}
	    }
	    
	    scope.pages = [5, 10, 25, 50];
	    diabloPagination.set_items_perpage(scope.pages[0]);
	    // scope.change(scope.pages[0]);
	    
	}
    }
});


diabloUtils.directive('diabloSwitch', function(){
    return {
	restrict: 'AE',
	require: '?ngModel', 
	
	link: function(scope, element, attrs, ngModel){
	    element.bootstrapSwitch();

	    element.on('switchChange.bootstrapSwitch', function(event, state) {
                if (ngModel) {
		    console.log(scope.$parent);
                    scope.$apply(function() {
			// var newValue = state === true ? 1:0;
                        ngModel.$setViewValue(state);
                    });
                }
            });

	     scope.$watch(attrs.ngModel, function(newValue, oldValue) {
		 console.log(newValue, oldValue);
                 if (newValue) {
                     element.bootstrapSwitch('state', true, true);
                 } else {
                     element.bootstrapSwitch('state', false, true);
                 }
             });
	}
    }
});

diabloUtils.directive('defaultImg', function () {
        return{
            restrict: 'AE',
            // template: '<canvas width="800" height="400"></canvas>',
            template:'<img ng-src={{default_img}}></img>', 
            replace: true,
            transclude: true,
            scope: {
		// styleNumber: '=',
		// brand:       '=',
		// type:        '=',
		// total:       '='
            },

            link: function(scope, element, attrs){
		scope.default_img =
		    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKAAAAB4CAYAAAB1ovlvAAAFeUlEQVR4Xu2Zr1MjQRCF5wRgwIABhUKhUGBQYMCA4a/EgAEDCgMGMGBQYMAQAwbMXfVWTWoz2c2vq8rrVH8x3CXZ7dfvfendmf3T6XT+Jl44IHLgDwCKnKds5QAAAoLUAQCU2k9xAIQBqQMAKLWf4gAIA1IHAFBqP8UBEAakDgCg1H6KAyAMSB0AQKn9FAdAGJA6AIBS+ykOgDAgdQAApfZTHABhQOoAAErtpzgAwoDUAQCU2k9xAIQBqQMAKLWf4gAIA1IHAFBqP8UBEAakDgCg1H6KAyAMSB0AQKn9FAdAGJA6AIBS+ykOgDAgdQAApfZTHABhQOoAAErtpzgAwoDUAQCU2k9xAIQBqQMAKLWf4gAIA1IHAFBqP8UBEAakDgCg1H6KAyAMSB0AQKn9FAdAGJA6AIBS+ykOgDAgdQAApfZTHABhQOoAAErtpzgAwoDUAQCU2k9xAIQBqQMAKLWf4m4AfH9/T09PT2l/f78xla+vr3R6eprsr73m5+fT8fFxWltb6/v+xcVFenl5qd7f2NhIh4eH3e9YnbOzs/T7+5uWlpbSyclJda7z8/Nkn9nLvm/H1V/D9Nl36+e2/+/s7KTt7e2x9EVDUgrgz89PT/AlLDkMC9agMjAycHd3d+n+/r4PQvve9/d3Ojo6qg43sBYXF/sgLM9nWq6vr9Pu7m4Fpr1G1WffNT32AzKg7Xj7AVxdXU2kLxKEUgDrRluAn5+fPaDkzw2WlZWVnmmS4VhfX+++3xR6nko2WetTraxnx3Y6ncaJlQFr09f0A2nSMo6+KBDODID50lgPpgSzPv0WFhZ6plg5Be1SbtNxb28vLS8vVxPMLpf5uBKAQT+QQZ+VevN0HqYPAKfswLAJ+PHx0b281S+PW1tb1WRrmoj1CVoGX59qeTKW932jTOhBdevHT6JvyhFIys3EBGxyxi5nDw8P1b2eTZO8SNnc3Oy7jJb3Z/l8+Ribjvk8bSm0/UDqdW2S2hTOr/oiZBJ9EiKmXHQmAbQwLy8v08HBQXfBMGnABtbr6+t/Azg3N1fdp+YVd3nvOam+KfMw9XIzB2ATfObaJAHnc9niolykjHoPmOuurq72LaDqcNu2j20jjTOhp06DoOBMAdgGX/2esL4qHnYPaJdwA+ft7W3oFBzlElzu+dltws3NTc9e4zj6BDxMveTMADgIvkGg5Zv/plXw4+Njte+Xp5j9u20h0gZg2/lNUx1A2xscZ5U+dRJEBWcCwKZN4jz1np+fk62Ec+Dl5m/bPmCefvWN7UH3gsO2Yeqb0DnL8v6SfcB+yt0A2DQdslyDyu6dysduTZvHozwJsYmXp1+5Im6bgoP0Na2m28AfRZ9oGEnKSgEsH3VlB/IzWvtbPgMuXWp6bjvoWbBNpdvb2+o0eZuk1NH2fpO+/F55jkmfVUsoEBaVAijsm9JOHABAJ0FElQGAUZN30jcAOgkiqgwAjJq8k74B0EkQUWUAYNTknfQNgE6CiCoDAKMm76RvAHQSRFQZABg1eSd9A6CTIKLKAMCoyTvpGwCdBBFVBgBGTd5J3wDoJIioMgAwavJO+gZAJ0FElQGAUZN30jcAOgkiqgwAjJq8k74B0EkQUWUAYNTknfQNgE6CiCoDAKMm76RvAHQSRFQZABg1eSd9A6CTIKLKAMCoyTvpGwCdBBFVBgBGTd5J3wDoJIioMgAwavJO+gZAJ0FElQGAUZN30jcAOgkiqgwAjJq8k74B0EkQUWUAYNTknfQNgE6CiCoDAKMm76RvAHQSRFQZABg1eSd9A6CTIKLKAMCoyTvpGwCdBBFVBgBGTd5J3wDoJIioMgAwavJO+gZAJ0FElQGAUZN30jcAOgkiqgwAjJq8k77/Aa0A9u1tG0GmAAAAAElFTkSuQmCC"; 
            }
        }
});

diabloUtils.directive('drawDefaultImg', function () {
    return{
        restrict: 'AE',
        // template: '<canvas width="800" height="400"></canvas>',
        template: '<canvas></canvas>',
        replace: true,
        transclude: true,
        // require: "ngModel",
        scope: {
            // orgImage: '=',
	    // options: '='
        },

        link: function(scope, element, attrs){
	    // set default width and height
	    
	    var height = 120;
	    var width  = 160;
	    element.attr("width", width);
            element.attr("height", height);
	    
            var ctx = element.get(0).getContext("2d");
	    ctx.fillStyle="rgba(238,238,238,1)";
	    ctx.fillRect(0, 0, width, height);
	    
	    ctx.fillStyle = "rgba(127, 127, 127, 1)";
	    ctx.font = "20px sans-serif";
	    ctx.textAlign = "start"
            ctx.textBaseline = 'top';
	    ctx.fillText("120X160", 30, 50);

	    w = element.get(0).toDataURL("image/png");
	    console.log(w);

	    // var context = ctx;
	    // context.fillStyle = "#EEEEFF";
            // context.fillRect(0,0,400,300);
            // context.fillStyle = "#00f";
            // context.font = "italic 30px sans-serif";
            // context.textBaseline = 'top';
            // var txt="fill示例文字"
            // context.fillText(txt, 0, 0);
        }
    }
});


diabloUtils.directive('imageDraw', function ($q) {
    function postLinkFn (scope, element, attrs){
	// console.log(scope);
	var ctx = element.get(0).getContext("2d");

	scope.$watch("orgImage.image", function(newValue, oldValue){
	    if (angular.isUndefined(newValue)
		|| angular.equals(newValue, oldValue)){
		return;
	    };

	    var options = scope.options; 
	    // var maxHeight = options ? options.maxHeight : 150;
	    // var maxWidth = options ? options.maxWidth : 200;
	    var quality = options ? options.quality : 0.5;
	    // var type = options ? options.type : 'image/jpg';

	    var orgImage = scope.orgImage.image;
	    // console.log(orgImage);
	    var height = 120;
	    var width  = 160;
	    // var height = orgImage.height;
	    // var width = orgImage.width;

	    // console.log(height, width, quality);

	    // if (width > height) {
	    // 	if (width > maxWidth) {
	    // 	    height = Math.round(height *= maxWidth / width);
	    // 	    width = maxWidth;
	    // 	}
	    // } else {
	    // 	if (height > maxHeight) {
	    // 	    width = Math.round(width *= maxHeight / height);
	    // 	    height = maxHeight;
	    // 	}
	    // }

	    console.log(height, width, quality);
	    
            element.attr("width", width);
            element.attr("height", height);

	    //draw image on canvas
	    ctx.drawImage(orgImage, 0, 0, width, height); 
	    // get the data from canvas as 70% jpg (or specified type). 
	    scope.orgImage.dataUrl = element.get(0).toDataURL("image/png", quality);
	})
    };
    
    return{
        restrict: 'AE',
        // template: '<canvas width="800" height="400"></canvas>',
        template: '<canvas></canvas>',
        replace: true,
        transclude: true,
        // require: "ngModel",
        scope: {
            orgImage: '=',
	    options: '='
        },

        compile: function(element, attrs){
            return postLinkFn;
        }
    }
});

diabloUtils.directive('imageUpload', function ($q) {
    'use strict'

    var URL = window.URL || window.webkitURL; 
    
    var createImage = function(url, callback) {
	var image = new Image();
	image.onload = function() {
	    callback(image);
	};
	image.src = url;
    };

    var fileToDataURL = function (file) {
	// console.log(file);
	var deferred = $q.defer();
	var reader = new FileReader(); 
	reader.readAsDataURL(file);
	
	reader.onload = function (e) {
	    deferred.resolve(e.target.result);
	};
	return deferred.promise;
    };
    
    return {
	restrict: 'AE',
	template: '<span class=\"btn btn-primary btn-file\">'
	    +'<i class="glyphicon glyphicon-arrow-right"></i>'
	    // +'<i class="glyphicon glyphicon-minus"></i>'
	    +'<input type="file" accept="image/*"></input>'
	    +'</span>',
	replace: true,
	transclude: true,
	scope: {
	    image: '=',
	    maxHeight: '@?',
	    maxWidth: '@?',
	    quality: '@?',
	    type: '@?'
	},
	
	link: function(scope, element, attrs){
	    var doResizing = function(imageResult, callback) {
		createImage(imageResult.url, function(image) {
		    console.log(image);
		    // var dataURL = resizeImage(image, scope);
		    // imageResult.resized = {
		    // 	dataURL: dataURL,
		    // 	type: dataURL.match(/:(.+\/.+);/)[1],
		    // };
		    imageResult.image = image; 
		    callback(imageResult);
		});
	    };

	    var applyScope = function(imageResult) {
		scope.$apply(function() {
		    console.log(imageResult);
		    scope.image = imageResult;
		});
	    };
	    
	    angular.element('.btn-file :file').bind('change', function(evt){
		// console.log(evt); 
		var file = evt.target.files[0];
		// console.log(file);
		if (angular.isDefined(file)) {
		    var imageResult = {
			file: file,
			url:  URL.createObjectURL(file)
		    };

		    fileToDataURL(file).then(function (dataURL) {
			// imageResult.dataURL = dataURL; 
		    });

		    
		    doResizing(imageResult, function(imageResult) {
			applyScope(imageResult);
		    });
		} 
	    }) 
	}
    }
});
