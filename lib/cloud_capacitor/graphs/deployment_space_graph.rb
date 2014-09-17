require 'plexus'
module CloudCapacitor
  class DeploymentSpaceGraph < Plexus::DirectedPseudoGraph
    attr_accessor :capacity_level, :categories, :mode, :root

    def initialize(*params)
      super(params)
      @categories = []
      @capacity_level = Hash.new {[]}
    end

    def strict_mode?
      mode == :strict
    end

    def capacity_level(from, height)

    end

    def height_from(from=categories[0])
      return 0 if from.nil?
      height = 0

      from = [from]
      while !from.empty?
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
        height += 1 unless cfgs.empty?
        from = cfgs
      end
      height
    end

  end
end