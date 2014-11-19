# lita-ey-deploy

[![Gem Version](https://badge.fury.io/rb/lita-ey-deploy.svg)](http://badge.fury.io/rb/lita-ey-deploy)
[![Build Status](https://travis-ci.org/carlosparamio/lita-ey-deploy.png?branch=master)](https://travis-ci.org/carlosparamio/lita-ey-deploy)
[![Code Climate](https://codeclimate.com/github/carlosparamio/lita-ey-deploy.png)](https://codeclimate.com/github/carlosparamio/lita-ey-deploy)
[![Coverage Status](https://coveralls.io/repos/carlosparamio/lita-ey-deploy/badge.png)](https://coveralls.io/r/carlosparamio/lita-ey-deploy)

**lita-ey-deploy** is a handler for [Lita](http://lita.io/) that allows to manage deployments, rollbacks and maintenance page management on EngineYard.

## Installation

Add lita-ey-deploy to your Lita instance's Gemfile:

``` ruby
gem "lita-ey-deploy"
```

Add required configuration to lita_config.rb file:

``` ruby
  config.handlers.ey.api_token = "YOUR_EY_API_TOKEN"
  config.handlers.ey.apps = {
    "my_app_name_for_lita" => {
      "ey_name" => "my_app_name_at_ey",
      "envs" => {
        "test" => {
          ey_name: "my_app_testing",
          auth_group: "devs",
          default_branch: "develop"
        },
        "stage" => {
          ey_name: "my_app_staging",
          auth_group: "testers",
          default_branch: "stage"
        },
        "production" => {
          ey_name: "my_app_production",
          auth_group: "devops",
          default_branch: "master"
        }
      }
    }
  }
```

## See also

[lita-ey-info](http://github.com/carlosparamio/lita-ey-info)

## License

[MIT](http://opensource.org/licenses/MIT)
