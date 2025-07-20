local arrayMethods = {}

--- Check if an array includes a value
---@generic T
---@param array T[]
---@param value unknown
---@return boolean
function arrayMethods.includes(array, value)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end

--- Filter an array based on a predicate
---@generic T
---@param array T[]
---@param predicate fun(value: T): boolean
---@return T[]
function arrayMethods.filter(array, predicate)
	local result = {}
	for _, v in ipairs(array) do
		if predicate(v) then
			table.insert(result, v)
		end
	end
	return result
end

--- Map an array to a new array using a transform function
---@generic T
---@generic U
---@param array T[]
---@param transform fun(value: T): U
---@return U[]
function arrayMethods.map(array, transform)
	local result = {}
	for _, v in ipairs(array) do
		table.insert(result, transform(v))
	end
	return result
end

--- Reduce an array to a single value
---@generic T
---@generic U
---@param array T[]
---@param reducer fun(acc: U, value: T): U
---@param initialValue U
---@return U
function arrayMethods.reduce(array, reducer, initialValue)
	local accumulator = initialValue
	for _, v in ipairs(array) do
		accumulator = reducer(accumulator, v)
	end
	return accumulator
end

--- Find the first item in an array that satisfies a predicate
---@generic T
---@param array T[]
---@param predicate fun(value: T): boolean
---@return T|nil
function arrayMethods.find(array, predicate)
	for _, v in ipairs(array) do
		if predicate(v) then
			return v
		end
	end
	return nil
end

--- Check if all items in an array satisfy some criteria
---@generic T
---@param array T[]
---@param predicate fun(value: T): boolean
---@return boolean
function arrayMethods.every(array, predicate)
	for _, v in ipairs(array) do
		if not predicate(v) then
			return false
		end
	end
	return true
end

--- Check if some items in the array satisfy some criteria
---@generic T
---@param array T[]
---@param predicate fun(value: T): boolean
---@return boolean
function arrayMethods.some(array, predicate)
	for _, v in ipairs(array) do
		if predicate(v) then
			return true
		end
	end
	return false
end

--- Check if an array has specific keys
---@generic T
---@generic K
---@param array T[]
---@param keys K[]
---@return boolean
function arrayMethods.hasKeys(array, keys)
	for _, key in ipairs(keys) do
		if not array[key] then
			return false
		end
	end
	return true
end

--- Get the keys of a table
---@generic T
---@generic K
---@param array T[]
---@return K[]
function arrayMethods.keys(array)
	local keys = {}
	for key,v in pairs(array) do
		table.insert(keys, key)
	end
	return keys
end

--- Creates a shallow copy of an array
---@generic T
---@param array T[]
---@return T[]
function arrayMethods.copy(array)
	local copy = {}
	for i, v in ipairs(array) do
		copy[i] = v
	end
	return copy
end

--- Creates a shallow copy of an associative array
---@param array table<unknown, unknown>
---@return table<unknown, unknown>
function arrayMethods.copyAssociative(array)
	local copy = {}
	for k, v in pairs(array) do
		copy[k] = v
	end
	return copy
end

return arrayMethods
-- End of File