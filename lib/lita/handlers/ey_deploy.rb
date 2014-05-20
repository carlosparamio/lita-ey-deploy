require "lita"

module Lita
  module Handlers
    class EyDeploy < Handler

      route(/ey deploy help/i, :help, command: true, help: {
        "ey deploy help" => "Display list of apps and envs available, and groups authorized to deploy on them"
      })

      route(/ey deploy (\w*) (\w*)( [\w\/\.\-\_]*)?/i, :deploy, command: true, help: {
        "ey deploy [app] [env] <branch_name>" => "Deploy specified branch (or default) to a particular app env"
      })

      route(/ey rollback (\w*) (\w*)/i, :rollback, command: true, help: {
        "ey rollback [app] [env]" => "Rollback a particular app env to previous version"
      })

      route(/ey maintenance on (\w*) (\w*)/i, :enable_maintenance, command: true, help: {
        "ey maintenance on [app] [env]" => "Place maintenance page at a particular app env"
      })

      route(/ey maintenance off (\w*) (\w*)/i, :disable_maintenance, command: true, help: {
        "ey maintenance off [app] [env]" => "Disable maintenance page at a particular app env"
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

          cmd = ey_deploy_cmd(app, env, branch)
          Lita.logger.info cmd
          deploy_result = `#{cmd}`

          feedback_msg = deploy_result.include?(ey_failure_msg) ? failed_msg : success_msg
          response.reply feedback_msg
        else
          response.reply access_denied % { group_name: required_group_to_access(app, env) }
        end
      end

      def rollback(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Rollback what?" and return unless valid_app?(app) && valid_env?(app, env)

        if can_deploy?(response.user, app, env)
          response.reply "Rolling back #{app} #{env} to previous version..."

          cmd = ey_rollback_cmd(app, env)
          Lita.logger.info cmd
          result = `#{cmd}`

          response.reply result
        else
          response.reply access_denied % { group_name: required_group_to_access(app, env) }
        end
      end

      def enable_maintenance(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Place maintenance page where?" and return unless valid_app?(app) && valid_env?(app, env)

        if can_deploy?(response.user, app, env)
          response.reply "Placing maintenance page at #{app} #{env}..."

          cmd = ey_maintenance_on_cmd(app, env)
          Lita.logger.info cmd
          result = `#{cmd}`

          response.reply result
        else
          response.reply access_denied % { group_name: required_group_to_access(app, env) }
        end
      end

      def disable_maintenance(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Disable maintenance page where?" and return unless valid_app?(app) && valid_env?(app, env)

        if can_deploy?(response.user, app, env)
          response.reply "Disabling maintenance page at #{app} #{env}..."

          cmd = ey_maintenance_on_cmd(app, env)
          Lita.logger.info cmd
          result = `#{cmd}`

          response.reply result
        else
          response.reply access_denied % { group_name: required_group_to_access(app, env) }
        end
      end

      def valid_app?(app)
        config.apps.keys.include?(app)
      end

      def valid_env?(app, env)
        config.apps[app]["envs"].keys.include?(env)
      end

      def can_deploy?(user, app, env)
        group = required_group_to_access(app, env)
        return true unless group
        Lita::Authorization.user_in_group? user, required_group_to_access(app, env)
      end

      def required_group_to_access(app, env)
        config.apps[app]["envs"][env]["auth_group"]
      end

      def ey_deploy_cmd(app, env, branch)
        "bundle exec ey deploy --app='#{ey_app(app)}' --environment='#{ey_env(app, env)}' --ref='refs/heads/#{branch}' --migrate='rake db:migrate' --api-token=#{config.api_token}"
      end

      def ey_rollback_cmd(app, env)
        "bundle exec ey rollback --app='#{ey_app(app)}' --environment='#{ey_env(app, env)}' --api-token=#{config.api_token}"
      end

      def ey_maintenance_on_cmd(app, env)
        "bundle exec ey web disable --app='#{ey_app(app)}' --environment='#{ey_env(app, env)}' --api-token=#{config.api_token}"
      end

      def ey_maintenance_off_cmd(app, env)
        "bundle exec ey web enable --app='#{ey_app(app)}' --environment='#{ey_env(app, env)}' --api-token=#{config.api_token}"
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