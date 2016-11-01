require.config({
    baseUrl: '/private/wgood/js',
    paths: {
        "angular": "/public/assets/angular-1.3.9/angular.min",
        "angular-router": "/public/assets/angular-1.3.9/angular-route.min",
	"angular-resource": "/public/assets/angular-1.3.9/angular-resource.min",
	"angular-zh": "/public/assets/angular-1.3.9/i18n/angular-locale_zh",
	"angular-local-storage": "/public/assets/angular-local-storage/angular-local-storage",
	"angular-ui-bootstrap": "/public/assets/bootstrap/ui-bootstrap-tpls-0.13.1",
	
        "jquery": "/public/assets/metronic/plugins/jquery-1.11.3.min",
	"jquery-migrate": "/public/assets/metronic/plugins/jquery-migrate-1.2.1.min",
	"jquery-custom": "/public/assets/metronic/plugins/jquery-ui/jquery-ui-1.10.3.custom.min", 
	"jquery-cookie": "/public/assets/metronic/plugins/jquery.cokie.min",
	"jquery-block": "/public/assets/metronic/plugins/jquery.blockui.min",
	"bootstrap": "/public/assets/bootstrap/js/bootstrap.min",

	"fastclick": "/public/assets/fastclick/fastclick.min", 
	"diablo-function": "/private/utils/javascript/diablo_function",
	
	"diablo-authen": "/private/utils/javascript/diablo_authen_app",
	"diablo-pattern": "/private/utils/javascript/diablo_pattern",
	"diablo-utils": "/private/utils/javascript/diablo_utils",
	"diablo-user-right": "/private/right/javascript/user_right_app",
	"diablo-authen-right": "/private/right/javascript/user_right_map",
	"diablo-login-out": "/private/login/javascript/login_out_app",
	"diablo-filter": "/private/utils/javascript/diablo_filter_app",

	"diablo-init": "/private/init/app",

	// "wgood-new": "/private/wgood/js/wgood_new",
	// "wgood-update": "/private/wgood/js/wgood_update",
	// "wgood-size": "/private/wgood/js/wgood_size",
	// "wgood-color": "/private/wgood/js/wgood_color"
    },
    
    shim: {
        "angular": {
            exports: "angular",
            deps: ["jquery"]
        },
        "angular-router": {
            exports: "angular-router",
            deps: ["angular"]
        },

	"angular-resource": {
            exports: "angular-esource",
            deps: ["angular"]
        },

	"angular-zh": {
            deps: ["angular"]
        },

	"angular-local-storage": {
            exports: "angular-local-storage",
            deps: ["angular"]
        },

	"angular-ui-bootstrap": {
            exports: "angular-ui-bootstrap",
            deps: ["angular"]
        },

	"diablo-function": {
	    deps: ["jquery"] 
	},

	"diablo-authen": {
            exports: "diablo-authen",
            deps: ["angular"]
        },

	"diablo-pattern": {
            exports: "diablo-pattern",
            deps: ["angular"]
	},

	"diablo-user-right": {
            exports: "diablo-user-right",
            deps: ["angular"]
	},

	"diablo-authen-right": {
            exports: "diablo-authen-right",
            deps: ["angular"]
	},

	"diablo-login-out":{
	    deps:["angular"]
	},

	"diablo-utils": {
            exports: "diablo-utils",
            deps: ["angular"]
	},
	
        "jquery": {
            exports: "jquery"
        },

	"jquery-custom": {
	    deps: ["jquery"],
	},

	"jquery-cookie": {
	    deps: ["jquery"]
        },

	"jquery-block": {
	    deps: ["jquery"]
        },
	
	"jquery-migrate": {
	    deps: ["jquery"]
        },

	"bootstrap": {
	    deps: ["jquery"]
	},

	"fastclick": {
	    // deps: ["jquery"]
	},

	// "diablo-good": {
        //     exports: "diablo-good",
        //     deps: ["angular"]
	// },
	
	"diablo-filter": {
            exports: "diablo-filter",
            deps: ["angular"]
	},

	"diablo-init":{
	    deps:["jquery", "jquery-custom", "jquery-cookie", "jquery-block", "jquery-migrate", "fastclick"]
	},

	// "wgood-update":{
	//     deps:["jquery"]
	// },

	// "wgood-size":{
	//     deps:["jquery"]
	// },

	// "wgood-color":{
	//     deps:["jquery"]
	// },

	// "wgood-new":{
	//     exports: "wgood-new",
	//     deps:["jquery"]
	// }
    }
});

require(["jquery",
	 
	 "angular", "angular-router", "angular-resource", "angular-zh", "angular-ui-bootstrap",
	 "angular-local-storage",
	 
	 "jquery-custom", "jquery-cookie", "jquery-migrate", "jquery-block",
	 "bootstrap", "fastclick",
	 
	 "diablo-init", "diablo-function", "diablo-authen",
	 "diablo-pattern", "diablo-user-right",
	 "diablo-authen-right", "diablo-login-out", "diablo-utils", "diablo-filter",

	 // "wgood-new", "wgood-update", "wgood-size", "wgood-color",
	 
	 "wgoodApp", "load_wgood"], function($, angular)
	{
	    $(function() {
		angular.bootstrap(document, ["wgoodApp"]);
	    });

	    var app = require("diablo-init");
	    if (app !== undefined) app.init();
	    
	    var attachFastClick = require('fastclick');
	    if (typeof(attachFastClick) === 'function') attachFastClick(document.body);
	    
	});
