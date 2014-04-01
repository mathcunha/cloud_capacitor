require 'plexus'
module CloudCapacitor

  class DeploymentSpaceBuilder

    DeploymentSpace::TRAVERSAL_MODES.each do |mode| 
      meth = "def self.graph_by_#{mode}(vm_types:) 
                graph_by_prop(vm_types, '#{mode}') 
              end"
      class_eval meth
    end

    def self.setup(vm_types)
      @@max_price         = Settings.deployment_space.max_price
      @@max_num_instances = Settings.deployment_space.max_num_instances
      @@configs_available = configs_under_price_limit(vm_types)
    end

    def self.configs_available
      @@configs_available
    end
    def self.max_price
      @@max_price
    end
    def self.max_num_instances
      @@max_num_instances
    end

    private
    def self.validate_setup
      raise InvalidConfigurationError unless defined? @@configs_available && !@@configs_available.nil?
    end

    def self.graph_by_prop(vm_types, prop_method)
      validate_setup
      graph = Plexus::DirectedPseudoGraph.new

      configurations = @@configs_available.sort {|x,y| x.method(prop_method).call() <=> y.method(prop_method).call()}

      prop = configurations[0].method(prop_method).call()
      vertexes = []
      vertexes_old = nil

      i = 0
      until i >= configurations.size() do
        if(equal(prop, configurations[i].method(prop_method).call(), 0.01))
          vertexes << configurations[i]
        else
          graph = add_edges(vertexes_old, vertexes, graph, prop_method)
          prop = configurations[i].method(prop_method).call()
          vertexes_old = Array.new(vertexes)
          vertexes = []
          i = i - 1
        end
        i += 1
      end

      graph = add_edges(vertexes_old, vertexes, graph, prop_method)
      graph
    end

    def self.equal(prop, prop2, error)
      diff = prop2 - prop
      diff < error
    end

    def self.configs_under_price_limit(vm_types)
      configs = []

      vm_types.each do |vm|
        (1..@@max_num_instances).each do |num_instances|
          if( (vm.price * num_instances) <= @@max_price)
            configs << Configuration.new(vm_type: vm, size: num_instances)
          end
        end
      end

      configs
    end
    
    def self.new_edge(source, target, label)
      #puts "source #{source} - target #{target} - label #{label.round(2)}"
      Plexus::Arc.new(source, target, label.round(2))
    end

    def self.add_edges(vertexes_old, vertexes, graph, prop_method)
      if(!vertexes_old.nil? && !vertexes.nil?)
        vertexes_old.each do |vertex_old|
          vertexes.each do |vertex|
            graph = graph.add_edge(vertex_old, vertex, (vertex.method(prop_method).call() - vertex_old.method(prop_method).call()).round(2))
            graph = graph.add_edge(vertex, vertex_old, (vertex_old.method(prop_method).call() - vertex.method(prop_method).call()).round(2))
          end
        end
      end
      graph
    end
  end
end
