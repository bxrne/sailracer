local boat = require "src.boat"

describe("boat", function()
  describe("getSpeedFactor", function()
    it("should return 0.1 for in irons (0 degrees)", function()
      assert.are.equal(0.1, boat.getSpeedFactor(0))
    end)
    it("should return 1.0 for beam reach (90 degrees)", function()
      assert.are.equal(1.0, boat.getSpeedFactor(math.pi/2))
    end)
    it("should return 0.5 for running (180 degrees)", function()
      assert.are.equal(0.5, boat.getSpeedFactor(math.pi))
    end)
  end)

  describe("normalizeAngle", function()
    it("should normalize angle > pi", function()
      local angle = 3 * math.pi
      local normalized = boat.normalizeAngle(angle)
      assert.are.equal(math.pi, normalized)
    end)
    it("should normalize angle < -pi", function()
      local angle = -3 * math.pi
      local normalized = boat.normalizeAngle(angle)
      assert.are.equal(-math.pi, normalized)
    end)
  end)
end)