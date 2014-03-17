require 'plexus'
module CloudCapacitor

  class DeploymentSpaceBuilder

    def self.graph_by_price(configurations:, max_price:, max_num_instances:2)
      configs = configurations.sort { |x,y| x.price <=> y.price }
      graph = Plexus::DirectedPseudoGraph.new
     
      config_groups = array_by_price(configurations, max_price, max_num_instances)
      config_groups = config_groups.sort {|x,y| x.price <=> y.price}
      config_groups.each {|config_group| puts"#{config_group}"}

      price = config_groups[0].price
      vertexes = []
      vertexes_old = nil
      for i in 0..config_groups.size()-1
        if(price == config_groups[i].price)
          vertexes << config_groups[i]
        else
          add_edges(vertexes_old, vertexes, graph)
          price = config_groups[i].price
          vertexes_old = vertexes
          vertexes = []
          i = i - 1
        end
      end

      add_edges(vertexes_old, vertexes, graph)

      puts"#{graph.edges.sort}"
      graph
    end

    def self.add_edges(vertexes_old, vertexes, graph)
      if(!vertexes_old.nil? && !vertexes.nil?)
        vertexes_old.each do |vertex_old|
          vertexes.each do |vertex|
            graph.add_edge(vertex_old, vertex, vertex.price-vertex_old.price)
            graph.add_edge(vertex, vertex_old, vertex_old.price-vertex.price)
          end
        end
      end
    end
    
    def self.array_by_price(configs, max_price, max_num_instances)
      config_groups = []

      for i in 0..configs.size()-1
        vm_types = []
        for j in 1..max_num_instances
          vm_types << configs[i]

          config_group = ConfigurationGroup.new(:configurations => vm_types)
          if(config_group.price < max_price)
            config_groups << config_group
          end
        end

      end

      config_groups
    end
  end
end
