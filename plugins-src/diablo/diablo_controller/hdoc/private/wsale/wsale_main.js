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
	// "diablo-employee": "/private/employ/javascript/employ_app",
	// "diablo-good": "/private/wgood/js/wgood_app",
	
	"diablo-filter": "/private/utils/javascript/diablo_filter_app",

	// "diablo-wsale": "/private/wsale/js/wsaleApp"
	"diablo-init": "/private/init/app",

	"diablo-employee": "/private/employ/javascript/employ_app",
	"diablo-stock": "/private/purchaser/js/purchaser_app",
	"diablo-retailer": "/private/wretailer/js/wretailer_app",
	"diablo-good": "/private/wgood/js/wgood_app",

	"wsale-utils" : "/private/wsale/js/wsale_utils",
	"wsale-good": "/private/wsale/js/wsale_new_good",
	
	"wsale-new": "/private/wsale/js/wsale_new", 
	"wsale-reject": "/private/wsale/js/wsale_reject",
	"wsale-rsn": "/private/wsale/js/wsale_rsn",
	"wsale-update": "/private/wsale/js/update_wsale_detail",
	"wsale-update-reject": "/private/wsale/js/update_wsale_reject"
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
	    // deps: ["jquery"]
	},

	"diablo-good": {
            exports: "diablo-good",
            deps: ["angular"]
	},
	
	"diablo-filter": {
            exports: "diablo-filter",
            deps: ["angular", "diablo-good"]
	},

	"diablo-init":{
	    deps:["jquery"]
	},

	// "diablo-wsale": {
        //     exports: "diablo-wsale",
        //     deps: ["angular"]
	// },

	// "diablo-wsale-ctrl": {
        //     exports: "diablo-wsale-ctrl",
        //     deps: ["angular"]
	// },

	"diablo-employee": {
            exports: "diablo-employee",
            deps: ["angular"]
	},
	
	"diablo-stock": {
            exports: "diablo-stock",
            deps: ["angular"]
	},

	"diablo-retailer": {
            exports: "diablo-retailer",
            deps: ["angular"]
	},

	"wsale-good": {
            // exports: "diablo-wsale-good",
            deps: ["angular"]
	},

	"wsale-utils": {
            deps: ["jquery"]
	},

	"wsale-new": {
            exports: "wsale-new",
            deps: ["angular", "jquery"]
	},

	"wsale-reject": {
	    deps: ["angular", "jquery"],
	},

	"wsale-rsn": {
	    deps: ["angular", "jquery"],
	},

	"wsale-update": {
	    deps: ["angular", "jquery"],
	},

	"wsale-update-reject": {
	    deps: ["angular", "jquery"],
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

	 "diablo-employee", "diablo-stock", "wsale-utils", "wsale-good",
	 "wsale-reject", "wsale-rsn", "wsale-update", "wsale-update-reject", "wsale-new",
	 
	 "wsaleApp"], function($, angular)
	{
	    // $.noConflict();
	    // console.log(window);
	    // console.log(angular);
	    // console.log(FastClick);
	    var attachFastClick = require('fastclick');
	    attachFastClick(document.body); 
	    App.init(); 
	    $(function() {
		angular.bootstrap(document, ["wsaleApp"]);
	    });
	});
