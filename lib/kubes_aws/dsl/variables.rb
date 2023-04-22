module KubesAws::Dsl
  module Variables
    include Kubes::Compiler::Shared::RuntimeHelpers

    def load_variables
      load_variables_file("base")
      load_variables_file(Kubes.env)
      # Then load type scope variables, so they take higher precedence
      load_variables_file("base", @options[:type])
      load_variables_file(Kubes.env, @options[:type])
    end

    def load_variables_file(filename, type=nil)
      items = ["#{Kubes.root}/.kubes", type, "variables/#{filename}.rb"].compact
      path = items.join('/')
      instance_eval(IO.read(path), path) if File.exist?(path)
    end
  end
end
