var app = angular.module("app", ["ngCookies", "ui.bootstrap", "ui.toggle"]);

app.config(["$provide", "$locationProvider",
    function ($provide, $locationProvider) {
        $provide.constant("_", window._);
        $locationProvider.html5Mode(true);
    }])
    .constant("websiteSettings", {
        baseUrl: window.location.protocol + "//" + window.location.hostname + "/SmartContract/",
        smartContractAddress: window.location.protocol === "https:" ? "0x12528042299e0fca4d44ae4f42359319b8901fa2" : "0x43b44d1b890c4cd52df6d442d23f16eaf9a398ef",
        environment: window.location.protocol === "https:" ? "production" : "test"
    })
    .run(["$rootScope",
		function ($rootScope) {
            $rootScope.safeApply = function(fn) {
                if (this.$root && this.$root.$$phase) {
                    var phase = this.$root.$$phase;
                    if (phase == '$apply' || phase == '$digest') {
                        if (fn && (typeof(fn) === 'function')) {
                            fn();
                        }
                    } else {
                        this.$apply(fn);
                    }
                } else {
                    this.$apply(fn);
                }
            };
	}])
    // allow you to format a text input field.
    // <input type="text" ng-model="test" format="number" />
    // <input type="text" ng-model="test" format="currency" />
    .directive("format", ["$filter", function ($filter) {
        return {
            require: "?ngModel",
            link: function (scope, elem, attrs, ctrl) {
                if (!ctrl) return;

                ctrl.$formatters.unshift(function (a) {
                    return $filter(attrs.format)(ctrl.$modelValue);
                });

                elem.bind("blur", function (event) {
                    var plainNumber = elem.val().replace(/[^\d|\-+|\.+]/g, "");
                    elem.val($filter(attrs.format)(plainNumber));
                });
            }
        };
    }])
    .filter('smallAddress', ['$filter', function ($filter) {
        return function (address, count) {
            var output = null;

            if(!address) {
                return null;
            }

            try {
                output = address.substr(0, count) + "...";
            } catch (err) {
                console.log(address);
            }

            return output;
        };
    }])
    .filter('utcToLocal', ['$filter', function ($filter) {
        return function (utcDateString, format) {
            // return if input date is null or undefined
            if (!utcDateString) {
                return;
            }

            var mDate = moment(utcDateString);
            return mDate.format(format);
        };
    }])
    ;