require.config({
    baseUrl: '/private/wsale/js',
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

	"diablo-employee": "/private/employ/javascript/employ_app",
	"diablo-stock": "/private/purchaser/js/purchaser_app",
	"diablo-retailer": "/private/wretailer/js/wretailer_app",
	"diablo-good": "/private/wgood/js/wgood_app",

	"wsale-utils" : "/private/wsale/js/wsale_utils",
	
	// "wsale-good": "/private/wsale/js/wsale_new_good", 
	// "wsale-new": "/private/wsale/js/wsale_new", 
	// "wsale-reject": "/private/wsale/js/wsale_reject",
	// "wsale-rsn": "/private/wsale/js/wsale_rsn",
	// "wsale-update": "/private/wsale/js/update_wsale_detail",
	// "wsale-update-reject": "/private/wsale/js/update_wsale_reject"
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
	    deps: ["angular"]
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
	},

	"diablo-good": {
            exports: "diablo-good",
            deps: ["angular", "diablo-utils"]
	},
	
	"diablo-filter": {
            exports: "diablo-filter",
            deps: ["angular", "diablo-good", "diablo-utils"]
	},

	"diablo-init":{
	    deps:["jquery", "jquery-custom", "jquery-cookie", "jquery-block", "jquery-migrate", "fastclick"]
	},
	
	"diablo-employee": {
            exports: "diablo-employee",
            deps: ["jquery", "angular", "diablo-utils"]
	},
	
	"diablo-stock": {
            exports: "diablo-stock",
            deps: ["jquery", "angular", "diablo-utils"]
	},

	"diablo-retailer": {
            exports: "diablo-retailer",
            deps: ["jquery", "angular"]
	}, 

	"wsale-utils": {
            deps: ["jquery", "diablo-utils"]
	} 
    }
});

require(["jquery",
	 
	 "angular", "angular-router", "angular-resource", "angular-zh", "angular-ui-bootstrap",
	 "angular-local-storage",
	 
	 "jquery-custom", "jquery-cookie", "jquery-migrate", "jquery-block",
	 "bootstrap", "fastclick",
	 
	 "diablo-init", "diablo-function", "diablo-authen",
	 "diablo-pattern", "diablo-user-right",
	 "diablo-authen-right", "diablo-login-out", "diablo-utils", "diablo-filter", "diablo-good",

	 "diablo-employee", "diablo-stock", "wsale-utils", 
	 "wsaleApp", "load_wsale"], function($, angular)
	{
	    $(function() {
	    	angular.bootstrap(document, ["wsaleApp"]);
	    });

	    var app = require("diablo-init");
	    if (app !== undefined) app.init();
	    
	    var attachFastClick = require('fastclick');
	    if (typeof(attachFastClick) === 'function') attachFastClick(document.body);
	    
	});
