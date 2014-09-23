module CloudCapacitor

  class DeploymentSpaceBuilder

    def self.setup(vm_types)
      @@categories        = vm_types.map { |vm| vm.category }.uniq
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
    def self.categories
      @@categories
    end

    def self.graph(root, mode=:price)
      raise Err::NilGraphRootError, "Graph root node cannot be nil." if root.nil?
      mode == :strict ? property = :price : property = mode

      graph = DeploymentSpaceGraph.new
      graph.root = root
      graph.mode = mode

      edges = []

      #We separate configs by category
      categories = separate_categories

      #Each category has an array of configurations.
      categories.each_pair do |category, configs|

        graph.categories << category

        #Sort each category configs in order
        #to find the tiniest one
        configs.sort! { |x, y| x.method(property).call <=> y.method(property).call }
        first = configs.select { |cfg| cfg.method(property) == configs[0].method(property) }

        #Each category is a branch from the graph root
        #So, round-trip connect the first configs to the root
        edges << add_edge(root, category, category.name)
        edges << add_edge(category, root, "root")

        #Connect the category node to its first nodes
        first.each do |cfg|
          edges << add_edge(category, cfg, 'config')
          edges << add_edge(cfg, category, 'category')
        end

        #For each configuration, find its successors
        configs.each do |current_config|
          successors = filter_successors(configs, current_config, mode)
          edges += connect(current_config, successors)
        end
      end

      edges.each { |e| graph.add_edge! e }
      graph.calculate_capacity_levels
      graph

    end

    def self.create_fake_node(name)
      vm = VMType.new(name:name,
                       cpu:0, mem:0, price:0,
                       category:name)

      Configuration.new(vm_type:vm, size:0)
    end

    def self.create_root_node
      create_fake_node('root')
    end

    private
    def self.filter_successors(configs, current_config, mode=:strict)
      successors = []
      #The > operator works for Configurations thanks to
      # the strict comparison nature of the Configurations,
      # eliminating only the comparable ones. See Configuration#>
      if mode == :strict
        successors = configs.select {|config| config > current_config }
        #Filter immediate strict successors only
        successors.each do |successor|
          successors.reject! { |bigger_config| bigger_config > successor}
        end
      else
        successors = configs.select {|config| config.method(mode).call > current_config.method(mode).call }
        #Filter immediate successors only
        successors.each do |successor|
          successors.reject! { |bigger_config| bigger_config.method(mode).call > successor.method(mode).call}
        end
      end

      successors
    end

    def self.separate_categories
      categories = Hash.new{[]}
      @@configs_available.each { |cfg| categories[create_fake_node(cfg.category)] <<= cfg }
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

  end
end
