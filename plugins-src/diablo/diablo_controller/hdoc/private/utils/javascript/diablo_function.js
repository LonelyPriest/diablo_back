
var diablo_delay = 1000; //ms

var diablo_yes = 1;
var diablo_no = 0;

var diablo_frontend = 0;
var diablo_backend = 1;
var diablo_badrepo = 1;

var diablo_round_record = 0;
var diablo_round_row = 1;

/*
 * storage key
 */

// wsale
var diablo_key_wsale_trans            = "q-wsale-trans";
var diablo_key_wsale_trans_detail     = "q-wsale-trans-detail";

// inventory
var diablo_key_inventory_detail       = "q-inventory-detail"
var diablo_key_invnetory_trans        = "q-inventory-trans";
var diablo_key_invnetory_trans_detail = "q-inventory-trans-detail";

// firm
var diablo_key_firm                   = "q-firm-detail";
var diablo_key_firm_trans             = "q-firm-trans";
var diablo_key_firm_trans_detail      = "q-firm-trans-detail";

// retailer
var diablo_key_retailer               = "q-retailer-detail";
var diablo_key_retailer_trans         = "q-retailer-trans";
var diablo_key_retailer_trans_detail  = "q-retailer-trans-detail";

function diablo_range(n){
    if (n < 0) return;
    return n ? diablo_range(n - 1).concat(n):[];
};

var in_array = function(arr, item){
    if (angular.isArray(arr)){
	var length = arr.length;
	for (var i = 0; i < length; i++){
	    if (angular.equals(arr[i], item)){
		return true;
	    }
	}
    }

    return false;
};


var diablo_is_empty = function(obj){
    for (var name in obj){
	return false;
    }

    return true;
};

var diablo_obj_strip = function(obj){
    for (var k in obj){
	if (obj[k] === "null" || obj[k] === "undefined"){
	    obj[k] = ""
	}
    } 
    return obj;
};

var diablo_season = ["春", "夏", "秋", "冬"];

var diablo_season2number = function(season){
    if (season == "春")
	return 0;
    else if (season == "夏")
	return 1;
    else if (season == "秋")
	return 2;
    else
	return 3;
}

var diablo_season2objects = [
    {name:"春", id:0},
    {name:"夏", id:1},
    {name:"秋", id:2},
    {name:"冬", id:3}
];

var diablo_sex2object = [
    {name:"女", id:0},
    {name:"男", id:1},
];

var diablo_sex = ["女", "男"];

var diablo_sizegroup = ["si", "sii", "siii", "siv", "sv", "svi"];

var diablo_shop = 0;
var diablo_repo = 1;

var diablo_sell_style = [
    {name: "吊牌价", id:1, f: "tag_price"},
    {name: "批发价", id:2, f: "pkg_price"},
    {name: "价3",    id:3, f: "price3"},
    {name: "价4",    id:4, f: "price4"},
    {name: "价5",    id:5, f: "price5"}
];

var diablo_sex2number = function(sex){
    if (sex == "女"){
	return 0;
    } else{
	return 1;
    }
};

var diablo_move_state = ["在途中", "已转移"];

var diablo_get_object = function(objectId, objects){
    if (!angular.isArray(objects)){
	return undefined;
    }
    
    for (var i=0, l=objects.length; i<l; i++){
	if (objectId === objects[i].id){
	    return objects[i]
	}
    }

    return undefined;
};

var diablo_remove_local_storage = function(l){
    var keys = l.keys();
    console.log(keys);
    var now = $.now();
    angular.forEach(keys, function(k){
	if (now > l.get(k).t + diablo_day_millisecond){
	    l.remove(k);
	}
    });
    
    // console.log(keys);
};

/*
 * add ordered id
*/
var diablo_order = function(objects, begin){
    // console.log(begin);
    var order_id = 1;

    if (angular.isDefined(begin) && diablo_set_integer(begin)){
	order_id = begin;
    }
    
    angular.forEach(objects, function(obj){
	obj.order_id = order_id;
	order_id++;
    });
    return objects;
};

var diablo_order_page = function(current_page, items_perpage, data){
    var inc = ((current_page - 1) * items_perpage) + 1;
    angular.forEach(data, function(d){
	d.order_id = inc;
	inc++;
    });

    return data;
};

var diablo_format_year = function(objects){
    angular.forEach(objects, function(obj){
	obj.year = angular.isDefined(obj.year) ? obj.year.slice(0,4) : obj.year;
    })
};

var diablo_goto_page = function(url){
    window.location = url;
};

var diablo_sidebar_goto_page = function(node, url){
    window.location = url;
    
    var sidebar = $(".page-sidebar-menu");
    var links = sidebar.find('li.active').removeClass();

    var path = node.split("\/");
    if (path.length === 1){
	var active_link = sidebar.find('li#' + node);
	active_link.addClass("active");
    } else if (path.length === 2){
	$('li#' + path[0] + "-" + path[1]).parent().parent().addClass("active");
    } 
};


