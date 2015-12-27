module Wiki
  class Engine < ::Rails::Engine
    isolate_namespace Wiki
    engine_name 'wiki'

    initializer "wiki.assets.precompile" do |app|
      app.config.assets.precompile += %w(inject.js)
    end
  end
end
