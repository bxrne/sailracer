local marks = require "src.marks"

describe("marks", function()
  describe("crossedStartLine", function()
    it("should return true when boat is at start line", function()
      local boat = { x = 400, y = 300 } -- Assuming line at y=300
      assert.is_true(marks.crossedStartLine(boat))
    end)
    it("should return false when boat is not at start line", function()
      local boat = { x = 400, y = 200 }
      assert.is_false(marks.crossedStartLine(boat))
    end)
  end)
end)