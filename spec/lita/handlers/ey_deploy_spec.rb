require "spec_helper"

describe Lita::Handlers::EyDeploy, lita_handler: true do
  it { routes_command("deploy appname envname develop").to(:deploy) }
  it { routes_command("deploy appname envname release/1.0").to(:deploy) }
end
