local race = require "src.race"

describe("race", function()
  describe("start", function()
    it("should set active to true and countdown to 5", function()
      race.reset()
      race.start()
      assert.is_true(race.active)
      assert.are.equal(5, race.countdown)
    end)
  end)

  describe("reset", function()
    it("should reset all values", function()
      race.active = true
      race.started = true
      race.finished = true
      race.penalties = 10
      race.reset()
      assert.is_false(race.active)
      assert.is_false(race.started)
      assert.is_false(race.finished)
      assert.are.equal(0, race.penalties)
      assert.are.equal(3, race.nextMark)
    end)
  end)
end)