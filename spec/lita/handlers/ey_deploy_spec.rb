require "spec_helper"

describe Lita::Handlers::EyDeploy, lita_handler: true do
  it { routes_command("ey deploy appname envname").to(:deploy) }
  it { routes_command("ey deploy appname envname release/1.0").to(:deploy) }
  it { routes_command("ey rollback appname envname").to(:rollback) }
  it { routes_command("ey maintenance on appname envname").to(:enable_maintenance) }
  it { routes_command("ey maintenance off appname envname").to(:disable_maintenance) }
end
