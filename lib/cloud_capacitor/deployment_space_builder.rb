require 'plexus'
module CloudCapacitor

  class DeploymentSpaceBuilder

    def self.graph_by_price(configurations:, max_price:, max_num_instances:4)
      configs = configurations.sort { |x,y| x.price <=> y.price }
      arcs = []
     
      config_groups = array_by_price(configurations, max_price, max_num_instances)
      config_groups = config_groups.sort {|x,y| x.price <=> y.price}
      config_groups.each {|config_group| puts"#{config_group}"}

      price = config_groups[0].price
      vertexes = []
      vertexes_old = nil

      i = 0
      until i >= config_groups.size() do
        if(equal(price, config_groups[i].price, 0.01))
          vertexes << config_groups[i]
        else
          add_edges(vertexes_old, vertexes, arcs)
          price = config_groups[i].price
          vertexes_old = Array.new(vertexes)
          vertexes = []
          i = i - 1
        end
        i += 1
      end

      add_edges(vertexes_old, vertexes, arcs)


      graph = Plexus::DirectedPseudoGraph.new(arcs)

      puts"graph - #{graph.edges}"
      
      graph
    end

    def self.equal(prop, prop2, error)
      diff = prop2 - prop
      if (diff < error)
        return true
      else
        return false
      end
    end


    def self.new_edge(source, target, label)
      puts "source #{source} - target #{target} - label #{label}"
      Plexus::Arc.new(source, target, label)
    end

    def self.add_edges(vertexes_old, vertexes, arcs)
      if(!vertexes_old.nil? && !vertexes.nil?)
        vertexes_old.each do |vertex_old|
          vertexes.each do |vertex|
            arcs << new_edge(vertex_old, vertex, vertex.price-vertex_old.price)
            arcs << new_edge(vertex, vertex_old, vertex_old.price-vertex.price)
          end
        end
      end
      puts ""
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
