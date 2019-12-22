module Helpers
  def myDig(input, path)
    curr = input
    for segment in path do
      if curr != nil && curr.is_a?(Hash)
        if curr[segment] == nil
          curr = curr[segment.to_s]
        else
          curr = curr[segment]
        end
      else
        return nil
      end
    end
    curr
  end
end