var diablo_filters = function(filters){
    var filter = {};
    angular.forEach(filters, function(f){
	if (angular.isDefined(f.value) && f.value){
	    var value = typeof(f.value) === 'object' ? f.value.id : f.value;
	    
	    // employ use the number, not id
	    // value = f.field.name === "employ" ? f.value.number : value;
	    // repeat
	    if (filter.hasOwnProperty(f.field.name)){
		var old = [].concat(filter[f.field.name]);
		if (!in_array(old, value)){
		    filter[f.field.name] = old.concat(value);
		}
	    } else{
		filter[f.field.name] = value;
	    }
	}
    });

    return filter;
};


var diablo_day_millisecond = 86400 * 1000;

var diablo_filter_time = function(time, days, format){
    var ms_time = typeof(time) === 'object' ? time.getTime() : time; 
    return format(ms_time + 86400 * 1000 * days, "yyyy-MM-dd");	
}

var diablo_format_prompt = function(prompts, formats){
    diablo_order(prompts);
    angular.forEach(prompts, function(p){
	formats.push({name: p.name, id: p.id, order_id: p.order_id});
    }); 
    return formats;
};

var diablo_valid_dialog = function(sizes){
    return sizes.length > 8 ? "lg" : undefined;
};

var diablo_pinyin = function(name){
    return pinyin.getCamelChars(name);
};


function diablo_float_add(arg1, arg2) {
    var r1, r2, m, c;
    try {
        r1 = arg1.toString().split(".")[1].length;
    }
    catch (e) {
        r1 = 0;
    }
    try {
        r2 = arg2.toString().split(".")[1].length;
    }
    catch (e) {
        r2 = 0;
    }
    c = Math.abs(r1 - r2);
    m = Math.pow(10, Math.max(r1, r2));
    if (c > 0) {
        var cm = Math.pow(10, c);
        if (r1 > r2) {
            arg1 = Number(arg1.toString().replace(".", ""));
            arg2 = Number(arg2.toString().replace(".", "")) * cm;
        } else {
            arg1 = Number(arg1.toString().replace(".", "")) * cm;
            arg2 = Number(arg2.toString().replace(".", ""));
        }
    } else {
        arg1 = Number(arg1.toString().replace(".", ""));
        arg2 = Number(arg2.toString().replace(".", ""));
    }
    return (arg1 + arg2) / m;
}

// var diablo_float_add = function(arg1, arg2){
//     var r1,r2,m;
//     try{
// 	r1 = arg1.toString().split(".")[1].length;
//     } catch(e) {
// 	r1=0;
//     }
    
//     try{
// 	r2 = arg2.toString().split(".")[1].length;
//     } catch(e){
// 	r2 = 0;
//     }
    
//     m = Math.pow(10,Math.max(r1,r2));
//     return (arg1 * m + arg2 * m) / m;
// };


var diablo_float_sub = function (arg1, arg2) {
    var r1, r2, m, n;
    try {
        r1 = arg1.toString().split(".")[1].length;
    }
    catch (e) {
        r1 = 0;
    }
    try {
        r2 = arg2.toString().split(".")[1].length;
    }
    catch (e) {
        r2 = 0;
    }
    m = Math.pow(10, Math.max(r1, r2)); //last modify
    n = (r1 >= r2) ? r1 : r2;
    return ((arg1 * m - arg2 * m) / m).toFixed(n);
};

var diablo_float_mul = function(arg1, arg2){
    var m  = 0;
    var s1 = arg1.toString();
    var s2 = arg2.toString();
    try{
	m+=s1.split(".")[1].length
    }catch(e){}
    
    try{
	m+=s2.split(".")[1].length}
    catch(e){}
    
    return Number(s1.replace(".",""))*Number(s2.replace(".",""))/Math.pow(10,m);
};

var diablo_round = function(value){
    return Math.round(value);
};

var diablo_full_year = [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020];

var diablo_print_field = {
    brand:        "品牌",
    style_number: "款号",
    type:         "类型",
    color:        "颜色",
    size_name:    "尺码组名称",
    size:         "尺码",
    price:        "单价",
    discount:     "折扣",
    dprice:       "折后价",
    hand:         "手数",
    count:        "数量",
    calc:         "小计"
};

var diablo_now_year = function(){
    var now = new Date();
    return now.getFullYear();
};

var diablo_now_date = function(){
    var now = new Date();
    now.setHours(0, 0, 0, 0);
    // now.setMinutes(0);
    // now.setSeconds(0);
    // now.setMilliseconds(0);
    return now;
};

var diablo_set_date = function(date){
    // console.log(date);
    var a = date.split("-");
    return new Date(parseInt(a[0]), parseInt(a[1]) - 1, parseInt(a[2]))
	.getTime();
};

