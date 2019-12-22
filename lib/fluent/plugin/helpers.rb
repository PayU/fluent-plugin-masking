module Helpers
  def myDig(input, path)
    curr = input
    for segment in path do
      if curr != nil && curr.is_a?(Hash)
        if curr[segment] == nil # segment is not a symbol
          curr = curr[segment.to_s] # segment as string
        else
          curr = curr[segment] # segment as symbol
        end
      else
        return nil
      end
    end
    curr
  end
end