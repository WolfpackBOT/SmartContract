var app = angular.module("app", ["ui.bootstrap", "ui.toggle"]);

app.config(["$provide" "$locationProvider",,
    function ($provide, $locationProvider) {
        $provide.constant("_", window._);
        $locationProvider.html5Mode(true);
    }])
    .constant("websiteSettings", {
        baseUrl: "https://wolfpackbot.github.com/SmartContract/",
        smartContractAddress: "0x42929134d71d752aaba973c11b499338ec2604da",
        environment: "test"
    })
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