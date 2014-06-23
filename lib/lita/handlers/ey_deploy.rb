module Lita
  module Handlers
    class EyDeploy < EyBase

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

      def deploy(response)
        app = response.matches[0][0]
        env = response.matches[0][1]

        response.reply "Deploy what to where?" and return unless valid_app?(app) && valid_env?(app, env)

        branch = (response.matches[0][2] || default_branch_for(app, env)).strip

        do_if_can_access(response, app, env) do
          response.reply "Deploying #{app} branch '#{branch}' to #{env}"

          cmd = ey_deploy_cmd(app, env, branch)
          Lita.logger.info cmd
          deploy_result = `#{cmd}`

          feedback_msg = deploy_result.include?(ey_failure_msg) ? failed_msg : success_msg
          response.reply feedback_msg
        end
      end

      def rollback(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Rollback what?" and return unless valid_app?(app) && valid_env?(app, env)

        do_if_can_access(response, app, env) do
          response.reply "Rolling back #{app} #{env} to previous version..."

          cmd = ey_rollback_cmd(app, env)
          Lita.logger.info cmd
          result = `#{cmd}`

          response.reply result
        end
      end

      def enable_maintenance(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Place maintenance page where?" and return unless valid_app?(app) && valid_env?(app, env)

        do_if_can_access(response, app, env) do
          response.reply "Placing maintenance page at #{app} #{env}..."

          cmd = ey_maintenance_on_cmd(app, env)
          Lita.logger.info cmd
          result = `#{cmd}`

          response.reply result
        end
      end

      def disable_maintenance(response)
        app = response.matches[0][0].strip
        env = response.matches[0][1].strip

        response.reply "Disable maintenance page where?" and return unless valid_app?(app) && valid_env?(app, env)

        do_if_can_access(response, app, env) do
          response.reply "Disabling maintenance page at #{app} #{env}..."

          cmd = ey_maintenance_on_cmd(app, env)
          Lita.logger.info cmd
          result = `#{cmd}`

          response.reply result
        end
      end

    private

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

    end

    Lita.register_handler(EyDeploy)
  end
end
