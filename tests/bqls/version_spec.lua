local version = require("bqls.version")

describe("bqls.version.compare", function()
	it("returns 0 when versions are equal", function()
		assert.are.same(0, version.compare("v1.2.3", "v1.2.3"))
	end)

	it("returns -1 when the first version is older (major)", function()
		assert.are.same(-1, version.compare("v0.5.0", "v1.0.0"))
	end)

	it("returns 1 when the first version is newer (major)", function()
		assert.are.same(1, version.compare("v1.0.0", "v0.5.0"))
	end)

	it("compares minor numerically, not lexicographically", function()
		-- A naive string comparison would treat "0.10.0" as older than "0.9.0"
		-- because "1" < "9" lexicographically; numeric comparison must not.
		assert.are.same(1, version.compare("v0.10.0", "v0.9.0"))
	end)

	it("compares patch when major and minor are equal", function()
		assert.are.same(-1, version.compare("v1.2.3", "v1.2.10"))
	end)

	it("treats versions with and without the v prefix the same", function()
		assert.are.same(0, version.compare("1.2.3", "v1.2.3"))
	end)

	it("returns nil when a version string cannot be parsed", function()
		assert.is_nil(version.compare("not-a-version", "v1.2.3"))
	end)
end)

describe("bqls.version.is_older_than", function()
	it("returns true when the version is older than the minimum", function()
		assert.is_true(version.is_older_than("v0.5.0", "v0.6.0"))
	end)

	it("returns false when the version meets the minimum", function()
		assert.is_false(version.is_older_than("v0.6.0", "v0.6.0"))
	end)

	it("returns false when the version exceeds the minimum", function()
		assert.is_false(version.is_older_than("v1.0.0", "v0.6.0"))
	end)

	it("returns false when either version is unparseable", function()
		assert.is_false(version.is_older_than("garbage", "v0.6.0"))
	end)
end)

describe("bqls.version.REQUIREMENTS", function()
	it("lists the minimum bqls server version bqls.nvim requires per feature", function()
		assert.is_true(#version.REQUIREMENTS > 0, "expected at least one feature requirement")
		for _, req in ipairs(version.REQUIREMENTS) do
			assert.is_string(req.feature)
			assert.is_string(req.min_version)
		end
	end)

	it("includes the Table Search requirement documented in the README (v0.6.0)", function()
		local found
		for _, req in ipairs(version.REQUIREMENTS) do
			if req.feature == "Table Search" then
				found = req
			end
		end
		assert.is_not_nil(found, "expected a Table Search requirement")
		assert.are.same(0, version.compare(found.min_version, "0.6.0"))
	end)
end)
