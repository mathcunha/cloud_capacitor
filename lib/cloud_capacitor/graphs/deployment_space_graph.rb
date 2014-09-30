require 'plexus'
module CloudCapacitor
  class DeploymentSpaceGraph < Plexus::DirectedPseudoGraph
    attr_accessor :categories, :mode, :root
    attr_reader   :capacity_levels

    def initialize(*params)
      super(params)
      # Categories are filled when the graph is created
      # by the deployment space builder
      @categories = []
      @capacity_levels = Hash.new {}
    end

    def strict_mode?
      mode == :strict
    end

    def capacity_levels
      @capacity_levels.deep_dup
    end

    def find_category(name)
      @categories[@categories.index { |c| c.name == name }]
    end

    def calculate_capacity_levels
      @categories.each do |category|
        @capacity_levels[category] = Hash.new {[]}
        height = 0
        from = [category]
        while !from.empty?
          cfgs = adjacent_from(from)
          height += 1 unless cfgs.empty?
          @capacity_levels[category][height] = cfgs.uniq{|c| c.fullname} unless cfgs.empty?
          @capacity_levels[category][height].each { |c| c.capacity_level = height }
          from = cfgs
        end
      end
    end

    def adjacent_from(from)
      cfgs = []
      from.each do |source|
        adj = adjacent(source)
        unless adj.nil?
          # Get rid of fake nodes like root and categories
          adj.select! { |c| c.size > 0 }
          if strict_mode?
            adj.select! { |c| c > source || source.size == 0}
          else
            adj.select! { |c| c.method(mode).call > source.method(mode).call }
          end
          cfgs += adj
        end
      end
      cfgs
    end

    def height_from(from=categories[0])
      return 0 if from.nil?
      height = 0
      from = [from]
      while !from.empty?
        cfgs = adjacent_from(from)
        height += 1 unless cfgs.empty?
        from = cfgs
      end
      height
    end

  end
end
