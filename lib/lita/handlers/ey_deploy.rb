require "lita"

module Lita
  module Handlers
    class EyDeploy < Handler

      route(/ey deploy help/i, :help, command: true, help: {
        "ey deploy help" => "Display list of apps and envs available, and groups authorized to deploy on them"
      })

      route(/ey deploy (\w*) (\w*)( [\w\/\.\-\_]*)?/i, :deploy, command: true, help: {
        "ey deploy [app] [env] <branch_name>" => "Deploy specified branch (or default) to env [test, staging, production]"
      })

      def self.default_config(config)
        config.api_token = nil
        config.apps = {}
      end

      def self.namespace
        "ey"
      end

      def help(response)
        result = ""
        config.apps.each do |app_name, app_data|
          result += "App Name: #{app_name}\n"
          result += "  Environments:\n"
          app_data["envs"].each do |env_name, env_data|
            result += "    * #{env_name}\n"
            result += "      Default branch: #{env_data["default_branch"]}\n"
            result += "      Authorized users group: #{env_data["auth_group"]}\n"
          end
          result += "\n"
        end
        response.reply result
      end

      def deploy(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Deploy what to where?" and return unless valid_app?(app) && valid_env?(app, env)

        branch = (response.matches[0][2] || default_branch_for(app, env)).strip

        if can_deploy?(response.user, app, env)
          response.reply "Deploying #{app} branch '#{branch}' to #{env}"

          deploy_result = `#{ey_deploy_cmd(app, env, branch)}`

          feedback_msg = deploy_result.include?(ey_failure_msg) ? failed_msg : success_msg
          response.reply feedback_msg
        else
          response.reply access_denied % { group_name: required_group_to_deploy(app, env) }
        end
      end

      def valid_app?(app)
        config.apps.keys.include?(app)
      end

      def valid_env?(app, env)
        config.apps[app]["envs"].keys.include?(env)
      end

      def can_deploy?(user, app, env)
        group = required_group_to_deploy(app, env)
        return true unless group
        Lita::Authorization.user_in_group? user, required_group_to_deploy(app, env)
      end

      def required_group_to_deploy(app, env)
        config.apps[app]["envs"][env]["auth_group"]
      end

      def ey_deploy_cmd(app, env, branch)
        "bundle exec ey deploy --app='#{ey_app(app)}' --environment='#{ey_env(app, env)}' --ref='refs/heads/#{branch}' --migrate='rake db:migrate' --api-token=#{config.api_token}"
      end

      def ey_failure_msg
        "Failed deployment recorded on Engine Yard Cloud"
      end

      def success_msg
        "Deployment done. Restarting!"
      end

      def failed_msg
        "Deployment failed! Shame on you!"
      end

      def access_denied
        "Sorry, you don't have access; you must be at %{group_name} group."
      end

      def default_branch_for(app, env)
        config.apps[app]["envs"][env]["default_branch"] || "master"
      end

      def ey_app(app)
        config.apps[app]["name"]
      end

      def ey_env(app, env)
        config.apps[app]["envs"][env]["name"]
      end

    end

    Lita.register_handler(EyDeploy)
  end
end