var diablo_set_datetime = function(datetime){
    var date = datetime.substr(0,10).split("-")
    var time = datetime.substr(11, 8).split(":");
    return new Date(date[0], date[1]-1, date[2], time[0], time[1], time[2]);
};

var diablo_get_time = function(date){
    if (typeof(date) === 'object'){
	return date.getTime();
    } else {
	return date;
    }
};

diablo_get_amount = function(cid, size, sorts){
    for(var i=0, l=sorts.length; i<l; i++){
	if (sorts[i].cid === cid && sorts[i].size === size){
	    return sorts[i];
	}
    }
    return undefined;
};

diablo_sort_inventory = function(invs, orderSizes){
    // console.log(invs);
    // console.log(orderSizes);
    var in_sort = function(sorts, inv){
	for(var i=0, l=sorts.length; i<l; i++){
	    if(sorts[i].cid === inv.color_id
	       && sorts[i].size === inv.size){
		sorts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var total = 0;
    var used_sizes  = [];
    var colors = [];
    var sorts = [];
    angular.forEach(invs, function(inv){
	if (angular.isDefined(inv.amount)){
	    total += inv.amount; 
	};
	
	if (!in_array(used_sizes, inv.size)){
	    used_sizes.push(inv.size);
	};
	
	var color = {cid:inv.color_id, cname: inv.color};
	if (!in_array(colors, color)){
	    colors.push(color)
	};

	if (!in_sort(sorts, inv)){
	    sorts.push({cid:inv.color_id, size:inv.size, count:inv.amount})
	}; 
    });

    // format size
    var order_used_sizes = [];
    if (angular.isArray(orderSizes) && orderSizes.length !== 0){
	order_used_sizes = orderSizes.filter(function(s){
	    return in_array(used_sizes, s); 
	});
    } else{
	order_used_sizes = used_sizes;
    };
    

    // console.log(order_used_sizes);
    // console.log(colors);
    // console.log(sorts);
    
    return {total: total, size: order_used_sizes, color:colors, sort:sorts};
};

var diablo_authen = function ($httpProvider) {
    var interceptor = ['$q', function($q){
	function success(response) {
	    return response;
	}

	function error(response) {
	    // console.log(response);
	    // 599 is the customer code of HTTP, means invalid session,
	    // so redirect to login
	    if(response.status === 401
	       || response.status === 599) {
		diablo_goto_page("/");
		return $q.reject(response);
	    }
	    // 598 is the customer code of HTTP, means no right to the operation
	    else if (response.status === 598){
		var injector = angular.element(document).injector();
		var dialog = injector.get('diabloUtilsService');
		dialog.response(false, "操作鉴权失败：",
				response.data.action + " 操作鉴权失败", undefined);
		return $q.reject(response);
	    }
	    else {
		return $q.reject(response);
	    }
	}

	return function(promise) {
	    return promise.then(success, error);
	}
    }]; 
    $httpProvider.responseInterceptors.push(interceptor);
};



var diablo_base_setting = function(name, shop, base_settings, transfer, defaultValue){
    var found = false;
    for (var i=0, l=base_settings.length; i<l; i++){
	if (name === base_settings[i].name
	    && shop === base_settings[i].shop){
	    var found = true;
	    return transfer(base_settings[i].value);
	}
    }

    if (!found){
	var s_default = 
	    base_settings.filter(function(s){
		return name === s.name && s.shop ===  -1
	    });

	if (s_default.length !== 0){
	    return transfer(s_default[0].value);
	}
    }
    
    return defaultValue;
};

diablo_set_float = function(v){
    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
	return undefined;
    } else{
	return parseFloat(v)
    }
};

diablo_set_integer = function(v){
    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
	return undefined;
    } else{
	return parseInt(v)
    }
};

diablo_set_string = function(s){
    if (angular.isUndefined(s)){
	return undefined;
    } else{
	return s.toString();
    }
};


var diablo_find_color = function(cid, allColors){
    if (cid === 0){
	return {cid:cid};
    } else{
	return {cid:cid, cname:diablo_get_object(cid, allColors).name};
    }
};

var diablo_in_colors = function(color, colors){
    for (var i=0, l=colors.length; i<l; i++){
	if (color.cid === colors[i].id
	   || color.cid === colors[i].cid){
	    return true;
	}
	
    }

    return false;
};


var diablo_viewport = function () {
    var e = window, a = 'inner';
    if (!('innerWidth' in window)) {
        a = 'client';
        e = document.documentElement || document.body;
    }
    return {
        width: e[a + 'Width'],
        height: e[a + 'Height']
    }
};

var diablo_items_per_page = function(){
    var h = diablo_viewport().height;

    if (h > 767){
	return 15;
    } else {
	return 10;
    }
};
