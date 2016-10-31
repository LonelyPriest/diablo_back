require.config({
    baseUrl: '/private/employ/javascript',
    paths: {
        "angular": "/public/assets/angular-1.3.9/angular.min",
        "angular-router": "/public/assets/angular-1.3.9/angular-route.min",
	"angular-resource": "/public/assets/angular-1.3.9/angular-resource.min",
	// "angular-locale_zh": "/public/assets/angular-1.3.9/i18n/angular-locale_zh.js",
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
	"diablo-login-out": "/private/login/javascript/login_out_app",
	"diablo-pattern": "/private/utils/javascript/diablo_pattern",
	"diablo-utils": "/private/utils/javascript/diablo_utils", 
	
	"diablo-init": "/private/init/app" 
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

	"diablo-login-out": {
            exports: "diablo-login-out",
            deps: ["angular"]
        },

	"diablo-pattern": {
            exports: "diablo-pattern",
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

	"diablo-init":{
	    deps:["jquery"]
	} 
    }
});

require(["jquery",
	 
	 "angular", "angular-router", "angular-resource", "angular-ui-bootstrap",
	 
	 "jquery-custom", "jquery-cookie", "jquery-migrate", "jquery-block",
	 "bootstrap", "fastclick",
	 
	 "diablo-init", "diablo-function", "diablo-authen", "diablo-login-out",
	 "diablo-pattern", "diablo-utils", "employeeApp"], function($, angular)
	{
	    var attachFastClick = require('fastclick');
	    attachFastClick(document.body); 
	    App.init(); 
	    $(function() {
		angular.bootstrap(document, ["employeeApp"]);
	    });
	});
