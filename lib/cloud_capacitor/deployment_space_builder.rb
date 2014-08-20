require 'plexus'
module CloudCapacitor

  class DeploymentSpaceBuilder

    def self.create_graph_generators
      DeploymentSpace::TRAVERSAL_MODES.each do |mode| 
        define_singleton_method "graph_by_#{mode}" do
          graph_by_prop(mode) 
        end
      end
    end

    def self.setup(vm_types)
      @@max_price         = Settings.deployment_space.max_price
      @@max_num_instances = Settings.deployment_space.max_num_instances
      @@configs_available = configs_under_price_limit(vm_types)
      create_graph_generators
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

    def self.strict_graph
      graph = Plexus::DirectedPseudoGraph.new
      edges = []
      root = create_root_node
      
      #We separate configs by category
      categories = separate_categories
      
      #Each category has an array of configurations.
      categories.each_value do |configs|
        #Sort each category configs by price in order
        #to find the tiniest one
        configs.sort! { |x, y| x.price <=> y.price }

        #Each category is a branch from the graph root
        #So, round-trip connect the first configs to the root
        edges << add_edge(root, configs[0], configs[0].category)
        edges << add_edge(configs[0], root, "root")

        #For each configuration, find its successors
        configs.each do |current_config|
          successors = filter_successors(configs, current_config)
          edges += connect(current_config, successors)
        end
      end
      
      edges.each { |e| graph.add_edge! e }
      graph

    end

    private
    def self.create_root_node
      root_vm = VMType.new(name:"root",
                           cpu:0, mem:0, price:0,
                           category:"root")

      Configuration.new(vm_type:root_vm, size:0)
    end

    def self.filter_successors(configs, current_config)
      #The > operator works thanks to the strict comparison
      #nature of the Configurations, eliminating only the
      #comparable ones. See Configuration#>
      successors = configs.select {|config| config > current_config }
      #Filter immediate strict successors only
      successors.each do |successor| 
        successors.reject! { |bigger_config| bigger_config > successor}
      end
      successors
    end

    def self.separate_categories
      categories = Hash.new{[]}
      @@configs_available.each { |cfg| categories[cfg.category] <<= cfg }
      categories
    end

    def self.connect(current_config, successors)
      edges = []
      successors.each do |s|
        edges << add_edge(current_config, s, "bigger")
        edges << add_edge(s, current_config, "smaller")
      end
      edges
    end

    def self.validate_setup
      raise InvalidConfigurationError unless defined? @@configs_available && !@@configs_available.nil?
    end

    def self.graph_by_prop(prop_method)
      edges = []
      root = Configuration.new(vm_type:VMType.new(name:"root",cpu:0,mem:0,price:0,category:"root"), size:0)
      configurations = @@configs_available.sort {|x,y| x.category <=> y.category}

      prop = configurations[0].category
      vertexes = []

      i = 0
      until i >= configurations.size() do
        if(prop.eql?configurations[i].category())
          vertexes << configurations[i]
        else
          edges.concat(array_by_prop(prop_method, vertexes, root))
          prop = configurations[i].category
          vertexes = []
          i = i - 1
        end
        i += 1
      end

      edges.concat(array_by_prop(prop_method, vertexes, root))
      
      graph = Plexus::DirectedPseudoGraph.new
      edges.each {|edge| graph.add_edge! edge}
      graph
    end

    def self.array_by_prop(prop_method, config, root)
      validate_setup
      edges = []

      configurations = config.sort {|x,y| x.method(prop_method).call() <=> y.method(prop_method).call()}

      prop = configurations[0].method(prop_method).call()
      vertexes = []
      vertexes_old = []
      vertexes_old << root

      i = 0
      until i >= configurations.size() do
        if(equal(prop, configurations[i].method(prop_method).call(), 0.01))
          vertexes << configurations[i]
        else
          add_edges(vertexes_old, vertexes, edges, prop_method)
          prop = configurations[i].method(prop_method).call()
          vertexes_old = Array.new(vertexes)
          vertexes = []
          i = i - 1
        end
        i += 1
      end

      add_edges(vertexes_old, vertexes, edges, prop_method)
      edges
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
    
    def self.add_edge(source, target, label)
      Plexus::Arc.new(source, target, label)
    end

    def self.add_edges(vertexes_old, vertexes, edges, prop_method)
      if(!vertexes_old.nil? && !vertexes.nil?)
        vertexes_old.each do |vertex_old|
          vertexes.each do |vertex|
            edges << add_edge(vertex_old, vertex, (vertex.method(prop_method).call() - vertex_old.method(prop_method).call()).round(2))
            edges << add_edge(vertex, vertex_old, (vertex_old.method(prop_method).call() - vertex.method(prop_method).call()).round(2))
          end
        end
      end
    end
  end
end
